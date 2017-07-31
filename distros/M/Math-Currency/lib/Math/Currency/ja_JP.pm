package Math::Currency::ja_JP;
$Math::Currency::ja_JP::VERSION = '0.52';
# ABSTRACT: ja_JP Locale Module for Math::Currency

use utf8;
use strict;
use warnings;
use Math::Currency qw($LC_MONETARY $FORMAT);
use base qw(Exporter Math::Currency);

our $LANG  = 'ja_JP';

$LC_MONETARY->{ja_JP} = {
    INT_CURR_SYMBOL   => 'JPY ',
    CURRENCY_SYMBOL   => '¥',
    MON_DECIMAL_POINT => '.',
    MON_THOUSANDS_SEP => ',',
    MON_GROUPING      => '3',
    POSITIVE_SIGN     => '',
    NEGATIVE_SIGN     => '-',
    INT_FRAC_DIGITS   => '0',
    FRAC_DIGITS       => '0',
    P_CS_PRECEDES     => '1',
    P_SEP_BY_SPACE    => '0',
    N_CS_PRECEDES     => '1',
    N_SEP_BY_SPACE    => '0',
    P_SIGN_POSN       => '4',
    N_SIGN_POSN       => '4'
};

require Math::Currency::JPY;

1;

__END__

=pod

=head1 NAME

Math::Currency::ja_JP - ja_JP Locale Module for Math::Currency

=head1 VERSION

version 0.52

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
