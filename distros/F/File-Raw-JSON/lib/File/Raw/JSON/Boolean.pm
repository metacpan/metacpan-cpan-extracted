package File::Raw::JSON::Boolean;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

use File::Raw::JSON;

1;

__END__

=head1 NAME

File::Raw::JSON::Boolean - True/false sentinel class for File::Raw::JSON

=head1 SYNOPSIS

    use File::Raw::JSON::Boolean;

    my $t = File::Raw::JSON::Boolean::TRUE;
    my $f = File::Raw::JSON::Boolean::FALSE;

    print "yes" if $t;       # bool overload (XSUB body)
    print "$t";              # "1" - stringification overload
    print 0 + $f;            # 0   - numification overload

=head1 DESCRIPTION

Lightweight true/false sentinel class so File::Raw::JSON callers do
not need L<Types::Serialiser> or L<JSON::PP> installed just to
distinguish JSON booleans from numbers/strings.

The two singletons (returned by L</TRUE> and L</FALSE>) are
allocated once in C at module load. Callers should not mutate them;
behaviour is undefined if you do.

The four overload entry points (C<bool>, C<0+>, C<"">, C<!>) are
XSUBs registered via the XS C<OVERLOAD:> directive at module-bootstrap
time - measurably faster than the equivalent Perl-level overload
bodies, which matters when JSON booleans get exercised in tight loops.

The encoder in L<File::Raw::JSON> also recognises objects blessed
into L<JSON::PP::Boolean>, L<Types::Serialiser::Boolean>,
L<Cpanel::JSON::XS::Boolean>, L<JSON::XS::Boolean>, and the
L<boolean> module by name. Booleans round-trip cleanly whichever
class they originated from.

=head1 CONSTANTS

=head2 TRUE

Returns the singleton true sentinel.

=head2 FALSE

Returns the singleton false sentinel.

=head1 METHODS

=head2 is_true / is_false

Class predicates - return 1 if the argument is a sentinel of the
matching truth value, 0 otherwise.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2026 LNATION. Artistic License 2.0.

=cut
