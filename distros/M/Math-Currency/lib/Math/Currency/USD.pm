package Math::Currency::USD;
$Math::Currency::USD::VERSION = '0.52';
# ABSTRACT: USD Currency Module for Math::Currency

use strict;
use warnings;
use base 'Math::Currency::en_US';

$Math::Currency::LC_MONETARY->{USD} =
    $Math::Currency::LC_MONETARY->{en_US};

1;

__END__

=pod

=head1 NAME

Math::Currency::USD - USD Currency Module for Math::Currency

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
