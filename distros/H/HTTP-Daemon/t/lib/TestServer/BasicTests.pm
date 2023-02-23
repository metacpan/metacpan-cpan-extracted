package TestServer::BasicTests;
use strict;
use warnings;

use TestServer ();
our @ISA = qw(TestServer);

use File::Temp qw(tempfile);

sub dispatch {
    my $self = shift;
    my ($c, $method, $uri, $request) = @_;
    my $p = ($uri->path_segments)[1];
    my $call = lc("httpd_" . $method . "_$p");
    if ($self->can($call)) {
        return $self->$call($c, $request);
    }
    $self->SUPER::dispatch(@_);
}

sub httpd_get_echo {
    my ($self, $c, $req) = @_;
    $c->send_basic_header(200);
    print $c "Content-Type: message/http\015\012";
    $c->send_crlf;
    print $c $req->as_string;
}

sub httpd_get_file {
    my ($self, $c, $r) = @_;
    my %form = $r->uri->query_form;
    my $file = $form{file};
    $c->send_file_response($file);
}

sub httpd_get_redirect {
    my ($self, $c) = @_;
    $c->send_redirect("/echo/redirect");
}

sub httpd_get_redirect2 { shift; shift->send_redirect("/redirect3/") }
sub httpd_get_redirect3 { shift; shift->send_redirect("/redirect2/") }

sub httpd_get_basic {
    my ($self, $c, $r) = @_;

    #print STDERR $r->as_string;
    my ($u, $p) = $r->authorization_basic;
    if (defined($u) && $u eq 'ok 12' && $p eq 'xyzzy') {
        $c->send_basic_header(200);
        print $c "Content-Type: text/plain";
        $c->send_crlf;
        $c->send_crlf;
        $c->print("$u\n");
    }
    else {
        $c->send_basic_header(401);
        $c->print("WWW-Authenticate: Basic realm=\"libwww-perl\"\015\012");
        $c->send_crlf;
    }
}

sub httpd_get_proxy {
    my ($self, $c, $r) = @_;
    if ($r->method eq "GET" and $r->uri->scheme eq "ftp") {
        $c->send_basic_header(200);
        $c->send_crlf;
    }
    else {
        $c->send_error;
    }
}

sub httpd_post_echo {
    my ($self, $c, $r) = @_;
    $c->send_basic_header;
    $c->print("Content-Type: text/plain");
    $c->send_crlf;
    $c->send_crlf;

    # Do it the hard way to test the send_file
    my ($fh, $filename) = tempfile('http-daemon-test-XXXXXX', TMPDIR => 1);
    binmode $fh;
    print $fh $r->as_string;
    close $fh;

    $c->send_file($filename);

    unlink($filename);
}

sub httpd_get_partial {
    my ($self, $c) = @_;
    $c->send_basic_header(206);
    print $c "Content-Type: image/jpeg\015\012";
    $c->send_crlf;
    print $c "some fake JPEG content";

}

sub httpd_get_quit {
    my ($self, $c) = @_;
    $c->send_error(503, "Bye, bye");
    exit;                    # terminate HTTP server
}

1;
