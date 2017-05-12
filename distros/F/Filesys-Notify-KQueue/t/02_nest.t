use t::Util qw/create_paths delete_paths cmp_files get_filelist/;
use Filesys::Notify::KQueue;
use FindBin;

my @test_paths = (
    "$FindBin::Bin/x/1",
    "$FindBin::Bin/x/nest/",
    "$FindBin::Bin/x/nest/1",
    "$FindBin::Bin/x/nest/nest/",
    "$FindBin::Bin/x/nest/nest/1",
);

mkdir "$FindBin::Bin/x" unless -d "$FindBin::Bin/x";

my $sleep_time = 3;
my $dir = 't/x';
my $kqueue_timeout = $sleep_time * 2 * 1000;

my $w = Filesys::Notify::KQueue->new(path => [$dir], timeout => $kqueue_timeout);
is $w->timeout, $kqueue_timeout, 'set timeout ok';

my @files = get_filelist($dir);
cmp_files([$w->files], \@files);

test_fork {
    child {
        my($rdr, $wtr) = @_;

        while (my $command = <$rdr>) {
            chomp $command;
            if ($command eq 'create') {
                create_paths(@test_paths);
            }
            elsif ($command eq 'delete') {
                delete_paths(@test_paths);
            }
            elsif ($command eq 'finish') {
                last;
            }
        }
    };
    parent {
        my($rdr, $wtr) = @_;

        my %callback = (
            create => sub {
                foreach my $event (@_) {
                    my $path = $event->{path};
                    is $event->{event} => 'create', 'command valid';
                    push @files => $path;
                }
            },
            delete => sub {
                foreach my $event (@_) {
                    my $path = $event->{path};
                    is $event->{event} => 'delete', 'command valid';
                    @files = grep { $_ ne $path } @files;
                }
            },
        );

        foreach my $command (qw/create delete/) {
            alarm 10;
            print $wtr "${command}\n";
            sleep $sleep_time;
            $w->wait($callback{$command});
            cmp_files([$w->files], \@files);
            alarm 0;
        }
        print $wtr 'finish\n';
    };
};
done_testing;
