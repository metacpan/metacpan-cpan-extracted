package FindApp::Object::State::Group;

use v5.10;
use strict;
use warnings;
use mro "c3";

use FindApp::Utils ":package";
use namespace::clean;
use parent implementation with "Overloading";

1;

__END__

=encoding utf8

=head1 NAME

FindApp::Object::State::Group - implement a FindApp constraint group

=head1 DESCRIPTION

This is the internal class used to implement L<FindApp> constraint groups,
with overloading.  Everything of interest is in the parent implementation.

=head1 SEE ALSO

=over

=item L<FindApp>

=item L<FindApp::Object>

=item L<FindApp::Object::Class>

=item L<FindApp::Object::State>

=item L<FindApp::Object::State::Group::State::Dirs>

=item L<FindApp::Object::Behavior>

=item L<FindApp::Object::Behavior::Overloading>

=back

=head1 BUGS AND LIMITATIONS

This man page is longer than the source code is.

There is no current way to override the specific class used for this, 
since it is in a "has-a" relationship to the L<FindApp::Object> proper.

=head1 AUTHOR

Tom Christiansen C<< <tchrist@perl.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2016, Tom Christiansen C<< <tchrist@perl.com> >>.
All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

