use strict;
use warnings;

package Module::Install::PRIVATE::Phat;

use base qw/Module::Install::Base/;

our $VERSION = '0.01';

use Cwd;
use File::Spec;
use Gtk2::CodeGen;
use Glib::MakeHelper;
use ExtUtils::Depends;
use ExtUtils::PkgConfig;

sub phat {
    my ($self) = @_;

    mkdir 'build', 0777;

    my %pkgconfig;
    eval {
       %pkgconfig = ExtUtils::PkgConfig->find('phat', 'libgnomecanvas-2.0');
    };

    if (my $error = $@) {
        print STDERR $error;
        return;
    }

    Gtk2::CodeGen->parse_maps('phat');
    Gtk2::CodeGen->write_boot(ignore => qr/^Gtk2::Phat$/);

    our @xs_files = <xs/*.xs>;

    our $phat = ExtUtils::Depends->new('Gtk2::Phat', 'Gtk2');
    $phat->set_inc($pkgconfig{cflags});
    $phat->set_libs($pkgconfig{libs});
    $phat->add_xs(@xs_files);
    $phat->add_pm('lib/Gtk2/Phat.pm', '$(INST_LIBDIR)/Phat.pm');
    my $cwd = cwd();
    $phat->add_typemaps(map { File::Spec->catfile($cwd, $_) } File::Spec->catfile('build', 'phat.typemap'));

    $phat->install(File::Spec->catfile('build', 'phat-autogen.h'));
    $phat->save_config(File::Spec->catfile('build', 'IFiles.pm'));

    $self->makemaker_args(
        $phat->get_makefile_vars,
        MAN3PODS => {
            Glib::MakeHelper->do_pod_files(@xs_files),
        },
    );

    return 1;
}


package MY;
use Cwd;

sub postamble {
	return Glib::MakeHelper->postamble_clean()
		. Glib::MakeHelper->postamble_docs_full(
				DEPENDS	=> $Module::Install::PRIVATE::Phat::phat,
				XS_FILES => \@Module::Install::PRIVATE::Phat::xs_files,
				COPYRIGHT => 'Copyright (C) 2005-2008 by Florian Ragwitz'
		)
        . <<"EOM"
README: lib/Gtk2/Phat.pm
\tpod2text \$< > \$@
EOM
}

1;
