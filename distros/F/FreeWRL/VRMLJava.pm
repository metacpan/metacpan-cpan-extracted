# Copyright (C) 1998 Tuomas J. Lukka
# DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
# See the GNU Library General Public License (file COPYING in the distribution)
# for conditions of use and redistribution.

# Implement VRMLPERL-JAVA communication.

package VRML::JavaCom::OHandle;
sub new {my($type,$handle) = @_; bless {Handle => $handle},$type;}
sub print {my $this = shift;
	if($VRML::verbose::java) {
		print "TO JAVA:\n---\n";
		print @_; print "---\n";
	}
	$this->{Handle}->print(@_);}
sub flush {$_[0]{Handle}->flush}

package VRML::JavaCom::IHandle;
sub new {my($type,$handle) = @_; bless {Handle => $handle},$type;}
sub getline {
	my $l = $_[0]{Handle}->getline;
	print "FROM JAVA:\n---\n$l---\n" if $VRML::verbose::java;
	return $l;
}

package VRML::JavaCom;
use FileHandle;
use IPC::Open2;
use Fcntl;

my $eid;

sub new {
	my($type) = @_;
	bless {
	}, $type;
}

sub connect {
	my($this) = @_;
# XXX java VM name
	# my @cmd = split ' ','java_g TjlScript';
	# $pid = system 1, @cmd;
	unless ($pid = fork()) {
		exec 'java_g -v TjlScript';
	}
	($this->{I} = FileHandle->new)->open("<.javapipej");
	$this->{I}->setvbuf("",_IONBF,0);
	($this->{O} = FileHandle->new)->open(">.javapipep");
	# $pid = open3("<, $this->{O}, 'java_g -v TjlScript ');
	$this->{O} = VRML::JavaCom::OHandle->new($this->{O});
	$this->{I} = VRML::JavaCom::IHandle->new($this->{I});
	$this->{O}->print( "TJL XXX PERL-JAVA 0.00\n" );
	$this->{O}->flush();
	$str = $this->{I}->getline; chomp $str;
	if("TJL XXX JAVA-PERL 0.00" ne $str) {
		die("Invalid response from java scripter: '$str'");
	}
	$this->{O}->print("\n"); # Directory - currently ""
}

sub initialize {return ()}

sub newscript {
	my($this, $purl, $url, $node) = @_;
	undef $1;
	$purl =~ /^(.*\/)[^\/]+$/;
	$url = $1.$url; # XXXX!!
	if(!$this->{O}) {$this->connect}
	$this->{Ids}{$node} = $node;
	$this->{O}->print("NEWSCRIPT\n$node\n$url\n");
	my $t = $node->{Type};
	my @k = keys %{$t->{Defaults}};
	$this->{O}->print(((scalar @k)-1)."\n");
	for(@k) {
		next if $_ eq "url";
		$this->{O}->print("$t->{FieldKinds}{$_}\n$t->{FieldTypes}{$_}\n$_\n");
		if($t->{FieldKinds}{$_} eq "field") {
			my $ft = "VRML::Field::".$t->{FieldTypes}{$_};
			$this->{O}->print($ft->toj($node->{RFields}{$_})."\n");
		}
	}
	$this->{O}->flush();
}

sub sendinit {
	my($this,$node) = @_;
	$eid++;
	$this->{O}->print("INITIALIZE\n$node\n$eid\n");
	$this->{O}->flush();
	return $this->receive($eid);
}

sub sendevent {
	my($this,$node,$event,$value,$timestamp) = @_;
	$eid++;
	$this->{O}->print("SENDEVENT\n$node\n$eid\n$event\n");
	$this->{O}->print(
		"VRML::Field::$node->{Type}{FieldTypes}{$event}"->toj(
			$value
		)."\n"
	);
	$this->{O}->print("$timestamp\n");
	$this->{O}->flush();
	return $this->receive($eid);
}

sub sendeventsproc {
	my($this,$node) = @_;
	$eid++;
	$this->{O}->print("EVENTSPROCESSED\n$node\n$eid\n");
	$this->{O}->flush();
	return $this->receive($eid);
}

sub receive {
	my($this,$id) = @_;
	my @a;
	$i = $this->{I};
	while(1) {
		print "WAITING FOR JAVA EVENT...\n" if $VRML::verbose::java;
		my $cmd = $i->getline; 
		die("EOF on java filehandle") 
			if !defined $cmd;
		chomp $cmd;
		print "JAVA EVENT '$cmd'\n" if $VRML::verbose::java;
		if($cmd eq "FINISHED") {
			my $ri = $i->getline; chomp $ri;
			if($ri ne $id) {
				die("Invalid request id from java scripter: '$ri' should be '$id'\n");
			}
			return @a;
		} elsif($cmd eq "SENDEVENT") {
			my $nid = $i->getline; chomp $nid;
			my $field = $i->getline; chomp $field;
			my $value = $i->getline; chomp $value;
			my $node = $this->{Ids}{$nid};
			$value = "VRML::Field::$node->{Type}{FieldTypes}{$field}"
				-> fromj($value);
			push @a, [$node, $field, $value];
		} else {
			die("Invalid Java event '$cmd'");
		}
	}
}

1;
