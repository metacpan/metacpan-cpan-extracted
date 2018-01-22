package Mail::BIMI::Result;

use strict;
use warnings;

our $VERSION = '1.20180122'; # VERSION

use Carp;
use English qw( -no_match_vars );

sub new {
    my ( $Class ) = @_;
    my $Self = {
        'domain' => '',
        'selector' => '',
        'result' => '',
        'result_comment' => '',
    };

    bless $Self, ref($Class) || $Class;
    return $Self;
}

sub set_domain {
    my ( $Self, $Domain ) = @_;
    $Self->{ 'domain' } = $Domain;
    return;
}

sub set_selector {
    my ( $Self, $Selector ) = @_;
    $Self->{ 'selector' } = $Selector;
    return;
}

sub set_result {
    my ( $Self, $Result, $Comment ) = @_;
    $Self->{ 'result' } = $Result;
    $Self->{ 'result_comment' } = $Comment;
    return;
}

sub result {
    my ( $Self ) = @_;
    return $Self->{ 'result' };
}

sub get_authentication_results {
    my ( $Self ) = @_;
    my @Result;
    push @Result, 'bimi=' . $Self->{ 'result' };
    push @Result, '(' . $Self->{ 'result_comment' } . ')' if $Self->{ 'result_comment' };
    push @Result, 'header.d=' . $Self->{ 'domain' } if $Self->{ 'result' } eq 'pass';
    push @Result, 'selector=' . $Self->{ 'selector' } if $Self->{ 'result' } eq 'pass';
    return join( ' ', @Result );
}

sub get_bimi_location {
}

1;

