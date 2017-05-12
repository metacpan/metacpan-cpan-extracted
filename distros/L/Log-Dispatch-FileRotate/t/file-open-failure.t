#!/usr/bin/env perl -w
#
# Test case for what happens when filename cannot be written to
#

use strict;
use warnings;
use Test::More 0.88;
use Path::Tiny 0.018;
use Test::Warn;

# we need to make sure we are in the correct locale so that we get "Permission
# denied" as the error message, not a translation of that into another locale

unless (eval { require POSIX; 1 }) {
    plan skip_all => 'POSIX module is required for this test';
}

if ($> == 0) {
    plan skip_all => 'root user is exempt from file RW permissions restrictions';
}

my $locale = 'en_US.UTF-8';
my $curloc = POSIX::setlocale(&POSIX::LC_ALL, $locale) || '';
unless ($curloc eq $locale) {
    plan skip_all => "locale $locale is not available on this system";
}

use_ok 'Log::Dispatch::FileRotate';

my $tempdir = Path::Tiny->tempdir;

# Create a file that isn't writable
my $filename = $tempdir->child('myerrs.log')->stringify;
open my $o, '>', $filename;
close $o;
chmod 0, $filename;

warning_is(
    sub {
        my $file_logger = eval {
            Log::Dispatch::FileRotate->new(
                filename    => $filename,
                min_level   => 'debug',
                mode        => 'append',
                max         => 5,
                newline     => 0,
                DatePattern => 'YYYY-dd-HH');
        };

        like(
            $@,
            qr/Cannot write to '.*myerrs.log': Permission denied/,
            'Expect a "Permission denied" error'
        );
    },
    undef,
    'No warnings from using an unwritable filename'
);

done_testing;
