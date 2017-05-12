package GetRc;
require 5.002;
require Exporter;

#use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use File::Basename;
use UNIVERSAL qw(isa);
use Carp;
use IO::File;
use Fcntl qw(:DEFAULT :flock); # import LOCK_* constants


### my initial version was 0.13
### version 0.20 is first OO ( Object Oriented of course )
$VERSION = '0.23';

@ISA = qw(Exporter);

# Items to export into callers namespace by default
@EXPORT =	qw();

# Other items we are prepared to export if requested
@EXPORT_OK =	qw();


sub new {
	my $type = shift;
	my $class = ref($type) || $type;
	croak "Usage $class->new (filename)" if ( @_ != 1 ) ;
	my $self = {};
	bless $self, $class;

	$self->{'filename'} = shift;

	$self->_init;
	$self->_find_file;

	return($self);
}

sub _find_file {
  my $self = shift;

  foreach (  @{$self->{'find_path'}} ) {
    last if ( $self->{'filename'} =~ /^\//);
    $self->{'filename'} = "$_".$self->{'filename'},last if ( -e "$_".$self->{'filename'}) ;
  }
  $self->dprint("file is " . $self->{'filename'});

}

sub _init {
  my $self = shift;
  my ( $filename,$dirname ) = fileparse($0);
  $self->{'ifs'} = '\s*=\s*';
  $self->{'ofs'} = ' = ';
  $self->{'debug'} = 0;
  $self->{'multivalues'} = 1;
  $self->{'lock'} = 1;
  $self->{'locktimeout'} = 15;
  $self->{'find_path'} = [
                           "./",
                           (getpwuid($>))[7]."/",
                           $dirname,
                           "../",
                           "/usr/local/etc/",
                         ];

  bless $self->{'find_path'};

  return($self);
}

sub writerc ($\%) {
  my $self = shift;
  local *h_input = shift;
  my ($rc);

  $self->dprint("join to writerc");
  ### locking ? uff .. this a bit messy code
  if ( $self->{'lock'} ) {
    eval {
      local $SIG{ALRM} = sub { die "File lock timeouted\n" };
      alarm($self->{'locktimeout'});
      $self->dprint("openning file ".$self->{'filename'});
      $rc = new IO::File $self->{'filename'}, O_CREAT|O_WRONLY|O_TRUNC;
      croak "Can't open file\n" unless ( defined $rc );
      $self->dprint("locking file ".$self->{'filename'});
      flock($rc,LOCK_EX);
      $self->dprint($self->{'filename'} . " locked");
      alarm(0);
    };

  if ($@) {
    return(-3),$self->dprint("File lock timeouted\n") if $@ eq "File lock timeouted\n";
    return(-4),$self->dprint("Can't open file ".$self->{'filename'}) if $@ eq "Can't open file\n";
  }   

  } else {
    $self->dprint("openning file ".$self->{'filename'});
    $rc = new IO::File $self->{'filename'}, O_CREAT|O_WRONLY|O_TRUNC;
    croak "Can't open file ".$self->{'filename'}." : $!" unless ( defined $rc );
  }

  my $separator = $self->{'ofs'};

    while (($key,$value) = each %h_input) {
      print $rc "$key${separator}$value\n";
      print "HEY: $key => $value\n";
    }
  flock($rc,LOCK_UN),$self->dprint( $self->{'filename'} ." unlocked") if ( $self->{'lock'} );
  $rc->close;
  croak "Can't close file ".$self->{'filename'} .": $1" if $?;
  $self->dprint( $self->{'filename'} ." closed");
  return(0);

}

sub getrc ($\%){
  my $self = shift;
  local *h_input = shift;
  my ( $key, $value, $rc);

  $self->dprint("join to getrc");
  $self->dprint("file ".$self->{'filename'}." doesn't exist"),return(-1) unless ( -e $self->{'filename'} );
  $self->dprint("Can't read file ".$self->{'filename'}),return(-2) unless ( -r $self->{'filename'} || -R $self->{'filename'} );

  ### locking ? uff .. this a bit messy code
  if ( $self->{'lock'} ) {
    eval {
      local $SIG{ALRM} = sub { die "File lock timeouted\n" };
      alarm($self->{'locktimeout'});
      $self->dprint("openning file ".$self->{'filename'});
      $rc = new IO::File $self->{'filename'}, O_RDONLY;
      croak "Can't open file ".$self->{'filename'}." : $!" unless  ( defined $rc );
      $self->dprint("locking file ".$self->{'filename'});
      flock($rc,LOCK_EX);
      $self->dprint($self->{'filename'} . " locked");
      alarm(0);
    };

  if ($@) {
    $self->dprint("File lock timeouted\n") if $@ eq "File lock timeouted\n";
    return(-3);
  }   

  } else {
    $self->dprint("openning file ".$self->{'filename'});
    $rc = new IO::File $self->{'filename'}, O_RDONLY;
    croak "Can't open file ".$self->{'filename'}." : $!" unless ( defined $rc );
  }

  my $separator = $self->{'ifs'};

    while (<$rc>) {
      chomp;
      #### Skip blank text entry fields and comment
      next if ( /^\s*#/ || /^\s*$/ || /^\s*\;/);

      #### Allow for multiple line values 
      if (s/\\$//) {
        $_ .= <$rc>;
        redo;
      }
      
      ($key,$value) = /\s*(.*?)${separator}(.*)/;

      ### skip empty keys
      $self->dprint("skip line: $_"),next if ( !defined($value) || !$key );
      
      #### Allow for multiple values of a single name
      if ($h_input{"$key"} && $self->{'multivalues'}) {
        $h_input{"$key"} .= ", " ;
        $h_input{"$key"} .= $value;
      } else {
        $h_input{"$key"} = $value;
      }
    }
  flock($rc,LOCK_UN),$self->dprint( $self->{'filename'} ." unlocked") if ( $self->{'lock'} );
  $rc->close;
  croak "Can't close file ".$self->{'filename'} .": $1" if $?;
  $self->dprint( $self->{'filename'} ." closed");
  return(0);
}

sub updaterc ($\%){
  my $self = shift;
  local *h_input = shift;
  my ( $key, $value, $rc, %update_input);

  $self->dprint("join to updaterc");
  $self->dprint("WARN: file ".$self->{'filename'}." doesn't exist") unless ( -e $self->{'filename'} );
  $self->dprint("WARN: Can't read file ".$self->{'filename'}) unless ( -r $self->{'filename'} || -R $self->{'filename'} );

  ### locking ? uff .. this a bit messy code
  if ( $self->{'lock'} ) {
    eval {
      local $SIG{ALRM} = sub { die "File lock timeouted\n" };
      alarm($self->{'locktimeout'});
      $self->dprint("openning file ".$self->{'filename'});
      $rc = new IO::File $self->{'filename'}, O_RDWR|O_CREAT;
      croak "Can't open file\n" unless ( defined $rc );
      $self->dprint("locking file ".$self->{'filename'});
      flock($rc,LOCK_EX);
      $self->dprint($self->{'filename'} . " locked");
      alarm(0);
    };

  if ($@) {
    return(-3),$self->dprint("File lock timeouted\n") if $@ eq "File lock timeouted\n";
    return(-4),$self->dprint("Can't open file ".$self->{'filename'}) if $@ eq "Can't open file\n";
    
  }   

  } else {
    $self->dprint("openning file ".$self->{'filename'});
    $rc = new IO::File $self->{'filename'}, O_RDWR|O_CREAT;
    croak "Can't open file ".$self->{'filename'}." : $!" unless ( defined $rc );
  }

  my $separator = $self->{'ifs'};

    while (<$rc>) {
      chomp;
      #### Skip blank text entry fields and comment
      next if ( /^\s*#/ || /^\s*$/ || /^\s*\;/);

      #### Allow for multiple line values 
      if (s/\\$//) {
        $_ .= <$rc>;
        redo;
      }
      
      ($key,$value) = /\s*(.*?)${separator}(.*)/;

      ### skip empty keys
      $self->dprint("skip line: $_"),next if ( !defined($value) || !$key );
      
      #### Allow for multiple values of a single name
      if ($update_input{"$key"} && $self->{'multivalues'}) {
        $update_input{"$key"} .= ", " ;
        $update_input{"$key"} .= $value;
      } else {
        $update_input{"$key"} = $value;
      }
    }

  while (($key,$value) = each %h_input) {
    $update_input{"$key"} = $value;
  }

  $separator = $self->{'ofs'};

  seek($rc,0,0);
  truncate($rc,0);

  while (($key,$value) = each %update_input) {
    print $rc "$key${separator}$value\n";
  }


  flock($rc,LOCK_UN),$self->dprint( $self->{'filename'} ." unlocked") if ( $self->{'lock'} );
  $rc->close;
  croak "Can't close file ".$self->{'filename'} .": $1" if $?;
  $self->dprint( $self->{'filename'} ." closed");
  return(0);
}

sub configure {
	my $self = shift;
	my (%arg) = @_;

	foreach (keys %arg) {
		$self->{"$_"} = $arg{$_};
	}

	bless $self->{'find_path'};
	return($self);
}

sub dprint {
  my $self = shift;
  my $debug_output = shift;
  my $filename = $self->{'filename'};
  return(0) unless $self->{'debug'};
  print STDERR <<EOM;
  ==> PID:$$\t$debug_output
  
EOM
}

sub AUTOLOAD {
  my $self = shift;
  my $value = shift;
  my ($name) = $AUTOLOAD;

  ($name) = ( $name =~ /^.*::(.*)/);

  $self->{$name} = $value if ( defined $value );

  ### find file location
  $self->_find_file if ( $value && ($name eq 'filename'));

  if ( ref($self->{$name}) =~ /ARRAY/ ) {
    return(@{$self->{$name}});
  } elsif (isa($self->{$name}, 'ARRAY')) {
    if ( wantarray ) {
      return(@{$self->{$name}});
    } else {
      return($self->{$name});
    }
  } else {
    return($self->{$name});
  }
}

sub push {
  my $self = shift;
  my $value = shift;

  return() unless (ref($self) !~ /ARRAY/ );

  push @{$self},$value;
  return($self);
}

sub unshift {
  my $self = shift;
  my $value = shift;

  return() unless (ref($self) !~ /ARRAY/ );

  unshift @{$self},$value;
  return($self);
}

sub pop {
  my $self = shift;

  return() unless (ref($self) !~ /ARRAY/ );

  pop @{$self};
}

sub shift {
  my $self = shift;

  return() unless (ref($self) !~ /ARRAY/ );

  shift @{$self};
}

sub DESTROY {}


1;
__END__

=head1 NAME

GetRc - A Module for reading configuration files

=head1 SYNOPSIS

  use GetRc;

  my $file = GetRc->new ("file_name");
  $file->ifs('\s*:\s*');
  my $result_get = $file->getrc(\%input);

  my $newfile = GetRc->new ("new_file_name");
  $newfile->ofs(' = ');
  my $result_wri = $newfile->writerc(\%input);

  my $updatefile = GetRc->new ("update_file_name");
  $updatefile->ifs('\s*:\s*');
  $updatefile->ofs(' = ');
  my $result_upd = $upadtefile->updaterc(\%input);

=head1 DESCRIPTION

This perl library provides reading, writing and updating configuration files
which is outside your Perl script.

The current version of GetRc.pm is available at

  http://rodney.alert.sk/perl/

=head1 INSTALLATION

To install this package, just change to the directory in which this
file is found and type the following:

	perl Makefile.PL
	make
	make test
	make install

This will copy GetRc.pm to your perl library directory for use by all
perl scripts.  You probably must be root to do this.   Now you can
load the GetRc routines in your Perl scripts with the line:

	use GetRc;

=head1 VERSION

  0.23

=head1 USE

=head2 Functions ( or Methods ? )

=over 4

=item new

	$file = GetRc->new($filename);

This creates a new GetRC object, using $filename, where $filename specified
(may be relative) path to filename.

For 'filename' looking in directories defined in $file->find_path. Default
find_path contain:

    ### actual directory
    "./",
    ### home directory
    (getpwuid($>))[7]."/",
    ### program directory by File::Basename::fileparse()
    $dirname,
    ### parent directory
    "../",
    ### default config directory
    "/usr/local/etc/"

You may redefine find_path with push, pop, shift and unshift methods.

=item getrc

	$retval = $file->getrc(\%input);
	
Fetch file content to %input.


=item writerc

	$retval = $file->writerc(\%input);

Write %input to 'filename' each entry per line.

=item updaterc

	$file = GetRc->new("filename");
	$retval = $file->updaterc(\%input);

Update specified file with %input. Get configuration fields from "filename",
update by %input and write to "filename".

=item ifs

	$file->ifs($ifs);

Definition Input Fields Separator. Default is used '\s*=\s*'. You may use
regex in this piece.

=item ofs

	$file->ofs($ofs);

Definition Output Fields Separator. Default is used ' = '. Don't use regex.

=item Other functions

	$file->configure (
		ifs => '\s*=\s*',
		ofs => ' : ',
		debug => 1,
		find_path => $array_ref,
		....
	);

	$file->find_path->push("value");
	$file->find_path->pop();
	$file->find_path->unshift("value");
	$file->find_path->shift();
	my @PATH = $file->find_path();

=back

=head1 Return codes

Return codes from getrc,writerc,updaterc:

   0  =  if everything is O.K
  -1  =  if 'filename' doesn't exist
  -2  =  if can't read 'filename'
  -3  =  if file lock timeouted
  -4  =  if can't open file for writing

Return codes from other functions ( methods ? ) is value

=head1 EXAMPLE

#!/usr/bin/perl

use GetRc;

$file = GetRc->new (".pinerc");
$file->configure(
	ifs => '\s*=\s*',
);

$file->getrc(\%input);

foreach ( keys %input ) {
  print "$_ -> $input{$_}\n";
}


=head1 DEBUG

	If $object->debug is set then print some debug informations on STDERR 
	$object->debug(1); ## default is 0 - no debug info

=head1 AUTHOR INFORMATION

Copyright 1997-2000 Jan 'Kozo' Vajda <Jan.Vajda@alert.sk>.  All rights
reserved.  It may be used and modified freely, but I do request that this
copyright notice remain attached to the file.  You may modify this module as
you wish, but if you redistribute a modified version, please attach a note
listing the modifications you have made.

Address bug reports and comments to:
Jan.Vajda@alert.sk

=head1 CREDITS

Thanks very much to:

=over 4

=item my wife Erika

for patience

=item mico ( mico@pobox.sk )

for inspiration

=item koleso ( tibor@pobox.sk )

for permanent discontent

=item milo ( milo@pobox.sk )

for background noise

=item Alert Security Group ( alert@alert.sk )

for some suggestions & solutions

=item O'Reilly and Associates, Inc

for my perl book :-{))

=item ...and many many more...

for many suggestions and bug fixes.

=back


=head1 SEE ALSO

L<IniConf> , L<perl(1)>

=cut


