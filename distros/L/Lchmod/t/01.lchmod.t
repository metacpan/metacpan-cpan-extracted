use strict;
use warnings;

use Lchmod;
use Test::More;
use File::Temp;
use File::Slurp;

diag("Testing Lchmod $Lchmod::VERSION");

plan skip_all => 'Skipping lchmod() tests since the system does not support lchmod.' unless Lchmod::LCHMOD_AVAILABLE();

my $dir = File::Temp->newdir();
_setup($dir);

is( lchmod( 0755, "$dir/noexist" ), 0, 'non existent file counts as zero' );

ok( lchmod( 0664, "$dir/sym_ok" ), 'symlink ok rv is true' ) || do {
    diag "Debug info for test failures because LCHMOD_AVAILABLE() is true (i.e. symbol found and created) but lchmod() has no effect on symlinks";
    if ( defined &Lchmod::_sys_lchmod ) {
        diag "is defined";
        diag "real call RV: " . Lchmod::_sys_lchmod( "$dir/sym_ok", 0664 );
        diag "zero call RV: " . Lchmod::_sys_lchmod( 0,             0 );
    }
    else {
        diag "is not defined";
    }
    require Config;
    diag( explain( \%Config::Config ) );
};
is( _mode_str("$dir/sym_ok"), "0664", 'symlink ok mode is changed' );
is( _mode_str("$dir/file"),   "0644", 'symlink ok target mode is not changed' );
ok( lchmod( 0664, "$dir/sym_ok" ), 'symlink ok rv is true when already set' );
is( _mode_str("$dir/sym_ok"), "0664", 'symlink ok mode remains when already set' );

ok( lchmod( 0664, "$dir/sym_broken" ), 'symlink broken rv is true' );
is( _mode_str("$dir/sym_broken"), "0664", 'symlink broken mode is changed' );
ok( lchmod( 0664, "$dir/sym_broken" ), 'symlink broken rv is true when already set' );
is( _mode_str("$dir/sym_broken"), "0664", 'symlink broken mode remains when already set' );

ok( lchmod( 0755, "$dir/file" ), 'file rv is true' );
is( _mode_str("$dir/file"), "0755", 'file mode is changed' );
ok( lchmod( 0755, "$dir/file" ), 'file rv is true when already set' );
is( _mode_str("$dir/file"), "0755", 'file mode remains when already set' );

ok( lchmod( 0755, "$dir/dir" ), 'dir rv is true' );
is( _mode_str("$dir/dir"), "0755", 'dir mode is changed' );
ok( lchmod( 0755, "$dir/dir" ), 'dir rv is true when already set' );
is( _mode_str("$dir/dir"), "0755", 'dir mode remains when already set' );

# Takes stat (e.g. 33261), oct(NNN), and oct("0NNN") in addition to 0NNN
my $raw_stat_value = ( stat "$dir/file" )[2];    # corresponds to 0755

ok( lchmod( oct(644), "$dir/file" ), 'lchmod takes oct(NNN) value - rv' );
is( _mode_str("$dir/file"), "0644", 'lchmod takes oct(NNN) value mode is changed' );

ok( lchmod( $raw_stat_value, "$dir/file" ), 'lchmod takes raw stat value - rv' );
is( _mode_str("$dir/file"), "0755", 'lchmod takes raw stat value mode is changed' );

ok( lchmod( oct("0750"), "$dir/file" ), 'lchmod takes oct("0NNN") value - rv' );
is( _mode_str("$dir/file"), "0750", 'lchmod takes oct("0NNN") value mode is changed' );

# multiple paths behavior
local $!;
is( lchmod( 0644, "$dir/dir", "$dir/file", "$dir/sym_ok", "$dir/sym_broken", "$dir/noexist" ), 4, 'returns count of successful ops' );
ok( defined $!, 'single failure sets $!' );

done_testing;

sub _mode_str {
    return sprintf( "%04o", ( lstat shift )[2] & 07777 );
}

sub _setup {
    my ($dir) = @_;

    write_file( "$dir/file", 'howdy' );
    chmod( 0644, "$dir/file" ) || die "Could not chmod test file: $!";

    mkdir "$dir/dir";
    chmod( 0644, "$dir/dir" ) || die "Could not chmod test dir : $!";

    symlink( "$dir/file", "$dir/sym_ok" );

    symlink( "$dir/noexist", "$dir/sym_broken" );
}
