# Copyright (c) 2026 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module to interact with words foreign to famibeib


package Lingua::famibeib::ForeignWord;

use v5.16;
use strict;
use warnings;

use Carp;

our $VERSION = v0.07;

use parent qw(Lingua::famibeib::Word);


sub new {
    my ($pkg, $type, $value, @opts) = @_;
    my $self = bless {}, $pkg;

    croak 'Stray options passed' if scalar @opts;
    croak 'No type given' unless defined $type;
    croak 'No value given' unless defined $value;

    if ($type eq 'string') {
        if ($value =~ /^to./i) {
            $value =~ s/^[Tt][Oo]/to/; # enforce lower case
            $self->{stem} = ':self';
            $self->{modifiers} = {};
            $self->{string} = $value;
        } else {
            croak 'Bad word, did you mean to call Lingua::famibeib::Word->new()?';
        }
    } else {
        croak 'Bad type: '.$type;
    }

    return $self;
}


sub combine {
    croak 'Combining foreign words is not supported';
}


sub as {
    my ($self, $as, @opts) = @_;
    if (scalar(@opts) == 0) {
        if ($self->isa($as)) {
            return $self;
        } elsif ($as eq 'Lingua::TokiPona::Word') {
            require Lingua::TokiPona::Word;
            return Lingua::TokiPona::Word->new(string => substr($self->as_string, 2));
        }
    }
    confess 'Not supported';
}

# ---- Private helpers ----

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::famibeib::ForeignWord - module to interact with words foreign to famibeib

=head1 VERSION

version v0.07

=head1 SYNOPSIS

    use Lingua::famibeib::Word;

    my Lingua::famibeib::Word $word = Lingua::famibeib::Word->new(string => 'toXyz');

    my $str = $word->as_string;

(since v0.06)

This package is used to store individual foreign words and query them about their properties.

This module inherits from L<Lingua::famibeib::Word>.
Most of it's methods do work on this type of words, however not all of them.

=head1 METHODS

=head2 new

    my Lingua::famibeib::Word $word = Lingua::famibeib::Word->new(...);

To construct a foreign word the normal word constructor should be used.

=head2 combine

    ... $word->combine(...);

This method is not supported for foreign words as such words cannot be combined.

=head2 as

    my $obj = $word->as($as);

This method is much more limited on foreign words as it cannot create a L<Data::Identifier>.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025-2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
