use strict;
use warnings;
package Hg::Lib;

use 5.10.1;

our $VERSION = 0.01;

1;

__END__

=head1 NAME

Hg::Lib - interface to mercurial's command server

=head1 SYNOPSIS

  use HG::Lib;

  my $server = HG::Lib->new( );


=head1 DESCRIPTION

B<mercurial> is a distributed source control management
tool. B<Hg::Lib> is an interface to its command server.

B<THIS CODE IS ALPHA QUALITY.> This code is incomplete.  Interfaces may change.


=head1 AUTHOR

Diab Jerius E<lt>djerius@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This code is Copyright 2013 Diab Jerius.  All rights reserved.

This program is free software; you can redistribute and/or modify it
under the same terms as Perl itself.
