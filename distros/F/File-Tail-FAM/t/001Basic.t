######################################################################
# Test suite for File::Tail::FAM
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More tests => 10;
use File::Temp qw(tempfile);
use Log::Log4perl qw(:easy);
use Sysadm::Install qw(:all);

#Log::Log4perl->easy_init({ level => $DEBUG, layout => "%F{1}-%L: %m%n"});

BEGIN { use_ok('File::Tail::FAM') };

my($fh, $filename) = tempfile( CLEANUP => 1 );

blurt("woot!", $filename);

my $tail = File::Tail::FAM->new(
    file => $filename);

blurt("woot2!", $filename, 1);
is($tail->read(), "woot2!", "first append");

blurt("woot3!", $filename, 1);
is($tail->read(), "woot3!", "second append");

blurt("woot4!", $filename);
is($tail->read(), '', "truncate");

blurt("woot5!", $filename, 1);
is($tail->read(), "woot5!", "third append");

is($tail->read_nonblock(), undef, "non_block on no change");
is($tail->read_nonblock(), undef, "non_block on no change");

blurt("woot6!", $filename, 1);
$tail->poll_pending();
is($tail->read_nonblock(), "woot6!", "nonblock after actual change");

unlink $filename;
blurt("woot8!", $filename, 1);
is($tail->read(), 'woot8!', "read after delete/recreate");
blurt("woot9!", $filename, 1);
is($tail->read(), "woot9!", "read after delete/recreate");
