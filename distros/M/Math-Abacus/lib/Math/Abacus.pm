package Math::Abacus;

use v5.10.0;
use Carp;
use feature 'say';

my $len = 10;

sub num_of_digit {
    $len = $_[1] || $len;
    return $len;
}

sub new {
    my ($class) = @_;
    my ($val) = ($_[1] =~ /(\d*)/);
    carp "Value extracted: $val.\n" if $_[1] !~ /^\d+$/;
    carp "The input value is smaller than the maximum length of the abacus.\n"
        if $val >= 10**$len;
    bless {
        _value => $val,
    }, $class;
}

sub value {
    return $_[0]->{_value};
}

sub add {
    my ($self, $v_add) = @_;
    croak "Only non-negative integer operation.\n" if $v_add !~ /^\d+$/;
    $self->{_value} += $v_add;
    carp "The input value is smaller than the maximum length of the abacus.\n"
        if $self->value >= 10**$len;
    return $self;
}

sub subtract {
    my ($self, $v_sub) = @_;
    croak "Only non-negative integer operation.\n" if $v_sub !~ /^\d+$/;
    $self->{_value} -= $v_sub;
    carp "The current value of the abacus is negative.\n"
        if $self->value < 0;
    return $self;
}

sub show {
    my ($self) = @_;
    $v = $self->value;
    _show(
        $v <= 0 ?
        0 :
        $v % (10**$len)
    );
}

sub _show {
    my $value = $_[0];
    my @digits = split "", $value;
    unshift @digits, (0) x ($len - scalar @digits);
    my @mod5dgts = map {$_ % 5} @digits;
    my $cross_line = join '-', ('+') x ($len+2);
    say $cross_line;
    say join " ", '|' , ('x') x $len, '|';
    say join " ", '|' , (map {$_ < 5 ? 'x' : '|' } @digits), '|';
    say join " ", '|' , (map {$_ < 5 ? '|' : 'x' } @digits), '|';
    say $cross_line;
    for my $o (0..5) {
        say join " ", '|' , (map {$_ == $o ? '|' : 'x' } @mod5dgts), '|';
    }
    say $cross_line;
}

=head1 NAME

Math::Abacus - A toy model of Chinese abacus

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    use Math::Abacus;

    Math::Abacus->num_of_digits(4);
    my $abacus = Math::Abacus->new(460);
    $abacus->add(1);
    $abacus->subtract(5);
    $abacus->show();

    # PRINT
    +-+-+-+-+-+
    | x x x x |
    | x x | | |
    | | | x x |
    +-+-+-+-+-+
    | | x | x |
    | x x x | |
    | x x x x |
    | x x x x |
    | x | x x |
    | x x x x |
    +-+-+-+-+-+


=head1 METHODS

=head2 show

=head2 add

=head2 subtract

=head1 AUTHOR

Cheok-Yin Fung, C<< <fungcheokyin at gmail.com> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Abacus


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Abacus>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Math-Abacus>

=item * Search CPAN

L<https://metacpan.org/release/Math-Abacus>

=back


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Cheok-Yin Fung.

This is free software, licensed under:

  MIT License (GPL Compatible)


=cut

1; # End of Math::Abacus
