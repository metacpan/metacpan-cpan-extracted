use strict;
use warnings;

use Test::More 0.88;
use Path::Tiny;
use Log::Dispatch;
use Log::Dispatch::File::Stamped;

plan skip_all => 'the UTF-8 encoding is not reliably available before perl 5.8' if "$]" < 5.008;

my $tempdir = Path::Tiny->tempdir;
my ($hour,$mday,$mon,$year) = (localtime)[2..5];

my %params = (
    name      => 'file',
    min_level => 'debug',
    filename  => $tempdir->child('logfile.txt')->stringify,
);
my @tests = (
  { expected => $tempdir->child(sprintf("logfile-%04d%02d%02d.txt", $year+1900, $mon+1, $mday)),
    params   => {%params, 'binmode' => ':encoding(UTF-8)'},
    message  => "foo bar\x{20AC}",
    expected_message => "foo bar\xe2\x82\xac",
  },
);

SKIP:
{
    skip "Cannot test utf8 files with this version of Perl ($])", 5 * @tests
        unless "$]" >= 5.008;

    for my $t (@tests) {
        my $dispatcher = Log::Dispatch->new;
        ok($dispatcher);
        my $file = $t->{expected};
        my $stamped = Log::Dispatch::File::Stamped->new(%{$t->{params}});
        ok($stamped);
        $dispatcher->add($stamped);
        $dispatcher->log( level   => 'info', message => $t->{message} );

        ok(-e $file, "$file exists");
        is($file->slurp, $t->{expected_message}, 'file contains correct (encoded) bytes');
    }
}

done_testing;
