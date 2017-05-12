use strict;
use warnings;
use Test::More 0.98;
use Test::Fatal;
use Test::Mock::Guard;
use Capture::Tiny qw/capture/;
use Path::Tiny;
use Time::Piece;

use POSIX qw/tzset/;
$ENV{TZ} = 'Asia/Tokyo';
tzset;

use Linux::GetPidstat::Writer::File;

my $tempfile = Path::Tiny->tempfile;
my $t = localtime 1464430676;
my %opt = (
    now     => $t,
    dry_run => '0',
);

like exception {
    my $instance = Linux::GetPidstat::Writer::File->new(%opt);
}, qr/Path::Tiny paths require defined, positive-length parts/;

$opt{res_file} = $tempfile;

is exception {
    my $instance = Linux::GetPidstat::Writer::File->new(%opt);
}, undef, "create ok";

{
    my $instance = Linux::GetPidstat::Writer::File->new(%opt);
    $instance->output('backup_mysql', 'cpu', '21.20');

    my $got = $tempfile->slurp;
    is $got, "2016-05-28T19:17:56,1464430676,backup_mysql,cpu,21.20\n";

    # cleanup
    $tempfile->spew('');
}

$opt{dry_run} = 1;

{
    my $instance = Linux::GetPidstat::Writer::File->new(%opt);
    my ($stdout, $stderr) = capture {
        $instance->output('backup_mysql', 'cpu', '21.20');
    };

    my @stdout_lines = split /\n/, $stdout;
    is scalar @stdout_lines, 1 or diag $stdout;
    is $stdout_lines[0],
        '(dry_run) file write: 2016-05-28T19:17:56,1464430676,backup_mysql,cpu,21.20';
    is $stderr, '';

    my $got = $tempfile->slurp;
    is $got, '';

    # cleanup
    $tempfile->spew('');
}

done_testing;
