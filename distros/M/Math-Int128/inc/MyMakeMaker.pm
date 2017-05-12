package inc::MyMakeMaker;

use strict;
use warnings;

use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_WriteMakefile_args => sub {
    my $self = shift;

    my $args = super();
    # This makes it build the perl_math_int64.c file into a .o and then link
    # it with Int128.o
    $args->{OBJECT} = '$(O_FILES)';

    delete $args->{VERSION};
    $args->{VERSION_FROM} = 'lib/Math/Int128.pm';

    return $args;
};

override _build_WriteMakefile_dump => sub {
    my $self = shift;

    my $dump = super();
    $dump .= <<'EOF';
$WriteMakefileArgs{DEFINE}  = _int128_define();
$WriteMakefileArgs{CCFLAGS} = _ccflags( $WriteMakefileArgs{CCFLAGS} );
EOF

    return $dump;
};

override _build_MakeFile_PL_template => sub {
    my $self     = shift;
    my $template = super();

    $template =~ s/^(WriteMakefile)/_check_for_capi_maker();\n\n$1/m;

    my $extra = do { local $/; <DATA> };
    return $template . $extra;
};

__PACKAGE__->meta()->make_immutable();

1;

__DATA__

use Config qw( %Config );

use lib 'inc';
use Config::AutoConf;

sub _check_for_capi_maker {
    return unless -d '.git';

    unless ( eval { require Module::CAPIMaker; 1; } ) {
        warn <<'EOF';

  It looks like you're trying to build Math::Int128 from the git repo. You'll
  need to install Module::CAPIMaker from CPAN in order to do this.

EOF

        exit 1;
    }
}

sub _int128_define {
    my $autoconf = Config::AutoConf->new;

    return unless $autoconf->check_default_headers();
    return '-D__INT128' if _check_type( $autoconf, '__int128' );
    return '-DINT128_TI'
        if _check_type( $autoconf, 'int __attribute__ ((__mode__ (TI)))' );

    warn <<'EOF';

  It looks like your compiler doesn't support a 128-bit integer type (one of
  "int __attribute__ ((__mode__ (TI)))" or "__int128"). One of these types is
  necessary to compile the Math::Int128 module.

EOF

    exit 1;
}

# This more complex check is needed in order to ferret out bugs with clang on
# i386 platforms. See http://llvm.org/bugs/show_bug.cgi?id=15834 for the bug
# report. This appears to be
sub _check_type {
    my $autoconf = shift;
    my $type     = shift;

    my $uint64_type
        = $autoconf->check_type('uint64_t') ? 'uint64_t'
        : $autoconf->check_type(
        'unsigned int __attribute__ ((__mode__ (DI)))')
        ? 'unsigned int __attribute__ ((__mode__ (DI)))'
        : return 0;

    my $cache_name = $autoconf->_cache_type_name( 'type', $type );
    my $check_sub = sub {
        my $prologue = $autoconf->_default_includes();
        $prologue .=
            $type =~ /__mode__/
            ? "typedef unsigned uint128_t __attribute__((__mode__(TI)));\n"
            : "typedef unsigned __int128 uint128_t;\n";

        # The rand() calls are there because if we just use constants than the
        # compiler can optimize most of this code away.
        my $body = <<"EOF";
$uint64_type a = (($uint64_type)rand()) * rand();
$uint64_type b = (($uint64_type)rand()) << 24;
uint128_t c = ((uint128_t)a) * b;
return c > rand();
EOF
        my $conftest = $autoconf->lang_build_program( $prologue, $body );
        return $autoconf->compile_if_else($conftest);
    };

    return $autoconf->check_cached( $cache_name, "for $type", $check_sub );
}

sub _ccflags {
    my $flags = shift;

    my $config_flags = $Config{ccflags};
    if ($config_flags) {
        $config_flags =~ s/ ?-arch i386//
            if $config_flags =~ /-arch x86_64/
            && $config_flags =~ /-arch i386/;
    }

    $flags = join q{ }, grep { defined && length } $flags, $config_flags;

    $flags
}

package MY;

sub postamble {
    my $self = shift;

    my $author = $self->{AUTHOR};
    $author = join( ', ', @$author ) if ref $author;
    $author =~ s/'/'\''/g;

    return <<"MAKE_FRAG";
c_api.h: c_api.decl
	perl -MModule::CAPIMaker -emake_c_api module_name=\$(NAME) module_version=\$(VERSION) author='$author'
MAKE_FRAG
}

sub init_dirscan {
    my $self = shift;
    $self->SUPER::init_dirscan(@_);
    push @{ $self->{H} }, 'c_api.h'
        unless grep { $_ eq 'c_api.h' } @{ $self->{H} };
    return;
}
