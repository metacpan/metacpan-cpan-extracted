use strict;
use ExtUtils::MakeMaker;
use File::Basename qw(fileparse);

# The location of shapelib (libshp) can be given as a command line
# param or as an env var.
my %ARGV;
for (@ARGV) {
    $ARGV{$1} = $2 if /^--(.*?)\=(.*)/;
    $_ = '' if /^--shapelib/;
}
$ARGV{shapelib} = $ENV{PERL_SHAPELIB} unless defined $ARGV{shapelib};

# If not given, search.
unless (defined $ARGV{shapelib}) {
    # scan known possible locations in the order of preference:
    my @locs;
    for (qw(/usr/lib /usr/lib64 /usr/lib/x86_64-linux-gnu /usr/local/lib /usr/local/lib64)) {
        # prefer a shared lib
        my $lib = $_ . '/libshp.so';
        $lib = $_ . '/libshp.a' unless -e $lib;
        push @locs, $lib if -e $lib;
    }
    if (@locs) {
        print "Found shapelib(s): '",join("', '", @locs),"'.\n";
        $ARGV{shapelib} = $locs[0];
        print "Will use '$ARGV{shapelib}'.\n";
    }
}
die "Can't find shapelib.\n".
    "Please install a development version of shapelib or\n".
    "specify the location of libshp.a or libshp.so with\n".
    "command line parameter --shapelib= or with environment\n".
    "variable PERL_SHAPELIB.\n".
    "You can get shapelib from http://download.osgeo.org/shapelib/."
    unless -e $ARGV{shapelib};

# Does the shapelib define SHPSearchDiskTree?
my $HAS_SEARCH_DISK_TREE;
if ($ARGV{shapelib} =~ /\.a$/) {
    my @ret = `nm $ARGV{shapelib} | grep SHPSearchDiskTree`;
    $HAS_SEARCH_DISK_TREE = $ret[0] ne '';
} else {
    my @ret = `readelf -Ws $ARGV{shapelib} | grep SHPSearchDiskTree`;
    $HAS_SEARCH_DISK_TREE = $ret[0] ne '';
}

warn "Warning: Shapelib is old version. You will not be able to save quadtree index." unless $HAS_SEARCH_DISK_TREE;
my ($file, $path, $suffix) = fileparse($ARGV{shapelib});

my $libs;
my $inc;
my $define;
if ($HAS_SEARCH_DISK_TREE) {
    $libs = ["-L$path -lshp"];
    $inc = "-I$path";
    $define = '-DHAS_SEARCH_DISK_TREE';
} else {
    $libs = ["-L$path -lshp"];
    $inc = "-I$path";
    $define = undef;
}

WriteMakefile(
    NAME                => 'Geo::Shapelib',
    VERSION_FROM        => 'lib/Geo/Shapelib.pm',
    PREREQ_PM           => {'Tree::R' => 0.01}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM       => 'lib/Geo/Shapelib.pm',
    LIBS                => $libs,
    DEFINE              => $define,
    INC                 => $inc,
    clean               => {'FILES' => 'stations.* example/test.*'},
    AUTHOR              => 'Ari Jolma <https://github.com/ajolma>',
    LICENSE             => 'perl_5',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository  => {
                type => 'git',
                web  => 'https://github.com/ajolma/Geo-Shapelib',
                url  => 'https://github.com/ajolma/Geo-Shapelib.git',
            },
        },
    }
);
