use 5.008003;
use strict;
use warnings;

package JavaScript::Any::Context;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use namespace::autoclean;
use Role::Tiny;

requires 'eval';
requires 'define';

use Ref::Util qw( is_plain_scalarref );

# convenience methods here

sub implementation {
	ref shift;
}

sub is_true {
	shift;
	my ($value) = @_;
	return !!1 if is_plain_scalarref($value) && $$value == 1;
	require JSON::PP;
	return !!1 if JSON::PP::is_bool($value) && $value == JSON::PP::true();
	return !!0;
}

sub is_false {
	shift;
	my ($value) = @_;
	return !!1 if is_plain_scalarref($value) && $$value == 0;
	require JSON::PP;
	return !!1 if JSON::PP::is_bool($value) && $value == JSON::PP::false();
	return !!0;
}

sub is_null {
	return !defined $_[1];
}

sub _throw_if_bad_name {
	return if $_[1] =~ /\A\w+\z/;
	require Carp;
	Carp::croak("Bad name: " . ref($_[1]));
}

sub _throw_because_bad_value {
	require Carp;
	Carp::croak("Cannot define values of type " . ref($_[1]));
	# ref should always be defined because non-ref scalars will be good values
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

JavaScript::Any::Context - an environment where custom functions can be defined and Javascript evaluated

=head1 SYNOPSIS

  use JavaScript::Any;
  
  my $context = JavaScript::Any->new_context;
  $context->define( say => sub { print @_, "\n" } );
  $context->eval('say(1 + 2)');

=head1 DESCRIPTION

This is a L<Role::Tiny> role defining the API for objects returned
by C<< JavaScript::Any->new_context >>.

=head2 Methods

=over

=item C<< $object->implementation >>

Returns the implementation class name as a string.

=item C<< $object->define($str, $coderef) >>

Defines a custom Perl function which can be called by Javascript code.

The current implementation only allows the name of the function to
consist of word characters. Defining a function called, for example,
C<< window.alert >>, would not be allowed because of the dot.

Roughly speaking, when the function is called by Javascript, whatever
arguments are passed to it are available in C<< @_ >> to your Perl
code, and whatever value your coderef returns is returned as the
Javascript function's return value. The exact details are currently
specific to the backend implementation.

=item C<< $object->define($str, $value) >>

Where C<< $value >> is a non-reference value, defines a simple string
or numeric variable. JavaScript is somewhat more typed than Perl, so
be aware that currently whether C<< $value >> is considered to be a
string or a number by Javascript is currently undetermined behaviour.

=item C<< $object->eval($str) >>

Evaluates a string of Javascript code and returns the result.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=JavaScript-Any>.

=head1 SEE ALSO

L<JavaScript::Any>, L<Role::Tiny>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

