use Modern::Perl;
use PBS::Client;
use Path::Tiny;
use YAML::XS qw(DumpFile LoadFile Load Dump);

my $yaml   = LoadFile(shift);
my $istart = shift || 0;

my $data    = path($yaml->{data});
my $scratch = path($yaml->{scratch});
$scratch->mkpath unless ($scratch->exists);

#adjust here if not all jsons need to be scanned
my @jsons = $data->children(qr/\.json/);

my $iend   = shift || $#jsons;
$iend = $#jsons if ($iend>$#jsons);

my $prefix = '';
$prefix = $yaml->{prefix} if (exists($yaml->{prefix}));

foreach my $json ( (sort @jsons)[$istart .. $iend] ){

  if ($prefix =~ /./){
    die "prefix matches what is already there" if ($json->basename =~ m/$prefix/);
  }
  $yaml->{name}     = $prefix . $json->basename(qr/\.json/); 
  $yaml->{out}      = $yaml->{name} . ".pdbqt";
  $yaml->{in}       = $yaml->{name} . ".txt";
  $yaml->{in_json}  = $json->stringify;
  $yaml->{out_json} = $scratch->child( $yaml->{name} . ".json" )->stringify;

  my $fyaml = $scratch->child($yaml->{name} . ".yaml");
  DumpFile($fyaml,$yaml);

  my $client = PBS::Client->new();
  my $job    = PBS::Client::Job->new (
              queue  => $yaml->{queue},
              name   => $yaml->{name},
              ppn    => $yaml->{cpu},
              nodes  => $yaml->{nodes},
              wallt  => $yaml->{wallt},
              cmd    => [$yaml->{cmd} . " $fyaml"] ,
  );
  do{say "skipping $fyaml"; next} if (name_in_queue($yaml->{name}));
  say $yaml->{cmd} . " $fyaml";
  #my $jobid = name_in_queue($yaml->{name});
  #$job->prev({ok => $job2});
  #say $yaml->{name} , " ", $jobid;
  #say $yaml->{name} if ($jobid);
  $client->qsub($job);
}

sub name_in_queue {
  my $name = shift;
  my ($jobline) = grep {m/\s+$name/} 
                  grep {! m/\d\sC\s/}  `qstat`; # avoid those pbs lagging jobs
  return 0 unless (defined($jobline));
  my ($jobid) = split(' ', $jobline);  
  $jobid =~ s/\.\w+//;
  return $jobid;
}

