package MIME::Expander;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.02';

use vars qw($PrefixGuess $PrefixPlugin @DefaultGuesser @EnabledPlugins);
BEGIN {
    $PrefixGuess    = 'MIME::Expander::Guess';
    $PrefixPlugin   = 'MIME::Expander::Plugin';
    @DefaultGuesser = ('MMagic', 'FileName');
    @EnabledPlugins = ();
}

use Email::MIME;
use Email::MIME::ContentType ();
use MIME::Type;
use Module::Load;
use Module::Pluggable search_path => $PrefixPlugin, sub_name => 'expanders';
use MIME::Expander::Plugin::MessageRFC822;
use Scalar::Util 'blessed';

sub import {
    my $class = shift;
    @EnabledPlugins = @_;
}

sub regulate_type {
    return undef unless( defined $_[1] );
    my $type = $_[1];

    # There is regexp from Email::MIME::ContentType 1.015
    my $tspecials = quotemeta '()<>@,;:\\"/[]?=';
    my $discrete  = qr/[^$tspecials]+/;
    my $composite = qr/[^$tspecials]+/;
    my $params    = qr/;.*/;
    return undef unless( $type =~ m[ ^ ($discrete) / ($composite) \s* ($params)? $ ]x );

    my $ct = Email::MIME::ContentType::parse_content_type($type);
    return undef if( ! $ct->{discrete} or ! $ct->{composite} );
    return MIME::Type->simplified(join('/',$ct->{discrete}, $ct->{composite}));
}

sub new {
    my $class = shift;
    $class = ref $class || $class;
    my $self = {
        expects     => [],
        guesser     => undef,
        depth       => undef,
        };
    bless  $self, $class;
    return $self->init(@_);
}

sub init {
    my $self = shift;
    my $args;
    if( 0 == @_ % 2 ){
        $args = { @_ }
    }else{
        $args = shift || {};
    }

    $self->expects(
        exists $args->{expects} ? $args->{expects} : [] );

    $self->guesser(
        exists $args->{guesser} ? $args->{guesser} : undef );

    $self->depth(
        exists $args->{depth} ? $args->{depth} : undef );

    return $self;
}

sub expects {
    my $self = shift;
    if( @_ ){
        $self->{expects} = shift;
        die "setting value is not acceptable, it requires an reference of ARRAY"
            if( defined $self->{expects} and ref($self->{expects}) ne 'ARRAY' );
    }
    return $self->{expects};
}

sub is_expected {
    my $self = shift;
    my $type = shift or undef;
    die "invalid type $type that has not looks as mime/type"
        if( $type !~ m,^.+/.+$, );
    return () unless( $self->expects );
    for my $regexp ( map { ref $_ ? $_ : qr/$_/ } @{$self->expects} ){
        return 1 if( $type =~ $regexp );
    }
    return ();
}

sub depth {
    my $self = shift;
    if( @_ ){
        $self->{depth} = shift;
        die "setting value is not acceptable, it requires a native number"
            if( defined $self->{depth} and $self->{depth} =~ /\D/ );
    }
    return $self->{depth};
}

sub guesser {
    my $self = shift;
    if( @_ ){
        $self->{guesser} = shift;
        die "setting value is not acceptable, it requires an reference of CODE or ARRAY"
            if( defined $self->{guesser} 
            and ref($self->{guesser}) ne 'CODE'
            and ref($self->{guesser}) ne 'ARRAY');
    }
    return $self->{guesser};
}

sub guess_type_of {
    my $self     = shift;
    my $ref_data = shift or die "missing mandatory parameter";
    my $info     = shift || {};
    
    my $type    = undef;
    my $routine = $self->guesser;

    if(     ref $routine eq 'CODE' ){
        $type = $self->guesser->($ref_data, $info);

    }else{
        my @routines;
        if( ref $routine eq 'ARRAY' ){
            @routines = @$routine;
        }else{
            @routines = @DefaultGuesser;
        }
        for my $klass ( @routines ){
            $klass = join('::', $PrefixGuess, $klass) if( $klass !~ /:/ );
            Module::Load::load $klass;
            $type = $self->regulate_type( $klass->type($ref_data, $info) );
            last if( $type and $type ne 'application/octet-stream');
        }
    }
    return ($type || 'application/octet-stream');
}

sub plugin_for {
    my $self = shift;
    my $type = shift;

    my $plugin = undef;
    for my $available ( $self->expanders ){

        my $klass = undef;
        unless( @EnabledPlugins ){
            $klass = $available;
        }else{
            for my $enable ( @EnabledPlugins ){
                $enable = join('::', $PrefixPlugin, $enable)
                    if( $enable !~ /:/ );
                if( $available eq $enable ){
                    $klass = $available;
                    last;
                }
            }
            next unless( $klass );
        }
        
        Module::Load::load $klass;
        if( $klass->is_acceptable( $self->regulate_type($type) ) ){
            $plugin = $klass->new;
            last;
        }
    }
    return $plugin;
}

sub create_media {
    my $self     = shift;
    my $ref_data = shift or die "missing mandatory parameter";
    my $info     = shift || {};

    my $type = $self->regulate_type($info->{content_type});
    if( ! $type or $type eq 'application/octet-stream' ){
        $type = $self->guess_type_of($ref_data, $info);
    }
    
    if( MIME::Expander::Plugin::MessageRFC822->is_acceptable(
        $self->regulate_type($type)
    )){
        return Email::MIME->new($ref_data);
    }else{
        return Email::MIME->create(
            attributes => {
                content_type    => $type,
                encoding        => 'binary',
                filename        => $info->{filename},
                },
            body => $ref_data,
            );
    }
}

sub walk {
    my $self        = shift;
    my $data        = shift;
    my $callback    = shift;
    my $info        = shift || {};
    my $c           = 0;

    my @medias = ();
    if( blessed($data) and $data->isa('Email::Simple') ){
        push @medias, $data;
    }else{
        @medias = ($self->create_media(
            ref $data eq 'SCALAR' ? $data : \$data,
            $info));
    }

    # reset vars for depth option
    my $ptr     = 0;
    my $limit   = 0;
    my $level   = 1;
    my $bound   = scalar @medias;
    
    # when expandable contents, then append it to @medias
    while( my $media = shift @medias ){
        my $type    = $media->content_type;
        my $plugin  = $self->plugin_for($type);
        if( $limit or $self->is_expected( $type ) or ! $plugin ){
            # expected or un-expandable data
            $callback->($media) if( ref $callback eq 'CODE' );
            ++$c;
        }else{
            # expand more
            $plugin->expand( $media , sub {
                push @medias, $self->create_media( @_ );
            });
        }

        ++$ptr;
        if( $bound <= $ptr ){
            if( $self->depth and $self->depth <= $level ){
                $limit = 1;
            }
            $bound += scalar @medias;
            ++$level;
        }
    }
    
    return $c;
}


1;
__END__


=pod

=head1 NAME

MIME::Expander - Walks through all the MIME parts expanded recursively in a message

=head1 SYNOPSIS

    use MIME::Expander;
    use IO::All;
    
    my $callback = sub {
            my $em = shift; # is instance of Email::MIME
            $em->body > io( $em->filename );
        };
    
    my $exp = MIME::Expander->new;
    my $num = $exp->walk( io($ARGV[0])->all, $callback );
    
    print "total $num files are expanded.\n";

=head1 DESCRIPTION

MIME::Expander is an utility module that works like the Email::MIME::walk method.
Feature of this module is that all the parts passing to the callback, are expanded by MIME mechanism.
It expands archived, compressed or multi-parted message using various MIME::Expander::Plugin modules.

=head1 CONSTRUCTOR AND ACCESSORS

The constructor new() accepts a reference of hash as configurations.

Following key of hash are available, and there is an access method of a same name.

=over 4

=item expects

A value is a list reference and the elements are string or regular expression.

If this parameter is set, then the walk() will not expand contents of specified mime types.

=item guesser

A value is a reference of code or reference of array which contains name of the "guess classes".
In the case of a code, it is only performed for determining the mime type.
In array, it performs in order of the element, and what was determined first is adopted.

Each routines have to determine the type of the data which will be inputted.

The parameters passed to a routine are a reference of scalar to contents, 
and information as reference of hash.

Although the information may have a "filename",
however depending on implements of each expander module, it may not be expectable.

The routine have to return mime type string, or undef.
If value of return is false value, that means "application/octet-stream".

For example, sets routine which determine text or jpeg.

    my $exp = MIME::Expander->new({
        guesser => sub {
                my $ref_contents = shift;
                my $info         = shift || {};
                if( defined $info->{filename} ){
                    my ($suffix) = $info->{filename} =~ /\.(.+)$/;
                    if( defined $suffix ){
                        if( lc $suffix eq 'txt' ){
                            return 'text/plain';
                        }elsif( $suffix =~ /^jpe?g$/i ){
                            return 'image/jpeg';
                        }
                    }
                }
            },
        });

When useing the "guess classes", like this is the default of guesser, package name is omissible:

    my $exp = MIME::Expander->new({
        guesser => [qw/MMagic FileName/],
        });

Please look in under namespace of L<MIME::Expander::Guess> about what kinds of routine are available.

=item depth

A value is a native number.

Please see "walk".

=back

=head1 CLASS METHODS

=head2 regulate_type( $type )

Simplify when the type which removed "x-" is registered.

    MIME::Expander->regulate_type("text/plain; charset=ISO-2022-JP");
    #=> "text/plain"

    MIME::Expander->regulate_type('application/x-tar');
    #=> "application/tar"

Please see about "simplified" in the document of L<MIME::Type>.

=head1 INSTANCE METHODS

=head2 init

Initialize instance. This is for overriding.

=head2 expects( \@list )

Accessor to field "expects".

=head2 is_expected( $type )

Is $type the contents set to field "expects" ?

=head2 depth( $native_number )

Accessor to field "depth".

=head2 guesser( \&code | \@list )

Accessor to field "guesser".

=head2 guess_type_of( \$contents, [\%info] )

Determine mime type from the $contents.

Optional %info is as hint for determing mime type.
It will be passed to "guesser" directly.

A key "filename" can be included in %info.

=head2 plugin_for( $type )

Get an instance of the expander class for mime type "$type".

    my $me = MIME::Expander->new;
    my $expander = $me->plugin_for('application/tar') or die "not available";
    $expander->expand( \$data, $callback );

Please see also the PLUGIN section.

=head2 create_media( \$contents )

Create an instance of Email::MIME from $contents.
If $contents does not look like a valid syntax of email,
it is as an attachment.

=head2 walk( \$message, $callback )

Walks through all the MIME parts expanded recursively in a $message.
If the $message includes expandable contents,
the callback will accept each MIME parts as instance of L<Email::MIME>.
Or $message does not have parts, the callback will accept $message own.

See also L<Email::MIME> about $email object.

Note that the expanded data are further checked and processed recursively.
And the recursive depth is to the level of the value of "depth" field.

=head1 PLUGIN

Expanding module for expand contents can be added as plug-in. 

Please see L<MIME::Expander::Plugin> for details.

=head1 CAVEATS

This module implements in-memory decompression.

=head1 REPOSITORY

MIME::Expander is hosted on github L<https://github.com/hiroaki/MIME-Expander>

=head1 AUTHOR

WATANABE Hiroaki E<lt>hwat@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Email::MIME>

L<MIME::Type>

=cut
