# ========================================================================== #
# lib/JPList/Controls/Sort.pm  - JPList Sort controls
# Copyright (C) 2017 Exceleron Software, LLC
# ========================================================================== #

package JPList::Controls::Sort;

use Moose::Role;

# ========================================================================== #

=head1 NAME

JPList::Controls::Sort - JPList Sort controls

=head1 SYNOPSIS

  with 'JPList::Controls::Sort'

=head1 DESCRIPTION

The Sort module allows you get the values sort controls

=head2 METHODS

=over 4

=cut

# ========================================================================== #

=item C<sortdropdown>

Params : sort_vals

	{
		'type' => 'sort-drop-down',
        'inStorage' => $VAR1->[0]{'inDeepLinking'},
        'inAnimation' => $VAR1->[0]{'inDeepLinking'},
        'name' => 'sort',
        'data' => {
                    'order' => '',
                    'type' => '',
                    'dateTimeFormat' => '',
                    'path' => 'default',
                    'ignore' => ''
                  },
        'initialIndex' => 1,
        'inDeepLinking' => $VAR1->[0]{'inDeepLinking'},
        'action' => 'sort',
        'isAnimateToTop' => $VAR1->[0]{'isAnimateToTop'}
      }

Returns: Returns the column and value for order

Desc   : Returns the column and value for order

=cut

sub sortdropdown
{
    my ($self, $sort_vals) = @_;

    my $data = $sort_vals->{'data'};
    my $result;
    my $order = "asc";

    if ($data && exists($data->{'path'}) && $data->{'path'}) {

        $result->{'column'} = $data->{'path'};
        $result->{'column'} =~ s/\.//;

        if (exists($data->{'order'})) {
            $order = lc($data->{'order'});
        }

        $result->{'order'} = ($order eq "desc") ? "desc" : "asc";
    }

    return $result;
}

# ========================================================================== #

=item C<sortselect>

Params : sort_vals

	{
        'type' => 'sort-select',
        'action' => 'sort',
        'inStorage' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
        'data' => {
                    'order' => '',
                    'type' => '',
                    'dateTimeFormat' => '{month}/{day}/{year}',
                    'path' => 'default',
                    'ignore' => ''
                  },
        'isAnimateToTop' => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ),
        'inDeepLinking' => $VAR1->[0]{'inStorage'},
        'name' => 'sort',
        'inAnimation' => $VAR1->[0]{'inStorage'}
    }

Returns: Returns the column and value for order

Desc   : Returns the column and value for order

=cut

sub sortselect
{
    shift->sortdropdown(@_);
}

1;

__END__

=back
   
=head1 AUTHORS

Sheeju Alex, <sheeju@exceleron.com>

=head1 BUGS

https://github.com/sheeju/JPList/issues

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc JPList


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=JPList>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/JPList>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/JPList>

=item * Search CPAN

L<http://search.cpan.org/dist/JPList/>

=back

=head1 ACKNOWLEDGEMENTS

Development time supported by Exceleron L<www.exceleron.com|http://www.exceleron.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017 Exceleron Software, LLC

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

# vim: ts=4
# vim600: fdm=marker fdl=0 fdc=3
