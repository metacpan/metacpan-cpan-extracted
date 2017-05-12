package HPSG::Mason::Interp;
use strict;

=head1 NAME

HPSG::Mason::Interp - Mason components for rendering Head-driven Phrase Structure Grammar feature structures to \LaTeX

=cut

use base qw( HTML::Mason::Interp );

use HTML::Mason;
use FindBin;
use File::Spec;

use File::ShareDir;

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

  use HPSG::Mason::Interp;

  my %phrase;

  $phrase{I} =
    {
     expression_arg =>
     {
      expr_type => 'phrase',
      syn_arg => { head_arg => { pos     => 'noun',
                                 agr_arg => { agr_cat => '1sing',
                                              per     => '1st',
                                              num     => 'sg',
                                            },
                                 case    => 'nom'
                               },
                   val_arg  => { spr   => [ ],
                                 comps => [ ],
                                 mod   => [ ],
                               }
                 },
      sem_arg => { mode  => 'ref',
                   index => '{\it i}',
                   restr => [ { reln => 'speaker',
                              inst => 'i',
                              } ]
                 }
     },
     tag => 9,
     daughters => [ 'I' ],
    };

  my $outbuf;
  my $interp = HPSG::Mason::Interp->new( outbuf => \$outbuf);

  $interp->exec( '/tree.mas', { root => $phrase{I} } );

  my $fname = 'lex_I.tex';

  open( my $fh, q{>}, $fname ) or die "couldn't open file '$fname': $!";
  print $fh $outbuf;
  close $fh;

=head1 FUNCTIONS

=head2 new

See HTML::Mason::new, we just add the search path for some stock components

=cut

sub new {
  my $class = shift;
  my %args = @_;

  my $share_dir = File::ShareDir::dist_dir('HPSG-Mason');
  my %data_dir = exists $args{data_dir} ? ( data_dir => $args{data_dir} ) : ();
  my $comp_root = $args{comp_root} || [];

  return
      HTML::Mason::Interp->new( comp_root  =>
				[ [ 'HPSG-Mason' => File::Spec->catfile( $share_dir,'comps' ) ],
				  @$comp_root,
				],
				%data_dir,
				out_method => $args{outbuf},
			      );
}

=head1 AUTHOR

C.J. Adams-Collier, C<< <cjac at u.washington.edu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-hpsg-mason at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HPSG-Mason>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HPSG::Mason::Interp


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HPSG-Mason>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HPSG-Mason>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HPSG-Mason>

=item * Search CPAN

L<http://search.cpan.org/dist/HPSG-Mason>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 C.J. Adams-Collier, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of HPSG::Mason::Interp
