package Hoppy::Service::Base;
use strict;
use warnings;
use base qw(Hoppy::Base);

__PACKAGE__->mk_virtual_methods($_) for qw( work );

1;
__END__

=head1 NAME

Hoppy::Service::Base - Base class of Hoppy::Service. 

=head1 SYNOPSIS

  package My::Service::Class;
  use base qw(Hoppy::Service::Base);

=head1 DESCRIPTION

Base class of Hoppy::Service. 

Derived classes of Hoppy::Serivce::Base must implement work() method.

=head1 METHODS

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
