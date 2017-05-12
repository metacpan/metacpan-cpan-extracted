package Labyrinth::Query::CGI;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '5.32';

=head1 NAME

Labyrinth::Query::CGI - Environment Handler via CGI for Labyrinth.

=head1 SYNOPSIS

  use Labyrinth::Query::CGI;
  my $cgi = Labyrinth::Query::CGI->new();

  $cgi->Vars();
  $cgi->cookie();

=head1 DESCRIPTION

A very thin wrapper around CGI.pm.

=cut

# -------------------------------------
# Library Modules

use base qw(CGI);
use CGI::Cookie;

# -------------------------------------
# The Subs

=head1 METHODS

All methods are as per CGI.pm.

=cut

1;

__END__

=head1 SEE ALSO

  CGI,
  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
