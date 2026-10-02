package Langertha::Raider::Binary;
# ABSTRACT: Internal check whether raider runs as the standalone binary
our $VERSION = '0.503';

use strict;
use warnings;
use Path::Tiny;

use Exporter 'import';
our @EXPORT_OK = qw( packed_binary );


sub packed_binary {
  return unless $INC{'PAR.pm'} && $ENV{PAR_PROGNAME};
  return path($ENV{PAR_PROGNAME})->absolute->stringify;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Binary - Internal check whether raider runs as the standalone binary

=head1 VERSION

version 0.503

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The standalone C<raider> binary is built with PAR::Packer. Inside it there
is no usable perl of its own: C<$^X> is a bare C<perl> off C<PATH>, and
C<perl E<lt>binaryE<gt>> dies on the ELF. Code that starts a perl, or a
raider, asks this module first.

=head2 packed_binary

    my $exe = packed_binary();   # undef unless this is the standalone binary

Returns the absolute path of the executable this process runs from when it
is a PAR::Packer binary, else C<undef>. F<PAR.pm> loaded in this process is
the signal, together with C<PAR_PROGNAME>. The variable alone is not: a
plain perl started from the binary inherits it.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-raider/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
