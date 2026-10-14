use strict;
use warnings;
use Test::More;
use FindBin;
use JSON;

# deploy/examples/ holds what an operator installs: the systemd units, the
# Postfix fragments, the authentication_milter handler config and the Sympa
# sendmail wrapper. The dkim2.com box installs the same files, so they must
# name only installed programs and no checkout.

my $ex = "$FindBin::Bin/../../deploy/examples";
plan skip_all => 'deploy/examples/ is in the interop repository, not in this distribution'
    unless -d $ex;
sub slurp { my $f = shift; open my $fh, '<', $f or die "$f: $!"; local $/; <$fh> }

ok(-f "$ex/$_", "$_ exists") for qw(dkim2-milter-inbound.service dkim2-milter-outbound.service
    dkim2-milter.service dkim2-split.service postfix-main.cf.fragment postfix-master.cf.fragment
    authentication_milter.json.fragment sympa-sendmail
    postfix-stock-mailman-main.cf.fragment postfix-stock-mailman-master.cf.fragment
    postfix-dkim2-lists postfix-dkim2-list-senders dkim2-milter-wrap.service);

for my $u (qw(dkim2-milter-inbound dkim2-milter-outbound dkim2-milter dkim2-milter-wrap)) {
    my $t = slurp("$ex/$u.service");
    like($t, qr{^ExecStart=/usr/local/bin/dkim2-milter\b}m, "$u runs the installed program");
    unlike($t, qr{/root/|/opt/dkim2|-I/}m, "$u names no checkout path");
    like($t, qr{^ProtectHome=yes}m, "$u can protect home");
    like($t, qr{^ExecStartPre=\+/usr/bin/install -d -m 750 -o dkim2 -g postfix /var/spool/postfix/var/run$}m,
         "$u creates the socket directory with privilege");
    like($t, qr{^ExecStartPre=\+/usr/bin/install -d -m 750 -o dkim2 -g postfix /var/spool/dkim2/snapshots$}m,
         "$u creates the snapshot directory with privilege");
    unlike($t, qr{mkdir}, "$u has no sandboxed mkdir that cannot succeed");
}
like(slurp("$ex/dkim2-split.service"), qr{^ExecStart=/usr/local/bin/dkim2-split-lmtp$}m,
     'the split unit runs the installed daemon');

my $json = slurp("$ex/authentication_milter.json.fragment");
my $cfg = eval { decode_json("{$json}") };
ok($cfg, 'authentication_milter fragment is a valid JSON object body') or diag($@);
is($cfg->{DKIM2Sign}{sign_local}, 1, 'the sign handler signs mail from local listeners');
is($cfg->{DKIM2Sign}{allow_null_body_recipe}, 1,
   'the sign handler signs a list manager\'s null body Recipe, as the outbound milter unit does');
is($cfg->{DKIM2Verify}{hide_none}, 0, 'the verify handler reports dkim2=none on inbound mail (its instance never sees list copies)');
is($cfg->{DKIM2Sign}{snapshot_directory}, $cfg->{DKIM2Verify}{snapshot_directory},
   'both handlers share one snapshot directory');

my $master = slurp("$ex/postfix-master.cf.fragment");
like($master, qr/^127\.0\.0\.1:10587 inet/m, 'master fragment defines the list submission listener');
like($master, qr/dkim2-milter-out\.sock/, '  ... with the signing milter');
{
    my ($reinject) = $master =~ /^#\s*127\.0\.0\.1:10589 inet(.*?)(?=^#\s*$|\z)/ms;
    ok($reinject, 'the split variant has a re-injection listener');
    unlike($reinject // '', qr/no_address_mappings/, '  ... which expands address mappings (the entry listener skipped them)');
}

my $main = slurp("$ex/postfix-main.cf.fragment");
like($main, qr/^disable_mime_output_conversion = yes/m, 'main fragment keeps signed bodies unconverted');
like($main, qr/^internal_mail_filter_classes = bounce/m, '  ... and signs bounces');
like($main, qr/append|existing/i, 'main fragment says to merge with existing milters, not replace them');

is(system($^X, '-c', "$ex/sympa-sendmail") >> 8, 0, 'sympa-sendmail compiles');
like(slurp("$ex/sympa-sendmail"), qr/DKIM2_SIGN_PORT/, '  ... and takes its port from the environment');

my $wrap = slurp("$ex/dkim2-milter-wrap.service");
like($wrap, qr/--mode inbound/, 'wrap unit is an inbound milter');
like($wrap, qr/--wrap-single-part/, '  ... that wraps');
like($wrap, qr{dkim2-milter-wrap\.sock}, '  ... on its own socket');
my $smaster = slurp("$ex/postfix-stock-mailman-master.cf.fragment");
for my $port (qw(10571 10572 10587)) {
    like($smaster, qr/^127\.0\.0\.1:$port inet/m, "stock master fragment defines 127.0.0.1:$port");
}
like($smaster, qr/content_filter=lmtp:\[127\.0\.0\.1\]:8024/, 'the wrap listener hands every message to Mailman');
like($smaster, qr/check_sender_access,regexp:\/etc\/postfix\/dkim2-list-senders/, 'the Mailman submission listener routes by sender (regexp: needs no extra package)');
like($smaster, qr/myhostname=/, 'loopback hops use a distinct myhostname');
unlike($smaster, qr/^127\.0\.0\.1:1002[456] /m, 'no listener on the content-filter ports 10024-10026');
{
    my %block = map { /^127\.0\.0\.1:(\d+) inet/ ? ($1 => $_) : () } split /\n(?=\S)/, $smaster;
    like($block{10571}, qr/local_header_rewrite_clients=$/m, 'the wrap listener does not rewrite headers');
    unlike($block{10572}, qr/smtpd_milters=/, 'Mailman\'s listener keeps the host\'s own milters');
    like($block{10587}, qr/content_filter=$/m, 'the signer sends nothing round a content filter again');
}
my $smain = slurp("$ex/postfix-stock-mailman-main.cf.fragment");
like($smain, qr/^transport_maps = hash:\/etc\/postfix\/dkim2-lists,/m, 'the DKIM2 list map comes before Mailman\'s');
unlike($smain, qr/^smtpd_milters\s*=\s*\S/m, 'port 25 runs no DKIM2 milter');
like(slurp("$ex/postfix-dkim2-list-senders"), qr/FILTER smtp:\[127\.0\.0\.1\]:10587/, 'sender map filters to the signer');
like(slurp("$ex/postfix-dkim2-lists"), qr/smtp:\[127\.0\.0\.1\]:10571/, 'transport map sends to the wrap listener');

done_testing;
