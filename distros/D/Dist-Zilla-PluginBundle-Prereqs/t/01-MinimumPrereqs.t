use sanity;
use Test::Most tests => 12;
 
use Test::DZil;
use YAML::Tiny;
 
sub build_meta {
   my $tzil = shift;
   $tzil->chrome->logger->set_debug(1);
   lives_ok(sub { $tzil->build }, 'built distro') || explain $tzil->log_messages;
   YAML::Tiny->new->read($tzil->tempdir->file('build/META.yml'))->[0];
}
 
my $tzil = Builder->from_config(
   { dist_root => 'corpus/dist' },
   { },
);
 
# check found prereqs
my $meta = build_meta($tzil);
 
my %wanted = (
   'Acme::Prereq::A'                    => 0,
   'Acme::Prereq::AnotherNS'            => 0,
   'Acme::Prereq::AnotherNS::B'         => 0,
   'Acme::Prereq::AnotherNS::C'         => 0,
   'Acme::Prereq::AnotherNS::Deeper::B' => 0,
   'Acme::Prereq::AnotherNS::Deeper::C' => 0,
   'Acme::Prereq::B'                    => 0,
   'Acme::Prereq::BigDistro::A'         => '!= 0.00',
   'Acme::Prereq::BigDistro::B'         => 0,
   'Acme::Prereq::BigDistro::Deeper::A' => '0.01',
   'Acme::Prereq::BigDistro::Deeper::B' => 0,
   'Acme::Prereq::None'                 => 0,

   'DZPA::NotInDist'  => 0,

   'Module::Metadata' => 0,
   'Module::Load'     => '0.12',
   'Shell'            => 0,

   'mro'              => '1.01',
   'strict'           => 0,
   'warnings'         => 0,
  
   'perl'             => '5.008',
);
 
is_deeply(
   $meta->{prereqs}{runtime}{requires},
   \%wanted,
   'no MinimumPrereqs works',
);
 
# Okay, add in the MinimumPrereqs stuff
for my $yr (0, 2008..2011) {
   $tzil = Builder->from_config(
      { dist_root => 'corpus/dist' },
      {
         add_files => {
            'source/dist.ini' => simple_ini(
               qw(GatherDir ExecDir),
               [ AutoPrereqs    => { skip => '^DZPA::Skip' } ],
               [ 'Prereqs / RuntimeRequires'
                                => { 'Acme::Prereq::BigDistro::A' => '!= 0.00' } ],
               [ MinimumPrereqs => { minimum_year => $yr } ],
               [ MetaYAML       => { version => 2 } ],
            ),
         },
      },
   );
    
   # check found prereqs
   $meta = build_meta($tzil);
   
   # We get newer and newer versions as we go...
   for ($yr) {
      when (0) {
         $wanted{'Acme::Prereq::'.$_} = '0.01' for (
            qw{A B None}, 
            ( map { 'AnotherNS::'.$_ } (qw{B C Deeper::B Deeper::C}) ),
            ( map { 'BigDistro::'.$_ } (qw{B   Deeper::A Deeper::B}) ),
         );
         $wanted{'Acme::Prereq::AnotherNS'} = '0.02';
         $wanted{'Module::Metadata'} = '1.000000';
      }
      when (2008) {
         $wanted{'Shell'}    = '0.72';
         $wanted{'warnings'} = '1.05_01';
         $wanted{'strict'}   = '1.03';
      }
      when (2009) {
         $wanted{'warnings'} = '1.06';
         $wanted{'strict'}   = '1.04';
      }
      when (2010) {
         $wanted{'warnings'} = '1.09';
      }
      when (2011) {
         $wanted{'Module::Metadata'} = '1.000003';
      }
   }
   
   is_deeply(
      $meta->{prereqs}{runtime}{requires},
      \%wanted,
      "MinimumPrereqs @ minimum year $yr",
   ) || explain { log => $tzil->log_messages, prereqs => $meta->{prereqs}{runtime}{requires} };
}
