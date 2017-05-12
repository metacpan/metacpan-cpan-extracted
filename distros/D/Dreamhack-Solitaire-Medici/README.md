# NAME

Dreamhack::Solitaire::Medici - Kit for Solitaire Medici

# SYNOPSIS

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

# DESCRIPTION

The Solitaire Medici, particular using by dreamhackers/stalkers for reality management.
Chain creation carried out by bruteforce method with max attempts count one hundred thousand (default) or your own value.
Starting layout between 0 and 36 cards.

# ABBR FOR DECK

- Suits 

    s - Spades

    c - Clubs

    d - Diamonds

    h - Hearts

- Valences

    A - Ace

    K - King

    Q - Queen

    J - Jack

    and 6, 7, 8, 9, 10

Example: Qs, 7d

# METHODS

- new \[ %options \]

    Constructor. Takes a hash with options as an argument.

        my $sol = Dreamhack::Solitaire::Medici->new(
            lang => 'ru_RU.utf8', # English if empty (default), Russian or another languages in future (may be), optional
            suits => ['_spades', '_clubs', '_diamonds', '_hearts'], # you own suits for deck, in this case lang ignored, optional
            valence => ['2','3','4','5','6','7','8','9','10',], # you own valences for deck, optional
        );

- init\_layout $arrayref

    Takes an array reference with starting layout as an argument. Arbitrary card in layout denoted as '?', or '', or null:

        $sol->init_layout([qw(? ? ? Qs)]);

- parse\_init\_string $string

    Auxiliary method. Converts layout string into an array for init\_layout. Symbols '\[' and '\]' - optional, marks the bounds of convolution.

        my @layout = $sol->parse_init_string('[Qd 7c 9s Qs Js][9d Ad Kd][8c 6s 10d 8s][Kc Qh 7s 6d 10s][Ah 6c 7h][7d As Jd][Ks][6h Jh Jc Qc 9h 9c][Kh][Ac][8h][10c][8d][10h]');
        $sol->init_layout(\@layout);

- process \[ %options \]

    Build the solitaire. Takes a hash with options as an argument. Returns self object if success or undef value otherwise.
    The result is placed into an array reference $sol->{'layout'}, committed number of attempts - into $sol->{'attempts'}.

        $sol->process(
            attempts => 500, # max number of attempts for build solitaire, optional, default 100000
        ) or die 'Cannot build solitaire, attempts count: ', $sol->{'attempts'};

- format

    Returns nice looking string for result printing.

        print $sol->format();

# LICENSE

Copyright (C) gugo.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

gugo &lt;gugo@cpan.org>
