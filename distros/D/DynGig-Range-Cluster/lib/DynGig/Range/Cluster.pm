=head1 NAME

DynGig::Range::Cluster - Extends DynGig::Range::String.

=cut
package DynGig::Range::Cluster;

=head1 VERSION

Version 0.01

=cut
our $VERSION = '0.03';

use base DynGig::Range::String;

use warnings;
use strict;
use Carp;

use DynGig::Range::Cluster::Client;

my %_ENV;

=head1 DESCRIPTION

=head2 setenv( timeout => seconds, server => server )

Sets DynGig::Range::Cluster::Client parameter. Returns object/class.

=cut
sub setenv
{
    my $this = shift @_;

    %_ENV = ( cluster => DynGig::Range::Cluster::Client->new( @_ ) );
    return $this;
}

=head1 SEE ALSO

See DynGig::Range::String for additional methods.

=head1 GRAMMAR

Tokenizer and parser implement the base class BNF with the
following differences.

=cut
sub _parse
{
    my ( $this, $input ) = @_;
    my $token = $this->_tokenize( $input, qr/[{}:=%()]/, qr/[-&]/ );

    $this += $this->_expression( $token, +{ '}' => 0, ')' => 0 } );
}

sub _valid
{
    my ( $this, $token, $lex ) = @_;

    return 0 unless @$token;
    return ref $token->[0] || $token->[0] eq '{' unless $lex;
    return ref $token->[0] || $token->[0] !~ /[-+&}:=%()]/ if $lex == 2;
    return $token->[0] =~ /[-+&]/;
}

=head2 <range> ::= <literal> | <cluster>

=head2 <cluster> ::= <literal> '(' <expression> ':' <expression> ')'

          | <literal> '(' <expression> '%' <expression> ')'
          | <literal> '(' <expression> '=' <expression> ')'

=head2 SYMBOLS

I<cluster operator>:

':' : given cluster name ( left operand ), get attribute keys by value.

'%' : given cluster name ( left operand ), get attribute values by key.

'=' : get cluster names with attribute key = value.

=cut
sub _range
{
    my ( $this, $token, $scope ) = @_;

    croak 'private method' unless $this->isa( ( caller )[0] );

    my $range = bless shift @$token, ref $this;

    return $range unless @$token && $token->[0] eq '(';

    my $type = ')';
    my $count = $scope->{$type};
    
    $this->_balance( $token, $scope, $type );

    my $key = $this->_expression( $token, $scope );
    my $op = shift @$token;

    unless ( @$token && $op && $op =~ /[:=%]/ )
    {
        splice @$token;
        return $this->new();
    }

    my $value = $this->_expression( $token, $scope );

    $this->_balance( $token, $scope, $type, $count )
        ? $this->_cluster( $op, $range, $key, $value ) : $range->clear();
}

sub _cluster
{
    my ( $this, $op ) = splice @_, 0, 2;
    my $range = $this->new();

    map { return $range if $_->empty() } @_;

    my $cluster = $_ENV{cluster} || croak "'cluster' not set";
    my ( $table, $key, $value ) = map { scalar $_->list() } @_;

    for my $table ( @$table )
    {
        for my $key ( @$key )
        {
            if ( $op eq ':' )
            {
                $range += $this->new
                (
                    map { $cluster->$table( cluster => $key, value => $_ ) }
                        @$value
                );
            }
            elsif ( $op eq '=' )
            {
                $range += $this->new
                ( 
                    map { $cluster->$table( key => $key, value => $_ ) }
                        @$value
                );
            }
            else
            {
                $range += $this->new
                (
                    map { $cluster->$table( cluster => $key, key => $_ ) }
                        @$value
                );
            }
        }
    }

    return $range;
}

=head1 MODULES

=head2 DynGig::Range::Cluster::Client 

Cluster client

=head2 DynGig::Range::Cluster::Cache 

Caching server. Implements DynGig::Range::Cluster::Interface.

=head2 DynGig::Range::Cluster::Server 

Cluster server. Implements DynGig::Range::Cluster::Interface.

=head2 DynGig::Range::Cluster::Interface

Extends DynGig::Util::TCPServer.

=head2 DynGig::Range::Cluster::Config 

Cluster configuration methods

=head2 DynGig::Range::Cluster::EZDB

Extends DynGig::Util::EZDB

=head1 AUTHOR

Kan Liu

=head1 COPYRIGHT and LICENSE

Copyright (c) 2010. Kan Liu

This program is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

__END__
