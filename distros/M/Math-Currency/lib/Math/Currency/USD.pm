package Math::Currency::USD;
$Math::Currency::USD::VERSION = '0.53';
# ABSTRACT: USD Currency Module for Math::Currency

use strict;
use warnings;
use base 'Math::Currency::en_US';

$Math::Currency::LC_MONETARY->{USD} =
    $Math::Currency::LC_MONETARY->{en_US};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Math::Currency::USD - USD Currency Module for Math::Currency

=head1 VERSION

version 0.53

=head1 SOURCE

The development version is on github at L<https://https://github.com/mschout/perl-math-currency>
and may be cloned from L<git://https://github.com/mschout/perl-math-currency.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/mschout/perl-math-currency/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2001 by John Peacock <jpeacock@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
