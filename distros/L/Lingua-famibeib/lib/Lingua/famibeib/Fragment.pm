# Copyright (c) 2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module to interact with the famibeib fragments


package Lingua::famibeib::Fragment;

use v5.16;
use strict;
use warnings;

use Carp;

use Lingua::famibeib::Word;

our $VERSION = v0.02;

use parent 'Data::Identifier::Interface::Subobjects';


sub new {
    my ($pkg, $type, $value, @opts) = @_;
    my @words;
    my $self = bless {words => \@words}, $pkg;

    croak 'Stray options passed' if scalar @opts;
    croak 'No type given' unless defined $type;
    croak 'No value given' unless defined $value;

    if ($type eq 'words') {
        foreach my $word (@{$value}) {
            push(@words, Lingua::famibeib::Word->new(from => $word));
        }
    } else {
        croak 'Bad type: '.$type;
    }

    return $self;
}


sub words {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return @{$self->{words}};
}


sub as_string {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return $self->{string} //= join(' ', @{$self->{words}});
}

# ---- Private helpers ----

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::famibeib::Fragment - module to interact with the famibeib fragments

=head1 VERSION

version v0.02

=head1 SYNOPSIS

    use Lingua::famibeib::Fragment;

This module inherits from L<Data::Identifier::Interface::Subobjects>.

=head2 new

    my Lingua::famibeib::Fragment $fragment = Lingua::famibeib::Fragment->new($type => $value);
    # e.g.:
    my Lingua::famibeib::Fragment $fragment = Lingua::famibeib::Fragment->new(words => [...]);

(since v0.01)

Creates a new fragment instance.
A fragment is any string of words.

Currently the following types (C<$type>) are supported:

=over

=item C<words>

Constructs a fragment from an arrayref of words (instances of L<Lingua::famibeib::Word>, or parsed as per L<Lingua::famibeib::Word/new>'s C<from>).

=back

=head2 words

    my @words = $fragment->words;

(since v0.01)

Returns the list of words as found in the fragment.

=head2 as_string

    my $str = $fragment->as_string;

(since v0.01)

Returns the current fragment as a string.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
