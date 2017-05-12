use strict;
use Test::More;

use Log::Dispatch::Config;
use FileHandle;
use File::Copy;
use File::Temp qw(tempfile);
use IO::Scalar;

if( $^O eq 'MSWin32' ) {
    plan skip_all => 'These tests fail in Win32 for silly reasons';
}
else {
    plan tests => 5;
}
my($fh, $file) = tempfile;
copy("t/foo.cfg", $file);

Log::Dispatch::Config->configure_and_watch($file);

{
    my $disp = Log::Dispatch::Config->instance;
    isa_ok $disp->{outputs}->{foo}, 'Log::Dispatch::File';

    sleep 1;

    copy("t/bar.cfg", $file);

    local $^W;
    my $disp2 = Log::Dispatch::Config->instance;
    isa_ok $disp2->{outputs}->{bar}, 'Log::Dispatch::File';
    is $disp2->{outputs}->{foo}, undef;
    isnt "$disp", "$disp2", "$disp - $disp2";

    my $disp3 = Log::Dispatch::Config->instance;
    is "$disp2", "$disp3", 'same one';
}
