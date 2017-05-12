# --8<--8<--8<--8<--
#
# Copyright (C) 2000-2009 Smithsonian Astrophysical Observatory
#
# This file is part of IPC-XPA
#
# IPC-XPA is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--


package IPC::XPA;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use Data::Dumper;

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.10';

bootstrap IPC::XPA $VERSION;

# Preloaded methods go here.

# default attributes for Get, Set, Info, Access
my %def_attrs = ( max_servers => 1000, mode => {} );

sub _flatten_mode
{
  my ( $mode ) = @_;

  return '' unless keys %$mode;

  join( ',', map { "$_=" . $mode->{$_} } keys %$mode );
}

sub Open
{
  my ( $class, $mode ) = @_;
  $class = ref($class) || $class;

  # _Open will bless $xpa into the IPC::XPA class, but
  # need to worry about inheritance.
  my $xpa = _Open( _flatten_mode( $mode ) );
  bless { xpa => $xpa }, $class;
}

sub Close
{
  my $xpa = shift;
  _Close( $xpa->{xpa} ) if defined $xpa->{xpa};
  undef $xpa->{xpa};
}

sub DESTROY
{
  $_[0]->Close;
}


sub Get
{
  my $obj = shift;

  my $attrs = pop @_
    if 'HASH' eq ref $_[-1];

  @_ == 2 or
    croak( 'usage: IPC::XPA->Get( $template, $paramlist [,\%attrs]');

  my ( $template, $paramlist ) = @_;

  my %attrs = ( %def_attrs, $attrs ? %$attrs : () );

  # if called as a class method (ref($obj) not defined)
  # create an essentially NULL pointer for pass to XPAGet
  my $xpa = ref($obj) ? $obj->{xpa} : nullXPA();

  _Get($xpa, $template, $paramlist, 
       _flatten_mode( $attrs{mode} ),
       $attrs{max_servers} );
}

sub Set
{
  my $obj = shift;

  my $attrs = pop @_
    if 'HASH' eq ref $_[-1];

  @_ ==2 || @_ == 3 or 
  croak( 'usage: IPC::XPA->Set( $template, $paramlist [, [$buf],[\%attrs]]');

  my $template = shift;
  my $paramlist = shift;

  my %attrs = ( %def_attrs, $attrs ? %$attrs : () );

  # we want a reference to the data to avoid copying it.
  # if it's already a reference, use that directly, else
  # make one.  also, if no buffer was passed, make an empty one.
  my $valref = @_ && defined $_[0] ? ( ref($_[0]) ? $_[0] : \($_[0]) ) : \('');

  $attrs{len} = length($$valref) unless defined $attrs{len};

  # if called as a class method (ref($obj) not defined)
  # create an essentially NULL pointer for pass to XPAGet
  my $xpa = ref($obj) ? $obj->{xpa} : nullXPA();

  _Set($xpa, $template, $paramlist, 
       _flatten_mode( $attrs{mode} ),
       $$valref, $attrs{len}, $attrs{max_servers} );
}


sub Info
{
  my $obj = shift;

  my $attrs = pop @_
    if 'HASH' eq ref $_[-1];

  @_ == 2 or
    croak( 'usage: IPC::XPA->Info( $template, $paramlist [,\%attrs]');

  my ( $template, $paramlist ) = @_;

  my %attrs = ( %def_attrs, $attrs ? %$attrs : () );

  # if called as a class method (ref($obj) not defined)
  # create an essentially NULL pointer for pass to XPAGet
  my $xpa = ref($obj) ? $obj->{xpa} : nullXPA();

  _Info($xpa, $template, $paramlist, 
	_flatten_mode( $attrs{mode} ),
	$attrs{max_servers} );
}


sub Access
{
  my $obj = shift;

  my $attrs = pop @_
    if 'HASH' eq ref $_[-1];

  @_ == 1 || @_ == 2 or
    croak( 'usage: IPC::XPA->Access( $template, [,$paramlist] [,\%attrs]');

  my ( $template, $paramlist ) = @_;

  my %attrs = ( %def_attrs, $attrs ? %$attrs : () );

  # if called as a class method (ref($obj) not defined)
  # create an essentially NULL pointer for pass to XPAGet
  my $xpa = ref($obj) ? $obj->{xpa} : nullXPA();

  _Access($xpa, $template, $paramlist, 
	  _flatten_mode( $attrs{mode} ),
	  $attrs{max_servers} );
}

sub NSLookup
{
  my $obj = shift;

  @_ == 2 ||
    croak( 'usage: IPC::XPA->NSLookup( $template, $type)');

  # if called as a class method (ref($obj) not defined)
  # create an essentially NULL pointer for pass to XPAGet
  my $xpa = ref($obj) ? $obj->{xpa} : nullXPA();

  _NSLookup( $xpa, @_ );
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

IPC::XPA - Interface to the XPA messaging system

=head1 SYNOPSIS

  use IPC::XPA;

  $xpa = IPC::XPA->Open();
  $xpa = IPC::XPA->Open(\%mode);
  $xpa = IPC::XPA->nullXPA;


  %res = $xpa->Get( $template, $paramlist );
  %res = $xpa->Get( $template, $paramlist, \%attrs );

  %res = $xpa->Set( $template, $paramlist );
  %res = $xpa->Set( $template, $paramlist, $buf );
  %res = $xpa->Set( $template, $paramlist, $buf, \%attrs );
  %res = $xpa->Set( $template, $paramlist, \%attrs );

  %res = $xpa->Info( $template, $paramlist );
  %res = $xpa->Info( $template, $paramlist, \%attrs );

  %res = IPC::XPA->Access( $template, $paramlist );
  %res = IPC::XPA->Access( $template, $paramlist, \%attrs );

  @res = IPC::XPA->NSLookup( $template, $type );

=head1 DESCRIPTION

This class provides access to the XPA messaging system library,
C<xpa>, developed by the Smithsonian Astrophysical Observatory's High
Energy Astrophysics R&D Group.  The library provides simple
inter-process communication via calls to the C<xpa> library as well as
via supplied user land programs.

The method descriptions below do not duplicate the contents of the
documentation provided with the C<xpa> library.

Currently, only the client side routines are accessible.

=head1 METHODS

Unless otherwise specified, the following methods are simple wrappers
around the similarly named XPA routines (just prefix the Perl
routines with C<XPA>).


=head2 Class Methods

=over 8

=item nullXPA

	$xpa = IPC::XPA->nullXPA;

This creates an xpa object which is equivalent to a NULL XPA handle as
far as the underlying XPA routines are concerned.  It can be used to
create a default XPA object, as it it guaranteed to succeed (the
B<Open()> method may fail).


=item Open

	$xpa = IPC::XPA->Open();
	$xpa = IPC::XPA->Open( \%mode );

This creates an XPA object.  C<mode> is a hash containing mode
keywords and values, which will be translated into the string form
used by B<XPAOpen()>.  The object will be destroyed when it goes out
of scope; the B<XPAClose()> routine will automatically be called.  It
returns B<undef> upon failure.

For example,

	$xpa = IPC::XPA->Open( { verify => 'true' } );


=item Close

	$xpa->Close;

Close the XPA object.  This is usually not necessary, as it will
automatically be closed upon destruction.

=item Access

	%res = IPC::XPA->Access( $name [, $type] [, \%attr ] )

Returns a hash keyed off of the server names which match the specified
name and access type.  The hash values are references to hashes, which
will have the key C<name>, indicating the server's name (seems a bit
redundant).

C<%attr> is a hash with the following recognized keys:

=over 8

=item mode

The value for this element should be a hashref which will be flattened
to provide the correct format for the actual XPA B<Access> C<mode> parameter.

=item max_servers

This should be set to the maximum number of servers to return.  It defaults
to 1000.

=back

See the XPA docs for more information.  This may also be called as an
object method.

=item NSLookup

	@res = IPC::XPA->NSLookup( $template, $type )

This calls the XPANSLookup routine.  It returns the results of the
lookup as a list of references to hashes, one per server. The hashes
have the keys C<name> C<class>, and C<method>.  For example,

	use Data::Dumper;
	@res = IPC::XPA->NSLookup( 'ds9', 'ls' );
	print Dumper(\@res);

results in

	$VAR1 = [
	          {
	            'method' => '838e2ab4:46529',
	            'name' => 'ds9',
	            'class' => 'DS9'
	          }
	        ];

Note that names returned by B<NSLookup> are different than those
returned by the B<Set> and B<Get> methods; the latter return names
which are essentially composites of the C<name> and C<method> keys.

This may also be called as an object method.  See the XPA docs for
more information the C<template> and C<type> specification.

=item Set

The B<Set> instance method (see L<Instance Methods>) can also be
called as a class method, which is equivalent to calling
B<XPASet()> with a C<NULL> handle to the B<xpa> object.

For example,

	%res = IPC::XPA->Set( $template, $paramlist );

=item Get

The B<Get> instance method (see L<Instance Methods>) can also be
called as a class method, which is equivalent to calling
B<XPAGet()> with a C<NULL> handle to the B<xpa> object.

For example,

	%res = IPC::XPA->Get( $template, $paramlist );


=item Info

The B<Info> instance method (see L<Instance Methods>) can also be
called as a class method, which is equivalent to calling
B<XPAInfo()> with a C<NULL> handle to the B<xpa> object.

For example,

	%res = IPC::XPA->Info( $template, $paramlist );


=back

=head2 Instance Methods

=over 8

=item Set

	%res = $xpa->Set( $template, $paramlist );
	%res = $xpa->Set( $template, $paramlist, $buf );
	%res = $xpa->Set( $template, $paramlist, $buf, \%attrs );
	%res = $xpa->Set( $template, $paramlist, \%attrs );

Send data to the XPA server(s) specified by B<$template>.  B<$xpa> is
a reference to an XPA object created by C<Open()>. B<$paramlist>
specifies the command to be performed.  If additional information is
to be sent, the B<$buf> parameter should be specified.  The B<%attrs>
hash specifies optional parameters and values to be sent.  The
following are available:

=over 8

=item max_servers

The maximum number of servers to which the request should be sent. This
defaults to C<1>.

=item len

The number of bytes in the buffer to be sent.  If not set, the entire
contents will be sent.

=item mode

The value of this is a hash containing mode keywords and values, which
will be translated into the string form used by B<XPASet()>.

=back

It returns a hash keyed off of the server names.  The hash values are
references to hashes, which will contain the key C<name> (duplicating the
server name), and if there was an error, the key C<message>.  See the
B<XPASet> documentation for more information on the C<name> and
C<message> values.

For example,

	%res = $xpa->Set( 'ds9', 'mode crosshair' );

	use Data::Dumper;
	%res = $xpa->Set( 'ds9', 'array [dim=100,bitpix=-64]', $buf, 
			  { mode => { ack => false } });
	print Dumper \%res, "\n";

The latter might result in:

	$VAR1 = {
          'DS9:ds9 838e2ab4:65223' => {
                                        'name' => 'DS9:ds9 838e2ab4:65223'
                                      },
        };

=item Get

	%res = $xpa->Get( $template, $paramlist );
	%res = $xpa->Get( $template, $paramlist, \%attrs );

Retrieve data from the servers specified by the B<$template>
parameter.  B<$xpa> is a reference to an XPA object created by
C<Open()>.  The B<$paramlist> indicates which data to return.  The
B<%attrs> hash specifies optional parameters and values to be sent.
The following are available:

=over 8

=item max_servers

The maximum number of servers to which the request should be sent. This
defaults to C<1>.

=item mode

The value of this is a hash containing mode keywords and values, which
will be translated into the string form used by B<XPAGet()>

=back

It returns a hash keyed off of the server names.  The hash values are
references to hashes, which will have the keys C<name>, indicating the
server's name, and C<buf> which will contain the returned data.  If
there was an error, the hashes will also contain the key C<message>.
See the B<XPAGet> documentation for more information on the C<name>
and C<message> values.

For example,

	use Data::Dumper;
	%res = $xpa->Get( 'ds9', '-help quit' );
	print Dumper(\%res);

might result in

	$VAR1 = {
	         'DS9:ds9 838e2ab4:46529' => {
	            'name' => 'DS9:ds9 838e2ab4:46529',
	            'buf' => 'quit:	-- exit application'
	          }
	        };

=item Info

	%res = $xpa->Info( $template, $paramlist);
	%res = $xpa->Info( $template, $paramlist, \%attrs );

Send a short message (in B<$paramlist>) to the servers specified in
the B<$template> parameter.  B<$xpa> is a reference to an XPA object
created by C<Open()>. The B<%attrs> hash specifies optional parameters
and values to be sent.  The following are available:

=over 8

=item max_servers

The maximum number of servers to which the request should be sent. This
defaults to C<1>.

=item mode

The value of this is a hash containing mode keywords and values, which
will be translated into the string form used by B<XPAGet()>

=back

It returns a hash keyed off of the server names.  The hash values are
references to hashes, which will contain the the key C<name>,
indicating the server's name.  If there was an error or the server
replied with a message, the hashes will also contain the key
C<message>.  See the B<XPAGet> documentation for more information on
the C<name> and C<message> values.

=back

=head1 The XPA Library

The XPA library is available at C<http://hea-www.harvard.edu/RD/xpa/>.

=head1 LICENSE

This software is released under the GNU General Public License.  You
may find a copy at 

   http://www.fsf.org/copyleft/gpl.html

=head1 AUTHOR

Diab Jerius ( djerius@cfa.harvard.edu )

=head1 SEE ALSO

perl(1).

=cut
