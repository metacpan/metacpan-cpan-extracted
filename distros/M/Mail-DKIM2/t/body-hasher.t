#!/usr/bin/perl
# Mail::DKIM2::BodyHasher: the body hash body_digest_raw gives, from a
# message fed in pieces of any size, whatever falls across a piece boundary.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Scalar::Util qw(weaken);
use Mail::DKIM2::BodyHasher;
use Mail::DKIM2::MessageInstance;

my $HEAD = "From: a\@example.com\r\nSubject: hi\r\n\r\n";

sub raw { Mail::DKIM2::MessageInstance::body_digest_raw(@_) }

# Feed $HEAD . $body to a hasher $size bytes at a time.
sub hashed {
    my ($body, $size, @algs) = @_;
    my $h = Mail::DKIM2::BodyHasher->new(@algs ? (Algs => \@algs) : ());
    my $text = $HEAD . $body;
    $h->PRINT(substr($text, $_ * $size, $size))
        for 0 .. int((length($text) - 1) / $size);
    $h->CLOSE;
    return $h;
}

my @bodies = (
    '', "\r\n", "\r\n\r\n", 'x', "x\r\n", "x\r\n\r\n\r\n", "x\n\n",
    "x\r", "x\r\r\n", "x\r\n\r", "\r\n\r\nx\r\n", "a\nb\r\nc\n",
    "trailing spaces  \r\n\r\n", "mixed\r\n\n\r\n",
);
for my $body (@bodies) {
    (my $name = $body) =~ s/\r/\\r/g;
    $name =~ s/\n/\\n/g;
    for my $size (1, 2, 3, 7, 1000) {
        is(hashed($body, $size)->body_hash, raw($body),
            "\"$name\" in pieces of $size");
    }
}

subtest 'a body over the megabyte it holds back' => sub {
    my $line = ('z' x 70) . "\r\n";
    for my $tail ('', "\r\n", "\r\n\r\n", "\r") {
        my $body = ($line x 40_000) . "end$tail";
        for my $size (65536, 1 << 20, 3 << 20) {
            is(hashed($body, $size)->body_hash, raw($body),
                length($body) . " bytes, pieces of $size");
        }
    }
    my $breaks = "x" . ("\r\n" x 600_000);
    is(hashed($breaks, 65536)->body_hash, raw($breaks),
        'a megabyte of trailing line breaks');
};

subtest 'as MessageInstance->calculate hashes the body' => sub {
    my $body = "hello\r\nworld\r\n\r\n";
    my $mi = Mail::DKIM2::MessageInstance->calculate($HEAD . $body);
    is(hashed($body, 5)->body_hash, $mi->body_hash, 'the b= of m=1');
};

subtest 'several algorithms' => sub {
    my $body = "one\r\ntwo\r\n";
    my $h = hashed($body, 3, qw(sha256 SHA512));
    is_deeply($h->body_hashes,
        { sha256 => raw($body, 'sha256'), sha512 => raw($body, 'sha512') },
        'body_hashes, keyed by lower-case name');
    is($h->body_hash('sha512'), raw($body, 'sha512'), 'body_hash($alg)');
    ok(!eval { $h->body_hash('sha1'); 1 }, 'an algorithm not asked for croaks');
};

subtest 'load from a filehandle' => sub {
    my $body = ("line\n" x 50_000) . "last\n\n";
    (my $lf_head = $HEAD) =~ s/\r\n/\n/g;
    open(my $fh, '<', \($lf_head . $body)) or die;
    my $h = Mail::DKIM2::BodyHasher->new->load($fh);
    is($h->body_hash, raw($body), 'LF file, read in pieces');
    is(scalar @{$h->{headers}}, 2, 'the header fields are parsed');
};

subtest 'a CRLF across the filehandle read boundary' => sub {
    my $piece = Mail::DKIM2::HeaderParser::READ_PIECE;
    for my $shift (-2 .. 2) {
        # The CR is at READ_PIECE - 1 + $shift in the file.
        my $body = ('y' x ($piece - 1 + $shift - length $HEAD)) . "\r\nz\r\n";
        open(my $fh, '<', \($HEAD . $body)) or die;
        is(Mail::DKIM2::BodyHasher->new->load($fh)->body_hash, raw($body),
            "CR at the boundary $shift");
    }
    open(my $fh, '<', \"${HEAD}x\r") or die;
    is(Mail::DKIM2::BodyHasher->new->load($fh)->body_hash, raw("x\r"),
        'a CR that ends the file');
};

subtest 'mistakes croak' => sub {
    ok(!eval { Mail::DKIM2::BodyHasher->new(Algs => ['md5']); 1 },
        'unknown algorithm');
    ok(!eval { Mail::DKIM2::BodyHasher->new(Algs => []); 1 }, 'no algorithm');
    my $h = Mail::DKIM2::BodyHasher->new;
    ok(!eval { $h->body_hashes; 1 }, 'body_hashes before CLOSE');
};

subtest 'no reference cycle' => sub {
    my $h = hashed("x\r\n", 2);
    weaken(my $weak = $h);
    undef $h;
    ok(!defined $weak, 'freed once the caller lets go');
};

done_testing;
