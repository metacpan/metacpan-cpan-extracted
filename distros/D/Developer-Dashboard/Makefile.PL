use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::ShareDir::Install qw(install_share);
use Config;
use File::Spec;
use Cwd qw(cwd);

install_share dist => 'share';

# Detect the project-local Perl library root so generated Perl invocations
# (e.g.  make test) can reach locally-installed CPAN modules without the
# calling shell having set PERL5LIB.
my $local_lib_root;
for my $candidate ( '.perl5', "$ENV{HOME}/perl5" ) {
    my $lib = File::Spec->catdir( $candidate, 'lib', 'perl5' );
    my @module_dirs = (
        $lib,
        File::Spec->catdir( $lib, $Config{archname} ),
        File::Spec->catdir( $lib, $Config{version} ),
    );
    if ( grep { -d $_ && grep { -f $_ } glob( File::Spec->catfile( $_, '*.pm' ) ) } @module_dirs ) {
        $local_lib_root = $candidate;
        last;
    }
}
$local_lib_root ||= '.perl5';

WriteMakefile(
    NAME         => 'Developer::Dashboard',
    MIN_PERL_VERSION => '5.038',
    VERSION_FROM => 'lib/Developer/Dashboard.pm',
    ABSTRACT     => 'Project-neutral local developer dashboard runtime',
    AUTHOR       => 'Developer Dashboard Contributors',
    EXE_FILES    => [
        'bin/dashboard',
        'bin/d2',
    ],
    PREREQ_PM    => {
        'strict'                => 0,
        'warnings'              => 0,
        'Cwd'                   => 0,
        'File::Basename'        => 0,
        'File::Path'            => 0,
        'File::Spec'            => 0,
        'File::Temp'            => 0,
        'File::Find'            => 0,
        'Cpanel::JSON::XS'      => '4.41',
        'Getopt::Long'          => 0,
        'HTML::Parser'          => '3.84',
        'HTTP::Date'            => '6.08',
        'HTTP::Request'         => 0,
        'HTTP::Tiny'            => '0.095',
        'JSON::XS'              => '4.04',
        'LWP::Protocol::https'  => '6.07',
        'LWP::UserAgent'        => '6.83',
        'YAML'                  => '1.28',
        'YAML::XS'              => '0.903.0',
        'TOML::Parser'          => 0,
        'Capture::Tiny'         => '0.24',
        'Digest::MD5'           => '2.25',
        'Crypt::URandom'        => '0.55',
        'Digest::SHA'           => '5.96',
        'Archive::Tar'          => '3.10',
        'Archive::Zip'          => '1.61',
        'MIME::Base64'          => 0,
        'Compress::Raw::Zlib'   => '2.220',
        'IO::Compress::Gzip'    => '2.220',
        'IO::Uncompress::Gunzip'=> '2.220',
        'Dancer2'               => '0.206000',
        'Plack'                 => '1.0054',
        'Socket'                => '2.041',
        'Starman'               => '0.4018',
        'Storable'              => '3.41',
        'Template'              => '3.103',
        'URI'                   => 0,
        'URI::Escape'           => 0,
        'XML::Parser'           => '2.48',
        'Time::HiRes'           => 0,
        'POSIX'                 => 0,
    },
    LICENSE      => 'mit',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'    => 0,
        'File::ShareDir::Install' => 0,
    },
    META_MERGE   => {
        resources => {
            homepage   => 'https://github.mf/manif3station/developer-dashboard',
            bugtracker => {
                web => 'https://github.mf/manif3station/developer-dashboard/issues',
            },
            repository => {
                type => 'git',
                url  => 'git@github.mf:manif3station/developer-dashboard.git',
                web  => 'https://github.mf/manif3station/developer-dashboard',
            },
        },
    },
);

package MY;

# _local_lib_perl5_path()
# Convenience helper: returns the PERL5LIB path fragment for the detected
# local Perl library root, or an empty string if none was configured.
# Includes both the base perl5 directory and any arch-specific subdirs
# that local::lib creates for the active Perl.
# Called from postamble() to inject the path into the generated Makefile.
# Input: none.
# Output: platform-separated absolute paths suitable for PERL5LIB, or ''.
sub _local_lib_perl5_path {
    return '' if !$local_lib_root || $local_lib_root eq '';
    my $base = File::Spec->catdir( $local_lib_root, 'lib', 'perl5' );
    $base = File::Spec->rel2abs( $base, Cwd::cwd() );
    my @paths = ($base);
    for my $platform_dir ( @Config::Config{qw(archname version)} ) {
        my $d = File::Spec->catdir( $base, $platform_dir );
        push @paths, $d if -d $d;
    }
    return join $Config::Config{path_sep}, @paths;
}

# postamble()
# Appends the File::ShareDir::Install postamble so packaged installs refresh
# dist share assets, then adds the home-runtime helper bootstrap hook used by
# checkout and local installs.  Also prepends a PERL5LIB export so the local
# Perl library (e.g. .perl5) is reachable during "make test" without the
# calling shell having set PERL5LIB manually.
# Input: ExtUtils::MakeMaker MY package object.
# Output: full make postamble text string.
sub postamble {
    my $self = shift;
    my $share_postamble = File::ShareDir::Install::postamble($self);

    my $local_perl5 = _local_lib_perl5_path();
    my $perl5lib_preamble = $local_perl5 ne ''
        ? "PERL5LIB := $local_perl5$Config::Config{path_sep}\$(PERL5LIB)\nexport PERL5LIB\n\n"
        : '';

    return $perl5lib_preamble . $share_postamble . <<'END_POSTAMBLE';
.PHONY: install pure_install install-private-cli-tools
install ::
	$(NOECHO) $(PERL) -e "1;"

pure_install :: install-private-cli-tools

install-private-cli-tools :
	$(NOECHO) $(PERL) -e 'use File::Copy; use File::Path qw(make_path); use File::Spec; my $$home = $$ENV{HOME} || $$ENV{USERPROFILE} || eval { (getpwuid($$>))[7] } || die "Unable to resolve a home directory for the private CLI helper staging\n"; my $$cli_dir = File::Spec->catdir($$home, ".developer-dashboard", "cli"); make_path($$cli_dir) unless -d $$cli_dir; for my $$cmd (qw(_dashboard-core jq yq tomq propq iniq csvq xmlq of open-file workspace file files path paths ps1 encode decode indicator collector config auth api ask init cpan page action docker serve stop restart log shell doctor housekeeper skills which upgrade complete)) { my $$src = File::Spec->catfile("share", "private-cli", $$cmd); my $$dst = File::Spec->catfile($$cli_dir, $$cmd); if (-f $$src) { File::Copy::copy($$src, $$dst) or warn "Failed to copy $$src to $$dst: $$!"; chmod(0755, $$dst); print "Installed $$cmd to $$cli_dir\n"; } }'
END_POSTAMBLE
}
