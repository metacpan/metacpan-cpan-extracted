use strict;
use warnings;
use utf8;
use Test::More;
use Log::Pony;

my @lines;
{
    package My::Logger;
    use parent qw/Log::Pony/;
    sub process {
        my ($self, $level, $message) = @_;
        push @lines, "[$level] $message";
    }
}
sub clear_lines { @lines = () }

subtest 'basic' => sub {
    my $logger = My::Logger->new(log_level => 'debug');
    $logger->info("foo");
    $logger->warn("bar");
    $logger->debug("baz");
    $logger->critical("woot");
    is_deeply(
        \@lines, [
            '[INFO] foo',
            '[WARN] bar',
            '[DEBUG] baz',
            '[CRITICAL] woot',
        ]
    );
    clear_lines();
};

subtest 'log level' => sub {
    my $logger = My::Logger->new(log_level => 'info');
    $logger->info("foo");
    $logger->warn("bar");
    $logger->debug("baz");
    $logger->critical("woot");
    is_deeply(
        \@lines, [
            '[INFO] foo',
            '[WARN] bar',
            '[CRITICAL] woot',
        ], 'no debug line',
    );
    clear_lines();
};

subtest '#sanitize' => sub {
    my $logger = My::Logger->new(log_level => 'info');
    is($logger->sanitize("\x0d\x0a\x09"), '\r\n\t');
    note $logger->time();
    clear_lines();
};

subtest 'sanitize works' => sub {
    my $logger = My::Logger->new(log_level => 'info');
    $logger->info("Hey!\x0dYo!\x0aHo!\x09Wow!\x0a");
    is_deeply(
        \@lines, [
            '[INFO] Hey!\rYo!\nHo!\tWow!',
        ], 'Escaped control char',
    );
    clear_lines();
};

subtest 'sanitize works' => sub {
    my $logger = My::Logger->new(log_level => 'info');
    $logger->info("Hey!\x0dYo!\x0aHo!\x09Wow!\x0a");
    is_deeply(
        \@lines, [
            '[INFO] Hey!\rYo!\nHo!\tWow!',
        ], 'Escaped control char',
    );
    clear_lines();
};

done_testing;

