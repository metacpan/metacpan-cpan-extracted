package Gantry::Plugins::Uaf::Authorize;

use strict;
use warnings;

use Gantry::Plugins::Uaf::GrantAllRule;
use base qw(Gantry::Plugins::Uaf::AuthorizeFactory);

sub rules {
    my $self = shift;

    $self->add_rule(Gantry::Plugins::Uaf::GrantAllRule->new());

}

1;

__END__
  
Gantry::Plugins::Uaf::Authorize - A default authorization module.

=head1 DESCRIPTION

Gantry::Plugins::Uaf::Authorize is a pre-built module that uses 
Gantry::Plugins::Uaf::GrantAllRule to implement an authorization scheme. It
is a good idea to overide this module with something better.

=head1 SEE ALSO

 Gantry::Plugins::Uaf::GrantAllRule
 Gantry::Plugins::Uaf::AuthorizeFactory

=head1 AUTHOR

Kevin L. Esteb

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
