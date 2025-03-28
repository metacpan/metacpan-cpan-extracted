package IPC::XPA;

# ABSTRACT: Interface to the XPA messaging system

use strict;
use warnings;

our $VERSION = '0.16';

use parent 'DynaLoader';

bootstrap IPC::XPA $VERSION;

use Carp;

use namespace::clean;


# default attributes for Get, Set, Info, Access
my %def_attrs = ( max_servers => 1000, mode => {} );

sub _flatten_mode {
    my ( $mode ) = @_;

    return q{} unless keys %$mode;

    join( q{,}, map { "$_=" . $mode->{$_} } keys %$mode );
}





























sub Open {
    my ( $class, $mode ) = @_;
    $class = ref( $class ) || $class;

    # _Open will bless $xpa into the IPC::XPA class, but
    # need to worry about inheritance.
    my $xpa = _Open( _flatten_mode( $mode ) );
    bless { xpa => $xpa }, $class;
}










sub Close {
    my $xpa = shift;
    _Close( $xpa->{xpa} ) if defined $xpa->{xpa};
    undef $xpa->{xpa};
}

sub DESTROY {
    $_[0]->Close;
}
































































sub Get {
    my $obj = shift;

    my $attrs = 'HASH' eq ref $_[-1] ? pop @_ : {};

    @_ == 2
      or croak( 'usage: IPC::XPA->Get( $template, $paramlist [,\%attrs]' );

    my ( $template, $paramlist ) = @_;

    my %attrs = ( %def_attrs, %$attrs );

    # if called as a class method (ref($obj) not defined)
    # create an essentially NULL pointer for pass to XPAGet
    my $xpa = ref( $obj ) ? $obj->{xpa} : nullXPA();

    _Get( $xpa, $template, $paramlist, _flatten_mode( $attrs{mode} ), $attrs{max_servers} );
}








































































sub Set {
    my $obj = shift;

    my $attrs = 'HASH' eq ref $_[-1] ? pop @_ : {};

    @_ == 2 || @_ == 3
      or croak( 'usage: IPC::XPA->Set( $template, $paramlist [, [$buf],[\%attrs]]' );

    my $template  = shift;
    my $paramlist = shift;

    my %attrs = ( %def_attrs, %$attrs );

    # we want a reference to the data to avoid copying it.
    # if it's already a reference, use that directly, else
    # make one.  also, if no buffer was passed, make an empty one.
    my $valref
      = @_ && defined $_[0] ? ( ref( $_[0] ) ? $_[0] : \( $_[0] ) ) : \( q{} );

    $attrs{len} = length( $$valref ) unless defined $attrs{len};

    # if called as a class method (ref($obj) not defined)
    # create an essentially NULL pointer for pass to XPAGet
    my $xpa = ref( $obj ) ? $obj->{xpa} : nullXPA();

    _Set( $xpa, $template, $paramlist, _flatten_mode( $attrs{mode} ),
        $$valref, $attrs{len}, $attrs{max_servers} );
}















































sub Info {
    my $obj = shift;

    my $attrs = 'HASH' eq ref $_[-1] ? pop @_ : {};

    @_ == 2
      or croak( 'usage: IPC::XPA->Info( $template, $paramlist [,\%attrs]' );

    my ( $template, $paramlist ) = @_;

    my %attrs = ( %def_attrs, %$attrs );

    # if called as a class method (ref($obj) not defined)
    # create an essentially NULL pointer for pass to XPAGet
    my $xpa = ref( $obj ) ? $obj->{xpa} : nullXPA();

    _Info( $xpa, $template, $paramlist, _flatten_mode( $attrs{mode} ), $attrs{max_servers} );
}
































sub Access {
    my $obj = shift;

    my $attrs = 'HASH' eq ref $_[-1] ? pop @_ : {};

    @_ == 1 || @_ == 2
      or croak( 'usage: IPC::XPA->Access( $template, [,$paramlist] [,\%attrs]' );

    my ( $template, $paramlist ) = @_;

    my %attrs = ( %def_attrs, %$attrs );

    # if called as a class method (ref($obj) not defined)
    # create an essentially NULL pointer for pass to XPAGet
    my $xpa = ref( $obj ) ? $obj->{xpa} : nullXPA();

    _Access( $xpa, $template, $paramlist, _flatten_mode( $attrs{mode} ), $attrs{max_servers} );
}
































sub NSLookup {
    my $obj = shift;

    @_ == 2
      || croak( 'usage: IPC::XPA->NSLookup( $template, $type)' );

    # if called as a class method (ref($obj) not defined)
    # create an essentially NULL pointer for pass to XPAGet
    my $xpa = ref( $obj ) ? $obj->{xpa} : nullXPA();

    _NSLookup( $xpa, @_ );
}

#
# This file is part of IPC-XPA
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

IPC::XPA - Interface to the XPA messaging system

=head1 VERSION

version 0.16

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

Only the client side routines are accessible.

=head2 Methods

Unless otherwise specified, the class and instance methods are simple
wrappers around the similarly named XPA routines (just prefix the Perl
routines with C<XPA>).

=head2 The XPA Library

The XPA library is available via the L<Alien::XPA> Perl module on CPAN,
as well as at L<https://github.com/ericmandel/xpa>.

=head1 CONSTRUCTORS

=head2 nullXPA

 $xpa = IPC::XPA->nullXPA;

This creates an xpa object which is equivalent to a NULL XPA handle as
far as the underlying XPA routines are concerned.  It can be used to
create a default XPA object, as it it guaranteed to succeed (the
B<Open()> method may fail).

=head2 Open

 $xpa = IPC::XPA->Open();
 $xpa = IPC::XPA->Open( \%mode );

This creates an XPA object.  C<mode> is a hash containing mode
keywords and values, which will be translated into the string form
used by B<XPAOpen()>.  The object will be destroyed when it goes out
of scope; the B<XPAClose()> routine will automatically be called.  It
returns B<undef> upon failure.

For example,

 $xpa = IPC::XPA->Open( { verify => 'true' } );

=head1 CLASS METHODS

=head2 Get

The B<Get> instance method (see L</METHODS>) can also be
called as a class method, which is equivalent to calling
B<XPAGet()> with a C<NULL> handle to the B<xpa> object.

For example,

 %res = IPC::XPA->Get( $template, $paramlist );

=head2 Set

The B<Set> instance method (see L</METHODS>) can also be
called as a class method, which is equivalent to calling
B<XPASet()> with a C<NULL> handle to the B<xpa> object.

For example,

 %res = IPC::XPA->Set( $template, $paramlist );

=head2 Info

The B<Info> instance method (see L</METHODS>) can also be
called as a class method, which is equivalent to calling
B<XPAInfo()> with a C<NULL> handle to the B<xpa> object.

For example,

 %res = IPC::XPA->Info( $template, $paramlist );

=head2 Access

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

=head2 NSLookup

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

=head1 METHODS

=head2 Close

 $xpa->Close;

Close the XPA object.  This is usually not necessary, as it will
automatically be closed upon destruction.

=head2 Get

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
             'buf' => 'quit: -- exit application'
           }
         };

=head2 Set

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

=head2 Info

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

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-ipc-xpa@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=IPC-XPA>

=head2 Source

Source is available at

  https://gitlab.com/djerius/ipc-xpa

and may be cloned from

  https://gitlab.com/djerius/ipc-xpa.git

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
