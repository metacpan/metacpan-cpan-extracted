# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module to interact with the famibeib texts


package Lingua::famibeib::Text;

use v5.16;
use strict;
use warnings;

use Carp;
use List::Util qw(any);

use Lingua::famibeib::Word;
use Lingua::famibeib::Fragment;
use Lingua::famibeib::Sentence;

our $VERSION = v0.01;

use parent 'Data::Identifier::Interface::Subobjects';

my @_sentence_ends = map {Lingua::famibeib::Word->new(string => $_)->register} qw(ba be bi bo);


sub new {
    my ($pkg, @opts) = @_;
    my $self = bless {fragments => [], words => [], queue => ''}, $pkg;

    croak 'Stray options passed' if scalar @opts;

    return $self;
}


sub fragments {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return @{$self->{fragments}};
}


sub parse_string {
    my ($self, $str, @opts) = @_;
    my $words = $self->{words};
    my $queue;

    croak 'Stray options passed' if scalar @opts;
    croak 'No string given' unless defined $str;

    # First parse string into words:
    $queue = $self->{queue}.' '.$str;
    $self->{queue} = '';

    foreach my $wstr (split/[\s\r\n]/, $queue) {
        my ($prefix, $ws, $suffix) = $wstr =~ /^([^bfklmst]*)((?:[bfklmst][aeiou]|[aeiou][bfklmst])*)([^bfklmstaeiou]*)$/;
        push(@{$words}, $prefix) if defined($prefix) && length($prefix);
        push(@{$words}, Lingua::famibeib::Word->new(string => $ws)) if defined($ws) && length($ws);
        push(@{$words}, $suffix) if defined($suffix) && length($suffix);
    }

    # Now try to convert words into fragments:
    outer:
    while (scalar @{$words}) {
        for (my $i = 0; $i < scalar(@{$words}); $i++) {
            my $w = $words->[$i];

            if (!ref($w)) {
                push(@{$self->{fragments}}, Lingua::famibeib::Fragment->new(words => [splice(@{$words}, 0, $i)]));
                push(@{$self->{fragments}}, shift(@{$words}));
                next outer;
            } elsif ($w->is_application && any {$w->eq($_)} @_sentence_ends) {
                my $f = Lingua::famibeib::Fragment->new(words => [splice(@{$words}, 0, $i + 1)]);
                eval { Lingua::famibeib::Sentence->_upgrade($f) };
                push(@{$self->{fragments}}, $f);
                next outer;
            }
        }

        last;
    }

    return $self;
}


sub parse_done {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    $self->parse_string(''); # flush all buffers

    croak 'BUG' if length($self->{queue});

    if (scalar @{$self->{words}}) {
        push(@{$self->{fragments}}, Lingua::famibeib::Fragment->new(words => $self->{words}));
        $self->{words} = [];
    }

    return $self;
}


sub as_string {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return join(' ', map {ref ? $_->as_string : $_ } @{$self->{fragments}});
}

# ---- Private helpers ----

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::famibeib::Text - module to interact with the famibeib texts

=head1 VERSION

version v0.01

=head1 SYNOPSIS

    use Lingua::famibeib::Text;

    my Lingua::famibeib::Text $text = Lingua::famibeib::Text->new;

    $text->parse_string('baba fafoof ba');
    $text->parse_done;

    my @fragments = $text->fragments;

This module is used to store and parse larger blocks of text.

This module inherits from L<Data::Identifier::Interface::Subobjects>.

=head2 new

    my Lingua::famibeib::Text $text = Lingua::famibeib::Text->new;

(since v0.01)

Creates a new text object. No options are currently supported.

=head2 fragments

    my @fragments = $text->fragments;

(since v0.01)

Returns all complete fragments.

Each element returned is a L<Lingua::famibeib::Fragment> or a plain string.
Plain strings are returned for parts the parser could not make sense of.

=head2 parse_string

    $text->parse_string($string);

(since v0.01)

Parses a string and adds it to the input queue.
It is fine for the string to contain incomplete sentences.
However, it is not permitted to contain incomplete words.

This method can be called over and over again to add more text.

The parser will try to split the string into useful fragments (sentences),
but might generate smaller fragments if can't do it for some reason.

B<Note:>
The input string (C<$string>) must be a plain perl string, not a byte string.
If you need to apply any encoding you must do this before.

Returns C<$text> (experimental since v0.01).

=head2 parse_done

    $text->parse_done;

(since v0.01)

Tell the parser that parsing is done and all buffers should be flushed.
Without calling this not all of the parsed text might be visible.

It is possible restart parsing new text.
In that case the next text will not have any overlapping fragments with the last parse run.

Returns C<$text> (experimental since v0.01).

=head2 as_string

    my $str = $text->as_string;

(since v0.01)

Returns the current text as a string.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
