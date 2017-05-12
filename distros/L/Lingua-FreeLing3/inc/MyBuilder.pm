package MyBuilder;
use base 'Module::Build';

use warnings;
use strict;

use Config;
use Carp;

use ExtUtils::PkgConfig;
use ExtUtils::Mkbootstrap;
use Config::AutoConf;

use File::Spec::Functions qw.catdir catfile.;
use File::Path qw.mkpath.;

sub fix_cbuilder {
    my $cbuilder = shift;
    $cbuilder->{config}{cxxflags} =~ s/-arch \S+//g;
    $cbuilder->{config}{lddlflags} =~ s/-arch \S+//g;
}

sub ACTION_code {
    my $self = shift;

    $self->dispatch("create_objects");
    $self->dispatch("compile_xscode");
    $self->SUPER::ACTION_code;
}

sub ACTION_compile_xscode {
    my $self = shift;
    my $cbuilder = $self->cbuilder;
    my $archdir  = catdir( $self->blib, 'arch', 'auto', 'Lingua', 'FreeLing3', 'Bindings');
    mkpath( $archdir, 0, 0777 ) unless -d $archdir;

    my $object = 'FreeLing.o';

    my $bs_file = catfile( $archdir => "Bindings.bs" );
    if ( !$self->up_to_date( $object, $bs_file ) ) {
        ExtUtils::Mkbootstrap::Mkbootstrap($bs_file);
        if ( !-f $bs_file ) {
            # Create file in case Mkbootstrap didn't do anything.
            open( my $fh, '>', $bs_file ) or confess "Can't open $bs_file: $!";
        }
        utime( (time) x 2, $bs_file );    # touch
    }

    # .o => .(a|bundle)
    my $lib_file = catfile( $archdir => "Bindings.$Config{dlext}" );
    if ( !$self->up_to_date( [ $object, $bs_file ], $lib_file ) ) {
        fix_cbuilder($cbuilder);
        $cbuilder->link(
                        module_name => 'Lingua::FreeLing3::Bindings',
                        extra_linker_flags => $self->notes('fl_libs'),
                        objects     => [$object],
                        lib_file    => $lib_file,
                       );
    }
}

sub ACTION_create_objects {
    my $self = shift;
    my $cbuilder = $self->cbuilder;

    die "Do not have a C++ compiler" unless $cbuilder->have_cplusplus;

    my $file = catfile('swig','FreeLing_wrap.cxx');
    my $object = 'FreeLing.o';

    return if $self->up_to_date($file, $object);

    fix_cbuilder($cbuilder);
    $cbuilder->compile(object_file  => $object,
                       extra_compiler_flags => $self->notes('fl_cflags'),
                       source       => $file,
                       'C++'        => 1);
}


sub detect_freeling {
    my $builder = shift;
    my %freeling = eval { ExtUtils::PkgConfig->find('freeling') };

    carp "Can't find FreeLing 3 .pc file." and exit 0 unless exists $freeling{libs};

    my $datadir = ExtUtils::PkgConfig->variable('freeling' => 'DataDir');

    $freeling{modversion} =~ /(\d+)\.(\d+)/;
    my ($major, $minor) = ($1, $2);

    $builder->notes(fl_major   => $major);
    $builder->notes(fl_minor   => $minor);
    $builder->notes(fl_version => $freeling{modversion});
    $builder->notes(fl_cflags  => $freeling{cflags});
    $builder->notes(fl_libs    => $freeling{libs});
    $builder->notes(fl_datadir => $datadir);

    $builder->config_data(fl_major   => $major);
    $builder->config_data(fl_minor   => $minor);
    $builder->config_data(fl_version => $freeling{modversion});
    $builder->config_data(fl_cflags  => $freeling{cflags});
    $builder->config_data(fl_libs    => $freeling{libs});
    $builder->config_data(fl_datadir => $datadir);
}

1;
