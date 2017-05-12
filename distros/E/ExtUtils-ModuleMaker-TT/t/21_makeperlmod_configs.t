use strict;
use warnings;

#use Test::More 'no_plan'; 
use Test::More tests => 27; 
use t::CLI;
use File::Copy;
use File::pushd;
use Path::Class;

BEGIN { 
    use_ok( "ExtUtils::ModuleMaker::Auxiliary",
        qw( _save_pretesting_status _restore_pretesting_status )
    );
}

#--------------------------------------------------------------------------#
# Setup
#--------------------------------------------------------------------------#

$|++;

my $null_default = dir('t/config/empty_default')->absolute;
my $sample_config = dir('t/config/sample')->absolute;

my $cli = t::CLI->new('bin/makeperlmod');

#--------------------------------------------------------------------------#
# Mask any user defaults for the duration of the program
#--------------------------------------------------------------------------#

# these add 8 tests
my $pretest_status = _save_pretesting_status();
# XXX This caused crazy deletion attempts all over my FS so disabling it
##END { _restore_pretesting_status( $pretest_status ) }

#--------------------------------------------------------------------------#
# error if config file doesn't exist
#--------------------------------------------------------------------------#

$cli->dies_ok(qw( -c doesntexist -s foo));
$cli->stderr_like(qr/doesntexist/, "config not found error message");

#--------------------------------------------------------------------------#
# set author name and templates via config
#--------------------------------------------------------------------------#

{
    my $dir = tempd;

    # create templates
    $cli->runs_ok(qw( -t templates ));

    # XXX should modify README template here and check after creation
    open( my $fh, ">", file("templates", "README"))
        or die "Couldn't open README template for editing";

    ok( print( $fh "Author: [% AUTHOR %]\n") , 
        "... modified README template");
    close $fh;
    
    # create new dir; sample config specifies templates directory
    $cli->runs_ok('-c', $sample_config, qw(-n Foo::Bar ));

    is( file("Foo-Bar/README")->slurp(chomp=>1), 
        "Author: Warren G. Harding",
        "... custom template filled with custom author name"
    );
    
}
    
#--------------------------------------------------------------------------#
# create a config file under a pseudonym
#--------------------------------------------------------------------------#

{
    my $dir = tempd;
    my $temp_program = "mpm_$$";
    ok( copy( $cli->program, $temp_program ),
        "Copied 'makeperlmod' to '$temp_program' for default config testing"
    ) or die $!;
    my $cli_copy = t::CLI->new( $temp_program );
    
    my $config_file;
    for my $config_name ( undef, qw( default foo ) ) {
        # create the default file
        $cli_copy->runs_ok('-d', $config_name ? $config_name : () );
        my $config_location = $cli_copy->stdout;
        chomp $config_location;

        # locate it the long way
        $cli_copy->runs_ok('-l', $config_name ? $config_name : () );
        $config_file = $cli_copy->stdout;
        chomp $config_file;
        $config_file = file($config_file);

        # confirm it matches
        is( $config_file, $config_location,
            "Config file reported by '-d' matches '-l'"
        );
            
        # confirm it exists
        my $clean_name = $config_name ? $config_name : 'default';
        ok( -e $config_file, "Found new config '$clean_name'" );

        # confirm that it works
        my @args = (
            ($config_name ? ( '-c', $config_name ) : ()),
            '-s', 
            'wibble'
        );
        $cli_copy->runs_ok(@args);
    }
    
    $config_file->dir()->rmtree;
    ok( ! -e $config_file->dir, 
       "Config directory for '$temp_program' cleaned up"
    );
}
