# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More ( tests => 32 );
use Data::Dumper;
use strict;

BEGIN {
    use_ok('HTML::WebDAO');
    use_ok('HTML::WebDAO::Store::Abstract');
    use_ok('HTML::WebDAO::SessionSH');
    use_ok('HTML::WebDAO::Response');
    use_ok( 'File::Temp', qw/ tempfile tempdir / );
}
my $ID = "tcontainer";
ok my $store_ab = ( new HTML::WebDAO::Store::Abstract:: ), "Create store";
ok my $session = ( new HTML::WebDAO::SessionSH:: store => $store_ab ),
  "Create session";
$session->U_id($ID);
isa_ok my $response =
  ( new HTML::WebDAO::Response:: session => $session, cv => $session->Cgi_obj ),
  'HTML::WebDAO::Response', 'create object';
isa_ok $response->_cv_obj, 'HTML::WebDAO::CVcgi', 'check cv class';

isa_ok my $resp1 = $response->set_header( "-status", '403 Forbidden' ),
  'HTML::WebDAO::Response', 'check type set_header';
is_deeply { '-STATUS' => '403 Forbidden' }, $response->_headers,
  'check _headers';
isa_ok $resp1->set_header( -type => 'text/html; charset=utf-8' ),
  'HTML::WebDAO::Response', 'check type set_header';
is_deeply {
    '-TYPE'   => 'text/html; charset=utf-8',
    '-STATUS' => '403 Forbidden'
  },
  $response->_headers, 'check _headers after set set_header';
ok !$response->_is_headers_printed, 'check flg _is_headers_printed before';
isa_ok $response->print_header, 'HTML::WebDAO::Response',
  'check type print_header';
ok $response->_is_headers_printed, 'check flg _is_headers_printed before';

isa_ok my $response1 =
  ( new HTML::WebDAO::Response:: session => $session, cv => $session->Cgi_obj )
  ->redirect2url('http://test.com'), 'HTML::WebDAO::Response',
  'test redirect2url';
is_deeply { '-LOCATION' => 'http://test.com', '-STATUS' => '302 Found' },
  $response1->_headers, 'check redirect2url headers';

isa_ok my $response2 =
  ( new HTML::WebDAO::Response:: session => $session, cv => $session->Cgi_obj )
  ->set_cookie(
    -name  => 'name1',
    -value => 'test1',
    -path  => "/path1"
  )->set_cookie(
    -name  => 'name2',
    -value => 'test2',
    -path  => "/path2"
  ),
  'HTML::WebDAO::Response', 'test set_cookie';
ok ref $response2->get_header('-cookie'), "check get_header('-cookie')";
ok scalar @{ $response2->get_header('-cookie') } == 2,
  "check count cookie == 2";

#create test files
my ( $fh, $filename ) = tempfile();
print $fh "test\n";
close $fh;
isa_ok my $response3 =
  ( new HTML::WebDAO::Response:: session => $session, cv => $session->Cgi_obj )
  ->send_file( $filename, -type => 'image/jpeg' ), 'HTML::WebDAO::Response',
  'test send_file';
ok $response3->_is_file_send,     'check $response3->_is_file_send';
ok $response3->_is_need_close_fh, 'check $response3->_is_need_close_fh';
is $response3->get_mime_for_filename('test.jpg'), 'image/jpeg',
  'get_mime_for_filename("test.jpg")';

ok !$response3->_is_flushed, 'check $response3->_is_flushed before flush';
isa_ok $response3->flush, 'HTML::WebDAO::Response', '$response3->flush';
ok $response3->_is_flushed, 'check $response3->_is_flushed after flush';

my $test_call_back1 = 1;
my $test_call_back2 = 2;
isa_ok my $response4 =
  ( new HTML::WebDAO::Response:: session => $session, cv => $session->Cgi_obj )
  ->set_callback( sub { $test_call_back1++ } )
  ->set_callback( sub { $test_call_back2++ } ), 'HTML::WebDAO::Response',
  'test set_callaback';
isa_ok $response4->flush, 'HTML::WebDAO::Response', '$response3->flush';
is $test_call_back1, 2, '$test_call_back1';
is $test_call_back2, 3, '$test_call_back2';

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

