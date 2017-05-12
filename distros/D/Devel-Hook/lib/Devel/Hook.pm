
package Devel::Hook;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.006';

require XSLoader;
XSLoader::load( 'Devel::Hook', $Devel::Hook::VERSION );


sub unshift_BEGIN_hook {
    shift;
    _check( 'BEGIN', @_ );
    unshift @{ _get_begin_array() }, @_;
}

sub push_BEGIN_hook {
    shift;
    _check( 'BEGIN', @_ );
    push @{ _get_begin_array() }, @_;
}


sub unshift_UNITCHECK_hook {
    shift;
    _check( 'UNITCHECK', @_ );
    unshift @{ _get_unitcheck_array() }, @_;
}

sub push_UNITCHECK_hook {
    shift;
    _check( 'UNITCHECK', @_ );
    push @{ _get_unitcheck_array() }, @_;
}


sub unshift_CHECK_hook {
    shift;
    _check( 'CHECK', @_ );
    unshift @{ _get_check_array() }, @_;
}

sub push_CHECK_hook {
    shift;
    _check( 'CHECK', @_ );
    push @{ _get_check_array() }, @_;
}


sub unshift_INIT_hook {
    shift;
    _check( 'INIT', @_ );
    unshift @{ _get_init_array() }, @_;
}

sub push_INIT_hook {
    shift;
    _check( 'INIT', @_ );
    push @{ _get_init_array() }, @_;
}


sub unshift_END_hook {
    shift;
    _check( 'END', @_ );
    unshift @{ _get_end_array() }, @_;
}

sub push_END_hook {
    shift;
    _check( 'END', @_ );
    push @{ _get_end_array() }, @_;
}


my $has_support_for = _get_supported_types();
sub _has_support_for {
    shift;
    my $BLOCK = shift;
    return $has_support_for->{$BLOCK};
}

sub _check {
    my $BLOCK = shift;
    if ( grep { !UNIVERSAL::isa($_, "CODE") } @_ ) {
        die "$BLOCK blocks must be CODE references";
    }
}


1;
