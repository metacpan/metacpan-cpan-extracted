package inc::MyMakeMaker;

# ABSTRACT: build a Makefile.PL that uses ExtUtils::MakeMaker
use Moose;

use namespace::autoclean;

extends 'Dist::Zilla::Plugin::DROLSKY::MakeMaker';

# We need to override this because we remove the DROLSKY::MakeMaker plugin
# from our config, and that's where this value is passed from our bundle.
has '+has_xs' => (
    default => 1,
);

override _build_WriteMakefile_args => sub {
    my $self = shift;

    my $args = super();

    $args->{PM} = {
        'lib/File/LibMagic.pm' => '$(INST_LIB)/File/LibMagic.pm',
        'lib/File/LibMagic/Constants.pm' =>
            '$(INST_LIB)/File/LibMagic/Constants.pm',
    };
    $args->{LIBS} = '-lmagic';

    delete $args->{VERSION};
    $args->{VERSION_FROM} = 'lib/File/LibMagic.pm';

    return $args;
};

override _build_WriteMakefile_dump => sub {
    my $self = shift;

    my $dump = super();
    $dump .= <<'EOF';
$WriteMakefileArgs{DEFINE} = ( $WriteMakefileArgs{DEFINE} || q{} ) . _defines();
$WriteMakefileArgs{INC}    = join q{ }, _includes();
$WriteMakefileArgs{LIBS}   = join q{ }, _libs(), $WriteMakefileArgs{LIBS};

EOF

    return $dump;
};

override _build_MakeFile_PL_template => sub {
    return super() . do { local $/ = undef; <DATA> };
};

__PACKAGE__->meta->make_immutable;

1;

__DATA__

use Config::AutoConf;
use Getopt::Long;

my @libs;
my @includes;

sub _libs     { return map { '-L' . $_ } @libs }
sub _includes { return map { '-I' . $_ } @includes }

sub _defines {
    GetOptions(
        'lib:s@'     => \@libs,
        'include:s@' => \@includes,
    );

    my $ac = Config::AutoConf->new(
        extra_link_flags   => [ _libs() ],
        extra_include_dirs => \@includes,
    );

    _check_libmagic($ac);

    my @defs;
    push @defs, '-DHAVE_MAGIC_VERSION'
            if $ac->check_lib( 'magic', 'magic_version' );
    push @defs, '-DHAVE_MAGIC_SETPARAM'
            if $ac->check_lib( 'magic', 'magic_setparam' );
    push @defs, '-DHAVE_MAGIC_GETPARAM'
            if $ac->check_lib( 'magic', 'magic_getparam' );

    return q{} unless @defs;
    return q{ } . join q{ }, @defs;
}

sub _check_libmagic {
    my $ac = shift;

    return
        if $ac->check_header('magic.h')
        && $ac->check_lib( 'magic', 'magic_open' );

    warn <<'EOF';

  This module requires the libmagic.so library and magic.h header. See
  INSTALL.md for more details on installing these.

EOF

    exit 1;
}
