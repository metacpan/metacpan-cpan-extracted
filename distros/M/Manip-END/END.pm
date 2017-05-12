use strict;
use warnings;

package Manip::END;

our $VERSION = '0.08';

require Exporter;
our @EXPORT_OK = qw(
	clear_end_array
	set_end_array
);

our @ISA = qw(Exporter);

require XSLoader;
XSLoader::load('Manip::END', $Manip::END::VERSION);

my $self = bless get_end_array(), __PACKAGE__;

sub set_end_array
{
	_check(@_);
	@$self = @_;
}

sub clear_end_array
{
	@$self = ();
}

sub new
{
	return $self;
}

sub clear
{
	@$self = ();
}

sub push
{
	shift;
	_check(@_);
	push(@$self, @_);
} 

sub unshift
{
	shift;
	_check(@_);
	unshift(@$self, @_);
} 

sub filter_sub
{
	shift;
	my $sub = shift;

	my $max = $#$self;	

	for (my $i = 0; $i <= $max; $i++)
	{
		if ( ! &$sub(get_pkg_for_index($i)) )
		{
			splice(@$self, $i, 1);
			$max--;
		}
	}
}

sub remove_class
{
	shift;

	my $class = shift;

	$self->filter_sub(sub { ref($_[0]) ne $class } );
}

sub remove_isa
{
	shift;

	my $class = shift;

	$self->filter_sub(sub { ! UNIVERSAL::isa($_[0], $class) } );
}

sub remove_pat
{
	shift;

	my $pat = shift;

	$pat = ref($_) ? $_ : qr/$pat/;

	$self->filter_sub(sub { ! ($_[0] =~ $pat) } );
}

sub _check
{
	if (grep {! UNIVERSAL::isa($_, "CODE") } @_)
	{
		die "END blocks must be CODE references";
	}
}

1;

__END__

=head1 NAME

Manip::END - Mess around with END blocks

=head1 SYNOPSIS

  use Manip::END qw( clear_end_array set_end_array );

  clear_end_array();

  set_end_array(sub {...}, sub {...});

  $ends = Manip::END->new;

  $ends->unshift(sub {...}, sub {...});

  $ends->remove_class("My::Class");

  $ends->remove_isa("My::Base::Class");

  $ends->remove_pat("^My::Modules");

  $ends->filter_sub(\&thing_about_it));

=head1 DESCRIPTION

Perl keeps an array of subroutines that should be run just before your
program exits (see perlmod manpage for more details). This module allows you
to manipulte this array.

=head1 WARNING

This module gives you access to one of Perl's internal arrays that you're
not supposed to see so there are a couple of funny things going on.

The array contains an C<undef> for each END blcok that has been encountered,
it's not really an C<undef> though, it's a kind of raw coderef that's not
wrapped in a scalar ref. This leads to fun error messages like

  Bizarre copy of CODE in sassign

when you try to assign one of these values to another variable. This all
means that it's somewhere between difficult and impossible to manipulate
these values array yourself. B<Use the filter functions provided>.

That said, you can erase them without any problem and you can add your own
coderefs without any problem too. If you want to selectively remove items
from the array, that's where the fun begins. You cannot do

  @$ref = grep {...} @$ref

if any of the C<undef> coderefs will survive the grep as they will cause an
error such as the one above.

=head1 HOW TO USE IT

The most useful thing you can do with it is to remove certain END blocks
based on the package they belong to. You can do something like

  my $ends = Manip::END->new;

  $ends->filter_sub(\&think_hard_about);

Where C<think_hard_about> is a function that takes in a package name and
returns a true or false value depending on whether you want to keep or
remove the END blocks in that package.

There are prebuilt convenience methods for removing the END blocks for a
specific package, all packages matching a pattern or all packages inheriting
from a certain package.

=head2 EXPORTED FUNCTIONS

C<clear_end_array()>

This will clear the array of END blocks.

C<set_end_array(@blocks)>

@blocks is an array of subroutine references. This will set the array of END
blocks.

=head2 CONSTRUCTOR

C<Manip::END-E<gt>new()>

This will return a blessed reference to the array of END blocks which you
can manipulate yourself. You can maipulate the array directly but it's
probably much better idea to to use the methods below.

=head2 OBJECT METHODS

C<$obj-E<gt>unshift(@blocks)>

@blocks is an array of references to code blocks. This will add the blocks
to the start of the array. By adding to the start of the array, they will be
the first code blocks executed by Perl when it is exiting

C<$obj-E<gt>push(@blocks)>

@blocks is an array of references to code blocks. This will add the blocks
to the end of the array. By adding to the end of the array, they will be
the last code blocks executed by Perl when it is exiting

C<$obj-E<gt>clear()>

This clears the array.

C<$obj-E<gt>filter_sub($code)>

$code is a reference to a subroutine. For each element of the array, this
will execute the subroutine in $code. The first and only argument to the
routine is the nameof the package in which the END block was declared. If
the subroutine returns a true value, the element will be kept. If it returns
false, the element will be removed from the array.

C<$obj-E<gt>remove_isa($class)>

$class is a string containing the name of a class. This removes all of the
END blocks from packages which inherit from $class.

C<$obj-E<gt>remove_pkg($pkg)>

$pkg is a string containing the name of a package. This removes all of the
END blocks from $pkg.

C<$obj-E<gt>remove_pat($pat)>

$pat is either a reference to a regular expression or a string which will be
used as a regular expression. This removes all of the END blocks from any
package which matches the regular expression.

=head1 AUTHOR

Written by Fergal Daly <fergal@esatclear.ie>. Suggested by Mark Jason
Dominus at his talk in Dublin.

=head1 LICENSE

Copyright 2003 by Fergal Daly E<lt>fergal@esatclear.ieE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=cut
