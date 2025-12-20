# Copyright (c) 2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module to interact with the famibeib sentences


package Lingua::famibeib::Sentence;

use v5.16;
use strict;
use warnings;

use Carp;
use List::Util qw(any);

our $VERSION = v0.02;

use parent 'Lingua::famibeib::Fragment';

use constant {
    TYPE_STATEMENT      => Lingua::famibeib::Word->new(string => 'ba')->register,
    TYPE_QUESTION       => Lingua::famibeib::Word->new(string => 'be')->register,
    TYPE_COMMAND        => Lingua::famibeib::Word->new(string => 'bi')->register,
    TYPE_EXCLAMATION    => Lingua::famibeib::Word->new(string => 'bo')->register,
};

my @_sentence_ends = (TYPE_STATEMENT, TYPE_QUESTION, TYPE_COMMAND, TYPE_EXCLAMATION);

sub new {
    my ($pkg, @opts) = @_;
    return __PACKAGE__->_upgrade($pkg->SUPER::new(@opts));
}


sub type {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return $self->{type};
}


sub is_statement {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return $self->{type}->eq(TYPE_STATEMENT);
}


sub is_question {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return $self->{type}->eq(TYPE_QUESTION);
}


sub is_command {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return $self->{type}->eq(TYPE_COMMAND);
}


sub is_exclamation {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return $self->{type}->eq(TYPE_EXCLAMATION);
}


sub main_verb {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return $self->{main_verb};
}

# ---- Private helpers ----

sub _upgrade {
    my ($pkg, $self) = @_;
    my $words = $self->{words};
    my $type = $words->[-1];
    my $sublevel = 0;
    my $main_verb;

    croak 'Not a sentence, bad type: '.$type unless any {$type->eq($_)} @_sentence_ends;

    for (my $i = 0; $i < (scalar(@{$words}) - 1); $i++) {
        my $word = $words->[$i];

        if ($word->is_verb && $sublevel == 0) {
            $main_verb //= $word;
        } elsif ($word->is_application && any {$word->eq($_)} @_sentence_ends) {
            croak 'Not a well formed sentence: inner sentence type found: '.$word;
        } elsif ($word->as_string =~ /^tus/ && $word->is_application) {
            $sublevel++;
        } elsif ($word->as_string =~ /^tut/ && $word->is_application) {
            $sublevel--;
        }
    }

    $self->{type} = $type;
    $self->{main_verb} = $main_verb;

    bless($self, $pkg);

    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::famibeib::Sentence - module to interact with the famibeib sentences

=head1 VERSION

version v0.02

=head1 SYNOPSIS

    use Lingua::famibeib::Sentence;

This module implements a fragment that is a peroper well formed sentence.
This is ensured at construction time.

This module inherits from L<Lingua::famibeib::Fragment>.

=head2 type

    my Lingua::famibeib::Word $type = $sentence->type;

(since v0.01)

Returns the type of the sentence as a L<Lingua::famibeib::Word>.

=head2 is_statement

    my $bool = $sentence->is_statement;

(since v0.01)

Returns whether the sentence is a statment (C<tubaik>).

=head2 is_question

    my $bool = $sentence->is_question;

(since v0.01)

Returns whether the sentence is a question (C<tubeik>).

=head2 is_command

    my $bool = $sentence->is_command;

(since v0.01)

Returns whether the sentence is a command (C<tubiik>).

=head2 is_exclamation

    my $bool = $sentence->is_exclamation;

(since v0.01)

Returns whether the sentence is an exclamation (C<tuboik>).

=head2 main_verb

    my Lingua::famibeib::Word $main_verb = $sentence->main_verb;

(since v0.01)

Returns the main verb of the sentence as a L<Lingua::famibeib::Word>.

B<Note:>
This method requires a well formed sentence to work correctly.
For non-well formed sentences the wrong verb might be returned.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
