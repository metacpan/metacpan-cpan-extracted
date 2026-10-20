#!perl
use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Raw ();
use File::Raw::Base64;
use File::Raw::JSON ();
use MIME::Base64 ();

# Decoding and encoding against MIME::Base64 for every length 0-300, wrapped
# and not, CRLF, URL-safe; then the recorded corpus (xt/make-corpus.pl): every
# case gives the bytes, or the error at the offset, it gave when recorded.
# The & call form throughout: File::Raw's custom-op form refuses a hash or an
# array in its argument list.

plan skip_all => 'RELEASE_TESTING not set' unless $ENV{RELEASE_TESTING};

srand 20261019;
my $dir  = File::Temp->newdir;
my $path = "$dir/f";
sub bytes { join '', map { chr int rand 256 } 1 .. $_[0] }
sub dec { my ($in, @o) = @_; File::Raw::spew($path, $in) or die; &File::Raw::slurp($path, @o) }
sub enc { my ($in, @o) = @_; &File::Raw::spew($path, $in, @o) or die; File::Raw::slurp($path) }
# lines of $w characters, each ended by $eol, the last too (when there is one)
sub wrapped { my ($s, $w, $eol) = @_; join '', map { "$_$eol" } $s =~ /(.{1,$w})/gs }

my ($bad, $n) = (0, 0);
for my $len (0 .. 300, 4096, 1 << 20) {
    my $b = bytes($len);
    my @checks = (
        [ 'decode unwrapped', dec(MIME::Base64::encode_base64($b, ''), plugin => 'base64'), $b ],
        [ 'decode wrapped 76', dec(MIME::Base64::encode_base64($b), plugin => 'base64'), $b ],
        [ 'decode CRLF', dec(MIME::Base64::encode_base64($b) =~ s/\n/\r\n/gr, plugin => 'base64'), $b ],
        [ 'decode url', dec(MIME::Base64::encode_base64url($b), plugin => 'base64url'), $b ],
        [ 'decode strict', dec(MIME::Base64::encode_base64($b, ''), plugin => 'base64', strict => 1), $b ],
        [ 'encode unwrapped', enc($b, plugin => 'base64'), MIME::Base64::encode_base64($b, '') ],
        [ 'encode url', enc($b, plugin => 'base64url', padding => 0), MIME::Base64::encode_base64url($b) ],
        [ 'encode wrapped 76', enc($b, plugin => 'base64', wrap => 76), MIME::Base64::encode_base64($b) ],
        [ 'encode wrapped 64', enc($b, plugin => 'base64', wrap => 64), wrapped(MIME::Base64::encode_base64($b, ''), 64, "\n") ],
        [ 'encode wrapped 10, CRLF', enc($b, plugin => 'base64', wrap => 10, eol => "\r\n"), wrapped(MIME::Base64::encode_base64($b, ''), 10, "\r\n") ],
    );
    for my $c (@checks) {
        $n++;
        next if defined $c->[1] && $c->[1] eq $c->[2];
        $bad++;
        diag "$len bytes, $c->[0]: differs" if $bad <= 5;
    }
}
is $bad, 0, "decode and encode agree with MIME::Base64 on all $n checks";

my $corpus = File::Raw::JSON::file_json_decode(File::Raw::slurp('xt/data/corpus.json'));
my $drift = 0;
for my $case (@{ $corpus->{cases} }) {
    my $in  = pack 'H*', $case->{input};
    my $out = eval { dec($in, plugin => $case->{plugin}, %{ $case->{opts} }) };
    (my $err = $@) =~ s/ at \S+ line \d+\.?\n\z//;
    my $ok = exists $case->{output}
        ? (defined $out && unpack('H*', $out) eq $case->{output})
        : (!defined $out && $err eq $case->{error});
    next if $ok;
    $drift++;
    diag sprintf "corpus case (%s %s): want %s, got %s", $case->{plugin}, join(',', %{ $case->{opts} }),
        $case->{error} // 'bytes', defined $out ? 'bytes ' . unpack('H*', substr($out, 0, 8)) : $err if $drift <= 5;
}
is $drift, 0, scalar(@{ $corpus->{cases} }) . " recorded cases (from $corpus->{version}) reproduced exactly";

done_testing;
