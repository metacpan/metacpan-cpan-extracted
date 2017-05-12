package Hash::Identity;

use warnings;
use strict;

=head1 NAME

Hash::Identity - Get a hash that always returns the key

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use Hash::Identity qw(e);

    print "The result is: $e{ 1 + 2 }\n";
    print "sin(1) = $e{ sin(1) }\n";

    # Or you wish to import multiple. though I think one is usually sufficient.

    use Hash::Identity qw(ident expr);

    print "You could use expr like this: $expr{2**3}.\n";
    print "Or you could use ident $ident{ 'a' . 'b' } as well.\n";

    # NOTE

    use Hash::Identity qw(e);
    print "If you want to just call a sub without params. Don't use $e{ rand }. Use $e{ rand() } instead.\n";

=head1 DESCRIPTION

To get a hash that always returns the key.

A hash that always returns the key is useful when interpolating EXPR in a double quoted string.

This module uses L<Tie::Hash::Identity> to achieve this,
and provides a better importing interface.

=head1 EXPORT

This module will not export anything by default.
You could assign each name you want to use like this:

    use Hash::Identity qw(a b c);

Then you will have identity hash %a, %b, and %c.

=cut

use Tie::Hash::Identity;

tie our %e, 'Tie::Hash::Identity';

sub import {
    shift;
    no strict 'refs';
    *{caller()."::$_"} = \%e for @_;
}

=head1 SEE ALSO

L<Tie::Hash::Identity>

=head1 AUTHOR

Cindy Wang (CindyLinz)

=head1 BUGS

Please report any bugs or feature requests to C<bug-hash-identity at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-Identity>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 LICENSE AND COPYRIGHT

Copyright 2010 Cindy Wang (CindyLinz).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Hash::Identity
