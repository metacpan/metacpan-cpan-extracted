use t::GmakeDOM;

plan tests => blocks() * 2;

run_tests;

__DATA__

=== TEST 1: empty makefile
--- src
--- dom
MDOM::Document::Gmake




