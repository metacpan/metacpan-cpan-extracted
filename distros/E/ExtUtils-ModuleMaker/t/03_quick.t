# t/03_quick.t
use strict;
use warnings;
use Test::More tests => 36;
use_ok( 'ExtUtils::ModuleMaker' );
use_ok( 'ExtUtils::ModuleMaker::Auxiliary', qw(
        _save_pretesting_status
        _restore_pretesting_status
    )
);

my $statusref = _save_pretesting_status();

SKIP: {
    eval { require 5.006_001 };
    skip "tests require File::Temp, core with Perl 5.6", 
        (36 - 10) if $@;
    use warnings;
    use_ok( 'File::Temp', qw| tempdir |);
    my $tdir = tempdir( CLEANUP => 1);
    ok(chdir $tdir, 'changed to temp directory for testing');

    ###########################################################################

    my $mod;

    ok($mod  = ExtUtils::ModuleMaker->new ( NAME => 'Sample::Module'),
        "call ExtUtils::ModuleMaker->new for Sample-Module");
        
    ok( $mod->complete_build(), 'call complete_build()' );

    ########################################################################

    ok(chdir "Sample/Module",
        "cd Sample/Module");

    for (qw/Changes MANIFEST Makefile.PL LICENSE
            README lib t/) {
        ok (-e,
            "$_ exists");
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

    ok($filetext =~ m/Terms of Perl itself/,
        "correct LICENSE generated");

    ########################################################################

    # tests of inheritability of constructor
    # note:  attributes must not be thought of as inherited because
    # constructor freshly repopulates data structure with default values

    my ($modparent, $modchild, $modgrandchild);

    ok($modparent  = ExtUtils::ModuleMaker->new(
        NAME => 'Sample::Module',
        ABSTRACT => 'The quick brown fox'
    ), "call ExtUtils::ModuleMaker->new for Sample-Module");
    isa_ok($modparent, "ExtUtils::ModuleMaker", "object is an EU::MM object");
    is($modparent->{NAME}, 'Sample::Module', "NAME is correct");
    is($modparent->{ABSTRACT}, 'The quick brown fox', "ABSTRACT is correct");

    $modchild = $modparent->new(
        'NAME'     => 'Alpha::Beta',
        ABSTRACT => 'The quick brown fox'
    );
    isa_ok($modchild, "ExtUtils::ModuleMaker", "constructor is inheritable");
    is($modchild->{NAME}, 'Alpha::Beta', "new NAME is correct");
    is($modchild->{ABSTRACT}, 'The quick brown fox', 
        "ABSTRACT was correctly inherited");

    ok($modgrandchild  = $modchild->new(
        NAME => 'Gamma::Delta',
        ABSTRACT => 'The quick brown vixen'
    ), "call ExtUtils::ModuleMaker->new for Sample-Module");
    isa_ok($modgrandchild, "ExtUtils::ModuleMaker", "object is an EU::MM object");
    is($modgrandchild->{NAME}, 'Gamma::Delta', "NAME is correct");
    is($modgrandchild->{ABSTRACT}, 'The quick brown vixen', 
        "explicitly coded ABSTRACT is correct");

    ok(chdir $statusref->{cwd},
        "changed back to original directory");
} # end SKIP block

END {
    _restore_pretesting_status($statusref);
}

