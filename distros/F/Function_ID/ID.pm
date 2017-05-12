=for gpg
-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA1

=head1 NAME

Function::ID - Variables to let functions know their names.

=head1 VERSION

This documentation describes version 0.02 of Function::ID, March 29, 2003.

=cut

use strict;
package Function::ID;
use Carp;
use vars '$VERSION';
$VERSION = 0.02;

use vars '$this_fn', '$this_function';

sub TIESCALAR
{
    my $class = shift;
    my $name = shift;
    return bless \$name, $class;
}

sub STORE
{
    my $self = shift;
    croak "Attempt to assign to \$$$self";
}

sub FETCH
{
    my $self = shift;
    my $callfunc = (caller 1)[3];
    $callfunc =~ s/.*::// if $$self eq 'this_fn';
    return $callfunc;
}



tie $this_fn,       __PACKAGE__, 'this_fn';
tie $this_function, __PACKAGE__, 'this_function';

sub import
{
    my $caller_pkg = caller;

    no strict 'refs';
    *{$caller_pkg."::this_fn"}       = \$this_fn;
    *{$caller_pkg."::this_function"} = \$this_function;
}

1;    # Modules must return true, for silly historical reasons.
__END__

=head1 SYNOPSIS

 use Function::ID;
 
 sub your_routine {
     print "Hi, I'm $this_function, or $this_fn for short!\n";
 }

Output:

 Hi, I'm main::your_routine, or your_routine for short!


=head1 DESCRIPTION

This module provides two tied variables, C<$this_function> and
C<$this_fn>, which when invoked contain the name of the function
they're being used in.  In other words, they return the identity of
the function that uses them.  This can be useful for log, error, or
debug messages.

Both these variables contain C<undef> in the main portion of a
program's code (ie, outside of any function body).


=head1 VARIABLES

=over 4

=item $this_function

C<$this_function> returns the fully-qualified name of the current function,
including its package.  For example: C<'Foo::Bar::Baz::my_function'>.

=item $this_fn

C<$this_fn> returns the name of the current function, with no package name.
For example: C<'my_function'>.

=back


=head1 EXPORTS

This module exports the following symbols into the caller's namespace:

 $this_function
 $this_fn


=head1 REQUIREMENTS

 Carp.pm (included with Perl)


=head1 AUTHOR / COPYRIGHT

Eric J. Roode, roode@cpan.org

Copyright (c) 2003 by Eric J. Roode. All Rights Reserved.  This module
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

If you have suggestions for improvement, please drop me a line.  If
you make improvements to this software, I ask that you please send me
a copy of your changes. Thanks.

=cut

=begin gpg

-----BEGIN PGP SIGNATURE-----
Version: GnuPG v1.2.1 (GNU/Linux)

iD8DBQE+hmOuY96i4h5M0egRAtFvAJ94wqEA6stWYPYxOEGGXbFzAKOnrwCgqPNS
MuQPZv8XxmFFeAa7OvAF4mk=
=ltgt
-----END PGP SIGNATURE-----

=end gpg
