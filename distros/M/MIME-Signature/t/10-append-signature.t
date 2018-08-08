#!perl
use 5.006;
use strict;
use warnings;

use Test::More;
use Config;
use IPC::Open3 qw(open3);
use Path::Tiny qw(path);
use Symbol qw(gensym);

BEGIN {
    use_ok('MIME::Signature') || print "Bail out!\n";
}

for my $mail ( path(qw/t mails orig/)->children ) {
    for my $sig ( path(qw/t sigs/)->children ) {
        open3 my $in, my $out, my $err = gensym,
          $Config{perlpath} => path(qw/bin append-signature/),
          '-plain-file'     => $sig;
        print $in $mail->slurp;
        close $in;
        local $/;
        my $result   = <$out>;
        my $errors   = <$err>;
        my $expected = path(
            't/mails/',
            my $_mail = $mail->basename,
            my $_sig  = $sig->basename,
        )->slurp;
        is $result, $expected, "$_sig to $_mail ok";

        if ( length $expected ) {
            is $errors, '', "no errors for $_sig to $_mail";
        }
        else {
            like $errors, qr/^Cannot handle /, "Cannot handle $_sig to $_mail";
        }
    }
}

done_testing;
