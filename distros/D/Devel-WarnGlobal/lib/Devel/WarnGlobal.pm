package Devel::WarnGlobal;

# ABSTRACT: Helps track down and eliminate globals

use strict;
use warnings;

our $VERSION = '0.09'; # VERSION

use Carp;

use Devel::WarnGlobal::Scalar;

sub import {
    no strict 'refs';

    my $type = shift;
    my (@var_ties) = @_;
    
    my $tie_params = $type->_rearrange(\@var_ties);
    
    while ( my ($var_name, $options) =  each %$tie_params ) {
	tie ${ $type->_fix_name($var_name) }, $type->_get_tie_type(), $options;
    }

    1;
}

sub _rearrange {
    my $type = shift;
    my ($var_ties_in) = @_;

    my @var_ties = @$var_ties_in;
    my %fixed_ties = ();

    while ( scalar @var_ties ) {
	my $var_name = shift @var_ties;
	my $var_arg = shift @var_ties;
	my %var_opts = ( name => $var_name );

	if (ref $var_arg eq 'ARRAY') {
	    $var_opts{'get'} = $var_arg->[0] if defined $var_arg->[0];
	    $var_opts{'set'} = $var_arg->[1] if defined $var_arg->[1];
	}
	elsif (ref $var_arg eq 'CODE') {
	    $var_opts{'get'} = $var_arg;
	}
	else {
	    croak("${$type}::import() called improperly; stopped");
	}
	$fixed_ties{$var_name} = \%var_opts;
    }

    return \%fixed_ties;
}

sub _get_tie_type {
    return 'Devel::WarnGlobal::Scalar';
}

sub _fix_name {
    my $type = shift;
    my ($var_name) = @_;

    my $var = substr($var_name, 1);

    $var_name =~ m{::} and return $var;

    return ( caller(2) )[0] . '::' . $var;
}

1;

__END__

=pod

=head1 NAME

Devel::WarnGlobal - Helps track down and eliminate globals

=head1 VERSION

version 0.09

=head1 SYNOPSIS

  use Devel::WarnGlobal $FOO => \&get_foo,
                      $BAR => [\&get_bar, \&set_bar];

  use Devel::WarnGlobal::Scalar;
  tie $GLOBAL, 'Devel::WarnGlobal::Scalar', { get => \&get_global };

=head1 DESCRIPTION

A program full of global variables can be a mind-bending thing to debug. They come
in various shapes and sizes. Some are package variables exported by default. Some are
accessed directly using the '$Modulename::Global' syntax.

Most experienced programmers agree that using global variables is a
Bad Thing in large programs, since they both add to the complexity of
the program and can introduce subtle bugs. Globals introduce
complexity because they increase the number of things that you need to
keep in your head at a given time. ("What the heck is $FROBOZZ
supposed to be again?")  They can introduce subtle bugs because if one
piece of code accidentally says 

    if ($THNEE = 34)

when they meant to say

    if ($THNEE == 34)

then another piece of code miles distant
could break, and you'll have to hunt through the entire program for
the bug. This can be very time-consuming!

The standard remedy for rampant global variables is to write subroutines that
return the information that the global is supposed to contain. For example,
if you have a global like so:

    $CLOWN = "Bozo";

then you can instead write a subroutine like this one:

    sub get_clown { return "Bozo"; }

and replace all instances of $CLOWN with get_clown(). If at some point in
the program we change to a different clown, you can write a set_clown()
method and change any '$CLOWN = "Binky"' statements to 'set_clown("Binky")'.
For the curious, one way of doing this would be:

 BEGIN {

   my $clown = 'Bozo';

   sub get_clown () {
     return $clown;
   }

   sub set_clown {
     my ($new_clown) = @_;
     $clown = $new_clown;
   }

 }

Writing a 'set' function reintroduces some of the problems of having
the global variable in the first place, since calling set_clown() in
one part of the program can cause problems in a different piece of
code. However, you have accomplished several good things. First, a
'set_clown' call is easier to spot than a '$CLOWN = foo'
statement. Secondly, you can put access controls into set_clown() to
make sure that get_clown() will always return a valid clown. And
thirdly, it becomes easier to make get_clown() and set_clown() into
class methods. Then you could have calls like $circus->get_clown(),
making it easier to separate circus-related stuff from non-circus
stuff.

Globals can be elusive. It can be hard to find them, and
time-consuming to replace them all at once. Devel::WarnGlobal is
designed to make the process easier. Once you've written your 'get'
function, you can tie that variable to the function, and the variable
will always return the value of the function. This can be valuable
while testing, since it serves to verify that you've written your new
'get'-function correctly.

In order to trace down uses of the given global, Devel::WarnGlobal can
provide warnings whenever the global is accessed. These warnings are
on by default; they are controlled by the 'warn' parameter. Also, one
can turn warnings on and off with the warn() method on the tied
object. If 'die_on_write' is set, Devel::WarnGlobal will die if an
attempt is made to write to a value with no 'set' method
defined. (Otherwise, the 'set' method will produce a warning, but will
have no affect on the value.)

As a convenience, you can tie variables in the 'use' line with
Devel::WarnGlobal. Or, you can use the underlying
Devel::WarnGlobal::Scalar module directly.

=head1 NAME

Devel::WarnGlobal - Track down and eliminate globals

=head1 TODO

Support for tying arrays, hashes, and filehandles

Variable-shadowing checks, so that we can monitor whether the tied variable and the subroutine stay in sync

=head1 SEE ALSO

L<Variable::Magic>

=head1 AUTHOR

Stephen Nelson <stephenenelson@mac.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Stephen Nelson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
