#
# This file is part of Jedi
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Jedi::Helpers::Scalar;

# ABSTRACT: Jedi Helpers for Scalar

use strict;
use warnings;

our $VERSION = '1.008';    # VERSION

use Import::Into;
use Module::Runtime qw/use_module/;

sub import {
    my $target = caller;
    use_module('autobox')->import::into( $target, SCALAR => __PACKAGE__ );
    return;
}

sub full_path {
    my ($path) = @_;
    $path .= '/' if substr( $path, -1 ) ne '/';
    return $path;
}

sub start_with {
    my ( $path, $start ) = @_;
    return substr( $path, 0, length($start) ) eq $start;
}

sub without_base {
    my ( $path, $base ) = @_;

    return substr( full_path($path), length( full_path($base) ) - 1 );
}

1;
__END__
=pod

=head1 NAME

Jedi::Helpers::Scalar - Jedi Helpers for Scalar

=head1 VERSION

version 1.008

=head1 METHODS

=head2 import

Equivalent in your module to :

  use autobox SCALAR => Jedi::Helpers::Scalar

=head2 full_path

Add a trailing "/" to your path :

	"/env"->full_path # /env/

=head2 start_with

Check if a path start with the value in param :

	"/env/test"->start_with("/env") # true

=head2 without_base

Remove from the path, the base pass in params :

	"/env/test"->without_base("/env") # /test/
	"/env/test"->without_base("/env") # /test/

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/perl-jedi/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

