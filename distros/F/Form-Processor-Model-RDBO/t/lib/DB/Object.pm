package DB::Object;

use strict;

use base qw/ Rose::DB::Object /;

use DB;

sub init_db {
    my $self = shift;

    DB->new_or_cached( @_ );
}

=head1 AUTHOR

vti

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
