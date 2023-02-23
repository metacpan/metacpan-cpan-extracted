package TestServer;
use strict;
use warnings;

use File::Spec;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
}

sub perl {
    my ($perl) = $^X =~ /(.*)/;
    return $perl;
}

sub lib_dirs {
    my $self = shift;
    my $perl = $self->perl;
    $perl = qq["$perl"]
      if $perl =~ /\s/;

    my @inc = `$perl -l -e"print for \@INC"`;
    chomp @inc;

    my %inc = map +($_ => 1), @inc;

    my @libs = grep !$inc{$_}, @INC;

    return @libs;
}

sub perl_cmd {
    my $self = shift;
    my $perl = $self->perl;
    $perl = qq["$perl"]
        if $perl =~ /\s/;

    my @libs = $self->lib_dirs;
    for my $lib ($self->lib_dirs) {
        my $quoted = $lib =~ /\s/ ? qq["$lib"] : $lib;
        $perl .= " -I$quoted";
    }

    return $perl;
}

sub start {
    my $self = shift;
    my $class = ref $self;

    my $perl = $self->perl_cmd;

    my $pid = open my $DAEMON, "$perl -M$class=run -e1 |"
        or die "Can't exec daemon: $!";

    my $greeting = <$DAEMON>;
    $greeting =~ /<URL:([^>]+)>/;

    my $base = URI->new("$1");

    $self->{url} = $base;
    $self->{pid} = $pid;
    $self->{io} = $DAEMON;

    return $base;
}

sub stop {
    my $self = shift;
    my $pid = delete $self->{pid} or return;
    my $io = delete $self->{io};

    kill 'KILL', $pid;
    close $io;

    waitpid $pid, 0;
    return;
}

sub DESTROY {
    my $self = shift;
    $self->stop
        if $self->{pid};
}

sub url {
    my $self = shift;
    my $base = $self->{url};
    if (@_) {
        my $u = URI->new(shift);
        $u = $u->abs($base);
        if (@_) {
            my $query = shift;
            $u->query_form($query);
        }
        return $u->as_string;
    }
    else {
        return $base;
    }
}

sub import {
    my $class = shift;
    if (@_ == 1 && $_[0] eq 'run') {
        $class->new->run;
    }
}

sub run {
    my $self = shift;

    my $listen_host;

    require Socket;
    require IO::Socket::IP;
    my ($err, @res) = Socket::getaddrinfo("localhost", "http", {
        protocol => Socket::IPPROTO_TCP(),
    } );

    my @local_hosts = map +(Socket::getnameinfo($_->{addr}, Socket::NI_NUMERICHOST()))[1], @res;
    push @local_hosts, '127.0.0.1';

    for my $host (@local_hosts) {
        my $try = IO::Socket::IP->new(LocalAddr => $host, Listen => 1);
        if ($try) {
            $listen_host = $host;
            $try->close;
            last;
        }
    }

    require HTTP::Daemon;
    my $d = HTTP::Daemon->new(
        Timeout => 10,
        $listen_host ? ( LocalHost => $listen_host ) : (),
    );

    print "HTTP::Daemon running at <URL:", $d->url, ">\n";
    open STDOUT, '>', File::Spec->devnull;

    while (my $c = $d->accept) {
        my $r = $c->get_request;
        if ($r) {
            $self->dispatch($c, $r->method, $r->uri, $r);
        }
        $c = undef;    # close connection
    }
    print STDERR "HTTP Server terminated\n";
    exit;
}

sub dispatch {
    my $self = shift;
    my ($c, $method, $uri, $request) = @_;

    $c->send_error(404);
}

1;
