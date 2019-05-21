package MPM::MyApp::Index; # $Id$
use strict;

=head1 NAME

MPM::MyApp::Index - Indexer of MyApp

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    none

=head1 DESCRIPTION

This module defines list of connected modules to the project.

=head2 init

Initializer of the project modules

=head1 HISTORY

See C<Changes> file

=head1 SEE ALSO

L<MPMinus>

=head1 AUTHOR

Mr. Anonymous E<lt>root@localhostE<gt>

=head1 COPYRIGHT

Copyright (C) 2019 Mr. Anonymous. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw($VERSION);
$VERSION = '1.00';

use base qw/
    MPM::MyApp::Root
    MPM::MyApp::Info
/;

#
# THE NEXT TWO LINES ARE NOT FOR EDITING! PLEASE DO NOT TOUCH THIS PART OF THE FILE
#

our @ISA;
sub init { my $d = shift; foreach (@ISA) { $d->set($_->record) } }

1;

