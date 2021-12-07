use strict;
use warnings;
use lib '../lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib';
use Dyn qw[call load :dl];
use Test::More;
use Config;
$|++;
#
my $libfile
    = $^O eq 'MSWin32' ? 'msvcrt.dll' :
    $^O eq 'darwin'    ? '/usr/lib/libm.dylib' :
    $^O eq 'bsd'       ? '/usr/lib/libm.so' :
    $Config{archname} =~ /64/ ?
    -e '/lib64/libm.so.6' ?
    '/lib64/libm.so.6' :
        '/lib/x86_64-linux-gnu/libm.so.6' :
    '/lib/libm.so.6';

#  "/usr/lib/system/libsystem_c.dylib", /* macos - note: not on fs w/ macos >= 11.0.1 */
#    "/usr/lib/libc.dylib",
#    "/boot/system/lib/libroot.so",       /* Haiku */
#    "\\ReactOS\\system32\\msvcrt.dll",   /* ReactOS */
#    "C:\\ReactOS\\system32\\msvcrt.dll",
#    "\\Windows\\system32\\msvcrt.dll",   /* Windows */
#    "C:\\Windows\\system32\\msvcrt.dll"
SKIP: {
    skip 'Cannot find math lib: ' . $libfile, 8 if $^O ne 'MSWin32' && !-f $libfile;
    diag 'Loading ' . $libfile . ' ...';
    my %loaders = (
        sin_default  => Dyn::load( $libfile, 'sin', '(d)d' ),
        sin_vararg   => Dyn::load( $libfile, 'sin', '(_:d)d' ),
        sin_ellipsis => Dyn::load( $libfile, 'sin', '(_.d)d' ),
        sin_cdecl    => Dyn::load( $libfile, 'sin', '(_cd)d' ),
        sin_stdcall  => Dyn::load( $libfile, 'sin', '(_sd)d' ),
        sin_fastcall => Dyn::load( $libfile, 'sin', '(_fd)d' ),
        sin_thiscall => Dyn::load( $libfile, 'sin', '(_#d)d' )
    );
    my $correct = -0.988031624092862;    # The real value of sin(30);
    is sin(30), $correct, 'sin(30) [perl]';
    for my $fptr ( keys %loaders ) {
        if ( !$loaders{$fptr} ) {
            diag 'Failed to attach ' . $fptr;
        }
        else {
            diag 'Attached ' . $fptr;
            is Dyn::call( $loaders{$fptr}, 30 ), $correct, sprintf 'Dyn::call( ... ) [%s]', $fptr;
        }
    }
}
done_testing;
