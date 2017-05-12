=head1 PURPOSE

Test that HTTP::LRDD compiles.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2010-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

use Test::More tests => 1;
BEGIN { use_ok('HTTP::LRDD') };

