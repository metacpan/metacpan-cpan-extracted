package VAST::semiarglist;
BEGIN {
  $VAST::semiarglist::VERSION = '0.05';
}
use utf8;
use strict;
use warnings;
use Mildew::AST::Helpers;

sub emit_m0ld {
    my $m = shift;
    $m->{arglist}[0]->emit_m0ld;
}

1;
