package Dreamhack::Solitaire;
use 5.008001;
use strict;
use warnings;

use List::Util qw(shuffle);
use List::MoreUtils 0.413 qw(uniq singleton);

our $VERSION = "0.01";

our @suits = ('s','c','d','h');
our @valence = ('A','K','Q','J','10','9','8','7','6');

sub new {
    my $class   = shift;
    my %args = @_;
    my @check = ();
    my @errors = ();

    if (exists $args{'suits'} && (ref $args{'suits'} eq 'ARRAY')) {
        @suits = @{$args{'suits'}}
    }
    elsif (exists $args{'lang'}) {
        if (lc($args{'lang'}) eq 'ru_ru.utf8') {
            @suits = ('п','к','б','ч');
            @valence = ('Т','К','Д','В','10','9','8','7','6');
        }
    }

    @check = uniq @suits;
    unless ($#check == $#suits) {
        die 'Duplicate suits';
    }

    if (exists $args{'valence'} && (ref $args{'valence'} eq 'ARRAY')) {
        @valence = @{$args{'valence'}}
    }

    @check = uniq @valence;
    unless ($#check == $#valence) {
        die 'Duplicate valence';
    }

    my @deck = ();
    my %complex = ();

    for my $suit (@suits) {
        for my $valence (@valence) {
            push @deck, $valence.$suit;
            $complex{$valence.$suit} = [$valence,$suit];
        }
    }

    my $self = {
        suits => \@suits,
        valence => \@valence,
        deck => \@deck,
        layout => [],
        leftcards => \@deck,
        complex => \%complex,
        convolution => [],
        attempts => undef,
        errors => \@errors,
    };

    bless $self, $class;
    return $self
}

sub init_layout {
    my ($self, $layout) = @_;

    unless ($layout && (ref $layout eq 'ARRAY')) {
        die 'Not an arrayref for layout';
    }

    if ($#$layout > $#{$self->{deck}}) {
        die 'Initial layout too long: ' . (1 + $#$layout) . ' cards';
    }

    my @cards = ();
    map {s/\?//} @$layout;
    for (@$layout) {
        if ($_) {
            push @cards, $_;
        }
    }

    my @test = uniq @cards;
    unless ($#test == $#cards) {
        die 'Duplicate cards in layout';
    }

    for my $card (@cards) {
        unless (grep {$card eq $_} @{$self->{'deck'}}) {
            die "Bad card in layout: $card";
        }
    }

    $self->{'layout'} = $layout;

    my @diff = singleton(@{$self->{'deck'}}, @{$self->{'layout'}});
    $self->{'leftcards'} = \@diff;

    return $self
}

sub parse_init_string {
    my ($self, $string) = @_;
    my @layout = split /[\[\]\s\n]+/, $string;
    @layout = grep {$_} @layout;
    return wantarray ? @layout : \@layout;
}

sub extract {
    my ($self, $str) = @_;
    my ($valence, $suit) = @{${$self->{'complex'}}{$str}};
    return ($valence, $suit)
}

sub add_rnd_layout {
    my ($self, ) = @_;
    my @cards = shuffle @{$self->{'leftcards'}};

    my @layout = ();
    for my $card (@{$self->{'layout'}}) {
        if ($card) {
            push @layout, $card;
        }
        else {
            push @layout, shift @cards;
        }
    }
    @layout = (@layout, @cards);

    return @layout
}

sub format {
    my ($self, ) = @_;
    my $string = '[';
    my @layout = @{$self->{'layout'}};
    my @convolution = @{$self->{'convolution'}};

    my $index = 0;
    my $convolution = shift @convolution;
    while (my $card = shift @layout) {
        $string .= $card;
        if ((defined $convolution) && ($convolution == $index++)) {
            $string .= "]\n";
            $convolution = shift @convolution;
            $string .= '[' if $convolution;
        }
        else {
            $string .= " ";
        }
    }
    return $string
}

1;
__END__

=encoding utf-8

=head1 NAME

Dreamhack::Solitaire - base class for Dreamhack::Solitaire::Medici and (possible) for other modules (in future)

=head1 SYNOPSIS

    use Dreamhack::Solitaire;

=head1 DESCRIPTION

Do not use it directly. See documentation for Dreamhack::Solitaire::Medici module instead.

=head1 LICENSE

Copyright (C) gugo.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

gugo E<lt>gugo@cpan.orgE<gt>

=cut

