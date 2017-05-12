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
    __PACKAGE__->set_levels(qw/debug info warn error fatal/);
}
sub clear_lines { @lines = () }

subtest 'Customized levels' => sub {
    my $logger = My::Logger->new(log_level => 'debug');
    $logger->info("foo");
    $logger->warn("bar");
    $logger->debug("baz");
    $logger->error("woot");
    $logger->fatal("aggh");
    is_deeply(
        \@lines, [
            '[INFO] foo',
            '[WARN] bar',
            '[DEBUG] baz',
            '[ERROR] woot',
            '[FATAL] aggh',
        ]
    );
    clear_lines();
};

subtest 'Throw an exception when got unknown level' => sub {
    my $logger = My::Logger->new(log_level => 'debug');
    eval {
        $logger->critical("woot");
    };
    ok($@) && like($@, qr/Unknown logging level: CRIT/);
    clear_lines();
};

done_testing;

