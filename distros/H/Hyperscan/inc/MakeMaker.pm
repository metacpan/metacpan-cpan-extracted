package inc::MakeMaker;

use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

around _build_MakeFile_PL_template => sub {
    my $orig = shift;
    my $self = shift;

    my $NEW_CONTENT = <<'TEMPLATE';
use ExtUtils::Constant qw(WriteConstants);

my @names = qw(
    HS_MAJOR HS_MINOR HS_PATCH

    HS_FLAG_CASELESS
    HS_FLAG_DOTALL
    HS_FLAG_MULTILINE
    HS_FLAG_SINGLEMATCH
    HS_FLAG_ALLOWEMPTY
    HS_FLAG_UTF8
    HS_FLAG_UCP
    HS_FLAG_PREFILTER
    HS_FLAG_SOM_LEFTMOST
    HS_FLAG_COMBINATION
    HS_FLAG_QUIET

    HS_MODE_BLOCK
    HS_MODE_NOSTREAM
    HS_MODE_STREAM
    HS_MODE_VECTORED

    HS_MODE_SOM_HORIZON_LARGE
    HS_MODE_SOM_HORIZON_MEDIUM
    HS_MODE_SOM_HORIZON_SMALL
);

WriteConstants(
    PROXYSUBS => {autoload => 1},
    NAME => 'Hyperscan',
    NAMES => \@names,
);

use ExtUtils::PkgConfig;

my %pkg_info = ExtUtils::PkgConfig->find('libhs');
TEMPLATE

    # insert new content near the beginning of the file, preserving the
    # existing header content
    my $string = $self->$orig(@_);
    $string =~ m/use warnings;\n\n/g;
    return substr($string, 0, pos($string)) . $NEW_CONTENT . substr($string, pos($string));
};

override _build_WriteMakefile_dump => sub {
    my $self = shift;

    my $dump = super();
    $dump .= <<'EOF';
$WriteMakefileArgs{CCFLAGS} = $pkg_info{cflags};
$WriteMakefileArgs{LIBS}    = $pkg_info{libs};
EOF

    return $dump;
};

1;
