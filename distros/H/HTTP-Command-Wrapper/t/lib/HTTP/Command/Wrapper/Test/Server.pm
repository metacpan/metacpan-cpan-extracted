package HTTP::Command::Wrapper::Test::Server;
use strict;
use warnings;
use utf8;

use Cwd qw/abs_path/;
use Exporter qw/import/;
use File::Spec;
use File::Basename qw/dirname/;
use Test::TCP;
use Plack::Loader;
use Plack::Middleware::Static;

our @EXPORT = qw/create_test_server/;

sub create_test_server {
	my $server = __PACKAGE__->new;
	$server->run;
	return $server;
}

sub new {
	my $class = shift;
	return bless {} => $class;
}

sub DESTROY {
	my $self = shift;
	delete $self->{server};
}

sub run {
    my $self = shift;
    
    return if $self->{server};
    
    my $root = $self->path_for;
    my $app  = sub {
        my $env = shift;

        Plack::Middleware::Static->new({
            path => sub { 1 },
            root => $root,
        })->call($env);
    };

    $self->{server} = Test::TCP->new(
        code => sub {
            my $port   = shift;
            my $server = Plack::Loader->auto(
                port => $port,
                host => '127.0.0.1',
            );
            $server->run($app);
        },
    );
}

sub port {
    return shift->{server}->port;
}

sub uri_for {
	my ($self, $path) = @_;
    my $port = $self->{server}->port;
    return "http://127.0.0.1:$port/$path";
}

sub path_for {
    my ($self, $path) = @_;
    $path = '' unless defined $path;
    return abs_path(File::Spec->catfile(dirname(__FILE__), qw/.. .. .. .. .. data htdocs/, $path)),
}

1;
