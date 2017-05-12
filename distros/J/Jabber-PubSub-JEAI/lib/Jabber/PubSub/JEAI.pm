package Jabber::PubSub::JEAI;

use 5.008003;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Jabber::PubSub::JEAI ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03';


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.
use Net::Jabber qw(Client);
sub create_channel{
	my $p = shift;
 	my ($uid,$pwd,$host,$port,$resource) = &conn_info($p);
        my $timestamp = time;
        my ($channel,$to,$iq_id,$payload);
        unless (defined $p->{'to'}){
        	warn "Missing service name: using pubsub.localhost instead.";
		$to = 'pubsub.localhost';
	}else{
		$to = $p->{'to'}||'pubsub.localhost';
	} 
        unless (defined $p->{'iq_id'}){
        	warn "Missing IQ ID: using default.";
		$iq_id = 'creating_on_'.$timestamp;
	}else{
		$iq_id = $p->{'iq_id'}||'creating_on_'.$timestamp;
	} 
        unless (defined $p->{'channel'}){
        	die "Missing channel name.";
	}else{
		$channel = $p->{'channel'};
	} 
        my ($Jabber,$vCard,@connect);
        eval{
                $Jabber   = Net::XMPP::Client->new();
                $Jabber->Connect(
                        hostname => $host,
                        port     => $port,
                );
                @connect = $Jabber->AuthSend(
                        username => $uid,
                        password => $pwd,
                        resource => $resource,
                );
        };
        die $! if($@);
        if ($connect[0] ne "ok") {
                die "Ident/Auth with server failed: $connect[0] - $connect[1]\n";
        }else{
                print "User $uid is connected to Jabber server $host on port $port...\n";
        }
        my $xml = qq|<pubsub xmlns='http://jabber.org/protocol/pubsub'>
	<create node='$channel'/>
</pubsub>|;
        eval{
                $vCard = new Net::Jabber::IQ();
                $vCard->SetIQ(type=>'set', to=>$to, id=> $iq_id);
                $vCard->InsertRawXML($xml);
                $Jabber->Send($vCard);
        };
        die $! if($@);
        print "User $uid has ordered to create pub/sub channel $channel.\n";
        1;
}

sub delete_channel{
	my $p = shift;
 	my ($uid,$pwd,$host,$port,$resource) = &conn_info($p);
        my $timestamp = time;
        my ($channel,$to,$iq_id,$payload);
        unless (defined $p->{'to'}){
        	warn "Missing service name: using pubsub.localhost instead.";
		$to = 'pubsub.localhost';
	}else{
		$to = $p->{'to'}||'pubsub.localhost';
	} 
        unless (defined $p->{'iq_id'}){
        	warn "Missing IQ ID: using default.";
		$iq_id = 'deleting_on_'.$timestamp;
	}else{
		$iq_id = $p->{'iq_id'}||'deleting_on_'.$timestamp;
	} 
        unless (defined $p->{'channel'}){
        	die "Missing channel name.";
	}else{
		$channel = $p->{'channel'};
	} 
        my ($Jabber,$vCard,@connect);
        eval{
                $Jabber   = Net::XMPP::Client->new();
                $Jabber->Connect(
                        hostname => $host,
                        port     => $port,
                );
                @connect = $Jabber->AuthSend(
                        username => $uid,
                        password => $pwd,
                        resource => $resource,
                );
        };
        die $! if($@);
        if ($connect[0] ne "ok") {
                die "Ident/Auth with server failed: $connect[0] - $connect[1]\n";
        }else{
                print "User $uid is connected to Jabber server $host on port $port...\n";
        }
        my $xml = qq|<pubsub xmlns='http://jabber.org/protocol/pubsub'>
	<delete node='$channel'/>
</pubsub>|;
        eval{
                $vCard = new Net::Jabber::IQ();
                $vCard->SetIQ(type=>'set', to=>$to, id=> $iq_id);
                $vCard->InsertRawXML($xml);
                $Jabber->Send($vCard);
        };
        die $! if($@);
        print "User $uid has ordered to delete pub/sub channel $channel.\n";
        1;
}

sub subscribe {
	my $p = shift;
 	my ($uid,$pwd,$host,$port,$resource) = &conn_info($p);
        my $timestamp = time;
        my ($channel,$to,$iq_id,$payload);
        unless (defined $p->{'to'}){
        	warn "Missing service name: using pubsub.localhost instead.";
		$to = 'pubsub.localhost';
	}else{
		$to = $p->{'to'}||'pubsub.localhost';
	} 
        unless (defined $p->{'iq_id'}){
        	warn "Missing IQ ID: using default.";
		$iq_id = 'subscribing_on_'.$timestamp;
	}else{
		$iq_id = $p->{'iq_id'}||'subscribing_on_'.$timestamp;
	} 
        unless (defined $p->{'channel'}){
        	die "Missing channel name.";
	}else{
		$channel = $p->{'channel'};
	}
	my ($Jabber,$vCard,@connect);
        eval{
                $Jabber   = Net::XMPP::Client->new();
                $Jabber->Connect(
                        hostname => $host,
                        port     => $port,
                );
                @connect = $Jabber->AuthSend(
                        username => $uid,
                        password => $pwd,
                        resource => $resource,
                );
        };
        die $! if($@);
        if ($connect[0] ne "ok") {
                die "Ident/Auth with server failed: $connect[0] - $connect[1]\n";
        }else{
                print "User $uid is connected to Jabber server $host on port $port...\n";
        }
        eval{
                my $xml = qq|<pubsub xmlns='http://jabber.org/protocol/pubsub'>
        <subscribe node='$channel' jid='$uid\@localhost'/>
</pubsub>|;
                $vCard = new Net::Jabber::IQ();
                $vCard->SetIQ(type=>'set', to=>$to, id=> $iq_id);
                $vCard->InsertRawXML($xml);
                $Jabber->Send($vCard);
        };
        die $! if($@);
        print "User $uid has ordered to subscribe to channel $channel.\n";
        1;
}

sub publish {
	my $p = shift;
 	my ($uid,$pwd,$host,$port,$resource) = &conn_info($p);
        my $timestamp = time;
        my ($channel,$to,$iq_id,$payload);
        unless (defined $p->{'to'}){
        	warn "Missing service name: using pubsub.localhost instead.";
		$to = 'pubsub.localhost';
	}else{
		$to = $p->{'to'}||'pubsub.localhost';
	} 
        unless (defined $p->{'iq_id'}){
        	warn "Missing IQ ID: using default.";
		$iq_id = 'publishing_on_'.$timestamp;
	}else{
		$iq_id = $p->{'iq_id'}||'publishing_on_'.$timestamp;
	}
        unless (defined $p->{'channel'}){
        	die "Missing channel name.";
	}else{
		$channel = $p->{'channel'};
	}
	unless (defined $p->{'payload'}){
		die "Missing payload." 
	}else{
		$payload = $p->{'payload'};
	}
	
        my ($Jabber,$vCard,@connect);
        eval{
                $Jabber   = Net::XMPP::Client->new();
                $Jabber->Connect(
                	hostname => $host,
                	port     => $port,
                );
                @connect = $Jabber->AuthSend(
	                username => $uid,
	                password => $pwd,
	                resource => $resource,
                );
        };
        die $! if($@);
        if ($connect[0] ne "ok") {
                die "Ident/Auth with server failed: $connect[0] - $connect[1]\n";
        }else{
                print "User $uid is connected to Jabber server $host on port $port...\n";
        }
        eval{
                my $xml = qq|<pubsub xmlns="http://jabber.org/protocol/pubsub">
        <publish node="$channel">
                <item>$payload</item>
        </publish>
</pubsub>|;
                $vCard = new Net::Jabber::IQ();
                $vCard->SetIQ(type=>'set', to=>$to, id=> $iq_id);
                $vCard->InsertRawXML($xml);
                my $res = $Jabber->Send($vCard);
        };
        die $! if($@);
        print "User $uid has sent a message to channel $channel.\n";
        1;
}


sub listen {
	my $p = shift;
 	my ($uid,$pwd,$host,$port,$resource) = &conn_info($p);
        my $timestamp = time;
        my ($channel,$to,$iq_id,$payload);
        my ($Jabber,$Presence, @connect);
        eval{
                $Jabber   = Net::XMPP::Client->new();
		$Presence = Net::XMPP::Presence->new();
                $Jabber->Connect(
	                hostname => $host,
	                port     => $port,
                );
                @connect = $Jabber->AuthSend(
	                username => $uid,
	                password => $pwd,
	                resource => $resource,
                );
        };
        die $! if($@);
        if ($connect[0] ne "ok") {
                die "Ident/Auth with server failed: $connect[0] - $connect[1]\n";
        }else{
                print "User $uid is connected to Jabber server $host on port $port...\n";
        }
        $Presence->SetType("available");
        $Presence->SetStatus("Ask me! Ask me, now!");
        $Jabber->Send($Presence);
        $Jabber->SetCallBacks(message=>\&handle_message, presence=>\&handle_presence, iq=>\&handle_iq,);
        my $lookups     = 0;
        my $max_lookups = 10;
        while (defined($Jabber->Process())) {
                my $current_type = $Presence->GetType();
                if (($lookups >= $max_lookups) && ($current_type ne "unavailable")) {
                        $Presence->SetType("unavailable");
                        $Presence->SetStatus("I am helping someone else right now.");
                        $Jabber->Send($Presence);
                }
                if ( ($lookups < $max_lookups) && ($current_type ne "available")) {
                        $Presence->SetType("available");
                        $Presence->SetStatus("Ask me! Ask me, now!");
                        $Jabber->Send($Presence);
                }
        }
        1;
}
sub handle_message {
        shift;
        my $msg = shift->GetX();
        my $item = $msg->{TREE}->{CHILDREN}->[0]->{CHILDREN}->[0]->{CHILDREN}->[0]->{CHILDREN}->[0];
        print $item,"\n";
        return $item;
}

sub handle_presence {
        print Dumper(\@_);
        return \@_;
}
sub handle_iq {
        print Dumper(\@_);
        return \@_;
}

sub conn_info {
        my $p = shift;
        die "Missing input param." unless(defined $p);
        my ($uid,$pwd,$host,$port,$resource,$channel,$to,$iq_id,$payload);
        my $timestamp = time;
        unless (defined $p->{'uid'}){
        	die "Missing ID of the channel owner.";
	}else{
		$uid = $p->{'uid'};
	}               
        unless (defined $p->{'pwd'}){
        	die "Missing password of the channel owner.";
	}else{
		$pwd = $p->{'pwd'};
	} 
        unless (defined $p->{'host'}){
        	warn "Missing host name: using localhost instead.";
		$host = 'localhost';
	}else{
		$host = $p->{'host'}||'localhost';
	} 
        unless (defined $p->{'port'}){
        	warn "Missing port number: using 5222 instead.";
		$port = 5222;
	}else{
		$port = $p->{'port'}||5222;
	} 
        unless (defined $p->{'resource'}){
        	warn "Missing resource name: using PerlScript instead.";
		$resource = 'PerlScript';
	}else{
		$resource = $p->{'resource'}||'PerlScript';
	} 
	return ($uid,$pwd,$host,$port,$resource);
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Jabber::PubSub::JEAI - Perl extension for Erlang's J-EAI server

=head1 SYNOPSIS

  use Jabber::PubSub::JEAI;

It is important that you put Jabber connection and pub/sub parameters in a hash reference and pass it to the subroutines. Although not all of the pamameters are necessary for each subroutine.
Example for channel creation:

	my $param = {
	    'uid'      => 'admin',
	    'pwd'      => 'nimda',
	    'host'     => 'localhost', 		# default is 'localhost'
	    'port'     => 5222, 		# default is 5222
	    'resource' => '', 			# use default
	    'channel'  => 'home/localhost/admin/sport',
	    'to'       => 'pubsub.localhost', 
	    'iq_id'    => '', 			# use default
	    'payload'  => '', 			# N/A for channel creation
	};
	Jabber::PubSub::JEAI::create_channel($param);

Example for channel deletion:

	my $param = {
	    'uid'      => 'admin',
	    'pwd'      => 'nimda',
	    'host'     => 'localhost', 		# default is 'localhost'
	    'port'     => 5222, 		# default is 5222
	    'resource' => '', 			# use default
	    'channel'  => 'home/localhost/admin/sport',
	    'to'       => 'pubsub.localhost', 
	    'iq_id'    => '', 			# use default
	    'payload'  => '', 			# N/A for channel creation
	};
	Jabber::PubSub::JEAI::delete_channel($param);

Example for subscription to the channel:

	$param = {
	    'uid'      => 'app2',
	    'pwd'      => 'app2',
	    'host'     => 'localhost',		# default is 'localhost'
	    'port'     => 5222,			# default is 5222
	    'resource' => '',			# used default
	    'channel'  => 'home/localhost/admin/sport',
	    'to'       => 'pubsub.localhost',
	    'iq_id'    => '', 			# use default
	    'payload'  => '', 			# N/A for channel subscription
	};
	Jabber::PubSub::JEAI::subscribe($param);


To receive the publised messages you can use any Jabber client. All subscribers to the same channel will get the same messages simultaneously if they are all listening, or get the messages later but in correct sequence. Here is an example for polling a Jabber box and show the payloads in the published messages with Jabber::PubSub::JEAI:

	$param = {
	    'uid'      => 'app2',
	    'pwd'      => 'app2',
	    'host'     => 'localhost',		# default is 'localhost'
	    'port'     => 5222,			# default is 5222
	    'resoirce' => 'Test',
	    'channel'  => '', 			# N/A for this purpose
	    'to'       => '', 			# N/A for this purpose
	    'iq_id'    => '', 			# N/A for this purpose
	    'payload'  => '', 			# N/A for this purpose
	};
	Jabber::PubSub::JEAI::listen($param);

Example for publication to the channel:

	$param = {
	    'uid'      => 'admin', 
	    'pwd'      => 'nimda',
	    'host'     => 'localhost',		# default is 'localhost'
	    'port'     => 5222,			# default is 5222
	    'resource' => 'Test',
	    'channel'  => 'home/localhost/admin/sport',
	    'to'       => 'pubsub.localhost',
	    'iq_id'    => '', 			# use default
	    'payload'  => 'Breaking news! ...',
	};
	Jabber::PubSub::JEAI::publish($param);	
	

=head1 DESCRIPTION

This package offers some utilities for interfacing with Erlang's J-EAI server 1.0.


=head2 EXPORT

None by default.



=head1 ACKNOWLEDGMENT

The author wishes to thank to "Thierry Mallard" <thierry.mallard@erlang-fr.org> and "Mickael Remond" <mickael.remond@erlang-fr.org>, leaders of J-EAI development team, for their support.

=head1 AUTHOR

Kai Li, E<lt>kaili@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Kai Li

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
