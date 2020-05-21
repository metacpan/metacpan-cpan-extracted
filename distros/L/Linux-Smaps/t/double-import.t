use Test::More tests => 1;
use POSIX ();
use strict;

POSIX::setlocale( &POSIX::LC_ALL, "C" );
my ($s, $old);

my $fn=$0;
$fn=~s!/*t/+[^/]*$!! or die "Wrong test script location: $0";
$fn='.' unless( length $fn );

my $count = 0;
require Linux::Smaps;
{ no strict 'refs';
  *{'Linux::Smaps::new'} = sub { $count++; };
};

Linux::Smaps->import;
Linux::Smaps->import;

is $count, 1, "only processed import once";

# Local Variables:
# mode: cperl
# End:
