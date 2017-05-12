#!/usr/bin/env perl
use Modern::Perl;
use HackaMol;
use MCE;

my @pdbs    = glob("pdbs/*.pdb");


my $MAX_PROCESSES = 8;

my $mce = MCE->new(
   max_workers => $MAX_PROCESSES,
);

$mce->foreach(\@pdbs,
  sub {

    my ($self, $chunk_ref, $chunk_id) = @_;

    my $hack = HackaMol->new( name => "hackitup" );
    my $fpdb = $chunk_ref->[0];
    say $fpdb; 
    my $name = $fpdb;
    $name =~ s/\.pdb//;
    my @atoms = grep { $_->occ == 1.0} 
                grep { $_->Z   != 1  } $hack->read_file_atoms($fpdb);

    my @ss    = $hack->find_disulfides(@atoms);

    my $i = 0;
    foreach my $ss (@ss){
  
      my @cys_s = $ss->all_atoms;
      my @cut5 = grep {
                       $cys_s[0]->distance($_) <= 5.0 and
                       $cys_s[1]->distance($_) <= 5.0
                      } @atoms;
      my %resid;

      foreach my $at (@cut5){
        $resid{$at->resid}{$at->resname}{$at->chain}++; 
      }
      my @bigcut = grep {
                         exists( $resid{$_->resid}{$_->resname}{$_->chain} )
                        } @atoms;

      my $mol   = HackaMol::Molecule->new(
                                      name  =>  $name,
                                      atoms => [@bigcut],
                                     );
      $mol->print_pdb($name."_$i.pdb");
      $i++;

    }
    say scalar (@atoms); 
  }
);
#} 0 .. $#pdbs;
#}

