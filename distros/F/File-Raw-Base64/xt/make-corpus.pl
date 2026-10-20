#!perl
# Records what the CURRENT decoder does with a fixed set of inputs, valid and
# not, lenient and strict, into xt/data/corpus.json, for xt/oracle.t to hold
# every later version to: the same bytes out, or the same error at the same
# offset. Deterministic: run it again on the same code and the file is the
# same. Run it only to record a deliberate change of behaviour.
use strict;
use warnings;
use File::Temp ();
use File::Raw ();
use File::Raw::Base64;
use MIME::Base64 ();

srand 4648;
my $dir = File::Temp->newdir;
my @cases;
sub bytes { join '', map { chr int rand 256 } 1 .. $_[0] }
sub add {
    my ($plugin, $input, %opt) = @_;
    my $path = "$dir/in";
    File::Raw::spew($path, $input) or die;
    # the & form: File::Raw 0.18/0.19 die on a hash or array in the argument
    # list of the custom-op form ("odd number of options")
    my $out = eval { &File::Raw::slurp($path, plugin => $plugin, %opt) };
    my $err = $@;
    $err =~ s/ at \S+ line \d+\.?\n\z//;
    push @cases, { plugin => $plugin, input => unpack('H*', $input), opts => {%opt},
                   defined $out ? (output => unpack('H*', $out)) : (error => $err) };
}

for my $len (0 .. 40, 57, 58, 76, 77, 1000) {
    my $b = bytes($len);
    my $enc = MIME::Base64::encode_base64($b, '');
    add(base64 => $enc);
    add(base64 => MIME::Base64::encode_base64($b));                     # wrapped at 76
    (my $crlf = MIME::Base64::encode_base64($b)) =~ s/\n/\r\n/g;
    add(base64 => $crlf);
    (my $nopad = $enc) =~ s/=+\z//;
    add(base64 => $nopad);
    add(base64 => $nopad, strict => 1);
    my $url = MIME::Base64::encode_base64url($b);
    add(base64url => $url);
    add(base64url => $url, strict => 1);
    # noise: stray bytes at random places, lenient then strict
    my $noisy = $enc;
    for (1 .. 1 + int rand 3) {
        substr($noisy, int rand(length($noisy) + 1), 0) = (' ', '!', "\x{ff}", '.', "\t", '-', '_')[ int rand 7 ];
    }
    add(base64 => $noisy);
    add(base64 => $noisy, strict => 1);
    # an alphabet byte after padding
    add(base64 => "$enc" . 'QQ==', strict => 1) if $enc =~ /=\z/;
    add(base64 => "$enc" . 'QQ==') if $enc =~ /=\z/;
}
# padding on a quartet boundary, then more: lenient decodes on, strict refuses
for my $s (qw(QUJD=QUJD QUJD==QUJD QUJD===QUJD QUJD=QUJD= QUJDQUJD=QUJD QUJD=Q QUJD=QQ==)) {
    add(base64 => $s);
    add(base64 => $s, strict => 1);
}
# truncation and odd tails
add(base64 => $_) for qw(Q QQ QQQ QQQQQ Q=== QQ= QQQ= =QQQ);
add(base64 => $_, strict => 1) for qw(Q QQ QQQ QQQQQ Q=== QQ= QQQ= =QQQ);
# PEM
my $der = bytes(300);
my $pem = "-----BEGIN CERTIFICATE-----\n" . MIME::Base64::encode_base64($der) . "-----END CERTIFICATE-----\n";
add(base64 => $pem, pem => 1);
add(base64 => "junk\n$pem", pem => 1);
(my $badlabel = $pem) =~ s/END CERTIFICATE/END KEY/;
add(base64 => $badlabel, pem => 1);
add(base64 => MIME::Base64::encode_base64($der), pem => 1);

require File::Raw::JSON;
File::Raw::spew('xt/data/corpus.json',
    File::Raw::JSON::file_json_encode({ version => $File::Raw::Base64::VERSION, cases => \@cases },
        pretty => 1, sort_keys => 1) . "\n") or die;
printf "%d cases recorded from File::Raw::Base64 %s\n", scalar @cases, $File::Raw::Base64::VERSION;
