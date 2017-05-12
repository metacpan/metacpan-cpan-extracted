use strict;
use warnings;

package Devel::ChangePackage;
BEGIN {
  $Devel::ChangePackage::AUTHORITY = 'cpan:FLORA';
}
{
  $Devel::ChangePackage::VERSION = '0.08';
}
# ABSTRACT: Change the package code is currently being compiled in

use XSLoader;
use Sub::Exporter -setup => {
    exports => ['change_package'],
    groups  => { default => ['change_package'] },
};


XSLoader::load(
    __PACKAGE__,
    # we need to be careful not to touch $VERSION at compile time, otherwise
    # DynaLoader will assume it's set and check against it, which will cause
    # fail when being run in the checkout without dzil having set the actual
    # $VERSION
    exists $Devel::ChangePackage::{VERSION}
        ? ${ $Devel::ChangePackage::{VERSION} } : (),
);

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Devel::ChangePackage - Change the package code is currently being compiled in

=head1 SYNOPSIS

    package Foo;

    use Devel::ChangePackage;

    BEGIN { change_package 'Bar' }

    warn __PACKAGE__; # Bar

=head1 DESCRIPTION

This module allows you to tell perl what package code should be compiled
into. It's very similar to the C<package> statement, but allows you to use
variables and therefore to generate the package name to be used in any way you
want. Just like C<package>, this module only has compile-time effects.

Note that the effect of C<change_package> is B<NOT> lexically scoped the way
that package is.  For example:

    package Foo;

    sub routine { } # this gets defined in package Foo

    { package Bar; }

    sub other { } # this gets defined in package Foo, also

...but...

    package Foo;

    sub routine { } # this gets defined in package Foo

    {
        BEGIN { change_package('Bar') }
    }

    sub other { } # this gets defined in package Bar!

One way to think about this is changing the "argument" provided for the last
C<package> statement, or, if there was none yet, changing the default namespace
from C<main> to something else. It's not possible to make changes to the current
namespace outside of the currently compiling scope.

=head1 FUNCTIONS

=head2 change_package

    my $previous_package = change_package $new_package;

Changes the package code is being compiled in to C<$new_package>. The name of
the package things were compiled in before is returned.

=head1 EXAMPLE

With this module, it's possible to write the following code:

    package namespace::anon;

    use Devel::ChangePackage;

    my $i = 0;
    sub import {
        change_package 'namespace::anon::' . $i++;
    }

Which you could later use like:

    use namespace::anon; # "package namespace::anon::0;"
    sub foo { ... } # namespace::anon::0::foo

    use namespace::anon; # "package namespace::anon::1;"
    sub foo { ... } # namespace::anon::1::foo

That is, every C<use namespace::anon> will create a new "anonymous" package
under the C<namespace::anon::> namespace and make that the current package. All
code that is compiled afterwards, until the next change of package (by either
the C<package> statement or C<change_package>) will live in that anonymous
namespace.

=head1 AUTHOR

Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
