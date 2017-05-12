=head1 PURPOSE

Test that the C<format> option can be used to define custom validation
criteria.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2011-2012 Toby Inkster.

This file is tri-licensed. It is available under the X11 (a.k.a. MIT)
licence; you can also redistribute it and/or modify it under the same
terms as Perl itself.

=cut

use Test::More tests => 4;
use strict;
use warnings;
use JSON::Schema;

my $schema1 = JSON::Schema->new(
	{
		type => 'object',
		properties => {
			mydate => { format => 'date-time' }
		},
	},
	format => {
		'date-time' => sub {
			ok(1, 'callback fired');
			$_[0] =~ /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/i;
		}
	}
);

my $result;

$result = $schema1->validate({mydate => '2011-11-11T11:11:11Z'});
ok $result, 'this should pass'
  or map { diag "reason: $_" } $result->errors;

$result = $schema1->validate({mydate => '2011-11-11T11:11:1Z'});
ok !$result, 'this should fail'
  or map { diag "reason: $_" } $result->errors;
