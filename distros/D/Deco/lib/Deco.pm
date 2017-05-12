package Deco;

use strict;
use warnings;

our $VERSION = '0.12';

1;
__END__

=head1 NAME

Deco - Module for simulating body tissue during a scuba dive

=head1 SYNOPSIS

  use Deco::Dive
  my $dive = Deco::Dive->new( model => 'haldane' );
  $dive->load_data_from_file( file => 'profile.txt' );
  $dive->gas( 'O2' => 40, 'N2' => 60);	
  $dive->simulate();

=head1 DESCRIPTION

The Deco package itself does not do anything useful, it only serves as the root of the other packages. You will want to look into the Deco::Dive module as that is the one to be using directly in your own scripts.

=head2 EXPORT

None by default.

=head1 SEE ALSO

An extensive treatment of the Haldane decompression theory is prodived in the Deco.pdf document which can be found in the docs directory.

=head1 AUTHOR

Jaap Voets, E<lt>narked@xperience-automatisering.nlE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Jaap Voets

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
