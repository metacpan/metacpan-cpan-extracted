package Devel::GC::Helper;

use 5.008006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
                                   sweep
                                   ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.25';

require XSLoader;
XSLoader::load('Devel::GC::Helper', $VERSION);


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Devel::GC::Helper - Perl extension for finding unused variables

=head1 SYNOPSIS

  use Devel::GC::Helper;
  my $leaks = Devel::GC::Helper::sweep;
  foreach my $leak (@$leaks) {
      print "Leaked $leak";
  }

=head1 DESCRIPTION

This module walks the entire perl space, from main:: and notes
what it has found, then it walks all SVs that are active and tells
you which ones are potential leaks.

=head2 EXPORT

None by default.

=over 4

=item sweep()

Returns an arrayref of references to all containers that it didn't find in the
mark phase.

=back

=head1 SEE ALSO

This module can be used together with Devel::Cycle to find where there is a leak.

You can trac the repository at http://code.sixapart.com/trac/Devel-GC-Helper/

=head1 BUGS

Will only work in threaded perl correctly, it won't find regular expressions in
non threaded perl because it is not walking the op tree. Nor will it find constants.

Leaked regular expressions won't be reported, because I can't figure out
how to tell if they are active or not, I also haven't looked closely at it
since I don't have much of a problem with leaking regexen.

There are three variables, tvo magic elements and one array that I have not
tracked down where they come from that are always reported as leaked. I
suspect they are from within DynaLoader/Exporter.

=head1 AUTHOR

Artur Bergman, E<lt>sky@crucially.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Artur Bergman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
