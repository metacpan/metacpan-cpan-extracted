use strict;
use Test::More tests => 5;

use HTML::ERuby;

my %vars = (
	    scalar => "foo",
	    hashref => {
			name => "IKEBE",
			email => 'ikebe@cpan.org'
		       },
	    arrayref => [qw(a b c)],
);

my $erb = HTML::ERuby->new;
my $res = $erb->compile(filename => './t/perlvars.rhtml', vars => \%vars);

like $res, qr/foo/;
like $res, qr/IKEBE : ikebe\@cpan.org/;
like $res, qr/a/;
like $res, qr/b/;
like $res, qr/c/;
