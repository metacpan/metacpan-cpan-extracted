use sanity;
use Test::Most tests => 4;
 
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
   'no @Prereqs works',
);
 
# Okay, add in the @Prereqs
$tzil = Builder->from_config(
   { dist_root => 'corpus/dist' },
   {
      add_files => {
         'source/dist.ini' => simple_ini(
            qw(GatherDir ExecDir),
            [ '@Prereqs'     => { skip => '^DZPA::Skip' } ],
            [ 'Prereqs / RuntimeRequires'
                             => { 'Acme::Prereq::BigDistro::A' => '!= 0.00' } ],
            [ MetaYAML       => { version => 2 } ],
         ),
      },
   },
);
 
# check found prereqs
$meta = build_meta($tzil);

# Refactor the %wanted hash
%wanted = (
  'Acme::Prereq::A'            => '0.01',
  'Acme::Prereq::AnotherNS'    => '0.02',
  'Acme::Prereq::B'            => '0.01',
  'Acme::Prereq::BigDistro'    => '0.01',
  'Acme::Prereq::BigDistro::A' => '!= 0.00',
  'Acme::Prereq::None'         => '0.01',
  'DZPA::NotInDist'            => '0',
  'Module::Metadata'           => '1.000000',
  'Shell'                      => '0.72',
  'perl'                       => '5.010001'
);

is_deeply(
   $meta->{prereqs}{runtime}{requires},
   \%wanted,
   '@Prereqs',
) || explain { log => $tzil->log_messages, prereqs => $meta->{prereqs}{runtime}{requires} };
