package Cpanel::CPAN::Locale::Maketext::Utils;
use parent q/Locale::MaybeMaketext::Tests::DummyAbstract/;
use v5.20.0;
use strict;
use warnings;
use vars;
use utf8;

use autodie qw/:all/;
use feature qw/signatures/;
no warnings qw/experimental::signatures/;

sub maketext ( $class, $string, @params ) {
    return 'Generated through ' . __PACKAGE__;
}

1;

__END__

=encoding utf8

=head1 NAME

Cpanel::CPAN::Locale::Maketext::Utils - A dummy file for testing purposes.

=cut
