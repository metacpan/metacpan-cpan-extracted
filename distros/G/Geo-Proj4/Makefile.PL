use ExtUtils::MakeMaker;
                                                                                
require 5.10.0;

my $VERSION = '1.11';

open CS, "cs2cs 2>&1 |"
   or die "ERROR: proj library not found, where is cs2cs?\n";

my $got = qx(cs2cs 2>&1);
$got =~ m/\ ([\d.]+)\,/
    or die "ERROR: proj library version not known\n";

my $version = $1;
warn "LIB=$version";
$version ge $libversion
    or die "ERROR: libproj too old, found $version required is $libversion\n";

WriteMakefile
 ( NAME     => 'Geo::Proj4'
 , VERSION  => $VERSION
 , AUTHOR   => 'Mark Overmeer'
 , ABSTRACT => 'PROJ library for carthographic and geodesic projections'
 , INC      => "-I."
 , LIBS     => [ "-lproj" ]
 , LICENSE  => 'perl_5'

 , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
         { repository =>
             { type => 'git'
             , url  => 'https://github.com/markov2/perl5-Geo-Proj4.git'
             , web  => 'https://github.com/markov2/perl5-Geo-Proj4'
             }
         , homepage => 'http://perl.overmeer.net/CPAN/'
         , license  => [ 'http://dev.perl.org/licenses/' ]
         }
      }
 );

### used by oodist during production of this distribution
sub MY::postamble { <<'__POSTAMBLE' }

RAWDIR          = ../public_html/geo-proj4/raw
DISTDIR         = ../public_html/geo-proj4/source
__POSTAMBLE
