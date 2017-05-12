use strict;
use warnings;

use Test::More 0.88;
use Path::Tiny;
use Log::Dispatch;
use Log::Dispatch::File::Stamped;

my ($hour,$mday,$mon,$year) = (localtime)[2..5];
my $tempdir = Path::Tiny->tempdir;

my %params = (
    name      => 'file',
    min_level => 'debug',
    filename  => $tempdir->child('logfile.txt')->stringify,
);
my @tests = (
  { expected => $tempdir->child(sprintf("logfile-%04d%02d%02d.txt", $year+1900, $mon+1, $mday)),
    params   => \%params,
    message  => 'foo bar',
  },
  { expected => $tempdir->child(sprintf("logfile-%02d%02d.txt", $mday, $hour)),
    params   => { %params, stamp_fmt => '%d%H' },
    message  => 'blah blah',
  },
);
for my $t (@tests) {
    my $dispatcher = Log::Dispatch->new;
    ok($dispatcher);
    my $file = $t->{expected};
    my $stamped = Log::Dispatch::File::Stamped->new(%{$t->{params}});
    ok($stamped);
    $dispatcher->add($stamped);
    $dispatcher->log_to( name =>'file', level => 'info', message => $t->{message} );

    ok(-e $file, "$file exists");
    is(path($file)->slurp, $t->{message}, 'log content is correct');
}

done_testing;
