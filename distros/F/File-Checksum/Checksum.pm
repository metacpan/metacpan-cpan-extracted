package File::Checksum;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
Checksum	
);
$VERSION = '0.01';

bootstrap File::Checksum $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

File::Checksum - Perl extension for fast and easy File-Checksum-Algorithm

=head1 SYNOPSIS

  use File::Checksum;
  my $checksum = Checksum('filename', 100);

=head1 DESCRIPTION

 The first parameter is the file name.
 The second parameter is the number of bytes being included
 into the checksum-Algorithm.
 To avoid carry outs the number should not be bigger as 65537.

=head2 EXPORT

 Checksum

=head1 AUTHOR

Torsten Knorr, create-soft@freenet.de

=head1 SEE ALSO

 http://freenet-homepage.de/torstenknorr

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Torsten Knorr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.9.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

