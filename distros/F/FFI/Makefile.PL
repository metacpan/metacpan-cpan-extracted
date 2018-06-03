BEGIN {
  unless(eval q{ use 5.008001; 1}) {
    print "Perl 5.008001 or better required\n";
    exit;
  }
}

use 5.008001;
use ExtUtils::MakeMaker;
use Alien::Base::Wrapper qw( Alien::FFCall );

WriteMakefile(
  'NAME'               => 'FFI',
  'AUTHOR'             => [ 'Graham Ollis <plicease@cpan.org>', 'Paul Moore <gustav@morpheus.demon.co.uk>' ],
  'VERSION_FROM'       => 'lib/FFI.pm',
  'ABSTRACT_FROM'      => 'lib/FFI.pm',
  'LICENSE'            => 'gpl_2',
  'DEFINE'             => ($^O eq "MSWin32" ? '-DWIN32' : ''),
  'MIN_PERL_VERSION'   => '5.008001',
  'CONFIGURE_REQUIRES' => {
    'Alien::FFCall'         => 0.02,
    'Alien::Base::Wrapper' => '0',
    'ExtUtils::MakeMaker'   => '6.52',
  },
  'clean'              => {
    'FILES' => "vc*.pdb FFI.obj FFI.o FFI_def.old FFI-*",
  },
  'META_MERGE'       => {
    'meta-spec' => { version => 2 },
    'resources' => {
      'bugtracker' => {
        'web'  => 'https://github.com/Perl5-FFI/FFI/issues',
      },
      'homepage' => 'https://github.com/Perl5-FFI/FFI',
      'repository' => {
        'type' => 'git',
        'url'  => 'https://github.com/Perl5-FFI/FFI.git',
        'web'  => 'https://github.com/Perl5-FFI/FFI',
      },
      x_IRC => "irc://irc.perl.org/#native",
     },
  },
  Alien::Base::Wrapper->mm_args,
);
