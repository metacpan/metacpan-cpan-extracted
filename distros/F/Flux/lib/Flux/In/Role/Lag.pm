package Flux::In::Role::Lag;
{
  $Flux::In::Role::Lag::VERSION = '1.03';
}

# ABSTRACT: role for input streams which are aware of their lag


use Moo::Role;

requires 'lag';


1;

__END__

=pod

=head1 NAME

Flux::In::Role::Lag - role for input streams which are aware of their lag

=head1 VERSION

version 1.03

=head1 DESCRIPTION

Input streams implementing this role can be asked for the amount of data remaining in the stream.

Amount units are implementation-specific. Sometimes it's in bytes, sometimes it's in items.

=head1 METHODS

=over

=item B<lag()>

Get stream's lag.

=back

=head1 AUTHOR

Vyacheslav Matyukhin <me@berekuk.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
