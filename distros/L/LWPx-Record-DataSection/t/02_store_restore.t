use strict;
use Test::More;
use Test::Requires qw(
    Test::TCP
    File::Temp
    Plack::Loader
    Plack::Request
);

plan skip_all => "Could not load modules: $@" if $@;
plan tests => 10;

my $count = 0;
my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);

    $count++;
    if ($req->method eq 'POST') {
        return [ 200, [ 'Content-Type' => 'text/plain' ], [ "post ($count)" ] ];
    } elsif ($env->{PATH_INFO} eq '/') {
        return [ 200, [ 'Content-Type' => 'text/plain' ], [ "hello ($count)" ] ];
    } elsif ($env->{PATH_INFO} eq '/newline') {
        return [ 200, [ 'Content-Type' => 'text/plain' ], [ "hello ($count)\n" ] ];
    } elsif ($env->{PATH_INFO} eq '/redirect') {
        return [ 302, [ 'Content-Type' => 'text/plain', Location => '/' ], [ ] ];
    }
};

my $server = Test::TCP->new(
    code => sub {
        my $port = shift;
        my $server = Plack::Loader->auto(port => $port, host => '127.0.0.1');
        $server->run($app);
    }
);

my ($fh, $filename) = File::Temp::tempfile();
print $fh do { local $/; scalar <DATA> };
close $fh;

sub run_script {
    my $path = shift || '/';
    my $post_content = shift || '';
    my @command = ($^X, map("-I$_", @INC), $filename, $server->port, $path, $post_content);
    return `@command`;
}

is run_script('/'), "hello (1)", 'server response';
is run_script('/'), "hello (1)", 'server response (stored)';

is run_script('/newline'), "hello (2)\n", 'server response w/newline';
is run_script('/newline'), "hello (2)\n", 'server response w/newline (stored)';

is run_script('/redirect'), "hello (1)", 'server response redirect';
is run_script('/redirect'), "hello (1)", 'server response redirect (stored)';

is run_script('/', 1), "post (4)", 'server response redirect';
is run_script('/', 1), "post (4)", 'server response redirect (stored)';

open my $dump_fh, '<', $filename;
my $generated_file = do { local $/; <$dump_fh> };

my $host = "127.0.0.1:${\$server->port}";
like $generated_file, qr(@@ GET http://\Q$host\E/ Post:);
like $generated_file, qr(@@ POST http://\Q$host\E/ Post:foo=1,foo=2);

__DATA__
#!perl
use strict;
use LWPx::Record::DataSection -append_data_section => 1, -record_post_param => [ 'foo' ];
use LWP::Simple qw($ua);

my ($port, $path, $post) = @ARGV;

my $res = $post ? $ua->post("http://127.0.0.1:$port$path", Content => [ foo => 1, foo => 2, bar => 3 ]) : $ua->get("http://127.0.0.1:$port$path");
print $res->content;
