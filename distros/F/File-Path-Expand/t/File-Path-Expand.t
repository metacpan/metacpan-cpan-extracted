#!perl -w
use strict;
use Test::More tests => 8;
use Sys::Hostname;
BEGIN { use_ok('File::Path::Expand') };

$ENV{HOME} = '/some/path';
is( expand_filename('~/foo'), "/some/path/foo", 'uses $HOME' );
is( expand_filename('~'), $ENV{HOME}, '...and similarly for ~' );

SKIP: {
    skip "only guaranteed on penfold", 5
      unless hostname eq 'penfold.unixbeard.net';

  SKIP: {
        skip "have to be richardc too", 2
          unless $> eq 1000;

        $ENV{HOME} = '';
        is( expand_filename("~/foo"), "/home/richardc/foo",
            'without $HOME ~/' );
        is( expand_filename("~"), "/home/richardc",
            '...and similarly for ~' );
    }

    is( expand_filename('~root/foo'), "/root/foo", 'root' );
    is( expand_filename('~root'), "/root", '...and similarly for ~root' );

    eval { expand_filename('~frooby/') };
    like( $@, qr{^no such user 'frooby'}, "failure" );
}


