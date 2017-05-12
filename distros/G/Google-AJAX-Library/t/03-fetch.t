use strict;
use warnings;

use Test::More;
use Google::AJAX::Library;
use File::Temp qw/tempfile/;

use constant AUTHOR_TESTING => $ENV{AUTHOR_TESTING} ? 1 : 0;
use constant jQuery_HEAD => <<'_END_';
/*
 * jQuery 1.2.3 - New Wave Javascript
 *
 * Copyright (c) 2008 John Resig (jquery.com)
 * Dual licensed under the MIT (MIT-LICENSE.txt)
 * and GPL (GPL-LICENSE.txt) licenses.
 *
 * $Date: 2008/05/23 $
 * $Rev: 4663 $
 */
_END_

plan skip_all => "Not going out to http://ajax.googleapis.com to test fetching/writing" unless AUTHOR_TESTING;
plan qw/no_plan/;

my $library = shift;

$library = Google::AJAX::Library->new(qw/name jquery version 1.2.3/);
ok($library->exists);

ok(0 <= index $library->fetch, jQuery_HEAD);

my $content = "";
ok($library->fetch(\$content));
ok(0 <= index $content, jQuery_HEAD);

{
    my ($handle, $file) = tempfile;
    ok($library->write($handle));
    $handle->flush;
    ok(-f $file);
    is(-s _, 54041);
}

{
    my ($handle, $file) = tempfile;
    ok($library->write($file));
    ok(-f $file);
    is(-s _, 54041);
}

$library->write(\*STDERR) if 0;
