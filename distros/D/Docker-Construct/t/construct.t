use strict;
use warnings;

use Test::Cmd;
use Test::More;
use File::Spec::Functions qw(catfile splitdir splitpath);

# Create Test::Cmd with a workdir
my $test = Test::Cmd->new(
    prog    => 'blib/script/docker-construct',
    workdir => ''
);

# Specify all of the filesystem that will be used
# to consturct our test image

my @setup_dirs      = (
    'setup',
    'image_setup',
    'final',
    [ 'setup', 'layer01' ],
    [ 'setup', 'layer02' ],
    [ 'setup', 'layer03' ],
);

my @layer01_dirs    = qw(a b c);
my %layer01_files   = (
    "root.txt"      => "hello there\n",
    "b/b.txt"       => "this is b.txt\n",
    "c/c.txt"       => "this is c.txt\n",
);

my @layer02_dirs    = qw(a);
my %layer02_files   = (
    "root.txt"      => "hello there (again)\n",
    "a/a.txt"       => "this is a.txt\n",
);

my @layer03_dirs    = qw(c d);
my %layer03_files   = (
    "root.txt"      => "goodbye!\n",
    ".wh.b"         => "",
    "c/.wh.c.txt"   => "",
    "d/d.txt"       => "this is d.txt\n",
);

my @image_dirs      = ();
my %image_files     = (
    'manifest.json' => <<'EOF',
[{
    "Config": "config.json",
    "Layers": [
        "layer01.tar", "layer02.tar", "layer03.tar"
    ]
}]
EOF
    'config.json'   => <<'EOF',
{
    "config": "yup"
}
EOF
);

my $dirs_to_create =    @setup_dirs   +
                        @layer01_dirs +
                        @layer02_dirs +
                        @layer03_dirs;

# Create filesystem within workdir
my $dirs_created = $test->subdir(
    @setup_dirs,
    ( map {[ 'setup', 'layer01', $_ ]}  @layer01_dirs ),
    ( map {[ 'setup', 'layer02', $_ ]}  @layer02_dirs ),
    ( map {[ 'setup', 'layer03', $_ ]}  @layer03_dirs ),
    ( map {[ 'image_setup',      $_ ]}  @image_dirs   )
);
die "failed to create one or more directories" unless $dirs_created == $dirs_to_create;

# _create_files
# Create a series of files inside the given subdirectory (first argument).
# All other arguments are interpreted as a hash mapping filenames
# to their text.
sub _create_files {
    my $base = shift;
    my %files = @_;

    my @basedirs = splitdir $base;
    while (my ($filename, $text) = each %files) {
        my $dirs = [ @basedirs, (splitpath $filename)[1,2] ];
        my $fullname = catfile @$dirs;
        $test->write($dirs, $text) or die "could not create test file: $fullname";
    }
}

_create_files('setup/layer01',      %layer01_files  );
_create_files('setup/layer02',      %layer02_files  );
_create_files('setup/layer03',      %layer03_files  );
_create_files('image_setup',        %image_files    );

# For each layer directory, create a tarball and place inside
# the image_setup directory.
for my $layer (qw(layer01 layer02 layer03)) {
    my $input  = $test->workpath('setup',$layer);
    my $output = $test->workpath('image_setup',"$layer.tar");
    system 'tar', '-C', $input, '-cf', $output, '.', '--xform=s,^./,,';
    die "could not create $layer.tar" unless $? == 0;
}

# Create a tarball of image_setup to act as our test image tarball.
my $image_input  = $test->workpath('image_setup');
my $image_output = $test->workpath('image.tar');
system 'tar', '-C', $image_input, '-cf', $image_output, '.', '--xform=s,^./,,';
die "could not create image.tar" unless $? == 0;

# Specify what the final, flattened image filesystem should look like
my @final_dirs      = qw(a c d);
my %final_files     = (
    "config.json"   => $image_files{'config.json'},
    "root.txt"      => "goodbye!\n",
    "a/a.txt"       => "this is a.txt\n",
    "d/d.txt"       => "this is d.txt\n",
);

plan tests => 1               # running docker-construct
            + @final_dirs     # test created directories
            + (%final_files)  # test created files
            + 2;              # to test whiteout-ed files/directories

# First test: Call docker-construct to create the image filesystem
# inside the 'final' directory.
my $final_output = $test->workpath('final');
$test->run(
    chdir => $test->workdir,
    args  => "$image_output $final_output --include_config",
);
ok($? == 0,     "call docker-construct");

# Test that each file/directory that should exist in the output does
for my $dir (@final_dirs) {
    ok(-d $test->workpath('final', $dir),   "check directory: $dir");
}
while (my ($filename, $text) = each %final_files) {
    my $path = $test->workpath('final', splitdir $filename);
    SKIP: {
        skip "file not found: final/$filename", 1 unless -f $path;

        open(my $fh, '<', $path)    or die "could not open file: final/$filename: $!";
        local $/ = undef;
        my $content = <$fh>;
        close $fh                   or die "could not close file: final/$filename: $!";

        is($content, $text,         "check file text: $filename");
    }
}

# Test that the two whiteout-ed files/directories do not exist.
ok(! -d $test->workpath(qw(final b)),        "check that final/b/ does not exist.");
ok(! -f $test->workpath(qw(final c c.txt)),  "check that final/c/c.txt does not exist.");
