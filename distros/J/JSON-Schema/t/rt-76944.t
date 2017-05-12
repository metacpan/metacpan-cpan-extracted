=head1 PURPOSE

Test that a false C<additionalProperties> forbids additional properties.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=76944>.

=head1 AUTHOR

sdevoid at gmail dot com

=head1 COPYRIGHT AND LICENCE

Copyright 2012 sdevoid at gmail dot com.

This file is tri-licensed. It is available under the X11 (a.k.a. MIT)
licence; you can also redistribute it and/or modify it under the same
terms as Perl itself.

=cut

use strict;
use Test::More tests => 1;
use JSON::Schema;
use JSON;

ok!(
	JSON::Schema
		-> new({ additionalProperties => JSON::false })
		-> validate({ foo  => "bar" })
);
