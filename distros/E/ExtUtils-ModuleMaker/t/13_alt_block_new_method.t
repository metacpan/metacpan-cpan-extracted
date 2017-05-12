# t/13_alt_block_new_method.t
# test whether methods overriding those provided by EU::MM::StandardText
# create files as intended
use strict;
use warnings;
use Test::More 
tests =>  40;
# qw(no_plan);
use_ok( 'ExtUtils::ModuleMaker' );
use_ok( 'Cwd');
use_ok( 'ExtUtils::ModuleMaker::Auxiliary', qw(
        read_file_string
        _subclass_preparatory_tests
        _subclass_cleanup_tests
    )
);
use_ok( 'File::Copy' );
use Carp;

my $odir = cwd();
my $prepref = _subclass_preparatory_tests($odir);
my $persref         = $prepref->{persref};
my $pers_def_ref    = $prepref->{pers_def_ref};
my %els1            = %{ $prepref->{initial_els_ref} };
my $eumm_dir        = $prepref->{eumm_dir};
my $mmkr_dir_ref    = $prepref->{mmkr_dir_ref};

SKIP: {
    eval { require 5.006_001 };
    skip "tests require File::Temp, core with 5.6", 
        (40 - 20) if $@;
    use warnings;
    use_ok( 'File::Temp', qw| tempdir |);

    ########################################################################

    {   # Set:   Alt_block_new_method


        # real tests go here

        my $alt    = 'Alt_block_new_method.pm';
        copy( "$prepref->{sourcedir}/$alt", "$eumm_dir/$alt")
            or die "Unable to copy $alt for testing: $!";
        ok(-f "$eumm_dir/$alt", "file copied for testing");

        my $testmod = 'Beta';
        my $mod;
        
        ok( $mod = ExtUtils::ModuleMaker->new( 
                NAME           => "Alpha::$testmod",
                COMPACT        => 1,
                ALT_BUILD      =>
                    q{ExtUtils::ModuleMaker::Alt_block_new_method},
            ),
            "call ExtUtils::ModuleMaker->new for Alpha-$testmod"
        );

        ok( $mod->complete_build(), 'call complete_build()' );

        ok( -d qq{Alpha-$testmod}, "compact top-level directory exists" );
        ok( chdir "Alpha-$testmod", "cd Alpha-$testmod" );
        ok( -d, "directory $_ exists" ) for ( qw/lib scripts t/);
        ok( -f, "file $_ exists" )
            for ( qw/Changes LICENSE Makefile.PL MANIFEST README Todo/);
        ok( -f, "file $_ exists" )
            for ( "lib/Alpha/${testmod}.pm", "t/001_load.t" );

        my $filetext = read_file_string("lib/Alpha/${testmod}.pm");
        my $newstr = <<'ENDNEW';
sub new {
    my $class = shift;
    my $self = bless ({}, $class);
    return $self;
}
ENDNEW

        ok( (index($filetext, $newstr)) > -1, 
            "string present in file as predicted");

        unlink( "$eumm_dir/$alt" )
            or croak "Unable to unlink $alt for testing: $!";
        ok(! -f "$eumm_dir/$alt", "file $alt deleted after testing");

        # end of real tests


    } # end of Set

    ok(chdir $odir, "changed back to original directory");

} # end SKIP block

END {
    _subclass_cleanup_tests( {
        persref         => $persref,
        pers_def_ref    => $pers_def_ref,
        eumm_dir        => $eumm_dir,
        initial_els_ref => \%els1,
        odir            => $odir,
        mmkr_dir_ref    => $mmkr_dir_ref,
    } );
}

