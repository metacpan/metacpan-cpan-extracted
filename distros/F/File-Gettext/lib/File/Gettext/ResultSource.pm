package File::Gettext::ResultSource;

use namespace::autoclean;

use File::DataClass::Types qw( HashRef );
use Moo;

extends q(File::DataClass::ResultSource);

has 'language_dependent' => is => 'ro', isa => HashRef, default => sub { {} };

1;

__END__

=pod

=encoding utf-8

=head1 Name

File::Gettext::ResultSource - Result source localisation

=head1 Synopsis

=head1 Description

Extends L<File::DataClass::ResultSource>

=head1 Configuration and Environment

Defines these attributes

=over 3

=item C<language_dependent>

Is a hash reference of language dependent attributes names. The values are just
set to true

=back

=head1 Subroutines/Methods

None

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<File::DataClass::ResultSource>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2016 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
