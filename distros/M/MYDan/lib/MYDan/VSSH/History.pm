package MYDan::VSSH::History;
use strict;
use warnings;
use Carp;

our @HISTORY;

sub new
{
    my $this = shift;
    bless +{}, ref $this || $this;
}

sub push
{
    my ( $this, @name ) = @_;
    push @HISTORY, @name;
}

sub list
{
    @HISTORY;;
}

1;
