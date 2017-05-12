use strict;
use warnings;

use Test::More;
use Google::AJAX::Library;

use constant AUTHOR_TESTING => $ENV{AUTHOR_TESTING} ? 1 : 0;

plan qw/no_plan/;

sub existing($;$) {
    my $library = shift;
    my $missing = shift || 0;
    SKIP: {
        skip "Not going out to http://ajax.googleapis.com to test existence" unless AUTHOR_TESTING;
        $missing ? 
            ok(!$library->exists, $library->uri . " does not exist") :
            ok($library->exists, $library->uri . " exists")
        ;
    }
}

sub missing {
    return existing shift, 1;
}

my $library;

ok($library = Google::AJAX::Library->new(qw/name jquery/));
is($library->version, '1');
is($library->uri, "http://ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js");
existing $library;

ok($library = Google::AJAX::Library->new(qw/name jquery version 1.2.3 uncompressed true/));
is($library->version, '1.2.3');
is($library->uri, "http://ajax.googleapis.com/ajax/libs/jquery/1.2.3/jquery.js");
existing $library;

ok($library = Google::AJAX::Library->new(qw/name jquery version 1.2.6 uncompressed false/));
is($library->version, '1.2.6');
is($library->uri, "http://ajax.googleapis.com/ajax/libs/jquery/1.2.6/jquery.min.js");
existing $library;

ok($library = Google::AJAX::Library->new(qw/name jquery version 8.3.1/));
is($library->version, '8.3.1');
is($library->uri, "http://ajax.googleapis.com/ajax/libs/jquery/8.3.1/jquery.min.js");
missing $library;


ok($library = Google::AJAX::Library->new(qw/name prototype/));
is($library->version, '1');
is($library->uri, "http://ajax.googleapis.com/ajax/libs/prototype/1/prototype.js");
existing $library;


ok($library = Google::AJAX::Library->new(qw/name scriptaculous version 0/));
is($library->version, '1');
is($library->uri, "http://ajax.googleapis.com/ajax/libs/scriptaculous/1/scriptaculous.js");
existing $library;

ok($library = Google::AJAX::Library->new(qw/name scriptaculo.us version 1.8/));
is($library->version, '1.8');
is($library->uri, "http://ajax.googleapis.com/ajax/libs/scriptaculous/1.8/scriptaculous.js");
existing $library;


ok($library = Google::AJAX::Library->new(qw/name mootools/));
is($library->version, '1');
is($library->uri, "http://ajax.googleapis.com/ajax/libs/mootools/1/mootools-yui-compressed.js");
existing $library;


ok($library = Google::AJAX::Library->new(qw/name dojo/));
is($library->version, '1');
is($library->uri, "http://ajax.googleapis.com/ajax/libs/dojo/1/dojo/dojo.xd.js");
existing $library;
