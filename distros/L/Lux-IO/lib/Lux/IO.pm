package Lux::IO;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.07';

require XSLoader;
XSLoader::load('Lux::IO', $VERSION);

1;

__END__

=head1 NAME

Lux::IO - A Perl Interface to Lux IO

=head1 SYNOPSIS

  use Lux::IO;
  use Lux::IO::Btree;

  my $bt = Lux::IO::Btree->new(Lux::IO::CLUSTER);
  $bt->open('test', Lux::IO::DB_CREAT);
  $bt->put('key', 'value', Lux::IO::OVERWRITE); #=> true
  $bt->get('key');                              #=> 'value'
  $bt->del('key');                              #=> true
  $bt->get('key');                              #-> false
  $bt->close;

=head1 DESCRIPTION

Lux IO is a yet another database manager. Lux::IO provides a Perl
interface to it. You must note that it supports only B+ Tree-based
database so far, though Lux IO supports also array-based database.

=head1 CAVEAT

Lux::IO now supports Lux IO library above version 0.2.1. You must
install it before trying to install this module.

=head1 METHODS

=head2 new ( I<$index_type> )

=over 4

  my $bt = Lux::IO::Btree->new(Lux::IO::CLUSTER);

Creates and returns a new Lux::IO::Btree object. C<$insert_type> can
be one of the types below:

=over 4

=item * Lux::IO::CLUSTER

=item * Lux::IO::NONCLUSTER

=back

=back

=head2 open ( I<$filename>, I<$oflags> )

=over 4

  $bt->open($filename, Lux::IO::DB_CREAT);

Opens a database specified by C<$filename>. C<$oflags> can be one of
or a combination of the flags below:

=over 4

=item * Lux::IO::DB_RDONLY

=item * Lux::IO::DB_RDWR

=item * Lux::IO::DB_CREAT

=item * Lux::IO::DB_TRUNC

=back

=back

=head2 close ()

=over 4

  $bt->close();

Closes the database.

=back

=head2 get ( I<$key> )

=over 4

  $bt->get($key);

Retrieves a value which is correspondent to the C<$key> from the
database.

=back

=head2 put ( I<$key>, I<$value>, I<$insert_mode> )

=over 4

  $bt->put($key, $value, Lux::IO::OVERWRITE);

Stores the key-value pair into the database. C<$insert_mode> can be
one of the modes below:

=over 4

=item * Lux::IO::OVERWRITE

=item * Lux::IO::NOOVERWRITE

=item * Lux::IO::APPEND

=back

=back

=head2 del ( I<$key> )

=over 4

  $bt->del($key);

Deletes the value which is correspondent to the C<$key>.

=back

=head1 SEE ALSO

=over 4

=item * Lux IO

http://luxio.sourceforge.net/

=back

=head1 AUTHOR

=item * Kentaro Kuribayashi E<lt>kentaro@cpan.orgE<gt>

=head1 ACKNOWLEDGMENT

=item * Tokuhiro Matsuno for much improvement of the codes.

=head1 COPYRIGHT AND LICENSE

Copyright (c) Kentaro Kuribayashi E<lt>kentaro@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
