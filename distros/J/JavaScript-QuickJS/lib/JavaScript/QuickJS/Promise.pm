package JavaScript::QuickJS::Promise;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

JavaScript::QuickJS::Promise - JavaScript `Promise` in Perl

=head1 SYNOPSIS

    my $js = JavaScript::QuickJS->new();

    $js->eval("Promise.resolve(123)")->then( sub { CORE::say "resolved: @_" } );

    CORE::say "before await";

    $js->await();

    CORE::say "after await";

=head1 DESCRIPTION

This class represents a JavaScript
L<Promise|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise>
instance in Perl.

This class is not instantiated directly.

=head1 METHODS

This exposes C<then()>, C<catch()>, and C<finally()> methods that wrap the
JavaScript methods of the same names.

=cut

1;
