use strict;
use warnings;
use Test::More tests => 3;
use File::Spec;
use IPC::Run qw( run timeout );

my @cmd = ( $^X, '-I' . File::Spec->catdir( 't', 'lib' ) );
my @nop = ( '-e', '0' );

like tryit( @cmd, '-MSome::Module', @nop ), qr{^\s*$}, "no error";

like tryit( @cmd, '-Ilib', '-MDevel::Unplug=Some::Module', '-MSome::Module', @nop ),
  qr{Can't\s+locate\s+Some/Module.pm}, "error message";

like tryit( @cmd, '-Ilib', '-MDevel::Unplug=Some::Module', '-MSome::Other::Module', @nop ),
  qr{^\s*$}, "no crosstalk";

sub tryit {
    my @cmd = @_;
    run \@cmd, \my $in, \my $out, \my $err, timeout( 10 );
    return $err;
}
