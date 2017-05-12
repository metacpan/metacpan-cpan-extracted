=head1 PURPOSE

Test that minLength and maxLength work.

=head1 SEE ALSO

L<https://rt.cpan.org/Ticket/Display.html?id=81736>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2012 Toby Inkster.

This file is tri-licensed. It is available under the X11 (a.k.a. MIT)
licence; you can also redistribute it and/or modify it under the same
terms as Perl itself.

=cut

use strict;
use warnings;
use Test::More;

use JSON::Schema;

my $S = "JSON::Schema"->new(
	{
		type => 'object',
		properties => {
			username => { minLength => 1, maxLength => 64, required => 1 },
			password => { minLength => 6,                  required => 1 },
		},
	},
);

ok     $S->validate({ username => 'abc', password => 'abcdef' });
ok     $S->validate({ username => 'abc', password => 'abcdefgh' });
ok not $S->validate({ username => 'abc', password => 'abcde' });
ok not $S->validate({ username => 'abc' });
ok not $S->validate({ password => 'abcdefgh' });
ok not $S->validate({ username => '', password => 'abcdefgh' });
ok not $S->validate({ username => ('a' x 65), password => 'abcdefgh' });

done_testing;
