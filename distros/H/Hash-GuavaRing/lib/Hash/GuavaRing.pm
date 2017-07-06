package Hash::GuavaRing;

use 5.010;
use strict;
use warnings;


our $VERSION = '0.04';

require XSLoader;
XSLoader::load('Hash::GuavaRing', $VERSION);

1;
__END__

=head1 NAME

Hash::GuavaRing - Consistent ring hashing using guava hash

=head1 SYNOPSIS

  use Hash::GuavaRing;

  my $ring = Hash::GuavaRing->new(
    nodes => [
      $node0,
      $node1,
    ]
  );

  my $node = $ring->get(crc32("key"));

=head1 DESCRIPTION



=head1 SEE ALSO

https://github.com/Mons/guava-hash

=head1 AUTHOR

Sveta Kotleta <ktl@cpan.org>

=head1 ACKNOWLEDGEMENTS

Mons Anderson <mons@cpan.org>

=head1 LICENSE

Copyright (C) 2017 by Sveta Kotleta

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
