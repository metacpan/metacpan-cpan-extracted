package Devel::Constants;
$Devel::Constants::VERSION = '1.04';
use 5.006;
use strict;
use warnings;
use vars qw( $VERSION %EXPORT_OK );

%EXPORT_OK =
(
	flag_to_names => \&flag_to_names,
	to_name       => \&to_name,
);

use constant;
use subs 'oldimport';

{
    no warnings;
	*oldimport        = \&constant::import;
	*constant::import = \&_newimport;
}

my %constants;

sub import
{
	my $class      = shift;

	my $pkg        = my $import = caller();
	my $flagholder = {};

	my @exports;

	while ( my $arg = shift )
	{
		if ( ref($arg) eq 'HASH' )
		{
			$flagholder = $arg;
		}
		elsif ( $arg eq 'package' )
		{
			$pkg = shift if @_;
		}
		elsif ( $arg eq 'import' )
		{
			$import = shift if @_;
		}
		elsif ( exists $EXPORT_OK{$arg} )
		{
			my $name = (@_ and ! exists $EXPORT_OK{ $_[0] }) ? shift : $arg;
			push @exports, [ $name, $EXPORT_OK{$arg} ];
		}
	}

	$constants{$pkg} = $flagholder;

	no strict 'refs';
	for my $export (@exports)
	{
		*{ $import . "::$export->[0]" } = $export->[1];
	}

}

sub _newimport
{
	my ( $class, @args ) = @_;
	my $pkg              = caller();

	if ( defined $constants{$pkg} )
	{
		while (@args)
		{
			my ( $name, $val ) = splice( @args, 0, 2 );
			last unless $val;
			$constants{$pkg}{$val} = $name;
		}
	}

	goto &oldimport;
}

sub flag_to_names
{
	my ( $val, $pkg ) = @_;
	$pkg            ||= caller();

	return unless my $constants = $constants{$pkg};

	my @flags;
	for my $flag ( keys %$constants )
	{
		push @flags, $constants->{$flag} if $val & $flag;
	}
	return wantarray() ? @flags : join( ' ', @flags );
}

sub to_name
{
	my ( $val, $pkg ) = @_;
	$pkg            ||= caller();

	return unless my $constants = $constants{$pkg};
	return $constants->{$val} if exists $constants->{$val};
}

1;

__END__

=head1 NAME

Devel::Constants - translates constants back to named symbols

=head1 SYNOPSIS

  # must precede use constant
  use Devel::Constants 'flag_to_names';
  
  use constant A => 1;
  use constant B => 2;
  use constant C => 4;
  
  my $flag = A | B;
  print "Flag is: ", join(' and ', flag_to_names($flag) ), "\n";

=head1 DESCRIPTION

Declaring constants is very convenient for writing programs, but as Perl often
inlines them, retrieving their symbolic names can be tricky.  This worse with
lowlevel modules that use constants for bit-twiddling.

Devel::Constants makes this much more manageable.

It silently wraps around the L<constant> module, intercepting all constant
declarations.  It builds a hash, associating the values to their names, from
which you can retrieve their names as necessary.

Note that you must use Devel::Constants I<before> C<constant>, or the magic
will not work and you will be very disappointed.  This is very important, and
if you ignore this warning, the authors will feel free to laugh at you (at
least a little.

By default, Devel::Constants only intercept constant declarations within the
same package that used the module.  Also by default, it stores the constants
for a package within a private (read, otherwise inaccessible) variable.  You
can override both of these.

Passing the C<package> flag to Devel::Constants with a valid package name will
make the module intercept all constants subsequently declared within that
package.  For example, in the main package you might say:

  use Devel::Constants package => NetPacket::TCP;
  use NetPacket::TCP;

All of the TCP flags declared within L<NetPacket::TCP> are now available.

It is also possible to pass in a hash reference in which to store the constant
values and names:

  my %constant_map;
  use Devel::Constants \%constant_map;
  
  use constant NAME	=> 1;
  use constant RANK	=> 2;
  use constant SERIAL	=> 4;
  
  print join(' ', values %constant_map), "\n";

=head2 EXPORT

By default, Devel::Constants exports no subroutines.  You can import its two
helper functions optionally by passing them on the use line:

  use Devel::Constants qw( flag_to_names to_name );
  
  use constant FOO => 1;
  use constant BAR => 2;
  
  print flag_to_names(2);
  print to_name(1);

You may also import these functions with different names, if necessary.  Pass
the alternate name after the function name.  B<Beware> that this is the most
fragile of all options.  If you do not pass a name, Devel::Constants may become
confused:

  # good
  use Devel::Constants
    flag_to_names => 'resolve',
    'to_name';
	
  # WILL WORK IN SPITE OF POOR FORM (the author thinks he's clever)
  use Devel::Constants
    'to_name',
    flag_to_names => 'resolve';

  # WILL PROBABLY BREAK, SO DO NOT USE
  use Devel::Constants
    'to_name',
    package => WD::Kudra;

Passing the C<import> flag will import any requested functions into the named
package.  This is occasionally helpful, but it will overwrite any existing
functions in the named package.  Be a good neighbor:

  use Devel::Constants
    import => 'my::other::namespace',
    'flag_to_names',
    'to_name';

Note that L<constant> also exports subroutines, by design.

=head1 FUNCTIONS

=over 4

=item C<flag_to_names($flag, [ $package ])>

This function resolves a flag into its component named bits.  This is generally
only useful for known bitwise flags that are combinations of named constants.
It can be very handy though.  C<$flag> is the flag to decompose.  The function
does not modify it.  The C<$package> parameter is optional.  If provided, it
will use flags set in another package.  In the L<NetPacket::TCP> example above,
you can use it to find the symbolic names of TCP packets, such as SYN or RST
set on a NetPacket::TCP object.

=item C<to_name($value, [ $package ])>

This function resolves a value into its constant name.  This does not mean that
the value necessarily comes from the constant, but merely that it has the same
value as the constant.  (For example, 2 could be the result of a mathematical
operation, or it could be a sign to dump core and bail out.  C<to_name> only
guarantees the same value, not the same semantics.  See L<PSI::ESP> if this is
not acceptable.)  As with L<flag_to_names>, the optional C<$package> parameter
will look for constants declared in a package other than the current.

=back

=head1 TODO

=over 4

=item * figure out a better way to handle C<flag_to_names> (inefficient
algorithm)

=item * allow potential capture lists?

=item * sync up better with allowed constant names in C<constant>

=item * evil nasty Damianesque idea: locally redefining constants

=back

=head1 AUTHOR

chromatic C<< chromatic at wgz dot org >>, with thanks to "Benedict" at
Perlmonks.org for the germ of the idea
(L<http://perlmonks.org/index.pl?node_id=117146>).

Thanks also to Tim Potter and Stephanie Wehner for L<NetPacket::TCP>.

Version 1.01 released by Neil Bowers E<lt>neilb at cpan dot orgE<gt>.

=head1 REPOSITORY

L<https://github.com/neilb/Devel-Constants>

=head1 COPYRIGHT

Copyright (c) 2001, 2005 chromatic.  Some rights reserved.

This is free software.  You may use, modify, and distribute it under the same
terms as Perl 5.8.x itself.

=head1 SEE ALSO

=over 4

=item * L<constant>

=item * L<Constant::Generate>

Provides the ability to define constants, a reverse mapping function,
and more besides.

=item * L<http://neilb.org/reviews/constants.html>

A review of all CPAN modules related to the definition and manipulation
of constants and read-only variables.

=back

=cut
