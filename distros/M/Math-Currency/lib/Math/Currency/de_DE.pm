package Math::Currency::de_DE;
$Math::Currency::de_DE::VERSION = '0.51';
# ABSTRACT: de_DE Locale Module for Math::Currency

use utf8;
use strict;
use warnings;
use Math::Currency qw($LC_MONETARY $FORMAT);
use base qw(Exporter Math::Currency);

our $LANG = 'de_DE';

$LC_MONETARY->{de_DE} = {
    CURRENCY_SYMBOL   => '€',
    FRAC_DIGITS       => '2',
    INT_CURR_SYMBOL   => 'EUR ',
    INT_FRAC_DIGITS   => '2',
    MON_DECIMAL_POINT => ',',
    MON_GROUPING      => '3',
    MON_THOUSANDS_SEP => '.',
    NEGATIVE_SIGN     => '-',
    N_CS_PRECEDES     => '0',
    N_SEP_BY_SPACE    => '1',
    N_SIGN_POSN       => '1',
    POSITIVE_SIGN     => '',
    P_CS_PRECEDES     => '0',
    P_SEP_BY_SPACE    => '1',
    P_SIGN_POSN       => '1'
};

require Math::Currency::EUR;

1;

__END__

=pod

=head1 NAME

Math::Currency::de_DE - de_DE Locale Module for Math::Currency

=head1 VERSION

version 0.51

=head1 SOURCE

The development version is on github at L<http://github.com/mschout/perl-math-currency>
and may be cloned from L<git://github.com/mschout/perl-math-currency.git>

=head1 BUGS

Please report any bugs or feature requests to bug-math-currency@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Math-Currency

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2001 by John Peacock <jpeacock@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
