use strict;
use warnings;
use Module::Build;
use File::Which;
use File::Spec;

my $builder = Module::Build->new(
    module_name             => 'Lingua::TreeTagger',
    license                 => 'gpl',
    dist_author             => q{Aris Xanthos <aris.xanthos@unil.ch>},
    dist_version            => '0.08',
    configure_requires => {
        'File::Spec'        => 0,
        'File::Which'       => 0,
    },
    build_requires => {
        'Test::More'        => 0,
        'Test::More::UTF8'  => 0,
        'File::Temp'        => 0.19,
    },
    requires => {
        'Moose'             => 0,
        'Path::Class'       => 0,
        'File::Temp'        => 0.19,
    },
);

my ( $treetagger_base_path, $treetagger_prog_path, $tokenizer_prog_path );
my ( $treetagger_lib_path, $test_language );

$treetagger_prog_path = which( 'tree-tagger' );

# If TreeTagger was found in PATH...
if ( defined $treetagger_prog_path ) {

    # Convert it to Path:Class:File.
    $treetagger_prog_path = file( $treetagger_prog_path );
}
# Else if TreeTagger was not found in PATH, try platform-specific defaults...
else {

    my $default_treetagger_prog_path;

    # Windows...
    if ( $^O eq 'MSWin32' ) {
        $default_treetagger_prog_path
            = file( 'C:/Program Files/TreeTagger/bin/tree-tagger.exe' );
    }
    # MacOSX...
    elsif ( $^O eq 'darwin' ) {
        $default_treetagger_prog_path
            = file( '/Applications/Tree-Tagger/bin/tree-tagger' );
    }
    # Linux...
    elsif ( $^O eq 'linux' ) {
        $default_treetagger_prog_path
            = file( '/bin/tree-tagger' );
    }

    # If default works, set path to TreeTagger executable...
    if ( -x $default_treetagger_prog_path ) {
        $treetagger_prog_path = $default_treetagger_prog_path;
    }
}

# If TreeTagger still wasn't found...
if ( ! defined $treetagger_prog_path ) {

    # Prompt the user...
    my $prompted_treetagger_prog_path = Module::Build->prompt(
        "Please enter the full path to the TreeTagger executable:"
    );

    # ... until the prompted path can be verified.
    while ( ! -x $prompted_treetagger_prog_path ) {

        print "Sorry, the TreeTagger executable doesn't seem to be there.\n";

        $prompted_treetagger_prog_path = Module::Build->prompt(
            "Please enter the full path to the TreeTagger executable:"
        );
    }

    # Then store the prompted path.
    $treetagger_prog_path = file( $prompted_treetagger_prog_path );
}

# Get path to TreeTagger base directory from program path.
$treetagger_base_path = parent( parent( $treetagger_prog_path ) );

my @installed_parameter_files;

# If there is a /lib directory in there...
if ( -d dir( $treetagger_base_path, 'lib' ) ) {

    # Save that location.
    $treetagger_lib_path = dir( $treetagger_base_path, 'lib' );

    # Try to find TreeTagger parameters file in there...
    @installed_parameter_files
        = get_installed_parameter_files( $treetagger_lib_path );

    if (!@installed_parameter_files) {
        # Try to guess where Lingua::TreeTagger::Installer would put them
        my $p = $builder->install_destination('lib');
        $treetagger_lib_path = dir ( $p, 'treetagger');
        @installed_parameter_files
          = get_installed_parameter_files( $treetagger_lib_path );
    }
}

# If there is no parameter file...
if ( @installed_parameter_files == 0 ) {

    # Prompt the user...
    my $prompted_treetagger_lib_path = Module::Build->prompt(
        "Please enter the full path to the TreeTagger 'lib' directory:"
    );

    @installed_parameter_files
        = get_installed_parameter_files( $prompted_treetagger_lib_path );

    # ... until the prompted path can be verified.
    while ( @installed_parameter_files == 0 ) {

        print "Sorry, the TreeTagger parameter files don't seem to be there.\n";

        $prompted_treetagger_lib_path = Module::Build->prompt(
            "Please enter the full path to the TreeTagger 'lib' directory:"
        );

        @installed_parameter_files
            = get_installed_parameter_files( $prompted_treetagger_lib_path );
    }

    # Then store the prompted path.
    $treetagger_lib_path = $prompted_treetagger_lib_path;

    # Discard unicode parameter files (not yet supported by the module).
    @installed_parameter_files
        = grep { $_ !~ /utf8/ } @installed_parameter_files;

    # Throw exception if there is no non-unicode parameter file.
    die "Sorry, there are only unicode parameter files in the 'lib' directory "
      . "and those are not supported by the module (yet). Aborting install..."
      if @installed_parameter_files == 0;
}

# Pick a parameter file for testing.
$test_language = $installed_parameter_files[ rand @installed_parameter_files ];
$test_language =~ s/\.par//;

# Set default path for script tokenize.pl.
my $default_tokenizer_prog_path
    = file( $treetagger_base_path, 'cmd', 'tokenize.pl' );

if (!-e $default_tokenizer_prog_path) {
    # try to guess where Lingua::TreeTagger::Installer would put it
    my $p = $builder->install_destination("bin");
    $default_tokenizer_prog_path = file($p, 'treetagger', 'tokenize.pl');
}

# If tokenize.pl is at that location...
if ( -e $default_tokenizer_prog_path ) {

    # Save that location.
    $tokenizer_prog_path = $default_tokenizer_prog_path;
}
# Otherwise...
else {

    # Prompt the user...
    my $prompted_tokenizer_prog_path = Module::Build->prompt(
        "Please enter the full path to the script 'tokenize.pl':"
    );

    # ... until the prompted path can be verified.
    while ( ! -e $prompted_tokenizer_prog_path ) {

        print "Sorry, the script 'tokenize.pl' doesn't seem to be there.\n";

        $prompted_tokenizer_prog_path = Module::Build->prompt(
            "Please enter the full path to the script 'tokenize.pl':"
        );
    }

    # Then store the prompted path.
    $tokenizer_prog_path = $prompted_tokenizer_prog_path;
}

# Store all the data that was gathered in Lingua::TreeTagger::ConfigData.pm.
$builder->config_data( 'treetagger_prog_path'  => "$treetagger_prog_path" );
$builder->config_data( 'tokenizer_prog_path'   => "$tokenizer_prog_path"  );
$builder->config_data( 'treetagger_lib_path'   => "$treetagger_lib_path"  );
$builder->config_data( 'test_language'         => $test_language          );

$builder->create_build_script();

sub get_installed_parameter_files {
    my ( $treetagger_lib_path ) = @_;

    # Return empty list if directory doesn't exist.
    return () if ! -d $treetagger_lib_path;

    # Open directory and retrieve parameter files...
    opendir( my $lib_dir, $treetagger_lib_path );
    my @parameter_files = grep { /\.par$/ } readdir( $lib_dir );

    return @parameter_files;
}

# Replacement for Path::Class methods -- until it becomes a standard module...

sub file {
    return File::Spec->catfile( split( qr{[\\/]}, shift @_ ), @_ );
}

sub dir {
    return File::Spec->catdir( split( qr{[\\/]}, shift @_ ), @_ );
}

sub parent {
    my @path_elements = split qr{[\\/]}, shift @_;
    splice @path_elements, -1;
    return File::Spec->catdir( @path_elements );
}


