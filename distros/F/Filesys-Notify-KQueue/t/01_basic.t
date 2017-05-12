use t::Util;
use Filesys::Notify::KQueue;
use FindBin;

plan tests => 2;

mkdir "$FindBin::Bin/x" unless -d "$FindBin::Bin/x";

my $w = Filesys::Notify::KQueue->new(path => [ "lib", "t" ]);
test_fork {
    child {
        sleep 3;
        my $test_file = "$FindBin::Bin/x/rm_create.data";
        open my $out, ">", $test_file or die $!;
        print $out "foo" . time;
        close $out;
        sleep 3;
        unlink $test_file;
    };
    parent {
        my $event;
        for (1..2) {
            alarm 10;
            $w->wait(sub { $event = shift; }); # create
            like $event->{path}, qr/rm_create\.data/;
        }
    };
};
