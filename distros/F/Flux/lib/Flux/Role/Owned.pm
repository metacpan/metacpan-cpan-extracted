package Flux::Role::Owned;
{
  $Flux::Role::Owned::VERSION = '1.03';
}

use Moo::Role;

# ABSTRACT: role for stream objects that belong to a specific user


requires 'owner';


1;

__END__

=pod

=head1 NAME

Flux::Role::Owned - role for stream objects that belong to a specific user

=head1 VERSION

version 1.03

=head1 METHODS

=over

=item B<owner()>

Get object owner's login string.

=back

=head1 AUTHOR

Vyacheslav Matyukhin <me@berekuk.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
