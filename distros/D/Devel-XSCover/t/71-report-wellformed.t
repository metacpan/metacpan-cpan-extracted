use 5.020;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use File::Spec ();
use XSCoverTest ();

plan skip_all => 'Devel::Cover is not installed' unless eval { require Devel::Cover::DB; 1 };
plan skip_all => 'no cover script found' unless XSCoverTest::cover_script();

my ($tmp, $db, $dir, $perl_tmp, $perl) = XSCoverTest::report_db();
XSCoverTest::run_report($db, $dir);
opendir my $dh, $db or die;
my @pages = sort grep { /\.html\z/ } readdir $dh;
ok(@pages >= 6, 'pages to check');

my %void = map { $_ => 1 } qw(meta br hr img input link area base col embed source track wbr);
for my $page (@pages) {
    my $path = File::Spec->catfile($db, $page);
    open my $fh, '<', $path or die "$path: $!";
    my $html = do { local $/; <$fh> };
    close $fh;
    like($html, qr/^<!doctype html>/i, "$page starts with the doctype");
    like($html, qr/<meta name="viewport"/, "$page has a viewport");
    like($html, qr/prefers-color-scheme: dark/, "$page carries the dark theme");
    like($html, qr/:root\[data-theme="dark"\]/, 'and the override');
    unlike($html, qr/https?:\/\//, "$page loads nothing from the web");
    unlike($html, qr/<script[^>]*src=/, 'no external script');
    (my $body = $html) =~ s/<script>.*?<\/script>//s;
    $body =~ s/<style>.*?<\/style>//s;
    my @stack;
    my $balanced = 1;
    while ($body =~ /<(\/?)([a-zA-Z][a-zA-Z0-9]*)[^>]*?(\/?)>/g) {
        my ($close, $tag, $self) = ($1, lc $2, $3);
        next if $void{$tag} || $self || $tag eq '!doctype';
        if ($close) {
            my $open = pop @stack;
            if (!defined $open || $open ne $tag) {
                $balanced = 0;
                diag "$page: </$tag> closes " . ($open // 'nothing');
                last;
            }
        }
        else {
            push @stack, $tag;
        }
    }
    ok($balanced && !@stack, "$page balances its tags") or diag "left open: @stack";
}

my ($pm) = grep { /Spike-pm\.html$/ } @pages;
open my $fh, '<', File::Spec->catfile($db, $pm) or die;
my $pm_html = do { local $/; <$fh> };
like($pm_html, qr/&lt;b&gt;\$name&lt;\/b&gt;/, 'a tag in the source is escaped');
unlike($pm_html, qr/<pre>[^<]*<b>/, 'and never raw');
open $fh, '<', File::Spec->catfile($db, 'Spike-xs.html') or die;
my $xs_html = do { local $/; <$fh> };
like($xs_html, qr/if \(a &amp;&amp; b\)/, 'the && of the C source is escaped');

done_testing;
