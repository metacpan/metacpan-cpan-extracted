#!perl -T

use strict;
use warnings;

use Test::More tests => 10;
use FindBin ();

BEGIN {
	use_ok( 'FabForce::DBDesigner4::DBIC' );
}

#use FabForce::DBDesigner4::DBIC::FakeDBIC;

my $foo = FabForce::DBDesigner4::DBIC->new();
isa_ok( $foo, 'FabForce::DBDesigner4::DBIC', 'object is type F::D::D' );

my $bin         = $FindBin::Bin;
my $file        = $bin . '/test.xml';
my $namespace   = 'MyApp::DB';
my $output_path = $bin . '/Test';

if( -e $output_path ){
    rmtree( $output_path );
}

$foo->input_file( $file );
$foo->namespace( $namespace );
$foo->output_path( $output_path );
$foo->create_scheme;

(my $path = $namespace) =~ s!::!/!;

my $subpath = $output_path . '/' . $path;
ok( -e $subpath , 'Path created' );
ok( -e $subpath . '/DBIC_Schema.pm' );
ok( -e $subpath . '/DBIC_Schema/Result/Gefa_User.pm' );
ok( -e $subpath . '/DBIC_Schema/Result/UserRole.pm' );
ok( -e $subpath . '/DBIC_Schema/Result/Role.pm' );

my $lib_path = _untaint_path($output_path);

my $version;
eval {
    eval "use lib '$lib_path'";
    require MyApp::DB::DBIC_Schema;
    $version = MyApp::DB::DBIC_Schema->VERSION;
} or diag $@;
is $version, 0.01, 'check version';

$foo->create_schema;
eval{
    delete $INC{"MyApp/DB/DBIC_Schema.pm"};
    require MyApp::DB::DBIC_Schema;
    $version = MyApp::DB::DBIC_Schema->VERSION;
} or diag $@;
is $version, 0.02, 'check version 0.02';

$foo->version_add( 1 );
$foo->create_schema;
eval{
    delete $INC{"MyApp/DB/DBIC_Schema.pm"};
    require MyApp::DB::DBIC_Schema;
    $version = MyApp::DB::DBIC_Schema->VERSION;
} or diag $@;
is $version, 1.02, 'check version 1.02';

eval{
    rmtree( $output_path );
    $output_path = _untaint_path( $output_path );
    rmdir $output_path;
};

sub rmtree{
    my ($path) = @_;
    $path = _untaint_path( $path );
    opendir my $dir, $path or die $!;
    while( my $entry = readdir $dir ){
        next if $entry =~ /^\.?\.$/;
        my $file = File::Spec->catfile( $path, $entry );
        $file = _untaint_path( $file );
        if( -d $file ){
            rmtree( $file );
            rmdir $file;
        }
        else{
            unlink $file;
        }
    }
    closedir $dir;
}

sub _untaint_path{
    my ($path) = @_;
    ($path) = ( $path =~ /(.*)/ );
    # win32 uses ';' for a path separator, assume others use ':'
    my $sep = ($^O =~ /win32/i) ? ';' : ':';
    # -T disallows relative directories in the PATH
    $path = join $sep, grep !/^\./, split /$sep/, $path;
    return $path;
}
