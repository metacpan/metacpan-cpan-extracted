# Copyright (c) 2026 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module to interact with the words of Toki Pona


package Lingua::TokiPona::Word;

use v5.20;
use strict;
use warnings;

use Carp;
use Data::Identifier;
use Data::Identifier::Generate;
use Data::Displaycolour;

our $VERSION = v0.01;

use parent qw(Data::Identifier::Interface::Known Data::Identifier::Interface::Subobjects Data::Identifier::Interface::Simple);

use overload (
    '""'    => \&as_string,
    'eq'    => sub {  $_[0]->eq($_[1]) },
    'ne'    => sub { !$_[0]->eq($_[1]) },
    'cmp'   => sub {  $_[0]->cmp($_[1]) },
);

my %_words;
my %_by_ise;

__PACKAGE__->_new($_) foreach qw(
    a kin akesi ala alasa ale ali anpa ante anu awen e en esun ijo ike ilo insa jaki jan
    jelo jo kala kalama kama kasi ken kepeken kili kiwen ko kon kule kulupu kute la lape
    laso lawa len lete li lili linja lipu loje lon luka lukin oko lupa ma mama mani meli
    mi mije moku moli monsi mu mun musi mute nanpa nasa nasin nena ni nimi noka o olin ona
    open pakala pali palisa pan pana pi pilin pimeja pini pipi poka poki pona pu sama seli
    selo seme sewi sijelo sike sin namako sina sinpin sitelen sona soweli suli suno supa suwi
    tan taso tawa telo tenpo toki tomo tu unpa uta utala walo wan waso wawa weka wile
);

__PACKAGE__->new(string => 'loje'  )->Data::Displaycolour::mark(for => Data::Identifier->new(uuid => 'c9ec3bea-558e-4992-9b76-91f128b6cf29')); # red
__PACKAGE__->new(string => 'jelo'  )->Data::Displaycolour::mark(for => Data::Identifier->new(uuid => '2892c143-2ae7-48f1-95f4-279e059e7fc3')); # yellow
__PACKAGE__->new(string => 'laso'  )->Data::Displaycolour::mark(for => Data::Identifier->new(uuid => 'abcbf48d-c302-4be1-8c5c-a8de4471bcbb')); # cyan
__PACKAGE__->new(string => 'walo'  )->Data::Displaycolour::mark(for => Data::Identifier->new(uuid => '1a2c23fa-2321-47ce-bf4f-5f08934502de')); # white
__PACKAGE__->new(string => 'pimeja')->Data::Displaycolour::mark(for => Data::Identifier->new(uuid => 'fade296d-c34f-4ded-abd5-d9adaf37c284')); # black


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
            } elsif ($value->isa('Data::Identifier')) {
                $type = 'Data::Identifier';
            } else {
                $type = 'Data::Identifier';
                $value = Data::Identifier->new(from => $value);
            }
        } else {
            $type = 'string';
        }
    }

    if ($type eq 'string') {
        return $_words{lc $value} // croak 'No such word';
    } elsif ($type eq 'Data::Identifier') {
        return $_by_ise{$value->uuid(default => undef, no_defaults => 1) // $value->ise} // croak 'No such word';
    } else {
        croak 'Bad type: '.$type;
    }
}


sub as_string {
    my ($self) = @_;
    return $self->{string};
}


sub eq {
    my ($self, $other, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return 1 if !defined($self) && !defined($other);
    return undef unless defined($self) && defined($other);

    $self  = __PACKAGE__->new(from => $self) unless eval {$self->isa(__PACKAGE__)};
    $other = __PACKAGE__->new(from => $other) unless eval {$other->isa(__PACKAGE__)};

    return $self->as_string eq $other->as_string;
}


sub cmp {
    my ($self, $other, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return 1 if !defined($self) && !defined($other);
    return undef unless defined($self) && defined($other);

    $self  = __PACKAGE__->new(from => $self) unless eval {$self->isa(__PACKAGE__)};
    $other = __PACKAGE__->new(from => $other) unless eval {$other->isa(__PACKAGE__)};

    {
        my $str_self  = $self->as_string;
        my $str_other = $other->as_string;

        return $str_self cmp $str_other;
    }

    croak 'BUG!';
}

# ---- Private helpers ----

#@returns __PACKAGE__
sub _new {
    my ($pkg, $str) = @_;
    my $self = bless {}, $pkg;
    my $id;

    $str = lc($str); # just to be on the safe side

    $self->{string} = $str;

    $id = Data::Identifier::Generate->generic(
        request => $str,
        displayname => $str,
        tagname => $str,
        style => 'id-based',
        namespace => '8d043e5e-b7da-4a37-a87a-26bb361288a1',
        generator => '45823114-5f38-47d8-a749-2e7f3ec819c3',
    )->register;

    $self->{id} = $id;

    $_words{$str} = $self;
    $_by_ise{$id->uuid} = $self;
    return $self;
}

sub as {
    my ($self, $as, @opts) = @_;
    my Data::Identifier $id = $self->{id};

    return $id if $as eq 'Data::Identifier' && scalar(@opts) == 0;
    return $id->as($as, @opts);
}

sub displayname {
    my ($self, @opts) = @_;
    return $self->as_string if scalar(@opts) == 0;
    return $self->{id}->displayname(@opts);
}

sub _known_provider {
    my ($pkg, $class, %opts) = @_;
    croak 'Unsupported options passed' if scalar(keys %opts);
    return ([values %_words], rawtype => __PACKAGE__) if $class eq ':all';
    croak 'Unsupported class';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::TokiPona::Word - module to interact with the words of Toki Pona

=head1 VERSION

version v0.01

=head1 SYNOPSIS

    use Lingua::TokiPona::Word;

    my Lingua::TokiPona::Word $word = Lingua::TokiPona::Word->new(string => 'mi');

    say $word->as_string;

This module inherits from
L<Data::Identifier::Interface::Known>,
L<Data::Identifier::Interface::Simple>,
and L<Data::Identifier::Interface::Subobjects>.

=head1 METHODS

=head2 new

    my Lingua::TokiPona::Word $word = Lingua::TokiPona::Word->new($type => $value);
    # e.g.:
    my Lingua::TokiPona::Word $word = Lingua::TokiPona::Word->new(string => 'mi');

(since v0.01)

Constructs a new word.
The word is normalised as part of this.
This method deduplicate instances.

Currently the following types (C<$type>) are supported:

=over

=item C<from>

(since v0.01)

Constructs a word from an object.
C<$value> should be a reference.

Currently references to the following types are supported:
L<Lingua::TokiPona::Word>,
or anything L<Data::Identifier/new> accepts via C<from>.
More types might be supported.

If C<$value> is not a reference the value is parsed as per C<string> if it looks like a word string (experimental since v0.01).

=item C<string>

(since v0.01)

Constructs a word from it's (latin) string representation.

=back

=head2 as_string

    my $str = $word->as_string;

(since v0.01)

Returns the string representation of the word.

=head2 eq

    my $bool = $word->eq($other); # $word must be non-undef
    # or:
    my $bool = Lingua::TokiPona::Word::eq($word, $other); # $word can be undef

(since v0.01)

Compares two words to be equal.

If both words are C<undef> they are considered equal.

If C<$word> or C<$other> is not an instance of L<Lingua::TokiPona::Word> or C<undef>
L</new> with the type C<from> is used.

The operators L<perlop/eq> and L<perlop/ne> are overloaded to this method.

=head2 cmp

    my $val = $word->cmp($other); # $word must be non-undef
    # or:
    my $val = Lingua::TokiPona::Word::cmp($word, $other); # $word can be undef

(experimental since v0.01)

Compares the words similar to C<cmp>. This method can be used to order words.
To check for them to be equal see L</eq>.

The parameters are parsed the same way as L</eq>.

The operator L<perlop/cmp> is overloaded to this method.

If this method is used for sorting the exact resulting order is not defined. However:

=over

=item *

The order is stable

=item *

The order is the same for C<$a-E<gt>cmp($b)> as for C<- $b-E<gt>cmp($a)>.

=back

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
