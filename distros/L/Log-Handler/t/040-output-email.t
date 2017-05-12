use strict;
use warnings;
use Test::More;

BEGIN {
    eval "use Net::SMTP;";
    if ($@) {
        plan skip_all => "No Net::SMTP installed";
        exit(0);
    } 
    eval "use Email::Date;";
    if ($@) {
        plan skip_all => "No Email::Date installed";
        exit(0);
    } 
};

plan tests => 4;

use Log::Handler::Output::Email;
$Log::Handler::Output::Email::TEST = 1;

my $log = Log::Handler::Output::Email->new(
    host     => [ "bloonix.de" ],
    hello    => "EHLO bloonix.de",
    timeout  => 60,
    debug    => 0,
    from     => 'jschulz.cpan@bloonix.de',
    to       => 'jschulz.cpan@bloonix.de',
    subject  => "Log::Handler::Output::Email test",
    buffer   => 20,
);

ok(1, "new");

# checking all log levels for would()
foreach my $i (1..10) {
    $log->log(message => "test $i\n") or die $!;
}

ok(1, "checking log()");

# checking all lines
my $match_lines = 0;
my $all_lines   = 0;

foreach my $line ( @{$log->{message_buffer}} ) {
    ++$all_lines;
    next unless $line->{message} =~ /^test \d+$/;
    ++$match_lines;
}

if ($match_lines == 10) {
   ok(1, "checking buffer ($all_lines:$match_lines)");
} else {
   ok(0, "checking buffer ($all_lines:$match_lines)");
}

$log->reload(
    {
        host     => [ "bloonix.de" ],
        hello    => "EHLO bloonix.de",
        timeout  => 60,
        debug    => 0,
        from     => 'jschulz.cpan@bloonix.de',
        to       => 'jschulz.cpan@bloonix.de',
        subject  => "Log::Handler::Output::Email test",
        buffer   => 100,
    }
);

ok($log->{buffer} == 100, "checking reload ($log->{buffer})");
