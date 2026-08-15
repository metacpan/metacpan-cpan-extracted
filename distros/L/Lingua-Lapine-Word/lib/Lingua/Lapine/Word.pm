# Copyright (c) 2026 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module to interact with the words of Lapine


package Lingua::Lapine::Word;

use v5.20;
use strict;
use warnings;

use Carp;
use Data::Identifier v0.34;

our $VERSION = v0.01;

use parent qw(Data::Identifier::Interface::Known Lingua::Generic::Interface::Word);

use constant {
    WK_LT_LAPINE    => Data::Identifier->new(uuid => '8ca63437-1b1e-4a85-8512-02ba5c15a412', displayname => 'Lapine')->register,
};

my %_registered_by_string;

my @_wellknown_words = map {__PACKAGE__->new(string => $_)->register} (
    qw(elil embleer flay flayrah Frith fu hlao hlessi homba hrair hraka hrududu lendri marli narn Ni-Frith owsla owslafa pfeffa rah roo silf tharn thlay threar vair yona zorn), # generic
    qw(Efrafa El-ahrairah Hlao-roo Hrairoo Hyzenthlay Nildro-hain Sayn Thethuthinnang Thlayli), "Inl\N{LATIN SMALL LETTER E WITH ACUTE}", # names
);


# Not our actual constructor, see _new(). This is for the public API only
sub new {
    my ($pkg, $type, $value, @opts) = @_;

    croak 'No type given' unless defined $type;
    croak 'No value given' unless defined $value;
    croak 'Stray options passed' if scalar @opts;

    if ($type eq 'from') {
        if (ref $value) {
            if ($value->isa(__PACKAGE__)) {
                return $value;
            } else {
                ...
            }
        } else {
            $type = 'string';
        }
    }

    if ($type eq 'string') {
        $value =~ s/^inle\z/Inl\N{LATIN SMALL LETTER E WITH ACUTE}/i; # normalise name
        return $_registered_by_string{fc $value} // $pkg->SUPER::new(string => $value);
    } else {
        croak 'Bad type: '.$type;
    }
}


#@returns Data::Identifier
sub natural_language {
    my ($self) = @_;
    return WK_LT_LAPINE;
}


#@returns __PACKAGE__
sub register {
    my ($self) = @_;

    $_registered_by_string{fc $self->as_string} //= $self;

    return $self;
}

# ---- Overridden methods ----



# ---- Private helpers ----


sub _known_provider {
    my ($pkg, $class, %opts) = @_;

    croak 'Unsupported options passed' if scalar(keys %opts);

    if ($class eq 'word') {
        return (\@_wellknown_words, rawtype => __PACKAGE__);
    } elsif ($class eq ':all') {
        return ([
                @_wellknown_words,
                WK_LT_LAPINE,
            ], rawtype => 'Data::Identifier::Interface::Simple');
    }

    croak 'Unsupported class';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Lapine::Word - module to interact with the words of Lapine

=head1 VERSION

version v0.01

=head1 SYNOPSIS

    use Lingua::Lapine::Word;

    my Lingua::Lapine::Word $word = Lingua::Lapine::Word->new(string => 'mi');

    say $word->as_string;

This module inherits from
L<Lingua::Generic::Interface::Word> (since v0.01),
and L<Data::Identifier::Interface::Known> (since v0.01).

=head1 METHODS

=head2 new

    my Lingua::Lapine::Word $word = Lingua::Lapine::Word->new($type => $value);
    # e.g.:
    my Lingua::Lapine::Word $word = Lingua::Lapine::Word->new(string => 'Frith');

(since v0.01)

Constructs a new word.
This method deduplicate instances.

Currently the following types (C<$type>) are supported:

=over

=item C<from>

(since v0.01)

Constructs a word from an object.
C<$value> should be a reference.

Currently references to the following types are supported:
L<Lingua::Lapine::Word>.
More types might be supported.

If C<$value> is not a reference the value is parsed as per C<string> if it looks like a word string (experimental since v0.01).

=item C<string>

(since v0.01)

Constructs a word from it's string representation.

=back

=head2 natural_language

    my Data::Identifier $natural_language = $word->natural_language;

(since v0.03)

Returns the natural language this word is in.

For Lapine words it will always return Lapine.
However this method might be useful together with other modules from the C<Lingua> namespace.

See also: L<Lingua::Generic::Interface::Word/natural_language>.

=head2 register

    $word->register;

(since v0.01)

Registers the word with this module.
A registered word will be kept in memory indefinitely.
It is used for deduplication and some types of lookups.

This method will return C<$word>.
This can be used to build constants.

B<Note:>
Calling this multiple times on the same word is fine.
However, doing so might waste some time.

B<Note:>
It is undefined (since v0.01) whether or not this will also register
the corresponding L<Data::Identifier>.

=head2 known

    my @list = Lingua::Lapine::Word->known($class [, %opts ] );

(since v0.01)

Returns the known items for the given class.

For details and supported options see L<Data::Identifier::Interface::Known/known>.

The following classes are supported:

=over

=item C<:all>

(since v0.01)

Returns all known things.

=item C<word>

(since v0.01)

Returns all known words.

=back

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
