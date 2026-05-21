use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::ShareDir::Install qw(install_share);
use File::Spec;

install_share dist => 'share';

WriteMakefile(
    NAME         => 'Developer::Dashboard',
    VERSION_FROM => 'lib/Developer/Dashboard.pm',
    ABSTRACT     => 'Project-neutral local developer dashboard runtime',
    AUTHOR       => 'Developer Dashboard Contributors',
    EXE_FILES    => [
        'bin/dashboard',
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
        'Getopt::Long'          => 0,
        'HTTP::Request'         => 0,
        'JSON::XS'              => 0,
        'LWP::Protocol::https'  => 0,
        'LWP::UserAgent'        => 0,
        'YAML::XS'              => 0,
        'TOML::Parser'          => 0,
        'Capture::Tiny'         => 0,
        'Digest::MD5'           => 0,
        'Digest::SHA'           => 0,
        'Archive::Zip'          => 0,
        'MIME::Base64'          => 0,
        'IO::Compress::Gzip'    => 0,
        'IO::Uncompress::Gunzip'=> 0,
        'Dancer2'               => 0,
        'Plack'                 => 0,
        'Starman'               => 0,
        'Template'              => 0,
        'URI'                   => 0,
        'URI::Escape'           => 0,
        'XML::Parser'           => 0,
        'Time::HiRes'           => 0,
        'POSIX'                 => 0,
    },
    LICENSE      => 'perl',
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

use File::ShareDir::Install qw(postamble);

# postamble()
# Appends the File::ShareDir::Install postamble so packaged installs refresh
# dist share assets, then adds the home-runtime helper bootstrap hook used by
# checkout and local installs.
# Input: ExtUtils::MakeMaker MY package object.
# Output: full make postamble text string.
sub postamble {
    my $self = shift;
    my $share_postamble = File::ShareDir::Install::postamble($self);
    return $share_postamble . <<'END_POSTAMBLE';
.PHONY: install pure_install install-private-cli-tools
install ::
	$(NOECHO) $(PERL) -e "1;"

pure_install :: install-private-cli-tools

install-private-cli-tools :
	$(NOECHO) $(PERL) -e 'use File::Copy; use File::Path qw(make_path); use File::Spec; my $$home = $$ENV{HOME} || (getpwuid($$>))[7]; my $$cli_dir = File::Spec->catdir($$home, ".developer-dashboard", "cli"); make_path($$cli_dir) unless -d $$cli_dir; for my $$cmd (qw(_dashboard-core jq yq tomq propq iniq csvq xmlq of open-file workspace file files path paths ps1 encode decode indicator collector config auth init cpan page action docker serve stop restart log shell doctor housekeeper skills which complete)) { my $$src = File::Spec->catfile("share", "private-cli", $$cmd); my $$dst = File::Spec->catfile($$cli_dir, $$cmd); if (-f $$src) { File::Copy::copy($$src, $$dst) or warn "Failed to copy $$src to $$dst: $$!"; chmod(0755, $$dst); print "Installed $$cmd to $$cli_dir\n"; } }'
END_POSTAMBLE
}
