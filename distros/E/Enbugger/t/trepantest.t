#!perl

use strict;
use warnings;
use English;
use Test::More;

=head1 DESCRIPTION

This is a basic test of Devel::Trepan

=cut

use File::Basename qw( fileparse basename);
use File::Spec::Functions qw( catfile );
use File::Path qw( rmtree );

# Check for the existence of Devel::Trepan before continuing
#
system $EXECUTABLE_NAME, '-e', 'exit ! eval { require Devel::Trepan }';
if ($CHILD_ERROR) {
    plan( skip_all => "Skipped because Devel::Trepan isn't installed" );
    exit;
}


# Locate my test script.
#
my ( $nm, $dir, $suffix ) = fileparse( $0, '.t' );
my $script = catfile( $dir, "$nm.pl" );

my $pid = fork();
if ($pid == 0) {
    exec $EXECUTABLE_NAME, $script;
} else {
    plan();
    waitpid($pid, 0);
    is($?>>8, 10);
    done_testing();
}

=begin emacs

## Local Variables:
## mode: cperl
## mode: auto-fill
## cperl-indent-level: 4
## End:

=end emacs
