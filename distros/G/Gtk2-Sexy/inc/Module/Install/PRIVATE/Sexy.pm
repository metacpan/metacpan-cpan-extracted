#line 1
use strict;
use warnings;

package Module::Install::PRIVATE::Sexy;

use base qw/Module::Install::Base/;

our $VERSION = '0.01';

use Cwd;
use File::Spec;
use Gtk2::CodeGen;
use Glib::MakeHelper;
use ExtUtils::Depends;
use ExtUtils::PkgConfig;

sub sexy {
    my ($self) = @_;

    mkdir 'build', 0777;

    my %pkgconfig;
    eval {
       %pkgconfig = ExtUtils::PkgConfig->find('libsexy');
    };

    if (my $error = $@) {
        print STDERR $@;
        return;
    }

    Gtk2::CodeGen->parse_maps('sexy');
    Gtk2::CodeGen->write_boot(ignore => qr/^Gtk2::Sexy$/);

    our @xs_files = <xs/*.xs>;

    our $sexy = ExtUtils::Depends->new('Gtk2::Sexy', 'Gtk2');
    $sexy->set_inc($pkgconfig{cflags});
    $sexy->set_libs($pkgconfig{libs});
    $sexy->add_xs(@xs_files);
    $sexy->add_pm('lib/Gtk2/Sexy.pm', '$(INST_LIBDIR)/Sexy.pm');
    my $cwd = cwd();
    $sexy->add_typemaps(map { File::Spec->catfile($cwd, $_) } File::Spec->catfile('build', 'sexy.typemap'));

    $sexy->install(File::Spec->catfile('build', 'sexy-autogen.h'));
    $sexy->save_config(File::Spec->catfile('build', 'IFiles.pm'));

    $self->makemaker_args(
        $sexy->get_makefile_vars,
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
				DEPENDS	=> $Module::Install::PRIVATE::Sexy::sexy,
				XS_FILES => \@Module::Install::PRIVATE::Sexy::xs_files,
				COPYRIGHT => 'Copyright (C) 2005-2008 by Florian Ragwitz'
		)
        . <<"EOM"
README: lib/Gtk2/Sexy.pm
\tpod2text \$< > \$@
EOM
}

1;
