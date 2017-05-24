=pod

=encoding utf-8

=head1 PURPOSE

Check renaming imported functions.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More tests => 6;

BEGIN { *note = *diag unless __PACKAGE__->can("note") };

use lib qw( examples ../examples );

note "Rename functions using -as"; do {
	package Local::AAA;
	use Example::Exporter fib => { -as => 'fibonacci' };
	::is fibonacci(6), 8, 'Correctly imported "fibonacci" from Example::Exporter';
	::ok !__PACKAGE__->can('fib'), 'Did not inadvertantly import "fib"';
};

note "Rename functions using -prefix"; do {
	package Local::BBB;
	use Example::Exporter fib => { -prefix => 'my' };
	::is myfib(6), 8, 'Correctly imported "myfib" from Example::Exporter';
	::ok !__PACKAGE__->can('fib'), 'Did not inadvertantly import "fib"';
};

note "Rename functions using -suffix"; do {
	package Local::CCC;
	use Example::Exporter fib => { -suffix => 'onacci' };
	::is fibonacci(6), 8, 'Correctly imported "fibonacci" from Example::Exporter';
	::ok !__PACKAGE__->can('fib'), 'Did not inadvertantly import "fib"';
};

