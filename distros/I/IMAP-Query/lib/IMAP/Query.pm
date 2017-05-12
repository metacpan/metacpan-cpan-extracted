package IMAP::Query;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Exporter qw(import);
use List::MoreUtils qw(any);

=head1 NAME

IMAP::Query - Build IMAP search queries!

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

use Readonly;
Readonly our @EXPORT_OK => qw(build_search_string);

Readonly my @KEYWORDS => qw(
    ALL
    ANSWERED
    BCC
    BEFORE
    BODY
    CC
    DELETED
    DRAFT
    FLAGGED
    FROM
    HEADER
    KEYWORD
    LARGER
    NEW
    NOT
    OLD
    ON
    OR
    RECENT
    SEEN
    SENTBEFORE
    SENTON
    SENTSINCE
    SINCE
    SMALLER
    SUBJECT
    TEXT
    TO
    UID
    UNANSWERED
    UNDELETED
    UNDRAFT
    UNFLAGGED
    UNKEYWORD
    UNSEEN
);

=head1 SYNOPSIS

This module is for those of us that can't create Polish notation queries by 
hand, L<IMAP::Query> can help you create them using a syntax inspired by other
query builder modules such as L<SQL::Abstract>.

    use IMAP::Query qw(build_search_string);

    my $query = build_search_string(
        BEFORE => strftime('%d-%b-%Y', localtime(parsedate('yesterday'))),
        NOT    => 'DELETED',
        -or    => [
            FROM => 'test@example.com',
            -and => [
                FROM    => 'other@example.com',
                SUBJECT => 'TESTING',
            ],
        ],
    );

    ... # Do something interesting with our $query

=head1 EXPORT

A list of functions that can be exported.  You can delete this section if you 
don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 build_search_string()

This method can be exported via your use statement.

    use IMAP::Query qw(build_search_string);

It takes two arguments.

    my $query = build_search_string($query, $operator);

=over

=item $query

This option is requried.  It is a HASHREF that contains all the items you want
to include in your search string.

=item $operator

This argument is optional and defaults to 'AND'.  You can use either 'AND' or 
'OR'.

=back

=cut

sub build_search_string
{
    my @options = @_;

    return _build_search_string_recurse(\@options);
}

sub _build_search_string_recurse
{
    my $opts = shift;
    my $op = shift || 'AND';

    my @options = @$opts;

    my $rv = '';

    while (@options) {
        my $item = shift @options;

        if (ref $item eq 'ARRAY') {
            my $value = _build_search_string_ARRAYREF($item, $op);
            if (length $value) {
                _maybe_add_space($rv);
                $rv .= $value;
            }
        }
        elsif (ref $item eq 'HASH') {
            _maybe_add_space($rv);
            $rv .= _build_search_string_recurse([ %$item ], $op);
        }
        elsif (defined $item && $item =~ /^-/) {
            if ($item =~ /^-and$/) {
                $op = 'AND';
            }
            elsif ($item =~ /^-or$/) {
                $op = 'OR';
            }
            else {
                die "Unknown operator $item.\n";
            }
        }
        elsif (defined $item && length $item) {
            _maybe_add_space($rv);
            use Data::Dumper;
            if (any{ uc($item) eq $_ } @KEYWORDS) {
                $rv .= uc($item);
            }
            else {
                $rv .= qq/"$item"/;
            }
        }
    }

    return ($op, $rv);
}

sub _build_search_string_ARRAYREF
{
    my $array    = shift;
    my $op       = shift || 'AND';
    my $local_op = $op;

    my $rv = '';
    return $rv unless @$array;

    my @items;
    foreach my $item (@$array) {
        my $value = '';
        ($local_op, $value) = _build_search_string_recurse([$item], $local_op);
        if (length $value) {
            push(@items, $value);
        }
    }
    return $rv unless @items;

    if ($op eq 'AND') {
        _maybe_add_space($rv);
        $rv .= '(';
        foreach my $item (@items) {
            _maybe_add_space($rv);
            $rv .= $item;
        }
        $rv .= ')';
        return $rv;
    }

    if (@items > 1) {
        do {
            my $or = '(OR '.shift(@items).' '.shift(@items).')';
            push(@items, $or);
        } while (@items >= 2);
    }
    if (@items) {
        _maybe_add_space($rv);
        $rv .= $items[0];
    }

    return $rv;
}

sub _maybe_add_space
{
    if (length $_[0] && substr($_[0], -1, 1) !~ /^[\(\s]$/) {
        $_[0] .= ' ';
    }
}

=head1 AUTHOR

Adam R. Schobelock, C<< <schobes at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-imap-query at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IMAP-Query>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IMAP::Query

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IMAP-Query>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IMAP-Query>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IMAP-Query>

=item * Search CPAN

L<http://search.cpan.org/dist/IMAP-Query/>

=item * Code Repository

L<https://github.com/schobes/IMAP-Query>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Adam R. Schobelock.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of IMAP::Query
