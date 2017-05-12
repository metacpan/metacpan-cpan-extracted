use Devel::CheckLib;
use ExtUtils::MakeMaker;
use File::Spec::Functions;
use File::Which;

my %header_config = ( header => 'ft2build.h', );

my $config; # store various configurations to check

# use the pkg-config wrapper for FreeType
if( which('freetype-config') ) {
    chomp($config->{ft_config}{LIBS} = `freetype-config --libs`);
    chomp($config->{ft_config}{INC}  = `freetype-config --cflags`);
}

# default configuration
$config->{default}{lib} = 'freetype';
$config->{default}{INC} = '-I/usr/include/freetype2';

# try each configuration
my $working_config_name = undef;
for my $config_name (qw(ft_config)) {
    my %checklib_config = (
            %{ $config->{$config_name} },
            %header_config,
    );

    # test the configuration
    if( check_lib( %checklib_config ) ) {
        $working_config_name = $config_name;
    }
}

# if none of the tried configurations work, use the default
$working_config_name = 'default' if not defined $working_config_name;

my $working_config = $config->{$working_config_name};
if( !exists $working_config->{LIBS} && exists $working_config->{lib} ) {
    $working_config->{LIBS} = "-l$working_config->{lib}";
}

# MakeMaker build flags
my %MakeMakerFlags = (
    LIBS => $working_config->{LIBS},
    INC  => $working_config->{INC},
);

print STDERR "Build config: $working_config_name\n";
print STDERR "Build flag LIB: $MakeMakerFlags{LIBS}\n";
print STDERR "Build flag INC: $MakeMakerFlags{INC}\n";

# finally use check_lib_or_exit so that it gives appropriate warnings to the user
check_lib_or_exit(
    %MakeMakerFlags,
    %header_config,
);

WriteMakefile(
    NAME               => 'Font::FreeType',
    AUTHOR             => 'Geoff Richards <qef@laxan.com>',
    VERSION_FROM       => 'lib/Font/FreeType.pm',
    ( eval { ExtUtils::MakeMaker->VERSION(6.64) } ?
        (
            CONFIGURE_REQUIRES => {
                "Devel::CheckLib"     => '0',
                "ExtUtils::MakeMaker" => "6.64",
                "File::Which"         => '0',
            },
            TEST_REQUIRES      => {
                Test::Warnings => 0,
            },
        ) : (
            PREREQ_PM => {
                "Devel::CheckLib"     => '0',
                "File::Which"         => '0',
                "ExtUtils::MakeMaker" => '6.64',
                Test::Warnings        => 0,
            },
        )
    ),
    %MakeMakerFlags, # set LIB/INC from working configuration
    ( eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ?
        (
            META_MERGE => {
                resources => {
                    repository => 'https://github.com/zmughal/p5-Font-FreeType',
                },
            }
        ) : ()
    ),
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? ( MIN_PERL_VERSION => '5.8.1') : ()),
);

# Generate a listing of the characters in the BDF test font, for checking
# that the library can find them all.  See t/10metrics_5x7bdf.t
my $data_dir = catdir(qw( t data ));
my $font_filename = catfile($data_dir, '5x7.bdf');
open my $font_file, '<', $font_filename
  or die "error opening BDF font '$font_filename': $!";
my $list_filename = catfile($data_dir, 'bdf_glyphs.txt');
open my $list_file, '>', $list_filename
  or die "error opening glyph listing file '$list_filename': $!";
my $name;
while (<$font_file>) {
    if (/^STARTCHAR\s+(.*)$/) {
        $name = $1;
        next;
    }
    elsif (/ENCODING\s+(\d+)$/) {
        die "BDF file is broken" unless defined $name;
        printf $list_file "%04X\t$name\n", $1;
        $name = undef;
    }
}

# vi:ts=4 sw=4 expandtab:
