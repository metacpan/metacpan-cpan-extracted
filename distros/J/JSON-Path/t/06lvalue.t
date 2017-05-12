=head1 PURPOSE

Basic tests for some of the lvalue stuff.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2013 Toby Inkster.

This module is tri-licensed. It is available under the X11 (a.k.a. MIT)
licence; you can also redistribute it and/or modify it under the same
terms as Perl itself.

=cut

use strict;
use warnings;
use Test::More;

use JSON::Path -all;

my $person = { name => "Robert" };
my $path = JSON::Path->new('$.name');
$path->value($person) = "Bob";

is_deeply($person, { name => "Bob" });

jpath1($person, '$.name') = "Robbie";

is_deeply($person, { name => "Robbie" });

done_testing;

