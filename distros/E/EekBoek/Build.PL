# Build.PL -- Buildfile for EekBoek	-*-perl-*-
# Author          : Johan Vromans
# Created On      : Thu Sep  1 17:28:26 2005
# Last Modified By: Johan Vromans
# Last Modified On: Tue Jan 31 12:15:22 2017
# Update Count    : 140
# Status          : Experimental

# Ease the life of the CPAN testers.
exit 0 if $ENV{AUTOMATED_TESTING} && $] < 5.008005;

use 5.008005;
use strict;
use lib 'inc';
use Module::Build 0.32;
use File::Find;

our $data = {};
require "inc/build_common.pl";
require "lib/EB/Version.pm";

# Warn on non-standard install locations.
checkbin(<<EOD);
Please consult section "How Installation Paths are Determined"
of the Module::Build documentation section if you want to change
this location.
EOD

# checkexec("psql");

my $class = Module::Build->subclass(code => <<'EOF');
sub ACTION_test {
    my $self = shift;
    if ( $self->args("skipdbtests") ) {
	warn("WARNING: Skipping database tests\n");
	$ENV{EB_SKIPDBTESTS} = 1;
    }
    require Cwd;
    my $cwd = Cwd::getcwd();
    require lib;
    lib->import( "$cwd/lib/EB/CPAN", "$cwd/inc" );
    $self->SUPER::ACTION_test;
}
EOF

my $build = $class->new
  (
   module_name	       => $data->{distname},
   dist_name	       => $data->{distname},
   dist_author	       => $data->{author},
   dist_abstract       => $data->{abstract},
   license	       => $data->{license},
   requires	       => $data->{prereq_pm},
   build_requires      => $data->{buildreq_pm},
   recommends	       => $data->{recomm_pm},
   script_files	       => $data->{script_files},
   pm_files	       => filelist("lib"),
   PL_files	       => $data->{PL_files},
   get_options	       => { skipdbtests => { } },
   dist_version        => "2.02.05.5",
   add_to_cleanup      =>
     [ 'pod2htm*',
       map { +"t/ivp/*.$_" } qw(sql log txt html csv)
     ],
   meta_merge	       =>
     { resources =>
	{ homepage    => 'http://www.eekboek.nl',
	  MailingList => 'http://lists.sourceforge.net/lists/listinfo/eekboek',
	}
     },
   meta_add            => {
     no_index          => { directory => [ qw(inc lib/EB) ] },
     provides	       => {
       'EekBoek' =>
	  { file => "lib/EekBoek.pm",
	    version => $EB::Version::VERSION,
	  },
     },
   },
  );

$build->create_build_script;

# Update some files.
ProcessTemplates( $build->dist_name, $EB::Version::VERSION );

# Debian needs this.
1;
