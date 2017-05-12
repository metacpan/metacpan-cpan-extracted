# -*- perl -*-
#
#  Mail::Spool::Node - adpO - Mail::Spool inode encapsulization
#
#  $Id: Node.pm,v 1.1 2001/12/08 05:52:59 rhandom Exp $
#
#  Copyright (C) 2001, Paul T Seamons
#                      paul@seamons.com
#                      http://seamons.com/
#
#  This package may be distributed under the terms of either the
#  GNU General Public License
#    or the
#  Perl Artistic License
#
#  All rights reserved.
#
#  Please read the perldoc Mail::Spool::Node
#
################################################################

package Mail::Spool::Node;

use strict;
use vars qw($AUTOLOAD $VERSION);
use File::NFSLock 1.10 ();
use IO::File ();

$VERSION = $Mail::Spool::VERSION;

###----------------------------------------------------------------###

sub new {
  my $type  = shift;
  my $class = ref($type) || $type || __PACKAGE__;
  my $self  = @_ && ref($_[0]) ? shift() : {@_};

  bless $self, $class;

  if( ! $self->load_node_properties ){
    return undef;
  }

  return $self;
}

###----------------------------------------------------------------###

sub load_node_properties {
  my $node = shift;
  
  return undef if $node->name =~ /\.NFSLock$/i; # skip lock files
  return undef if $node->name =~ /^\.+$/;       # skip root directory nodes
  return undef if -d $node->filename;           # skip directories

  # looking for stuff like 995909015-80EA68E2D942BA85-forward@b.c-paul@seamons.com
  if( $node->name !~ /^(\d+)-([^\-]+)-([^\-]+)-([^\-]*)$/ ){
    die "Strange file found in spool dir \"".$node->filename."\"\n";
  }

  my($time,$message_id,$to_addr,$from_addr) = ($1,$2,$3,$4);
  $from_addr ||= ''; # allow for undeliverables

  ### unencode the to and from
  foreach ( $to_addr, $from_addr ){
    s/%([a-f0-9]{2})/chr(hex($1))/eig;
  }

  ### store some properties
  $node->time( $time );
  $node->id( $message_id );
  $node->to( $to_addr );
  $node->from( $from_addr );
  
  return 1;
}

###----------------------------------------------------------------###

### is this node up for processing
sub can_process {
  my $node = shift;

  die "No wait property found in mail spool handle"
    if ! defined $node->msh->wait;

  return (time() - $node->time >= $node->msh->wait);
}

sub size {
  my $node = shift;
  return -s $node->filename || 0;
}

###----------------------------------------------------------------###

### exclusive lock (NFS or not)
sub lock_node {
  my $node = shift;
  my $lock = File::NFSLock->new($node->filename,
                                "NONBLOCKING",
                                0,
                                ($node->msh->spool->max_connection_time+2),
                                );
  $node->{lock_error} = $File::NFSLock::errstr;
  return $lock;
}

sub lock_error {
  return shift()->{lock_error};
}

###----------------------------------------------------------------###

sub filehandle {
  my $node = shift;
  my $mode = shift;
  $mode = 'r' if ! $mode || $mode !~ /^(a|w|r|wr)$/;

  my $fh = IO::File->new($node->filename,$mode);

  if( ! $fh ){
    warn "Couldn't open file ".$node->filename." [$!]";
    return undef;
  }
  return $fh;
}

sub filename {
  my $node = shift;
  return $node->msh->spool_dir .'/'. $node->name;
}

sub fallback_filename {
  my $node = shift;
  my $name = join("-",time(),$node->id,$node->to,$node->from);
  return undef if ! defined $node->msh->fallback_dir;
  return $node->msh->fallback_dir .'/'. $name;
}

sub fallback {
  my $node = shift;
  
  if( ! rename($node->filename,
               $node->fallback_filename) ){
    warn "Couldn't rename ".$node->filename." to ".$node->fallback_filename." [$!]";
    unlink $node->filename; # maybe some more error checking
  }
}

sub delete_node {
  my $node = shift;
  unlink $node->filename;
}

###----------------------------------------------------------------###

sub AUTOLOAD {
  my $node = shift;
  my ($method) = $AUTOLOAD =~ /([^:]+)$/;
  die "No method found in \$AUTOLOAD \"$AUTOLOAD\"" unless defined $method;
  
  ### allow for dynamic installation of some subs
  if( $method =~ /^(to|from|id|time|msh|name)$/ ){
    no strict 'refs';
    * { __PACKAGE__ ."::". $method } = sub {
      my $self = shift;
      my $val = $self->{$method};
      $self->{$method} = shift if @_;
      return $val;
    };
    use strict 'refs';
    
    ### now that it is installed, call it again
    return $node->$method( @_ );
  }

  die "Unknown method \"$method\"";
}

sub DESTROY {}

1;



__END__


=head1 NAME

Mail::Spool::Node - Mail Spool inode encapsulization

=head1 SYNOPSIS

  #!/usr/bin/perl -w
  package MySpoolNode;

  use Mail::Spool::Node;
  @ISA = qw(Mail::Spool::Node);

  # OR

  sub new {
    my $self = __PACKAGE__->SUPER::new(@_);

    ### do my own stuff here

    return $self;
  }

=head1 DESCRIPTION

Mail::Spool::Node is intended as an encapsulization
of an inode for use by Mail::Spool::Handle.  It has been
written with the intent of being able to use a database
or other "file" system as a backend.

=head1 PROPERTIES

Properties of Mail::Spool::Node are accessed methods of
the same name.  They may be set by calling the
method and passing the new value as an argument.
For example:

  my $from = $self->from;
  $self->from($new_from);

The following properties are
available:

=over 4

=item to

Returns the "To" email address of this node.

=item from

Returns the "From" email address of this node.

=item id

Returns the message id of this node.

=item time

Returns the time this node was placed in the spool.

=item msh

Returns the mail spool handle that this node is in.

=item name

Returns the filename of this node in the mail spool handle
directory.

=back

=head1 METHODS

=over 4

=item new

Returns a Mail::Spool::Node object.  Arguments in
the form of a hash or hash ref are used to
populate the object.  Also calls load_node_properties.

=item can_process

Returns whether the node is eligible for processing.  This
is based upon how long it has been in the mail spool handle.

=item size

Returns the size of the node in bytes.

=item lock_node

Locks the node to prevent any other process from trying to write
to it.  This is done via File::NFSLock.  Returns the lock object.

=item lock_error

Returns the error of File::NFSLock should something happen during
the locking process.

=item filehandle

Returns an IO::Handle style object opened to the filename of this node.

=item filename

Returns the filename of this node.

=item fallback_filename

Returns the place to put this file in case the node could not
be sent right now.  Returns undef if fallback cannot proceed
(undeliverable).

=item fallback

Actually perform the fallback operation.

=item delete_node

Unlink the node from the directory.

=back

=head1 SEE ALSO

Please see also
L<Mail::Spool>,
L<Mail::Spool::Handle>.

=head1 COPYRIGHT

  Copyright (C) 2001, Paul T Seamons
                      paul@seamons.com
                      http://seamons.com/

  This package may be distributed under the terms of either the
  GNU General Public License
    or the
  Perl Artistic License

  All rights reserved.

=cut
