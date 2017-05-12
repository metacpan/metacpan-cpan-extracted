# Demian Riccardi May 20, 2014
#
# This script is for running virtual screens using Autodock Vina.  This is a work in
# progress...  Eventually, the functionality will be encapsulated in a class for screening.
# Obviously, this needs to be reworked to use a proper database!
#
# INPUT:
#   this script reads in a YAML configuration file passed on commandline:
#   $yaml->{in_json} is the path to the json file containing independent data
#   for each receptor. The first run, there will be no docking information present.
#   The json file will contain the receptor information (TMass(kD), formula, BEST => {BE = 0},
#   etc. ). This script iterates (see JSON::XS on metacpan) through this json loaded by 
#   receptor and running the ligands from the YAML configuration file. The centers are   
#   determined on the fly!  the script below uses disulfid bonds, which was relevant for the 
#   HackaMol paper.
#
#   You are encouraged load the json file and then dump it with YAML early and often
#   to get oriented with the datastructure.
#
#   The num_modes will always be 1 for screens; i don't see the point (yet) of additional 
#   configs for virtual screens.  Need a different script to run with num_modes>1 
#==============================================================================
# INPUT:  see receptors_example.yaml
#==============================================================================
#
# OUTPUT:
#   STDERR: some carping if ligands are ignored or results overwritten
#   STDOUT: dumped yaml with info about best ligand, center, and receptor combo that was screened
#
#   if using pbs, this information will dump into the .e and .o files (.o todo: dock_accumulator.pl)
#
#   JSON: This script will write to a temporary file incremented complete json hash for each ligand.
#     this is different than the json file loaded, which is one hash keyed by ligand!  The temporary
#     file is writted so that if the run is terminated, the data won't be lost. To convert the temp
#     file to the out_json file, you have to convert something like {liga}{ligb}{ligc}{ligd} to 
#     {liga=>{}, ligb=>{}, ...} but be careful if merging with data rich json files (so you don't 
#     lose data)... i.e. backup.
#
use Modern::Perl;
use HackaMol;
use HackaMol::X::Vina;
use Math::Vector::Real;
use YAML::XS qw(Dump LoadFile);
use Time::HiRes qw(time);
use Path::Tiny;
use File::Slurp;
use JSON::XS;

my $tp1         = time;
my $tdock       = 0;
my $yaml_config = shift or die "pass yaml configuration file";
my $djob        = LoadFile($yaml_config);
#set some default configurations
#
$djob->{overwrite_json} = 0          unless( exists( $djob->{overwrite_json}) );
$djob->{out_json} = $djob->{in_json} unless( exists( $djob->{out_json}) );
$djob->{rerun} = 0                   unless( exists( $djob->{rerun}) );
$djob->{clean} = 1                   unless( exists( $djob->{clean}) );

unless ($djob->{overwrite_json}){
  if( $djob->{out_json} eq $djob->{in_json}){
    die "trying to overwrite in_json, but overwrite_json set to 0";
  }
  if(-e $djob->{out_json}){
    die "trying to overwrite out_json, but overwrite_json set to 0";
  }
}

my $json_fn = $djob->{in_json};    #
die "$json_fn does not exist." unless ( -e $json_fn );

#set up vina docking object
my $vina = HackaMol::X::Vina->new(
    ligand         => 'tmp.pdbqt',
    receptor       => 'tmp.pdbqt',
    in_fn          => $djob->{in},
    out_fn         => $djob->{out},
    size           => V( @{$djob->{size}} ),
    cpu            => $djob->{cpu},
    exhaustiveness => $djob->{exhaustiveness},
    scratch        => $djob->{scratch},
    exe            => '~/bin/vina',
);


#load up the json file and ready the loop over existing ligands 
my $text = read_file( $json_fn, { binmode => ':raw' } );
my $json = new JSON::XS;
$json->incr_parse($text);
my $stor = $json->incr_parse;

# hackamol instance for building and logging
my $hack = HackaMol->new( hush_read => 1, 
                             log_fn => Path::Tiny->tempfile(
                                         TEMPLATE => "TMP_". $djob->{name}."_XXXX",
                                         DIR      => $vina->scratch, 
                                         SUFFIX   => '.JSON',
                                         UNLINK   => 0,
                                        ),
                        );
my $ligand;
$stor->{BEST}{BE}=0 unless (exists($stor->{BEST}{BE}));
my $fh = $hack->log_fn->openw_raw; 
my $doing_again = 0;
my $from_last_time = {};

foreach my $rec (grep {!/BEST/} keys %{$stor}){ 
    my $receptor = $stor->{$rec}{rpath};
    $vina->receptor($receptor);
    $stor->{$rec}{BEST}{BE}= 999 unless ( exists( $stor->{$rec}{BEST}{BE} ) );
    my $mrec   = $hack->read_file_mol($receptor);
    my @SS = $hack->find_disulfide_bonds($mrec->all_atoms);
  
    my $best_today = 0;
    foreach my $ligand ( @{ $djob->{ligands} } ) {

        $vina->ligand($ligand);
        my $lbase = $vina->ligand->basename('.pdbqt');

        $stor->{$rec}{ligand}{$lbase}{lpath} = $vina->ligand->stringify;

        foreach my $center ( map{$_->COM} @SS ) {

            $vina->center($center);    # coercion needed here!!
            my $center_key = join( '_', @$center );
            if (
                exists( $stor->{$rec}{ligand}{$lbase}{center}{$center_key} ) )
            {
                print STDERR "already docked $rec $lbase $center_key\n";
                next if ($djob->{rerun} == 0);
                $doing_again = 1;
                print STDERR "overwriting $rec $lbase $center_key if BE improves\n";
                $from_last_time = $stor->{$rec}{ligand}{$lbase}{center}{$center_key};
                $from_last_time->{BE} = 999 unless (exists ($from_last_time->{BE}));
            }

            my $t1  = time;
            my $mol = $vina->dock_mol(1);
            my $t2  = time;
            $tdock += $t2 - $t1;
            my $results =
              pack_up( $mrec, $mol, $djob->{be_cutoff}, $djob->{dist_cutoff} );

            # replace new with old if new are not improvement
            if ($doing_again){
              if($results->{BE} > $from_last_time->{BE}){
                print STDERR "redocking did not improve\n";
                print STDERR "  last dock: ". $from_last_time->{BE}. " this dock: " . $results->{BE}."\n";
                $results = $from_last_time;
              }
              $doing_again = 0;
            }

            $stor->{$rec}{ligand}{$lbase}{center}{$center_key} = $results;
            #best for ligand
            $best_today = $results->{BE} if ($best_today > $results->{BE});
            if ( $stor->{$rec}{BEST}{BE} > $results->{BE} ) {
                $stor->{$rec}{BEST}{BE}       = $results->{BE};
                $stor->{$rec}{BEST}{COM}      = $results->{COM};
                $stor->{$rec}{BEST}{Zxyz}     = $results->{Zxyz}     if (exists($results->{Zxyz}));
                $stor->{$rec}{BEST}{NeighRes} = $results->{NeighRes} if (exists($results->{NeighRes}));
                $stor->{$rec}{BEST}{ligand}   = $lbase;
                $stor->{$rec}{BEST}{center}   = $center_key;
                $stor->{$rec}{BEST}{rpath}    = $stor->{$rec}{rpath};
                $stor->{$rec}{BEST}{lpath}    = $stor->{$rec}{ligand}{$lbase}{lpath};
            }
        }
    }
    #best overall
    if ( $stor->{BEST}{BE} > $stor->{$rec}{BEST}{BE} ) {
         $stor->{BEST}{BE}       = $stor->{$rec}{BEST}{BE};
         $stor->{BEST}{COM}      = $stor->{$rec}{BEST}{COM};
         $stor->{BEST}{Zxyz}     = $stor->{$rec}{BEST}{Zxyz}     if (exists($stor->{$rec}{BEST}{Zxyz})); 
         $stor->{BEST}{NeighRes} = $stor->{$rec}{BEST}{NeighRes} if (exists($stor->{$rec}{BEST}{NeighRes})); 
         $stor->{BEST}{receptor}   = $rec;
         $stor->{BEST}{TMass}    = $stor->{$rec}{TMass};
         $stor->{BEST}{formula}  = $stor->{$rec}{formula};
         $stor->{BEST}{ligand} = $stor->{$rec}{BEST}{ligand};
         $stor->{BEST}{center}   = $stor->{$rec}{BEST}{center};
         $stor->{BEST}{lpath}    = $stor->{$rec}{BEST}{lpath};
         $stor->{BEST}{rpath}    = $stor->{$rec}{BEST}{rpath};
    }
    print $fh encode_json { $rec => $stor->{$rec} };
    printf STDERR ("BEST this run for %15s = %5.1f\n", $rec, $best_today);
    #$hack->log_fn->append( encode_json $stor );
}

my $best = $stor->{BEST};
my $out_json = path($djob->{out_json});
$out_json->spew(encode_json $stor);

my $tp2 = time;
$best->{message}    = "results here are for the best observed overall for this set";
$best->{total_time} = sprintf("%.3f",$tp2 - $tp1);
$best->{dock_time}  = sprintf("%.3f",$tdock);
$best->{scratch}    = $vina->scratch->stringify;
$best->{out_json}   = $out_json->stringify;
$best->{job_configuration} = $djob;

print Dump $best;

if ($djob->{clean}){
  print STDERR "removing temporary files; set \$djob->{clean} to keep\n";
  $hack->log_fn->remove;
  $vina->scratch->child($vina->in_fn)->remove;
  $vina->scratch->child($vina->out_fn)->remove;
  path($yaml_config)->remove;
};

sub pack_up {

    # save all that good stuff.  save more based on cutoff
    my ( $rec, $mlig, $be_cut, $dist_cut ) = ( shift, shift, shift, shift );
    $be_cut   = 0.0 unless defined($be_cut);
    $dist_cut = 4.0 unless defined($dist_cut);

    # results always returned
    my $results = {
        BE  => $mlig->get_score(0),
        COM => [ @{ $mlig->COM } ],
    };

    if ( $results->{BE} <= $be_cut ) {
        my @Zxyz = map { [ $_->Z, @{ $_->xyz } ] } $mlig->all_atoms;
        $results->{Zxyz} = \@Zxyz;
        my %Res;

        # accumulate binding site info
        foreach my $lat ( $mlig->all_atoms ) {

            my @pat = grep { $lat->distance($_) <= $dist_cut }
              grep { $_->Z != 1 } $rec->all_atoms;

            $Res{ $_->resname . "_" . $_->resid }++ foreach @pat;
        }
        $results->{NeighRes} = \%Res;

    }
    return $results;

}

