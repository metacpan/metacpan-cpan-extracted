=pod

=encoding utf-8

=head1 PURPOSE

Test that Marlin::XAttribute::Lvalue compiles.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2026 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use Test2::V0;
use Test2::Plugin::BailOnFail;

use Marlin::XAttribute::Lvalue ();

pass 'compiles ok';

done_testing;

