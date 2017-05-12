# -*- perl -*-
#
#  Mail::Spool::Handle - adpO - Mail::Spool directory encapsulization
#
#  $Id: Handle.pm,v 1.1 2001/12/08 05:52:59 rhandom Exp $
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
#  Please read the perldoc Mail::Spool::Handle
#
################################################################

package Mail::Spool::Handle;

use strict;
use vars qw($AUTOLOAD $VERSION);

$VERSION = $Mail::Spool::VERSION;

###----------------------------------------------------------------###

sub new {
  my $type  = shift;
  my $class = ref($type) || $type || __PACKAGE__;
  my $self  = @_ && ref($_[0]) ? shift() : {@_};

  return bless $self, $class;
}

###----------------------------------------------------------------###

### allow for opening up a spool
### this could be a directory, or
### db handle, etc
sub open_spool {
  my $msh = shift;
  die 'Usage: $msh->open_spool'
    if ! $msh || ! ref $msh;
  
  die 'Invalid Object: missing spool_dir property'
    unless defined $msh->spool_dir;

  die 'Invalid Object: missing wait property'
    unless defined $msh->wait;

  ### get a directory handle
  my $dh = do {local *_DH};
  if( ! opendir($dh, $msh->spool_dir) ){
    die "Couldn't open directory (".$msh->spool_dir.") [$!]";
  }
  $msh->dh( $dh );
  
  ### optional return
  return $dh;
}

sub next_node {
  my $msh = shift;

  ### read the next inode
  while ( defined(my $sub = readdir( $msh->dh )) ){
    
    ### instantiate a new object
    my $node = eval{ $msh->mail_spool_node(msh  => $msh,
                                           name => $sub,
                                           ) };
    ### check for errors
    if( $@ || ! $node ){
      # warn "Trouble creating node [$@]\n";
      next;
    }

    ### see if this is a good node 
    if( ! $node->can_process ){
      next;
    }

    ### all good
    return $node;
  }

  ### exit loop
  return undef;
}

sub mail_spool_node {
  my $self = shift;
  return Mail::Spool->mail_spool_node(@_);
}

###----------------------------------------------------------------###

sub AUTOLOAD {
  my $msh = shift;
  my ($method) = $AUTOLOAD =~ /([^:]+)$/;
  die "No method found in \$AUTOLOAD \"$AUTOLOAD\"" unless defined $method;
  
  ### allow for dynamic installation of some subs
  if( $method =~ /^(spool_dir|fallback_dir|wait|dh|spool)$/ ){
    no strict 'refs';
    * { __PACKAGE__ ."::". $method } = sub {
      my $self = shift;
      my $val = $self->{$method};
      $self->{$method} = shift if @_;
      return $val;
    };
    use strict 'refs';
    
    ### now that it is installed, call it again
    return $msh->$method( @_ );
  }

  die "Unknown method \"$method\"";
}

sub DESTROY {}

1;


__END__


=head1 NAME

Mail::Spool::Handle - Mail Spool directory encapsulization

=head1 SYNOPSIS

  #!/usr/bin/perl -w
  package MySpoolHandle;

  use Mail::Spool::Handle;
  @ISA = qw(Mail::Spool::Handle);

  # OR

  sub new {
    my $self = __PACKAGE__->SUPER::new(@_);

    ### do my own stuff here

    return $self;
  }

=head1 DESCRIPTION

Mail::Spool::Handle is intended as an encapsulization
of a directory for use by Mail::Spool.  It has been
written with the intent of being able to use a database
or other "file" system as a backend.

=head1 PROPERTIES

Properties of Mail::Spool::Handle are accessed methods of
the same name.  They may be set by calling the
method and passing the new value as an argument.
For example:

  my $spool_dir = $self->spool_dir;
  $self->spool_dir($new_spool_dir);

The following properties are
available:

=over 4

=item spool_dir

Path to the directory of this spool.

=item fallback_dir

Path to the directory of the fallback spool, used if
a node could could not be delivered.  If undef, it is
assumed that that message is undeliverable.

=item wait

Number of seconds which a node must be present in the
spool before it can be sent.

=item dh

An open directory handle to spool_dir.

=item spool

Return the spool that created this msh object.

=back

=head1 METHODS

=over 4

=item new

Returns a Mail::Spool::Handle object.  Arguments in
the form of a hash or hash ref are used to
populate the object.

=item open_spool

Opens a directory handle on spool_dir and
stores the result in dh.

=item next_node

Essentially does a readdir on the dh property.  Returns
a Mail::Spool::Node object.  Once there are no more nodes,
it returns undef.

=item mail_spool_node

Calls &Mail::Spool::mail_spool_node by default.  Returns
a Mail::Spool::Node.

=back

=head1 SEE ALSO

Please see also
L<Mail::Spool>,
L<Mail::Spool::Node>.

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
