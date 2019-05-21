package MPM::MyApp::Info; # $Id$
use strict;
use utf8;

=head1 NAME

MPM::MyApp::Info - Info controller (/mpminfo)

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    GET /mpminfo

=head1 DESCRIPTION

Info controller (/mpminfo)

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

sub record {
    (
        -uri      => '/mpminfo',
        -response => sub { shift->mpminfo },
    )
}

1;

