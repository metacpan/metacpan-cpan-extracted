package Devel::Command::Viz;

use 5.006;
use strict;
use warnings;
use GraphViz::Data::Structure;
use File::Temp qw(tempfile);

use base qw(Devel::Command);

our $VERSION = '0.02';

sub command {
  my ($arg) = (shift =~ /viz\s+(.*)/);
  chomp $arg;
  my $gvds = new GraphViz::Data::Structure(&eval($arg));
  my ($fh, $filename) = tempfile();
  print $fh $gvds->graph->as_canon;
  close $fh;
  system "dotty $filename";
  1;
}

1;
__END__

=head1 NAME

Devel::Command::Viz - graph data structures under the debugger

=head1 SYNOPSIS

  # in .perldb:
  use Devel::Command;
  sub afterinit {
     Devel::Command->install;
  }

  # In the debugger:
  DB<1> my $a = [1, 2, {3=>4}, [5.6]]
  DB<2> viz $a

  # A 'dotty' window pops up, showing the data structure.

=head1 DESCRIPTION

C<Devel::Command::Viz> is a debugger extension command plugin for Devel::Command.
It uses C<GraphViz::Data::Structure> to visualize a Perl data structure and
C<dotty> to display the resultant graph.

=head1 ROUTINES

=head2 command

Standard C<Devel::Command> wrapper code to parse a debugger command line,
render the graph, and display it.

=head1 BUGS

None known; it's possible that the resultant graphs may have probelms due
to as-yet-uncaught bugs in C<GraphViz::Data::Structure>.

The command will not work if you have no way of running C<dotty>, which 
requires X Windows to be running.

=head1 SEE ALSO

C<perl5db.pl>, C<Devel::Command>, C<dotty>

=head1 AUTHOR

Joe McMahon, E<lt>mcmahon@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Joe McMahon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
