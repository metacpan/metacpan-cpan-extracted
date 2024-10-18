package File::SharedVar;

=head1 NAME

File::SharedVar - Pure-Perl extension to share variables between Perl processes using files and file locking for their transport

=head1 SYNOPSIS

  use File::SharedVar;

  # Create a new shared variable object
  my $shared_var = File::SharedVar->new(
    file   => '/tmp/ramdisk/sharedvar.dat',
    create => 1,  # Set to 1 to create or truncate the file
  );

  # Update a key
  my $previous_value = $shared_var->update('foo', 1, 1); # Increment 'foo' by 1

  # Read a key
  my $value = $shared_var->read('foo');
  print "Value of foo: $value\n";


=head1 DESCRIPTION

File::SharedVar provides an object-oriented interface to share variables between Perl processes using a file as shared storage, with working cross-platform file locking mechanisms to ensure data integrity in concurrent environments.

It allows you to read, update, and reset shared variables stored in a file (uses JSON format), making it easy to coordinate between multiple processes.

This module was written to serve as a functioning alternative to the incomplete and unmaintained "IPC::Shareable" module which has multiple unfixed bugs reported against it (and which shreds your shared memory under long-running processes)

=head2 CAUTION

This module relies on your filesystem properly supporting file locking (and your selection of a lockfile on that filesystem), which is not the case for Windows Services for Linux (WSL1 and WSL2) nor their "lxfs" filesystem.  The bug has been reported to Microsoft.

The "test" phase of installing this module, when run on a system with broken locking, may take an extended amount of time to fail (many minutes or even hours).

A future version of this module is planned, optionally using a lockfile as a mutex for WSL, because flock() does not work properly in WSL1, WSL2, or their lxfs file systems (randomly throws "invalid argument" on seek() calls under heavy load).

=head2 WSL workaround

The mounted windows NTFS file system does support locking under WSL - use a lockfile on one of your "drvfs" (e.g. C: or /mnt/c) to have this module work properly there.

=cut

use strict;
use warnings;
use Fcntl qw(:DEFAULT :flock LOCK_EX LOCK_UN LOCK_NB O_RDWR O_EXCL O_CREAT);
#use Fcntl ':flock';   # For using O_EXCL and O_CREAT constants
#use Fcntl qw(:DEFAULT :flock O_EXCL O_CREAT O_RDWR); # Ensure proper constants are imported

#my($LOCK_EX,$LOCK_UN,$LOCK_NB,$O_RDWR)=(2,8,4,2); # These are required, because the $LOCK_* constants are sometimes not numbers, and inconveniently require "no strict 'subs';"
my($LOCK_EX,$LOCK_UN,$LOCK_NB,$O_RDWR,$O_EXCL,$O_CREAT)=(0+LOCK_EX,0+LOCK_UN,0+LOCK_NB,0+O_RDWR,0+O_EXCL,0+O_CREAT); # Avoid no strict 'subs' and nonnumber issues

our $VERSION = '1.00';
our $DEBUG = 0;

eval {
  require JSON::XS;
  JSON::XS->import; 1;
} or do {
  require JSON;
  JSON->import;
};

#my $json_text = encode_json($data);
#my $decoded_data = decode_json($json_text);

=head1 METHODS



=head2 new

  my $shared_var = File::SharedVar->new(%options);

Creates a new `File::SharedVar` object.

=over 4

=item *

C<file>: Path to the shared variable file. Defaults to C</tmp/sharedvar$$.dat>.
C<mutex>: set this key to 'lock' to use file-existance locking instead of just flock(). Uses C<file.lock> for locking.

=item *

C<create>: If true (non-zero), the file will be created if it doesn't exist or truncated if it does. Defaults to C<0>.

=back

=cut

sub new {
  my ($class, %args) = @_;
  my $self = {
    file   => $args{file}   // "/tmp/sharedvar$$.dat",
    fh     => undef,
  };

  bless $self, $class;

  if ($args{create}) {
    # Create or truncate the file
    open my $fh, '>', $self->{file} or die "Cannot open $self->{file}: $!";
    close $fh;
  } elsif (!-f $self->{file}) {
    die $self->{file},": No such file";
  }
  $self->{lock}=$self->{file}.".lock" if($args{mutex} && $args{mutex} eq 'lock');
  return $self;
}



=head2 read

  my $value = $shared_var->read($key);

Reads the value associated with the given key from the shared variable file.

=over 4

=item *

C<$key>: The key whose value you want to read.

=back

Returns the value associated with the key, or C<undef> if the key does not exist.

=cut

sub read {
  my ($self, $key) = @_;
  my($data)= _load_from_file($self);
  return $data->{$key};
}



=head2 update

  my $new_value = $shared_var->update($key, $value, $increment);

Updates the value associated with the given key in the shared variable file.

=over 4

=item *

C<$key>: The key to update.

=item *

C<$value>: The value to set or increment by.

=item *

C<$increment>: If true (non-zero), increments the existing value by C<$value>; otherwise, sets the key to C<$value>.

=back

Returns the previous value associated with the key, from before the update.

=cut

sub update {
  my($self, $key, $val, $inc) = @_;
  my($data)= _load_from_file($self,1);
  my $ret = $data->{$key};

  # Update the value for the key
  if($inc) {
    $data->{$key} = ($data->{$key} // 0) + $val;
  } else {
    $data->{$key} = $val;
  }
  _save_to_file($self,$data);

  return $ret;
}



sub _load_from_file {
  my($self,$staylocked)=@_;

  if($self->{lock}) {
    sysopen($self->{lfh}, $self->{lock}, O_EXCL | O_CREAT ) or die "Cannot open $self->{lock}: $!";
    die "incomplete";
  }

  open $self->{fh}, '+<', $self->{file} or die "$$ Cannot open $self->{file}: $!";
  #sysopen($self->{fh}, $self->{file}, $O_RDWR) or die "Cannot open $self->{file}: $!";

  my $data = {};

  &dbg( "$$ pre-lock" );
  flock($self->{fh}, $LOCK_EX) or die "$$ Cannot lock: $!";
  my $json_text = undef; do { local $/; $json_text=readline($self->{fh}) };
  #my $json_text = undef; do { local $/; my $fh=$self->{fh}; <$fh> };
  &dbg( "$$ post-lock d=$json_text" );
  #my $json_text; sysread($self->{fh},$json_text,65535); 
  $data = decode_json($json_text) if $json_text;
  unless($staylocked){  # LOCK_UN (unlock)
    flock($self->{fh}, $LOCK_UN) or die "$$ Cannot unlock: $!";
    $self->{fh}->close; $self->{fh}=undef;
    if($self->{lock}) {
      die "incomplete";
    }
  }
  return($data);
} # _load_from_file


sub _save_to_file {
  my ($self,$data) = @_;
  seek($self->{fh}, 0, 0) or die "$$ Cannot seek: $!";
  truncate($self->{fh}, 0) or die "$$ Cannot truncate $self->{file} file: $!";
  print { $self->{fh} } encode_json($data);
  #syswrite($self->{fh},encode_json($data));
  flock($self->{fh}, $LOCK_UN) or die "$$ Cannot unlock: $!";  # LOCK_UN (unlock)
  $self->{fh}->close; $self->{fh}=undef; 
  if($self->{lock}) {
    die "incomplete";
  }
} # _save_to_file


sub _open_lock {
  my($self)=@_;
  my $i=0;
  while($i++<9999) {
    sysopen($self->{fh}, $self->{file}, $O_RDWR) or die "Cannot open $self: $!";
    
  }
}



sub dbg {
  if($DEBUG) {
    my $message = shift;
    my ($package, $filename, $line) = caller;
    print STDERR "$message at $filename line $line.\n";
  }
}






1; # End of File::SharedVar

__END__

=head1 EXPORT

None by default.

=head1 DEPENDENCIES

This module requires these other modules and libraries:

  JSON (either JSON::XS or JSON::PP)
  Fcntl

=head1 SOURCE / BUG REPORTS

Please report any bugs or feature requests on the GitHub repository at:

L<https://github.com/gitcnd/File-SharedVar>

=head1 AUTHOR

This module was written by Chris Drake E<lt>cdrake@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2024 Chris Drake. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

# perl -MPod::Markdown -e 'Pod::Markdown->new->filter(@ARGV)' lib/File/SharedVar.pm  > README.md
