#!perl -T

# http://perlbuzz.com/2017/06/11/improve-your-test-logs-with-simple-distro-diagnostics/

use warnings ;
use strict ;
use Test::More tests => 1 ;

use Expect ;
use IO::Pty 1.11 ;    # We need make_slave_controlling_terminal()
use IO::Tty ;
use POSIX ;
use Fcntl ;
use Carp ;
use IO::Handle ;
use Exporter ;
use Errno ;

my @modules = qw(
    Expect
    Carp
    Errno
    Exporter
    Fcntl
    IO::Handle
    IO::Pty
    IO::Tty
    POSIX
    Test::More
    ) ;

pass('All external modules loaded') ;


diag( "Testing Expect version $Expect::VERSION under Perl $], $^X" );
for my $module ( @modules ) {
    no strict 'refs';
    my $ver = ${$module . '::VERSION'};
    diag( "Using $module $ver" );
}

done_testing() ;
