#!perl

use strict;
use warnings;
use Test::More tests => 7;

use Log::Tiny;

my $buf = '';
open( my $fh, '>>', \$buf ) or die $!;
my $log = Log::Tiny->new( $fh, "%c:%m%n" ) or die Log::Tiny->errstr;

# LOGWARN: logs under WARN, then warn()s.
my @warns;
{
    local $SIG{__WARN__} = sub { push @warns, $_[0] };
    $log->LOGWARN("careful");
}
is( $buf, "WARN:careful\n", "LOGWARN logs under the WARN category" );
like( $warns[0], qr/careful/, "LOGWARN also warn()s the message" );

# LOGDIE: logs under FATAL, then die()s.
$buf = '';
my $survived = eval { $log->LOGDIE("boom"); 1 };
ok( !$survived, "LOGDIE die()s" );
like( $@, qr/boom/, "LOGDIE die message carries the text" );
is( $buf, "FATAL:boom\n", "LOGDIE logs under the FATAL category" );

# LOGCROAK: Carp::croak after logging under FATAL.
$buf = '';
eval { $log->LOGCROAK("bad args") };
like( $@, qr/bad args/, "LOGCROAK croak()s the message" );
like( $buf, qr/^FATAL:bad args/, "LOGCROAK logs under the FATAL category" );
