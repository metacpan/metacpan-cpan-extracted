package Method::Alias;

=pod

=head1 NAME

Method::Alias - Create method aliases (and do it safely)

=head1 SYNOPSIS

  # My method
  sub foo {
      ...
  }
  
  # Alias the method
  use Method::Alias 'bar' => 'foo',
                    'baz' => 'foo';

=head1 DESCRIPTION

For a very long time, whenever I wanted to have a method alias (provide
an alternate name for a method) I would simple do a GLOB alias. That is,

  # My method
  sub foo {
      ...
  }
  
  # Alias the method
  *bar = *foo;

While this works fine for functions, it does B<not> work for methods.

If your class has a subclass that redefines C<foo>, any call to C<bar>
will result in the overloaded method being ignored and the wrong C<foo>
method being called.

These are basically bugs waiting to happen, and having completed a number
of very large APIs with lots of depth myself, I've been bitten several
times.

In this situation, the canonical and fasest way to handle an alias looks
something like this.

  # My method
  sub foo {
     ...
  }
  
  # Alias the method
  sub bar { shift->foo(@_) }

Note that this adds an extra entry to the caller array, but this isn't
really all that important unless you are paranoid about these things.

The alternative would be to try to find the method using UNIVERSAL::can,
and then goto it. I might add this later if someone really wants it, but
until then the basic method will suffice.

That doing this right is even worthy of a module is debatable, but I
would rather have something that looks like a method alias definition,
than have to document additional methods all the time.

=head2 Using Method::Alias

Method::Alias is designed to be used as a pragma, to which you provide a
set of pairs of method names. Only very minimal checking is done, if you
wish to create infinite loops or what have you, you are more than welcome
to shoot yourself in the foot.

  # Add a single method alias
  use Method::Alias 'foo' => 'bar';
  
  # Add several method aliases
  use Method::Alias 'a' => 'b',
                    'c' => 'd',
                    'e' => 'f';

And for now, that's all there is to it.

=head1 METHODS

=cut

use 5.005;
use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.03';
}

=pod

=head2 import from => to, ...

Although primarily used as a pragma, you may call import directly if you
wish.

Taking a set of pairs of normal strings, the import method creates a number
of methods in the caller's package to call the real method.

Returns true, or dies on error.

=cut

sub import {
	my $class = shift;
	my %pairs = @_;

	# Where will we create the aliases
	my $pkg = (caller())[0];

	# Generate the code
	my $code = join "\n", "package $pkg;",
		map { "sub $_ { shift->$pairs{$_}(\@_) }" }
		keys %pairs;

	# Execute the code
	eval $code;
	die $@ if $@;

	1;
}

1;

=pod

=head1 SUPPORT

Bugs should always be submitted via the CPAN bug tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Method-Alias>

For other issues, contact the maintainer

=head1 AUTHORS

Adam Kennedy E<lt>cpan@ali.asE<gt>

=head1 SEE ALSO

L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2004, 2006 Adam Kennedy. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
