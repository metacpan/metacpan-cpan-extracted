package Linux::Bootloader::Grub;

=head1 NAME

Linux::Bootloader::Grub - Parse and modify GRUB configuration files.

=head1 SYNOPSIS

	use Linux::Bootloader;
	use Linux::Bootloader::Grub;

        my $config_file='/boot/grub/menu.lst';
	$bootloader = Linux::Bootloader::Grub->new($config_file);

        $bootloader->read();

	# add a kernel	
	$bootloader->add(%hash)

	# remove a kernel
	$bootloader->remove(2)

	# print config info
	$bootloader->print_info('all')

	# set new default
	$bootloader->set_default(1)

        $bootloader->write();


=head1 DESCRIPTION

This module provides functions for working with GRUB configuration files.

	Adding a kernel:
	- add kernel at start, end, or any index position.
	- kernel path and title are required.
	- root, kernel args, initrd, savedefault, module are optional.
	- any options not specified are copied from default.
	- remove any conflicting kernels first if force is specified.
	
	Removing a kernel:
	- remove by index position
	- or by title/label


=head1 FUNCTIONS

Also see L<Linux::Bootloader> for functions available from the base class.

=head2 new()

	Creates a new Linux::Bootloader::Grub object.

=head2 _info()

	Parse config into array of hashes.
	Takes: nothing.
	Returns: array of hashes containing config file options and boot entries,
                 undef on error.

=head2 set_default()

	Set new default kernel.
	Takes: integer or string, boot menu position or title.
	Returns: undef on error.

=head2 add()

	Add new kernel to config.
	Takes: hash containing kernel path, title, etc.
	Returns: undef on error.

=head2 update()

        Update args of an existing kernel entry.
        Takes: hash containing args and entry to update.
        Returns: undef on error.

=head2 install()

        Prints message on how to re-install grub.
        Takes: nothing.
        Returns: nothing.

=head2 update_main_options()

	This updates or adds a general line anywhere before the first 'title' line.
	it is called with the 'update' and 'option' options, when no 'update-kernel'
	is specified.

=head2 boot_once()

	This is a special case of using 'fallback'.   This function makes the current 
	default the fallback kernel and sets the passed argument to be the default 
	kernel which saves to the fallback kernel after booting.  The file 
	'/boot/grub/default' is created if it does not exist.

	This only works with grub versions 0.97 or better.

=head2 _get_bootloader_version()

        Prints detected grub version.
        Takes: nothing.
        Returns: nothing.

=cut

use strict;
use warnings;
use Linux::Bootloader

@Linux::Bootloader::Grub::ISA = qw(Linux::Bootloader);
use base 'Linux::Bootloader';


use vars qw( $VERSION );
our $VERSION = '1.2';


sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = bless({}, $class);
    #my $self = fields::new($class);

    $self->SUPER::new();

    return $self;
}

sub _set_config_file {
    my $self=shift;
    $self->{'config_file'}='/boot/grub/menu.lst';
}


### GRUB functions ###

# Parse config into array of hashes

sub _info {
  my $self=shift;

  return undef unless $self->_check_config();

  my @config=@{$self->{config}};
  @config=grep(!/^#|^\n/, @config);

  my %matches = ( default => '^\s*default\s*\=*\s*(\S+)',
		  timeout => '^\s*timeout\s*\=*\s*(\S+)',
		  fallback => '^\s*fallback\s*\=*\s*(\S+)',
		  kernel => '^\s*kernel\s+(\S+)',
		  root 	=> '^\s*kernel\s+.*\s+.*root=(\S+)',
		  args 	=> '^\s*kernel\s+\S+\s+(.*)\n',
		  boot 	=> '^\s*root\s+(.*)',
		  initrd => '^\s*initrd\s+(.*)',
		  savedefault => '^\s*savedefault\s+(.*)',
		  module      => '^\s*module\s+(.+)',
		);

  my @sections;
  my $index=0;
  foreach (@config) {
      if ($_ =~ /^\s*title\s+(.*)/i) {
        $index++;
        $sections[$index]{title} = $1;
      }
      foreach my $key (keys %matches) {
        if ($_ =~ /$matches{$key}/i) {
          $key .= '2' if exists $sections[$index]{$key};
          $sections[$index]{$key} = $1;
          if ($key eq 'args') {
	    $sections[$index]{$key} =~ s/root=\S+\s*//i;
	    delete $sections[$index]{$key} if ($sections[$index]{$key} !~ /\S/);
          }
        }
      }
  }

  # sometimes config doesn't have a default, so goes to first
  if (!(defined $sections[0]{'default'})) { 
    $sections[0]{'default'} = '0'; 

  # if default is 'saved', read from grub default file
  } elsif ($sections[0]{'default'} =~ m/^saved$/i) {
    open(DEFAULT_FILE, '/boot/grub/default')
      || warn ("ERROR:  cannot read grub default file.\n") && return undef;
    my @default_config = <DEFAULT_FILE>;
    close(DEFAULT_FILE);
    $default_config[0] =~ /^(\d+)/;
    $sections[0]{'default'} = $1;
  }

  # return array of hashes
  return @sections;
}


# Set new default kernel

sub set_default {
  my $self=shift;
  my $newdefault=shift;

  return undef unless defined $newdefault;
  return undef unless $self->_check_config();

  my @config=@{$self->{config}};
  my @sections=$self->_info();

  # if not a number, do title lookup
  if ($newdefault !~ /^\d+$/ && $newdefault !~ m/^saved$/) {
    $newdefault = $self->_lookup($newdefault);
    return undef unless (defined $newdefault);
  }

  my $kcount = $#sections-1;
  if ($newdefault !~ m/saved/) {
    if (($newdefault < 0) || ($newdefault > $kcount)) {
      warn "ERROR:  Enter a default between 0 and $kcount.\n";
      return undef;
    }
  }

  foreach my $index (0..$#config) {

    if ($config[$index] =~ /(^\s*default\s*\=*\s*)\d+/i) { 
      $config[$index] = "$1$newdefault	# set by $0\n"; 
      last;
    } elsif ($config[$index] =~ /^\s*default\s*\=*\s*saved/i) {
      my @default_config;
      my $default_config_file='/boot/grub/default';

      open(DEFAULT_FILE, $default_config_file) 
        || warn ("ERROR:  cannot open default file.\n") && return undef;
      @default_config = <DEFAULT_FILE>;
      close(DEFAULT_FILE);

      if ($newdefault eq 'saved') {
          warn "WARNING:  Setting new default to '0'\n";
          $newdefault = 0;
      }

      $default_config[0] = "$newdefault\n";

      open(DEFAULT_FILE, ">$default_config_file") 
        || warn ("ERROR:  cannot open default file.\n") && return undef;
      print DEFAULT_FILE join("",@default_config);
      close(DEFAULT_FILE);
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

  if (!defined $param{'add-kernel'} || !defined $param{'title'}) { 
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

  foreach my $p ('args', 'root', 'boot', 'savedefault') {
    if (! defined $param{$p}) {
      $param{$p} = $sections[$default]{$p};
    }
  }

  # use default entry to determine if path (/boot) should be removed
  if ($sections[$default]{'kernel'} !~ /^\/boot/) {
    $param{'add-kernel'} =~ s/^\/boot//;
    $param{'initrd'} =~ s/^\/boot// unless !defined $param{'initrd'};
  }

  my @newkernel;
  push(@newkernel, "title\t$param{title}\n") if defined $param{title};
  push(@newkernel, "\troot $param{boot}\n") if defined $param{boot};

  my $line;
  if ( defined $param{xen} ) {
      $line = "\tkernel $sections[$default]{kernel}";
      $line .= " $sections[$default]{root}" if defined $sections[$default]{root};
      $line .= " $sections[$default]{args}" if defined $sections[$default]{args};
      push( @newkernel, "$line\n" );
      push( @newkernel, "\tinitrd $sections[$default]{'initrd'}\n" ) if defined $sections[$default]{'initrd'};
      $line = "\tmodule $param{'add-kernel'}" if defined $param{'add-kernel'};
      $line .= " root=$param{root}"    if defined $param{root};
      $line .= " $param{args}"         if defined $param{args};
      push( @newkernel, "$line\n" );
      push( @newkernel, "\tmodule $param{initrd}\n" ) if defined $param{initrd};
  } else {
      $line = "\tkernel $param{'add-kernel'}" if defined $param{'add-kernel'};
      $line .= " root=$param{root}"    if defined $param{root};
      $line .= " $param{args}"         if defined $param{args};
      push( @newkernel, "$line\n" );
      push( @newkernel, "\tinitrd $param{initrd}\n" ) if defined $param{initrd};
  }

  push(@newkernel, "\tsavedefault $param{savedefault}\n") if defined $param{savedefault};

  foreach my $module (@{$param{'module'}}) {
     push(@newkernel, "\tmodule " . $module . "\n");
  }

  push(@newkernel, "\n");

  if (!defined $param{position} || $param{position} !~ /end|\d+/) { 
    $param{position}=0 
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
      if ($_ =~ /^\s*title/i) { 
        if ($index==$param{position}) { 
          push (@newconfig, @newkernel); 
        }
        $index++;
      }
      push (@newconfig, $_);
    }
  }

  @{$self->{config}} = @newconfig;

  if (defined $param{'make-default'} || defined $param{'boot-once'}) { 
    $self->set_default($param{position});
  }
  print "Added: $param{'title'}.\n";
}


# Update kernel args

sub update {
  my $self=shift;
  my %params=@_;

  print ("Updating kernel.\n") if $self->debug()>1;

  if (defined $params{'option'} && !defined $params{'update-kernel'}) {
    return $self->update_main_options(%params);
  } elsif (!defined $params{'update-kernel'} || (!defined $params{'args'} && !defined $params{'remove-args'} && !defined $params{'option'})) { 
    warn "ERROR:  kernel position or title (--update-kernel) and args (--args or --remove-args) required.\n";
    return undef; 
  }

  return undef unless $self->_check_config();

#  my @config = @{$self->{config}};
  my @sections=$self->_info();

  # if not a number, do title lookup
  if (defined $params{'update-kernel'} and $params{'update-kernel'} !~ /^\d+$/) {
    $params{'update-kernel'} = $self->_lookup($params{'update-kernel'});
  }

  my $kcount = $#sections-1;
  if ($params{'update-kernel'} !~ /^\d+$/ || $params{'update-kernel'} < 0 || $params{'update-kernel'} > $kcount) {
    warn "ERROR:  Enter a default between 0 and $kcount.\n";
    return undef;
  }

  my $kregex = '(^\s*kernel\s+\S+)(.*)';
  $kregex = '(^\s*module\s+\S+vmlinuz\S+)(.*)' if defined $params{'xen'};

  my $index=-1;
  my $config_line = -1;
  my $line = '';
  foreach $line (@{$self->{config}}) {
    $config_line = $config_line + 1;
    if ($line =~ /^\s*title/i) {
      $index++;
    }
    if ($index==$params{'update-kernel'}) {
      if (defined $params{'args'} or defined $params{'remove-args'}){
        if ( $line =~ /$kregex/i ) {
          my $kernel = $1;
          my $args = $2;
          $args =~ s/\s+$params{'remove-args'}(\=\S+|\s+|$)/ /ig if defined $params{'remove-args'};
          if ( defined $params{'args'} ) {
              my $base_arg = $params{'args'};
              $base_arg =~ s/\=.*//;
              $args =~ s/\s+$base_arg(\=\S+|\s+|$)/ /ig;
              $args = $args . " " . $params{'args'};
          }
          if ($line eq $kernel . $args . "\n") {
            warn "WARNING:  No change made to args.\n";
            return undef;
          } else {
            $line = $kernel . $args . "\n";
          }
          next;
        }
      } elsif (defined $params{'option'}){
        foreach my $val ( keys %params){
          if ($line =~ m/^\s*$val.*/i) {
            splice @{$self->{config}},$config_line,1,"$val $params{$val}\n";
            delete $params{$val};
            $config_line += 1;
          }
        }
      }
    } elsif ($index > $params{'update-kernel'}){
      last;
    }
  }
  # Add any leftover parameters
  delete $params{'update-kernel'};
  if (defined $params{'option'}){
    delete $params{'option'};
    $config_line -= 1;
    foreach my $val ( keys %params){
      splice @{$self->{config}},$config_line,0,"$val $params{$val}\n";
      $config_line += 1;
    }
  }
}


# Run command to install bootloader

sub install {
  my $self=shift;
  my $device;

  warn "Re-installing grub is currently unsupported.\n";
  warn "If you really need to re-install grub, use 'grub-install <device>'.\n";
  return undef;

  #system("grub-install $device");
  #if ($? != 0) {
  #  warn ("ERROR:  Failed to run grub-install.\n") && return undef;
  #}
  #return 1;
}


sub update_main_options{
  my $self=shift;
  my %params=@_;
  delete $params{'option'};
  foreach my $val (keys %params){
    my $x=0;
    foreach my $line ( @{$self->{config}} ) {
      # Replace 
      if ($line =~ m/^\s*$val/) {
	splice (@{$self->{config}},$x,1,"$val $params{$val}\n");
        last;
      }
      # Add
      if ($line =~ /^\s*title/i) {
        #  This is a new option, add it before here
        print "Your option is not in current configuration.  Adding.\n";
	splice @{$self->{config}},$x,0,"$val $params{$val}\n";
        last;
      }
      $x+=1;
    }
  }
}


sub boot_once {
  my $self=shift;
  my $entry_to_boot_once = shift;

  unless ( $entry_to_boot_once ) { print "No kernel\n"; return undef;}
  $self->read();
  my $default=$self->get_default();

  if ( $default == $self->_lookup($entry_to_boot_once)){
     warn "The default and once-boot kernels are the same.  No action taken.  \nSet default to something else, then re-try.\n";
     return undef;
  }
  if ( $self->_get_bootloader_version() < 0.97 ){
     warn "This function works for grub version 0.97 and up.  No action taken.  \nUpgrade, then re-try.\n";
     return undef;
  }

  $self->set_default('saved');
  if ( ! -f '/boot/grub/default' ){
     open FH, '>/boot/grub/default'; 
     my $file_contents="default
#
#
#
#
#
#
#
#
#
#
# WARNING: If you want to edit this file directly, do not remove any line
# from this file, including this warning. Using `grub-set-default\' is
# strongly recommended.
";
    print FH $file_contents;
    close FH;
  }
  $self->set_default( "$entry_to_boot_once" );
  $self->update( 'option'=>'','fallback' => $default );
  $self->update( 'update-kernel'=>"$entry_to_boot_once",'option'=>'','savedefault' => 'fallback' );
  $self->update( 'update-kernel'=>"$default",'option'=>'', 'savedefault' => '' );
  $self->write();
  
}

sub _get_bootloader_version {
  my $self = shift;
  return `grub --version | sed 's/grub (GNU GRUB //' | sed 's/)//'`;
}


1;


=head1 AUTHOR

Open Source Development Labs, Engineering Department <eng@osdl.org>

=head1 COPYRIGHT

Copyright (C) 2006 Open Source Development Labs
All Rights Reserved.

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Linux::Bootloader>

=cut

