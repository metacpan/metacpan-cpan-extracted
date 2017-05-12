package Dua;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw();
@EXPORT_OK = qw(dua_create dua_free dua_errstr dua_settmout dua_open
		dua_modrdn dua_delete dua_close dua_moveto dua_add
		dua_modattr dua_delattr dua_find dua_show dua_attribute);

$VERSION = '2.2';

bootstrap Dua $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;

package Dua;

sub new
{
  my($type,$dsa,$port,$bind_dn,$bind_passwd) = @_;
  my $self = {};
  $self->{session} = dua_create();
  bless $self;
}

sub DESTROY
{
  my $self = shift;
  return undef unless defined $self->{session};
  dua_free($self->{session});
}

sub error
{
  my $self = shift;
  return "No Session" unless defined $self->{session};
  dua_errstr($self->{session});
}

sub settmout
{
  my($self, $seconds, $microseconds) = @_;

  return undef unless defined $self->{session};
  dua_settmout($self->{session},$seconds, $microseconds);
}

sub open
{
  my($self,$dsa,$port,$bind_dn,$bind_passwd) = @_;
  return undef unless defined $self->{session};
  $port = 0 unless defined $port;
  dua_open($self->{session},$dsa,$port,$bind_dn,$bind_passwd);
}

sub close
{
  my $self = shift;
  return undef unless defined $self->{session};
  dua_close($self->{session});
}

sub moveto
{
  my($self,$dn) = @_;
  return undef unless defined $self->{session};
  dua_moveto($self->{session},$dn);
}

sub modrdn 
{
  my($self,$dn,$newrdn) = @_;
  return undef unless defined $self->{session};
  dua_modrdn($self->{session},$dn,$newrdn);
}

sub delete
{
  my($self,$rdn) = @_;
  return undef unless defined $self->{session};
  dua_delete($self->{session},$rdn);
}

sub add
{
  my($self,$rdn,@args) = @_;
  return undef unless defined $self->{session};
  dua_add($self->{session},$rdn,@args);
}

sub modattr
{
  my($self,$rdn,@args) = @_;
  return undef unless defined $self->{session};
  dua_modattr($self->{session},$rdn,@args);
}

sub find
{
  my($self,$rdn,$filter,$scope,$all) = @_;
  return undef unless defined $self->{session};
  dua_find($self->{session},$rdn,$filter,$scope,$all);
}

sub show
{
  my($self,$rdn) = @_;
  return undef unless defined $self->{session};
  dua_show($self->{session},$rdn);
}

sub attribute
{
  my($self,$rdn,$attribute) = @_;
  return undef unless defined $self->{session};
  dua_attribute($self->{session},$rdn,$attribute);
}


__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Dua - DUA/Perl interface to an X.500 directory

=head1 SYNOPSIS

  use Dua;

=head1 DESCRIPTION

  This module provides a set of subroutines which allow a Perl script to
  access to the X.500 directory.

=head1 SUBROUTINES

  $dua = new Dua() 

      Creates a new instance of a Dua object.

  $dua->open($dsa, $port, $dn, $passwd)

      Open an association to the DSA  specified  in  dsa  and
      running  on  the  port specified by port. If no port is
      specified, then  duaperl  will  use  the  default  port
      number.  duaperl  will bind to the DSA as dn, using the
      credentials supplied in passwd. Currently, only  simple
      authentication is supported.

  $dua->error()

      This routine returns a description of the problem when an error
      occurs.

  $dua->settmout($seconds, $microseconds)

      This routine sets the asynchronous timeout value for
      all operations.  The default is 30 seconds.

  $dua->close()

      This routine closes the association to the X.500 DSA.

  $dua->moveto($dn)

      Move to the location in the DIT specified by dn.

  $dua->modrdn($rdn, $newrdn)

      Modify the object whose RDN is rdn to newrdn.

  $dua->delete($rdn)

      Delete the object specified by rdn from the DIT.

  $dua->add($rdn, %attrs)

      Add a new object to the DIT with an RDN of rdn with the
      attributes attrs.

  $dua->modattr($rdn, %attrs)

      Modify the object specified by rdn with the  attribute-
      value pairs in attrs. If a value is set to an empty string
      the associated attribute is deleted from the entry.

  $dua->show($rdn)

      Returns in an  associative  array  the  attribute-value
      pairs found in the object specified by rdn.

  $dua->attribute($rdn,$attribute)

      Returns an array of values for the specified attribute
      found in the object specified by rdn. 

      This method maybe used to retrieve binary attributes not
      accessible via the show method.

  $dua->find($rdn, $filter, $scope, $all)

      Returns in an associative array the attribute-value pairs found
      beneath the object specified by rdn. filter is a string
      representation of a filter to apply to the search.  A
      Backus-Naur Form definition is given below.  scope refers to how
      deep the search is to progress in the DIT. A value of 0
      specifies the immediate children of the object; a value of 1
      specifies the entire sub- tree beneath the object.  all refers
      to what will be returned in the associative array. A value of 0
      will return just the DN's of matching objects, keyed by their
      ordinality in the search response; a value of 1 specifies that
      the attribute-value pairs of all match- ing objects are to be
      returned.  This routine is used for non-leaf objects.

=head1 NOTES

 $dua->moveto() determines the path which is prepended to the rdn of all
 other functions. This simulates ``standing'' at a particular position
 in the DIT, and being able to specify DN's relative to the current
 position. If a fully-qualified DN is more appropriate for a
 particular call, begin the rdn string with an `@' character.

 The Backus-Naur Form (BNF) for the filter specified in dua_find()
 is as follows:

             <filter> ::= '(' <filtercomp> ')'
             <filtercomp> ::= <and> | <or> | <not> | <simple>
             <and> ::= '&' <filterlist>
             <or> ::= '|' <filterlist>
             <not> ::= '!' <filter>
             <filterlist> ::= <filter> | <filter> <filterlist>
             <simple> ::= <attributetype> <filtertype> <attributevalue>
             <filtertype> ::= '=' | '~=' | '<=' | '>='

=head1 RETURN VALUES

  All routines except $dua->show() and $dua->find() will return 1 on
  success, 0 otherwise. For those routines which return associative
  arrays ( $dua->show() and $dua->find() ), the array is returned
  empty if an error occurs. The description of the problem may be
  obtained by use of $dua->error().


=head1 AUTHOR

  Converted from duaperl Version 1.0a3 to a Perl 5 module by 
  Stephen Pillinger, School of Computer Science, 
  The University of Birmingham, UK.

  duaperl was written by Eric W. Douglas, California State University,
  Fresno.

=head1 SEE ALSO

perl(1), ldap(3).

=cut
