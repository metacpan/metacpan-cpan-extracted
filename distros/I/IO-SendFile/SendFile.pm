package IO::SendFile;

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
	
);
@EXPORT_OK = qw( sendfile );
$VERSION = '0.01';

bootstrap IO::SendFile $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

IO::SendFile - Perl extension that implements the sendfile() interface.

=head1 SYNOPSIS

  use IO::SendFile;
  IO::SendFile::sendfile( fileno(OUT), fileno(IN), $offset, $count );
  # Send file everything from filehandle IN from offset	
  # $offset and send $count bytes.

  use IO::SendFile qw( sendfile ); # import the senfile function
  sendfile( fileno(OUT), fileno(IN), $offset, $count );
	

=head1 DESCRIPTION

IO::SendFile implements the sendfile() function call.  This version
only works on linux.

IO::SendFile is released under the same conditions as perl itself.

=head1 AUTHOR

Arnar M. Hrafnkelsson, addi@umich.edu

=head1 SEE ALSO

perl(1).
sendfile(2).

=cut
