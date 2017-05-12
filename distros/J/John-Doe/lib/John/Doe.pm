package John::Doe;

use strict;
use warnings;

use 5.008_005;
our $VERSION = '0.01';


1;

__END__

=encoding utf-8

=head1 NAME

John::Doe - Test case duplicate file names in distribution

=head1 SYNOPSIS

  use John::Doe;

=head1 DESCRIPTION

Don't install or use it, except for testing module toolchains.

This distribution contains files in C<lib/>, C<t/> and C<share/> written in case variants.

At the time of release version 0.00 this distribution builds and passes all tests.

On environments with case insensitive filenames only one variant of the files survives.

=head1 AUTHOR

Helmut Wollmersdorfer E<lt>helmut.wollmersdorfer@gmx.atE<gt>

=head1 COPYRIGHT

Copyright 2014- Helmut Wollmersdorfer

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut

