use strict;
use warnings;
use Test::More qw(no_plan);
use Log::Log4perl qw(:easy);
use Log::Log4perl::NDC::Scoped qw(push_ndc);
use File::Temp qw(tempdir);

my $dir = tempdir(CLEANUP => 1);
my $test_log = "$dir/test.log";

Log::Log4perl->easy_init({
    level   => $DEBUG,
    file    => "> $test_log",
    layout  => '%d %-5p %x - %m%n',
});

open my $fh, '<', $test_log or die "Cannot open $test_log";

my $failed = not eval { push_ndc('tag'); 1 };
ok($failed, "NDC is useless in void context");

my $log_line;

# Scope tests
{
    my $ndc = push_ndc('TEST');
    DEBUG('message');

    $log_line = <$fh>;
    like($log_line, qr|TEST|, 'NDC inserted')
}


DEBUG("message");
$log_line = <$fh>;
unlike($log_line, qr|TEST|, 'NDC not inserted');

# Separator tests
{
    my $ndc = push_ndc('tag1', 'tag2');
    DEBUG("message");
    $log_line = <$fh>;
    like($log_line, qr/tag1\|tag2/, 'default separator');
}

$Log::Log4perl::NDC::Scoped::SEPARATOR = ':';

{
    my $ndc = push_ndc('tag1', 'tag2');
    DEBUG("message");
    $log_line = <$fh>;
    like($log_line, qr/tag1:tag2/, 'changed default separator');
}
