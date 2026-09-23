use strict;
use warnings;
use Test::More;
use Config;
use File::Temp ();

plan skip_all => 'author test: set AUTHOR_TESTING=1' unless $ENV{AUTHOR_TESTING};

# A client still materialised when the process exits is a real crash window,
# not a tidy leak: TDLib skips client teardown once exit has begun and detaches
# its scheduler thread rather than joining it. This runs every t/ file with a
# hook that reports any such client, so the invariant is enforced mechanically
# instead of relying on each test to be careful.

my @tests = sort glob 't/*.t';
cmp_ok scalar(@tests), '>', 40, 'the scan found test files to audit';

# The audit reports a problem by printing. Every real test is expected to be
# clean, so a report that had stopped working would look exactly like 46
# passes -- this is the one case that must produce output.
{
    # written to a file rather than passed to -e: the script's own quotes
    # would end the shell's
    my ($fh, $script) = File::Temp::tempfile(SUFFIX => '.pl', UNLINK => 1);
    # a raw id, materialised without new(): the module's END closes the
    # clients it knows about, so a client it created is never the case this
    # audit has to catch
    print $fh <<'LEAKY';
use EV; use EV::Telegram::TDLib;
my $cid = EV::Telegram::TDLib::_create_client_id();
EV::Telegram::TDLib::_send($cid, '{"@type":"getOption","name":"version"}');
LEAKY
    close $fh;
    my $out = `"$Config{perlpath}" -Iblib/lib -Iblib/arch -Ixt/lib -MTeardownAudit $script 2>&1`;
    like $out, qr/TEARDOWN-AUDIT-LIVE:/,
        'a client left materialised at exit is actually reported';
}

# ...and the case that made it worth having: an on_close handler that
# reconnects runs during END's pump, so its client joins %CLIENTS after the
# close-all and would otherwise reach exit materialised
{
    my ($fh, $script) = File::Temp::tempfile(SUFFIX => '.pl', UNLINK => 1);
    my $db = File::Temp::tempdir(CLEANUP => 1);
    print $fh <<"REENTER";
use EV; use EV::Telegram::TDLib;
my \$td = EV::Telegram::TDLib->new(api_id => 1, api_hash => 'x',
    database_directory => '$db/a', on_error => sub {},
    on_close => sub {
        my \$new = EV::Telegram::TDLib->new(api_id => 1, api_hash => 'x',
            database_directory => '$db/b', on_error => sub {});
        \$new->send({ '\@type' => 'getOption', name => 'version' });
    });
\$td->send({ '\@type' => 'getOption', name => 'version' });
REENTER
    close $fh;
    my $out = `"$Config{perlpath}" -Iblib/lib -Iblib/arch -Ixt/lib -MTeardownAudit $script 2>&1`;
    ok $out =~ /TEARDOWN-AUDIT-DONE/, 'the re-entrant case ran to completion';
    unlike $out, qr/TEARDOWN-AUDIT-LIVE:/,
        'a client created from on_close is closed before exit too';
}

for my $t (@tests) {
    my $out = `"$Config{perlpath}" -Iblib/lib -Iblib/arch -Ixt/lib -MTeardownAudit $t 2>&1`;
    # the audit reports by absence, so its own silence must not read as a
    # pass: a child that died before END prints neither line
    ok $out =~ /TEARDOWN-AUDIT-DONE/, "$t ran the audit to completion"
        or diag $out =~ s/^/  /gmr;
    my ($live) = $out =~ /TEARDOWN-AUDIT-LIVE: (.+)/;
    ok !$live, "$t leaves no client materialised at exit"
        or diag "still live: $live";
    # STRANDED (a close sent and never answered) is printed but not asserted
    # per file: a test that installs its own dispatch callback -- which is
    # exactly what 02_transport, 12_utf8 and 18_dispatch_hardening exist to
    # do -- unhooks the observer, and 17_fork_child never runs its loop. The
    # case that matters is asserted directly below instead.
    my ($stranded) = $out =~ /TEARDOWN-AUDIT-STRANDED: (.+)/;
    diag "$t: close sent but never answered: $stranded" if $stranded && $ENV{TD_VERBOSE};
}

# the stricter oracle must actually bite: a program that blocks for longer
# than the shutdown budget outside the loop used to lose the whole pump
{
    my ($fh, $script) = File::Temp::tempfile(SUFFIX => '.pl', UNLINK => 1);
    my $db = File::Temp::tempdir(CLEANUP => 1);
    print $fh <<"BLOCKED";
use EV; use EV::Telegram::TDLib;
my \$td = EV::Telegram::TDLib->new(api_id => 1, api_hash => 'x',
    database_directory => '$db');
\$td->send({ '\@type' => 'getOption', name => 'version' }, sub { });
my \$t = EV::timer 0.3, 0, sub { EV::break };
EV::run;
select undef, undef, undef, 2.5;
BLOCKED
    close $fh;
    local $ENV{EV_TDLIB_SHUTDOWN_TIMEOUT} = 2;
    my $out = `"$Config{perlpath}" -Iblib/lib -Iblib/arch -Ixt/lib -MTeardownAudit $script 2>&1`;
    ok $out =~ /TEARDOWN-AUDIT-DONE/, 'the blocked-before-exit case ran to completion'
        or diag $out =~ s/^/  /gmr;
    unlike $out, qr/TEARDOWN-AUDIT-STRANDED:/,
        'blocking longer than the budget before exit still closes the client'
        or diag $out =~ s/^/  /gmr;
}

done_testing;
