use strict;
use warnings;
use Test::More;
use Dir::Flock;

if (!eval "use threads;1") {
    ok(1, "# skip: threads not available");
    done_testing();
    exit;
}

my $dir = Dir::Flock::getDir("t");
ok(!!$dir, 'getDir returned value');
ok(-d $dir, 'getDir returned dir');
ok(-r $dir, 'getDir return value is readable');
ok(-w $dir, 'getDir return value is writeable');

my @t = glob("$dir/dir-flock-*");
ok(@t == 0, "lock directory is empty because it is new");

my $f = "t/08.out";
unlink $f;

sub write_f {
    my @list = @_;
    open my $fh, ">>", $f;
    $fh->autoflush(1);
    seek $fh, 0, 2;
    foreach my $item (@list) {
        print $fh $item;
        print $fh " ";
        select undef,undef,undef,0.1*rand;
    }
    close $fh;
}

my @data = map [ ($_) x $_ ], 12 .. 18;
write_f("");
my @thr = map threads->create( sub {
    my @list = @{$_[0]};
    Dir::Flock::sync  { write_f(@list) } $dir;
}, $_ ), @data;

$_->join for @thr;

open my $fh, "<", $f;
my @contents = <$fh>;
close $fh;
ok(@contents == 1, "thread output is on a single line");
my $data = $contents[0];
for my $n (12..18) {
    my $patt = qr/( $n){$n}/;
    ok( $data =~ $patt, "found instances of token $n" );
}
unlink $f;

done_testing;
