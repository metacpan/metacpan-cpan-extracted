package Test::LogSyslogFast;

use base 'Test::Builder::Module';
@EXPORT = qw(payload_ok expected_payload);

use POSIX 'strftime';

my $Tester = Test::Builder->new();

sub expected_payload {
    my ($facility, $severity, $sender, $name, $pid, $msg, $time) = @_;
    return sprintf "<%d>%s %s %s[%d]: %s",
        ($facility << 3) | $severity,
        strftime("%h %e %T", localtime($time)),
        $sender, $name, $pid, $msg;
}

sub payload_ok ($@;$) {
    my ($payload, @payload_params, $text) = @_;
    for my $offset (0, -1, 1) {
        my $allowed = expected_payload(@payload_params);

        if ($allowed eq $payload) {
            $Tester->ok(1,$text);
            return 1;
        }
    }

    $Tester->ok(0,$text);    
    return 0;
}

1;
