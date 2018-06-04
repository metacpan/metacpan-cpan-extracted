package MVC::Neaf::View::Dumper;

use strict;
use warnings;

our $VERSION = 0.2501;

=head1 NAME

MVC::Neaf::View::Dumper - Data::Dumper interface for Not Even A Framework

=head1 USAGE

Use the following to debug your application:

     perl -MMVC::Neaf=view,Dumper <your_application> '/path/to?foo=42&bar=137'

Maybe this module could also be useful if you want to frighten you site's
users to death on April, 1.

=head1 METHODS

=cut

use Data::Dumper;
use parent qw(MVC::Neaf::View);

=head2 render( \%data )

Return a Perl dump and "text/plain".

=cut

sub render {
    my ($self, $data) = @_;

    local $Data::Dumper::Indent = 1;

    return (Dumper($data), "text/plain");
};

=head1 LICENSE AND COPYRIGHT

This module is part of L<MVC::Neaf> suite.

Copyright 2016-2018 Konstantin S. Uvarin C<khedin@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
