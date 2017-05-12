=pod

=encoding utf-8

=head1 PURPOSE

Test that Devel::StrictMode works with PERL_STRICT true.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

BEGIN {
	$ENV{PERL_STRICT} = 1;
};

use strict;
use warnings;
use Test::More tests => 2;

use Devel::StrictMode qw( STRICT LAX );

ok STRICT;
ok not LAX;
