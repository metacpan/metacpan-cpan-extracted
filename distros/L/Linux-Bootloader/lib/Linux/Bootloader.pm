=head1 NAME

Linux::Bootloader - Base class interacting with Linux bootloaders

=head1 SYNOPSIS

	use Linux::Bootloader;
	
	my $bootloader = new Linux::Bootloader();
        my $config_file='/boot/grub/menu.lst';
	
	$bootloader->read($config_file);
	$bootloader->print_info('all');
	$bootloader->add(%hash);
	$bootloader->update(%hash);
	$bootloader->remove(2);
	$bootloader->get_default();
	$bootloader->set_default(2);
	%hash = $bootloader->read_entry(0);
	$bootloader->write($config_file);

  
=head1 DESCRIPTION

This module provides base functions for working with bootloader configuration files.

=head1 FUNCTIONS

=head2 new()

	Creates a new Linux::Bootloader object.

=head2 read()

	Reads configuration file into an array.
	Takes: string.
	Returns: undef on error.

=head2 write()

	Writes configuration file.
	Takes: string.
	Returns: undef on error.

=head2 print_info()

	Prints information from config.
	Takes: string.
	Returns: undef on error.

=head2 _info()

	Parse config into array of hashes.
	Takes: nothing.
	Returns: array of hashes.

=head2 get_default()

	Determine current default kernel.
	Takes: nothing.
	Returns: integer, undef on error.

=head2 set_default()

	Set new default kernel.
	Takes: integer.
	Returns: undef on error.

=head2 add()

	Add new kernel to config.
	Takes: hash.
	Returns: undef on error.

=head2 update()

	Update args of an existing kernel entry.
	Takes: hash.
	Returns: undef on error.

=head2 remove()

	Remove kernel from config.
	Takes: string.
	Returns: undef on error.

=head2 read_entry()

        Read an existing entry into a hash suitable to add or update from.
	Takes: integer or title
	Returns: undef or hash

=head2 debug($level)

        Sets or gets the current debug level, 0-5.
        Returns:  Debug level

=head2 _check_config()

        Conducts a basic check for kernel validity
        Returns:  true if checks out okay,
                  false if not okay,
                  undef on error

=head2 _lookup()

        Converts title into position.
	Takes: string.
        Returns:  integer,
                  undef on error

=cut


package Linux::Bootloader;

use Linux::Bootloader::Detect;
use strict;
use warnings;

use vars qw( $VERSION );
our $VERSION = '1.2';


sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    if ( defined $class and $class  eq 'Linux::Bootloader' ){
        my $detected_bootloader = Linux::Bootloader::Detect::detect_bootloader();
        unless (defined $detected_bootloader) { return undef; }
        $class = "Linux::Bootloader::" . "\u$detected_bootloader";
        eval" require $class; ";
    } 
    my $self = bless ({}, $class);
    $self->{config_file} = shift;
    unless (defined $self->{'config_file'}){
        $self->_set_config_file(); 
    }

    $self->{config}	= [];
    $self->{debug}	= 0;
    $self->{'entry'}    = {};

    return $self;
}


### Generic Functions ###

# Read config file into array

sub read {
  my $self=shift;
  my $config_file=shift || $self->{config_file};
  print ("Reading $config_file.\n") if $self->debug()>1;

  open(CONFIG, "$config_file")
    || warn ("ERROR:  Can't open $config_file.\n") && return undef;
  @{$self->{config}}=<CONFIG>;
  close(CONFIG);

  print ("Current config:\n @{$self->{config}}") if $self->debug()>4;
  print ("Closed $config_file.\n") if $self->debug()>2;
  return 1;
}


# Write new config

sub write {
  my $self=shift;
  my $config_file=shift || $self->{config_file};
  my @config=@{$self->{config}};

  return undef unless $self->_check_config();

  print ("Writing $config_file.\n") if $self->debug()>1;
  print join("",@config) if $self->debug() > 4;

  if (-w $config_file) {
    system("cp","$config_file","$config_file.bak.boottool");
    if ($? != 0) {
      warn "ERROR:  Cannot backup $config_file.\n"; 
      return undef;
    } else {
      print "Backed up config to $config_file.bak.boottool.\n";
    }

    open(CONFIG, ">$config_file")
      || warn ("ERROR:  Can't open config file.\n") && return undef;
    print CONFIG join("",@config);
    close(CONFIG);
    return 0;
  } else {
    print join("",@config) if $self->debug() > 2;
    warn "WARNING:  You do not have write access to $config_file.\n";
    return 1;
  }
}


# Parse config into array of hashes

sub _info {
  my $self=shift;

  return undef unless $self->_check_config();
  my @config=@{$self->{config}};

  # remove garbarge - comments, blank lines
  @config=grep(!/^#|^\n/, @config);

  my %matches = ( default => '^\s*default[\s+\=]+(\S+)',
                  timeout => '^\s*timeout[\s+\=]+(\S+)',
                  title   => '^\s*label[\s+\=]+(\S+)',
                  root    => '^\s*root[\s+\=]+(\S+)',
                  args    => '^\s*append[\s+\=]+(.*)',
                  initrd  => '^\s*initrd[\s+\=]+(\S+)',
                );

  my @sections;
  my $index=0;
  foreach (@config) {
    if ($_ =~ /^\s*(image|other)[\s+\=]+(\S+)/i) {
      $index++;
      $sections[$index]{'kernel'} = $2;
    }
    foreach my $key (keys %matches) {
      if ($_ =~ /$matches{$key}/i) {
        $sections[$index]{$key} = $1;
	$sections[$index]{$key} =~ s/\"|\'//g if ($key eq 'args');
      }
    }
  }

  # sometimes config doesn't have a default, so goes to first
  if (!(defined $sections[0]{'default'})) {
    $sections[0]{'default'} = '0';

  # if default is label name, we need position
  } elsif ($sections[0]{'default'} !~ m/^\d+$/) {
    foreach my $index (1..$#sections) {
      if ($sections[$index]{'title'} eq $sections[0]{'default'}) {
        $sections[0]{'default'} = $index-1;
        last;
      }
    }
  }

  # if still no valid default, set to first
  if ( $sections[0]{'default'} !~ m/^\d+$/ ) {
    $sections[0]{'default'} = 0;
  }

  # return array of hashes
  return @sections;
}


# Determine current default kernel

sub get_default {
  my $self = shift;

  print ("Getting default.\n") if $self->debug()>1;
  return undef unless $self->_check_config();

  my @sections = $self->_info();
  my $default = $sections[0]{'default'};
  if ($default =~ /^\d+$/) {
      return 0+$default;
  }

}


# Set new default kernel

sub set_default {
  my $self=shift;
  my $newdefault=shift;

  print ("Setting default.\n") if $self->debug()>1;

  return undef unless defined $newdefault;
  return undef unless $self->_check_config();

  my @config=@{$self->{config}};
  my @sections=$self->_info();

  # if not a number, do title lookup
  if ($newdefault !~ /^\d+$/) {
    $newdefault = $self->_lookup($newdefault);
  }

  my $kcount = $#sections-1;
  if ((!defined $newdefault) || ($newdefault < 0) || ($newdefault > $kcount)) {
    warn "ERROR:  Enter a default between 0 and $kcount.\n";
    return undef;
  }

  # convert position to title
  $newdefault = $sections[++$newdefault]{title};
 
  foreach my $index (0..$#config) {
    if ($config[$index] =~ /^\s*default/i) { 
      $config[$index] = "default=$newdefault	# set by $0\n"; 
      last;
    }
  }
  @{$self->{config}} = @config;
}


# Add new kernel to config

sub add {
  my $self=shift;
  my %param=@_;

  print ("Adding kernel.\n") if $self->debug()>1;

  if (!defined $param{'add-kernel'} && defined $param{'kernel'}) {
    $param{'add-kernel'} = $param{'kernel'};
  } elsif (!defined $param{'add-kernel'} || !defined $param{'title'}) {
    warn "ERROR:  kernel path (--add-kernel), title (--title) required.\n";
    return undef;
  } elsif (!(-f "$param{'add-kernel'}")) {
    warn "ERROR:  kernel $param{'add-kernel'} not found!\n";
    return undef;
  } elsif (defined $param{'initrd'} && !(-f "$param{'initrd'}")) {
    warn "ERROR:  initrd $param{'initrd'} not found!\n";
    return undef;
  }

  return undef unless $self->_check_config();

  # remove title spaces and truncate if more than 15 chars
  $param{title} =~ s/\s+//g;
  $param{title} = substr($param{title}, 0, 15) if length($param{title}) > 15;

  my @sections=$self->_info();

  # check if title already exists
  if (defined $self->_lookup($param{title})) {
    warn ("WARNING:  Title already exists.\n");
    if (defined $param{force}) {
      $self->remove($param{title});
    } else {
      return undef;
    }
  }

  my @config = @{$self->{config}};
  @sections=$self->_info();
 
  # Use default kernel to fill in missing info
  my $default=$self->get_default();
  $default++;

  foreach my $p ('args', 'root') {
    if (! defined $param{$p}) {
      $param{$p} = $sections[$default]{$p};
    }
  }

  # use default entry to determine if path (/boot) should be removed
  if ($sections[$default]{'kernel'} !~ /^\/boot/) {
    $param{'add-kernel'} =~ s/^\/boot//;
    $param{'initrd'} =~ s/^\/boot// unless (!defined $param{'initrd'});
  }

  my @newkernel;
  push (@newkernel, "image=$param{'add-kernel'}\n", "\tlabel=$param{title}\n");
  push (@newkernel, "\tappend=\"$param{args}\"\n") if defined $param{args};
  push (@newkernel, "\tinitrd=$param{initrd}\n") if defined $param{initrd};
  push (@newkernel, "\troot=$param{root}\n") if defined $param{root};
  push (@newkernel, "\tread-only\n\n");

  if (!defined $param{position} || $param{position} !~ /end|\d+/) {
    $param{position}=0;
  }

  my @newconfig;
  if ($param{position}=~/end/ || $param{position} >= $#sections) { 
    $param{position}=$#sections;
    push (@newconfig,@config);
    if ($newconfig[$#newconfig] =~ /\S/) {
      push (@newconfig, "\n");
    }
    push (@newconfig,@newkernel);
  } else {
    my $index=0;
    foreach (@config) {
      if ($_ =~ /^\s*(image|other)/i) { 
        if ($index==$param{position}) {
          push (@newconfig, @newkernel);
        }
        $index++;
      }
      push (@newconfig, $_);
    }
  }

  @{$self->{config}} = @newconfig;

  if (defined $param{'make-default'}) { 
    $self->set_default($param{position});
  } 
}


# Update kernel args

sub update {
  my $self=shift;
  my %params=@_;

  print ("Updating kernel.\n") if $self->debug()>1;

  if (!defined $params{'update-kernel'} || (!defined $params{'args'} && !defined $params{'remove-args'})) {
    warn "ERROR:  kernel position or title (--update-kernel) and args (--args or --remove-args) required.\n";
    return undef;
  }

  return undef unless $self->_check_config();

  my @config = @{$self->{config}};
  my @sections=$self->_info();

  # if not a number, do title lookup
  if ($params{'update-kernel'} !~ /^\d+$/) {
    $params{'update-kernel'} = $self->_lookup($params{'update-kernel'});
  }

  my $kcount = $#sections-1;
  if ($params{'update-kernel'} !~ /^\d+$/ || $params{'update-kernel'} < 0 || $params{'update-kernel'} > $kcount) {
    warn "ERROR:  Enter a default between 0 and $kcount.\n";
    return undef;
  }

  my $index=-1;
  foreach (@config) {
    if ($_ =~ /^\s*(image|other)/i) {
      $index++;
    }
    if ($index==$params{'update-kernel'}) {
      if ($_ =~ /(^\s*append[\s\=]+)(.*)\n/i) {
        my $append = $1;
        my $args = $2;
        $args =~ s/\"|\'//g;
        $args =~ s/\s*$params{'remove-args'}\=*\S*//ig if defined $params{'remove-args'};
        $args = $args . " ". $params{'args'} if defined $params{'args'};
        if ($_ eq "$append\"$args\"\n") {
          warn "WARNING:  No change made to args.\n";
          return undef;
        } else {
          $_ = "$append\"$args\"\n";
        }
        next;
      }
    }
  }
  @{$self->{config}} = @config;
}


# Remove kernel from config

sub remove {
  my $self=shift;
  my $position=shift;
  my @newconfig;

  return undef unless defined $position;
  return undef unless $self->_check_config();

  my @config=@{$self->{config}};
  my @sections=$self->_info();

  if ($position=~/^end$/i) {
    $position=$#sections-1;
  } elsif ($position=~/^start$/i) {
    $position=0;
  }

  print ("Removing kernel $position.\n") if $self->debug()>1;

  # remove based on title
  if ($position !~ /^\d+$/) {
    my $removed=0;
    for (my $index=$#sections; $index > 0; $index--) {
      if (defined $sections[$index]{title} && $position eq $sections[$index]{title}) {
        $removed++ if $self->remove($index-1);
      }
    }
    if (! $removed) {
      warn "ERROR:  No kernel with specified title.\n";
      return undef;
    }

  # remove based on position
  } elsif ($position =~ /^\d+$/) {

    if ($position < 0 || $position > $#sections) {
      warn "ERROR:  Enter a position between 0 and $#sections.\n";
      return undef;
    }

    my $index=-1;
    foreach (@config) {
      if ($_ =~ /^\s*(image|other|title)/i) {
        $index++
      }
      # add everything to newconfig, except removed kernel (keep comments)
      if ($index != $position || $_ =~ /^#/) {
        push (@newconfig, $_)
      }
    }
    @{$self->{config}} = @newconfig;


    # if we removed the default, set new default to first
    $self->set_default(0) if $position == $sections[0]{'default'};

    print "Removed kernel $position.\n";
    return 1;

  } else {
    warn "WARNING:  problem removing entered position.\n";
    return undef;
  }

}


# Print info from config

sub print_info {
  my $self=shift;
  my $info=shift;

  return undef unless defined $info; 
  return undef unless $self->_check_config();

  print ("Printing config info.\n") if $self->debug()>1;

  my @config=@{$self->{config}};
  my @sections=$self->_info();

  my ($start,$end);
  if ($info =~ /default/i) {
    $start=$end=$self->get_default()
  } elsif ($info =~ /all/i) {
    $start=0; $end=$#sections-1
  } elsif ($info =~ /^\d+/) {
    $start=$end=$info
  } else {
    warn "ERROR:  input should be: #, default, or all.\n";
    return undef;
  }

  if ($start < 0 || $end > $#sections-1) {
    warn "ERROR:  No kernels with that index.\n";
    return undef;
  }

  for my $index ($start..$end) {
    print "\nindex\t: $index\n";
    $index++;
    foreach ( sort keys(%{$sections[$index]}) ) {
      print "$_\t: $sections[$index]{$_}\n";
    }
  }
}


# Set/get debug level

sub debug {
  my $self=shift;
  if (@_) {
      $self->{debug} = shift;
  }
  return $self->{debug} || 0;
}

# Get a bootloader entry as a hash to edit or update.
sub read_entry {
  my $self=shift;
  my $entry=shift;

  if ($entry !~ /^\d+$/) {
    $entry = $self->_lookup($entry);
  }
  my @sections=$self->_info();

  my $index = $entry + 1;
  if ((defined $sections[$index]{'title'})) {
    $self->{'entry'}->{'index'} = $index;
    foreach my $key ( keys %{$sections[$index]} ){
      $self->{'entry'}->{'data'}->{ $key } = $sections[$index]{$key};
    }
    return $self->{'entry'}->{'data'};
  } else {
    return undef;
  }
}

# Basic check for valid config

sub _check_config {
  my $self=shift;

  print ("Verifying config.\n") if $self->debug()>3;

  if ($#{$self->{config}} < 5) {
    warn "ERROR:  you must read a valid config file first.\n";
    return undef;
  }
  return 1;
}


# lookup position using title

sub _lookup {
  my $self=shift;
  my $title=shift;
  
  unless ( defined $title ){ return undef; }

  my @sections=$self->_info();

  for my $index (1..$#sections) {
    my $tmp = $sections[$index]{title};
    if (defined $tmp and $title eq $tmp) {
      return $index-1;
    }
  }
  return undef;
}


=head1 AUTHOR

Jason N., Open Source Development Labs, Engineering Department <eng@osdl.org>

=head1 COPYRIGHT

Copyright (C) 2006 Open Source Development Labs
All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<boottool>, L<Linux::Bootloader::Grub>, L<Linux::Bootloader::Lilo>, 
L<Linux::Bootloader::Elilo>, L<Linux::Bootloader::Yaboot>

=cut


1;
