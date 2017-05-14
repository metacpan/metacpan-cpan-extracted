package Net::Objwrap::Client;
use 5.012;
use strict;
use warnings;

use Carp;
use Socket;
use Data::Dumper;

sub new {
    my ($pkg, $file) = @_;

    # read server connection info
    my ($conn_info, $store);
    if ($file && open my $fh_ci, '<', $file) {
	$conn_info = Net::Objwrap::deserialize(scalar <$fh_ci>);
	$store = delete $conn_info->{store};
    } else {
	Carp::croak __PACKAGE__,
            ": could not read connection info from '$file'";
    }

    # make server connection
    my $iaddr = Socket::inet_aton($conn_info->{host});
    my $paddr = Socket::pack_sockaddr_in($conn_info->{port}, $iaddr);
    socket(my $socket, Socket::PF_INET(), Socket::SOCK_STREAM(),
	   getprotobyname("tcp")) || Carp::croak "socket: $!";
    connect($socket, $paddr) ||
	Carp::croak
            "connect to $conn_info->{host}:$conn_info->{port} failed";
    my $client = bless {
        connection_info => $conn_info,
        socket => $socket,
        proxies => {},
        objs => [],
    }, $pkg;

    my $fh_sel = select $socket;
    $| = 1;
    select $fh_sel;

    foreach my $odata (@$store) {
        my $proxyref = Net::Objwrap::Aux::getproxy($odata, $client);

        $client->{proxies}{$odata->{id}} = $proxyref;
        push @{$client->{objs}}, $proxyref;
    }
    return $client;
}

sub get_objs {
    my ($self) = @_;
    return @{$self->{objs}};
}

##################################################################
#
# Net::Objwrap::Aux package was defined in Net/Objwrap/Aux.pm,
# but aux is a reserved word for MSWin32 filesystems

package Net::Objwrap::Aux;
use Carp;
use Data::Dumper;

sub process_request {
    my ($proxy, $request) = @_;
    Carp::confess if ref($proxy) ne 'HASH' &&
        ref($proxy) ne 'Net::Objwrap::ProxyS';

    Net::Objwrap::xdiag("proxy: process_request $proxy $request ",ref($proxy));
    my $socket = $proxy->{socket};
    $request->{context} //= defined(wantarray) ? 1+wantarray : 0;
    $request->{id} //= $proxy->{id};

    if (0 && $request->{has_args}) {    # not sure this is necessary
        unwind_args($request);
    }
    
    my $jreq = Net::Objwrap::serialize($request);
    Net::Objwrap::xdiag("proxy: serialized request: $jreq");

    my $resp;
    if ($proxy->{_DESTROY}) {
        no warnings 'closed';
        print {$socket} $jreq, "\n";
        $resp = readline($socket);
    } else {
        print {$socket} $jreq, "\n";
        $resp = readline($socket);
    }
    $Net::Objwrap::Aux::LAST_RESPONSE = $resp;

    if (!defined $resp) {
	return "{context:0,response:\"\"}";
    }

    croak if ref($resp);

    $resp = deserialize_response($resp,$proxy->{client});
    
    if ($resp->{error}) {
	croak $resp->{error};
    }
    if ($resp->{disconnect_ok}) {
	# bless $proxy, '.';
	return;
    }
    if ($resp->{context} == 0) {
	return;
    }
    if ($resp->{context} == 1) {
	return $resp->{response};
    }
    if ($resp->{context} == 2) {
	if ($request->{context} == 2) {
	    return @{$resp->{response}};
	} else {
	    return $resp->{response}[0];
	}
    }
    croak "invalid response context";
}

# Converts object metadata into a  Proxy  or  ProxyS  object.
# Object metadata contains 'id','ref','reftype', and possibly 'overload' fields.
# Register the object with the given Client.
# called from Net::Objwrap::Client constructor, Net::Objwrap::Aux::vet_element
sub getproxy {
    my ($objdata,$client) = @_;

    croak unless $objdata->{id} && $objdata->{ref} && $objdata->{reftype};

    Net::Objwrap::xdiag("Building proxy object around $objdata->{id}, ",
                        Data::Dumper::Dumper($objdata));

    my $proxy = { %$objdata };
    if ($objdata->{overload}) {
        $proxy->{overloads} = { map {; $_ => 1 } @{$objdata->{overload}} };
    }
    $proxy->{client} = $client;
    $proxy->{socket} = $client->{socket};
    if ($proxy->{reftype} eq 'HASH') {
        tie my %h, 'Net::Objwrap::HASH', $proxy;
        $proxy->{hash} = \%h;
        return bless \$proxy, 'Net::Objwrap::Proxy';
    }
    if ($proxy->{reftype} eq 'ARRAY') {
        tie my @a, 'Net::Objwrap::ARRAY', $proxy;
        $proxy->{array} = \@a;
        return bless \$proxy, 'Net::Objwrap::Proxy';
    }
    if ($proxy->{reftype} eq 'SCALAR') {
        tie my $s, 'Net::Objwrap::SCALAR', $proxy;
        $proxy->{scalar} = \$s;
        return bless $proxy, 'Net::Objwrap::ProxyS';
    }
    croak "reftype of remote object must be HASH, ARRAY, or SCALAR";
}


# Expand any  Proxy/ProxyS  references in argument list to
# complete specifications.
#
# Could be called from  process_request  , but I'm not sure that this
# function is necessary.

sub unwind_args {
    my $request = shift;
    $request->{args} = [ map  unwind($_), @{$request->{args}} ];
}

sub unwind {
    my ($arg) = @_;
    my $ref = ref($arg);
    if ($ref ne 'Net::Objwrap::Proxy' && $ref ne 'Net::Objwrap::ProxyS') {
        return $arg;
    }

    my $ref0 = Net::Objwrap::ref($arg);
    my $reftype0 = Net::Objwrap::reftype($arg);
    warn "unwrap for $ref => $ref0 $reftype0";
    if ($ref eq 'Net::Objwrap::ProxyS') {
        my $val = unwind(tied($arg->{scalar})->FETCH);
        $arg = \$val;
        if ($reftype0 ne $ref0) {
            bless $arg, $reftype0;
        }
        warn "Unwound $_[0] --> $arg\n";
        return $arg;
    }

    if ($reftype0 eq 'ARRAY') {
        my $tied = tied($$arg->{array});
        my $n = $tied->FETCHSIZE;
        my @val = map { unwind($tied->FETCH($_)) } 0 .. $n-1;
        if ($reftype0 ne $ref0) {
            return bless \@val, $reftype0;
        } else {
            return \@val;
        }
    }
    if ($reftype0 eq 'HASH') {
        my $tied = tied($$arg->{hash});
        my $key = $tied->FIRSTKEY;
        my $hash = {};
        if (defined($key)) {
            my $val = $tied->FETCH($key);
            $hash->{$key} = unwind($val);
            while (defined($key = $tied->NEXTKEY($key))) {
                $val = $tied->FETCH($key);
                $hash->{$key} = $val;
            }
        }
        if ($reftype0 ne $ref0) {
            return bless $hash, $reftype0;
        } else {
            return $hash;
        }
    }
    warn "Net::Objwrap::Aux::unwind: did nothing for ref $ref";

    return $arg;
}

######################################################################

# as we deserialize a response string from the server into a response object,
# inspect it for new objects that we haven't seen yet
sub deserialize_response {
    my ($response,$client) = @_;
    $response = Net::Objwrap::deserialize($response);
    if ($response->{response}) {
        if ($response->{context} == 2) {
            $response->{response} = [ map {
                vet_element($client,$_,$response);
                                      } @{$response->{response}} ];
        } else {
            $response->{response} =
                vet_element($client, $response->{response}, $response);
        }
    }
    return $response;
}

# inspect a response element for new object metadata
sub vet_element {
    my ($client,$elem,$response) = @_;
    #return $elem if ref($elem) ne 'Net::Objwrap::ObjectID';
    return $elem if ref($elem) ne 'SCALAR';

    my $id = $$elem;
    if (!$client->{proxies}{$id}) {
        my $objdata = $response->{meta}{$id};
        # includes  id, ref, reftype, *overload

        croak $Net::Objwrap::Aux::LAST_RESPONSE
            if $response->{meta}{$id}{ref} eq 'Net::Objwrap::Proxy';

        Net::Objwrap::xdiag("proxy: new object id $id objdata ",
                            Data::Dumper::Dumper($objdata));

        my $newproxy = getproxy($objdata, $client);
        $client->{proxies}{$id} = $newproxy;
        push @{$client->{objs}}, $newproxy;
    } else {
        Net::Objwrap::xdiag("proxy: object id $id already registered");
    }
    Net::Objwrap::xdiag("object id $id => $client->{proxies}{$id}");
    return $client->{proxies}{$id};
}

######################################################################

# overloading for  Net::Objwrap::Proxy  and  ProxyS  objects

my %numeric_ops = map { $_ => 1 }
qw# + - * / % ** << >> += -= *= /= %= **= <<= >>= <=> < <= > >= == != ^ ^=
    & &= | |= neg ! not ~ ++ -- atan2 cos sin exp abs log sqrt int 0+ #;

# non-numeric ops:
#  x . x= .= cmp lt le gt ge eq ne ^. ^.= ~. "" qr -X ~~


# overload function for all opts except deferencing operators
# By default it should behave like a ref
sub overload_handler {
    my ($ref, $y, $swap, $op) = @_;
    my $reqobj = Scalar::Util::reftype($ref) eq 'REF' ? $$ref : $ref;
    my $overloads = $reqobj->{overloads};
    
    if ($overloads) {
        # has the remote object overloaded this op?
	if ($overloads->{$op}) {
            #Net::Objwrap::xdiag("proxy: sending overload request ",
            #                    "op=$op y=$y swap=$swap");
	    return process_request(
		$reqobj, { id => $reqobj->{id},
                          topic => 'overload', command => $op,
                          has_args => 1, args => [ $y, $swap ] });
	}
    }

    # operation is not overloaded in remote variable
    return 1 if $op eq 'bool';
    return if $op eq '<>';      # no sensible default result for readline op

    my $str = overload::StrVal($ref);
    if ($numeric_ops{$op}) {
	my $num = hex($str =~ /x(\w+)/);

	# unary numeric operators
	return $num if $op eq '0+';
	return cos($num) if $op eq 'cos';
	return sin($num) if $op eq 'sin';
	return exp($num) if $op eq 'exp';
	return log($num) if $op eq 'log';
	return sqrt($num) if $op eq 'sqrt';
	return int($num) if $op eq 'int';
	return abs($num) if $op eq 'abs';
	return -$num if $op eq 'neg';
	return $num+1 if $op eq '++';
	return $num-1 if $op eq '--';
	return !$num if $op eq '!' || $op eq 'not';
	return ~$num if $op eq '~';

	# binary numeric operators
	($num,$y) = ($y,$num) if $swap;
	return atan2($num,$y) if $op eq 'atan2';
	return $ref if $op eq '=' || $op =~ /^[^<=>]=/; # assignment op
	return eval "$num $op \$y";
    }

    # string operator
    return $str if $op eq '""';
    return $ref if $op eq '=' || $op =~ /^[^<=>]=/;    # assignment op
    return qr/$str/ if $op eq 'qr';
    return eval "-$y \$str" if $op eq '-X';

    ($str,$y) = ($y,$str) if $swap;
    return eval "\$str $op \$y";
}



1;

=head1 NAME

Net::Objwrap::Client - client for proxy access to remote Perl object



=head1 VERSION

0.08



=head1 DESCRIPTION

The C<Net::Objwrap::Client> manages a connection to a remote object
server. It is mainly instantiated in the C<Net::Objwrap::unwrap()>
call, and is attached to all proxy objects that are received in the
current process by the remote server.





=head1 LICENSE AND COPYRIGHT

Copyright (c) 2017, Marty O'Brien.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

See http://dev.perl.org/licenses/ for more information.

=cut
