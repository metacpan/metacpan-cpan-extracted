package Drogo::RequestResponse;

use base qw(
    Drogo::Guts
);

use strict;

sub new 
{
    my $class = shift;
    my $self = {};
    bless($self);
    return $self;
}

=head1 AUTHORS

Bizowie <http://bizowie.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 Bizowie

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
