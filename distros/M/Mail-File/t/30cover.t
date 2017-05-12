#!/usr/bin/perl -w
use strict;

# The test script is purely created to cover all the branches and
# conditionals that Devel::Cover highlighted weren't tested.

use Test::More tests => 14;

use Mail::File;
use File::Path;

my $path = 'mailfiles';
my $temp = 'mailfiles/mail-XXXXXX.eml';

# ensure a path is auto-created
my $mail = Mail::File->new(template => $temp);
ok(!-d $path);

# ensure unknown subs are caught
eval { $mail->BadHeader('blah'); };
like($@,qr/Unknown sub Mail::File::BadHeader/);

# check X-Header settings
my $retval = $mail->XHeader('Z-Header-1','This is a test');
is($retval, undef);
$retval = $mail->XHeader('X-Header-1','This is a test');
is($retval, 'This is a test');
$retval = $mail->XHeader('X-Header-1');
is($retval, 'This is a test');

# check we can't send without the default 4 fields
ok(!-d $path);
is($mail->send(), undef);
ok(-d $path);

$mail->From('me@example.com');
is($mail->send(), undef);
$mail->To('you@example.com');
is($mail->send(), undef);
$mail->Subject('Blah Blah Blah');
is($mail->send(), undef);
$mail->Body('Yadda Yadda Yadda');

my $file = $mail->send();
is(-r $file,1);

rmtree $path;

# check we can create a local file, from the default template
$mail = Mail::File->new();
$mail->From('me@example.com');
$mail->To('you@example.com');
$mail->Subject('Blah Blah Blah');
$mail->Body('Yadda Yadda Yadda');

$file = $mail->send();
is(-r $file,1);

unlink $file;

# check we can create a local file in the current directory
$temp = 'test-XXXXXX.eml';
$mail = Mail::File->new(template => $temp);
$mail->From('me@example.com');
$mail->To('you@example.com');
$mail->Subject('Blah Blah Blah');
$mail->Body('Yadda Yadda Yadda');

$file = $mail->send();
is(-r $file,1);

unlink $file;
