use strict;
use warnings;

use Test::More tests => 51;
use t::CLI;
use File::pushd 1;
use Path::Class 0.15;

BEGIN { 
    use_ok( "ExtUtils::ModuleMaker::Auxiliary",
        qw( _save_pretesting_status _restore_pretesting_status )
    );
}

#--------------------------------------------------------------------------#
# Setup
#--------------------------------------------------------------------------#

my $null_default = dir('t/config/empty_default')->absolute;
my $cli = t::CLI->new('bin/makeperlmod', "-c", $null_default);

my @Foo_Bar_files = qw(
     Foo-Bar
     Foo-Bar/Changes
     Foo-Bar/LICENSE
     Foo-Bar/Makefile.PL
     Foo-Bar/MANIFEST
     Foo-Bar/README
     Foo-Bar/Todo
     Foo-Bar/lib
     Foo-Bar/lib/Foo
     Foo-Bar/lib/Foo/Bar.pm
     Foo-Bar/scripts
     Foo-Bar/t
     Foo-Bar/t/001_load.t
);

#--------------------------------------------------------------------------#
# Mask any user defaults for the duration of the program
#--------------------------------------------------------------------------#

# these add 8 tests
my $pretest_status = _save_pretesting_status();
# XXX This caused crazy deletion attempts all over my FS so disabling it
##END { _restore_pretesting_status( $pretest_status ) }

#--------------------------------------------------------------------------#
# With no arguments or in help mode, give a usage message
#--------------------------------------------------------------------------#

$cli->dies_ok();
$cli->stdout_like(qr/usage/i, "generated a usage message");

for (qw( -? -h --help) ) {
    $cli->dies_ok($_);
    $cli->stdout_like(qr/usage/i, "generated a usage message");
}

#--------------------------------------------------------------------------#
# version report
#--------------------------------------------------------------------------#

for (qw( -V --version ) ) {
    $cli->runs_ok($_);
    $cli->stdout_like(qr/version/i, "generated version information");
}

#--------------------------------------------------------------------------#
# write a template dir
#--------------------------------------------------------------------------#

{
    no warnings 'once';
    require_ok("ExtUtils::ModuleMaker::TT");

    my %tt_templates = %ExtUtils::ModuleMaker::TT::templates;
    my $first_pass;

    for (qw( -t --templates )) {
        my $dir = dir( my $td = tempd );
        
        $cli->runs_ok($_,"templates");

        ok( -e $dir->subdir("templates"), "... template dir exists" );
        
        my @file_list = map { $_->basename } dir->subdir("templates")->children;
        is_deeply( 
            [sort @file_list], 
            [sort keys %tt_templates],
            "... correct list of templates generated"
        ) or diag "Got @file_list";
        
        if (!$first_pass) {
            for (@file_list) {
            is( $dir->file("templates", $_)->slurp(), 
                $tt_templates{$_}, 
                "... template '$_' correct"
            );
            $first_pass++;
            }
        }
    }
}

#--------------------------------------------------------------------------#
# Print a sub
#--------------------------------------------------------------------------#

for ( qw( -s --subroutine ) ) {

    $cli->runs_ok($_, 'foo');
    $cli->stdout_like(qr{sub \s+ foo \s+ \{}xmsi, "generated a subroutine");
}

#--------------------------------------------------------------------------#
# Create a basic distribution
#--------------------------------------------------------------------------#

for ( qw( -n --newdist) ) {
    my $dir = dir( my $td = tempd );
    
    $cli->runs_ok($_, 'Foo::Bar');

    my @file_list;
    $dir->subdir("Foo-Bar")->recurse( 
        callback => sub { 
            push @file_list, $_[0]->relative($dir)->as_foreign("Unix"); 
        } 
    );
    
    is_deeply( [sort @file_list], [sort @Foo_Bar_files],
        "... correct list of files created"
    );
    
}


#--------------------------------------------------------------------------#
# Create a distribution with extra modules
#--------------------------------------------------------------------------#

{
    my $dir = dir( my $td = tempd );
    
    $cli->runs_ok(qw(-n Foo::Bar --extra Foo::Baz -e Foo::Bar::Bam));

    my @file_list;
    $dir->subdir("Foo-Bar")->recurse( 
        callback => sub { 
            push @file_list, $_[0]->relative($dir)->as_foreign("Unix"); 
        } 
    );
    
    my @expected = (@Foo_Bar_files, qw(
        Foo-Bar/lib/Foo/Bar
        Foo-Bar/lib/Foo/Bar/Bam.pm
        Foo-Bar/t/Foo_Bar_Bam.t
        Foo-Bar/lib/Foo/Baz.pm 
        Foo-Bar/t/Foo_Baz.t 
    ));
    
    is_deeply( [sort @file_list], [sort @expected],
        "... correct list of files created"
    );
    
}

#--------------------------------------------------------------------------#
# Create a distribution and add an extra module afterwards
#--------------------------------------------------------------------------#

{
    my $dir = dir( my $td = tempd );
    
    $cli->runs_ok(qw(-n Foo::Bar));

    chdir $dir->subdir("Foo-Bar");
    is( dir()->absolute, $dir->subdir("Foo-Bar"),
        "chdir to Foo-Bar"
    );

    $cli->runs_ok(qw(-m Foo::Baz));

    chdir dir()->subdir("lib/Foo");
    is( dir()->absolute, $dir->subdir("Foo-Bar/lib/Foo"),
        "chdir to Foo-Bar/lib/Foo"
    );
    
    $cli->runs_ok(qw(--module Foo::Bar::Bam));

    my @file_list;
    $dir->subdir("Foo-Bar")->recurse( 
        callback => sub { 
            push @file_list, $_[0]->relative($dir)->as_foreign("Unix"); 
        } 
    );
    
    my @expected = (@Foo_Bar_files, qw(
        Foo-Bar/lib/Foo/Bar
        Foo-Bar/lib/Foo/Bar/Bam.pm
        Foo-Bar/t/Foo_Bar_Bam.t
        Foo-Bar/lib/Foo/Baz.pm 
        Foo-Bar/t/Foo_Baz.t 
    ));
    
    is_deeply( [sort @file_list], [sort @expected],
        "... correct list of files created"
    );
    
}




