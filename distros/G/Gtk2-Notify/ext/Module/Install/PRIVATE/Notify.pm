use strict;
use warnings;

package Module::Install::PRIVATE::Notify;

use base qw/Module::Install::Base/;

our $VERSION = '0.01';

use Gtk2::CodeGen;
use Glib::MakeHelper;
use ExtUtils::Depends;
use ExtUtils::PkgConfig;
use File::Spec::Functions qw/catfile rel2abs/;

sub notify {
    my ($self) = @_;

    mkdir 'build', 0777;

    my %pkg_config;
    eval {
       %pkg_config = ExtUtils::PkgConfig->find('libnotify');
    };

    if (my $error = $@) {
        print STDERR $@;
        return;
    }

    Glib::CodeGen->parse_maps('notify');
    Glib::CodeGen->write_boot(ignore => qr/^Gtk2::Notify$/);

    our $notify = ExtUtils::Depends->new('Gtk2::Notify', 'Gtk2');
    our @xs_files = <xs/*.xs>;

    $notify->add_xs( @xs_files );
    $notify->add_typemaps(rel2abs(catfile(qw( build notify.typemap ))));
    $notify->set_inc( $pkg_config{cflags}.' -Ibuild -Wall' );
    $notify->set_libs( $pkg_config{libs} );
    $notify->install(catfile(qw( build notify-autogen.h )));
    $notify->save_config(catfile(qw( build IFiles.pm )));
    $notify->add_pm(
        'lib/Gtk2/Notify.pm' => '$(INST_LIBDIR)/Notify.pm',
    );

    $self->makemaker_args(
        $notify->get_makefile_vars,
        MAN3PODS => {
            Glib::MakeHelper->do_pod_files(@xs_files),
        },
    );

    return 1;
}

package MY;

sub postamble {
    return Glib::MakeHelper->postamble_clean()
         . Glib::MakeHelper->postamble_docs_full(
             DEPENDS   =>  $Module::Install::PRIVATE::Notify::notify,
             XS_FILES  => \@Module::Install::PRIVATE::Notify::xs_files,
             COPYRIGHT => 'Copyright (C) 2006-2008 by Florian Ragwitz',
         );
}

1;
