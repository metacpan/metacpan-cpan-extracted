#!/usr/bin/env perl

use common::sense;
use lib::abs '../lib';
use Test::More tests => 4;
BEGIN { $ENV{DEBUG_CB} = 0 }
use Devel::Leak::Cb;

our $name = 'somename';
{
	my $named;$named = cb $name { $named };
}
{
	my $named;$named = cb $main::name { $named };
}
{
	my $named;$named = cb "$name var" { $named };
}

cb       { pass "cb could be run" }->();
cb named { pass "cb named could be run" }->();
cb $name { pass "cb \$name could be run" }->();
# Not supported yet
#$named = cb q{some $name var} { };
#$named = cb qq{some $name var} { };

pass 'dummy';
