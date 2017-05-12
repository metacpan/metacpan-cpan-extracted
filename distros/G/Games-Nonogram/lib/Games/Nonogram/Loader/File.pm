package Games::Nonogram::Loader::File;

use strict;
use warnings;

sub load {
  my ($class, $file) = @_;

  my ($height, $width, @lines);
  open my $fh, '<', $file or die "Cannot open $file";
  while(<$fh>) {
    chomp;
    next if /^#/;
    if ( $_ eq '' ) {
      unless ( $height ) {
        $height = scalar @lines;
        next;
      }
      last; # should be the end of the column clues
    }
    push @lines, $_;
  }
  $width = (scalar @lines) - $height;

  return ($height, $width, @lines);
}

1;

__END__

=head1 NAME

Games::Nonogram::Loader::File

=head1 SYNOPSIS

  use Games::Nonogram::Loader::File;
  my ($h, $w, @lines) = Games::Nonogram::Loader::File->load( $file );

=head1 DESCRIPTION

This is used internally to load puzzle data from a file. 

=over 4

=item loader ignores lines which start with #

=item loader reads row clues first: a set of row clues per a line, and the row clues should be comma-separated.

=item loader regards the first blank line as the end of the row clues.

=item loader reads column clues, then, in the same manner.

=item loader regards end-of-file or the second blank line as the end of the column clues.

=back

In short, a file like below

  # row clues
  1
  3
  1,1,1
  3
  1
  
  # column clues
  1
  1,1
  5
  1,1
  1

would produce a puzzle like below.

  __X__
  _XXX_
  X_X_X
  _XXX_
  __X__

=head1 METHOD

=head2 load

takes a filename as an argument and reads its data.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Kenichi Ishigaki

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
