#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use B::Concise ();
use Ex::Op ();

# B names a custom op by its registered name from 5.14. Before that every
# custom op is "custom", and Ex::Op's is the only one here.
my $XOP = $] < 5.014 ? qr/\bcustom\b/ : qr/\bexop_call\b/;

plan skip_all => 'needs a build made with EX_OP_CHECK_WRAP=1, or perl before 5.14'
    unless defined &Ex::Op::_test_check_wrap && Ex::Op::_test_check_wrap();

BEGIN {
    Ex::Op::_test_add_checker() if defined &Ex::Op::_test_check_wrap && Ex::Op::_test_check_wrap();
    Ex::Op::make(add => sub { my ($x, $y) = @_; $x + $y });
}
sub plain { my ($x) = @_; $x }
sub seen { defined &Ex::Op::_test_checker_seen ? Ex::Op::_test_checker_seen() : 0 }

my ($base0, $base1, $before);
BEGIN { $base0 = seen() }
BEGIN { $base1 = seen() }
BEGIN { $before = seen() }
sub calls { my $a = add(1, 2); my $b = plain(3); my $c = add($a, $b); $c }
my $after;
BEGIN { $after = seen() }

is( ($after - $before) - ($base1 - $base0), 3, 'a checker wrapped on top of Ex::Op\'s still sees every entersub' );

my $out = '';
B::Concise::walk_output(\$out);
B::Concise::compile('-exec', 'main::calls')->();
my @calls = $out =~ /$XOP/g;
my @subs  = $out =~ /\bentersub\b/g;
is( scalar @calls, 2, '... and both calls to the op are still rewritten' );
is( scalar @subs,  1, '... and the call to a plain sub is left alone' );
is( calls(), 6, '... and they run' );

{
    package EO::Chain::Other;
    BEGIN { *add2 = \&main::add }
    sub use_it { my $r = add2(4, 5); $r }
}
$out = '';
B::Concise::walk_output(\$out);
B::Concise::compile('-exec', 'EO::Chain::Other::use_it')->();
like( $out, $XOP, 'a call through another name for the same sub is rewritten: the sub is found by its glob' );
is( EO::Chain::Other::use_it(), 9, '... and runs' );

done_testing;
