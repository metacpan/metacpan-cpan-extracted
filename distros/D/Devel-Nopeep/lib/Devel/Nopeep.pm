package Devel::Nopeep;
our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Devel::Nopeep', $Devel::Nopeep::VERSION);

1;
__END__

=head1 NAME

Devel::Nopeep - Disable the peephole optimiser

=head1 SYNOPSIS

  perl -MDevel::Nopeep -MO=Concise,baz -e 'sub baz { if (1) { return 2; } }'

Or in a program (near the top):

  use Devel::Nopeep;

=head1 DESCRIPTION

This module disables the peephole optimiser. This is really only useful if you 
want to benchmark the differences between an optimised block and a 
non-optimised block, or if you want to see what an op tree looks like 
before it's optimised.

You should NOT use this in production code, as it may introduce bugs since the 
peephole optimiser is probably responsible for more than just optimisations.

This is intended as a tool for help with development of Perl itself.

=head1 AUTHOR

Matthew Horsfall (alh) - <wolfsage@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Matthew Horsfall

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
