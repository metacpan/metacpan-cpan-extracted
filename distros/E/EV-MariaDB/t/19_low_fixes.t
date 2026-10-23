use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestMariaDB;
use EV;
use EV::MariaDB;

my $have_server = TestMariaDB::server_available();
plan tests => 11;
diag('no test server - autocommit checks will skip') unless $have_server;

# --- query POD pins the buffering contract, not "any exclusive op" -------
# MariaDB.xs query() buffers only while state < STATE_STMT_PREPARE (i.e.
# during connect/pipeline/utility ops) and croaks "cannot queue query"
# during statement, streaming, or close states. The POD must say that.
{
    open my $fh, '<', 'lib/EV/MariaDB.pm' or die "open: $!";
    local $/;
    my $pm = <$fh>;
    close $fh;

    my ($query_pod) = $pm =~ /(=head2 query\b.*?)(?==head2 |\z)/s;
    ok(defined $query_pod, 'query POD section exists');
    like($query_pod, qr/cannot queue\s+query/,
         'query POD documents the "cannot queue query" croak');
    like($query_pod, qr/while a utility op/,
         'query POD narrows buffering to utility ops');
    unlike($query_pod, qr/while an exclusive op/,
           'query POD no longer claims buffering during any exclusive op');
    my ($methods_pod) = $pm =~ /(=head1 METHODS\b.*?)(?==head1 |\z)/s;
    like($methods_pod, qr/reset_connection.*set_charset|set_charset.*reset_connection/s,
         'METHODS POD enumerates the buffering utility ops');
}

SKIP: {
    skip 'No MariaDB/MySQL server', 6 unless $have_server;

    # --- autocommit() treats $mode as a boolean, like the POD promises ---
    # "any truthy value enables, any falsy value disables". The XS glue
    # used to take `int mode`, so SvIV("yes") == 0 silently disabled.
    my %A = TestMariaDB::connect_args();
    my @cases = (
        [1,     1, 'numeric 1 enables'],
        [0,     0, 'numeric 0 disables'],
        ['yes', 1, 'truthy string enables'],
        ['0',   0, 'falsy string "0" disables'],
        ['',    0, 'empty string disables'],
        [undef, 0, 'undef disables'],
    );

    my $m;
    $m = EV::MariaDB->new(
        %A,
        on_connect => sub {
            my $i = 0;
            my $next;
            $next = sub {
                if ($i >= @cases) { EV::break; return }
                my ($mode, $want, $name) = @{$cases[$i++]};
                no warnings 'numeric';
                $m->autocommit($mode, sub {
                    my ($ok, $err) = @_;
                    BAIL_OUT("autocommit failed: $err") if $err;
                    $m->query('SELECT @@autocommit', sub {
                        my ($rows, $qerr) = @_;
                        BAIL_OUT("SELECT failed: $qerr") if $qerr;
                        is($rows->[0][0] + 0, $want, "autocommit: $name");
                        $next->();
                    });
                });
            };
            $next->();
        },
        on_error => sub { BAIL_OUT("connect failed: $_[0]") },
    );
    my $t = EV::timer(15, 0, sub { BAIL_OUT('timed out'); EV::break });
    EV::run;
    $m->finish if $m->is_connected;
}
