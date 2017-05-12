use strict;
use 5.010;

package FusqlFS::Artifact::Test;

use FusqlFS::Version;
our $VERSION = $FusqlFS::Version::VERSION;

use Test::More;
use Test::Deep;

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;
}

sub run
{
    my $self = shift;

    $self->set_up();

    plan 'no_plan';
    $self->tests();

    $self->tear_down();
}

sub set_up
{
}

sub tear_down
{
}

sub tests
{
}

1;
