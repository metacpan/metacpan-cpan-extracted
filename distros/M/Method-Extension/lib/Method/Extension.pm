#
# This file is part of Method-Extension
#
# This software is Copyright (c) 2015 by Tiago Peczenyj.
#
# This is free software, licensed under:
#
#   The MIT (X11) License
#
use 5.006;
use strict;
use warnings;
package Method::Extension;
{
  $Method::Extension::VERSION = '0.1';
}

# ABSTRACT: Method Extension port for perl

use parent 'Attribute::Handlers';
 
sub UNIVERSAL::ExtensionMethod : ATTR(CODE) {
    my ($package, $symbol, $referent, $attr, $data, $phase) = @_;
    $data = [$data] unless ref $data eq 'ARRAY';
    foreach my $item (@{$data}) {
        no strict 'refs';
        *{$item} = $referent;
    }
}

1;


=pod

=encoding UTF-8

=head1 NAME

Method::Extension - Method Extension port for perl

=head1 VERSION

version 0.1

=head1 SYNOPSIS

	package Foo;
	# no baz method
	...

	package Bar;

	use Method::Extension;

	sub baz :ExtensionMethod(Foo::baz) {
		my ($self, ... ) = @_; # $self will be a Foo instance
    	return "Baz from extension method";
	}
	...

	Foo->new->baz();	

=head1 DESCRIPTION

One good definition of Method Extension can be found L<here|https://msdn.microsoft.com/en-us/library/vstudio/bb383977(v=vs.110).aspx>.

	Extension methods enable you to "add" methods to existing types without creating a new derived type, recompiling, or otherwise modifying the original type. Extension methods are a special kind of static method, but they are called as if they were instance methods on the extended type. For client code written in C# and Visual Basic, there is no apparent difference between calling an extension method and the methods that are actually defined in a type.

In other words, you can create, in C# for example, one subroutine and use a syntax sugar to invoke as a method. In other words, instead do this:

	my $foo = Foo->new;
	baz( $foo );

You can do:

	$foo->baz(); # magic!

This is very useful when you deal with languages like C# or Java, when you have a very strict way for add behavior to one class (Java does not support multiple inheritance, for example). 

Of course, in Perl we have more tools. L<Moose>/L<Moo> Roles, for example, are a great way to extend one class ( and you can apply one role in runtime ).

But I miss extension methods. Because it is a syntax sugar we do not change the original class, and there is no way to emulate this in Perl (maybe override the operator -> or using some dark magic). 

The solution is ugly: this package offer one L<attribute> C<ExtensionMethod> and it allows to inject the subroutine in the specified package. It is not a B<real> extension method but it is our first effort. It is important call the attribute with the package + the method name ( I loose the subroutine name when we real with attributes ). 

What we have: one attribute who helps to inject one subroutine in another package.

What I want to do (future): one way to avoid inject the subroutine, just like the sugar:

	$object->extension_method( args... );

became

	extension_method( $object, args... );

Better:

	{
		use Bar qw(baz);

		Foo->new->baz; # ok
	}

	Foo->new->baz # method not found

If someone has some idea to help me on this, please let me know.

Ps: AUTOLOAD seems B<very> ugly and intrusive too.

=head1 NAME

Method::Extension - easily extend existing packages using method extension

=head1 ATTRIBUTES

=head2 ExtensionMethod

With this attribute we can insert one subroutine to one existing package.

Usage: C<ExtensionMethod(Package::method_name)>.

Example:

	package Bar;

	sub baz :ExtensionMethod(Foo::baz) {
		...
	} 

This inject the method Bar::baz into Foo::baz.

Important: you should not forget to rewrite the method name. We loose the subroutine name when we deal with attribute.

The good point is: we can use a different name. And we can inject in multiple packages too if we pass an array.

=head1 LICENSE

The MIT License

 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated
 documentation files (the "Software"), to deal in the Software
 without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to
 whom the Software is furnished to do so, subject to the
 following conditions:
  
  The above copyright notice and this permission notice shall
  be included in all copies or substantial portions of the
  Software.
   
   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
   WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
   INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR
   PURPOSE AND NONINFRINGEMENT. IN NO EVENT
   SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
   LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
   TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
   CONNECTION WITH THE SOFTWARE OR THE USE OR
   OTHER DEALINGS IN THE SOFTWARE.

=head1 AUTHOR

Tiago Peczenyj <tiago (dot) peczenyj (at) gmail (dot) com>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/peczenyj/Method-Extension/issues>

=head1 AUTHOR

Tiago Peczenyj <tiago.peczenyj@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Tiago Peczenyj.

This is free software, licensed under:

  The MIT (X11) License

=cut


__END__
