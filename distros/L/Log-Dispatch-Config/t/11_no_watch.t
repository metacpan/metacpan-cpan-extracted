use strict;
use Test::More tests => 3;

use Log::Dispatch::Config;
use FileHandle;
use File::Copy;
use File::Temp qw(tempfile);
use IO::Scalar;

my($fh, $file) = tempfile;
copy("t/foo.cfg", $file);

Log::Dispatch::Config->configure($file);

{
    my $disp = Log::Dispatch::Config->instance;
    isa_ok $disp->{outputs}->{foo}, 'Log::Dispatch::File';

    sleep 1;
    copy("t/bar.cfg", $file);

    local $^W;
    my $disp2 = Log::Dispatch::Config->instance;
    isa_ok $disp2->{outputs}->{foo}, 'Log::Dispatch::File';
    is "$disp", "$disp2", "same: $disp - $disp2";
}
