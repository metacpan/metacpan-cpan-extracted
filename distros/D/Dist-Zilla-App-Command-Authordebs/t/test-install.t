# -*- cperl -*-
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(utf8)';

use Probe::Perl;

use Test::Command 0.08;
use Test::More;
use Path::Tiny;

if ( not path('/etc/debian_version')->exists ) {
    plan skip_all => "Cannot test on non Debian system";
}

if ( not path('/usr/bin/apt-file')->exists ) {
    plan skip_all => "Cannot test without apt-file";
}

## testing exit status

my $path = Probe::Perl->find_perl_interpreter();

my $perl_cmd = $path . ' -Ilib ' . join( ' ', map { "-I$_" } Probe::Perl->perl_inc() );

my $list_ok = Test::Command->new(
    cmd => "$perl_cmd -S dzil authordebs"
);
exit_is_num( $list_ok, 0, 'dzil authordebs command went well' );

done_testing;
