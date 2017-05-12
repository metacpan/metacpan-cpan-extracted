package MIME::Detect::Type;
use strict;
use Moo;
use if $] < 5.020, 'Filter::signatures';
use feature 'signatures';
no warnings 'experimental::signatures';

use vars '$VERSION';
$VERSION = '0.08';

=head1 NAME

MIME::Detect::Type - the type of a file

=head1 SYNOPSIS

    my $type = $mime->mime_type('/usr/bin/perl');
    print $type->mime_type;
    print $type->comment;

=head1 METHODS

=cut

=head2 C<< $type->aliases >>

Reference to the aliases of this type

=cut

has 'aliases' => (
    is => 'ro',
    default => sub {[]},
);

=head2 C<< $type->comment >>

Array reference of the type description in various languages
(currently unused)

=cut

has 'comment' => (
    is => 'ro',
);

=head2 C<< $type->mime_type >>

    print "Content-Type: " . $type->mime_type . "\r\n";

String of the content type

=cut

has 'mime_type' => (
    is => 'ro',
);

=head2 C<< $type->globs >>

    print $_ for @{ $type->globs };

Arrayref of the wildcard globs of this type

=cut

has 'globs' => (
    is => 'ro',
    default => sub {[]},
);

sub _get_extension( $e=undef ) {
    if( defined $e ) { $e =~ s!^\*\.!! };
    $e
}

sub _globmatch( $target, $glob ) {
    $glob =~ s!([.+\\])!\\$1!g;
    $glob =~ s!\*!.*!g;
    $target =~ /\A$glob\z/;
}

=head2 C<< $type->extension >>

    print $type->extension; # pl

Returns the default extension for this mime type, without a separating
dot or the glob.

=cut

sub extension($self) { 
    _get_extension( $self->globs->[0] );
}

=head2 C<< $type->valid_extension( $fn ) >>

    print "$fn has the wrong extension"
        unless $type->valid_extension( $fn );

Returns whether C<$fn> matches one of the extensions
as specified in C<globs>. If there is a match, the extension is returned
without dot.

=cut

sub valid_extension( $self, $fn ) {
    _get_extension((grep {
        _globmatch( $fn, $_ )
    } @{ $self->globs })[0])
}

=head2 C<< $type->priority >>

    print $type->priority;

Priority of this type. Types with higher priority
get tried first when trying to recognize a file type.

The default priority is 50.

=cut

has 'priority' => (
    is => 'ro',
    default => 50,
);

has 'rules' => (
    is => 'ro',
    default => sub { [] },
);

=head2 C<< $type->superclass >>

    my $sc = $type->superclass;
    print $sc->mime_type;

The notional superclass of this file type. Note that superclasses
don't necessarily match the same magic numbers.

=cut

has 'superclass' => (
    is => 'rw',
    default => undef,
);

sub BUILD($self, $args) {
    # Preparse the rules here:
    for my $rule (@{ $args->{rules} }) {
        my $value = $rule->{value};

        # This should go into the part reading the XML, not into the part
        # evaluating the rules
        if( ref $rule eq 'HASH' and $rule->{type} eq 'string' ) {
            my %replace = (
                'n' => "\n",
                'r' => "\r",
                't' => "\t",
                "\\" => "\\",
            );
            $value =~ s{\\([nrt\\]|([0-7][0-7][0-7])|x([0-9a-fA-F][0-9a-fA-F]))}
                       { $replace{$1} ? $replace{$1} 
                       : $2 ? chr(oct($2))
                       : $3 ? chr(hex($3))
                       : $1
                       }xge;

        } elsif( ref $rule eq 'HASH' and $rule->{type} eq 'little32' ) {
            $value = pack 'V', hex($rule->{value});

        } elsif( ref $rule eq 'HASH' and $rule->{type} eq 'little16' ) {
            $value = pack 'v', hex($rule->{value});

        } elsif( ref $rule eq 'HASH' and $rule->{type} eq 'big32' ) {
            $value = pack 'N', hex($rule->{value});

        } elsif( ref $rule eq 'HASH' and $rule->{type} eq 'big16' ) {
            $value = pack 'n', hex($rule->{value});

        } elsif( ref $rule eq 'HASH' and $rule->{type} eq 'host16' ) {
            $value = pack 'S', hex($rule->{value});

        } elsif( ref $rule eq 'HASH' and $rule->{type} eq 'host32' ) {
            $value = pack 'L', hex($rule->{value});

        } elsif( ref $rule eq 'HASH' and $rule->{type} eq 'byte' ) {
            $value = pack 'c', hex($rule->{value});

        } else {
            die "Unknown rule type '$rule->{type}'";
        };

        $rule->{type} = 'string';
        $rule->{value} = $value;
    }
}

sub compile($self,$fragment) {
    die "No direct-to-Perl compilation implemented yet.";
}

=head2 C<< $type->matches $buffer >>

    my $buf = "PK\003\004"; # first four bytes of file
    if( $type->matches( $buf ) {
        print "Looks like a " . $type->mime_type . " file";
    };

=cut

sub matches($self, $buffer, $rules = $self->rules) {
    my @rules = @$rules;

    # Superclasses are for information only
    #if( $self->superclass and $self->superclass->mime_type !~ m!^text/!) {
    #    return if ! $self->superclass->matches($buffer);
    #};

    if( !ref $buffer) {
        # Upgrade to an in-memory filehandle
        my $_buffer = $buffer;
        open my $fh, '<', \$_buffer
            or die "Couldn't open in-memory handle!";
        binmode $fh;
        $buffer = MIME::Detect::Buffer->new(fh => $fh);
    };

    # Hardcoded rule for plain text detection...
    if( $self->mime_type eq 'text/plain') {
        my $buf = $buffer->request(0,256);
        return $buf !~ /[\x00-\x08\x0b\x0c\x0e-\x1f]/;
    };

    my $matches;
    for my $rule (@rules) {

        my $value = $rule->{value};

        my $buf = $buffer->request($rule->{offset}, length $value);
        #use Data::Dumper;
        #$Data::Dumper::Useqq = 1;
        no warnings ('uninitialized', 'substr');
        if( $rule->{offset} =~ m!^(\d+):(\d+)$! ) {
            #warn sprintf "%s: index match %d:%d for %s", $self->mime_type, $1,$2, Dumper $value;
            #warn Dumper substr( $buf, 0, ($2-$1)+length($value));
            $matches = $matches || 1+index( substr( $buf, 0, ($2-$1)+length($value)), $value );
        } else {
            #warn sprintf "%s: substring match %d for %s", $self->mime_type, $rule->{offset}, Dumper $value;
            #warn Dumper substr( $buf, $rule->{offset}, length($value));
            $matches = $matches || substr( $buf, 0, length($value)) eq $value;
        };
        $matches = $matches && $self->matches( $buffer, $rule->{and} ) if $rule->{and};

        last if $matches;
    };
    !!$matches
}

1;

=head1 REPOSITORY

The public repository of this module is 
L<http://github.com/Corion/filter-signatures>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Filter-signatures>
or via mail to L<filter-signatures-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2015-2016 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
