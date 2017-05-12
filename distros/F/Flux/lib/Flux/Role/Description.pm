package Flux::Role::Description;
{
  $Flux::Role::Description::VERSION = '1.03';
}

use Moo::Role;

# ABSTRACT: role for stream objects that implement 'description'


requires 'description';


1;

__END__

=pod

=head1 NAME

Flux::Role::Description - role for stream objects that implement 'description'

=head1 VERSION

version 1.03

=head1 METHODS

=over

=item B<description()>

String with object's description.

Should not end with "\n" but can contain "\n" in the middle of the string.

=back

=head1 AUTHOR

Vyacheslav Matyukhin <me@berekuk.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
