package HTTP::Server::Daemon;
use strict;
use warnings;
use POSIX qw(strftime setsid WNOHANG);
use Fcntl ':flock';
use Socket qw(:all);
use Carp;
use IO::Select;
use File::Basename qw(dirname basename);
use Data::Dump qw(dump);
use vars qw(@ISA @EXPORT_OK $pipe_write $pipe_write $pipe_write $pipe_status $pipe_read @idle_children %children $min_children $max_children $port $pidfile $quit $caller_package $caller_filename $caller_line $str $str $str @allow_ips @allow_ips);

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(server_perfork_dynamic check_pid become_daemon become_netserver get_msg send_msg peer_info net_filter);

our $VERSION = '0.04';

=head1 NAME

Daemon - Start an Application as a Daemon 

=head1 SYNOPSIS

    use HTTP::Server::Daemon qw(check_pid become_daemon);

    my $child_num = 0;
    my $quit = 1;
    my $pidfile = become_daemon(__FILE__);
    $SIG{CHLD} = sub { while(waitpid(-1,WNOHANG)>0){ $child_num--; } };
    $SIG{TERM} = $SIG{INT} = sub { unlink $pidfile; $quit--; };
    while ($quit){
        #do your things;
    }

=head1 DESCRIPTION

Help running an application as a daemon.

=head1 METHODS

=head2 server_perfork_dynamic($child_func, $port, $min_children, $max_children)

Prefork a net server listen on the given port.

=cut

sub server_perfork_dynamic
{
    my $child_func = shift;
    my $port = shift;
    my $min_children = shift || 10;
    my $max_children = shift || 20;

    croak "avg1 must be a function.\n" unless ref $child_func eq 'CODE';
    croak "port must be a munber.\n" unless $port =~ /\d+/;
    croak "min_children must be a munber.\n" unless $min_children =~ /\d+/;
    croak "max_children must be a munber.\n" unless $max_children =~ /\d+/;

    my $quit = 0;
    my %children = ();
    my $server = become_netserver($port);

    my $pipe_read;
    my $pipe_write;
    pipe($pipe_read, $pipe_write);
    my $pipe_status = IO::Select->new($pipe_read);

    $SIG{CHLD} = sub { while(waitpid(-1,WNOHANG)>0){} };
    $SIG{HUP} = sub { kill HUP => keys %children; $quit++; };

    perfork_child_pipe($server, $pipe_write, $child_func);

    while (!$quit)
    {
        if ($pipe_status->can_read)
        {
            my $pipe_msg;
            next unless sysread($pipe_read, $pipe_msg, 4096);
            my @pipe_msg = split "\n", $pipe_msg;
            foreach (@pipe_msg)
            {
                next unless my ($pid, $sta) = /^(\d+)\s*(\w+)$/;
                if ($sta eq 'exit')
                {
                    delete $children{$pid};
                }
                else
                {
                    $children{$pid} = $sta;
                }
            }
        }

        my @idle_children = sort {$a <=> $b} grep {$children{$_} eq 'idle'} keys %children;

        if (@idle_children < $min_children)
        {
            perfork_child_pipe($server, $pipe_write, $child_func);
        }
        elsif(@idle_children > $max_children)
        {
            my @kill_pids = @idle_children[0..@idle_children - $max_children - 1];
            my $kill_pid = kill HUP => @kill_pids;
        }
    }
}

=head2 perfork_child_pipe($server_sock, $pipe_write, $child_func_ref, $dead_after_requests_num)

Fork a child listen the port. 
(Internal methods).

=cut
    
sub perfork_child_pipe
{
    my $server = shift;
    my $pipe_write = shift;
    my $child_func = shift;
    my $max_request = shift;
    $max_request = int(rand 99) + 9 unless $max_request;

    croak "function perfork_child_pipe() avg3 must be a function.\n" unless ref $child_func eq 'CODE';

    my $child = fork;
    if ($child == 0)
    {
        undef $pipe_status;
        undef $pipe_read;
        undef @idle_children;
        undef %children;
        undef $min_children;
        undef $max_children;
        undef $port;
        undef $quit;

        my $quit = 0;
        my $caller = $0;
        local $SIG{HUP} = sub {$0 = "$caller busy hup"; $quit++; exit 0;};
        while(!$quit and $max_request--)
        {
            my $sock;
            syswrite $pipe_write, "$$ idle\n";
            $0 = "$caller life=$max_request idle";

            next unless eval
            {
                local $SIG{HUP} = sub {$0 = "$caller idle hup"; $quit++; die;};
                accept($sock, $server);
            };

            syswrite $pipe_write, "$$ busy\n";
            $0 = "$caller life=$max_request busy";
            &$child_func($sock);

            close $sock;
        }
        close $server;
        syswrite $pipe_write, "$$ exit\n";
        close $pipe_write;
        exit 0;
    }
}

=head2 become_netserver($port)

Let the proccess listen on given port using protocol 'TCP'.

=cut

sub become_netserver
{
    my $port = shift;
    my $address = sockaddr_in($port, INADDR_ANY);
    my $server;
    socket($server, AF_INET, SOCK_STREAM, IPPROTO_TCP) || die "socket create: $!\n";
    setsockopt($server, SOL_SOCKET, SO_REUSEADDR, 1) || die "socket reuse: $!\n";
    bind($server, $address) || die "socket bind: $!\n";
    listen($server, SOMAXCONN) || die "socket listen: $!\n";
    return $server;
}

=head2 send_msg($sock)

Send msg to sock using protocol 'PON'(Perl Object Notation).

=cut

sub send_msg
{
    my $sock = shift;
    my $script = shift;
    my $data = shift;
    my %str;
    $str{'script'} = $script;
    $str{'data'} = \%{$data};
    $str = dump(%str);
    my $str_length = length($str);
    #print $str;
    my $binstr = pack('N', $str_length) . $str;
    syswrite($sock, $binstr);
    return $str_length;
}

=head2 get_msg($sock)

Receive msg from sock using protocol 'PON'(Perl Object Notation).

=cut

sub get_msg
{
    my $sock = shift;
    my $buf = '';
    sysread($sock, $buf, 4);
    my $msg_length = unpack('N',$buf);
    sysread($sock, $buf, $msg_length);
    return eval($buf);
}

=head2 peer_info($sock)

Return ($peer_port, $peer_ip).

=cut

sub peer_info
{
    my $sock = shift;
    my $hersockaddr = getpeername $sock;
    my ($peer_port, $heraddr) = sockaddr_in($hersockaddr);
    my $peer_ip = inet_ntoa($heraddr);
    return ($peer_port, $peer_ip);
}

=head2 net_filter($sock)

Enable white list net filter. 
Allow only ip list in 'conf/allowip.conf' access, return 0. 
Others return 'deny'.

=cut

sub net_filter
{
    my $sock = shift;
    my ($peer_port, $peer_ip) = peer_info($sock);
    return 'deny' if $peer_ip eq '255.255.255.255';

    my $ip_conf = `cat conf/allow_ip.conf conf/captain_ip.conf`;
    @allow_ips = split "\n",$ip_conf;
    foreach (@allow_ips)
    {
        next if $_ =~ /^#/;
        next if $_ =~ /^\s+$/;
        return 0 if $_ eq $peer_ip;
    }
    return 'deny';
}

=head2 check_pid($invoker_name)

Deal with pid file things. Can be used independently.

=cut

sub check_pid
{
    my $invoker = shift;
    my $pidfile = basename($invoker) . ".pid";
    if (-e $pidfile)
    {
        open my $pidfh,"<",$pidfile;
        my $pid = <$pidfh>;
        close $pidfh;
        if (kill 0 => $pid)
        {
            print "$invoker is serving in company, programme exit.\n";
            exit;
        }
        else
        {
            print "pid file exist, try to unlink it.\n";
            if (unlink $pidfile)
            {
                print "pid file unlinked.\n";
                print "$invoker on posion.\n";
                open my $pidfh,">",$pidfile;
                print $pidfh $$;
                close $pidfh;
            }
            else
            {
                print "pid file unlink failed.\n";
                exit 0;
            }
        }
    }
    else
    {
        print "$invoker on posion.\n";
        open my $pidfh,">",$pidfile;
        print $pidfh $$;
        close $pidfh;
    }
    return $pidfile;
}

=head2 become_daemon($invoker_name)

Let the proccess become a daemon. Can be used independently.

=cut

sub become_daemon
{
    my $invoker = shift;
    defined (my $child = fork) or die "Can`t fork: $!";
    exit 0 if $child;
    setsid();

    my $rootdir = `pwd`;
    chomp $rootdir;
    my $caller_filename = basename($invoker);
    $0 = $rootdir."/".$caller_filename;

    #open(STDOUT, ">/dev/null");
    #open(STDERR, ">/dev/null");
    open(STDIN, "</dev/null");
    chdir($rootdir);
    umask(0);
    $ENV{PATH} = "/sbin:/bin:/usr/sbin:/usr/bin";
    return check_pid($invoker);
}

1;

=head1 AUTHOR

Written by ChenGang, yikuyiku.com@gmail.com

L<http://blog.yikuyiku.com/>


=head1 COPYRIGHT

Copyright (c) 2011 ChenGang.
This library is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.


=head1 SEE ALSO

L<Parallel::Prefork>, L<Daemon::Generic>

=cut

