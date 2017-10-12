## no critic (RequirePODUseEncodingUTF8)
package List::Breakdown;

# Force me to write this properly
use strict;
use warnings;
use utf8;

# Target reasonably old Perls
use 5.006;

# Import required modules
use Carp;

# Handle exporting in a way Perl v5.6 should tolerate
use base qw(Exporter);    ## no critic (ProhibitUseBase)
our @EXPORT_OK = 'breakdown';

# Specify package version
our $VERSION = '0.20';

# Dispatch table of functions to handle different ref types for the spec
# hashref's values
my %types = (

    # If it's a hash, apply breakdown() again as if it were another root-level
    # spec
    HASH => sub {
        my $spec = shift;
        return { breakdown( $spec, @_ ) };
    },

    # If it's an array, we're doing numeric bounds checking [a,b)
    ARRAY => sub {
        my $bounds = shift;
        @{$bounds} == 2
          or croak 'ARRAY ref for bounds needs two items';
        return [
            grep {
                      ( not defined $bounds->[0] or $_ >= $bounds->[0] )
                  and ( not defined $bounds->[1] or $_ < $bounds->[1] )
            } @_,
        ];
    },

    # If it's a subroutine, return a arrayref of all elements for which it
    # returns true
    CODE => sub {
        my $sub = shift;
        return [ grep { $sub->() } @_ ];
    },

    # If it's a regular expression, return an arrayref of all elements it
    # matches
    Regexp => sub {
        my $re = shift;
        return [ grep { $_ =~ $re } @_ ];
    },
);

# Given a spec and a list of items, filter them into a hash of the same
# structure
sub breakdown {
    my ( $spec, @items ) = @_;

    # Check the spec is a hashref
    ref $spec eq 'HASH'
      or croak 'HASH ref expected for first argument';

    # Start building a results hash
    my %results;
    for my $key ( keys %{$spec} ) {

        # Check that the value for this key is a reference
        my $ref = ref $spec->{$key}
          or croak "Ref expected for '$key'";

        # Check it's a reference we understand
        exists $types{$ref}
          or croak "Unhandled ref type $ref for '$key'";

        # Apply the appropriate subroutine for this reference type to the list
        # of items
        $results{$key} = $types{$ref}->( $spec->{$key}, @items );
    }

    # Return the constructed result set
    return %results;
}

1;

__END__

=pod

=for stopwords
sublists Unhandled tradename licensable MERCHANTABILITY hashrefs CPAN AnnoCPAN
syntaxes perldoc

=head1 NAME

List::Breakdown - Build sublist structures matching conditions

=head1 VERSION

Version 0.20

=head1 SYNOPSIS

    use List::Breakdown 'breakdown';
    ...
    my @words = qw(foo bar baz quux wibble florb);
    my $cats  = {
        all    => sub { 1 },
        has_b  => sub { m/ b /msx },
        has_w  => sub { m/ w /msx },
        length => {
            3    => sub { length == 3 },
            4    => sub { length == 4 },
            long => sub { length > 4 },
        },
        has_ba => qr/ba/msx,
    };
    my %filtered = breakdown $cats, @words;

This puts the following structure in C<%filtered>:

    (
        all    => ['foo', 'bar', 'baz', 'quux', 'wibble', 'florb'],
        has_b  => ['bar', 'baz', 'wibble', 'florb'],
        has_w  => ['wibble'],
        length => {
            3    => ['foo', 'bar', 'baz'],
            4    => ['quux'],
            long => ['wibble', 'florb'],
        },
        has_ba => ['bar', 'baz'],
    )

=head1 DESCRIPTION

This module assists you in making a I<breakdown> of a list, copying and
filtering its items into a structured bucket layout according to your
specifications. Think of it as a syntax for L<C<grep>|perlfunc/"grep BLOCK
LIST"> that returns named and structured results from one list.

It differs from the excellent L<List::Categorize|List::Categorize> in the use
of references to define each category, and in not requiring only one final
category for any given item; an item can end up in the result set for more than
one filter.

If you want to divide or I<partition> your list so that each item can only
appear in one category, you may want either
L<List::MoreUtils|List::MoreUtils/"Partitioning"> or possibly
L<Set::Partition|Set::Partition> instead.

=head1 SUBROUTINES/METHODS

=head2 C<breakdown(\%spec, @items)>

This is the only exportable subroutine. Given a hash reference structure and a
list of items, it applies each of the referenced values as tests, returning a
new hash in the same structure with the references replaced with the matching
items, in the same way as L<C<grep>|perlfunc/"grep BLOCK LIST">.

There are two shortcut syntaxes for a value in the C<\%spec> structure:

=over 4

=item * C<ARRAY>

If the referenced array has exactly two items, it will be interpreted as
defining numeric bounds C<[lower,upper)> for its values. C<undef> can be used
to denote negative or positive infinity. Any other number of items is a fatal
error.

=item * C<Regexp>

This will be interpreted as a pattern for the list items to match.

=back

Additionally, if the value is a C<HASH> reference, it can be used to make a
sub-part of the structure, as demonstrated in the C<length> key of the example
C<\%spec> given in L<SYNOPSIS|/SYNOPSIS>.

=head1 EXAMPLES

=head2 Collecting troublesome records

Suppose you have a list of strings from a very legacy system that you need to
regularly check for problematic characters, alerting you to problems with an
imperfect Perl parser:

    my @records = (
        "NEW CUSTOMER John O''Connor\r 2017-01-01",
        "RETURNING CUSTOMER\tXah Zhang 2016-01-01",
        "CHECK ACCOUNT Pierre d'Alun 2016-12-01",
        "RETURNING CUSTOMER Aaron Carter 2016-05-01",
    );

You could have a bucket structure like this, using the B<pattern syntax>, which
catches certain error types you've seen before for review:

    my %buckets = (
        bad_whitespace     => qr/ [\r\t] /msx,
        apostrophes        => qr/ ' /msx,
        double_apostrophes => qr/ '' /msx,
        not_ascii          => qr/ [^[:ascii:]] /msx,
    };

Applying the bucket structure like so:

    my %results = breakdown \%buckets, @records;

The result set would look like this:

    my %expected = (
        bad_whitespace => [
            "NEW CUSTOMER John O''Connor\r 2017-01-01",
            "RETURNING CUSTOMER\tXah Lee 2016-01-01",
        ],
        apostrophes => [
            "NEW CUSTOMER John O''Connor\r 2017-01-01",
            'CHECK ACCOUNT Pierre d\'Alun 2016-12-01',
        ],
        double_apostrophes => [
            "NEW CUSTOMER John O''Connor\r 2017-01-01",
        ],
        not_ascii => [
        ],
    );

Notice that some of the lines appear in more than one list, and that the
C<not_ascii> bucket is empty, because none of the items matched it.

=head2 Monitoring system check results

Suppose you ran a list of checks with your monitoring system, and now you have
a list of C<HASH> references with keys describing each check and its outcome:

    my @checks = (
        {
            hostname => 'webserver1',
            status   => 'OK',
        },
        {
            hostname => 'webserver2',
            status   => 'CRITICAL',
        },
        {
            hostname => 'webserver3',
            status   => 'WARNING',
        },
        {
            hostname => 'webserver4',
            status   => 'OK',
        }
    );

You would like to break the list down by status. You would lay out your buckets
like so, using the B<subroutine syntax>:

    my %buckets = (
        ok       => sub { $_->{status} eq 'OK' },
        problem  => {
            warning  => sub { $_->{status} eq 'WARNING' },
            critical => sub { $_->{status} eq 'CRITICAL' },
            unknown  => sub { $_->{status} eq 'UNKNOWN' },
        },
    );

And apply them like so:

    my %results = breakdown \%buckets, @checks;

For our sample data above, this would yield the following structure in
C<%results>:

    (
        ok => [
            {
                hostname => 'webserver1',
                status   => 'OK',
            },
            {
                hostname => 'webserver4',
                status   => 'OK',
            },
        ],
        problem => {
            warning => [
                {
                    hostname => 'webserver3',
                    status   => 'WARNING',
                },
            ],
            critical => [
                {
                    hostname => 'webserver2',
                    status   => 'CRITICAL',
                },
            ],
            unknown => [],
        }
    )

Note the extra level of C<HASH> references beneath the C<problem> key.

=head2 Grouping numbers by size

Suppose you have a list of numbers from your volcanic activity reporting
system, some of which might be merely worrisome, and some others an emergency,
and they need to be filtered to know where to send them:

    my @numbers = ( 1, 32, 3718.4, 0x56, 0777, 3.14, -5, 1.2e5 );

You could filter them into buckets like this, using the B<interval syntax>: an
C<ARRAY> reference with exactly two elements: lower bound (inclusive) first,
upper bound (exclusive) second:

    my $filters = {
        negative => [ undef, 0 ],
        positive => {
            small  => [ 0,   10 ],
            medium => [ 10,  100 ],
            large  => [ 100, undef ],
        },
    };

Applying the bucket structure like so:

    my %filtered = breakdown $filters, @numbers;

The result set would look like this:

    my %expected = (
        negative => [ -5 ],
        positive => {
            small  => [ 1, 3.14 ],
            medium => [ 32, 86 ],
            large  => [ 3_718.4, 511, 120_000 ],
        },
    );

Notice that you can express infinity or negative infinity as C<undef>. Note
also this is a numeric comparison only.

=head1 AUTHOR

Tom Ryder C<< <tom@sanctum.geek.nz> >>

=head1 DIAGNOSTICS

=over 4

=item C<HASH reference expected for first argument>

The first argument that C<breakdown()> saw wasn't the hash reference it expects.
That's the only format a spec is allowed to have.

=item C<Reference expected for '%s'>

The value for the named key in the spec was not a reference, and one was
expected.

=item C<Unhandled ref type %s for '%s'>

The value for the named key in the spec is of a type that makes no sense to
this module. Legal reference types are C<ARRAY>, C<CODE>, C<HASH>, and
C<Regexp>.

=back

=head1 DEPENDENCIES

=over 4

=item *

Perl 5.6.0 or newer

=item *

L<base|base>

=item *

L<Carp|Carp>

=item *

L<Exporter|Exporter>

=back

=head1 CONFIGURATION AND ENVIRONMENT

None required.

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

Definitely. This is a very early release. Please report any bugs or feature
requests to C<tom@sanctum.geek.nz>.

=head1 SUPPORT

You can find documentation for this module with the B<perldoc> command.

    perldoc List::Breakdown

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=List-Breakdown>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/List-Breakdown>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/List-Breakdown>

=item * Search CPAN

L<http://search.cpan.org/dist/List-Breakdown/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017 Tom Ryder

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License. By using, modifying or distributing the
Package, you accept this license. Do not use, modify, or distribute the
Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made by
someone other than you, you are nevertheless required to ensure that your
Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent
license to make, have made, use, offer to sell, sell, import and otherwise
transfer the Package with respect to any patent claims licensable by the
Copyright Holder that are necessarily infringed by the Package. If you
institute patent litigation (including a cross-claim or counterclaim) against
any party alleging that the Package constitutes direct or contributory patent
infringement, then this Artistic License to you shall terminate on the date
that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW.
UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY
OUT OF THE USE OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
DAMAGE.

=cut
