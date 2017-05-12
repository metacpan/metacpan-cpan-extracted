package MacOSX::File::Exchange;

use 5.008006;
use strict;
use warnings;

require constant;
require XSLoader;

our $VERSION = '0.01';

our @EXPORT_OK =
    qw(exchangedata FSOPT_NOFOLLOW);

our @EXPORT =
    qw(exchangedata);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK
);

XSLoader::load('MacOSX::File::Exchange', $VERSION);

constant::->import(_make_constants());

require Exporter;

our @ISA =
    qw(Exporter);

1;
__END__

=head1 NAME

MacOSX::File::Exchange - Perl access to the exchangedata system call

=head1 SYNOPSIS

  use MacOSX::File::Exchange;

  exchangedata("newfile", "oldfile");

or

  use MacOSX::File::Exchange qw(:all);

  exchangedata("newfile", "oldfile", FSOPT_NOFOLLOW);

=head1 DESCRIPTION

The Darwin/Mac OS X system call C<exchangedata> atomically exchanges
the contents and modification dates of two regular files, leaving
all other metadata unchanged (this includes the inode numbers).

Expected arguments are two path strings and a flags integer.
An omitted flags argument is interpreted as 0.

Available flags:

=over 4

=item FSOPT_NOFOLLOW

Do not follow leaf symlinks in paths.

=back

=head1 EXPORTS

=over 4

=item By default:

exchangedata

=item On request:

FSOPT_NOFOLLOW

=back

=head1 SEE ALSO

L<exchangedata(2)> in your Darwin manual.

=head1 AUTHOR

Bo Lindbergh, E<lt>blgl@stakcen.kth.seE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Bo Lindbergh

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

=cut
