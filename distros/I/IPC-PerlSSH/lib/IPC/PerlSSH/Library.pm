#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2008-2010,2016 -- leonerd@leonerd.org.uk

package IPC::PerlSSH::Library;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw( init func );
use Carp;

our $VERSION = '0.17';

=head1 NAME

C<IPC::PerlSSH::Library> - support package for declaring libraries of remote
functions

=head1 SYNOPSIS

 package IPC::PerlSSH::Library::Info;

 use strict;
 use IPC::PerlSSH::Library;

 func uname   => 'uname()';
 func ostype  => '$^O';
 func perlbin => '$^X';

 1;

This can be loaded by

 use IPC::PerlSSH;

 my $ips = IPC::PerlSSH->new( Host => "over.there" );

 $ips->use_library( "Info" );

 print "Remote perl is running from " . $ips->call("perlbin") . "\n";
 print " Running on a machine of type " . $ips->call("ostype") .
                                          $ips->call("uname") . "\n";

=head1 DESCRIPTION

This module allows the creation of pre-prepared libraries of functions which
may be loaded into a remote perl running via C<IPC::PerlSSH>.

All the code is kept in its own package in the remote perl. The package
declaration is performed in the remote perl, by including an optional block of
initialisation code, passed to the C<init()> function.

Typically this code could C<use> a perl module, or declare shared variables
or functions. Be careful when C<use>ing a module, as the remote perl executing
it may not have the same modules installed as the local machine, or even be of
the same version.

Note that C<our> variables will be available for use in stored code, but
limitations of the way perl's lexical scopes work mean that C<my> variables
will not. On versions of perl before 5.10, the variable will have to be
C<our>ed again in each block of code that requires it. On 5.10 and above, this
is not necessary; but beware that the code will not work on remote perls before
this version, even if the local perl is 5.10.

For example, consider the following small example:

 package IPC::PerlSSH::Library::Storage;

 use IPC::PerlSSH::Library;

 init q{
    our %storage;

    sub list  { keys %storage }
    sub clear { undef %storage }
 };

 func get   => q{ our %storage; return $storage{$_[0]} };
 func set   => q{ our %storage; $storage{$_[0]} = $_[1] };
 func clear => q{ clear() }
 func list  => q{ return list() }

 1;

=cut

my %package_funcs;

=head1 FUNCTIONS

=cut

=head2 func

   func( $name, $code )

Declare a function called $name, which is implemented using the source code in
$code. Note that $code must be a plain string, I<NOT> a CODE reference.

The function name may not begin with an underscore.

=cut

sub func
{
   my ( $name, $code ) = @_;
   my $caller = caller;

   $name =~ m/^_/ and croak "Cannot name a library function beginning with '_'";

   # $code may contain leading whitespace and linefeeds. Kill them
   $code =~ s/\s*\n\s*//g;

   $package_funcs{$caller}->{$name} = $code;
}

=head2 init( $code )

Declare library initialisation code. This code will be executed in the remote
perl before any functions are compiled.

=cut

sub init
{
   my ( $code ) = @_;
   my $caller = caller;

   $package_funcs{$caller}->{_init} and croak "Already have library initialisation";

   # $code may contain leading whitespace and linefeeds. Kill them
   $code =~ s/\s*\n\s*//g;

   $package_funcs{$caller}->{_init} = $code;
}

sub funcs
{
   my ( $classname, @funcs ) = @_;

   my $package_funcs = $package_funcs{$classname};
   $package_funcs or croak "$classname does not define any library functions";

   my %funcs;
   # Always report the _init function
   $funcs{_init} = $package_funcs->{_init} if exists $package_funcs->{_init};

   if( @funcs ) {
      foreach my $f ( @funcs ) {
         $package_funcs->{$f} or croak "$classname does not define a library function called $f";
         $funcs{$f} = $package_funcs->{$f};
      }
   }
   else {
      %funcs = %{ $package_funcs };
   }

   %funcs;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
