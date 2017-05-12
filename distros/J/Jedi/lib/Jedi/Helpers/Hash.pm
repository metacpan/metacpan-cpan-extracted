#
# This file is part of Jedi
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Jedi::Helpers::Hash;

# ABSTRACT: Jedi Helpers for Hash

use strict;
use warnings;

our $VERSION = '1.008';    # VERSION

use Import::Into;
use Module::Runtime qw/use_module/;

sub import {
    my $target = caller;
    use_module('autobox')->import::into( $target, HASH => __PACKAGE__ );
    return;
}

sub to_arrayref {
    my ($headers) = @_;
    my @res;
    for my $k ( keys %$headers ) {
        for my $v ( @{ $headers->{$k} } ) {
            push @res, $k, $v;
        }
    }
    return \@res;
}

1;
__END__
=pod

=head1 NAME

Jedi::Helpers::Hash - Jedi Helpers for Hash

=head1 VERSION

version 1.008

=head1 METHODS

=head2 import

Equivalent in your module to :

  use autobox HASH => Jedi::Helpers::Hash

=head2 to_arrayref

Transform an headers form into an arrayref

Ex :

	{
		'X-Test' => [ "AAA" ],
		'Set-Cookie' => ["T1=1", "T2=2"],
	}

become

	[ 
		"X-Test", "AAA",
		"Set-Cookie", "T1=1",
		"Set-Cookie", "T2=2",
	]

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

