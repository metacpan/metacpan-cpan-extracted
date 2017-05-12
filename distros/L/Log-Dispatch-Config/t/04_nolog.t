use strict;
use Test::More tests => 1;

use Log::Dispatch::Config;
use FileHandle;
use File::Temp qw(tempfile);
use IO::Scalar;

sub writefile {
    my $fh = FileHandle->new(">" . shift) or die $!;
    $fh->print(@_);
}

my($fh, $file) = tempfile;
writefile($file, <<'CFG');
CFG
    ;

Log::Dispatch::Config->configure($file);

{
    my $disp = Log::Dispatch::Config->instance;
    $disp->debug('null');
}

ok 1, 'can call with nothing';


