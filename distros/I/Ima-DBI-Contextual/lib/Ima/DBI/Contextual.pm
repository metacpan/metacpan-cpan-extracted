
package Ima::DBI::Contextual;

use strict;
use warnings 'all';
use Carp 'confess';
use DBI;
use Digest::MD5 'md5_hex';
use Time::HiRes 'usleep';

our $VERSION = '1.006';

my $cache = { };
  
sub set_db
{
  my ($pkg)           = shift;
  $pkg                = ref($pkg) ? ref($pkg) : $pkg;
  my ($name)          = shift;
  my @dsn_with_attrs  = @_;
  my @dsn             = grep { ! ref($_) } @_;
  my ($attrs)         = grep { ref($_) } @_;
  my $default_attrs   = {
    RaiseError          => 1,
    AutoCommit          => 0,
    PrintError          => 0,
    Taint               => 1,
    AutoInactiveDestroy => 1,
  };
  map { $attrs->{$_} = $default_attrs->{$_} unless defined($attrs->{$_}) }
    keys %$default_attrs;
  
  @dsn_with_attrs = ( @dsn, $attrs );

  no strict 'refs';
  no warnings 'redefine';
  *{"$pkg\::db_$name"} = $pkg->_mk_closure( $name, \@dsn, $attrs );
  return;
}# end set_db()


sub _mk_closure
{
  my ($pkg, $name, $dsn, $attrs) = @_;
  
  return sub {
    my ($class) = @_;
    
    my @dsn = @$dsn;
    
    $attrs->{pid} = $$;
    my $key = $class->_context( $name, \@dsn, $attrs );
    my $dbh;
    if( $dbh = $cache->{$key}->{dbh} )
    {
      if( $class->_ping($dbh) )
      {
        # dbh belongs to this process and it's good:
        # YAY:
      }
      else
      {
        # dbh has gone stale.  reconnect:
        my $child_attrs = { %$attrs };
        my $clone = $dbh->clone($child_attrs);
        $dbh->{InactiveDestroy} = 1;
        undef($dbh);
        
        # Now - make sure that the clone worked:
        if( $class->_ping( $clone ) )
        {
          # This is a good clone - use it:
          $dbh = $cache->{$key}->{dbh} = $clone;
        }
        else
        {
          # The clone was no good - reconnect:
          $dbh = $cache->{$key}->{dbh} = DBI->connect_cached(@dsn, $attrs);
        }# end if()
      }# end if()
    }
    else
    {
      # We have not connected yet - engage:
      $dbh = $cache->{$key}->{dbh} = DBI->connect_cached(@dsn, $attrs);
    }# end if()
    
    # Finally:
    return $dbh;
  };
}# end _mk_closure()


sub _context
{
  my ($class, $name, $dsn, $attrs) = @_;
  
  my @parts = ($name );
  $attrs->{child_pid} = $$;
  eval { push @parts, threads->tid }
    if $INC{'threads.pm'};
  foreach( $dsn, $attrs )
  {
    if( ref($_) eq 'HASH' )
    {
      my $h = $_;
      push @parts, map {"$_=$h->{$_}"} sort keys %$h;
    }
    elsif( ref($_) eq 'ARRAY' )
    {
      push @parts, @$_;
    }
    else
    {
      push @parts, $_;
    }# end if()
  }# end foreach()
  
  return md5_hex(join ", ", @parts);
}# end _context()


sub _ping
{
  my ($class, $dbh) = @_;
  
  # Forgive the "If Slalom" - putting each condition on a separate line gives us
  # better error messages were one of them to fail:
  if( $dbh )
  {
    if( $dbh->FETCH('Active') )
    {
      if( $dbh->ping )
      {
        return $dbh;
      }# end if()
    }# end if()
  }# end if()
  
  
  return;
}# end _ping()


sub rollback
{
  my ($class) = @_;
  confess 'Deprecated';
  $class->db_Main->rollback;
}# end dbi_rollback()


sub commit
{
  my ($class) = @_;
  confess 'Deprecated';
  $class->db_Main->commit;
}# end dbi_commit()

1;# return true:

=pod

=head1 NAME

Ima::DBI::Contextual - Liteweight context-aware dbi handle cache and utility methods.

=head1 DEPRECATED

This module has been deprecated.  Do not use.

=head1 SYNOPSIS

  package Foo;
  
  use base 'Ima::DBI::Contextual';
  
  my @dsn = ( 'DBI:mysql:dbname:hostname', 'username', 'password', {
    RaiseError => 0,
  });
  __PACKAGE__->set_db('Main', @dsn);

Then, elsewhere:

  my $dbh = Foo->db_Main;
  
  # Use $dbh like you normally would:
  my $sth = $dbh->prepare( ... );

=head1 DESCRIPTION

If you like L<Ima::DBI> but need it to be more context-aware (eg: tie dbi connections to
more than the name and process id) then you need C<Ima::DBI::Contextual>.

=head1 RANT

B<Indications>: For permanent relief of symptoms related to hosting multiple mod_perl
web applications on one server, where each application uses a different database
but they all refer to the database handle via C<< Class->db_Main >>.  Such symptoms 
may include:

=over 4

=item * Wonky behavior which causes one website to fail because it's connected to the wrong database.

Scenario - Everything is going fine, you're clicking around walking your client through
a demo of the web application and then BLAMMO - B<500 server error>!  Another click and it's OK.  WTF?
You look at the log for Foo application and it says something like "C<Unknown method 'frobnicate' in package Bar::bozo>"

Funny thing is - you never connected to that database.  You have no idea B<WHY> it is trying to connect to that database.
Pouring over the guts in L<Ima::DBI> it's clear that L<Ima::DBI> only caches database
handles by Process ID (C<$$>) and name (eg: db_B<Main>).  So if the same Apache child
process has more than one application running within it and each application has C<db_Main> then 
I<it's just a matter of time before your application blows up>.

=item * Wondering for years what happened.

Years, no less.

=item * Not impressing your boss.

Yeah - it can happen - when you have them take a look at your new shumwidget and
instead of working - it I<doesn't> work.  All your preaching about unit tests and
DRY go right out the window when the basics (eg - connecting to the B<CORRECT FRIGGIN' DATABASE>) are broken.

=back

=head1 SEE ALSO

L<Ima::DBI>

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 LICENSE

This software is B<Free> software and may be used and redistributed under the same
terms as Perl itself.

=cut

