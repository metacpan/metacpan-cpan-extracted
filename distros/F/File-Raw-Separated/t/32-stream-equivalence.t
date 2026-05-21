use strict;
use warnings;
use Test::More;
use File::Raw::Separated qw(import);
use File::Temp qw(tempfile);

# Same fixture parsed via slurp+file_csv_parse_buf and via file_csv_parse_stream
# must yield identical AoA. This is the canary that the streaming path
# uses the same parser core — no behavioural drift.

my @cases = (
    "a,b,c\n",
    "a,b,c\nd,e,f\n",                   # multi-row
    qq("a,b","c""d",e\n),               # quoted + escapes
    qq("multi\nline",x\nplain,y\n),     # embedded newlines
    "a,b\r\nc,d\r\n",                   # CRLF
    "no_trailing_nl,here",              # missing final newline
    "",                                  # empty
);

for my $case (@cases) {
    my ($fh, $path) = tempfile(SUFFIX => '.csv', UNLINK => 1);
    print $fh $case;
    close $fh;

    my $via_buf = file_csv_parse_buf($case);
    my @via_stream;
    file_csv_parse_stream($path, sub { push @via_stream, [@{$_[0]}] });

    my $label = sprintf("case %d (%d bytes)", scalar(@cases) - @cases + 1, length $case);
    is_deeply(\@via_stream, $via_buf, "stream == buf for $label")
        or diag("input: ", explain($case),
                "\nbuf:    ", explain($via_buf),
                "\nstream: ", explain(\@via_stream));
}

done_testing;
