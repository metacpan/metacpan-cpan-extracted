#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 4;

#sub FileUpload::Filename::DEBUG { 1 };
sub FileUpload::Filename::VERBOSE { 0 };
use FileUpload::Filename;


eval {
    my $filename = FileUpload::Filename->name();
};
like($@, qr/Must provide a file name/, 'Must provide a file name');


eval {
    my $filename = FileUpload::Filename->name({
        filename  => 'C:\TMP\test with spaces.dat',
    });
};
like($@, qr/Can't get a UA to work with/, "Can't get a UA to work with");


{
    local $ENV{'HTTP_USER_AGENT'}
        = 'Mozilla/4.0 (compatible; MSIE 6.0; X11; Linux i686) Opera 7.23  [en]';

    my $filename = FileUpload::Filename->name({
        filename  => '/tmp/test.dat',
    });

    is($filename, 'test.dat', 'Setting HTTP_USER_AGENT environment variable');
}


{
    local $ENV{'HTTP_USER_AGENT'}
        = 'Mozilla/4.0 (compatible; MSIE 5.5; Windows 95)', 

    my $filename = FileUpload::Filename->name({
        filename  => 'C:\TMP\test with spaces.dat',
    });

    is($filename, 'test_with_spaces.dat', 'Setting HTTP_USER_AGENT environment variable');
}


