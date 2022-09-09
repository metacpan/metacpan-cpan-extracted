package JavaScript::QuickJS::Date;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

JavaScript::QuickJS::Date

=head1 SYNOPSIS

    my $date = JavaScript::QuickJS->new()->eval("new Date()");

    binmode \*STDOUT, ':encoding(utf-8)';
    print $date->toISOString();

=head1 DESCRIPTION

This class represents a JavaScript
L<Date|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Date>
instance in Perl.

This class is not instantiated directly.

=head1 METHODS

All correspond to their JavaScript equivalents:

=over

=item * Getters:

=over

=item * C<getFullYear()>, C<getMonth()>, C<getDate()>, C<getHours()>,
C<getMinutes()>, C<getSeconds()>, C<getMilliseconds()>, C<getDay()>

=item * UTC variants of the above: C<getUTCFullYear()>, C<getUTCMonth()>,
C<getUTCDate()>, C<getUTCHours()>, C<getUTCMinutes()>, C<getUTCSeconds()>,
C<getUTCMilliseconds()>, C<getUTCDay()>

=item * Stringification: C<toString()>, C<toUTCString()>, C<toGMTString()>,
C<toISOString()>, C<toDateString()>, C<toTimeString()>, C<toLocaleString()>,
C<toLocaleDateString()>, C<toLocaleTimeString()>, C<toJSON()>

=item * C<getTime()>, C<getTimezoneOffset()>

=back

=item * Setters:

=over

=item * C<setFullYear()>, C<setMonth()>, C<setDate()>, C<setHours()>,
C<setMinutes()>, C<setSeconds()>, C<setMilliseconds()>

=item * UTC variants of the above: C<setUTCFullYear()>, C<setUTCMonth()>,
C<setUTCDate()>, C<setUTCHours()>, C<setUTCMinutes()>, C<setUTCSeconds()>,
C<setUTCMilliseconds()>

=back

=back

NB: C<getYear()> and C<setYear()> are omitted by design.

=cut

1;
