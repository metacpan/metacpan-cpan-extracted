# t/04_compact.t
use strict;
local $^W = 1;
use Test::More tests => 27;
use_ok( 'ExtUtils::ModuleMaker::PBP' );
use_ok( 'ExtUtils::ModuleMaker::Auxiliary', qw(
        _save_pretesting_status
        _restore_pretesting_status
    )
);

my $statusref = _save_pretesting_status();

SKIP: {
    eval { require 5.006_001 };
    skip "tests require File::Temp, core with Perl 5.6", 
        (27 - 10) if $@;
    use warnings;
    use_ok( 'File::Temp', qw| tempdir |);
    my $tdir = tempdir( CLEANUP => 1);
    ok(chdir $tdir, 'changed to temp directory for testing');

    #######################################################################

    my $mod;

    ok($mod  = ExtUtils::ModuleMaker::PBP->new
    			( 
    				NAME		=> 'Sample::Module::Foo',
    				LICENSE		=> 'looselips',
    			 ),
    	"call ExtUtils::ModuleMaker::PBP->new for Sample-Module-Foo");
    	
    ok( $mod->complete_build(), 'call complete_build()' );

    ########################################################################

    ok(chdir 'Sample-Module-Foo',
    	"cd Sample-Module-Foo");

    for (qw/Changes MANIFEST Makefile.PL LICENSE README lib t/) {
        ok (-e, "$_ exists");
    }
    for (qw/scripts Todo/) {
        ok (! -e, "$_ does not exist");
    }

    ########################################################################

    my $filetext;
    {
        local *FILE;
        ok(open (FILE, 'LICENSE'),
            "reading 'LICENSE'");
        $filetext = do {local $/; <FILE>};
        close FILE;
    }

    ok($filetext =~ m/Loose lips sink ships/,
    	"correct LICENSE generated");

    ok(chdir $statusref->{cwd}, "changed back to original directory");

} # end SKIP block

END {
    _restore_pretesting_status($statusref);
}

