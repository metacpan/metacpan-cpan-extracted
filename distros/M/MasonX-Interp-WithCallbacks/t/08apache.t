#!perl -w

use strict;
use Test::More;

BEGIN {
    plan skip_all => 'Testing of apache_req requires Apache::Test 1.04'
      unless eval { require Apache::Test };

    plan skip_all => 'Test of apache_req requires mod_perl'
      unless Apache::Test::have_module('mod_perl.c');

    require Apache::TestRequest;
    Apache::TestRequest->import(qw(GET POST));

    plan tests => 178;
}

Apache::TestRequest::user_agent(
    reset                 => 1,
    requests_redirectable => 0,
);

my $key = 'myCallbackTester';
my @keys = (
    myCallbackTester => '/test',
    OOCBTester       => '/oop',
    OOCBTester       => '/ooconf',
);

##############################################################################
# Just make sure it works.
while (my $key = shift @keys) {
    my $uri = shift @keys;
    ok( my $res = GET("$uri?$key|simple_cb=1"), "Get response" );
    is( $res->code, 200, "Check simple response code" );
    is( $res->content, "Success", 'Check simple content' );

    # Make sure that POST works.
    ok( $res = POST($uri, ["$key|simple_cb" => 1]), "Get POST response" );
    is( $res->code, 200, "Check simple POST response code" );
    is( $res->content, "Success", 'Check simple POST content' );

    # Check that multiple callbacks execute in priority order.
    ok( $res = POST($uri,
                    [ "$key|priority_cb0" => 0,
                      "$key|priority_cb2" => 2,
                      "$key|priority_cb9" => 9,
                      "$key|priority_cb7" => 7,
                      "$key|priority_cb1" => 1,
                      "$key|priority_cb4" => 4,
                      "$key|priority_cb"  => 'def' ]
                   ),
        "Get execution order response" );
    is( $res->code, 200, "Check execution order response code" );
    is( $res->content, " 0 1 2 4 5 7 9", 'Check execution order content' );

    # Execute the one callback with an array of values
    ok( $res = POST($uri,
                    [ "$key|multi_cb" => 1,
                      "$key|multi_cb" => 1,
                      "$key|multi_cb" => 1,
                      "$key|multi_cb" => 1,
                      "$key|multi_cb" => 1 ]
                   ),
        "Get array response" );
    is( $res->code, 200, "Check array response code" );
    is( $res->content, 5, 'Check array content' );

    # Emmulate the sumission of an <input type="image" /> button.
    ok( $res = POST($uri,
                    [ "$key|simple_cb.x" => 18,
                      "$key|simple_cb.y" => 24 ]
                   ),
        "Get image button response" );
    is( $res->code, 200, "Check image button code" );
    is( $res->content, "Success", 'Check image button content' );

    # Make sure that an image submit doesn't cause the callback to be called
    # twice.
    ok( $res = POST($uri,
                    [ "$key|count_cb.x" => 18,
                      "$key|count_cb.y" => 24 ]
                   ),
        "Get image button count response" );
    is( $res->code, 200, "Check image button count response code" );
    is( $res->content, 1, 'Check image button count content' );

    # Try the pre request callback.
    ok( $res = POST($uri,
                    [ do_upper => 1,
                      result => 'yowza!' ]),
        "Get pre request callback response" );
    is( $res->code, 200, "Check pre request callback code" );
    is( $res->content, "YOWZA!", 'Check pre request callback content' );

    # Try the post request callback.
    ok( $res = POST($uri,
                    [ "$key|simple_cb" => 1,
                      do_lower => 1 ]),
        "Get post request callback response" );
    is( $res->code, 200, "Check post request callback code" );
    is( $res->content, "success", 'Check post request callback content' );

    ##########################################################################
    # Fun with notes.
    my $note_key = 'myNote';
    my $note = 'Test note';
    ok( $res = POST($uri,
                    [ "$key|add_note_cb1" => $note_key, # Executes first.
                      note                => $note,
                     "$key|get_note_cb"  => $note_key]),
        "Get note response" );
    is( $res->code, 200, "Check note callback code" );
    is( $res->content, $note, "Check note callback result" );

    # Make sure the note isn't available on the next request.
    ok( $res = POST($uri, ["$key|get_note_cb" => $note_key]),
        "Get no note response" );
    is( $res->code, 200, "Check no note code" );
    is( $res->content, '', "Check no note result" );

    # Add multiple notes.
    ok( $res = POST($uri,
                    [ "$key|add_note_cb1"   => $note_key, # Executes first.
                      "$key|add_note_cb2"   => $note_key . 1, # Executes second.
                      note                  => $note,
                     "$key|list_notes_cb"  => 1 ]),
        "Get multiple note response" );
    is( $res->code, 200, "Check no note code" );
    is( $res->content, "$note_key => $note\n${note_key}1 => $note\n",
        "Check multiple note result" );

    # Make sure that notes percolate back to Mason.
    ok( $res = POST($uri,
                    [ "$key|add_note_cb1"  => $note_key,
                      note                 => $note,
                      "$key|mason_note_cb" => $note_key,
                    ]),
        "Get mason note response" );
    is( $res->code, 200, "Check mason note code" );
    is( $res->content, $note, "Check mason note result" );

    # Make sure that we can still get at the notes via the callback request
    # object in Mason components.
    ok( $res = POST($uri,
                    [ "$key|add_note_cb"   => $note_key,
                      note                 => $note,
                      "$key|cbr_note_cb"   => $note_key,
                    ]),
        "Get cb_request note respone" );
    is( $res->code, 200, "Check cb_request note code" );
    is( $res->content, $note, "Check cb_request note result" );

    # Finally, make sure that if we clear it in callbacks, that no one gets it.
    ok( $res = POST($uri,
                    [ "$key|add_note_cb1"  => $note_key, # Executes first.
                      note                 => $note,
                      "$key|clear_cb"      => 1,
                      "$key|mason_note_cb" => 1,
                    ]),
        "Get Mason cleared note response" );
    is( $res->code, 200, "Check Mason cleared note code" );
    is( $res->content, '', "Check Mason cleared note result" );

    ok( $res = POST($uri,
                    [ "$key|add_note_cb1"  => $note_key, # Executes first.
                      note                 => $note,
                      "$key|clear_cb"      => 1,
                      "$key|cbr_note_cb"   => $note_key,
                    ]),
        "Get cb_request cleared note response" );
    is( $res->code, 200, "Check cb_request cleared note code" );
    is( $res->content, '', "Check cb_request cleared note result" );
}

##############################################################################
# Make sure an exception get thrown for a non-existant package.
ok( my $res = POST("/test?myNoSuchLuck|foo_cb=1"),
    "Get non-existent callback response" );
is( $res->code, 500, "Check non-existent callback response code" );

# Make sure that redirects work.
SKIP: {
    skip "Redirect tests rrequire Apache::Test 1.04 or newer", 8
      unless Apache::Test->VERSION >= 1.04;
    ok( $res = POST("/test",
                    ["$key|redir_cb" => 0,
                     "$key|add_header_cb9" => 1,
                     "header" => 'Age',
                     "value" => 42 ]
                ),
        "Get redirect response" );
    is( $res->code, 302, "Check redirect response code" );
    is( $res->header('Location'), 'http://example.com/',
        "Check redirect location" );
    is( $res->header('Age'), undef, "Check redirect Age header" );

    # Make sure that redirect without abort works.
    ok( $res = POST("/test",
                    ["$key|redir_cb0" => 1,
                     "$key|add_header_cb9" => 1,
                     "header" => 'Age',
                     "value" => 42 ]
                ),
        "Get redirect without abort response" );
    is( $res->code, 302, "Check redirect without abort response code" );
    is( $res->header('Location'), 'http://example.com/',
        "Check redirect without abort location" );
    is( $res->header('Age'), 42, "Check redirect without abort Age header" );
}

# Make sure that abort 200 works.
ok( $res = POST("/test", [ "$key|test_abort_cb" => 200 ]),
    "Get abort 200 request" );
is( $res->code, 200, "Check abort 200 response code" );

# Now try to die in the callback.
ok( $res = POST("/test", [ "$key|exception_cb" => 0 ]), "Get die response" );
is( $res->code, 500, "Check die response code" );

# Now try to throw and handle an exception in the callback.
ok( $res = POST("/exception_handler", [ "$key|exception_cb" => 1 ]),
    "Get exception handler response" );
is( $res->code, 200, "Check exception handler response code" );

# Now make sure that a callback with a value executes.
ok( $res = POST("/no_null", [ "$key|simple_cb" => 1 ]),
    "Get simle no null response" );
is( $res->code, 200, "Check simple no null code" );
is( $res->content, "Success", 'Check simple no null content' );

# Now make sure that a callback with a null string does not execute.
ok( $res = POST("/no_null", [ "$key|simple_cb" => '' ]),
    "Get simle no null response" );
is( $res->code, 200, "Check simple null code" );
is( $res->content, "", 'Check simple null content' );

# Test MasonCallbacks + MasonDefaultPkgKey.
ok( $res = POST("/conf", ["CBFoo|pkg_key_cb" => 1]),
    "Get MasonDefaultPkgKey response" );
is( $res->code, 200, "Check MasonDefaultPkgKey code" );
is( $res->content, 'CBFoo', 'Check MasonDefaultPkgKey content' );

# Test MasonCallbacks + MasonDefaultPriority.
ok( $res = POST("/conf", ["CBFoo|priority_cb" => 1]),
    "Get MasonDefaultPriority response" );
is( $res->code, 200, "Check MasonDefaultPriority code" );
is( $res->content, 3, 'Check MasonDefaultPriority content' );

# Test MasonPreCallbacks.
ok( $res = POST("/conf", [result => 'yes', do_upper => 1]),
    "Get MasonPreCallbacks response" );
is( $res->code, 200, "Check MasonPreCallbacks code" );
is( $res->content, 'YES', 'Check MasonPreCallbacks content' );

# Test MasonCbExceptionHandler.
ok( $res = POST("/conf", ["CBFoo|die_cb" => 1]),
    "Get MasonCbExceptionHandler response" );
is( $res->code, 200, "Check MasonCbExceptionHandler code" );
is( $res->content, '', 'Check MasonCbExceptionHandler content' );

# Test MasonPostCallbacks.
ok( $res = POST("/conf", [result => 'YES', do_lower => 1]),
    "Get MasonPostCallbacks response" );
is( $res->code, 200, "Check MasonPostCallbacks code" );
is( $res->content, 'yes', 'Check MasonPostCallbacks content' );

# Test MasonIgnoreNulls.
ok( $res = POST("/nulls_conf", ["CBFoo|exec_cb" => 1]),
    "Get MasonIgnoreNulls response" );
is( $res->code, 200, "Check MasonIgnoreNulls code" );
is( $res->content, 'executed', 'Check MasonIgnoreNulls content' );

# Test MasonIgnoreNulls.
ok( $res = POST("/nulls_conf", ["CBFoo|exec_cb" => '']),
    "Get MasonIgnoreNulls null response" );
is( $res->code, 200, "Check MasonIgnoreNulls null code" );
is( $res->content, '', 'Check MasonIgnoreNulls null content' );

1;
__END__

