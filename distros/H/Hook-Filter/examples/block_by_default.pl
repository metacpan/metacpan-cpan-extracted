#
# $Id: block_by_default.pl,v 1.1 2007/05/22 13:40:53 erwan_lemonnier Exp $
#
# An example on how to use Hook::Filter to block all calls
# to a function debug() by default.
#

use strict;
use warnings;
use lib "../lib/";

#-----------------------------------------------
# a logging package

package My::Log;

sub debug {
    print "_debug() got: ".$_[0]."\n";
}

#-----------------------------------------------

package main;

# filter calls to subroutine 'My::Log::_debug'
use Hook::Filter hook => "My::Log::debug";

# calls are still allowed by default since no rules are registered yet:
My::Log::debug("this is logged since no rules are defined yet");

# block all calls to _debug() by default
use Hook::Filter::RulePool qw(get_rule_pool);
my $pool = get_rule_pool;
$pool->add_rule("0");

# this won't be printed: the only rule registered returns 0, hence
# blocking calls to _debug:
My::Log::debug("you won't see this");
My::Log::debug("nor this");

# now allow calls only if they are from function foo() in package main
$pool->add_rule("from eq 'main::foo'");

sub foo {
    My::Log::debug($_[0]);
}

My::Log::debug("this message is not logged");
foo("this message is logged, since debug() is called from main::foo()");

