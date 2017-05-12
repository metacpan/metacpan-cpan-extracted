package Dreamhack::Solitaire::Medici;
use 5.008001;
use strict;
use warnings;
no warnings 'recursion';

use base 'Dreamhack::Solitaire';
use Dreamhack::Solitaire;

our $VERSION = "0.01";

sub process {
    my ($self, %args) = @_;

    my $imax = (exists $args{'attempts'}) && ($args{'attempts'} =~ m/^[1-9]\d*$/) ? $args{'attempts'} : $self->_iterations(1+$#{$self->{'leftcards'}});

    for my $i (1..$imax) {

        my @layout = $self->add_rnd_layout();
        my @save = @layout;
        my @work = ();

        my $cardno = 0;
        while (@layout) {
            my $el = shift @layout;
            push @work, $el;
            @work = $self->_pass(0, \@work, $cardno++);
        }

        $self->{'attempts'} = $i;
        if ($#work <= 1) {
            $self->{'layout'} = \@save;
            return $self;
        }
        $self->{'convolution'} = [];
    }
    return undef;
}

sub _pass {
    my ($self, $offset, $work, $cardno) = @_;
    my @work = @$work;

    if (($offset >=0) && ($#work - $offset >= 2)) {
        my ($vr, $sr) = $self->extract($work[$#work - $offset]);
        my ($vl, $sl) = $self->extract($work[$#work - $offset - 2]);
        if (($vl eq $vr) or ($sl eq $sr)) {
            $work[$#work - $offset - 2] = $work[$#work - $offset - 1];
            splice @work, $#work - $offset - 1, 1;
            if ($cardno) {
                push @{$self->{'convolution'}}, $cardno;
            }
            @work = $self->_pass($#work-2, \@work);
        }
        else {
            @work = $self->_pass(--$offset, \@work);
        }
    }
    else {
        return @work
    }
    return @work
}

sub _iterations {
    my ($self, $cardscount) = @_;

    my $imax = 0;
    if ($cardscount <= 1) {
        $imax = 1;
    }
    else {
        $imax = 100_000;
    }
    return $imax
}

1;
__END__

=encoding utf-8

=head1 NAME

Dreamhack::Solitaire::Medici - Kit for Solitaire Medici

=head1 SYNOPSIS

    use Dreamhack::Solitaire::Medici;

    my $sol = Dreamhack::Solitaire::Medici->new();
    $sol->init_layout([qw(Jh ? Ac 10s ? ? Kd)]);
    $sol->process() or die 'Cannot build solitaire, attempts count: ', $sol->{'attempts'};

    print $sol->format();
    print "Attempts count: ", $sol->{'attempts'}, "\n";

or, for empty starting layout:

    print Dreamhack::Solitaire::Medici->new()->process()->format();

or, for russian programmers:

    print Dreamhack::Solitaire::Medici->new(lang=>'ru_RU.utf8')->process()->format();
    In this case you mast use cyrrilic cards abbr for init layout.

=head1 DESCRIPTION

The Solitaire Medici, particular using by dreamhackers/stalkers for reality management.
Chain creation carried out by bruteforce method with max attempts count one hundred thousand (default) or your own value.
Starting layout between 0 and 36 cards.

=head1 ABBR FOR DECK

=over

=item Suits 

s - Spades

c - Clubs

d - Diamonds

h - Hearts

=back

=over

=item Valences

A - Ace

K - King

Q - Queen

J - Jack

and 6, 7, 8, 9, 10

=back

Example: Qs, 7d

=head1 METHODS

=over

=item new [ %options ]

Constructor. Takes a hash with options as an argument.

    my $sol = Dreamhack::Solitaire::Medici->new(
        lang => 'ru_RU.utf8', # English if empty (default), Russian or another languages in future (may be), optional
        suits => ['_spades', '_clubs', '_diamonds', '_hearts'], # you own suits for deck, in this case lang ignored, optional
        valence => ['2','3','4','5','6','7','8','9','10',], # you own valences for deck, optional
    );

=back

=over

=item init_layout $arrayref

Takes an array reference with starting layout as an argument. Arbitrary card in layout denoted as '?', or '', or null:

    $sol->init_layout([qw(? ? ? Qs)]);

=back

=over

=item parse_init_string $string

Auxiliary method. Converts layout string into an array for init_layout. Symbols '[' and ']' - optional, marks the bounds of convolution.

    my @layout = $sol->parse_init_string('[Qd 7c 9s Qs Js][9d Ad Kd][8c 6s 10d 8s][Kc Qh 7s 6d 10s][Ah 6c 7h][7d As Jd][Ks][6h Jh Jc Qc 9h 9c][Kh][Ac][8h][10c][8d][10h]');
    $sol->init_layout(\@layout);

=back

=over

=item process [ %options ]

Build the solitaire. Takes a hash with options as an argument. Returns self object if success or undef value otherwise.
The result is placed into an array reference $sol->{'layout'}, committed number of attempts - into $sol->{'attempts'}.

    $sol->process(
        attempts => 500, # max number of attempts for build solitaire, optional, default 100000
    ) or die 'Cannot build solitaire, attempts count: ', $sol->{'attempts'};

=back

=over

=item format

Returns nice looking string for result printing.

    print $sol->format();

=back

=head1 LICENSE

Copyright (C) gugo.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

gugo <gugo@cpan.org>

=cut
