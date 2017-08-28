package MYDan::Node::Call;

=head1 NAME

MYDan::Node::Call - callback interface to MYDan::Node

=head1 SYNOPSIS

 use MYDan::Node::Call;

 my $cb = MYDan::Node::Call->new( '/callback/dir' );

 my $barbaz = $cb->run( foo => [ 1, qw( bar baz ) ] );
 my $notbarbaz = $cb->run( foo => [ 0, qw( bar baz ) ] );
 my $all = $cb->run( 'foo' );

=cut
use strict;
use warnings;
use Carp;

use File::Spec;
use File::Basename;

=head1 CALLBACKS

Each callback must return a CODE that returns a HASH of ARRAY when invoked.

=cut
sub new
{
    my ( $class, $path, %self ) = splice @_, 0, 2;

    confess "undefined path" unless $path;
    $path = readlink $path if -l $path;
    confess "invalid path $path: not a directory" unless -d $path;

    for my $path ( grep { -f $_ } glob File::Spec->join( $path, '*' ) )
    {
        my $error = "invalid code: $path";
        my $name = File::Basename::basename( $path );

        $self{$name} = do $path;
        confess "$error: $@" if $@;
    }
    bless \%self, ref $class || $class;
}

=head1 METHODS

=head3 select( %query )

Run callback ( index of %query ) by condition ( value of %query ).
Returns results.

=cut
sub select
{
    my ( $self, $name, $cond ) = splice @_;
    return () unless my $code = $self->{$name};

    my $result = &$code( cond => $cond );
    return () unless $result && ref $result eq 'HASH';

    my ( $match, @val ) = shift @$cond;

    unless ( @$cond )
    {
        @val = values %$result;
    }
    elsif ( ref ( my $regex = $cond->[0] ) )
    {
        my @key = $match
            ? grep { $_ =~ $regex } keys %$result
            : grep { $_ !~ $regex } keys %$result;

        @val = @$result{ @key };
    }
    else
    {
        @val = delete @$result{ @$cond };
        @val = values %$result unless $match;
    }
    @val = grep { $_ && ref $_ eq 'ARRAY' } @val;
}

=head3 run( %query )

Alias to select().

=cut
sub run
{
    my $self = shift;
    $self->select( @_ );
}

1;
