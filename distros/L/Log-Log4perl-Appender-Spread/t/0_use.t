# -*- perl -*-
use Test::More tests => 2;

use Log::Log4perl::Appender::Spread;

SKIP: {
	my $ap;
	eval { $ap = Log::Log4perl::Appender::Spread->new() };

	skip "spread not running",2 if $@;

	ok( defined $ap,            "new()" );
	ok( $ap->isa('Log::Log4perl::Appender::Spread'), "  and it's the right class" );
}

### thats about it for the use part

