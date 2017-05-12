# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

my @expected;
BEGIN {
  @expected = ([ident => 'abc'],
	       [op => 'plus'],
	       [num => 123],
	       [ident => 'azt123']);
};
use Test::More;
use IO::Tokenized::File;
plan tests=> 1 + 2 * @expected + 2;


my %opnames = qw(* times + plus - minus / divide);
sub opname {
  $opnames{$_[0]};
}


ok($FH = IO::Tokenized::File->new('t/t2.txt',
				  [num => qr/\d+/],
				  [ident => qr/[a-z_]\w*/i],
				  [op => qr![*/+-]!,\&opname]
				 ),
   'creation');

foreach my $r (@expected) {
  my ($exp_tok,$exp_val) = @$r;
  my ($tok,$val) = $FH->gettoken();
  is ($tok,$exp_tok,'token equality');
  my $op = $exp_tok eq 'num' ? '==' : 'eq';
  cmp_ok($val,$op,$exp_val,'value equalty');
}
ok(! defined $FH->gettoken(),"no more token");
ok($FH->eof(),'eof');
