use strict;
use warnings;
use Test::More;
use GitHub::WebHook::Run;

for (undef, 1, {}) {
    eval { GitHub::WebHook::Run->new( cmd => $_ ) };
    ok $@, "validate cmd";
}

my $run = GitHub::WebHook::Run->new( 
    cmd => sub {
        my $payload = shift;
        [ $^X, '-e', 'print "'.$payload.'\n";die "!\n"' ]
    }
);

my @log;
my $logger = {
    map { my $level = $_; $level => sub { push @log, $level, $_[0] } } 
    qw(debug info warn error fatal)
};

ok $run->call(42,0,0,$logger), 'called';
is_deeply \@log, [
    info  => '$ '.$^X.' -e print "42\n";die "!\n"',
    debug => "42\n",
    warn  => "!\n",
], 'executed and logged';

done_testing;
