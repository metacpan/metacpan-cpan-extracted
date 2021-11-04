package FindApp::Object;

use v5.10;
use strict;
use warnings;
use mro "c3";

use FindApp::Utils ":package";
use namespace::clean;
use parent implementation with <Loader Devperl Overloading Shortcuts>;

# Ok, I fibbed. This pulls in the debugging and tracing methods.
use FindApp::Utils <debugging tracing>;

1;

=encoding utf8

=head1 NAME

FindApp::Object - Class to hold the FindApp object implementation and roles

=head1 DESCRIPTION

This class, which is purely declarative, holds the implementation of the 
FindApp Object class along with its roles.  The only difference between 
this and the general L<FindApp> class is that the latter also ropes in the
L<FindApp:Exporter>.  

=head2 Public Methods

=over

=item FIXME

=back

=head2 Exports

=over

=item FIXME

=back

=head1 EXAMPLES

=head1 ENVIRONMENT

=head1 SEE ALSO

=over

=item L<FindApp>

=back

=head1 CAVEATS AND PROVISOS

=head1 BUGS AND LIMITATIONS

=head1 HISTORY

=head1 AUTHOR

Tom Christiansen << <tchrist@perl.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2016, Tom Christiansen C<< <tchrist@perl.com> >>.
All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

