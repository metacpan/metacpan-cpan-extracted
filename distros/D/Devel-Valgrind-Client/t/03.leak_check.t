use Test::More;
use Devel::Valgrind::Client qw(is_in_memcheck leak_check);

if(!is_in_memcheck()) {
  no warnings;
  exec "valgrind", "--log-file=delete-me.log", "${^X}", "-Mblib", __FILE__;
  plan skip_all => "Valgrind not found";
}

ok is_in_memcheck();

my $leaks = leak_check {
  my $x = "x" x 1e6;
  Internals::SvREFCNT($x, 2);
};

ok $leaks->{dubious} >= 1_000_000;

done_testing;
unlink "delete-me.log";
