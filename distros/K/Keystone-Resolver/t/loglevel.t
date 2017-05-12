# $Id: loglevel.t,v 1.3 2008-03-26 15:19:49 mike Exp $

use strict;
use Test;

use vars qw(@tests);
BEGIN {
    use Keystone::Resolver::LogLevel;
    @tests = (
	[ CHITCHAT => Keystone::Resolver::LogLevel::CHITCHAT ],
	[ CACHECHECK => Keystone::Resolver::LogLevel::CACHECHECK ],
	[ WARNING => Keystone::Resolver::LogLevel::WARNING ],
	[ "HANDLE,WARNING" => (Keystone::Resolver::LogLevel::WARNING |
			       Keystone::Resolver::LogLevel::HANDLE) ],
	[ "DBLOOKUP,MKRESULT,SQL" => (Keystone::Resolver::LogLevel::DBLOOKUP |
				      Keystone::Resolver::LogLevel::MKRESULT |
				      Keystone::Resolver::LogLevel::SQL) ],
	[ LIFECYCLE => Keystone::Resolver::LogLevel::LIFECYCLE ],
    );

    plan tests => 1 + 2*scalar(@tests);
};

ok(1); # For the successful "use";

foreach my $ref (@tests) {
    my($str, $num) = @$ref;
    ok(Keystone::Resolver::LogLevel::num($str), $num);
    ok(Keystone::Resolver::LogLevel::label($num), $str);
}
