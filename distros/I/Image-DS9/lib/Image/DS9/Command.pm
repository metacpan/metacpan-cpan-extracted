package Image::DS9::Command;

# ABSTRACT: Command definitions

use v5.10;
use strict;
use warnings;

our $VERSION = 'v1.0.1';

our @CARP_NOT = qw( Image::DS9 );

use Image::DS9::PConsts;
use Image::DS9::Grammar 'grammar';
use Image::DS9::Parser;
use Image::DS9::Constants::V1 'SPECIAL_ATTRIBUTES';

use Ref::Util 'is_arrayref', 'is_scalarref';
use Scalar::Util 'reftype';

use namespace::clean;

sub _croak {
    require Carp;
    my $fmt = shift;
    @_ = sprintf( $fmt, @_ );
    goto \&Carp::croak;
}

sub _carp {
    require Carp;
    my $fmt = shift;
    @_ = sprintf( $fmt, @_ );
    goto \&Carp::carp;
}

sub new {
    my $class = shift;
    $class = ref $class || $class;

    my $command = shift;
    my $opts    = shift || {};

    my $spec = grammar( $command ) // return;

    my $self = bless {
        command       => $command,
        spec          => $spec,
        opts          => $opts,
        cvt           => 1,
        chomp         => 1,
        retref        => 0,
        attrs         => {},
        special_attrs => {},
    }, $class;

    $self->parse( @_ );

    $self;
}

sub parse {
    my $self = shift;

    my $match = Image::DS9::Parser::parse_spec( $self->{command}, $self->{spec}, @_ );

    $self->{$_} = $match->{$_} for keys %$match;
    $self->{found_attrs} = exists $self->{attrs};

    $self->{name} = $self->{argl}{name} || q{};

    $self->{chomp}  = $self->{argl}{chomp}  if exists $self->{argl}{chomp};
    $self->{cvt}    = $self->{argl}{cvt}    if exists $self->{argl}{cvt};
    $self->{retref} = $self->{argl}{retref} if exists $self->{argl}{retref};

    # the 'new' and 'now' attributes are special.  this needs to be generalized
    for my $special ( SPECIAL_ATTRIBUTES ) {
        $self->{special_attrs}{$special} = $self->{attrs}{$special} || 0;
        delete $self->{attrs}{$special};
    }

    # if this command has a buffer argument, it needs to be
    # sent via the XPASet buffer argument, not as part of the
    # command string. split it off from the regular args
    if ( $self->{argl}{bufarg} && !$self->{query} ) {
        my $value = pop @{ $self->{args} };
        $self->{bufarg} = $value->cvt_for_set;
    }

    $self->form_command
      unless $self->{opts}{nocmd};
}

sub _expand_token {
    my $token = shift;

    return () if $token->is_ephemeral;

    my @return;

    if ( $token->is_rewrite ) {
        push @return, ${ $token->extra }
          if $token->has_extra;
    }
    else {
        my $ref = $token->cvt_for_set;
        push @return,
            is_scalarref( $ref ) ? ${$ref}
          : is_arrayref( $ref )  ? @{$ref}
          :   _croak( q{don't know how to handle reference type of %s}, reftype( $ref ) );
    }

    return @return;
}

sub form_command {
    my $self = shift;

    my @command = ( $self->{command} );

    foreach my $special ( SPECIAL_ATTRIBUTES ) {
        push @command, $special if $self->{special_attrs}{$special};
    }

    push @command, map { _expand_token( $_ ) } @{ $self->{cmds} };
    my @args = map { _expand_token( $_ ) } @{ $self->{args} };

    my @attr;

    unless ( $self->{opts}{noattrs} ) {
        for my $name ( keys %{ $self->{attrs} } ) {
            my $val    = $self->{attrs}{$name};
            my $valref = $val->cvt_for_set;

            # dereference
            push @attr, $name, $$valref;
        }
    }

    $self->{command_list} = [ \@command, \@args, \@attr ];
}

sub attrs {
    my $self = shift;

    my %attrs;

    for my $name ( keys %{ $self->{attrs} } ) {
        my $val    = $self->{attrs}{$name};
        my $valref = $val->cvt_for_set;

        # dereference scalar refs; leave the rest as is
        $attrs{$name} = is_scalarref( $valref ) ? $$valref : $valref;
    }

    %attrs;
}

sub cvt_get {
    my $self = shift;

    # don't change the buffer unless asked to convert values
    # unless expecting more than one value or we're supposed to convert
    return unless @{ $self->{argl}{rvals} } > 1 || $self->{cvt};


    # the buffer will be changed, either through a split or a convert,
    # or both.

    # split the buffer if required
    my @input = @{ $self->{argl}{rvals} } > 1 ? _splitbuf( $_[0] ) : ( $_[0] );
    my @output;

    if ( @input != @{ $self->{argl}{rvals} } ) {
        # too many results is always an error
        if ( @input > @{ $self->{argl}{rvals} } ) {
            _croak(
                '%s: expected %d values, got %d',
                $self->{command}, 0+ @{ $self->{argl}{rvals} },
                0+ @input,
            );
        }

        unless ( $self->{opts}{ResErrIgnore} ) {
            ## no critic( ProhibitNoStrict)
            no strict 'refs';
            require Carp;
            my $func = $self->{opts}{ResErrWarn} ? \&_carp : \&_croak;
            $func->(
                '%s: expected %d values, got %d',
                $self->{command}, 0+ @{ $self->{argl}{rvals} },
                0+ @input,
            );
        }

        if ( @input < @{ $self->{argl}{rvals} } ) {
            push @input, () x ( @{ $self->{argl}{rvals} } - @input );
        }
    }

    if ( $self->{cvt} ) {
        foreach my $arg ( @{ $self->{argl}{rvals} } ) {
            my $input  = shift @input;
            my $valref = $arg->cvt_from_get( \$input );
            push @output, is_scalarref( $valref ) ? $$valref : $valref;
        }
    }
    else {
        @output = @input;
    }

    $_[0] = @output > 1 ? \@output : $output[0];
}

sub _splitbuf {

    $_[0] =~ s/^\s+//;
    $_[0] =~ s/\s+$//;
    split( / /, $_[0] );
}

sub command_list { @{ $_[0]->{command_list} } }

sub command {
    my ( $commands, $args, $attr ) = $_[0]->command_list;
    join q{ }, @$commands, @$args, @$attr;
}

sub query  { $_[0]->{query} }
sub bufarg { $_[0]->{bufarg} }
sub chomp  { $_[0]->{chomp} }    ## no critic(Subroutines::ProhibitBuiltinHomonyms)
sub retref { $_[0]->{retref} }

#
# This file is part of Image-DS9
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Image::DS9::Command - Command definitions

=head1 VERSION

version v1.0.1

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-image-ds9@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Image-DS9>

=head2 Source

Source is available at

  https://gitlab.com/djerius/image-ds9

and may be cloned from

  https://gitlab.com/djerius/image-ds9.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Image::DS9|Image::DS9>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
