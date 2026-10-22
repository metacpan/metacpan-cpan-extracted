 #!/usr/bin/perl -w
use strict;
use warnings;
use Test::More tests => 2;
use MIME::Parser;

my $msg = join("\n",
'MIME-Version: 1.0',
'Content-Type: multipart/mixed; boundary="b"',
'', # end of header
'', # empty preamble: this line is lost with CRLF
'--b',
'Content-Type: text/plain',
'',
'hello',
'--b--',
'');

for my $eol ("\n", "\r\n") {
        my $str_eol;
        if ($eol eq "\n") {
                $str_eol = 'CR';
        } else {
                $str_eol = 'CRLF';
        }
        (my $in = $msg) =~ s/\n/$eol/g;
        my $parser = MIME::Parser->new;
        $parser->output_to_core(1);
        my $out = $parser->parse_data($in)->as_string;
        $out =~ s/\r\n/\n/g; # compare content, not line endings
        (my $want = $in) =~ s/\r\n/\n/g;
        is ($out, $want, "Reconstituted MIME message matches input when eol = $str_eol");
}

