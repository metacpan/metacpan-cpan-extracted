package Encoding::FixLatin::XS;
{
  $Encoding::FixLatin::XS::VERSION = '1.01';
}

use 5.010000;
use strict;
use warnings;

our @ISA = qw();

require XSLoader;
XSLoader::load('Encoding::FixLatin::XS', $Encoding::FixLatin::XS::VERSION);

# Preloaded methods go here.

1;
__END__

=head1 NAME

Encoding::FixLatin::XS - XS implementation layer for Encoding::FixLatin

=head1 SYNOPSIS

  use Encoding::FixLatin  qw(fix_latin);    # will load XS module if available

  my $utf8_string = fix_latin($mixed_encoding_string);

=head1 DESCRIPTION

This module provides a C implementation of the 'fix_latin' algorithm.  It is
not meant to be called directly.  Instead, simply install this module and use
L<Encoding::FixLatin> as normal.  Encoding::FixLatin will use this module if
it's found and will fall back to the pure-Perl implementation otherwise.

The C<fix_latin> function accepts a C<use_xs> option which can be used to
control how this module is used:

  # Default behaviour: try to load/use XS module, fall back to PP on failure

  $out = fix_latin($in, use_xs => 'auto');

  # Always try to load/use XS module, die if it's not available

  $out = fix_latin($in, use_xs => 'always');

  # Never try to load/use XS module, always use pure-Perl implementation

  $out = fix_latin($in, use_xs => 'never');


=head1 SEE ALSO

L<Encoding::FixLatin>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Encoding::FixLatin::XS

You can also look for information at:

=over 4

=item * Issue tracker

L<https://github.com/grantm/encoding-fixlatin-xs/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Encoding::FixLatin::XS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Encoding::FixLatin::XS>

=item * Search CPAN

L<http://search.cpan.org/dist/Encoding::FixLatin::XS/>

=item * Source Code Respository

L<http://github.com/grantm/encoding-fixlatin-xs>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Grant McLean C<< <grantm@cpan.org> >>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
