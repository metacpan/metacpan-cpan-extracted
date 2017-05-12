use constant TEST_GROUP => 70;

use Test::More tests => 1 + TEST_GROUP * 4;
use strict;

# $Id$

BEGIN {
    use_ok( 'HTTP::Server::Brick' );
}

use version;
use LWP;
use LWP::UserAgent;
use HTTP::Status;
use POSIX qw(:sys_wait_h SIGHUP SIGKILL);

my $port = $ENV{HSB_TEST_PORT} || 65432;
my $host = $ENV{HSB_TEST_HOST} || '127.0.0.1';

diag( '' );
diag( '' );
diag( "Using port: $port and host: $host for test server.");
diag( 'If these are not suitable settings on your machine, set the environment' );
diag( 'variables HSB_TEST_PORT and HSB_TEST_HOST to something suitable.');
diag( '' );

run_tests( ssl => 0, fork => 0 );
run_tests( ssl => 0, fork => 1 );

SKIP: {
  skip "can't run SSL tests without HTTP::Daemon::SSL and IO::Socket::SSL",
    TEST_GROUP * 2
    unless eval "require HTTP::Daemon::SSL; require IO::Socket::SSL; 1";
  run_tests( ssl => 1, fork => 0 );
  run_tests( ssl => 1, fork => 1 );
}

sub test_url {
    my ($scheme, $method, $uri, $code, $regex, $test_name, $mime_type) = @_;

    my $url = "$scheme://$host:$port$uri";

    my $ua = LWP::UserAgent->new();
    my $req = HTTP::Request->new(GET => $url);

    my $res;
    ok($res = $ua->request($req), "$test_name (LWP request worked)" );
    cmp_ok($res->code, '==', $code, "$test_name (result code as expected).");
    like($res->content, $regex, "$test_name (content matched).");

    if ($mime_type) {
        is($res->header('Content-type'), $mime_type, "$test_name (Mime type)");
    }

}

sub run_tests {
  my %args = @_;

  diag('Configuring' . ($args{fork} ? ' forked' : '') . ' server' . ($args{ssl} ? ' with ssl' : ''));
  
  # set the error out to stdout to play nice with test::harness
  my $server;

  my %server_args = (
      port => $port, host => $host, error_log => \*STDOUT,
      fork => $args{fork},
     );

  if ($args{ssl}) {
      $server_args{daemon_class} = 'HTTP::Daemon::SSL';
      $server_args{daemon_args} = [
          SSL_key_file => 't/test.pem',
          SSL_cert_file => 't/test.pem',
         ];
  }
  
  ok( $server = HTTP::Server::Brick->new( %server_args ), 'Created server object.');
  isa_ok( $server, 'HTTP::Server::Brick');


  # setup dir and file for static tests
  my $temp_text_file = 'foo.txt';
  my $temp_html_file = 'foo.html';

  my $temp_dir = POSIX::tmpnam();
  mkdir $temp_dir or die "Unable to create temp dir $temp_dir";

  {
      my $text_fh;
      open($text_fh, ">$temp_dir/$temp_text_file") or die "Unable to write to temp file $temp_text_file";
      print $text_fh "Hello Everybody";

      my $html_fh;
      open($html_fh, ">$temp_dir/$temp_html_file") or die "Unable to write to temp file $temp_html_file";
      print $html_fh "<html><body><h1>Hi Dr Nick</h1></body></html>";
  }

  # clean up temp dirs
  END {
      no warnings 'closure';
      
      unlink "$temp_dir/$temp_text_file" if $temp_dir && $temp_text_file && -f "$temp_dir/$temp_text_file";
      unlink "$temp_dir/$temp_html_file" if $temp_dir && $temp_html_file && -f "$temp_dir/$temp_html_file";
      rmdir $temp_dir if $temp_dir && -d $temp_dir;
  }

  # no point testing these - they just return 1.
  $server->mount( '/static/test', { path => $temp_dir } );
  $server->mount( '/exotic_error', { handler => sub { RC_CONFLICT } });
  $server->mount( '/another_exotic_error' => {
          handler => sub {
              my ($req, $res) = @_;
              $res->code(RC_METHOD_NOT_ALLOWED);
              1;
          },
      });
  $server->mount( '/static/test/more_specific_mount', { handler => sub { RC_CONFLICT } });
  $server->mount( '/test/non_wildcard_handler' => {
      handler => sub {
          my ($req, $res) = @_;
          $res->add_content("<html><body>No wildcards here</body></html>");
          1;
      },
  });
  $server->mount( '/test/wildcard_handler' => {
      handler => sub {
          my ($req, $res) = @_;
          $res->add_content("<html><body>
                                   <p>Path info: $req->{path_info}</p>
                                   <p>Mount path: $req->{mount_path}</p>
                                 </body></html>");
          1;
      },
      wildcard => 1,
  });
  $server->mount( '/test/redirect' => {
      handler => sub {
          my ($req, $res) = @_;
          $res->{target_uri} = URI::http->new('/test/non_wildcard_handler');
          RC_FOUND;
      },
  });
  $server->mount( '/test/relative_redirect' => {
      handler => sub {
          my ($req, $res) = @_;
          $res->{target_uri} = URI::http->new('wildcard_handler/flubber');
          RC_FOUND;
      },
  });
  $server->mount( '/test/data' => {
      handler => sub {
          my ($req, $res) = @_;
          $res->add_content("2,3,5,7,11,13,17,19,23,29");
          $res->header('Content-type', 'text/csv');
          1;
      },
      wildcard => 1,
  });
  $server->mount( '/test/remote-header' => {
      handler => sub {
          my ($req, $res) = @_;
          $res->add_content("X-Brick-Remote-IP header is: " . $req->header('X-Brick-Remote-IP'));
          1;
      },
  });

  # need to fork off a child to run the server

  my $child_pid;
  if (!($child_pid = fork())) {
      # child - this will be the server

      diag('Starting server');
      $server->start;
      exit(0);
  }

  my $scheme = $args{ssl} ? 'https' : 'http';

  sleep(1); # just to play it safe on slow OS/machine combos

  test_url( $scheme, GET => "/url_that_doesn't_exist", RC_NOT_FOUND, qr/Not Found in Site Map/,
           "Pathological case - mount doesn't exist" );

  test_url( $scheme, GET => "/static/test", RC_OK, qr!static/test.*foo.html.*foo.txt!s,
           "Directory indexing", 'text/html');

  test_url( $scheme, GET => "/static/test/flubber", RC_NOT_FOUND, qr/File Not Found/,
           "Static file not found" );

  test_url( $scheme, GET => "/static/test/foo.txt", RC_OK, qr/Hello Everybody/,
           "Plain text static file", 'text/plain' );

  test_url( $scheme, GET => "/static/test/foo.html", RC_OK, qr!<html><body><h1>Hi Dr Nick</h1></body></html>!,
           "HTML static file", 'text/html' );

  test_url( $scheme, GET => "/exotic_error", RC_CONFLICT, qr/Conflict/,
           "HTTP Return code via handler return value" );

  test_url( $scheme, GET => "/another_exotic_error", RC_METHOD_NOT_ALLOWED, qr/Not Allowed/,
           "HTTP Return code via HTTP::Response->code()" );

  test_url( $scheme, GET => "/static/test/more_specific_mount", RC_CONFLICT, qr/Conflict/,
           "More specific mount matched first" );

  test_url( $scheme, GET => "/test/non_wildcard_handler", RC_OK, qr!<html><body>No wildcards here</body></html>!,
           "Regular HTML mounted handler", 'text/html' );

  test_url( $scheme, GET => "/test/non_wildcard_handler/foo", RC_NOT_FOUND, qr!Not Found!,
           "Handlers default to non-wildcard", );

  test_url( $scheme, GET => "/test/wildcard_handler", RC_OK, qr!Path info: </p>!,
           "Wildcard mounted handler root (path info)", 'text/html' );

  test_url( $scheme, GET => "/test/wildcard_handler", RC_OK, qr!Mount path: /test/wildcard_handler</p>!,
           "Wildcard mounted handler root (mount path)", 'text/html' );

  test_url( $scheme, GET => "/test/wildcard_handler/foo/bar", RC_OK, qr!Path info: /foo/bar</p>!,
           "Wildcard mounted handler with extra path", 'text/html' );

  test_url( $scheme, GET => "/test/wildcard_handler/foo/bar", RC_OK, qr!Mount path: /test/wildcard_handler</p>!,
           "Wildcard mounted handler with extra path (mount path)", 'text/html' );

  test_url( $scheme, GET => "/test/redirect", RC_OK, qr!<html><body>No wildcards here</body></html>!,
           "Fully qualified Redirect", 'text/html' );

  test_url( $scheme, GET => "/test/relative_redirect", RC_OK, qr!Path info: /flubber</p>!,
           "Relative Redirect", 'text/html' );

  test_url( $scheme, GET => "/test/data", RC_OK, qr!^2,3,5,7,11,13,17,19,23,29$!s,
           "HTTP::Response custom mime type", 'text/csv' );

  test_url( $scheme, GET => '/test/remote-header', RC_OK, qr/^X-Brick-Remote-IP header is: 127.0.0.1$/,
           "X-Brick-Remote-IP header", "text/html");


  cmp_ok(kill( SIGHUP, $child_pid), '==', 1, "Requesting server shutdown via HUP ($child_pid)");
  sleep(6); # just to be safe in case it takes some OS/hardware combinations a while to clean up
  waitpid($child_pid, WNOHANG);
  {
      my $current_hds_version = version->new($HTTP::Daemon::SSL::VERSION);
      my $minimum_hds_version = version->new("1.03_01");
      
      local $TODO = $args{ssl} && $current_hds_version < $minimum_hds_version ?
        "HTTP::Daemon::SSL 1.02 accept() never timesout (in violation of HTTP::Daemon docs)" : undef;
      
      cmp_ok(kill( SIGKILL, $child_pid), '==', 0, "Shouldn't need to force kill server");
  }
}
