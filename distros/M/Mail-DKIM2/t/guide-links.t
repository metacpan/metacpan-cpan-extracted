use strict;
use warnings;
use Test::More;
use FindBin;

# The operator guide names files in this repository and settings the rest
# of the repository implements; this keeps it from drifting.

my $root = "$FindBin::Bin/../..";
my $guide = "$root/docs/dkim2-postfix-list-host-guide.md";
plan skip_all => 'the operator guide is in the interop repository, not in this distribution'
    unless -f $guide;
my $text = do { local (@ARGV, $/) = $guide; <> };

my %seen;
for my $path ($text =~ /`((?:perl|deploy|mailman|sympa|util|docs)\/[A-Za-z0-9_.\/-]+)`/g) {
    next if $seen{$path}++;
    ok(-e "$root/$path", "guide path $path exists in the repo");
}
like($text, qr/^## .*Mailman/m, 'has a Mailman section');
like($text, qr/mailman\@dkim2-3\.3\.10/, 'recommends the 3.3.10 backport branch');
like($text, qr/git checkout v3\.3\.10/, '  ... and the release tag for the patch route');
like($text, qr/^## .*Sympa/m,   'has a Sympa section');
like($text, qr/max_recipients: 1/, 'tells Mailman to deliver one recipient per transaction');
like($text, qr/\bnrcpt 1\b/,     'tells Sympa the same');
like($text, qr/disable_mime_output_conversion = yes/, 'warns about transport conversion');
like($text, qr/Sendmail::PMilter 1\.28/, 'requires the Sendmail::PMilter that answers a null sender');
unlike($text, qr/pmilter-null-sender-envfrom\.patch|deploy\/patches/, 'no longer tells operators to patch PMilter');
like($text, qr/DKIM2Sign/ && qr/DKIM2Verify/, 'covers the authentication_milter handlers');
unlike($text, qr{/root/interop|/opt/dkim2}, 'no dkim2.com box paths');

# The copy-paste steps a reviewer found broken on a fresh host.
unlike($text, qr/^(?:smtp_port|message_instance|max_recipients):[^\n#]*#/m,
       'mailman.cfg block has no inline comments (lazr.config keeps them in the value)');
like($text, qr/-H 'Content-Type: application\/json'/, 'REST example sends JSON as JSON');
unlike($text, qr/mailman\.database\.initialize/, 'no nonexistent migration entry point');
unlike($text, qr/perldoc -l/, 'nothing depends on perl-doc (not on a stock Debian)');
like($text, qr/useradd -r -U -G postfix/, 'the dkim2 user has its own group and is in postfix');
like($text, qr/install -d -m 750 -o dkim2 -g postfix \/var\/spool\/postfix\/var\/run/,
     'the socket directory is created before the units start');
like($text, qr/mailman3 journal/, 'says Mailman DKIM2 logs go to the mailman3 journal');
unlike($text, qr/logging\.dkim2/, 'no [logging.dkim2] section (Mailman ignores it)');
like($text, qr/not (?:been )?tested end to end/i, 'the authentication_milter path is labelled as untested');
like($text, qr/wwsympa/, 'Sympa restart list includes wwsympa');
like($text, qr/git -c user\.name/, 'git am works on a host with no identity');
like($text, qr/i=1\.\.1 verified/, 'the plain-upstream example shows i=1..1');

# The stock-Mailman guide (milters and Postfix routing only, Mailman unpatched).
my $sguide = "$root/docs/dkim2-postfix-stock-mailman-guide.md";
ok(-f $sguide, 'the stock-Mailman guide exists');
my $stext = -f $sguide ? do { local (@ARGV, $/) = $sguide; <> } : '';
%seen = ();
for my $path ($stext =~ /`((?:perl|deploy|mailman|sympa|util|docs)\/[A-Za-z0-9_.\/-]+)`/g) {
    next if $seen{$path}++;
    ok(-e "$root/$path", "stock guide path $path exists in the repo");
}
like($stext, qr/max_recipients: 1/, 'stock guide: one recipient per transaction');
like($stext, qr/smtp_port: 10572/, 'stock guide: Mailman submits to the routing listener');
like($stext, qr/--wrap-single-part/, 'stock guide: the wrapping milter');
like($stext, qr/X-DKIM2-Snapshot/, 'stock guide: explains the snapshot token');
like($stext, qr/cleanup_service_name=cleanup-dkim2/, 'stock guide: port 25 keeps the hashed headers');
like($stext, qr/recast_multipart/, 'stock guide: says content filtering undoes the wrap');
like($stext, qr/disable_mime_output_conversion = yes/, 'stock guide: warns about transport conversion');
unlike($stext, qr{/root/interop|/opt/dkim2}, 'stock guide: no dkim2.com box paths');
unlike($stext, qr/^(?:smtp_port|max_recipients):[^\n#]*#/m, 'stock guide: no inline mailman.cfg comments');
like($text, qr{dkim2-postfix-stock-mailman-guide\.md}, 'the list-host guide points to the stock guide');

my $index = do { local (@ARGV, $/) = "$root/deploy/www/index.html"; <> };
like($index, qr{docs/dkim2-postfix-list-host-guide\.md}, 'dkim2.com links to the guide');
like($index, qr{docs/dkim2-postfix-stock-mailman-guide\.md}, 'dkim2.com links to the stock-Mailman guide');
my $opguide = do { local (@ARGV, $/) = "$root/docs/dkim2-operator-guide.md"; <> };
like($opguide, qr{dkim2-postfix-list-host-guide\.md}, 'the operator guide links to it');
like($opguide, qr{dkim2-postfix-stock-mailman-guide\.md}, 'the operator guide links to the stock guide');
done_testing;
