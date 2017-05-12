package Labyrinth::Query::PSGI;

use warnings;
use strict;

our $VERSION = '1.02';

=head1 NAME

Labyrinth::Query::PSGI - Environment Handler via PSGI for Labyrinth.

=head1 SYNOPSIS

  use Labyrinth::Query::PSGI;
  my $cgi = Labyrinth::Query::PSGI->new();

  $cgi->Vars();
  $cgi->cookie();

=head1 DESCRIPTION

A very thin wrapper around CGI::PSGI

=cut

# -------------------------------------
# Library Modules

use base qw(CGI::PSGI);
use CGI::Cookie;

# -------------------------------------
# The Subs

=head1 METHODS

All methods are as per CGI::PSGI.

=cut

1;

__END__

=head1 SEE ALSO

L<CGI::PSGI>,
L<Labyrinth>

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2013-2014 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
