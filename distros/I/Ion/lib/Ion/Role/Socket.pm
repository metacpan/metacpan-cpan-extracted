package Ion::Role::Socket;
$Ion::Role::Socket::VERSION = '0.02';
use common::sense;

use Moo::Role;

has host => (is => 'rw');
has port => (is => 'rw');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ion::Role::Socket

=head1 VERSION

version 0.02

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
