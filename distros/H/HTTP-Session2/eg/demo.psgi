use strict;
use Plack::Builder;
use Plack::Request;
use HTTP::Session2::ClientStore;
use File::Spec::Functions;
use File::Basename qw(dirname);

my $TOP_HTML = <<'TOP_HTML';
<!doctype html>
<html>
<head>
    <script src="http://code.jquery.com/jquery-2.0.3.min.js" type="text/javascript"></script>
    <script src="/xsrf-token.js" type="text/javascript"></script>
</head>
<body>
    User: %s<br>
    <a href="/login">login</a>
    <a href="/logout">logout</a>
    <form method="post" action="/post">
        <input type="submit">
    </form>
</body>
</html>
TOP_HTML

sub {
    my $req = Plack::Request->new(shift);
    my $session = HTTP::Session2::ClientStore->new(env => $req->env, secret => 'hah');
    if ($req->method eq 'POST') {
        my $token = $req->header('X-XSRF-TOKEN') || $req->param('XSRF-TOKEN');
        unless ($session->validate_xsrf_token($token)) {
            return [403, [], ['XSRF DETECTED']];
        }
    }
    my $res = sub {
        if ($req->path_info eq '/') {
            [200, [], [sprintf $TOP_HTML, $session->get('user') || 'Not logged in']];
        } elsif ($req->path_info eq '/login') {
            $session->set('user' => 'john');
            [302, ['Location', '/'], []];
        } elsif ($req->path_info eq '/logout') {
            $session->expire();
            [302, ['Location', '/'], []];
        } elsif ($req->path_info eq '/post') {
            [200, [], ['Post OK']];
        } elsif ($req->path_info eq '/xsrf-token.js') {
            [200, [], [slurp(catfile(dirname(__FILE__), "../js/xsrf-token.js"))]];
        } else {
            [404, [], ['not found']];
        }
    }->();
    $session->finalize_psgi_response($res);
    $res;
};

sub slurp {
    my $fname = shift;
    open my $fh, '<', $fname
      or Carp::croak("Can't open '$fname' for reading: '$!'");
    scalar(
        do { local $/; <$fh> }
    );
}
