#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf::Exception;

my $ex;
my $file = __FILE__;
my $line;

$ex = MVC::Neaf::Exception->new( 403 ); $line = __LINE__;

is   $ex->status, 403, "Status preserved";
ok  !$ex->is_sudden, "Error anticipated";
like $ex->reason, qr/403 at \Q$file\E line \d+$/, "Reason as expected";
is   $ex->file_and_line, " at $file line $line", "Somewhere in this file";
like $ex, qr/^MVC::Neaf/, "Stringified with MVC::Neaf mention";

$ex = MVC::Neaf::Exception->new( "Foobared at /foo/bar line 137.\n" );

is   $ex->status, 500, "status = 500 by default";
ok   $ex->is_sudden, "Error not expected";
like $ex->reason, qr/Foobared/, "Reason came through";
is   $ex->file_and_line, " at /foo/bar line 137", "file:line as expected";
unlike $ex, qr/^MVC::Neaf/, "MVC::Neaf not mentioned";

$ex = MVC::Neaf::Exception->new( 405, -headers => [ Allow => 'GET, POST' ] );

is_deeply $ex->make_reply(My::Fake::Request->new)->{-headers}, [
         Allow => 'GET, POST',
    ], "Header round trip";

$ex = MVC::Neaf::Exception->new( 405, -location => '/', -headers => [ Allow => 'GET, POST' ] );
is_deeply $ex->make_reply(My::Fake::Request->new)->{-headers}, [
        Location => '/',
        Allow    => 'GET, POST',
    ], "Header round trip (redir)";


done_testing;

package My::Fake::Request;

sub new {
    return bless {}, shift;
};

sub id {
    1;
};
