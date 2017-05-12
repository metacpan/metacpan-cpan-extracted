use strict;

use Test;

use Mail::CheckUser qw(check_email);

eval { require Sys::Hostname; $Mail::CheckUser::Helo_Domain = Sys::Hostname::hostname(); };

sub start($) {
    my($test_num) = @_;

    plan tests => $test_num;
}

sub run_test($$) {
    my($email, $fail) = @_;

    print "# $email\n";
    my $ok = check_email($email);
    $ok = !$ok if $fail;

    ok($ok);
}

sub run_timeout_test($$) {
    my($email, $timeout) = @_;

    $Mail::CheckUser::Timeout = $timeout;

    my $start_time = time;
    check_email($email);

    ok(time - $start_time < $timeout + 5)
}

1;
