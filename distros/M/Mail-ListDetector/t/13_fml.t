use strict;
use Test::More tests => 3;

use FileHandle;
use Mail::Internet;
use Mail::ListDetector;
use Mail::ListDetector::Detector::Fml;

my $msg = FileHandle->new('t/fml-match');
my $mail = Mail::Internet->new($msg);
my $list = Mail::ListDetector->new($mail);

is $list->listname, 'mlname';
is $list->posting_address, 'mlname@domain.example.com';
is $list->listsoftware, 'fml 4.0 STABLE (20010208)';

