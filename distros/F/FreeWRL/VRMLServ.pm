# Copyright (C) 1998 Tuomas J. Lukka
# DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
# See the GNU Library General Public License (file COPYING in the distribution)
# for conditions of use and redistribution.

# Implement communication with EAI and script processes.

package VRML::EAIServer;
use FileHandle;
use IO::Socket;
use strict;

sub new {
	my($type,$browser) = @_;
	my $this = bless {
		B => $browser,
	}, $type;
	$browser->add_periodic(sub {$this->poll});
	return $this;
}

sub gulp {
	my($this, $handle) = @_;
	my ($s,$b);
	my($rin,$rout);
	do {
		print "GULPING\n";
		my $n = $handle->sysread($b,1000);
		print "GULPED $n ('$b')\n";
		goto OUT if !$n;
		$s .= $b;
		vec($rin,$handle->fileno,1) = 1;
		select($rout=$rin,"","",0);
		print "ROUT : $rout\n";
	} while(vec($rout,$handle->fileno,1));
	print "ENDGULP\n";
  OUT:
	return $s;
}

# However funny this is, we do connect as the client ;)
sub connect {
	my($this, $addr) = @_;
	$addr =~ /^(.*):(.*)$/ or die("Invalid EAI adress '$addr'");
	my ($remote, $port) = ($1,$2);
	my $sock = IO::Socket::INET->new(
		Proto => "tcp",
		PeerAddr => $remote,
		PeerPort => $port
	) or die("Can't connect to $remote at port $port");
	$sock->autoflush(1);
	$sock->setvbuf("",&_IONBF,0);
	$sock->print("TJL EAI FREEWRL 0.01\n");
	my $x;
	$sock->sysread($x,20); 
	chomp $x;
	if("TJL EAI CLIENT 0.01" ne $x) {
		die("Invalid response from EAI client: '$x'");
	}
	push @{$this->{Conn}}, $sock;
}

sub poll {
	my($this) = @_;
	my ($nfound, $timeleft,$rout);
   	print "POLL\n";
	my $rin = '';
	for(@{$this->{Conn}}) {
		vec($rin, $_->fileno, 1) = 1;
	}
	($nfound, $timeleft) = select($rout = $rin, '', '', 0);
	print "SELECT NF $nfound\n";
	if($nfound) {
		for(@{$this->{Conn}}) {
			if(vec($rout, $_->fileno, 1)) {
				print "CONN: $_\n";
				$this->handle_input($_);
			}
		}
	}
}

sub handle_input {
	my($this, $hand) = @_;
	
	my @lines = split "\n",$this->gulp($hand);

	while(@lines) {
		print "Handle input $#lines\n";
		my $reqid = shift @lines; # reqid + newline
		my $str = shift @lines; 
		$hand->print("RE\n"); # Replying...
		$hand->print("$reqid\n"); # Responding to reqid...
		# Next line is number of lines to read
		if($str =~ /^GN (.*)$/) { # Get node
			my $node = $this->{B}->api_getNode($1);
			my $id = VRML::Handles::reserve($node);
			$hand->print("1\n$id\n");
		} elsif($str =~ /^GFT ([^ ]+) ([^ ]+)$/) { # get field type & kind
			my($id, $field) = ($1, $2);
			my ($kind, $type) = 
			 $this->{B}->api__getFieldInfo(VRML::Handles::get($id),
				$field);
			$hand->print("2\n$kind\n$type\n");
		} elsif($str =~ /^GI ([^ ]+) ([^ ]+)$/) { # get eventIn type
			my($id, $field) = ($1, $2);
			my ($kind, $type) = 
			 $this->{B}->api__getFieldInfo(VRML::Handles::get($id),
				$field);
			$hand->print("1\n$type\n");
		} elsif($str =~ /^GO ([^ ]+) ([^ ]+)$/) { # get eventOut type
			my($id, $field) = ($1, $2);
			my $node = VRML::Handles::get($id);
			my ($kind, $type) = 
			 $this->{B}->api__getFieldInfo($node, $field);
			my $val = $node->{RFields}{$_};
			# XXXXXXXX Horrible failure for nodes ;)
			my $strval = "VRML::Field::$type"->as_string($val);
			print "Sending VAL: $id $field '$strval'\n";
			$hand->print("2\n$type\n$strval\n");
		} elsif($str =~ /^SE ([^ ]+) ([^ ]+)$/) { # send eventIn to node
			my($id, $field) = ($1,$2);
			my $v = (shift @lines)."\n";
			my $node = VRML::Handles::get($id);
			# MFStrings will have exactly one space between
			# component strings -> this checks completeness of
			# both SF and MFStrings
			# XXX Do this!
			# while(!($v =~ /"\]?$/s and ($v !~ /" "\]?$/s or 
			# 	$v =~ /(^|[^\\])(\\\\)*\\" "\]?$/s)
			# 	)) {
			# 	$v .= (shift @lines)."\n";
			# }
			my $ft = $node->{Type}{FieldTypes}{$field};
			my $value = "VRML::Field::$ft"->parse("FOO",$v);
			$this->{B}->api__sendEvent($node,
					$field,
					$value
			);
			# No response
			$hand->print("0\n");
		} elsif($str =~ /^DN (.*)$/) { # Dispose node
			VRML::Handles::release($1);
			$hand->print("0\n");
		} elsif($str =~ /^RL ([^ ]+) ([^ ]+) ([^ ]+)$/) {
			my($id, $field, $lid) = ($1,$2,$3);
			my $node = VRML::Handles::get($id);
			$this->{B}->api__registerListener(
				$node,
				$field,
				sub {
					$this->send_listened($hand,
						$node,$id,$field,$lid,
						$_[0]);
				}
			);
			$hand->print("0\n");
		} elsif($str =~ /^GNAM$/) { # Get name
			$hand->print("0\n");
		} else {
			die("Invalid EAI input: '$str'");
		}
	}
	print "ENDLINES\n";
}

sub send_listened {
	my($this, $hand, $node, $id, $field, $lid, $value) = @_;
	my $ft = $node->{Type}{FieldTypes}{$field};
	my $str = "VRML::Field::$ft"->as_string($value);
	$hand->print("EV\n"); # Event incoming
	$hand->print("$lid\n");
	$hand->print("$str\n");
}


1;
