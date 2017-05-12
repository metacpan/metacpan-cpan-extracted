package VAST::comp_unit;
BEGIN {
  $VAST::comp_unit::VERSION = '0.05';
}
use utf8;
use strict;
use warnings;
use Mildew::AST::Helpers;

sub emit_m0ld {
    my ($m) = @_;
    Mildew::AST::Block->new(regs=>['interpreter','scope'],stmts=>$m->{statementlist}->emit_m0ld);
}

1;
