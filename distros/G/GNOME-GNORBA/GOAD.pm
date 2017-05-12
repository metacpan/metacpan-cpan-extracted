#!/usr/bin/perl -w

package GNOME::GOAD;

use CORBA::ORBit idl => [ qw (name-service.idl gnome-factory.idl) ];
use Error qw(:try);

require Carp;

my $GOAD_MAGIC_FD = 123;

sub server_name {
    my ($name, $kind) = @_;

    return [ { id => "GNOME",   kind => "subcontext" },
	     { id => "Servers", kind => "subcontext"},
	     { id => $name,     kind => $kind } ];
}

sub server_register {

    my ($name_server, $server, $name, $kind) = $_;

    my $orb = CORBA::ORB_init ("orbit-local-orb");
    
    $strior = $name_server->object_to_string ($orb, $server)."\n";

    eval {
	local $SIG{PIPE} = 'IGNORE';

	open (IOROUT, "<&=$GOAD_MAGIC_FD") || die;
        defined(syswrite (IOROUT, $strior)) || die;
	close (IOROUT) || die;
    };
    if ($@) {
	Carp::carp ("Error registering server: $!\n");
	return;
    }

    if (!defined $name) { 
	return 0;
    }
    if (!defined $kind) {
	$kind = "server";
    }
    if (!defined $name_server) { 
	$name_server = GNOME::GNORBA::name_service_get();
    }
    if (!defined $name_server) {
	Carp::croak ("Cannot get Name Server\n");
    }

    my $old_server;
    try {
	$old_server = $name_server->resolve ($name);
    } catch CosNaming::NamingContext::NotFound with {
	# do nothing, OK
    };

    if (defined $old_server) {
	return -2;
    }

    try {
	$name_server->bind ($name, $server);
    };
}    


sub server_unregister {

    my ($name_server, $name, $kind) = @_;
    
    if (!defined $name_server) { 
	$name_server = GNOME::GNORBA::name_service_get();
    }
    if (!defined $name_server) {
	Carp::croak ("Cannot get Name Server\n");
    }


    try {
	$name_server->unbind (server_name ($name, $kind));
    } catch CORBA::Exception with {
	# $e = shift;
	# warn "Caught exception $e while unregistering server\n";
    };
}

my $server_list;
sub activate {
    if (!defined $server_list) {
	$server_list = GNOME::GOAD::ServerList::get();
    }

    $server_list->activate(@_);
}

package GNOME::GOAD::ServerList;

use strict;
require Carp;
use Error qw(:try);

my %possible_types = (
		      shlib => 1,
		      exe => 1,
		      relay => 1,
		      factory => 1
		     );
my %possible_flags = (
		      new_only => 1,
		      existing_only => 1,
		      shlib => 1,
		      remote => 1
		     );

sub _validate_flags {
}

sub _validate_server {
    my ($server_id, $section) = @_;
    
    if (!exists ($section->{type})) {
	warn ("Server $server_id: no activation method\n");
	return 0;
    }
    
    $section->{type} = lc($section->{type});
    if (!exists ($possible_types {$section->{type}})) {
	warn ("Server $server_id: invalid activation method $section->{type}\n");
	return 0;
    }

    my $newflags = {};
    if (exists $section->{flags}) {
	 foreach (split /\|/, $section->{flags}) {
	     $_ = lc($_);
	     if (!exists $possible_flags{$_}) {
		 warn ("Server $server_id: Unknown activation flag $_\n");
		 return 0;
	     }
	     $newflags->{$_} = 1;
	 }

	 if (exists $newflags->{new_only} && exists $newflags->{existing_only}) {
	     warn ("Server $server_id: Can't combine new_only and existing_only activation flags");
	     return 0;
	 }
	 if (exists $newflags->{shlib} && exists $newflags->{remote}) {
	     warn ("Server $server_id: Can't combine shlib and remote activation flags");
	     
	     return 0;
	 }
     }
    $section->{flags} = join ("|", keys %$newflags);

    if (!exists $section->{repo_id}) {
	warn ("Server $server_id: no repository ID\n");
	return 0;
    }

    if (!exists $section->{description}) {
	warn ("Server $server_id: no description\n");
	# Allow this with the warning.
    }

    if (!exists $section->{location_info}) {
	warn ("Server $server_id: no location information\n");
	# Allow this with the warning.
    }

    return 1;
}

sub _server_list_read {
    my ($filename) = shift;

    my @result;

    if (!open FILE, "<$filename") {
	warn "Cannot open file $filename: $!\n";
	return @result;
    }

    my $section;
    my $server_id;
    
    while (<FILE>) {
	chomp;

	if (/^\s*\[([^\]]*)\]\s*$/) {
	    if (defined $server_id &&
		_validate_server ($server_id, $section)) {
		$section->{server_id} = $server_id;
		push @result, $section;
	    }

	    $server_id = $1;
	    $section = {};
	} else {
	    if (/^([^ =\t][^=\t]*)=(.*)/) {
		$section->{$1} = $2;
	    }
	}
    }

    if (defined $server_id &&
	_validate_server ($server_id, $section)) {
	$section->{server_id} = $server_id;
	push @result, $section;
    }

    @result;
}

sub get {
    my @servers;
    
    my $sysconfdir = `gnome-config --sysconfdir`;
    chomp ($sysconfdir);
    my $server_dir = "$sysconfdir/CORBA/servers";
    opendir(DIR, $server_dir) or Carp::croak ("Can't open directory $server_dir: $!");
    while (defined (my $dir = readdir(DIR))) {
	push @servers, _server_list_read ("$server_dir/$dir");
    }

    return bless { servers => [ @servers ] };
}

sub _activate_exe {
    require POSIX;
    
    my ($self,$server,$flags,$params) = @_;
    my $pid;

    my ($inpipe, $outpipe) = POSIX::pipe();
    defined $inpipe or die "Cannot create pipes: $!\n";

    defined ($pid = fork) or die "Cannot fork: $!\n";
    
    if (!$pid) { # child
	if (fork) {
	    # Set up file descriptors
	    close STDIN;
	    POSIX::close($inpipe);
	    POSIX::dup2($outpipe, $GOAD_MAGIC_FD);
	    POSIX::close($outpipe);
	    
	    setpgrp 0,0;		# Run in a new session
	    my @args = ((split ' ', $server->{location_info}),
			"--activate-goad-server", $server->{server_id},
			@$params);

	    exec @args;
	}
    }

    open INPIPE, "<&=$inpipe";
    my $ior = <INPIPE>;
    close INPIPE;

    if ($ior !~ /^IOR:/) {
	warn "Output from server does not match IOR:";
	return undef;
    }

    chomp($ior);

    my $orb = CORBA::ORB_init ("orbit-local-orb");

    return $orb->string_to_object ($ior);
}

sub _activate_factory {
    my ($self, $server, $flags, $params) = @_;

    my $newflags = { %$flags };
    delete $newflags->{new_only};
    delete $newflags->{async};
    
    my $factory_obj = $self->activate (id => $self->{location_info},
				       flags => $newflags);
    if (!defined $factory_obj) {
	warn "Factory activation failed for $self->{location_info}\n";
	return undef;
    }
    
    my $result;
    try {
	$result = $factory_obj->get_object ($self->{server_id}, $params);
    } otherwise {
	my $e = shift;
	warn "Error getting object from factory. $e";
	return undef;
    }

    return $result;
}

sub _activate {
    my ($self, $server, $flags, $params) = @_;

    my $retval;
    
    # Combine flags
    
    my $newflags = { %$flags };
    my $sflags = { map { $_ => 1 } split /\|/, $server->{flags} };
    
    if (exists $sflags->{remote}) {
	delete $newflags->{shlib};
	$newflags->{remote} = 1;
    }
    if (exists $sflags->{shlib}) {
	delete $newflags->{remote};
	$newflags->{shlib} = 1;
    }
    
    if (exists $sflags->{new_only}) {
	delete $newflags->{existing_only};
	$newflags->{new_only} = 1;
    }
    if (exists $sflags->{existing_only}) {
	delete $newflags->{new_only};
	$newflags->{existing_only} = 1;
  }
    
    # First, do a name service lookup (unless told otherwise)

    if (!$newflags->{new_only}) {
  	my $name_service = GNOME::GNORBA::name_service_get ();
  	my $name = GNOME::GOAD::server_name ($server->{server_id}, 'object');
  	try {
  	    $retval = $name_service->resolve ($name);
  	} catch CosNaming::NamingContext::NotFound with {
	    undef $retval;
  	};
	
  	defined $retval and return $retval;
    }

    if ($server->{type} eq 'shlib') {
	Carp::croak ("shlib servers not supported under Perl\n");
    } elsif ($server->{type} eq 'exe') {
	_activate_exe ($self, $server, $newflags, $params);
    } elsif ($server->{type} eq 'relay') {
	Carp::croak ("Relay interface not yet defined (write an RFC :). Relay objects NYI\n");
    } else {
	_activate_factory ($self, $server, $newflags, $params);
    }
    
}

sub activate {
    my $self = shift;
    my %args = @_;

    my $flags;
    if (exists $args{flags}) {
	$flags = $args{flags};
	if (exist $flags->{shlib}) {
	    Carp::croak ("Shared library activation not supported for Perl\n");
	}

	delete $args{flags};
    } else {
	$flags = {};
    }

    my $params;
    if (exists $args{params}) {
	$params = $args{params};
	delete $args{params};
    } else {
	$params = [];
    }

    my $server_id;
    if (exists $args{id}) {
	$server_id = $args{id};
	delete $args{id};
    }

    my $repo_id;
    if (exists $args{repo_id}) {
	$repo_id = $args{repo_id};
	delete $args{repo_id};
    }

    if (keys %args) {
	my $arg = $args{(keys %args)[0]};
	Carp::croak ("Unknown argument '$arg'");
    }
    
    defined $server_id or defined $repo_id or Carp::croak ("Must specify 'id' or 'repo_id'\n");

    my $server;
    my $object;

    # first check for existing servers
    if (!$flags->{new_only}) {
	my $new_flags = { %$flags };
	$new_flags->{existing_only} = 1;
	
	for $server (@{$self->{servers}}) {
	    
	    next if ($server->{type} eq 'shlib');
	    next if (defined $server_id && $server->{server_id} ne $server_id);
	    next if (defined $repo_id && $server->{repo_id} ne $repo_id);

	    $object = _activate($self, $server, $new_flags, $params);
	    if (defined $object) {
		return $object;
	    }
	}
    }

    # now allow new servers
    for $server (@{$self->{servers}}) {
	    
	next if ($server->{type} eq 'shlib');
	next if (defined $server_id && $server->{server_id} ne $server_id);
	next if (defined $repo_id && $server->{repo_id} ne $repo_id);
	
	$object = _activate_($self, $server, $flags, $params);
	if (defined $object) {
	    return $object;
	}
    }

    return undef;
}
