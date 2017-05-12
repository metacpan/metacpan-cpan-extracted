# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use lib qw(t/lib);
use Test::More tests => 2520;
use Lingua::Zompist::Kebreni;

#########################

my %word;

open DAT, '<t/kebtest.dat' or die "Can't open t/kebtest.dat: $!";

while(<DAT>) {
  next unless /\S/;
  chomp;

  if(/^Trying combination\s+$/) {
    @meth = ('null');
  } elsif(/^Trying combination /) {
    @meth = /\w+/g;
    splice @meth, 0, 2;
  } elsif(/^(\S+) --> (\S+)/) {
    my($from, $to) = ($1, $2);

    $word{$from} ||= Lingua::Zompist::Kebreni->new($from);

    my $code = join '->', '$word{$from}', @meth;
    my $out = eval $code;
    is($@, '', "No problem with $code");
    is($out, $to, "$from --> $to under @meth");
  }
}

close DAT or die "Can't close t/kebtest.dat: $!";
