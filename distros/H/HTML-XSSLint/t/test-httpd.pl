use strict;
use CGI;
use FileHandle;
use HTTP::Daemon;
use IO::String;

my $port = shift;
my $daemon = HTTP::Daemon->new(
    LocalPort => $port,
);

my $pidfile = "t/test-httpd.pid";
pidout($pidfile);
$SIG{INT} = sub { unlink $pidfile; exit };

while (my $c = $daemon->accept) {
    while (my $r = $c->get_request) {
	handle_request($r, $c);
    }
}

sub handle_request {
    my($r, $c) = @_;
    my $uri = $r->uri;
    my $query = CGI->new($uri->query);
    my $path = $uri->path;
    $path =~ s/-/_/g;
    $path =~ s!/!!g;

    no strict 'refs';
    my $command = \&{"action_" . $path};
    my $html = eval { $command->($query) };
    $c->send_file(IO::String->new($html));
}

sub action_secure {
    return <<HTML;
<form action="/secure">
<input type="text" name="name">
</form>
HTML
    ;
}


sub action_vulnerable {
    return <<HTML;
<form action="/vulnerable-form">
<input type="text" name="name">
<input type="text" name="password">
<input type="text" name="email">
</form>
<form action="/vulnerable-form">
<input type="text" name="name">
<input type="text" name="password">
<input type="text" name="email">
</form>
HTML
    ;
}

sub action_vulnerable_form {
    my $query = shift;
    my $name  = $query->param('name');
    my $email = $query->param('email');
    return <<HTML;
name:  $name<br>
Email: $email
HTML
    ;
}

sub respond {
    my($c, $html) = @_;

}

sub pidout {
    my $out = FileHandle->new(">". shift) or die;
    $out->print($$);
    $out->close;
}
