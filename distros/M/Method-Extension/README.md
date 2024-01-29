# NAME

Method::Extension - easily extend existing packages using method extension


[![Kwalitee](https://cpants.cpanauthors.org/dist/Method-Extension.svg)](https://cpants.cpanauthors.org/dist/Method-Extension)
[![tests](https://github.com/peczenyj/Method-Extension/actions/workflows/linux.yml/badge.svg)](https://github.com/peczenyj/Method-Extension/actions/workflows/linux.yml)
[![tests](https://github.com/peczenyj/Method-Extension/actions/workflows/windows.yml/badge.svg)](https://github.com/peczenyj/Method-Extension/actions/workflows/windows.yml)
[![tests](https://github.com/peczenyj/Method-Extension/actions/workflows/macos.yml/badge.svg)](https://github.com/peczenyj/Method-Extension/actions/workflows/macos.yml)
[![tests](https://github.com/peczenyj/Method-Extension/actions/workflows/perltidy.yml/badge.svg)](https://github.com/peczenyj/Method-Extension/actions/workflows/perltidy.yml)
[![tests](https://github.com/peczenyj/Method-Extension/actions/workflows/perlcritic.yml/badge.svg)](https://github.com/peczenyj/Method-Extension/actions/workflows/perlcritic.yml)
[![Coverage Status](https://coveralls.io/repos/github/peczenyj/Method-Extension/badge.svg?branch=master)](https://coveralls.io/github/peczenyj/Method-Extension?branch=master)
[![license](https://img.shields.io/cpan/l/Method-Extension.svg)](https://github.com/peczenyj/Method-Extension/blob/master/LICENSE)
[![cpan](https://img.shields.io/cpan/v/Method-Extension.svg)](https://metacpan.org/dist/Method-Extension)

# SYNOPSIS

    package Foo;
    # no baz method
    ...

    package Bar;

    use Method::Extension;

    sub baz :ExtensionMethod(Foo) {
        my ($self, ... ) = @_; # $self will be a Foo instance

        return "Baz from extension method";
    }
    ...

    Foo->new->baz();

# DESCRIPTION

One good definition of Method Extension can be found [here](https://msdn.microsoft.com/en-us/library/vstudio/bb383977\(v=vs.110\).aspx).

    Extension methods enable you to "add" methods to existing types without creating a new derived type, recompiling, or otherwise modifying the original type. Extension methods are a special kind of static method, but they are called as if they were instance methods on the extended type. For client code written in C# and Visual Basic, there is no apparent difference between calling an extension method and the methods that are actually defined in a type.

In other words, you can create, in C# for example, one subroutine and use a syntax sugar to invoke as a method. In other words, instead do this:

    my $foo = Foo->new;
    baz( $foo );

You can do:

    $foo->baz(); # magic!

# ATTRIBUTES

## ExtensionMethod

With this attribute we can insert one subroutine to one existing package.

Usage: `ExtensionMethod(Package)`.

Example:

    package Bar;

    sub baz :ExtensionMethod(Foo) {
        ...
    }

This inject the method Bar::baz into Foo::baz.

This attribute support multiple packages.

# LICENSE

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

# AUTHOR

Tiago Peczenyj &lt;tiago (dot) peczenyj (at) gmail (dot) com>

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/peczenyj/Method-Extension/issues](https://github.com/peczenyj/Method-Extension/issues)
