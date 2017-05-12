package Drogo::Server;
use strict;

my %SERVER_VARIABLES;

sub initialize { }
sub cleanup    { }
sub post_limit { shift->variable('post_limit') || 1_048_576 }

=head1 NAME

Drogo::Server - Shared methods for server implementations

=cut

=head1 AUTHORS

Bizowie <http://bizowie.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 Bizowie

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
