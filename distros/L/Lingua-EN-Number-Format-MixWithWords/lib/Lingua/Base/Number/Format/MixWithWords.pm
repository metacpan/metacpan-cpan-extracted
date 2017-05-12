package Lingua::Base::Number::Format::MixWithWords;

our $DATE = '2016-06-14'; # DATE
our $VERSION = '0.08'; # VERSION

use 5.010;
use strict;
use warnings;

use Math::Round qw(nearest);
use Number::Format;
use POSIX qw(floor ceil log10);

our %SPEC;

sub new {
    my ($class, %args) = @_;
    $args{min_fraction} //= 1;
    $args{min_format}   //= 1000000;

    die "Invalid min_fraction, must be 0 < x <= 1"
        unless $args{min_fraction} > 0 && $args{min_fraction} <= 1;
    $args{_nf} = Number::Format->new(
        THOUSANDS_SEP => $args{thousands_sep},
        DECIMAL_POINT => $args{decimal_point},
    );
    $args{powers} = [sort {$a<=>$b} keys %{$args{names}}];
    bless \%args, $class;
}

sub _format {
    my ($self, $num) = @_;
    return undef unless defined $num;

    if (defined $self->{num_decimal}) {
        $num = nearest(10**-$self->{num_decimal}, $num);
    }
    my ($exp, $mts, $exp_f);
    my $anum = abs($num);
    if ($anum) {
        $exp   = floor(log10($anum));
        $mts   = $anum / 10**$exp;
        $exp_f = floor(log10($anum/$self->{min_fraction}));
    } else {
        $exp   = 0;
        $mts   = 0;
        $exp_f = 0;
    }

    my $p;
    my ($res_n, $res_w);
    for my $i (0..@{$self->{powers}}-1) {
        last if $self->{powers}[$i] > $exp_f;
        $p = $self->{powers}[$i];
    }
    if (defined($p) && $anum >= $self->{min_format}*$self->{min_fraction}) {
        $res_n = $mts * 10**($exp-$p);
        $res_w = $self->{names}{$p};
    } else {
        $res_n = $anum;
        $res_w = "";
    }
    # N::F has a limit of 15 num_decimals
    my $e = ceil(log10($res_n)); $e = 0 if $e < 0;
    my $def_nd = 15 - $e; $def_nd = 0 if $def_nd < 0;
    my $nd = $self->{num_decimal} // 15; $nd = 0 if $nd < 0;
    $nd = $def_nd if $nd > $def_nd;
    #print "res_n=$res_n, nd=$nd\n";

    $res_n = $e > 15 ? $res_n : $self->{_nf}->format_number($res_n, $nd);

    ($num < 0 ? "-" : "") . $res_n . ($res_w ? " $res_w" : "");
}

1;
# ABSTRACT: Base class for Lingua::XX::Number::Format::MixWithWords

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Base::Number::Format::MixWithWords - Base class for Lingua::XX::Number::Format::MixWithWords

=head1 VERSION

This document describes version 0.08 of Lingua::Base::Number::Format::MixWithWords (from Perl distribution Lingua-EN-Number-Format-MixWithWords), released on 2016-06-14.

=for Pod::Coverage ^(new)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Lingua-EN-Number-Format-MixWithWords>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Lingua-EN-Number-Format-MixWithWords>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Lingua-EN-Number-Format-MixWithWords>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
