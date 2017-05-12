package Math::Derivative_XS;

use 5.010000;
use strict;
use warnings;

require Exporter;
use Math::Derivative;

our @ISA = qw(Exporter Math::Derivative);

our %EXPORT_TAGS = ( 'all' => [ qw(
                                      Derivative2
                                      Derivative1
                              ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Math::Derivative_XS', $VERSION);

sub Derivative1 { &Math::Derivative::Derivative1; };

1;
__END__

=head1 NAME

Math::Derivative_XS - Provides an XS implementation for part of Math::Derivative (and fallsback to Perl for the rest)

=head1 SYNOPSIS

  use Math::Derivative_XS qw(Derivative1 Derivative2);
  @dydx=Derivative1(\@x,\@y);
  @d2ydx2=Derivative2(\@x,\@y);
  @d2ydx2=Derivative2(\@x,\@y,$yp0,$ypn);

=head1 DESCRIPTION

Provides an XS implementation for part of Math::Derivative (and fallsback to Perl for the rest).

=head2 EXPORT

=over

=item 4 Derivative1 (currently inherits the pure perl version from Math::Derivative)

=item 4 Derivative2

=back

=head1 SEE ALSO

L<Math::Derivative>

=head1 CAVEATS

This module's tests only confirm no regression from Math::Derivative, not correctness of the maths.

=head1 AUTHOR

Mark Aufflick, E<lt>mark@pumptheory.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Mark Aufflick, Pumptheory Pty Ltd

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
