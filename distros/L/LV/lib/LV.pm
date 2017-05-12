use 5.006;
use strict;
use warnings;

package LV;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.006';

BEGIN {
	*_subname = eval { require Sub::Name }
		? \&Sub::Name::subname
		: sub { $_[1] }
};

use Exporter ();
our @ISA       = qw( Exporter );
our @EXPORT    = qw( lvalue );
our @EXPORT_OK = qw( get set );

sub get (&;@) { my $caller = (caller(1))[3]; get => _subname("$caller~get", shift), @_ }
sub set (&;@) { my $caller = (caller(1))[3]; set => _subname("$caller~set", shift), @_ }

{
	my $i;
	
	sub implementation
	{
		return $i;
	}
	
	sub _set_implementation
	{
		my $module = shift;
		*lvalue = $module->can('lvalue') or do {
			require Carp;
			Carp::croak("$module does not appear to be an LV backend");
		};
		$i = $module;
	}
}

if ( $ENV{PERL_LV_IMPLEMENTATION} )
{
	my $module = sprintf('LV::Backend::%s', $ENV{PERL_LV_IMPLEMENTATION});
	eval "require $module; 1" or do {
		require Carp;
		Carp::croak("Could not load LV backend $module");
	};
	_set_implementation($module);
}

else
{
	my @implementations = qw(
		LV::Backend::Sentinel
		LV::Backend::Magic
		LV::Backend::Tie
	);
	
	for my $module (@implementations)
	{
		if (eval "require $module; 1")
		{
			_set_implementation($module);
			last;
		}
	}
}

unless (__PACKAGE__->can('lvalue'))
{
	require Carp;
	Carp::croak("No suitable backend found for lv");
}

1;

__END__

=pod

=encoding utf-8

=for stopwords lvaluedness rvalue

=head1 NAME

LV - LV ♥ lvalue

=head1 SYNOPSIS

   use LV qw( lvalue get set );
   
   my $xxx;
   sub xxx :lvalue {
      lvalue
         get { $xxx }
         set { $xxx = $_[0] }
   }
   
   xxx() = 42;
   say xxx();    # says 42

=head1 DESCRIPTION

This module makes lvalue subroutines easy and practical to use.
It's inspired by the L<lvalue> module which is sadly problematic
because of the existence of another module on CPAN called L<Lvalue>.
(They can get confused on file-systems that have case-insensitive
file names.)

LV comes with three different implementations, based on
L<Variable::Magic>, L<Sentinel> and C<tie>; it will choose and
use the best available one. You can force LV to pick a particular
implementation using:

   $ENV{PERL_LV_IMPLEMENTATION} = 'Magic'; # or 'Sentinel' or 'Tie'

The tie implementation is the slowest, but will work on Perl 5.6
with only core modules.

=head2 Functions

=over

=item C<< lvalue(%args) >>

Creates the magic lvalue. This must be the last expression evaluated
by the lvalue sub (and thus will be returned by the sub) but also
must not be returned using an explicit C<return> keyword (which would
break its lvaluedness).

As a matter of style, you may like to omit the optional semicolon
after calling this function, which will act as a reminder that no
statement should follow this one.

The arguments are C<get> and C<set>, which each take a coderef:

   sub xxx :lvalue {
      lvalue(
         get => sub { $xxx },
         set => sub { $xxx = $_[0] },
      ); # semicolon
   }

Note that the C<set> coderef gets passed the rvalue part as
C<< $_[0] >>.

=item C<< get { BLOCK } >>,  C<< set { BLOCK } >>

Convenience functions for defining C<get> and C<set> arguments for
C<lvalue>:

   sub xxx :lvalue {
      lvalue
         get { $xxx }
         set { $xxx = $_[0] }
   }

As well as populating C<< %args >> for C<lvalue>, these functions also
use L<Sub::Name> (if it's installed) to ensure that the anonymous
coderefs have sensible names for the purposes of stack traces, etc.

These functions are not exported by default.

=item C<< implementation() >>

Can be used to determine the current backend.

Cannot be exported.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=LV>.

=head1 SEE ALSO

L<lvalue>, L<Sentinel>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

