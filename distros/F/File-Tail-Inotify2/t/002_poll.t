use strict;
use warnings;
use Test::More tests => 4;
use File::Temp;
use File::Copy qw(move);
use Fcntl qw(O_CREAT O_RDWR);
use File::Spec::Functions qw(catfile);
use File::Tail::Inotify2;
use Linux::Inotify2;

my $dir      = File::Temp->newdir;
my $filename = catfile( $dir->dirname, 1 );
my $temp     = temp($filename);
my $content  = "foobar\n";

my $watcher;
$watcher = File::Tail::Inotify2->new(
    file    => $filename,
    on_read => sub {
        my $line = shift;
        note 'on_read called';
        is $line, $content, 'callback ok';
    }
);

{
    syswrite $temp, $content;
    close $temp;
    my ($e) = $watcher->{inotify}->read;
    is $e->fullname, $filename, 'filename ok';
}

# rotate
{
    my $to = $filename . ".1";
    move( $filename, $to );
    note $filename;
    my $new_temp = temp($filename);

    my @events = $watcher->{inotify}->read;
    is scalar @events, 3, '3 events are triggered';

    syswrite $new_temp, $content or die $!;
    close $new_temp;
    $watcher->{inotify}->read;
}

sub temp {
    my $filename = shift;
    open my $fh, '+>', $filename or die $!;
    return $fh;
}
