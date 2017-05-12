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
        my $trace_info = $self->trace_info();
        push @lines, "[$level] $message $trace_info";
    }
}
sub clear_lines { @lines = () }

subtest 'basic' => sub {
    my $logger = My::Logger->new(log_level => 'debug');
    $logger->info("foo");
    $logger->warn("bar");
    $logger->debug("baz");
    $logger->critical("woot");
    $logger->log('INFO', "log!");
    is_deeply(
        \@lines, [
            map { my $x=$_; $x=~s!t/02_trace_info.t!__FILE__!ge; $x }
            "[INFO] foo at t/02_trace_info.t line 21",
            "[WARN] bar at t/02_trace_info.t line 22",
            "[DEBUG] baz at t/02_trace_info.t line 23",
            "[CRITICAL] woot at t/02_trace_info.t line 24",
            "[INFO] log! at t/02_trace_info.t line 25",
        ]
    );
    clear_lines();
};

done_testing;

