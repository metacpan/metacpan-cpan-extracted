# Connection.pm
# Scott Bronson
# 8 Dec 2003
#
# This is a connection abstraction library for the xmlexer utility.
# Right now, only the RPC::XML is supported, but it should be very
# easy to add your own client library.  It should work with anything
# that exports a set of callable functions -- it doesn't even have
# to be XML-based!

# hierarchy (parens means not implemented yet):
#
#     base object           protocol object           client object
#     -----------------------------------------------------------
#     Connection     <-     XMLRPC             <-     RPCXMLClient
#                                                     (Frontier::RPC)
#                                                     (Soap::Lite)
#
#                           Soap               <-     SOAPLiteClient
#                                                     (SOAP::RPC)
#


package RPC::Connection;

use strict;

use vars qw($VERSION);
$VERSION = '0.81';


# this is the base class common to all connections

# protocol objects need to implement
# calc_command_set

# client objects need to implement
# new
# get_url
# call


# Returns the previously cached command set
sub get_command_set
{
	my $self = shift;
	return $self->{commands} || {};
}

# Call introspection methods to retrieve the command set from the server
# there's no longer any need to have these routines separate...
sub retrieve_command_set
{
	my $self = shift;
	return $self->calc_command_set(@_);
}

# Clear commands from the command set
sub clear_command_set
{
	my $self = shift;

	if(@_) {
		for(@_) {
			if(exists $self->{commands}->{$_}) {
				delete $self->{commands}->{$_};
				print "$_ cleared\n" if $self->verb > 0;
			} else {
				print "$_ doesn't exist!\n";
			}
		}
	} else {
		# clear all commands
		my $cnt = keys %{$self->{commands}};
		delete $self->{commands} if exists $self->{commands};
		print "$cnt commands cleared\n" if $self->verb > 0;
	}
}


# Sets the noise level for all subsequent calls.
sub set_verbosity
{
	my $self = shift;
	$self->{verbosity} = shift;
}

# Returns the verbosity (cuts down on typing)
sub verb
{
	return shift->{verbosity};
}


sub trimstring
{
	my $self = shift;
	my $val = shift;
	my $maxlen = shift || 40;

	$val =~ s/\n//;
	my $len = length($val);
	$val = substr($val, 0, $maxlen);
	if($len > length($val)) {
		$val =~ s/...$/\.\.\./;
	}

	return $val;
}


sub summarize_array
{
	my $self = shift;
	my $type = shift;
	my $val = shift;

	my $str = "$type with " . @$val . " item" . (@$val==1?'':'s');
	if(@$val) {
		$str .= ": (" . $self->trimstring("'".join("', '", @$val)."'") . ")\n";
	} else {
		$str .= '.';
	}

	return $str;
}



sub summarize
{
	my $self = shift;
	my $val = shift;

	if(ref $val eq 'ARRAY') {
		return $self->summarize_array('array', $val);
	} elsif(ref $val eq 'HASH') {
		return $self->summarize_array('hash', [keys %$val]);
	} elsif(ref $val eq '') {
		return "scalar: \"" . $self->trimstring($val) . "\"\n";
	}
	return "Unknown type: " . ref($val) . "\n";
}



package RPC::Connection::Soap;

# Protocol object handling SOAP

# one day...





package RPC::Connection::XMLRPC;

# Protocol object handling XML-RPC

# This module uses the standardized XML-RPC introspection calls to
# discover the list of callable functions.  Most XML-RPC implementation
# objects will want to inherit from this one.

use strict;
use vars qw(@ISA);
@ISA = qw(RPC::Connection);


# If a server doesn't support the introspection call, we can fake it
# using methodSignature and methodHelp.  This will never return the
# version though.

sub fake_introspection
{
	my $self = shift;
	my $cmd = shift;

	my $intro = { name => $cmd };

	my $sig = $self->call('system.methodSignature', $cmd);
	if(ref($sig) eq 'ARRAY') {
		$intro->{'signature'} = $sig;
	} else {
		print "system.methodSignature($cmd) did not return an array!\n";
	}

	my $help = $self->call('system.methodHelp', $cmd);
	if(ref($help) eq '') {
		$intro->{'help'} = $help;
	} else {
		print "system.methodHelp($cmd) returned a " . ref($help) . "!\n";
	}

	return $intro;
}


sub real_introspection
{
	my $self = shift;
	my $cmd = shift;

	my $intro = $self->call('system.introspection', $cmd);
	unless(ref($intro) eq 'HASH') {
		print "system.introspection($cmd) did not return a hash!\n";
	}

	return $intro;
}


# returns the number of new commands loaded
sub calc_command_set
{
	my $self = shift;
	# rest of args are names of commands to load

	my $verb = $self->verb;
	my $cset = $self->{commands} || {};
	$self->{commands} = $cset;

	my $cmds;
	if(@_) {
		# commands to load are specified by caller
		$cmds = [@_];
	} else {
		# get a list of all commands using listMethods
		$cmds = $self->call('system.listMethods');
		unless(ref($cmds) eq 'ARRAY') {
			print "system.listMethods did not return an array!\n";
			return {};
		}
	}

	my $loadcnt = 0;
	my $use_real = 1;
	for my $cmd (@$cmds) {
		# don't load functions we may have loaded before.
		next if exists $cset->{$cmd};

		my $t;
		if($use_real) {
			print "Trying real introspection on $cmd\n" if $verb > 6;
			$t = eval { $self->real_introspection($cmd) };
			die $@ if $@ =~ /^Interrupt/;
		}
		if(!defined($t)) {
			print "Real introspection failed, trying fake on $cmd\n" if $verb > 6;
			$t = $self->fake_introspection($cmd);
			$use_real = 0;
		}
		if(defined($t)) {
			print "Loaded $cmd\n" if $verb > 0;
			$loadcnt += 1;

			if($t->{help}) {
				my $maxdesclen = 42;
				$t->{help} =~ /^(.*)$/;
				$t->{desc} = substr $1, 0, $maxdesclen;	# first line of help
				if(length($t->{desc}) == $maxdesclen) {
					$t->{desc} =~ s/...$/\.\.\./;	# add ellipsis if it's too long.
				}
			} else {
				$t->{desc} = '(no description available)';
			}

			$t->{args} = sub { $self->args_from_sig(@_) };
			$t->{doc} = $t->{help};
			$t->{proc} = sub { $self->call_proc($cmd, @_) };

			$cset->{$cmd} = $t;
		} else {
			print "no info on $cmd\n" if $verb > 0;
		}
	}

	return $loadcnt;
}


package RPC::Connection::RPCXMLClient;

# Client object using the RPC::XML::Client

use strict;
use vars qw(@ISA);
@ISA = qw(RPC::Connection::XMLRPC);


# returns the object if it was created, or an error string if not.

sub new
{
	require RPC::XML::Client;

	my $type = shift;
	my $url = shift;

	my $self = {};
	bless $self, $type;

	my $cli = RPC::XML::Client->new($url);
	unless(ref $cli) {
		print "$cli\n";
		return undef;
	}

	$self->{cli} = $cli;
	return $self;
}


sub get_url
{
	my $self = shift;
	return $self->{cli}->uri()->as_string();
}


sub call
{
	my $self = shift;
	my $verb = $self->verb;

	print "Calling: [" . join("], [", @_) . "]\n" if $verb > 2;
	my $resp = $self->{cli}->send_request(@_);
	if(ref($resp)) {
		if($resp->is_fault()) {
			die $resp->code() . ": " . $resp->string() . "\n";
		}
		my $val = $resp->value();
		print "Received: " . $self->summarize($val) if $verb > 3;
		if($verb > 5) {
			require Data::Dumper;
			print Data::Dumper->Dump([$val], ['Result']);
		}
		return $val;
	}

	die defined($resp) && length($resp) ? $resp : "Unknown RPC::XML error!\n"
}


1;

