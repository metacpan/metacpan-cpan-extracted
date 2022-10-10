package Game::SDL;

use 5.028002;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Game::SDL ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.1.1';


# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Game::SDL - Perl extension for making games with SDL(1) 

=head1 SYNOPSIS

  use Game::SDL;

=head1 DESCRIPTION

The meaning is to provide a functionality for having several game types using
SDL for graphics, sound and events. It might be featured in a OOP way but
some more for clean code.

=head2 EXPORT

=head1 SEE ALSO

=head1 AUTHOR

koboldwiz, E<lt>koboldwiz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by koboldwiz 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.28.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
