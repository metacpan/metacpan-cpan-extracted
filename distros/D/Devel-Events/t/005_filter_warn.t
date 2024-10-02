# vim: set ts=2 sw=2 noet nolist :
use strict;
use warnings;

use Test::More 0.88;

use ok 'Devel::Events::Filter::Warn';

my @warnings;
$SIG{__WARN__} = sub { push @warnings, [ @_ ] };

my $f = Devel::Events::Filter::Warn->new;

$f->new_event( foo => bar => 42 );

is_deeply(
	\@warnings,
	[ [ "foo: bar => 42\n" ] ],
);

done_testing;
