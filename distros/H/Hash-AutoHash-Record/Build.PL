use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass
  (
   class => 'My::Builder',
   code => q{
       sub harness_switches { # turn off -w in Test::Harness
         shift->{properties}{debugger} ? qw(-d) : qw(-X);
       }
     },
  );

my $builder = $class->new
  (module_name         => 'Hash::AutoHash::Record',
   license             => 'perl',
   dist_author         => q{Nat Goodman <natg@shore.net>},
   configure_requires=>{'Module::Build' => 0.4007,
		       },
   build_requires =>   {'Carp' => 1.20,
			'Exporter' => 5.68,
			'File::Spec' => 3.40,
			'Hash::AutoHash' => 1.17,
			'Hash::AutoHash::AVPairsMulti' => 1.17,
			'Hash::AutoHash::AVPairsSingle' => 1.17,
			'List::MoreUtils' => 0.33,
			'Test::Deep' => 0.11,
			'Test::More' => 0.98,
			'Test::Pod' => 1.48,
			'Test::Pod::Content' => '0.0.6',
		       },
   requires =>         {'Carp' => 1.20,
			'Cwd' => 3.40,
			'Exporter' => 5.68,
			'Fcntl' => 1.11,
			'Hash::AutoHash' => 1.17,
			'Hash::AutoHash::AVPairsMulti' => 1.17,
			'Hash::AutoHash::AVPairsSingle' => 1.17,
			'Hash::AutoHash::MultiValued' => 1.17,
			'List::MoreUtils' => 0.33,
			'List::Util' => 1.32,
			'Storable' => 2.30,
			'Tie::ToObject' => 0.03,
			'XSLoader' => 0.16,
		       },
   add_to_cleanup      => [ 'Hash-AutoHash-Record-*' ],
   create_makefile_pl => 'small',
  );

$builder->create_build_script();
