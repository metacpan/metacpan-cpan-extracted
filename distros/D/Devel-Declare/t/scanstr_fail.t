use warnings;
use strict;

use Devel::Declare ();
use Test::More tests => 1;

sub my_quote($) { $_[0] }

sub my_quote_parser {
  my($declarator, $offset) = @_;
  $offset += Devel::Declare::toke_move_past_token($offset);
  $offset += Devel::Declare::toke_skipspace($offset);
  my $len = Devel::Declare::toke_scan_str($offset);
  die "suprising len=$len" if defined $len;
  die "toke_scan_str fail\n";
}

BEGIN {
  Devel::Declare->setup_for(__PACKAGE__, {
    my_quote => { const => \&my_quote_parser },
  });
}

eval q{ my_quote[foo };
is $@, "toke_scan_str fail\n";

1;
