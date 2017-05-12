use 5.012;
use strictures;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok "Games::2048" or BAIL_OUT "Couldn't use Games::2048";
}

diag "Testing Games::2048 $Games::2048::VERSION, Perl $], $^X" ;
