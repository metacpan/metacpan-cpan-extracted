package Debug::Flags;

use 5.008;

use strict;
use warnings;

use Carp;
use XSLoader;
use Scalar::Util;
use Scope::Guard;

our $VERSION = '0.26';

XSLoader::load 'Debug::Flags', $VERSION;

1;


=head1 NAME

Debug::Flags - set PL_debug flags at runtime

=head1 SYNOPSIS

  use strict;
  use Debug::Flags;
  Debug::Flags::set_flags(0x2);

  .. do something

=head1 DESCRIPTION

This module turns on the -D flags described in L<perlrun> in runtime,
if you have a debugging perl.

=head1 AUTHORS

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

=head1 COPYRIGHT

Copyright 2006 by Chia-liang Kao and others.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
