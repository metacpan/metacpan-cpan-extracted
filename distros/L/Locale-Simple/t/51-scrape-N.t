use strict;
use warnings;
use Test::More;

use Test::InDistDir;
use Capture::Tiny 'capture';
use Locale::Simple::Scraper 'scrape';

# For each (Perl, JS, Python) fixture pair — an l*-call file and its
# N*_-call twin — scrape both and confirm byte-identical .pot output
# (minus the filename comment). Proves the N* markers emit the same
# msgid/msgid_plural/msgctxt/domain entries as their runtime twins.

for my $lang ( qw( pl js py ) ) {
    my $l_out = scrape_one( "l-calls.$lang",  $lang );
    my $n_out = scrape_one( "N-calls.$lang",  $lang );
    is( $n_out, $l_out, "$lang: N*_ markers produce same .pot as l*()" );
}

done_testing;

sub scrape_one {
    my ( $file, $lang ) = @_;

    my ( $out, $err ) = capture {
        scrape(
            '--only',            "n-fixtures/\Q$file\E",
            '--no_line_numbers',
        );
    };

    # Drop the #: file comment — we're comparing payloads, not paths.
    $out =~ s{^\#:[^\n]*\n}{}mg;
    return $out;
}
