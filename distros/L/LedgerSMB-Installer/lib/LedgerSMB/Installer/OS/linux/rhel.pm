package LedgerSMB::Installer::OS::linux::rhel v0.999.13;

use v5.20;
use experimental qw(signatures);
use parent qw( LedgerSMB::Installer::OS::linux::fedora );

use Capture::Tiny qw(capture_stdout capture);

sub prepare_builder_env($self, $config) {
    my $dnf = $self->have_cmd( 'dnf' );
    my ($groups, ) = capture_stdout {
        system( $dnf, 'group', 'list', '--installed' );
    };
    my $have_development = ($groups =~ m/^development/m);
    unless ($have_development) {
        $config->mark_pkgs_for_cleanup( [ '@development' ] );
        $self->pkg_install( [ '@development' ] );
    }
}

sub pkg_deps_latex($self) {
    return ($self->_rm_installed([ qw(texlive-collection-latexrecommended
                                      texlive-collection-latex
                                      texlive-collection-xetex) ]),
            []);
}

1;
