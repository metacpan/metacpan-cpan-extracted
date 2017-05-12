package File::Gettext::Constants;

use strict;
use warnings;

use Exporter 5.57 qw( import );

our @EXPORT = qw( CONTEXT_SEP DIRECTORIES LOCALE_DIRS MAGIC_N
                  MAGIC_V PLURAL_SEP );

sub CONTEXT_SEP () {
   return "\004";
}

sub DIRECTORIES () { # TODO: Deprecated
   return LOCALE_DIRS();
}

sub LOCALE_DIRS () {
   return [ [ q(), qw(usr share locale) ],
            [ q(), qw(usr local share locale) ],
            [ q(), qw(usr lib locale) ] ];
}

sub MAGIC_N () {
   return 0x950412de;
}

sub MAGIC_V () {
   return 0xde120495;
}

sub PLURAL_SEP () {
   return "\000";
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

File::Gettext::Constants - Definitions of constant values

=head1 Synopsis

   use File::Gettext::Constants;

   my $magic = MAGIC_V;

=head1 Description

Exports a list of subroutines each of which returns a constant value

=head1 Subroutines/Methods

=head2 CONTEXT_SEP

Character used to separate the context from the message id in a gettext
.mo file

=head2 DIRECTORIES

=head2 LOCALE_DIRS

List of default system directories the might contain a .mo file

=head2 MAGIC_N

Magic number at start of .mo file

=head2 MAGIC_V

Magic number at start of .mo file (other byte order)

=head2 PLURAL_SEP

Character used to separate one plural string from another in a gettext
.mo file

=head1 Diagnostics

None

=head1 Configuration and Environment

None

=head1 Dependencies

=over 3

=item L<Sub::Exporter>

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
