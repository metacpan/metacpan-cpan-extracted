package LedgerSMB::Installer::OS::linux::fedora v0.999.5;

use v5.20;
use experimental qw(signatures);
use parent qw( LedgerSMB::Installer::OS::linux );

use Carp qw( croak );
use English;
use HTTP::Tiny;
use JSON::PP;

use Capture::Tiny qw(capture_stdout capture);
use Log::Any qw($log);

# dnf repoquery --installed --queryformat '%{name}\n' <packages>
# dnf group list --installed

sub new($class, %args) {
    return bless {
        _distro => $args{distro},
    }, $class;
}

sub name($self) {
    return $self->{_distro}->{ID};
}

sub dependency_packages_identifier($self) {
    my $arch;
    if (my $dnf5 = $self->have_cmd( 'dnf5' )) {
        my ($out, $err, ) = capture {
            system( $dnf5, '--dump-variables' );
        };
        (undef, $arch) = split(/ *= */, grep { m/basearch =/ } split( /\n/, $out ) );
    }
    else {
        ($arch, ) = capture_stdout {
            system( 'python3', '-c', 'import dnf; print(dnf.Base().conf.basearch)' );
        };
    }

    chomp($arch);
    return "$self->{_distro}->{ID}-$self->{_distro}->{VERSION_CODENAME}-$arch";
}

sub pkgs_from_modules($self, $mods) {
    my (%pkgs, @unmapped);
    my $dnf = $self->have_cmd( 'dnf' );
    while (my $mod = shift $mods->@*) {
        my ($pkg, $err, ) = capture {
            system( $dnf, 'repoquery', '--whatprovides', "perl($mod)", '--queryformat', '%{name}' );
        };
        chomp($pkg);
        if ($pkg) {
            $pkgs{$pkg} //= [];
            push $pkgs{$pkg}->@*, $mod;
            $log->trace( "Module '$mod' found in package $pkg" );
        }
        else {
            push @unmapped, $mod;
            $log->trace( "Module '$mod' not found" );
        }
    }
    return (\%pkgs, \@unmapped);
}

sub pkg_can_install($self) {
    return ($EFFECTIVE_USER_ID == 0);
}

sub pkg_install($self, $pkgs) {
    $pkgs //= [];
    my $dnf = $self->have_cmd( 'dnf' );
    my @cmd;
    @cmd = ($dnf, qw(install -q -y), $pkgs->@*);
    $log->debug( "system(): " . join(' ', map { "'$_'" } @cmd ) );
    system(@cmd) == 0
        or croak $log->fatal( "Unable to install required packages through dnf: $!" );
}

sub pkg_uninstall($self, $pkgs) {
    $pkgs //= [];
    my $dnf = $self->have_cmd( 'dnf' );
    my @cmd = ($dnf, qw(remove -q -y), $pkgs->@*);
    $log->debug( "system(): " . join(' ', map { "'$_'" } @cmd ) );
    system(@cmd) == 0
        or croak $log->fatal( "Unable to uninstall packages through dnf: $!" );
}

sub cleanup_env($self, $config, %args) {
    $self->pkg_uninstall( [ $config->pkgs_for_cleanup ] );
}

sub prepare_builder_env($self, $config) {
    my $dnf = $self->have_cmd( 'dnf' );
    my ($groups, ) = capture_stdout {
        system( $dnf, 'group', 'list', '--installed' );
    };
    my $have_c_development = ($groups =~ m/^c-development/m);
    unless ($have_c_development) {
        $config->mark_pkgs_for_cleanup( [ '@c-development' ] );
        $self->pkg_install( [ '@c-development' ] );
    }
}

sub prepare_installer_env($self, $config) {
    my $dnf = $self->have_cmd( 'dnf' );
    my ($make_pkgs, ) = capture_stdout {
        system( $dnf, 'repoquery', '--installed', '--queryformat', '%{name}', 'make' );
    };
    my $have_make = ($make_pkgs =~ m/^make/m);
    unless ($have_make) {
        $config->mark_pkgs_for_cleanup( [ 'make' ] );
        $self->pkg_install( [ 'make' ] );
    }
    $self->SUPER::prepare_installer_env( $config );
}

sub prepare_pkg_resolver_env($self, $config) {
    $self->have_cmd( 'dnf',     $config->effective_compute_deps );
}

sub _rm_installed($self, $pkgs) {
    my %pkgs = map {
        $_ => 1
    } $pkgs->@*;
    my $dnf = $self->have_cmd( 'dnf' );
    my ($installed, ) = capture_stdout {
        system( $dnf, qw(repoquery --installed --queryformat), q{%{name}\n}, $pkgs->@*);
    };
    delete $pkgs{$_} for (split( /\n/, $installed ));

    return [ keys %pkgs ];
}

sub pkg_deps_latex($self) {
    return ($self->_rm_installed([ qw(texlive-latex texlive-plain texlive-xetex) ]),
            []);
}

sub pkg_deps_xml($self) {
    return ($self->_rm_installed([ qw(libxml2) ]),
            $self->_rm_installed([ qw(libxml2-devel) ]));
}

sub pkg_deps_expat($self) {
    return ($self->_rm_installed([ qw(expat) ]),
            $self->_rm_installed([ qw(expat-devel) ]));
}

sub pkg_deps_dbd_pg($self) {
    return ($self->_rm_installed([ qw(libpq) ]),
            $self->_rm_installed([ qw(libpq-devel) ]));
}

1;
