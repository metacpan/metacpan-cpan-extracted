package MYDan::Util::MIO;

=head1 NAME

MYDan::Util::MIO - Interface for MYDan::Util::MIO modules

=cut
use strict;
use warnings;

use Carp;
use File::Spec;

our %RUN = ( max => 128, timeout => 300, log => \*STDERR );
our %MAX = ( buffer => 1024 * 16, period => 0.01 );

sub net
{
    my ( $class, %self ) = shift;

    for my $node ( @_ )
    {
        confess "duplicate addr: $node" if $self{$node};
        $self{$node} = $node =~ /^[^:]+:\d+$/o
            ? 1 : File::Spec->file_name_is_absolute( $node )
            ? 0 : confess "$node: invalid unix domain socket";
    }

    bless \%self, ref $class || $class;
}

sub cmd
{
    my ( $class, %self, %cmd ) = splice @_;

    while ( my ( $node, $cmd ) = each %self )
    {
        confess "command undefined for $node" unless $cmd;
        $self{$node} = $cmd{$cmd} ||= ref $cmd ? $cmd : [ $cmd ];
    }

    bless \%self, ref $class || $class;
}

1;
