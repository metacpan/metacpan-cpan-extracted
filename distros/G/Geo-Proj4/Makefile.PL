use ExtUtils::MakeMaker;
                                                                                
require 5.006;

# increased per release
my $relversion = '1.09';

my $libversion = '4.4.9';

# Should also work when you do not have FWTools installed...
my $FWTools    = $ENV{GEOPROJ_FWTOOLS_DIR}
              || $ENV{FWTOOLS_DIR}           # windows
              || '.';

# This is part is very UNIX/Linux centric.  Please help me with the
# required windows tests.
my $FWbin      = "$FWTools/bin_safe";
my $cs2cs      = -x "$FWbin/cs2cs" ? "$FWbin/cs2cs" : 'cs2cs';

open CS, "$cs2cs 2>&1 |"
   or die "ERROR: proj library not found, where is cs2cs?\n";

my $got = <CS>;

$got =~ m/\ ([\d.]+)\,/
    or die "ERROR: proj library version not known\n";

my $version = $1;
$version ge $libversion
    or die "ERROR: libproj too old, found $version required is $libversion\n";

if($^O ne 'MSWin32' && $^O ne 'cygwin')
{   unlink 'projects.h';
    my $own_projects = "src/$version/projects.h";
    if(-f $own_projects)
    {   symlink $own_projects, 'projects.h'
            or die "ERROR: cannot install $own_projects: $!\n";
        warn "installed $own_projects\n";
    }
}

WriteMakefile
 ( NAME     => 'Geo::Proj4'
 , VERSION  => $relversion
 , AUTHOR   => 'Mark Overmeer'
 , ABSTRACT => 'Proj4 library for carthographic projections'
 , INC      => "-I$FWTools/include -I."
 , LIBS     => [ "-L$FWTools/lib -lproj" ]
 , LICENSE  => 'perl'

 , META_MERGE =>
      { 'meta-spec' => { version => 2 }
      , resources  =>
         { repository =>
             { type => 'git'
             , url  => 'https://github.com/markov2/perl5-Geo-Proj4.git'
             , web  => 'https://github.com/markov2/perl5-Geo-Proj4'
             }
         }
      , homepage => 'http://perl.overmeer.net/CPAN/'
      , license  => [ 'http://dev.perl.org/licenses/' ]
      }
 );

### used by oodist during production of this distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST, see PODTAIL.txt as well
RAWDIR          = ../public_html/geo-proj4/raw
DISTDIR         = ../public_html/geo-proj4/source
__POSTAMBLE
