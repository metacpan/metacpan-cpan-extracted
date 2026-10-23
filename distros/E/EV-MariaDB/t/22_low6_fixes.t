use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestMariaDB;
use EV;
use EV::MariaDB;

my $have_server = TestMariaDB::server_available();
diag('no test server - DB tests will skip') unless $have_server;

# Constructor defaults preserve visible error reporting.
{
    my $m = EV::MariaDB->new(on_error => undef);
    ok(defined $m->on_error, 'on_error=>undef retains the default error handler');

    my $dflt = EV::MariaDB->new();
    ok(defined $dflt->on_error, 'absent on_error still installs default die handler');

    my $sub = sub { };
    my $m2 = EV::MariaDB->new(on_error => $sub);
    is($m2->on_error, $sub, 'explicit on_error sub still installed');
}

# --- 2. MANIFEST.SKIP excludes the pcg graph dir
{
    open my $fh, '<', 'MANIFEST.SKIP' or die "open MANIFEST.SKIP: $!";
    my @lines = <$fh>;
    close $fh;
    chomp @lines;
    ok(grep({ '.pcg/graph.db' =~ /$_/ } @lines),
       'MANIFEST.SKIP excludes .pcg/ from the tarball');
}

SKIP: {
    skip 'No MariaDB/MySQL server', 3 unless $have_server;
    my %A = TestMariaDB::connect_args();

    # --- 4. connect works after finish (documents the corrected POD)
    {
        my ($m, $nconnect);
        $m = EV::MariaDB->new(
            on_connect => sub { $nconnect++; EV::break },
            on_error   => sub { diag("Error: $_[0]"); EV::break },
        );
        $m->connect(@A{qw/host user password database port/}, $A{unix_socket});
        my $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        $m->finish;
        $m->connect(@A{qw/host user password database port/}, $A{unix_socket});
        EV::run;
        is($nconnect, 2, 'connect after finish reconnects');
        $m->finish;
    }

    # --- 5. pending_count stays 1 inside stream row callbacks
    {
        my ($m, $seen, $eof_count);
        $m = EV::MariaDB->new(
            %A,
            on_connect => sub {
                $m->query_stream(
                    'select 1 as v union all select 2 union all select 3',
                    sub {
                        my ($row, $err) = @_;
                        die $err if $err;
                        if (defined $row) {
                            $seen = $m->pending_count unless defined $seen;
                        } else {
                            $eof_count = $m->pending_count;
                            EV::break;
                        }
                    });
            },
            on_error => sub { diag("Error: $_[0]"); EV::break },
        );
        my $t = EV::timer(10, 0, sub { EV::break });
        EV::run;
        is($seen, 1, 'pending_count is 1 inside stream row callback');
        is($eof_count, 0, 'pending_count returns to 0 at stream EOF');
        $m->finish;
    }

}

# --- 6. is_utf8_charset covers all live utf8 collation IDs
# Local MariaDB normalizes wire charsetnr to the connection default, so no
# live query can surface the new IDs here; instead compile the predicate
# extracted verbatim from MariaDB.xs and check its truth table.
SKIP: {
    my $cc = $ENV{CC} // 'cc';
    my $have_cc = defined $ENV{CC} ? 1 : grep { -x "$_/cc" } split /:/, $ENV{PATH} // '';
    skip 'no C compiler for predicate probe', 1 unless $have_cc;

    open my $xs, '<', 'MariaDB.xs' or die "open MariaDB.xs: $!";
    my $src = do { local $/; <$xs> };
    close $xs;
    my ($fn) = $src =~ /^(static int is_utf8_charset\(unsigned int charsetnr\) \{.*?^\})/ms;
    ok(defined $fn, 'extracted is_utf8_charset from MariaDB.xs') or skip 'predicate not found', 1;
    (my $callable = $fn) =~ s/^static int/int/;

    require File::Temp;
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    open my $c, '>', "$dir/pred.c" or die "open pred.c: $!";
    print $c "#include <stdio.h>\n$callable\n"
        . "int main(void){unsigned id;while(scanf(\"%u\",&id)==1)"
        . "{printf(\"%d\\n\",is_utf8_charset(id));}return 0;}\n";
    close $c;
    my $built = system($cc, '-O1', '-o', "$dir/pred", "$dir/pred.c") == 0;
    ok($built, 'predicate probe compiled') or skip 'probe build failed', 1;

    my @yes = (33, 83, 192, 211, 212, 213, 214, 215, 223,
               45, 46, 224, 247, 255, 256, 309,
               576, 577, 578, 579, 608, 609, 610, 611,
               1057, 1069, 1070, 1107, 1216, 1238, 1248, 1270,
               2048, 2304, 2559);
    my @no = (0, 1, 8, 63, 191, 216, 222, 248, 254, 310,
              575, 580, 607, 612, 1056, 1058, 1068, 1071,
              1106, 1108, 1215, 1217, 1237, 1239, 1247, 1249,
              1269, 1271, 2047, 2560, 3000);
    open my $ids, '>', "$dir/ids.txt" or die "open ids: $!";
    print $ids "$_\n" for (@yes, @no);
    close $ids;
    my @lines = qx("$dir/pred" < "$dir/ids.txt");
    chomp @lines;
    my @got_yes = splice @lines, 0, scalar @yes;
    my @got_no  = @lines;
    my (@miss_yes, @miss_no);
    for my $i (0 .. $#yes) { push @miss_yes, $yes[$i] unless ($got_yes[$i] // '') eq '1' }
    for my $i (0 .. $#no)  { push @miss_no, $no[$i]   unless ($got_no[$i] // '') eq '0' }
    is_deeply(\@miss_yes, [], 'utf8 IDs recognized: ' . join(',', @yes));
    is_deeply(\@miss_no, [], 'non-utf8 IDs rejected');
}

done_testing;
