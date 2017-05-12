package Games::Nonogram::CommandLine;

use strict;
use warnings;
use Getopt::Long;
use Games::Nonogram::Grid;

sub bootstrap {
  my $class = shift;

  my %options;
  GetOptions(
    'dir=s'      => \$options{dir},
    'check_only' => \$options{check_only},
    'debug'      => \$options{debug},
    'verbose'    => \$options{verbose},
  );

  my @files = @ARGV;
  push @files, $class->_files_from_dir( $options{dir} ) if $options{dir};

  foreach my $file ( @files ) {
    $class->_solve( $file, \%options );
  }
}

sub _files_from_dir {
  my ($class, $dir) = @_;

  $dir .= '/' unless $dir =~ m{[/\\]$};
  $dir .= '*';

  my @dirs = grep { /^[^\.]/ && -f } glob( $dir );
}

sub _solve {
  my ($class, $file, $options) = @_;

  return unless $file && -f $file;

  my $grid = Games::Nonogram::Grid->new_from( file => $file );

  my $debug      = $options->{debug} || 0;
  my $verbose    = $options->{verbose} || $debug;
  my $check_only = $options->{check_only} || 0;

  $grid->debug( $debug );

  while ( $grid->is_dirty ) {
    $grid->update;
    print $grid->as_string,"\n" if $verbose;
  }

  if ( $grid->is_done or $grid->has_answers ) {
    my @answers = $grid->answers;
    unless ( $check_only ) {
      print "\n$file: Answers\n", join "\n", @answers;
    }
    elsif ( @answers > 1 ) {
      print "$file is ambiguous.\n";
    }
    else {
      print "$file is ok.\n";
    }
  }
  else {
    unless ( $check_only ) {
      print "\n$file: Failed\n";
      print $grid->as_string,"\n";
    }
    else {
      print "$file seems broken.\n";
    }
  }
}

1;

__END__

=head1 NAME

Games::Nonogram::CommandLine

=head1 SYNOPSIS

  use Games::Nonogram::CommandLine;
  Games::Nonogram::CommandLine->bootstrap;

=head1 DESCRIPTION

This module is used internally to handle command line interface.

=head1 METHODS

=head2 bootstrap

takes several command line options and passes them to the solver. Options are:

=over 4

=item dir

lets the solver load and process each file under the specified directory.

=item check_only

If this is set, the solver would not show you the answer of the puzzle(s), but tell you whether the puzzle(s) is solvable, or ambiguous (or, unsolvable).

=item verbose

If this is set, the solver would show you the process of solving.

=item debug

If this is set, the solver would become more verbose and show you more messages.

=back

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Kenichi Ishigaki

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
