package Nada::Zip;
#                                doom@kzsu.stanford.edu
#                                26 Apr 2007

use 5.006;
use strict; 
use warnings;
my $DEBUG = 1;
use Carp;
use Data::Dumper;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(
   stub
   skip
  );




our $VERSION = '0.01';

# Object code goes here.

sub skip {
  my $self       = shift;
  my $filter    = shift;
  my $input_aref = shift;

  my $pats = $filter->terms;
  my $mods = $filter->terms;


  my @result = ();

ITEM: 
  foreach my $item ( @{$input_aref} ) {
    my $skip_flag = 0;
    foreach my $pat ( @{ $pats } ) {
      if ($mods =~ m/i/){  # the "i" modifier is the only one supported by this stub
        if( $item =~ m/$pat/i ) {
          $skip_flag = 1;
        };
      } else {
        if( $item =~ m/$pat/ ) {
          $skip_flag = 1;
        }
      }
    }
    if ($skip_flag) {
      next ITEM;
    }

    push @result, $item;
  }

#  my $output_aref = ['i am a stub'];
#  return $output_aref;

  return \@result;
}




1;
__END__


=head1 NAME

Nada::Zip - doesn't quite not do nothing (or something -- nothing? -- like that)

=head1 SYNOPSIS

   use Nada::Zip;
   blah blah blah

=head1 DESCRIPTION

This stuby module is a little less stubby, has an actual 
"skip" method implemented. 


=head2 EXPORT

None by default.

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Joseph Brenner, E<lt>doom@kzsu.stanford.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Joseph Brenner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 BUGS

None reported... yet.

=cut
