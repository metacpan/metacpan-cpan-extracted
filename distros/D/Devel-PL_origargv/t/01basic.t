=head1 PURPOSE

Check C<< Devel::PL_origargv >> compiles.

Check that C<< Devel::PL_origargv->get >> returns sane data in list
and scalar context.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test::More tests => 3;
BEGIN { use_ok('Devel::PL_origargv') };

my ($pl) = Devel::PL_origargv->get;
like $pl, qr{perl}i;

my $argc = Devel::PL_origargv->get;
ok $argc > 1;
