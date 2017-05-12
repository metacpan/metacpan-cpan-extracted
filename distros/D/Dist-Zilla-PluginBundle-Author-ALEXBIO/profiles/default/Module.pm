package {{$name}};

use strict;
use warnings;

=head1 NAME

{{$name}} - Module to do something

=head1 SYNOPSIS

    use {{$name}};

    ...

=head1 DESCRIPTION

Some description here...

=head1 METHODS/SUBROUTINES

=head2 my_sub( $args )

Subroutine to do something

=cut

sub my_sub {

	...

}

=head1 INTERNAL METHODS

=head2 _my_sub( $args )

Subroutine to do something

=cut

sub _my_sub {

	...

}

=head1 AUTHOR

{{@{$dist->authors}[0]}}

=head1 LICENSE AND COPYRIGHT

Copyright {{(localtime)[5] + 1900}} {{$dist->copyright_holder}}.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of {{$name}}
