package Locale::MaybeMaketext::Tests::DummyAbstract;
use v5.20.0;
use strict;
use warnings;
use vars;
use utf8;

use autodie qw/:all/;
use feature qw/signatures/;
no warnings qw/experimental::signatures/;

sub get_handle ( $class, @languages ) {

    $class = ref($class) || $class;
    if (@languages) {
        $class .= q{::} . $languages[0];
    }
    my $path = ( $class =~ tr{:}{\/}rs ) . '.pm';
    require $path;
    return $class->new();
}

sub maketext ( $class, $string, @params ) {
    die('Needs to be overriden in individual package');    ## no critic (ErrorHandling::RequireCarping)
}

sub new ($class) {
    $class = ref($class) || $class;
    return bless {}, $class;
}

1;

=encoding utf8

=head1 NAME

Locale::MaybeMaketext::Tests::DummyAbstract - Contains various routines to aid the
dummy/mock localizations modules to work under testing.

=cut
