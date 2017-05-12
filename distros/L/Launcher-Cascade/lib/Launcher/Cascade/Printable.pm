package Launcher::Cascade::Printable;

=head1 NAME

Launcher::Cascade::Printable - a base class for printable objects

=head1 SYNOPSIS

    package MyPrintable;
    use base qw( Launcher::Cascade::Printable );

    sub new {

        ...
    }

    sub as_string {

        my $self = shift;
        ...
    }

    1;

=head1 DESCRIPTION

This class serves as a base class for objects that might be included in a
launcher's errors list.

=cut

use strict;
use warnings;

use overload '""' => 'as_string';

=head2 Methods

=over 4

=item B<as_string>

Subclasses of Launcher::Cascade::Printable should overload this method to
return a string representing their content. as_string() will be invoked when
the object is interpolated in a double-quoted string, or in any situation where
it is "stringified".

=cut

sub as_string {}

=back

=head1 SEE ALSO

L<Launcher::Cascade::Base>, L<Launcher::Cascade::ListOfStrings>.

=head1 AUTHOR

Cédric Bouvier C<< <cbouvi@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2006 Cédric Bouvier, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1; # end of Launcher::Cascade::Printable
