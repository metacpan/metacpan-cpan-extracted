use strict;
use warnings;
use Test::More;
use FindBin;

# The operator guide names files in this repository and settings the rest
# of the repository implements; this keeps it from drifting.

my $root = "$FindBin::Bin/../..";
my $guide = "$root/docs/dkim2-postfix-list-host-guide.md";
ok(-f $guide, 'the guide exists') or BAIL_OUT('no guide');
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
like($text, qr/logging\.dkim2/, 'tells Mailman where dkim2.log comes from');
like($text, qr/not (?:been )?tested end to end/i, 'the authentication_milter path is labelled as untested');
like($text, qr/wwsympa/, 'Sympa restart list includes wwsympa');
like($text, qr/git -c user\.name/, 'git am works on a host with no identity');
like($text, qr/i=1\.\.1 verified/, 'the plain-upstream example shows i=1..1');

my $index = do { local (@ARGV, $/) = "$root/deploy/www/index.html"; <> };
like($index, qr{docs/dkim2-postfix-list-host-guide\.md}, 'dkim2.com links to the guide');
my $opguide = do { local (@ARGV, $/) = "$root/docs/dkim2-operator-guide.md"; <> };
like($opguide, qr{dkim2-postfix-list-host-guide\.md}, 'the operator guide links to it');
done_testing;
