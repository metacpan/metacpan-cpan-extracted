package Graph::Dependency;

use 5.008000;
use strict;
use warnings;

use vars qw/$VERSION/;

$VERSION = '0.02';

1;
__END__

=head1 NAME

Graph::Dependency - Generate dependency graphs and reports

=head1 SYNOPSIS

  ./graph YAML
  ./graph Foo-Bar html

=head1 DESCRIPTION

The script graph.pl will generate a dependency tree from the
given module name. It does this by fetching recursively the
META.yml file for each module, and then extracting the prerequisites
from this file. 

=head1 SEE ALSO

L<CPANTS::Dependency>, L<Graph::Easy>.

=head1 AUTHOR

(C) 2006 by Tels at bloodgate.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Tels

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
