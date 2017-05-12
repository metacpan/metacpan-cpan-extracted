package Games::Nonogram;

use strict;
use warnings;

our $VERSION = '0.01';

sub bootstrap {
  my $class = shift;

  my $target = @ARGV ? 'CommandLine' : 'Shell';
  my $package = "Games::Nonogram::$target";
  eval qq{ require $package };
  die $@ if $@;
  $package->bootstrap;
}

1;

__END__

=head1 NAME

Games::Nonogram - solve and analyze Nonogram

=head1 SYNOPSIS

    use Games::Nonogram;
    Games::Nonogram->bootstrap;

=head1 DESCRIPTION

This is a simple utility to solve a puzzle called 'Nonogram'
(i.e. 'Paint by numbers', 'Griddlers' or whatever).
See L<http://en.wikipedia.org/wiki/Nonogram> for details
of the puzzle.

=head1 METHOD

=head2 bootstrap

bootstraps command line solver or solver shell, according to the
value(s) of @ARGV. See appropriate pods for details.

=head1 SEE ALSO

L<Games::Nonogram::CommandLine>, L<Games::Nonogram::Shell>

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Kenichi Ishigaki

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
