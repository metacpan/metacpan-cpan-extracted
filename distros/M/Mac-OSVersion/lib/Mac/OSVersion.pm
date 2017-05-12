package Mac::OSVersion;
use strict;

use warnings;
no warnings;

use Carp;

use subs qw();
use vars qw($VERSION);

$VERSION = '1.002';

=encoding utf8

=head1 NAME

Mac::OSVersion - Get the Mac OS X system version

=head1 SYNOPSIS

	use Mac::OSVersion;

	my $version = Mac::OSXVersion->version; # 10.4.11
	my @version = Mac::OSXVersion->version; # (10, 4, 11, 'Tiger', '8.10.1' )

	my $name    = Mac::OSXVersion->name; # Tiger, etc.
	my $name    = Mac::OSXVersion->minor_to_name( 3 ); 'Panther';

	my $major   = Mac::OSXVersion->major;  # 10 of 10.4.11

	my $minor   = Mac::OSXVersion->minor;  # 4 or 10.4.11

	my $point   = Mac::OSXVersion->point;  # 11 of 10.4.11

	my $build   = Mac::OSXVersion->build;  # 8R2218

	my $kernel  = Mac::OSXVersion->kernel; # 8.10.1

=head1 DESCRIPTION

Extract the values for the various OS numbers (Mac OS X version, build,
kernel) using various methods. Methods may use other modules or
external programs. So far this only works on the current machine.

=cut

=head2 Methods

=over 4

=item version( METHOD );

In scalar context, returns the numeric version of OS X, I<e.g.> 10.4.11.

In list context, returns the list of the major, minor, point, name, and
kernel versions. Some methods may not return all values, but the values
will always be in the same positions.


	#  0       1       2       3      4       5
	( $major, $minor, $point, $name, $build, $kernel );

The available methods are list in "Ways of collecting info". Use the subroutine
name as C<METHOD>. For instance:

	my @list = Mac::OSVersion->version( 'gestalt' );

=item methods()

Returns the list of methods that C<version> can use to do its work.

=cut

BEGIN {
no strict 'refs';
my @positions = qw(MAJOR MINOR POINT NAME BUILD KERNEL);
use vars ( map { "_$_" } @positions );

foreach my $index ( 0 .. $#positions )
	{
	my $name = $positions[$index];

	*{"_$name" } = sub () { $index }
	}
}

{
my %methods = map { $_, 1 }
	qw(uname gestalt sw_vers system_profiler default);

sub version
	{
	my( $class, $method ) = @_;

	$method ||= 'default';

	croak( "$class doesn't know about method [$method]" ) unless
		eval { $class->can( $method ) };

	my @list = $class->$method;
	unless( wantarray ) {
		return join ".", @list[0,1], (defined($list[2]) ? $list[2] : ());
		}

	return @list;
	}

sub methods { () = keys %methods }
}

=item name( [METHOD] )

Returns the name of  major version number, I<e.g.> 'Tiger' 10.4.

C<METHOD> optionally specifies the method to use to get the answer. See
C<version> for the possible values.

=item minor_to_name( MINOR )

Returns the name ( I<e.g.> 'Tiger' ) for the given minor version
number.

	0	Cheetah
	1	Puma
	2	Jaguar
	3	Panther
	4	Tiger
	5	Leopard
	6	Snow Leopard
	7   Lion
	8	Mountain Lion
	9	Mavericks
	10	Yosemite
	11  El Capitan
	12  Sierra

=item minor_version_numbers()

Returns a list of the minor version numbers

=item minor_version_names()

Returns a list of the names of the minor versions ( I<e.g.>
qw(Cheetah Puma ... )

=cut

BEGIN {
my @names = qw( Cheetah Puma Jaguar Panther Tiger Leopard ) ;
push @names, 'Snow Leopard', 'Lion', 'Mountain Lion',
	'Mavericks', 'Yosemite', 'El Capitan', 'Sierra';

sub minor_to_name { $names[ $_[1] ] }

sub minor_version_numbers { ( 0 .. $#names ) }

sub minor_version_numbers { @names }
}

sub name
	{
	$_[0]->minor_to_name(
		${
			[ $_[0]->version( $_[1] ) ]
		}[_MINOR]
		)
	}

=item major( [METHOD] )

Returns the major version number, I<e.g.> 10 or 10.4.11.

C<METHOD> optionally specifies the method to use to get the answer. See
C<version> for the possible values. Not all methods can return an answer.

=cut

sub major {  ${ [ $_[0]->version( $_[1] ) ] }[_MAJOR] }

=item minor( [METHOD] )

Returns the major version number, I<e.g.> 4 or 10.4.11.

C<METHOD> optionally specifies the method to use to get the answer. See
C<version> for the possible values. Not all methods can return an answer.

=cut

sub minor { ${ [ $_[0]->version( $_[1] ) ] }[_MINOR] }

=item point( [METHOD] )

Returns the point release version number, I<e.g.> 11 or 10.4.11.

C<METHOD> optionally specifies the method to use to get the answer. See
C<version> for the possible values. Not all methods can return an answer.

=cut

sub point { ${ [ $_[0]->version( $_[1] ) ] }[_POINT] }

=item build( [METHOD] )

Returns the point release version number, I<e.g.> 11 or 10.4.11.

C<METHOD> optionally specifies the method to use to get the answer. See
C<version> for the possible values. Not all methods can return an answer.

=cut

sub build { ${ [ $_[0]->version( $_[1] ) ] }[_BUILD] }

=item kernel( [METHOD] )

Returns the kernel version number, I<e.g.> 8.10.1.

C<METHOD> optionally specifies the method to use to get the answer. See
C<version> for the possible values. Not all methods can return an answer.

=cut

sub kernel { ${ [ $_[0]->version( $_[1] ) ] }[_KERNEL] }

=back

=head2 Ways of collecting info

There isn't a single way to get all of the info that C<version> wants to
provide, and some of the ways might give different answers for the same
installation. Not all methods can return an answer. Here's a table of
which methods return what values:

			default    system_profiler   sw_vers      gestalt    uname

	major     x          x                 x            x
	minor     x          x                 x            x
	point     x          x                 x            x
	name      x          x                 x            x
	build     x          x                 x
	kernel    x          x                                         x


=cut

=over 4

=item default

Uses several methods to collect information.

=cut

sub default
	{
	my $class = shift;

	my @list;

	if( wantarray ) { @list = $class->system_profiler }
	else            { scalar $class->system_profiler }
	}

=item gestalt

Only uses C<gestaltSystemVersion> from C<Mac::Gestalt> to get the
major, minor, point, and name fields. This has the curious bug that
the point release number will not be greater than 9.

In scalar context, returns the version as "10.m.p". In list context, returns
the same list as C<version>, although some fields may be missing.

=cut

sub gestalt
	{
	my $class = shift;

	eval { require Mac::Gestalt };
	croak "Need to install Mac:Gestalt to use 'gestalt' method" if $@;

	my @list;

	my $key     = Mac::Gestalt::gestaltSystemVersion();
	#print STDERR "key is $key\n";

	my $version = sprintf "%x", $Mac::Gestalt::Gestalt{$key};
	my @version = $version =~ m/^(\d+)(\d)(\d)$/g;
	#print STDERR "Got version [@version]\n";

	@list[ _MAJOR, _MINOR, _POINT ] = @version;

	return join ".", @list[ _MAJOR, _MINOR, _POINT ] unless wantarray;

	$list[_NAME] = $class->minor_to_name( $list[_MINOR] );

    @list;
	}

=item sw_vers

Only uses C</usr/bin/sw_vers> to get the major, minor, point, build, and name
fields.

In scalar context, returns the version as "10.m.p". In list context, returns
the same list as C<version>, although some fields may be missing.

=cut

BEGIN {
my $command = '/usr/bin/sw_vers';

sub sw_vers
	{
	croak "Missing $command!" unless -x $command;

	my $class = shift;

	my @list = ();

	chomp( my $product = `$command -productVersion` );

	return $product unless wantarray;

	chomp( my $build   = `$command -buildVersion` );

	( $list[_MAJOR], $list[_MINOR], $list[_POINT] ) = split /\./, $product;
	$list[_BUILD] = $build;
	$list[_NAME] = $class->minor_to_name( $list[_MINOR] );

	@list;
	}
}

=item system_profiler

Only uses C</usr/sbin/system_profiler> to get the major, minor, point,
build, and name fields.

In scalar context, returns the version as "10.m.p". In list context,
returns the same list as C<version>, although some fields may be
missing.

=cut

BEGIN {
my $command = '/usr/sbin/system_profiler';

sub system_profiler
	{
	croak "Missing $command!" unless -x $command;

	my $class = shift;

	chomp( my $output = `$command SPSoftwareDataType` );

	my @list = ();

	# mavericks omits the Mac in the output
	if( $output =~
		m/  \s+System\ Version:\ (?:Mac\ )? OS\ X\ (\d+\.\d+(?:\.\d+)?)\ \((.*?)\)
			\s+Kernel\ Version:\ Darwin\ (\d+\.\d+\.\d+)
			/xm )

		{
		return $1 unless wantarray;

		my( $version, $build, $kernel ) = ($1, $2, $3 );

		( $list[_MAJOR], $list[_MINOR], $list[_POINT] ) = split /\./, $version;

		$list[_BUILD]  = $build;
		$list[_KERNEL] = $kernel;
		$list[_NAME]   = $class->minor_to_name( $list[_MINOR] );
		}

	@list;
	}
}

=pod

Software:

    System Software Overview:

      System Version: Mac OS X 10.4.10 (8R2218)
      Kernel Version: Darwin 8.10.1
      Boot Volume: Tiger
      Computer Name: macbookpro
      User Name: brian d  foy (brian)

=cut

=item uname

Only uses C<uname -a> to get the kernel field.

In scalar context, returns the kernel version. In list context, returns
the same list as C<version>, although some fields may be missing.

=cut

BEGIN {
my $command = '/usr/bin/uname';

sub uname
	{
	croak "Missing $command!" unless -x $command;

	my $class = shift;

	chomp( my $output = `$command -a` );

	my @list = ();
	if( $output =~ /Darwin Kernel Version (\d+\.\d+\.\d+)/ )
		{
		return $1 unless wantarray;
		$list[_KERNEL] = $1;
		}

	@list;
	}
}

=back

=head1 TO DO

* How does the API look if there is a Mac OS 11?

* Specify a remote machine

=head1 SEE ALSO

=over 4

=item * /usr/bin/sw_vers

=item * /usr/sbin/system_profiler

=item * /usr/bin/uname

=item * Mac::Gestalt

=back

=head1 SOURCE AVAILABILITY

This module is in Github

	git://github.com/briandfoy/mac-osversion.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2007-2016, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
