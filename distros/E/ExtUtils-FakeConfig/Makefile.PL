#!/usr/bin/perl

use strict;
use lib 'lib';

# poor man's File::Spec
eval {
  require File::Spec;
};
if( $@ ) {
  eval <<'EOT';
package File::Spec;

sub catfile { shift; join '/', @_ }

sub path { split /$Config::Config{path_sep}/, $ENV{PATH} }

$INC{'File/Spec.pm'} = 'loaded';
EOT
}

use Config;
use ExtUtils::FakeConfig;

my $make;

BEGIN {
  if( $^O eq 'MSWin32' ) {
    $make = $ENV{MAKE};
    $make ||= ( ExtUtils::FakeConfig::find_program( 'nmake', 'dmake' ) )[1];

    $make || die "Unable to find 'make' program";

    import ExtUtils::FakeConfig make => $make;
  }
}

use ExtUtils::MakeMaker;

eval {
    require ExtUtils::MY_Metafile;
    ExtUtils::MY_Metafile->import;

    my_metafile
      ( { license        => 'perl',
          dynamic_config => 1,
          } );
};

my $liar = File::Spec->catfile( 'lib', 'ExtUtils', 'FakeConfig.pm' );

WriteMakefile( NAME => 'ExtUtils::FakeConfig',
               # Perl < 5.005 does not support some attributes
               ( $] >= 5.005 ?
                 ( ABSTRACT_FROM => $liar,
                   AUTHOR => 'Mattia Barbon <mbarbon@cpan.org>',
                 ) : () ),
               VERSION_FROM => $liar,
               PREREQ_PM => { 'File::Spec'        => 0,
                              'Test::More'        => 0.48,
                              },
             );

print "Using: '$make'\n" if $^O eq 'MSWin32';

my( @params, $templater, $specfile );
BEGIN {
  $specfile = 'spec/ap_mingw.txt';
  $specfile = 'spec/ap_mingw_58.txt'  if $] >= 5.008;
  $specfile = 'spec/ap_mingw_510.txt' if $] >= 5.010;
  $templater = '$(PERL) script/fill_template.pl';
  @params = ( { Module   => 'Config_m.pm',
                Template => 'spec/Config_ap.txt',
                Spec     => $specfile,
                Params   => "cc=gcc pack_name=Config_m" },
            );
}

package MY;

use strict;
use Config;

sub depend {
  my $this = shift;
  my $inst = $this->{INST_LIB};

  my $extra_deps = join ' ', map { "$inst/" . $_->{Module} } @params;

  $this->SUPER::depend
    ( @_,
      ( $^O eq 'MSWin32' ?
        ( 'pm_to_blib'  => $extra_deps ) :
        () ),
    );
}

use vars qw(%i);

sub postamble {
  local( *i );
  my $ret;
  my $lib = $_[0]->{INST_LIB};

  if( $^O eq 'MSWin32' ) {
    foreach my $j ( @params ) {
      *i = $j;
      $ret .= <<EOT;
$lib/$i{Module} : $i{Template} $i{Spec}
	$templater $i{Template} $i{Spec} \$@ $i{Params}

EOT
    }

    my $core = "$Config{archlibexp}\\CORE";
    my $perl5_dll = ( glob( "$Config{binexp}\\perl*.dll" ) )[0];
    my $gcc = ( ExtUtils::FakeConfig::find_program( 'gcc' ) )[1];
    my $msvc = ( ExtUtils::FakeConfig::find_program( 'cl' ) )[1];

    if( $gcc ) {
      $ret .= <<EOT;
pure_install :: implib_mingw

implib_mingw :
	\$(PERL) script\\make_implib.pl --output-dir="$core" --target=mingw "$perl5_dll"

EOT
    }

    if( $msvc ) {
      $ret .= <<EOT;
implib_msvc :
	\$(PERL) script\\make_implib.pl --output-dir="$core" --target=vc "$perl5_dll"

EOT
    }
  }

  return $ret;
}

