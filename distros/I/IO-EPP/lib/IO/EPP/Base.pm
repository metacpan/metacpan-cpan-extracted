package IO::EPP::Base;

=encoding utf8

=head1 NAME

IO::EPP::Base

=head1 SYNOPSIS

    use Data::Dumper;
    use IO::EPP::Base;

    sub make_request {
        my ( $action, $params ) = @_;

        unless ( $params->{conn} ) {
            # need to connect

            my %sock_params = (
                PeerHost        => 'epp.example.com',
                PeerPort        => 700,
                SSL_key_file    => 'key.pem',
                SSL_cert_file   => 'cert.pem',
                Timeout         => 30,
            );

            $params->{user} = 'login';
            $params->{pass} = 'xxxxx';

            $params->{sock_params} = \%sock_params;

            $params->{test_mode} = 1; # use emulator

            # $params->{no_log} = 1; # 1 if no logging

            # enter a name if you need to specify a file for the log
            # $params->{log_name} = '/var/log/comm_epp_example.log';

            # use our function for logging
            $params->{log_fn} = sub { print "epp.example.com logger:\n$_[0]\n" };
        }

        return IO::EPP::Base::make_request( $action, $params );
    }

    my ( $answ, $msg, $conn_obj ) = make_request( 'check_domains', { domains => [ 'xyz.com', 'com.xyz', 'reged.xyz' ] } );

    print Dumper $answ;

Result:

    $VAR1 = {
          'msg' => 'Command completed successfully.',
          'xyz.com' => {
                         'avail' => '1'
                       },
          'reged.xyz' => {
                           'reason' => 'in use',
                           'avail' => '0'
                         },
          'code' => '1000',
          'com.xyz' => {
                         'avail' => '1'
                       }
        };
}

=head1 DESCRIPTION

Module for common EPP-functions, without extension (dnssec only).

The module can be used to work with any provider,
if the requests do not use extensions and the provider does not have its own features

It has two options: using a separate function call or working as an object

=cut

use Digest::MD5 qw(md5_hex);
use Time::HiRes qw(time);
use IO::Socket;
use IO::Socket::SSL;

use strict;
use warnings;

# common chunks for all standard queries
our $epp_head = '<?xml version="1.0" encoding="UTF-8"?>
<epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $epp_cont_urn =
'xmlns:contact="urn:ietf:params:xml:ns:contact-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:contact-1.0 contact-1.0.xsd"';
our $epp_host_urn =
'xmlns:host="urn:ietf:params:xml:ns:host-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:host-1.0 host-1.0.xsd"';
our $epp_dom_urn  =
'xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"';

our %id = ( crID => 'creater', clID => 'owner', upID => 'updater', reID => 'requestors_id', acID => 'senders_id' );
our %dt = ( crDate => 'cre_date', upDate => 'upd_date', trDate => 'trans_date', exDate => 'exp_date', reDate => 'request_date', acDate => 'send_date'  );


=head1 FUNCTIONS

=head2 make_request

See IO:EPP for description

An example of working with functions is presented in the synopsis

Work checked on CentralNic server

INPUT:
action name;
parameters of query

OUTPUT:
full answer with code and message;
string with code and message;
io::epp object

=cut

sub make_request {
    my ( $action, $params ) = @_;

    my ( $self, $code, $msg, $answ );

    if ( !$params->{tld}  &&  $params->{dname} ) {
        ( $params->{tld} ) = $params->{dname} =~ /^[0-9a-z\-]+\.(.+)$/;
    }

    unless ( $params->{conn} ) {
        # Need greate obj and login
        ( $self, $code, $msg ) = IO::EPP::Base->new( $params );

        unless ( $code  and  $code == 1000 ) {
            goto END_MR;
        }
    }
    else {
        $self = $params->{conn};
    }

    $self->{critical_error} = '';

    if ( $self->can( $action ) ) {
        ( $answ, $code, $msg ) = $self->$action( $params );
    }
    else {
        $msg = "undefined command <$action>, request cancelled";
        $code = 0;
    }

END_MR:

    $msg .= '; ' . $self->{critical_error} if $self->{critical_error};

    my $full_msg = "code: $code\nmsg: $msg";

    $answ = {} unless $answ && ref $answ;

    $answ->{code} = $code;
    $answ->{msg}  = $msg;

    return wantarray ? ( $answ, $full_msg, $self ) : $answ;
}


sub gen_id {
    my @chars = ( 'a'..'z', '0'..'9' );

    return join '', map( { $chars[ int rand( scalar @chars ) ] } 1..12 );
}


=head2 gen_pw

Authinfo Generation

INPUT:
length of authInfo, default 16 symbols

OUTPUT:
new authInfo

=cut

sub gen_pw {
    my ( $pw_length ) = @_;

    $pw_length = 16  unless $pw_length;

    my $pw;

    my @chars = ( '0'..'9', 'A'..'Z', 'a'..'z', '!', '@', '$', '%', '*', '_', '.', ':', '-', '=', '+', '?', '#', ',', '"', "'" );

    for ( 0..32 ) {
        $pw = join '', map( { $chars[ int rand( scalar @chars ) ] } 1..$pw_length );

        # буквы, цифры и символы должны быть обязательно
        last if ( $pw =~ /\d/  and  $pw =~ /[A-Z]/  and  $pw =~ /[a-z]/  and  $pw =~ /[!\@\$\%\*_\.:-=\+\?#,"']/ );
    }

    return $pw;
}


# Generation transaction id

sub get_cltrid {
    return md5_hex( time() . $$ . rand(1000000) );
}


# recursive removal of utf8 flag

sub recursive_utf8_unflaged {
    my $root = shift;

    if ( ref $root eq 'HASH' ) {
        foreach my $k ( keys %$root ) {
            my $key = $k;
            utf8::decode( $key );
            utf8::decode( $key );
            utf8::encode( $key );
            # work if $root->{with_utf8_flag} ne $root->{without_utf8_flag}
            $root->{$key} = recursive_utf8_unflaged( delete $root->{$k} ) ;
        }
    }
    elsif ( ref $root eq 'ARRAY' ) {
        $_ = recursive_utf8_unflaged($_) foreach @$root;
    }
    elsif ( $root  &&  ref $root eq '' ) {
        utf8::decode( $root );
        utf8::decode( $root );
        utf8::encode( $root );
    }

    return $root;
}

# clear date-time

sub cldate {
    my ( $dt ) = @_;

    $dt =~ s/T/ /;
    $dt =~ s/\.\d+Z$//;
    $dt =~ s/Z$//;

    return $dt;
}


=head1 METHODS

=head2 new

Create new IO::EPP object, аutomatically connects to the provider and logins.

Example of a call

    # Parameters for L<IO::Socket::SSL>
    my %sock_params = (
        PeerHost => 'epp.example.com',
        PeerPort => 700,
        SSL_key_file  => $path_to_ssl_key_file,
        SSL_cert_file => $path_to_ssl_cert_file,
        Timeout  => 30,
    );

    # initialization of an object, during which login is called
    my $o = IO::EPP::Base->new( {
        sock_params => \%sock_params,
        user        => $login_name,
        pass        => $login_password,
        log_name    => '/var/log/comm_epp_registry_name',
    } );

    # call check of domains
    my ( $answ, $code, $msg ) = $o->check_domains( { domains => [ 'kalinka.realty' ] } );

    undef $o; # call logout() и DESTROY() of object

Connection parameters:
C<user>        -- login;
C<pass>        -- password;
C<tld>         -- zone for providers that have a binding in it, for example, verisign;
C<server>      -- server name if the registry has different servers with different extensions, for example, pir/afilias for afilias;
C<sock_params> -- hashref with L<IO::Socket::SSL> parameters;
C<test_mode>   -- use a real connection or registry emulator.

Parameters for logging:
C<no_log>   -- do not write anything to the log;
C<log_name> -- write log in this file, not in STDOUT;
C<log_fn>   -- ref on functions to write to the log.

=cut

sub new {
    my ( $package, $params ) = @_;

    my ( $self, $code, $msg );

    my $sock;

    my $sock_params = delete $params->{sock_params};

    my $test = delete $params->{test_mode};

    if ( $test ) {
        $sock = $sock_params->{PeerHost} . ':' . $sock_params->{PeerPort};
    }
    else {
        $sock = IO::Socket::SSL->new(
            PeerPort => 700,
            Timeout  => 30,
            %{$sock_params},
        );
    }

    unless ( $sock ) {
        $msg = "can not connect";
        $code = 0;

        goto ERR;
    }

    $self = bless {
        sock           => $sock,
        user           => delete $params->{user},
        tld            => $params->{tld} || '',
        server         => delete $params->{server} || '',
        #launch         => $params->{launch} || '',
        log_name       => delete $params->{log_name},
        log_fn         => delete $params->{log_fn},
        no_log         => delete $params->{no_log} || 0,
        test           => $test,
        critical_error => undef,
    }, $package;

    $self->set_urn();

    $self->set_log_vars( $params );

    $self->epp_log( "Connect to $$sock_params{PeerHost}:$$sock_params{PeerPort}\n" );

    my $hello = $self->req();

    if ( !$hello  ||  $self->{critical_error} ) {
        $msg = "Can't get greeting";
        $msg .= '; ' . $self->{critical_error} if $self->{critical_error};
        $code = 0;

        goto ERR;
    }

    my ( $svcs, $extension ) = ( '', '' );

    if ( ref( $self ) =~ /IO::EPP::Base/ ) {
        if ( $hello =~ /urn:ietf:params:xml:ns:contact-1.0/ ) {
            $svcs .= '
    <objURI>urn:ietf:params:xml:ns:contact-1.0</objURI>';
        }
        if ( $hello =~ /urn:ietf:params:xml:ns:domain-1.0/ ) {
            $svcs .= '
    <objURI>urn:ietf:params:xml:ns:domain-1.0</objURI>';
        }
        if ( $hello =~ /urn:ietf:params:xml:ns:host-1.0/ ) {
            # drs.ua not want host
            $svcs .= '
    <objURI>urn:ietf:params:xml:ns:host-1.0</objURI>';
        }

        if ( $hello =~ /urn:ietf:params:xml:ns:secDNS-1.1/ ) {
            $extension .= '
     <extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI>';
        }
    }

    # have a connection, can log in
    my ( undef, $c, $m ) = $self->login( delete $params->{pass}, $svcs, $extension ); # no save passwd in object

    if ( $c  and  $c == 1000 ) {
        return wantarray ? ( $self, $c, $m ) : $self;
    }

    $msg = ( $m || '' ) . $self->{critical_error};
    $code = $c || 0;

ERR:
    return wantarray ? ( 0, $code, $msg ) : 0;
}


sub set_urn {
    $_[0]->{urn} = {
        head => $IO::EPP::Base::epp_head,
        cont => $IO::EPP::Base::epp_cont_urn,
        host => $IO::EPP::Base::epp_host_urn,
        dom  => $IO::EPP::Base::epp_dom_urn,
    };
}


# Set name for log

sub set_log_vars {
    my ( $self, $params ) = @_;

    $self->{log_name} = delete $params->{log_name} if $params->{log_name};
    $self->{log_fn}   = delete $params->{log_fn}   if $params->{log_fn};
}


=head2 epp_log

Writes data to the log or calls the function specified when creating the object

By default, the log is written: date and time, pid of the process, name and body of the request:

    Thu Jan  1 01:00:00 1111
    pid: 12345
    check_domains request:
    <?xml version="1.0" encoding="UTF-8"?>
    <epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">
     <command>
      <check>
       <domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd">
        <domain:name>xyz.com</domain:name><domain:name>com.xyz</domain:name><domain:name>reged.xyz</domain:name>
       </domain:check>
      </check>
      <clTRID>50df482a1e928a00fa0e7fce3fe68f0f</clTRID>
     </command>
    </epp>

    Thu Feb  2 02:02:22 2222
    pid: 12345
    check_domains answer:
    <?xml version="1.0" encoding="UTF-8" standalone="no"?>
    <epp xmlns="urn:ietf:params:xml:ns:epp-1.0">
    <response>
    <result code="1000">
    <msg>Command completed successfully.</msg>
    </result>
    <resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0">
    <domain:cd><domain:name avail="1">xyz.com</domain:name></domain:cd>
    <domain:cd><domain:name avail="1">com.xyz</domain:name></domain:cd>
    <domain:cd><domain:name avail="0">reged.xyz</domain:name><domain:reason>in use</domain:reason></domain:cd>
    </domain:chkData></resData><trID>
    <clTRID>50df482a1e928a00fa0e7fce3fe68f0f</clTRID><svTRID>TEST-2979E52890117206AAA1639725F4E862</svTRID>
    </trID>
    </response>
    </epp>

=cut

sub epp_log {
    my ( $self, $string ) = @_;

    return if $self->{no_log};

    $string = "pid: $$\n" . $string;

    if ( $self->{log_fn} ) {
        &{$self->{log_fn}}( $string );
    }
    elsif ( $self->{log_name} ) {
        my $fh;

        if ( $self->{log_fh} ) {
            $fh = $self->{log_fh};
        }
        else{
            open( $fh, '>>', $self->{log_name} ) or die "Can't open $self->{log_name}: $!\n";

            $self->{log_fh} = $fh;
        }

        print $fh scalar(localtime) . "\n$string\n\n"; # if `print( $self->{log_fh} $string );` that get error `(Missing operator before  $string?)`
    }
    else {
        print scalar(localtime) . "\n$string\n\n";
    }
}


=head2 req_test

For replace req() in test mode

=cut

sub req_test {
    my ( $self, $out_data, $info ) = @_;

    require IO::EPP::Test::Base;

    $self->epp_log( "$info request:\n$out_data" ) if $out_data;

    my $answ;
    eval{
        $answ = IO::EPP::Test::Base::req( @_ );
        1;
    }
    or do {
        $self->{critical_error} = "$info req error: $@";
        return;
    };

    $self->epp_log( "$info answer:\n$answ" );

    return $answ;
}


=head2 req

Request to registry

INPUT:
out_data -- body of request;
info -- name of request for log.

OUTPUT:
answer from registry.

=cut

sub req {
    my ( $self, $out_data, $info ) = @_;

    $self->{critical_error} = '';

    $info ||= '';

    return $self->req_test( $out_data, $info ) if $self->{test};

    my $THRESHOLD = 100000000;

    if ( $out_data ) {
        my $d = $out_data;
        # Remove password, authinfo from log
        $d =~ s/<pw>[^<>]+<\/pw>/<pw>xxxxx<\/pw>/;

        $self->epp_log( "$info request:\n$d" );
    }

    my $in_data = '';
    my $start_time = time;

    eval{
        local $SIG{ALRM} = sub { die "connection timeout\n" };

        alarm 120;

        if ( $out_data ) {
            # https://rt.cpan.org/Ticket/Display.html?id=98368
            # https://rt.cpan.org/Ticket/Display.html?id=98372
            utf8::downgrade( $out_data );

            my $len = length( $out_data ) + 4;
            my $pk_data_size = pack( 'N', $len );

            my $a_out = $self->{sock}->print( $pk_data_size . $out_data );
            $self->{sock}->flush();

            die "data write failed" unless $a_out;
        };

        # header - 4 bytes Nxxx with size
        my $hdr;
        unless ( defined( $self->{sock}->read( $hdr, 4 ) ) ) {
            die "closed connection\n";
        }

        my $data_size = ( unpack( 'N', $hdr ) // 0 ) - 4;

        die "closed connection\n" if $data_size < 0;

        die "data length is zero\n" unless $data_size;

        die "data length is $data_size which exceeds $THRESHOLD\n" if $data_size > $THRESHOLD;

        # Read data block
        my $buf;
        my $wait_cnt = 0;

        while ( length( $in_data ) < $data_size ) {
            $buf = '';
            $self->{sock}->read( $buf, ( $data_size - length( $in_data ) ));

            if ( length( $buf ) == 0 ) {
                if ( $wait_cnt < 3 ) {
                    # part of the data may come with a long delay when saving the connection
                    # this problem is observed in corenic and drs
                    $wait_cnt++;
                    sleep 1;
                    redo;
                }
                else {
                    # it is likely that the socket has closed
                    last;
                }
            }

            $in_data .= $buf;
        }

        # recheck, because something could not reach or stop at \0
        my $l = length( $in_data );
        die "data read failed: readed $l, need $data_size\ndata: $in_data" if $l != $data_size;

        alarm 0;

        1;
    } or do {
        my $err = $@;

        alarm 0;

        my $req_time = sprintf( '%0.4f', time - $start_time );
        $self->epp_log( "req_time: $req_time\n$info req error: $err" );

        $self->{critical_error} = "req error: $err";

        return;
    };

    my $req_time = sprintf( '%0.4f', time - $start_time );
    $self->epp_log( "req_time: $req_time\n$info answer:\n$in_data" );

    return $in_data;
}


=head2 simple_request

Universal handler for simple answer

INPUT:
request body;
request name;
check or not epp poll, default is 0

OUTPUT:
answer;
answer code;
answer message

=cut

sub simple_request {
    my ( $self, $body, $info, $check_queue_msgs ) = @_;

    unless ( $body ) {
        return wantarray ? ( 0, 0, 'no query' ) : 0 ;
    }

    my $content = $self->req( $body, $info );

    if ( $content  &&  $content =~ /<result code=['"](\d+)['"]>/ ) {
        my $code = $1 + 0;

        my $msg = '';
        if ( $content =~ /<result.+<msg[^<>]*>(.+)<\/msg>.+\/result>/s ) {
            $msg = $1;
        }

        if ( $code == 1001  or  $code >= 2000 ) {
            # 1001 -- pendingAction
            # 2000+ - May be an addition to the error, It is the inventions of different providers
            my $reason = join( ';', $content =~ /<reason[^<>]*>([^<>]+)<\/reason>/g );

            $msg .= "; " . $reason if $reason;

            my ( $xcp ) = $content =~ /<oxrs:xcp>([^<>]+)<\/oxrs:xcp>/;

            $msg .= "; " . $xcp if $xcp;

            my ( $text ) = $content =~ /<result.+<text>([^<>]+)<\/text>.+\/result>/s;

            $msg .= "; " . $text if $text;
        }

        # And check epp poll
        my $queue_msgs = '';

        if ( $check_queue_msgs  and  $content =~ /<msgQ count=['"](\d+)['"] id=['"](\d+)['"]>/ ) {
            $queue_msgs = { count => $1 , id => $2 };
        }

        my $info = {};

        # dates
        foreach my $k ( keys %dt ) {
            if ( $content =~ m|<[a-z]+:$k>([^<>]+)</[a-z]+:$k>| ) {
                $info->{$dt{$k}} = cldate( $1 );
            }
        }

        if ( $content =~ m{<contact:id>([^<>]+)</contact:id>} ) {
            $info->{cont_id} = $1;
        }

        if ( $content =~ m{<(host|domain):name>([^<>]+)</(host|domain):name>} ) {
            my %r = ( host => 'ns', domain => 'dname' );

            $info->{$r{$1}} = $2;
        }

        # This is needed to monitor deferred actions at some providers
        ( $info->{cltrid} ) = $content =~ /<clTRID>([0-9A-Za-z\-]+)<\/clTRID>/;
        ( $info->{svtrid} ) = $content =~ /<svTRID>([0-9A-Za-z\-]+)<\/svTRID>/;

        return wantarray ? ( $info, $code, $msg, $queue_msgs ) : $info;
    }

    return wantarray ? ( 0, 0, 'empty answer' ) : 0 ;
}

=head2 login

Authorization on the server.
The function is automatically called from new.
A separate call is only needed to change the password.

INPUT:
password;
addition standard parameters (<objURI>xxxxx-1.0</objURI>);
extensions (<extURI>yyyyyy-1.0</extURI>);
new password if need.

OUTPUT: see L</simple_request>.

=cut

sub login {
    my ( $self, $pw, $svcs, $ext, $new_pw ) = @_;

    return ( 0, 0, 'no user'   ) unless $self->{user};
    return ( 0, 0, 'no passwd' ) unless $pw;

    $svcs ||= ''; # addition standard parameters
    $ext  ||= ''; # extension

    if ( $ext ) {
        $ext = "\n    <svcExtension>$ext\n    </svcExtension>";
    }

    my $npw = '';
    if ( $new_pw ) {
        $npw = "\n   <newPW>$new_pw</newPW>";
    }

    my $cltrid = get_cltrid();

    my $body = <<LOGIN;
$$self{urn}{head}
 <command>
  <login>
   <clID>$$self{user}</clID>
   <pw>$pw</pw>$npw
   <options>
    <version>1.0</version>
    <lang>en</lang>
   </options>
   <svcs>$svcs$ext
   </svcs>
  </login>
  <clTRID>$cltrid</clTRID>
 </command>
</epp>
LOGIN

    return $self->simple_request( $body, 'login' );
}


=head2 hello

Get greeting, ping analog.

No parameters.

=cut

sub hello {
    my ( $self ) = @_;

    my $body = <<HELLO;
$$self{urn}{head}
 <hello xmlns="urn:ietf:params:xml:ns:epp-1.0"/>
</epp>
HELLO

    my $content = $self->req( $body, 'hello' );

    unless ( $content && $content =~ /greeting/ ) {
        return wantarray ? ( 0, 0, 'no greeting' ) : 0;
    }

    my $info = {
        code => 1000,
        msg  => $content,
    };

    return wantarray ? ( $info, 1000, $content ) : $info;
}


=head2 check_contacts

Check whether there are contacts with such IDs

INPUT:
params with key:
C<contacts> -- arrayref on contact id list.

Request:

    my ( $answ, $msg ) = make_request( 'check_contacts', {  contacts => [ 'H1234567', 'nfjkrek-fre8fm' ] } );

    print Dumper $answ;

Answer:

    $VAR1 = {
          'msg' => 'Command completed successfully.',
          'nfjkrek-fre8fm' => {
                                'avail' => '1'
                              },
          'H1234567' => {
                          'avail' => '0'
                        },
          'code' => '1000'
        };

=cut

sub check_contacts {
    my ( $self, $params ) = @_;

    return ( 0, 0, 'no contacts' ) unless $params->{contacts}  &&  scalar( @{$params->{contacts}} );

    my $contacts = $params->{contacts};

    my $conts = '';

    foreach my $cont ( @$contacts ) {
        $conts .= "<contact:id>$cont</contact:id>";
    }

    my $ext = $$params{extension} || '';

    $ext = "\n  <extension>\n$ext  </extension>" if $ext;

    my $cltrid = get_cltrid();

    my $body = <<CHECKCONT;
$$self{urn}{head}
 <command>
  <check>
   <contact:check $$self{urn}{cont}>
    $conts
   </contact:check>
  </check>$ext
  <clTRID>$cltrid</clTRID>
 </command>
</epp>
CHECKCONT

    my $content = $self->req( $body, 'check_contacts' );

    if ( $content =~ /<result code=['"](\d+)['"]>/ ) {
        my $code = $1 + 0;

        my $msg = '';
        if ( $content =~ /<result.+<msg[^<>]*>(.+)<\/msg>.+\/result>/s ) {
            $msg = $1;
        }

        my @aa = $content =~ /(<contact:id avail=['"]\d['"]>[^<>]+<\/contact:id>)/g;

        my %answ;
        foreach my $a ( @aa ) {
            if ( $a =~ /<contact:id avail=['"](\d)['"]>([^<>]+)<\/contact:id>/ ) {
                $answ{$2} = { avail => $1 };
            }
        }

        return wantarray ? ( \%answ, $code, $msg ) : \%answ;
    }

    return wantarray ? ( 0, 0, 'empty answer' ) : 0 ;
}

# Convert contact params to xml text

sub cont_to_xml {
    my ( $self, $params ) = @_;

    unless ( $$params{'int'}  &&  $$params{'loc'} ) {
        # Set default is 'int'
        foreach my $f ( 'name', 'first_name', 'last_name', 'patronymic', 'family_name', 'company', 'addr', 'city', 'state', 'postcode', 'country_code' ) {
            $$params{'int'}{$f} = delete $$params{$f} if defined $$params{$f};
        }
    }

    my $postalinfo = '';
    foreach my $type ( 'int', 'loc' ) { # legal - in children modules
        next unless $$params{$type};

        # need_name=1 for creation - always, for update:
        # According to the standard at change of id the name does not change ( https://tools.ietf.org/html/rfc5733#page-23 ),
        # but some providers of it do not know,
        # at the same time, they have no documentation, but send all to read RFC, example, drs.ua
        my $name = '';
        if ( $$params{need_name} ) {
            if ( $$params{$type}{name} ) {
                $name = $$params{$type}{name};
            }
            else {
                $name = $$params{$type}{first_name} if $$params{$type}{first_name};

                if ( $$params{$type}{last_name}  &&  $$params{$type}{family_name} ) {
                    if ( $$params{$type}{last_name} ) {
                        $name .= ' ' if $name;
                        $name .= $$params{$type}{last_name};
                    }

                    if ( $$params{$type}{patronymic} ) {
                        $name .= ' ' if $name;
                        $name .= $$params{$type}{patronymic};
                    }

                    if ( $$params{$type}{family_name} ) {
                        $name .= ' ' if $name;
                        $name .= $$params{$type}{family_name};
                    }
                }
                else {
                    # family_name eq last_name
                    if ( $$params{$type}{patronymic} ) {
                        $name .= ' ' if $name;
                        $name .= $$params{$type}{patronymic};
                    }

                    if ( $$params{$type}{last_name}  ||  $$params{$type}{family_name} ) {
                        $name .= ' ' if $name;
                        $name .= $$params{$type}{last_name} || $$params{$type}{family_name};
                    }
                }

            }

            $name = "\n     <contact:name>$name</contact:name>" if $name;
        }

        my $org;
        if ( $$params{$type}{org} ) {
            $$params{$type}{org} =~ s/&/&amp;/g;

            $org = "<contact:org>$$params{$type}{org}</contact:org>";
        }
        else {
            $org = '<contact:org/>';
        }


        my $street = '';

        $$params{$type}{addr} = [ $$params{$type}{addr} ] unless ref $$params{$type}{addr};

        foreach my $s ( @{$$params{$type}{addr}} ) {
            $street .= "\n      " if $street;
            $street .= "<contact:street>$s</contact:street>";
        }

        my $sp   = $$params{$type}{'state'}  ? "<contact:sp>$$params{$type}{state}</contact:sp>"     : '<contact:sp/>' ;
        my $pc   = $$params{$type}{postcode} ? "<contact:pc>$$params{$type}{postcode}</contact:pc>"  : '<contact:pc/>' ;

        $postalinfo .= qq|
    <contact:postalInfo type="$type">$name
     $org
     <contact:addr>
      $street
      <contact:city>$$params{$type}{city}</contact:city>
      $sp
      $pc
      <contact:cc>$$params{$type}{country_code}</contact:cc>
     </contact:addr>
    </contact:postalInfo>|;
    }

    # voice / fax Extension <contact:voice x="1234"> is disabled
    my $voice = '';
    $$params{phone} = [ $$params{phone} ] unless ref $$params{phone};
    foreach my $s ( @{$$params{phone}} ) {
        $voice .= "\n      " if $voice;
        $voice .= "<contact:voice>$s</contact:voice>";
    }

    my $fax = $$params{fax}      ? "<contact:fax>$$params{fax}</contact:fax>"    : '<contact:fax/>';

    my $email = '';
    $$params{email} = [ $$params{email} ] unless ref $$params{email};
    foreach my $s ( @{$$params{email}} ) {
        $email .= "\n      " if $email;
        $email .= "<contact:email>$s</contact:email>";
    }

    my $pw  = $$params{authinfo} ? "<contact:pw>$$params{authinfo}</contact:pw>" : '<contact:pw/>' ;

    $$params{pp_ext} ||= '';

    my $textcont = qq|$postalinfo
    $voice
    $fax
    $email
    <contact:authInfo>
     $pw
    </contact:authInfo>$$params{pp_ext}|;

    return $textcont;
}


# create contact extensions,
# for overwriting in child classes

sub create_contact_ext {
    return '';
}

=head2 create_contact

Register a contact

OUTPUT: see L</simple_request>.

=cut

sub create_contact {
    my ( $self, $params ) = @_;

    return ( 0, 0, 'no params' ) unless ref $params;

    return ( 0, 0, 'no cont_id' ) unless $params->{cont_id};

    $params->{need_name} = 1;

    my $textcont = $self->cont_to_xml( $params );

    my $ext = $params->{extension} || '';

    $ext .= $self->create_contact_ext( $params );

    if ( $ext ) {
        $ext = "\n  <extension>\n$ext  </extension>";
    }

    my $cltrid = get_cltrid();

    my $body = <<CRECONT;
$$self{urn}{head}
 <command>
  <create>
   <contact:create $$self{urn}{cont}>
    <contact:id>$$params{cont_id}</contact:id>$textcont
   </contact:create>
  </create>$ext
  <clTRID>$cltrid</clTRID>
 </command>
</epp>
CRECONT

    return $self->simple_request( $body, 'create_contact' );
}


sub cont_from_xml {
    my ( undef, $rdata ) = @_;

    my %cont;

    ( $cont{cont_id} ) = $rdata =~ /<contact:id>([^<>]+)<\/contact:id>/;

    ( $cont{roid} ) = $rdata =~ /<contact:roid>([^<>]+)<\/contact:roid>/;

    my @atypes = ( 'int', 'loc' );
    foreach my $atype ( @atypes ) {
        my ( $postal ) = $rdata =~ /<contact:postalInfo type=['"]$atype['"]>(.+?)<\/contact:postalInfo>/s;

        next unless $postal;

        ( $cont{$atype}{name} ) = $postal =~ /<contact:name>([^<>]+)<\/contact:name>/;

        if ( $rdata =~ /<contact:org>([^<>]*)<\/contact:org>/ ) {
            $cont{$atype}{org} = $1;
            $cont{$atype}{org} =~ s/&amp;/&/g;
        }


        $cont{$atype}{addr} = join(', ', $postal =~ /<contact:street>([^<>]*)<\/contact:street>/ );

        ( $cont{$atype}{city} ) = $postal =~ /<contact:city>([^<>]*)<\/contact:city>/;

        ( $cont{$atype}{'state'} ) = $postal =~ /<contact:sp>([^<>]*)<\/contact:sp>/;

        ( $cont{$atype}{postcode} ) = $postal =~ /<contact:pc>([^<>]*)<\/contact:pc>/;

        ( $cont{$atype}{country_code} ) = $postal =~ /<contact:cc>([A-Za-z]+)<\/contact:cc>/;
        $cont{$atype}{country_code} = uc $cont{$atype}{country_code};
    }

    $cont{phone}  = [ $rdata =~ /<contact:voice[^<>]*>([0-9+.]*)<\/contact:voice>/g ];

    $cont{fax} = [ $rdata =~ /<contact:fax[^<>]*>([0-9+.]*)<\/contact:fax>/g ];

    $cont{email} = [ $rdata =~ /<contact:email>([^<>]+)<\/contact:email>/g ];

    # <contact:status s="linked"/>
    my @ss = $rdata =~ /<contact:status s=['"]([^'"]+)['"]\s*\/?>/g;
    # <contact:status s="ok">No changes pending</contact:status>
    my @aa = $rdata =~ /<contact:status[^<>]+>[^<>]+<\/contact:status>/g;
    if ( scalar @aa ) {
        foreach my $row ( @aa ) {
            if ( $row =~ /<contact:status s=['"]([^'"]+)['"]\s*>([^<>]+)<\/contact:status>/ ) {
                $cont{statuses}{$1} = $2;
            }
        }
    }
    else {
        $cont{statuses}{$_} = '+' for @ss;
    }

    if ( $rdata =~ /<contact:authInfo>\s*<contact:pw>(.+?)<\/contact:pw>/s ) {
        $cont{authinfo} = $1;
    }

    my ( $visible ) = $rdata =~ /<contact:disclose flag=['"](\d)['"]>/;
    $cont{pp_flag} = $visible ? 0 : 1;

    # owner, ...
    foreach my $k ( keys %id ) {
        if ( $rdata =~ /<contact:$k>([^<>]+)<\/contact:$k>/ ) {
            $cont{$id{$k}} = $1;
        }
    }

    # dates
    foreach my $k ( keys %dt ) {
        if ( $rdata =~ /<contact:$k>([^<>]+)<\/contact:$k>/ ) {
            $cont{$dt{$k}} = $1;

            $cont{$dt{$k}} =~ s/T/ /;
            $cont{$dt{$k}} =~ s/\.\d+Z$//;
            $cont{$dt{$k}} =~ s/Z$//;
        }
    }

    return \%cont;
}


# Providers extension, replaced in provider modules

sub get_contact_ext {
    return {};
}


=head2 get_contact_info

Get information on the specified contact

=cut

sub get_contact_info {
    my ( $self, $params ) = @_;

    return ( 0, 0, 'no cont_id' ) unless $$params{cont_id};

    my $ext = $$params{extension} || '';

    if ( $ext ) {
        $ext = "\n  <extension>\n$ext  </extension>";
    }

    my $cltrid = get_cltrid();

    my $body = <<CONTINFO;
$$self{urn}{head}
 <command>
  <info>
   <contact:info $$self{urn}{cont}>
    <contact:id>$$params{cont_id}</contact:id>
   </contact:info>
  </info>$ext
  <clTRID>$cltrid</clTRID>
 </command>
</epp>
CONTINFO

    my $content = $self->req( $body, 'get_contact_info' );

    if ( $content =~ /result code=['"](\d+)['"]/ ) {
        my $rcode = $1 + 0;

        my $msg = '';
        if ( $content =~ /<result.+<msg[^<>]*>(.+)<\/msg>.+\/result>/s ) {
            $msg = $1;
        }

        my $cont;

        # take the main part and disassemble
        if ( $content =~ /<resData>(.+)<\/resData>/s ) {
            $cont = $self->cont_from_xml( $1 );
        }
        else {
            return wantarray ? ( 0, $rcode, $msg ) : 0 ;
        }

        if ( $content =~ /<extension>(.+)<\/extension>/s ) {
            my $ext = $1;

            my $spec_ext = $self->get_contact_ext( $ext );

            $cont->{$_} = $spec_ext->{$_} for keys %$spec_ext;

            if ( $content =~ /<keysys:resData[^<>]*>(.+)<\/keysys:resData>/s ) {
                # key-system extension TODO: move
                my $krdata = $1;

                push @{$cont->{statuses}}, 'validated' if $krdata =~ /<keysys:validated>1<\/keysys:validated>/;
                push @{$cont->{statuses}}, 'verified'  if $krdata =~ /<keysys:verified>1<\/keysys:verified>/;
                push @{$cont->{statuses}}, 'verification-requested'
                    if $krdata =~ /<keysys:verification-requested>1<\/keysys:verification-requested>/;
            }
        }

        return wantarray ? ( $cont, $rcode, $msg ) : $cont;
    }

    return wantarray ? ( 0, 0, 'empty answer' ) : 0 ;
}

sub update_statuses_add {
    my ( undef, $type, $statuses ) = @_;

    my $add = '';
    my %sts;

    if ( ref $statuses eq 'HASH' ) {
        %sts = %{$statuses};
    }
    elsif ( ref $statuses eq 'ARRAY' ) {
        $sts{$_} = '+' for @{$statuses};
    }

    foreach my $st ( keys %sts ) {
        if ( !$sts{$st}  or  $sts{$st} eq '+' ) {
            $add .= qq|     <$type:status s="$st"/>\n|;
        }
        else {
            $add .= qq|     <$type:status s="$st">$sts{$st}</$type:status>\n|;
        }
    }

    return $add;
}


sub update_statuses_rem {
    my ( undef, $type, $statuses ) = @_;

    my $rem = '';
    my @sts;

    if ( ref $statuses eq 'HASH' ) {
        @sts = keys %{$statuses};
    }
    elsif ( ref $statuses eq 'ARRAY' ) {
        @sts = @{$statuses};
    }

    $rem .= qq|     <$type:status s="$_"/>\n| foreach @sts;

    return $rem;
}

=head2 update_contact

To update contact information

OUTPUT: see L</simple_request>.

=cut

sub update_contact {
    my ( $self, $params ) = @_;

    return ( 0, 0, 'no params' ) unless ref $params;

    return ( 0, 0, 'no cont_id' ) unless $params->{cont_id};

    my ( $add, $rem, $chg ) = ( '', '', '' );

    if ( $$params{add} ) {
        if ( $$params{add}{statuses} ) {
            $add .= $self->update_statuses_add( 'contact', $$params{add}{statuses} );
        }
    }

    $add = "\n    <contact:add>\n$add    </contact:add>" if $add;

    if ( $$params{rem} ) {
        if ( $$params{rem}{statuses} ) {
            $rem .= $self->update_statuses_rem( 'contact', $$params{rem}{statuses} );
        }
    }

    $rem = "\n    <contact:rem>\n$rem    </contact:rem>" if $rem;

    if ( $$params{chg} ) {
        $chg .= $self->cont_to_xml( $$params{chg} );

        $chg =~ s/\n/\n  /g;
    }

    $chg = "\n    <contact:chg>$chg   </contact:chg>" if $chg;

    my $ext = $$params{extension} || '';

    $ext = "\n  <extension>\n$ext  </extension>" if $ext;

    my $cltrid = get_cltrid();

    my $body = <<UPDCONT;
$$self{urn}{head}
 <command>
  <update>
   <contact:update $$self{urn}{cont}>
    <contact:id>$$params{cont_id}</contact:id>$add$rem$chg
   </contact:update>
  </update>$ext
  <clTRID>$cltrid</clTRID>
 </command>
</epp>
UPDCONT

    return $self->simple_request( $body, 'update_contact' );
}


=head2 delete_contact

Delete the specified contact

OUTPUT:
see L</simple_request>.

=cut

sub delete_contact {
    my ( $self, $params ) = @_;

    return ( 0, 0, 'no params' ) unless ref $params;

    return ( 0, 0, 'no cont_id' ) unless $$params{cont_id};

    my $ext = $$params{extension} || '';

    $ext = "\n  <extension>\n$ext  </extension>" if $ext;

    my $cltrid = get_cltrid();

    my $body = <<DELCONT;
$$self{urn}{head}
 <command>
  <delete>
   <contact:delete $$self{urn}{cont}>
    <contact:id>$$params{cont_id}</contact:id>
   </contact:delete>
  </delete>$ext
  <clTRID>$cltrid</clTRID>
 </command>
</epp>
DELCONT

    return $self->simple_request( $body, 'delete_contact' );
}


=head2 check_nss

Check that the nameserver is registered

OUTPUT:
see L</simple_request>.

=cut

sub check_nss {
    my ( $self, $params ) = @_;

    return ( 0, 0, 'no nss' ) unless $params->{nss} && scalar( @{$params->{nss}} );

    my $hosts = '';

    foreach my $h ( @{$params->{nss}} ) {
        $hosts .= "<host:name>$h</host:name>";
    }

    my $ext = $$params{extension} || '';

    $ext = "\n  <extension>\n$ext  </extension>" if $ext;

    my $cltrid = get_cltrid();

    my $body = <<CHECKNSS;
$$self{urn}{head}
 <command>
  <check>
   <host:check $$self{urn}{host}>
    $hosts
   </host:check>
  </check>$ext
  <clTRID>$cltrid</clTRID>
 </command>
</epp>
CHECKNSS

    my $content = $self->req( $body, 'check_nss' );

    if ( $content =~ /<result code=['"](\d+)['"]>/ ) {
        my $code = $1 + 0;

        my $msg = '';
        if ( $content =~ /<result.+<msg[^<>]*>(.+)<\/msg>.+\/result>/s ) {
            $msg = $1;
        }

        my @aa = $content =~ /<host:cd>(.+?)<\/host:cd>/sg;

        my %answ;
        foreach my $a ( @aa ) {
            if ( $a =~ /<host:name avail=['"](\d)['"]>([^<>]+)<\/host:name>/ ) {
                my $ns = $2;
                $answ{$ns} = { avail => $1 };

                if ( $a =~ /<host:reason>([^<>]+)<\/host:reason>/ ) {
                    $answ{$ns}{reason} = $1;
                }
            }
        }

        return wantarray ? ( \%answ, $code, $msg ) : \%answ;
    }

    return wantarray ? ( 0, 0, 'no answer' ) : 0;
}


=head2 create_ns

Registering a nameserver

OUTPUT:
see L</simple_request>.

=cut

sub create_ns {
    my ( $self, $params ) = @_;

    return ( 0, 0, 'no ns' ) unless $params->{ns};

    my $addrs = '';
    if ( $params->{ips}  and  ref( $params->{ips} ) eq 'ARRAY' ) {
        foreach my $ip ( @{$params->{ips}} ) {
            if ( $ip =~ /^\d+\.\d+\.\d+\.\d+$/ ) {
                $addrs .= '<host:addr ip="v4">' . $ip . '</host:addr>';
            }
            else {
                $addrs .= '<host:addr ip="v6">' . $ip . '</host:addr>';
            }
        }
    }

    my $ext = $$params{extension} || '';

    $ext = "\n  <extension>\n$ext  </extension>" if $ext;

    my $cltrid = get_cltrid();

    my $body = <<CREATENS;
$$self{urn}{head}
 <command>
  <create>
   <host:create $$self{urn}{host}>
    <host:name>$$params{ns}</host:name>$addrs
   </host:create>
  </create>$ext
  <clTRID>$cltrid</clTRID>
 </command>
</epp>
CREATENS

    return $self->simple_request( $body, 'create_ns' );
}


sub get_ns_info_rdata {
    my ( undef, $rdata ) = @_;

    my %ns;

    ( $ns{name} ) = $rdata =~ /<host:name>([^<>]+)<\/host:name>/;
    $ns{name} = lc $ns{name};

    ( $ns{roid} ) = $rdata =~ /<host:roid>([^<>]+)<\/host:roid>/;

    # <host:status s="ok"/>
    my @ss = $rdata =~ /<host:status s=['"]([^'"]+)['"]\s*\/?>/g;
    # <host:status s="ok">No changes pending</host:status>
    my @aa = $rdata =~ /<host:status[^<>]+>[^<>]+<\/host:status>/g;
    if ( scalar @aa ) {
        foreach my $row ( @aa ) {
            if ( $row =~ /<host:status s=['"]([^'"]+)['"]\s*>([^<>]+)<\/host:status>/ ) {
                $ns{statuses}{$1} = $2;
            }
        }
    }
    else {
        $ns{statuses}{$_} = '+' for @ss;
    }

    $ns{addrs} = [ $rdata =~ /<host:addr ip=['"]v\d['"]>([0-9A-Fa-f.:]+)<\/host:addr>/g ];

    # owner, ...
    foreach my $k ( keys %id ) {
        if ( $rdata =~ /<host:$k>([^<>]+)<\/host:$k>/ ) {
            $ns{$id{$k}} = $1;
        }
    }

    # dates
    foreach my $k ( keys %dt ) {
        if ( $rdata =~ /<host:$k>([^<>]+)<\/host:$k>/ ) {
            $ns{$dt{$k}} = $1;

            $ns{$dt{$k}} =~ s/T/ /;
            $ns{$dt{$k}} =~ s/\.\d+Z$//;
            $ns{$dt{$k}} =~ s/Z$//;
        }
    }

    return \%ns;
}


=head2 get_ns_info

Get information about the specified nameserver

=cut

sub get_ns_info {
    my ( $self, $params ) = @_;

    return ( 0, 0, 'no ns' ) unless $params->{ns};

    my $ext = $$params{extension} || '';

    $ext = "\n  <extension>\n$ext  </extension>" if $ext;

    my $cltrid = get_cltrid();

    my $body = <<NSINFO;
$$self{urn}{head}
 <command>
  <info>
   <host:info $$self{urn}{host}>
    <host:name>$$params{ns}</host:name>
   </host:info>
  </info>$ext
  <clTRID>$cltrid</clTRID>
 </command>
</epp>
NSINFO

    my $content = $self->req( $body, 'get_ns_info' );

    if ( $content =~ /result code=['"](\d+)['"]/ ) {
        my $rcode = $1 + 0;

        my $msg = '';
        if ( $content =~ /<result.+<msg[^<>]*>(.+)<\/msg>.+\/result>/s ) {
            $msg = $1;
        }

        my $ns = {};

        # вытягиваем смысловую часть и парсим
        if ( $content =~ /<resData>(.+)<\/resData>/s ) {
            my $rdata = $1;

            $ns = $self->get_ns_info_rdata( $rdata );
        }

        return wantarray ? ( $ns, $rcode, $msg ) : $ns;
    }

    return 0;
}

=head2 update_ns

Change the data of the specified nameserver

OUTPUT:
see L</simple_request>.

=cut

sub update_ns {
    my ( $self, $params ) = @_;

    return ( 0, 0, 'no ns' ) unless $$params{ns};

    my $add = '';

    if ( $params->{add} ) {
        if ( $params->{add}{ips}  and  ref $params->{add}{ips} ) {
            foreach my $ip ( @{$params->{add}{ips}} ) {
                if ( $ip =~ /^\d+\.\d+\.\d+\.\d+$/ ) {
                    $add .= '     <host:addr ip="v4">'.$ip."</host:addr>\n";
                }
                else {
                    $add .= '     <host:addr ip="v6">'.$ip."</host:addr>\n";
                }
            }
        }

        if ( $params->{add}{statuses} ) {
            $add .= $self->update_statuses_add( 'host', $params->{add}{statuses} );
        }
    }

    if ( $add ) {
        $add = "<host:add>\n$add    </host:add>";
    }
    else {
        $add = '<host:add/>';
    }

    my $rem = '';

    if ( $params->{rem} ) {
        if ( defined $params->{rem}{ips}  and  ref $params->{rem}{ips} ) {
            foreach my $ip ( @{$params->{rem}{ips}} ) {
                if ( $ip =~ /^\d+\.\d+\.\d+\.\d+$/ ) {
                    $rem .= '     <host:addr ip="v4">'.$ip."</host:addr>\n";
                }
                else {
                    $rem .= '     <host:addr ip="v6">'.$ip."</host:addr>\n";
                }
            }
        }

        if ( $params->{rem}{statuses} ) {
            $rem .= $self->update_statuses_rem( 'host', $params->{rem}{statuses} );
        }
    }

    if ( $rem ) {
        $rem = "<host:rem>\n$rem    </host:rem>";
    }
    else {
        $rem = "<host:rem/>";
    }

    my $chg = '';

    if ( $params->{chg} ) {
        if ( $params->{chg}{new_name} ) {
            $chg .= "     <host:name>" . $$params{chg}{new_name} . "</host:name>\n";
        }
    }

    if ( $chg ) {
        $chg = "<host:chg>\n$chg    </host:chg>\n";
    }
    elsif ( !$params->{no_empty_chg} ) {
        $chg = "<host:chg/>";
    }

    my $ext = $$params{extension} || '';

    $ext = "\n  <extension>\n$ext  </extension>" if $ext;

    my $cltrid = get_cltrid();

    my $body = <<UPDATENS;
$$self{urn}{head}
 <command>
  <update>
   <host:update $$self{urn}{host}>
    <host:name>$$params{ns}</host:name>
    $add
    $rem
    $chg
   </host:update>
  </update>$ext
  <clTRID>$cltrid</clTRID>
 </command>
</epp>
UPDATENS

    return $self->simple_request( $body, 'update_ns' );
}


=head2 delete_ns

Remove nameserver from the registry.

OUTPUT:
see L</simple_request>.

=cut

sub delete_ns {
    my ( $self, $params ) = @_;

    return ( 0, 0, 'no ns' ) unless $$params{ns};

    my $ext = $$params{extension} || '';

    $ext = "\n  <extension>\n$ext  </extension>" if $ext;

    my $cltrid = get_cltrid();

    my $body = <<DELNS;
$$self{urn}{head}
 <command>
  <delete>
   <host:delete $$self{urn}{host}>
    <host:name>$$params{ns}</host:name>
   </host:delete>
  </delete>$ext
  <clTRID>$cltrid</clTRID>
 </command>
</epp>
DELNS

    return $self->simple_request( $body, 'delete_ns' );
}

# TODO: move
sub check_domains_rdata {
    my ( undef, $rdata ) = @_;

    my %domlist;

    my @aa = $rdata =~ /<domain:cd>\s*(<domain:name avail=['"]\d['"]>[^<>]+<\/domain:name>(?:\s*<domain:reason>[^<>]+<\/domain:reason>)?)\s*<\/domain:cd>/sg;

    foreach my $a ( @aa ) {
        if ( $a =~ /<domain:name avail=['"](\d)['"]>([^<>]+)<\/domain:name>/ ) {
            my $dm = lc($2);

            $domlist{$dm} = { avail => $1 }; # no utf8, puny only

            if ( $a =~ /<domain:reason>([^<>]+)<\/domain:reason>/ ) {
                $domlist{$dm}{reason} = $1;
            }
        }
    }

    if ( $rdata =~ /<launch:phase>claims<\/launch:phase>/ ) {
        # this is a call with an extension to get the key, if there is one
        if ( $rdata =~ /<launch:name exists=['"](\d)['"]>([0-9a-z.\-]+)<\/launch:name>\n?\s*<launch:claimKey>([^<>]+)<\/launch:claimKey>/ ) {
            $domlist{ lc($2) }{claim} = { avail => $1, claimkey => $3 };
        }
    }

    if ( $rdata =~ /<fee:chkData[^<>]+>(.+)<\/fee:chkData>/ ) {
        # this is a call with the extension draft-brown-epp-fees-02
        my $fee = $1;

        my @ff = $fee =~ /<fee:cd>(.+)<\/fee:cd>/g;

        foreach my $f ( @ff ) {
            $f =~ /<fee:name>([0-9a-z\-\.])<\/fee:name>.*<fee:fee>([0-9\.])<\/fee:fee>/;
            $domlist{ lc($1) }{fee} = { new => $2 }
        }
    }

    return \%domlist;
}

=head2 check_domains

Check that the domain is available for registration

=cut

sub check_domains {
    my ( $self, $params ) = @_;

    return ( 0, 0, 'no domains' ) unless $params->{domains} && scalar( @{$params->{domains}} );

    my $dms = '';

    foreach my $dm ( @{$params->{domains}} ) {
        $dms .= "<domain:name>$dm</domain:name>";
    }

    my $ext = $$params{extension} || '';

    $ext = "\n  <extension>\n$ext  </extension>" if $ext;

    my $cltrid = get_cltrid();

    my $body = <<CHECKDOMS;
$$self{urn}{head}
 <command>
  <check>
   <domain:check $$self{urn}{dom}>
    $dms
   </domain:check>
  </check>$ext
  <clTRID>$cltrid</clTRID>
 </command>
</epp>
CHECKDOMS

    my $answ = $self->req( $body, 'check_domains' ) // '';

    my $rcode = '';
    my $msg = '';

    if ( $answ =~ /<result code=['"](\d+)['"]/ ) {
        $rcode = $1 + 0;
    }

    if ( $answ =~ /<msg[^<>]*>([^<>]+)<\/msg>/ ) {
        $msg = $1;
    }

    if ( $answ =~ /<resData>(.+)<\/resData>/s ) {
        my $rdata = $1 // '';

        my $domlist = $self->check_domains_rdata( $rdata );

        return wantarray ? ( $domlist, $rcode, $msg ) : $domlist;
    }

    return wantarray ? ( 0, $rcode, $msg ) : 0;
}


sub create_domain_nss {
    my ( $self, $params ) = @_;

    my $nss = '';

    foreach my $ns ( @{$params->{nss}} ) {
        $nss .= "     <domain:hostObj>$ns</domain:hostObj>\n";
    }

    $nss = "\n    <domain:ns>\n$nss    </domain:ns>" if $nss;

    return $nss;
}


sub create_domain_authinfo {
    my ( $self, $params ) = @_;

    # Some providers require an empty authinfo, but no <domain:pw/>
    if ( exists $params->{authinfo} ) {
        return "\n    <domain:authInfo>\n     <domain:pw>$$params{authinfo}</domain:pw>\n    </domain:authInfo>";
    }

    return "\n    <domain:authInfo>\n     <domain:pw/>\n    </domain:authInfo>";
}

# DNSSEC extension

sub create_domain_ext {
    my ( $self, $params ) = @_;

    my $ext = '';

    if ( $params->{dnssec} ) {
        my $dsdata = '';
        foreach my $raw ( @{$params->{dnssec}} ) {
            my $ds = '';
            $ds .= "     <secDNS:keyTag>$$raw{keytag}</secDNS:keyTag>\n"          if $raw->{keytag};
            $ds .= "     <secDNS:alg>$$raw{alg}</secDNS:alg>\n"                   if $raw->{alg};
            $ds .= "     <secDNS:digestType>$$raw{digtype}</secDNS:digestType>\n" if $raw->{digtype};
            $ds .= "     <secDNS:digest>$$raw{digest}</secDNS:digest>\n"          if $raw->{digest};

            $dsdata .= "     <secDNS:dsData>\n$ds     </secDNS:dsData>\n" if $ds;
        }

        $ext = qq|   <secDNS:create xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd" >\n$dsdata    </secDNS:create>\n|
            if $dsdata;
    }

    return $ext;
}


=head2 create_domain

Domain registration.

OUTPUT:
see L</simple_request>.

=cut

sub create_domain {
    my ( $self, $params ) = @_;

    return ( 0, 0, 'no dname' ) unless $params->{dname};

    my $nss = '';
    if ( $params->{nss}  &&  scalar @{$params->{nss}} ) {
        $nss = $self->create_domain_nss( $params );
    }

    my $cont = '';
    # 1. There is a zone without an owner, but with admin :)
    # 2. Verisign Core server -- without all contacts
    $cont .= qq|\n    <domain:registrant>$$params{reg_id}</domain:registrant>| if $$params{reg_id};

    foreach my $t ( 'tech', 'admin', 'billing' ) {
        if ( $$params{$t.'_id'} ) {
            $$params{$t.'_id'} = [ $$params{$t.'_id'} ] unless ref $$params{$t.'_id'};

            foreach my $c ( @{$$params{$t.'_id'}} ) {
                $cont .= qq|\n    <domain:contact type="$t">$c</domain:contact>|;
            }
        }
    }

    my $descr = ''; # tcinet registry
    if ( $params->{descr} ) {
        $params->{descr} = [ $params->{descr} ] unless ref $params->{descr};

        $descr .= "\n    <domain:description>$_</domain:description>" for @{$params->{descr}};
    }

    my $authinfo = $self->create_domain_authinfo( $params );

    my $ext = $params->{extension} || '';

    $ext .= $self->create_domain_ext( $params );

    $ext = "\n  <extension>\n$ext  </extension>" if $ext;

    my $cltrid = get_cltrid();

    my $body = <<CREATEDOM;
$$self{urn}{head}
 <command>
  <create>
   <domain:create $$self{urn}{dom}>
    <domain:name>$$params{dname}</domain:name>
    <domain:period unit="y">$$params{period}</domain:period>$nss$cont$authinfo$descr
   </domain:create>
  </create>$ext
  <clTRID>$cltrid</clTRID>
 </command>
</epp>
CREATEDOM

    return $self->simple_request( $body, 'create_domain' );
}

# For replace in children class
sub get_domain_spec_rdata {
    return {};
}


sub get_domain_info_rdata {
    my ( $self, $rdata ) = @_;

    my $info = {};

    ( $info->{dname} ) = $rdata =~ /<domain:name>([^<>]+)<\/domain:name>/;
    $info->{dname} = lc $info->{dname};

    # <domain:status s="ok"/>
    my @ss = $rdata =~ /<domain:status s=['"]([^'"]+)['"]\s*\/?>/g;
    # <domain:status s="clientTransferProhibited">No reason supplied</domain:status>
    my @aa = $rdata =~ /<domain:status[^<>]+>[^<>]+<\/domain:status>/g;
    if ( scalar @aa ) {
        foreach my $row ( @aa ) {
            if ( $row =~ /<domain:status s=['"]([^'"]+)['"]\s*>([^<>]+)<\/domain:status>/ ) {
                $info->{statuses}{$1} = $2;
            }
        }
    }
    else {
        $info->{statuses}{$_} = '+' for @ss;
    }

    if ( $rdata =~ /<domain:registrant>([^<>]+)<\/domain:registrant>/             ) {
        # One of the .ua zones uses admin instead of owner
        $info->{reg_id}     = $1;
    }

    my @cc = $rdata =~ /<domain:contact type=['"][^'"]+['"]>[^<>]+<\/domain:contact>/g;
    foreach my $row ( @cc ) {
        if ( $row =~ /<domain:contact type=['"]([^'"]+)['"]>([^<>]+)<\/domain:contact>/ ) {
            $info->{ lc($1) . '_id' } = $2;
        }
    }

    if ( $rdata =~ /<domain:description>/ ) {
        $info->{descr} = [ $rdata =~ /<domain:description>([^<>]+)<\/domain:description>/g ];
    }

    if ( $rdata =~ /<domain:hostObj>/ ) {
        $info->{nss} = [ $rdata =~ /<domain:hostObj>([^<>]+)<\/domain:hostObj>/g ];
    }

    unless ( $info->{nss}  or  $rdata !~ /<domain:hostName>/ ) {
        # some providers use the old variant for some zones, example: irrp for ph
        # this is a rare option, so it is made separately and not built into the previous regexp
        $info->{nss} = [ $rdata =~ /<domain:hostName>([^<>]+)<\/domain:hostName>/g ];
    }

    unless ( $info->{nss}  or  $rdata !~ /<domain:ns>/  or  scalar @{$info->{nss}} ) {
        # ещё 1 древний вариант, наверное самый старый
        $info->{nss} = [ $rdata =~ /<domain:ns>([^<>]+)<\/domain:ns>/g ];
    }

    if ( $info->{nss} ) {
        $info->{nss} = [ map{ lc $_ } @{$info->{nss}} ];
    }

    # Domain-based nss
    if ( $rdata =~ /<domain:host>/ ) {
        $info->{hosts} = [ $rdata =~ /<domain:host>([^<>]+)<\/domain:host>/g ];
        $info->{hosts} = [ map{ lc $_ } @{$info->{hosts}} ];
    }

    # owner, ...
    foreach my $k ( keys %id ) {
        if ( $rdata =~ /<domain:$k>([^<>]+)<\/domain:$k>/ ) {
            $info->{$id{$k}} = $1;
        }
    }

    # dates
    foreach my $k ( keys %dt ) {
        if ( $rdata =~ /<domain:$k>([^<>]+)<\/domain:$k>/ ) {
            $info->{$dt{$k}} = cldate( $1 );
        }
    }

    if ( $rdata =~ /authInfo.+<domain:pw>([^<>]+)<\/domain:pw>.+authInfo/s ) {
        ( $info->{authinfo} ) = $1;

        $info->{authinfo} =~ s/&gt;/>/g;
        $info->{authinfo} =~ s/&lt;/</g;
        $info->{authinfo} =~ s/&amp;/&/g;
    }

    ( $info->{roid} ) = $rdata =~ /<domain:roid>([^<>]+)<\/domain:roid>/;

    my $spec = $self->get_domain_spec_rdata( $rdata );
    $info->{$_} = $spec->{$_} for keys %$spec;

    return $info;
}

# For replace in children
sub get_domain_spec_ext {
    return {};
}

=head2 get_domain_info

The main information on the domain

=cut

sub get_domain_info {
    my ( $self, $params ) = @_;

    unless ( $$params{dname} ) {
        return wantarray ? ( 0, 0, 'no dname') : 0;
    }

    my $pw = $$params{authinfo} ? "\n    <domain:authInfo>\n     <domain:pw>$$params{authinfo}</domain:pw>\n    </domain:authInfo>" : '';

    my $hosts_type = $$params{hosts} ? ' hosts="'.$$params{hosts}.'"' : '';

    my $ext = $$params{extension} || '';

    $ext = "\n  <extension>\n$ext  </extension>" if $ext;

    my $cltrid = get_cltrid();

    my $body = <<DOMINFO;
$$self{urn}{head}
 <command>
  <info>
   <domain:info $$self{urn}{dom}>
    <domain:name$hosts_type>$$params{dname}</domain:name>$pw
   </domain:info>
  </info>$ext
  <clTRID>$cltrid</clTRID>
 </command>
</epp>
DOMINFO

    my $answ = $self->req( $body, 'domain_info' );

    if ( $answ  &&  $answ =~ /<result code=['"](\d+)['"]>/ ) {
        my $rcode = $1 + 0;

        my $msg = '';
        if ( $answ =~ /<result.+<msg[^<>]*>(.+)<\/msg>.+\/result>/s ) {
            $msg = $1;
        }

        if ( $rcode != 1000 ) {
            if ( $answ =~ /<reason>(.+)<\/reason>/s ) {
                # for details
                $msg .= '; ' . $1;
            }

            if ( $answ =~ /<oxrs:xcp>(.+)<\/oxrs:xcp>/s ) {
                # for oxrs details
                $msg .= '; ' . $1;
            }

            return wantarray ? ( 0, $rcode, $msg ) : 0;
        }

        my $info = {};

        # pull out the main part and parse
        if ( $answ =~ /<resData>(.+)<\/resData>/s ) {
            my $rdata = $1 // '';

            $info = $self->get_domain_info_rdata( $rdata );
        }

        if ( $answ =~ /<extension>(.+)<\/extension>/s ) {
            my $rdata = $1;

            my @st = $rdata =~ /<rgp:rgpStatus s=['"]([^'"]+)['"]\s*\/>/g;
            $info->{statuses}{$_} = '+' for @st;

            my @est = $rdata =~ /(<rgp:rgpStatus s=['"][^'"]+['"]>[^<>]+<\/rgp:rgpStatus>)/g;

            foreach my $e ( @est ) {
                my ( $st, $descr ) = $e =~ /<rgp:rgpStatus s=['"]([^'"]+)['"]>([^<>]+)<\/rgp:rgpStatus>/;

                if ( $descr =~ /^endDate=/ ) {
                    $descr =~ s/T/ /;
                    $descr =~ s/\.\d+Z$//;
                    $descr =~ s/Z$//;
                }
                $info->{statuses}{$st} = $descr;
            }

            if ( $rdata =~ /secDNS:infData/ ) {
                $info->{dnssec} = [];

                my @dsdata = $rdata =~ /<secDNS:dsData>(.+?)<\/secDNS:dsData>/g;
                foreach my $sdata ( @dsdata ) {
                    my %one_raw;
                    ( $one_raw{keytag}  ) = $sdata =~ /<secDNS:keyTag>(\d+)<\/secDNS:keyTag>/;
                    ( $one_raw{alg}     ) = $sdata =~ /<secDNS:alg>(\d+)<\/secDNS:alg>/;
                    ( $one_raw{digtype} ) = $sdata =~ /<secDNS:digestType>(\d+)<\/secDNS:digestType>/;
                    ( $one_raw{digest}  ) = $sdata =~ /<secDNS:digest>([A-Za-z0-9]+)<\/secDNS:digest>/;

                    if ( $sdata =~ /<secDNS:keyData>(.+)<\/secDNS:keyData>/s ) {
                        my $kdata = $1;

                        $one_raw{keydata} = {};
                        ( $one_raw{keydata}{flags}    ) = $kdata =~ /<secDNS:flags>(\d+)<\/secDNS:flags>/;
                        ( $one_raw{keydata}{protocol} ) = $kdata =~ /<secDNS:protocol>(\d+)<\/secDNS:protocol>/;
                        ( $one_raw{keydata}{alg}      ) = $kdata =~ /<secDNS:alg>(\d+)<\/secDNS:alg>/;
                        ( $one_raw{keydata}{pubkey}   ) = $kdata =~ /<secDNS:pubKey>([^<>]+)<\/secDNS:pubKey>/;
                    }

                    push @{$$info{dnssec}}, \%one_raw;
                }
            }

            my $spec = $self->get_domain_spec_ext( $rdata );
            $info->{$_} = $spec->{$_} for keys %$spec;
        }

        return wantarray ? ( $info, $rcode, $msg ) : $info;
    }

    return wantarray ? ( 0, 0, 'empty answer' ) : 0;
}


=head2 renew_domain

Domain registration renewal for N years.

OUTPUT:
see L</simple_request>.

=cut

sub renew_domain {
    my ( $self, $params ) = @_;

    return ( 0, 0, 'no params' ) unless $$params{dname} && $$params{period} && $$params{exp_date};

    my $ext = $params->{extension} || '';

    $ext = "\n  <extension>\n$ext  </extension>" if $ext;

    my $cltrid = get_cltrid();

    my $body = <<RENEWDOM;
$$self{urn}{head}
 <command>
  <renew>
   <domain:renew $$self{urn}{dom}>
    <domain:name>$$params{dname}</domain:name>
    <domain:curExpDate>$$params{exp_date}</domain:curExpDate>
    <domain:period unit="y">$$params{period}</domain:period>
   </domain:renew>
  </renew>$ext
  <clTRID>$cltrid</clTRID>
 </command>
</epp>
RENEWDOM

    return $self->simple_request( $body, 'renew_domain' );
}

# replaced in DrsUa
sub update_domain_add_nss {
    my ( undef, $params ) = @_;

    my $add = "     <domain:ns>\n";

    foreach my $ns ( @{$$params{add}{nss}} ) {
        $add .= "      <domain:hostObj>$ns</domain:hostObj>\n";
    }

    $add .= "     </domain:ns>\n";

    return $add;
}


sub update_domain_rem_nss {
    my ( undef, $params ) = @_;

    my $rem = "     <domain:ns>\n";

    foreach my $ns ( @{$$params{rem}{nss}} ) {
        $rem .= "      <domain:hostObj>$ns</domain:hostObj>\n";
    }

    $rem .= "     </domain:ns>\n";

    return $rem;
}


sub update_domain_ext {
    my ( undef, $params ) = @_;

    my $ext = '';

    my $rem_ds = '';
    if ( $params->{rem}  &&  $params->{rem}{dnssec} ) {
        foreach my $raw ( @{$params->{rem}{dnssec}} ) {
            my $ds = '';
            $ds .= "      <secDNS:keyTag>$$raw{keytag}</secDNS:keyTag>\n"          if $raw->{keytag};
            $ds .= "      <secDNS:alg>$$raw{alg}</secDNS:alg>\n"                   if $raw->{alg};
            $ds .= "      <secDNS:digestType>$$raw{digtype}</secDNS:digestType>\n" if $raw->{digtype};
            $ds .= "      <secDNS:digest>$$raw{digest}</secDNS:digest>\n"          if $raw->{digest};

            $rem_ds .= "     <secDNS:dsData>\n$ds     </secDNS:dsData>\n" if $ds;
        }

        $rem_ds = "    <secDNS:rem>\n$rem_ds    </secDNS:rem>\n" if $rem_ds;
    }

    my $add_ds = '';
    if ( $params->{add}  &&  $params->{add}{dnssec} ) {
        foreach my $raw ( @{$params->{add}{dnssec}} ) {
            my $ds = '';
            $ds .= "      <secDNS:keyTag>$$raw{keytag}</secDNS:keyTag>\n"          if $raw->{keytag};
            $ds .= "      <secDNS:alg>$$raw{alg}</secDNS:alg>\n"                   if $raw->{alg};
            $ds .= "      <secDNS:digestType>$$raw{digtype}</secDNS:digestType>\n" if $raw->{digtype};
            $ds .= "      <secDNS:digest>$$raw{digest}</secDNS:digest>\n"          if $raw->{digest};

            $add_ds .= "     <secDNS:dsData>\n$ds     </secDNS:dsData>\n" if $ds;
        }

        $add_ds = "    <secDNS:add>\n$add_ds    </secDNS:add>\n" if $add_ds;
    }

    if ( $rem_ds || $add_ds ) {
        $ext .= qq|
   <secDNS:update xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:secDNS-1.1 secDNS-1.1.xsd" >\n|;
        $ext .= $rem_ds;
        $ext .= $add_ds;
        $ext .= "   </secDNS:update>\n";
    }

    return $ext;
}

=head2 update_domain

To update domain data: contact ids, nss, hosts, statuses.

OUTPUT:
see L</simple_request>.

=cut

sub update_domain {
    my ( $self, $params ) = @_;

    return ( 0, 0, 'no params' ) unless ref $params;

    return ( 0, 0, 'no dname' ) unless $params->{dname};

    my $nm = 'update_domain';

    my $add = '';
    if ( ref $$params{add} ) {
        if ( $$params{add}{nss}  &&  ref $$params{add}{nss}  &&  scalar( @{$$params{add}{nss}} ) ) {
            $add .= $self->update_domain_add_nss( $params );

            $nm .= '_add_ns';
        }

        foreach my $t ( 'admin', 'billing', 'tech' ) {
            if ( $$params{add}{$t.'_id'} ) {
                $$params{add}{$t.'_id'} = [ $$params{add}{$t.'_id'} ] unless ref $$params{add}{$t.'_id'};

                foreach my $c ( @{$$params{add}{$t.'_id'}} ) {
                    $add .= qq|     <domain:contact type="$t">$c</domain:contact>\n|;
                }
            }
        }

        if ( $params->{add}{statuses} ) {
            $add .= $self->update_statuses_add( 'domain', $params->{add}{statuses} );

            $nm .= '_add_status';
        }
    }

    if ( $add ) {
        $add = "<domain:add>\n$add    </domain:add>";
    }
    else {
        $add = '<domain:add/>';
    }

    my $chg = '';
    if ( ref $$params{chg} ) {
        if ( $$params{chg}{reg_id} ) {
            $chg .= '     <domain:registrant>' . $$params{chg}{reg_id} . "</domain:registrant>\n";

            $nm .= '_chg_cont';
        }

        if ( $$params{chg}{authinfo} ) {
            $chg .= "     <domain:authInfo>\n      <domain:pw>".$$params{chg}{authinfo}."</domain:pw>\n     </domain:authInfo>\n";

            $nm .= '_chg_key';
        }

        if ( $params->{chg}{descr} ) {
            $params->{chg}{descr} = [ $params->{chg}{descr} ] unless ref $params->{chg}{descr};

            $chg .= "     <domain:description>$_</domain:description>\n" foreach @{$params->{chg}{descr}};

            $nm .= '_chg_descr';
        }
    }

    if ( $chg ) {
        $chg = "<domain:chg>\n$chg    </domain:chg>";
    }
    else {
        $chg = '<domain:chg/>';
    }

    my $rem = '';
    if ( $$params{rem} ) {
        if ( $$params{rem}{nss}  &&  ref $$params{rem}{nss}  &&  scalar( @{$$params{rem}{nss}} ) ) {
            $rem .= $self->update_domain_rem_nss( $params );

            $nm .= '_del_ns';
        }

        foreach my $t ( 'admin', 'billing', 'tech' ) {
            if ( $$params{rem}{$t.'_id'} ) {
                $$params{rem}{$t.'_id'} = [ $$params{rem}{$t.'_id'} ] unless ref $$params{rem}{$t.'_id'};

                foreach my $c ( @{$$params{rem}{$t.'_id'}} ) {
                    $rem .= qq|     <domain:contact type="$t">$c</domain:contact>\n|;
                }
            }
        }

        if ( $$params{rem}{statuses} ) {
            $rem .= $self->update_statuses_rem( 'domain', $$params{rem}{statuses} );

            $nm .= '_del_status';
        }
    }

    if ( $rem ) {
        $rem = "<domain:rem>\n$rem    </domain:rem>";
    }
    else {
        $rem = '<domain:rem/>';
    }

    my $ext = $$params{extension} || '';

    $ext .= $self->update_domain_ext( $params );

    $ext = "\n  <extension>\n$ext  </extension>" if $ext;

    my $cltrid = get_cltrid();

    my $body = <<UPDDOM;
$$self{urn}{head}
 <command>
  <update>
   <domain:update $$self{urn}{dom}>
    <domain:name>$$params{dname}</domain:name>
    $add
    $rem
    $chg
   </domain:update>
  </update>$ext
  <clTRID>$cltrid</clTRID>
 </command>
</epp>
UPDDOM

    return $self->simple_request( $body, $nm );
}


=head2 transfer

Domain transfers: to us, from us, reject transfers.

=cut

sub transfer {
    my ( $self, $params ) = @_;

    return ( 0, 0, 'no dname' ) unless $params->{dname};

    return ( 0, 0, 'no op[eration]' ) unless $params->{op} && $params->{op} =~ /query|request|cancel|approve|reject|usertransfer/;

    my $pw = '';
    if ( defined $params->{authinfo} ) {
        # 0 & undef are differents
        $pw = "\n    <domain:authInfo>\n     <domain:pw>$$params{authinfo}</domain:pw>\n    </domain:authInfo>";
    }

    my $per = '';
    if ( defined $params->{period} ) {
        # 0 & undef is different
        $per = qq|\n    <domain:period unit="y">$$params{period}</domain:period>|;
    }

    # special parameters for very original registries
    my $spec = $$params{addition} // '';

    my $ext = $$params{extension} || '';

    $ext = "\n  <extension>\n$ext  </extension>" if $ext;

    my $cltrid = get_cltrid();

    my $body = <<TRANS;
$$self{urn}{head}
 <command>
  <transfer op="$$params{op}">
   <domain:transfer $$self{urn}{dom}>
    <domain:name>$$params{dname}</domain:name>$per$pw$spec
   </domain:transfer>
  </transfer>$ext
  <clTRID>$cltrid</clTRID>
 </command>
</epp>
TRANS

    my $answ = $self->req( $body, $$params{op}.'_transfer' );

    if ( $answ =~ /<result code=['"](\d+)['"]>/ ) {
        my $rcode = $1 + 0;

        my $msg = '';
        if ( $answ =~ /<result.+<msg[^<>]*>(.+)<\/msg>.+\/result>/s ) {
            $msg = $1;

            if ( $answ =~ /<result.+<text[^<>]*>(.+)<\/text>.+\/result>/s ) {
                $msg .= '; ' . $1;
            }

            if ( $answ =~ /<reason>([^<>]+)<\/reason>/ ) {
                $msg .= '; ' . $1;
            }
        }

        my $info = {}; # for data

        # pull out the main part and parse
        if ( $answ =~ /<resData>(.+)<\/resData>/s ) {
            my $rdata = $1;

            ( $info->{dname} ) = $rdata =~ /<domain:name>([^<>]+)<\/domain:name>/;

            ( $info->{trstatus} ) = $rdata =~ /<domain:trStatus>([^<>]+)<\/domain:trStatus>/;

            # owner, ...
            foreach my $k ( keys %id ) {
                if ( $rdata =~ /<domain:$k>([^<>]+)<\/domain:$k>/ ) {
                    $info->{$id{$k}} = $1;
                }
            }

            # dates
            foreach my $k ( keys %dt ) {
                if ( $rdata =~ /<domain:$k>([^<>]+)<\/domain:$k>/ ) {
                    $info->{$dt{$k}} = $1;

                    $info->{$dt{$k}} =~ s/T/ /;
                    $info->{$dt{$k}} =~ s/\.\d+Z$//;
                    $info->{$dt{$k}} =~ s/Z$//;
                }
            }
        }

        ( $info->{cltrid} ) = $answ =~ /<clTRID>([0-9A-Za-z\-]+)<\/clTRID>/;
        ( $info->{svtrid} ) = $answ =~ /<svTRID>([0-9A-Za-z\-]+)<\/svTRID>/;

        return wantarray ? ( $info, $rcode, $msg ) : $info;
    }

    return wantarray ? ( 0, 0, 'empty answer' ) : 0;
}


=head2 delete_domain

Deleting a domain.

OUTPUT:
see L</simple_request>.

=cut

sub delete_domain {
    my ( $self, $params ) = @_;

    return ( 0, 0, 'no dname' ) unless $params->{dname};

    my $ext = $$params{extension} || '';

    $ext = "\n  <extension>\n$ext  </extension>" if $ext;

    my $cltrid = get_cltrid();

    my $body = <<DELDOM;
$$self{urn}{head}
 <command>
  <delete>
   <domain:delete $$self{urn}{dom}>
    <domain:name>$$params{dname}</domain:name>
   </domain:delete>
  </delete>$ext
  <clTRID>$cltrid</clTRID>
 </command>
</epp>
DELDOM

    return $self->simple_request( $body, 'delete_domain' );
}


# Parse resData from req poll

sub req_poll_rdata {
    my ( $self, $rdata ) = @_;

    my %info;

    if ( $rdata =~ /^\s*<contact:panData/ ) {
        $info{upd_del} = {};
        ( $info{upd_del}{result}, $info{upd_del}{contact} ) =
            $rdata =~ /<contact:id paResult=['"]([^'"]+)['"]>([^<>]+)<\/contact:id>/;
    }

    elsif ( $rdata =~ /\s*<host:infData/ ) {
        ( $info{ns} ) = $rdata =~ m|<host:name>([^<>]+)</host:name>|s;
        $info{ns} = lc $info{ns};

        ( $info{roid} ) = $rdata =~ m|<host:roid>([^<>]+)</host:roid>|s;

        my @sts = $rdata =~ m|(<host:status s="[^"]+"/>)|gs;
        for my $row ( @sts ) {
            if ( $row =~ /host:status s="([^"]+)"/ ) {
                $info{statuses}{$1} = '+';
            }
        }

        my @ips = $rdata =~ m|(<host:addr ip="v\d">[^<>]+</host:addr>)|gs;
        $info{ips} = [];
        for my $row ( @ips ) {
            if ( $row =~ m|host:addr ip="v\d">([^<>]+)</host:addr| ) {
                push @{$info{ips}}, $1;
            }
        }
        # owner, ...
        foreach my $k ( keys %id ) {
            if ( $rdata =~ /<host:$k>([^<>]+)<\/host:$k>/ ) {
                $info{$id{$k}} = $1;
            }
        }
        # dates
        foreach my $k ( keys %dt ) {
            if ( $rdata =~ m|<host:$k>([^<>]+)</host:$k>| ) {
                $info{$dt{$k}} = cldate( $1 );
            }
        }
    }

    elsif ( $rdata =~ /^\s*<domain:creData/ ) {
        $info{create} = {};
        ( $info{create}{dname} ) = $rdata =~ /<domain:name>([^<>]+)<\/domain:name>/;

        if ( $rdata =~ /<domain:crDate>([^<>]+)<\/domain:crDate>/ ) {
            $info{create}{date} = IO::EPP::Base::cldate( $1 );
        }
    }

    elsif ( $rdata =~ /^\s*<domain:renData/ ) {
        $info{renew} = {};
        ( $info{renew}{dname}  ) = $rdata =~ /<domain:name>([^<>]+)<\/domain:name>/;
    }

    elsif ( $rdata =~ /^\s*<domain:trnData/ ) {
        $info{transfer} = {};
        ( $info{transfer}{dname}  ) = $rdata =~ /<domain:name>([^<>]+)<\/domain:name>/;
        ( $info{transfer}{status} ) = $rdata =~ /<domain:trStatus>([^<>]+)<\/domain:trStatus>/;

        # sender, requestor
        foreach my $k ( keys %id ) {
            if ( $rdata =~ /<domain:$k>([^<>]+)<\/domain:$k>/ ) {
                $info{transfer}{$id{$k}} = $1;
            }
        }
        # dates
        foreach my $k ( keys %dt ) {
            if ( $rdata =~ /<domain:$k>([^<>]+)<\/domain:$k>/ ) {
                $info{transfer}{$dt{$k}} = IO::EPP::Base::cldate( $1 );
            }
        }
    }

    elsif ( $rdata =~ /^\s*<domain:panData/ ) {
        $info{upd_del} = {};
        ( $info{upd_del}{result}, $info{upd_del}{dname} ) =
            $rdata =~ /<domain:name paResult=['"]([^'"]+)['"]>([^<>]+)<\/domain:name>/;

        if ( $rdata =~ /<domain:paTRID>(.+?)<\/domain:paTRID>/s ) {
            my $trids = $1;
            if ( $trids =~ /<clTRID>([0-9A-Za-z]+)<\/clTRID>/ ) {
                $info{upd_del}{cltrid} = $1;
            }
            if ( $trids =~ /<svTRID>([0-9A-Za-z\-]+)<\/svTRID>/ ) {
                $info{upd_del}{svtrid} = $1;
            }
        }

        if ( $rdata =~ /<domain:paDate>([^<>]+)<\/domain:paDate>/ ) {
            $info{upd_del}{date} = IO::EPP::Base::cldate( $1 );
        }
    }

    else {
        return ( 0, 'New poll message type!' );
    }

    return ( \%info, '' );

}


# Parse req poll extension

# Empty, for replace in children modules

sub req_poll_ext {
    return {};
}

=head2 req_poll

Get and parse message from poll

=cut

sub req_poll {
    my ( $self, undef ) = @_;

    my $cltrid = get_cltrid();

    my $body = <<RPOLL;
$$self{urn}{head}
 <command>
  <poll op="req"/>
  <clTRID>$cltrid</clTRID>
 </command>
</epp>
RPOLL

    my $answ = $self->req( $body, 'req_poll' );

    if ( $answ  and  $answ =~ /<result code=['"](\d+)['"]>/ ) {
        my $rcode = $1 + 0;

        my $msg = '';
        if ( $answ =~ /<result.+<msg[^<>]*>(.+?)<\/msg>.+\/result>/s ) {
            $msg = $1;
        }

        my %info;

        if ( $rcode == 1301 ) {
            if ( $answ =~ /<msgQ ([A-Za-z]+)=['"](\d+)['"] ([A-Za-z]+)=['"]([^'"]+)['"]>(.*)<\/msgQ>/s ) {
                $info{$1} = $2;
                $info{$3} = $4;
                my $q     = $5;

                if ( $q  and  $q =~ /<qDate>(.+)<\/qDate>.*<msg( lang=['"][^'"]+['"])?>(.+?)<\/msg>/s ) {
                    $info{date} = IO::EPP::Base::cldate( $1 );
                    $info{qmsg} =  $3;
                    $info{qmsg} =~ s/&quot;/"/g;
                    if ( $info{qmsg} =~ /\[CDATA\[/ ) {
                        $info{qmsg} =~ s/<!\[CDATA\[//;
                        $info{qmsg} =~ s/\]\]>//;
                    }
                }
                # wihout special message
                elsif ( $q  and  $q =~ /<qDate>(.+)<\/qDate>/s ) {
                    $info{date} = IO::EPP::Base::cldate( $1 );
                    $info{qmsg} = $q; #
                }
                elsif ( $q ) {
                    # not standard
                    $info{qmsg} = $q;
                }
            }

            if ( $answ =~ /<resData>(.+?)<\/resData>/s ) {
                my ( $rdata, $err ) = $self->req_poll_rdata( $1 );

                if ( !$rdata  and  $err ) {
                    return wantarray ? ( 0, 0, $err ) : 0 ;
                }

                $info{$_} = $rdata->{$_} for keys %$rdata;
            }

            if ( $answ =~ /<extension>(.+?<\/extension>)/s ) {
                $info{ext} = $self->req_poll_ext( $1 );
            }

            ( $info{cltrid} ) = $answ =~ /<clTRID>([0-9A-Za-z\-]+)<\/clTRID>/;
            ( $info{svtrid} ) = $answ =~ /<svTRID>([0-9A-Za-z\-]+)<\/svTRID>/;
        }

        return wantarray ? ( \%info, $rcode, $msg ) : \%info;
    }

    return wantarray ? ( 0, 0, 'empty answer' ) : 0 ;
}

=head2 ask_poll

Delete message from poll

=cut

sub ask_poll {
    my ( $self, $params ) = @_;

    return ( 0, 0, 'no msg_id' ) unless $params->{msg_id};

    my $cltrid = get_cltrid();

    my $body = <<APOLL;
$$self{urn}{head}
 <command>
  <poll op="ack" msgID="$$params{msg_id}"/>
  <clTRID>$cltrid</clTRID>
 </command>
</epp>
APOLL

    my $answ = $self->req( $body, 'ask_poll' );

    if ( $answ  &&  $answ =~ /<result code=['"](\d+)['"]>/ ) {
        my $rcode = $1 + 0;

        my ( $msg ) = $answ =~ /<result.+<msg[^<>]*>(.+)<\/msg>.+\/result>/s;

        my %info;

        if ( $answ =~ /<msgQ count=['"](\d+)['"] id=['"](\d+)['"]\/>/ ) {
            $info{msg_cnt} = $1;
            $info{msg_id}  = $2;
        }

        return wantarray ? ( \%info, $rcode, $msg ) : \%info;
    }

    # Неконнект или ошибка запроса
    # По хорошему надо отделять неконнект от ошибки
    return wantarray ? ( 0, 0, 'empty answer' ) : 0 ;
}


=head2 logout

Close session, disconnect

No parameters.

=cut

sub logout {
    my ( $self ) = @_;

    return unless $self->{sock};

    unless ( $self->{test}  ||  $self->{sock}->opened() ) {
        delete $self->{sock};

        return;
    }

    my $cltrid = get_cltrid();

    my $logout = <<LOGOUT;
$$self{urn}{head}
 <command>
  <logout/>
  <clTRID>$cltrid</clTRID>
 </command>
</epp>
LOGOUT

    $self->req( $logout, 'logout' );

    unless ( $self->{test} ) {
        close( $self->{sock} );
    }

    delete $self->{sock};

    return ( undef, '1500', 'ok' );
}


sub DESTROY {
    my ( $self ) = @_;

    local ($!, $@, $^E, $?); # Protection against action-at-distance

    if ( $self->{sock} ) {
        $self->logout();
    }

    if ( $self->{log_fh} ) {
        close $self->{log_fh};

        delete $self->{log_fh};
    }
}


1;

__END__

=pod

=head1 AUTHORS

Vadim Likhota <vadiml@cpan.org>, some edits were made by Andrey Voyshko, Victor Efimov

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
