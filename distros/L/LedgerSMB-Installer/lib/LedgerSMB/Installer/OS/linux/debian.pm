package LedgerSMB::Installer::OS::linux::debian v0.999.9;

use v5.20;
use experimental qw(signatures);
use parent qw( LedgerSMB::Installer::OS::linux );

use Carp qw( croak );
use English;
use HTTP::Tiny;
use JSON::PP;

use Capture::Tiny qw( capture_stdout );
use Log::Any qw($log);

sub new($class, %args) {
    return bless {
        _distro => $args{distro},
    }, $class;
}

sub name($self) {
    return $self->{_distro}->{ID};
}

sub dependency_packages_identifier($self) {
    my ($arch, ) = capture_stdout {
        system( qw( dpkg --print-architecture ) );
    };
    chomp($arch);
    return "$self->{_distro}->{ID}-$self->{_distro}->{VERSION_CODENAME}-$arch";
}

sub pkgs_from_modules($self, $mods) {
    if (not state $init = 0) {
        $log->info( "Updating 'apt-file' packages index" );
        system($self->{cmd}->{'apt-file'}, 'update') == 0
            or croak $log->fatal( "Unable to update apt-file's index: $!" );
        $init = 1;
    }

    my $args = join(' ', $mods->@*);
    open(my $fh, '-|',
         "$self->{cmd}->{'dh-make-perl'} --no-verbose locate $args 2>/dev/null")
        or return ({}, []);

    my (%pkgs, @unmapped);
    my %found;
    while (my $pkg_line = <$fh>) {
        if ($pkg_line =~ m/^(\S+) is not found in any/) {
            $found{$1} = 1;
            push @unmapped, $1;
            $log->trace( "Module '$1' not found" );
        }
        elsif ($pkg_line =~ m/^(\S+) is in (\S+)(?: \| \S+)* package/) {
            $found{$1} = 1;
            $pkgs{$2} //= [];
            push $pkgs{$2}->@*, $1;
            $log->trace( "Module '$1' found in package $2" );
        }
        elsif ($pkg_line =~ m/^(\S+) is in Perl core/) {
            $found{$1} = 1;
            $log->trace( "Module '$1' resolves to 'perl' package; skipping as explicit dependency" );
        }
        else {
            $log->trace( "Unprocessed $self->{cmd}->{'dh_make_perl'} output line: " . $pkg_line );
        }
    }
    my @skipped = grep { !$found{$_} } $mods->@*;
    if (@skipped) {
        $log->error( "Error: Modules skipped while mapping to packages: " . join(', ', @skipped ) );
        push @unmapped, @skipped;
    }
    return (\%pkgs, \@unmapped);
}

sub pkg_can_install($self) {
    return ($EFFECTIVE_USER_ID == 0);
}

sub pkg_install($self, $pkgs) {
    $pkgs //= [];
    my $apt_get = $self->have_cmd( 'apt-get' );
    my @cmd;
    @cmd = ($apt_get, qw( update -q -y ));
    do {
        local $ENV{DEBIAN_FRONTEND} = 'noninteractive';
        $log->debug( "system(): " . join(' ', map { "'$_'" } @cmd ) );
        system(@cmd) == 0
            or croak $log->fatal( "Unable to update 'apt-get' package index: $!" );
    };

    @cmd = ($apt_get, qw( install -q -y ), $pkgs->@*);
    do {
        local $ENV{DEBIAN_FRONTEND} = 'noninteractive';
        $log->debug( "system(): " . join(' ', map { "'$_'" } @cmd ) );
        system(@cmd) == 0
            or croak $log->fatal( "Unable to install required packages through apt-get: $!" );
    };
}

sub pkg_uninstall($self, $pkgs) {
    $pkgs //= [];
    my $apt_get = $self->have_cmd( 'apt-get' );
    my @cmd = ($apt_get, qw(autoremove --purge -q -y), $pkgs->@*);

    do {
        local $ENV{DEBIAN_FRONTEND} = 'noninteractive';
        $log->debug( "system(): " . join(' ', map { "'$_'" } @cmd ) );
        system(@cmd) == 0
            or croak $log->fatal( "Unable to uninstall packages through apt-get: $!" );
    };
}

sub cleanup_env($self, $config, %args) {
    $self->pkg_uninstall( [ $config->pkgs_for_cleanup ] );
}

sub prepare_builder_env($self, $config) {
    my ($have_build_essential, ) = capture_stdout {
        system( qw( dpkg-query -W build-essential ) );
    };
    unless (grep { m/build-essential/ } split( /\n/, $have_build_essential )) {
        $config->mark_pkgs_for_cleanup( [ 'build-essential' ] );
        $self->pkg_install( [ 'build-essential' ] );
    }
}

sub prepare_extraction_env($self, $config) {
    my ($have_deps, ) = capture_stdout {
        system( qw( dpkg-query -W tar gzip gpg ) );
    };
    my @pkgs;
    unless (grep { m/tar/ } split(/\n/, $have_deps)) {
        push @pkgs, 'tar';
    }
    unless (grep { m/gzip/ } split(/\n/, $have_deps)) {
        push @pkgs, 'gzip';
    }
    if ($config->verify_sig) {
        unless (grep { m/gpg/ } split(/\n/, $have_deps)) {
            push @pkgs, 'gpg';
        }
    }
    if (@pkgs) {
        $config->mark_pkgs_for_cleanup( \@pkgs );
        $self->pkg_install( \@pkgs );
    }
    $self->SUPER::prepare_extraction_env( $config );
}

sub prepare_installer_env($self, $config) {
    my ($have_make, ) = capture_stdout {
        system( qw( dpkg-query -W make ) );
    };
    unless (grep { m/make/ } split(/\n/, $have_make)) {
        $config->mark_pkgs_for_cleanup( [ 'make' ] );
        $self->pkg_install( [ 'make' ] );
    }
    $self->SUPER::prepare_installer_env( $config );
}

sub prepare_pkg_resolver_env($self, $config) {
    my @new_pkgs;
    my ($have_dh_make_perl, ) = capture_stdout {
        system( qw( dpkg-query -W dh-make-perl ) );
    };
    unless (grep { m/dh-make-perl/ } split( /\n/, $have_dh_make_perl)) {
        push @new_pkgs, 'dh-make-perl';
    }
    my ($have_apt_file, ) = capture_stdout {
        system( qw( dpkg-query -W apt-file ) );
    };
    unless (grep { m/apt-file/ } split( /\n/, $have_apt_file)) {
        push @new_pkgs, 'apt-file';
    }
    if ($config->effective_prepare_env) {
        $config->mark_pkgs_for_cleanup( \@new_pkgs );
        $self->pkg_install( \@new_pkgs );
    }
    $self->have_cmd( 'apt-file',     $config->effective_compute_deps );
    $self->have_cmd( 'dh-make-perl', $config->effective_compute_deps );
}

sub _rm_installed($pkgs) {
    my %pkgs = map {
        $_ => 1
    } $pkgs->@*;
    my @cmd = (qw(dpkg-query -W), $pkgs->@*);
    my ($installed, ) = capture_stdout {
        system( @cmd );
    };
    delete $pkgs{$_} for (
        map {
            my ($pkg) = split( /\t/, $_ );
            $pkg =~ s/:.*$//r;
        } split( /\n/, $installed )
        );

    return [ keys %pkgs ];
}

sub pkg_deps_latex($self) {
    return (_rm_installed([ qw(texlive-latex-recommended texlive-fonts-recommended
                 texlive-plain-generic texlive-xetex) ]),
            []);
}

sub pkg_deps_xml($self) {
    return (_rm_installed([ qw(libxml2) ]),
            _rm_installed([ qw(libxml2-dev) ]));
}

sub pkg_deps_expat($self) {
    return (_rm_installed([ qw(libexpat1) ]),
            _rm_installed([ qw(libexpat1-dev) ]));
}

sub pkg_deps_dbd_pg($self) {
    return (_rm_installed([ qw(libpq5) ]),
            _rm_installed([ qw(libpq-dev) ]));
}

1;
