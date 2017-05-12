use Test::More;
use Test::Exception;
use IO::Slice;
use File::Basename qw< dirname >;
my $dirname = dirname(__FILE__);
my @specs = map { $_->{filename} = "$dirname/$_->{filename}"; $_ }
   @{ do "$dirname/testfile.specs" };

my ($sfh, $so);
lives_ok {
   $sfh = IO::Slice->new($specs[0])
      or die 'new failed';
   $so = tied *$sfh;
} 'new on filename lives, with hashref';

isa_ok $so, 'IO::Slice';

ok $so->opened(), 'file is open';
lives_ok { close $sfh } 'close lives';
ok ! $so->opened(), 'file is not opened any more';

done_testing();
