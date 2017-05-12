package MyBuilder;
use base 'Module::Build';
use warnings;
use strict;
use Config;
use Carp;
use Config::AutoConf;

use ExtUtils::LibBuilder;
use File::Spec::Functions qw.catdir catfile.;
use File::Path qw.mkpath.;

my @SOURCES = map { "cld-src/$_" }
  (
   qw{encodings/compact_lang_det/cldutil.cc
      encodings/compact_lang_det/cldutil_dbg_empty.cc
      encodings/compact_lang_det/compact_lang_det.cc
      encodings/compact_lang_det/compact_lang_det_impl.cc
      encodings/compact_lang_det/ext_lang_enc.cc
      encodings/compact_lang_det/getonescriptspan.cc
      encodings/compact_lang_det/letterscript_enum.cc
      encodings/compact_lang_det/tote.cc
      encodings/compact_lang_det/generated/cld_generated_score_quadchrome_0406.cc
      encodings/compact_lang_det/generated/compact_lang_det_generated_cjkbis_0.cc
      encodings/compact_lang_det/generated/compact_lang_det_generated_ctjkvz.cc
      encodings/compact_lang_det/generated/compact_lang_det_generated_deltaoctachrome.cc
      encodings/compact_lang_det/generated/compact_lang_det_generated_quadschrome.cc
      encodings/compact_lang_det/win/cld_htmlutils_windows.cc
      encodings/compact_lang_det/win/cld_unilib_windows.cc
      encodings/compact_lang_det/win/cld_utf8statetable.cc
      encodings/compact_lang_det/win/cld_utf8utils_windows.cc
      encodings/internal/encodings.cc
      languages/internal/languages.cc}
  );


use ExtUtils::ParseXS;
use ExtUtils::Mkbootstrap;

sub ACTION_code {
    my $self = shift;

    my $libbuilder = ExtUtils::LibBuilder->new;
    $self->notes(libbuilder => $libbuilder);

    $self->notes(CFLAGS  => '-fPIC -I. -O2 -DCLD_WINDOWS'); # XXX fixme for windows
    $self->notes(LDFLAGS => '-L.');

    $self->dispatch("create_objects");
    $self->dispatch("compile_xscode");

    $self->SUPER::ACTION_code;
}


sub ACTION_compile_xscode {
    my $self = shift;
    my $cbuilder = $self->cbuilder;

    my $archdir = catdir( $self->blib, 'arch', 'auto', 'Lingua', 'Identify', 'CLD');
    mkpath( $archdir, 0, 0777 ) unless -d $archdir;

    print STDERR "\n** Preparing XS code\n";
    my $cfile = catfile("CLD.cc");
    my $xsfile= catfile("CLD.xs");
    my $ofile = catfile("CLD.o");

    $self->add_to_cleanup($cfile); ## FIXME
    if (!$self->up_to_date($xsfile, $cfile)) {
        ExtUtils::ParseXS::process_file( filename   => $xsfile,
                                         'C++'      => 1,
                                         prototypes => 0,
                                         output     => $cfile);
    }

    $self->add_to_cleanup($ofile); ## FIXME

    my $extra_compiler_flags = $self->notes('CFLAGS');
    $Config{ccflags} =~ /(-arch \S+(?: -arch \S+)*)/ and $extra_compiler_flags .= " $1";

    if (!$self->up_to_date($cfile, $ofile)) {
        $cbuilder->compile( source               => $cfile,
                            include_dirs         => [ catdir("cld-src") ],
                            'C++'                => 1,
                            extra_compiler_flags => $extra_compiler_flags,
                            object_file          => $ofile);
    }

    # Create .bs bootstrap file, needed by Dynaloader.
    my $bs_file = catfile( $archdir, "CLD.bs" );
    if ( !$self->up_to_date( $ofile, $bs_file ) ) {
        ExtUtils::Mkbootstrap::Mkbootstrap($bs_file);
        if ( !-f $bs_file ) {
            # Create file in case Mkbootstrap didn't do anything.
            open( my $fh, '>', $bs_file ) or confess "Can't open $bs_file: $!";
        }
        utime( (time) x 2, $bs_file );    # touch
    }

    my $extra_linker_flags = "-lstdc++";
    $extra_linker_flags .= " -lgcc_s" if $^O eq 'netbsd';

    my $objects = [
      $ofile,
      @{ $self->rscan_dir('cld-src', qr/\.o$/) },
    ];

    # .o => .(a|bundle)
    my $lib_file = catfile( $archdir, "CLD.$Config{dlext}" );
    if ( !$self->up_to_date( [ @$objects ], $lib_file ) ) {
        my $btparselibdir = $self->install_path('usrlib');
        $cbuilder->link(
                        module_name => 'Lingua::Identify::CLD',
                        extra_linker_flags => $extra_linker_flags,
                        objects     => $objects,
                        lib_file    => $lib_file,
                       );
    }
}

sub ACTION_create_objects {
    my $self = shift;
    my $cbuilder = $self->cbuilder;

    my $extra_compiler_flags = $self->notes('CFLAGS');
    $Config{ccflags} =~ /(-arch \S+(?: -arch \S+)*)/ and $extra_compiler_flags .= " $1";

    for my $file (@SOURCES) {
        my $object = $file;
        $object =~ s/\.cc/.o/;
        next if $self->up_to_date($file, $object);
        $cbuilder->compile(object_file  => $object,
                           source       => $file,
                           include_dirs => ["cld-src"],
                           extra_compiler_flags => $extra_compiler_flags,
                           'C++' => 1);
    }
}

1;
