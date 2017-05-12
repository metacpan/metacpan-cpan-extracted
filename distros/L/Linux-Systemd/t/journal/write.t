use Test::More;
use Linux::Systemd::Journal::Write;

my $jnl = new_ok 'Linux::Systemd::Journal::Write' => [id => 'test'];

ok $jnl->print('flarg'), 'print string';

# {
#     "PRIORITY" : "6",
#     "SYSLOG_IDENTIFIER" : "perl",
#     "MESSAGE" : "flarg",
# }

ok $jnl->print('Hello world', 4), 'print with priority';

# {
#     "PRIORITY" : "4",
#     "SYSLOG_IDENTIFIER" : "perl",
#     "MESSAGE" : "Hello world",
# }

ok $jnl->perror('An error was set'), 'perror';

# {
#     "PRIORITY" : "3",
#     "SYSLOG_IDENTIFIER" : "perl",
#     "ERRNO" : "0",
#     "MESSAGE" : "An error was set: Success",
# }

my $hashref = {
    message        => 'Test send a hashref',
    abstract       => 'XS wrapper around sd-journal',
    author         => 'Ioan Rogers <ioanr@cpan.org>',
    dynamic_config => 0,
};

ok $jnl->send($hashref), 'send a hashref';

# {
#     "PRIORITY" : "6",
#     "DYNAMIC_CONFIG" : "0",
#     "AUTHOR" : "Ioan Rogers <ioanr@cpan.org>",
#     "CODE_LINE" : "35",
#     "MESSAGE" : "Test send a hashref",
#     "ABSTRACT" : "XS wrapper around sd-journal",
#     "CODE_FILE" : "t/01-main.t",
#     "SYSLOG_IDENTIFIER" : "01-main.t",
# }

my $arrayref = [
    message        => 'Test send an arrayref',
    abstract       => 'XS wrapper around sd-journal',
    author         => 'Ioan Rogers <ioanr@cpan.org>',
    dynamic_config => 0,
];
ok $jnl->send($arrayref), 'send an arrayref';

# {
#     "PRIORITY" : "6",
#     "DYNAMIC_CONFIG" : "0",
#     "AUTHOR" : "Ioan Rogers <ioanr@cpan.org>",
#     "ABSTRACT" : "XS wrapper around sd-journal",
#     "CODE_FILE" : "t/01-main.t",
#     "SYSLOG_IDENTIFIER" : "01-main.t",
#     "MESSAGE" : "Test send an arrayref",
#     "CODE_LINE" : "47",
# }

ok $jnl->send(
    message        => 'Test send an array',
    abstract       => 'XS wrapper around sd-journal',
    author         => 'Ioan Rogers <ioanr@cpan.org>',
    dynamic_config => 0,
  ),
  'send an array';

# {
#     "PRIORITY" : "6",
#     "DYNAMIC_CONFIG" : "0",
#     "AUTHOR" : "Ioan Rogers <ioanr@cpan.org>",
#     "ABSTRACT" : "XS wrapper around sd-journal",
#     "CODE_FILE" : "t/01-main.t",
#     "SYSLOG_IDENTIFIER" : "01-main.t",
#     "MESSAGE" : "Test send an array",
#     "CODE_LINE" : "65",
# }

ok $jnl->send('I am a string'), 'send a string';

# {
#     "PRIORITY" : "6",
#     "CODE_FILE" : "t/01-main.t",
#     "SYSLOG_IDENTIFIER" : "01-main.t",
#     "MESSAGE" : "I am a string",
#     "CODE_LINE" : "83",
# }

done_testing;
