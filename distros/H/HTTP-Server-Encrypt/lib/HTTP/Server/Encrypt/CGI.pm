package HTTP::Server::Encrypt::CGI;
use 5.008008;
use strict;
use warnings;
use Carp qw(croak);
use HTTP::Server::Daemon qw(become_daemon server_perfork_dynamic peer_info get_msg send_msg);
use HTTP::Status qw(status_message);
use HTTP::Date qw(time2str);
use MIME::Base64 qw(encode_base64);
use File::Basename qw(dirname basename);
use Sys::Sendfile qw(sendfile);
use Log::Lite qw(log logpath);
use Crypt::CBC;
use Data::Dump qw(ddx);
use Sys::Hostname;
use IPC::Open3;
use Cwd;
use vars qw(@ISA @EXPORT_OK $right_auth $username $script_base_dir $peer_port $peer_ip $body %_HEAD $static_expires_secs $blowfish $blowfish_encrypt $blowfish_decrypt $_POST %ip_allow %ip_deny $log_dir $port $colonel_version $hostname);

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(http_server_start);

our $VERSION = '0.01';

sub http_server_start
{
    my $ref_http_conf = shift;
    my %http_conf = %$ref_http_conf;
    our $port = $http_conf{'port'} || 80;
    my $protocol = $http_conf{'protocol'} || 'http';
    my $min_spare = $http_conf{'min_spare'} || 10;
    my $max_spare = $http_conf{'max_spare'} || 20;
    our $script_base_dir = $http_conf{'docroot'} || 'htdoc';
    $script_base_dir = substr($script_base_dir,0,-1) if substr($script_base_dir,-1) eq '/';
    our $static_expires_secs = $http_conf{'cache_expires_secs'} || 3600;
    our $username = $http_conf{'username'};
    my $passwd = $http_conf{'passwd'};
    my $blowfish_key = $http_conf{'blowfish_key'};
    our $blowfish_encrypt = $http_conf{'blowfish_encrypt'};
    our $blowfish_decrypt = $http_conf{'blowfish_decrypt'};
    our %ip_allow = %{$http_conf{'ip_allow'}} if $http_conf{'ip_allow'};
    our %ip_deny = %{$http_conf{'ip_deny'}} if $http_conf{'ip_deny'};
    our $log_dir = $http_conf{'log_dir'} if $http_conf{'log_dir'};
    $log_dir = '' if defined $log_dir and $log_dir eq 'no';
    logpath($log_dir) if defined $log_dir and $log_dir;
    our $colonel_version = 'Colonel/0.9';
    our $hostname = hostname;

    if ($blowfish_key)
    {
        our $blowfish = Crypt::CBC->new( 
                            -key    => $blowfish_key ,
                            -cipher => 'Blowfish',
        );
    }

    if ($username or $passwd)
    {
        our $right_auth = $username if $username;
        $right_auth.= ":";
        $right_auth.= $passwd if $passwd;
        $right_auth = encode_base64($right_auth);
        chomp $right_auth;
    }

    my ($package, $invoker) = caller;
    chdir( dirname($invoker) );

    my $pidfile = become_daemon($invoker);
    $SIG{TERM} = sub { unlink $pidfile; kill HUP => $$; };

    server_perfork_dynamic(\&do_child_http, $port, $min_spare, $max_spare);
    return $pidfile;
}

sub do_child_http
{
    my $sock = shift;
    local ($peer_port, $peer_ip) = peer_info($sock);
    if (%ip_allow) {return unless $ip_allow{$peer_ip};}
    if (%ip_deny)  {return if $ip_deny{$peer_ip};}
    my $status = 100;
    my $send_bytes;
    undef %ENV;
    local %ENV;
    $ENV{'AUTH_TYPE'} = "Basic" if $username;
    $ENV{'GATEWAY_INTERFACE'} = "CGI/1.1";
    $ENV{'REMOTE_ADDR'} = $peer_ip;
    $ENV{'REMOTE_HOST'} = $peer_ip;
    $ENV{'REMOTE_USER'} = $username if $username;
    $ENV{'SERVER_NAME'} = $hostname;
    $ENV{'SERVER_PORT'} = $port;
    $ENV{'SERVER_PROTOCOL'} = "HTTP/1.0";
    $ENV{'SERVER_SOFTWARE'} = $colonel_version;

    my $chunk = http_readline($sock);
    if (!$chunk or length($chunk) > 16*1024)
    {
        $status = 414;
        goto HTTP_RESP;
    }

    my $method;
    my $request_uri;
    my $protocol;
    ($method, $request_uri, $protocol) = $chunk =~ m/^(\w+)\s+(\S+)(?:\s+(\S+))?\r?$/;
    $ENV{'REQUEST_METHOD'} = $method;
    $ENV{'REQUEST_URI'} = $request_uri;

    my ($script, $query_string ) = $request_uri =~ /([^?]*)(?:\?(.*))?/s;
    $ENV{'PATH_INFO'} = $script;
    $ENV{'QUERY_STRING'} = $query_string if $query_string;
    $ENV{'SCRIPT_NAME'} = $script;

    local %_HEAD = http_get_header($sock);
    $ENV{'CONTENT_LENGTH'} = $_HEAD{'Content-Length'} if $_HEAD{'Content-Length'};
    $ENV{'CONTENT_TYPE'} = $_HEAD{'Content-Type'} if $_HEAD{'Content-Type'};
    $ENV{'HTTP_HOST'} = $_HEAD{'Host'} if $_HEAD{'Host'};
    $ENV{'HTTP_COOKIE'} = $_HEAD{'Cookie'} if $_HEAD{'Cookie'};
    $ENV{'COOKIE'} = $_HEAD{'Cookie'} if $_HEAD{'Cookie'};
    $ENV{'HTTP_USER_AGENT'} = $_HEAD{'User-Agent'} if $_HEAD{'User-Agent'};

    my $location;
    if( -d "$script_base_dir$script" )
    {
        if (substr($script, -1) ne '/')
        {
            $status = 301;
            $location = "http://" . $_HEAD{'Host'} . "$script/$query_string";
            goto HTTP_RESP;
        }

        foreach (qw(index.pl index.php index.htm index.html))
        {
            $script .= $_ if (-e "$script_base_dir$script/$_");
        }
    }
    my $script_file = "$script_base_dir$script";
    $ENV{'PATH_TRANSLATED'} = $script_file;

    if ($right_auth)
    {
        my ($client_auth) = $_HEAD{'Authorization'} =~ /Basic\s*([\w\+\=]+)/ if $_HEAD{'Authorization'};
        unless (defined $client_auth and $client_auth eq $right_auth)
        {
            $status = 401;
            goto HTTP_RESP;
        }
    }

    local $_POST;
    if ($method eq 'POST')
    {
        use bytes;
        my $post_data = '';
        if(defined $_HEAD{'Content-Length'})
        {
            read($sock, $post_data, $_HEAD{'Content-Length'});
        }
        else
        {
            my $i = 0;
            while( substr($post_data, -2) ne "\015\012" )
            {
                read($sock, my $buf, 1);
                $post_data .= $buf;
                $i++;
                if ($i > 4096)
                {
                    $status = 411;
                    goto HTTP_RESP;
                }
            }
        }
        last unless $post_data;

        $post_data = $blowfish->decrypt($post_data) if $blowfish_decrypt;
        $_POST = $post_data;
    }

    my $boolen_sendfile;
    my $body = '';
    my $head = '';
    if (-e $script_file and -r $script_file and -s $script_file)
    {
        eval
        {
            $status = 200;
            if ( -x $script_file )
            {
                my $current_dir = getcwd;
                chdir dirname($script_file);
                my($wtr, $rdr, $err);
                use Symbol 'gensym'; 
                $err = gensym;
                my $pid = open3($wtr, $rdr, $err, basename $script_file);
                print $wtr $_POST if $_POST;
                close $wtr;
                
                my $http_err = '';
                my $separator = 0;
                while(<$rdr>)
                {
                    $separator = 1 if $_ eq "\015\012";
                    $head .= $_ unless $separator;
                    $body .= $_ if $separator;
                }
                while(<$err>)
                {
                    $http_err .= $_; 
                }

                waitpid( $pid, 0 );
                my $child_exit_status = $? >> 8;
                chdir $current_dir;
            }
            else
            {
                open my $fh,"<",$script_file or die "couldn`t open file";
                binmode $fh;
                if(!$blowfish_encrypt and $^O eq 'linux')
                {
                    syswrite $sock, "HTTP/1.0 $status " . status_message($status) . "\015\012";
                    syswrite $sock, "Cache-Control: max-age=$static_expires_secs\015\012";
                    syswrite $sock, "\015\012";
                    $send_bytes = sendfile($sock, $fh);
                    $boolen_sendfile = 1;
                    goto HTTP_RESP;
                }
                else
                {
                    $body = do {local $/; <$fh>};
                }
                close $fh;
            }

            if($blowfish_encrypt)
            {
                $body = $blowfish->encrypt($body);
            }
        };
        if($@)
        {
            $status = 500;
            $body = $@;
            goto HTTP_RESP;
        }
    }
    else
    {
        $status = 404;
        goto HTTP_RESP;
    }

    HTTP_RESP: $send_bytes = http_response($sock, $status, $body, $head, $location) unless $boolen_sendfile;
    log('http_access', $peer_ip, $status, $method, $request_uri, $send_bytes, status_message($status), $@) if $log_dir;
    return $send_bytes;
}

sub http_get_header
{
    my $sock = shift;
    my @header;
    while ( my $line = http_readline($sock) ) 
    {
        last if ( $line =~ /^\s*$/ );
        my ($k, $v) = $line =~ /^([\w\-]+)\s*:\s*(.*)/;
        $v =~ s/[\015\012]//g;
        push @header, $k => $v;
    }
    return @header;
}

sub http_readline
{
    my $sock = shift;
    my $line;
    while ( read( $sock, my $buf, 1 ) ) 
    {
        last if $buf eq "\012";
        $line .= $buf;
    }
    return $line;
}

sub http_response
{
    my $sock = shift;
    my $status = shift || 200;
    my $body = shift;
    my $head = shift;
    my $location = shift;

    my $status_msg = status_message($status);
    if (!$body and $status != 200 )
    {
        $head = "HTTP/1.0 $status $status_msg\015\012";
        $head.= "Server: $colonel_version\015\012";
        $head.= "Date: ".time2str(time)."\015\012";
        $head.= "WWW-Authenticate: Basic realm=\"Colonel Authentication System\"\015\012" if $status == 401 ;
        $head.= "Location: $location\015\012" if defined $location and $location;
        $head.= "\015\012";
        $body = "<title>$status $status_msg</title>Colonel ERROR: $status $status_msg";
    }

    my $output = $head;
    $output .= $body if defined $body and $body;
    print $sock $output;
    return length($output);
}

1;
__END__

=head1 NAME

HTTP::Server::Encrypt::CGI - CGI support for HTTP::Server::Encrypt

=head1 USAGE

Use
	
	use HTTP::Server::Encrypt::CGI;

Instead of 

	use HTTP::Server::Encrypt;

Then you just put you CGI applications in I<docroot>.


=head1 HOW TO WRITE CGI SCRIPT

Many language can be used,like C/Python/Lua/PHP/etc..

First get raw POST data from STDIN, and environment variables from shell env.

Then output to STDOUT, server will send them back to browser.

More information at L<http://tools.ietf.org/html/draft-robinson-www-interface-00>.


=head1 CODE IN PERL

If you code in PERL, you want this L<CGI>.

NOTICE: You MUST keep I<nph> enabled. 


=head1 AUTHOR

Written by ChenGang, yikuyiku.com@gmail.com

L<http://blog.yikuyiku.com/>


=head1 COPYRIGHT

Copyright (c) 2011 ChenGang.
This library is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.


=head1 SEE ALSO

L<HTTP::Server::Encrypt>, L<CGI>, L<http://en.wikipedia.org/wiki/Common_Gateway_Interface>

=cut
