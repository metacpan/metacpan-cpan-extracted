package JSON::JSONFold::Stats;
use strict ;

1;

__END__

=head1 CONFIGURATION

A C<JSON::JSONFold::Config> object controls how aggressively JSONFold
compacts pretty-printed JSON. All formatting decisions remain subject to
the configured C<width>.

=head2 General

=over 4

=item * width

Maximum output line width. Folding, packing and grid alignment are only
performed if the resulting line fits within this width.

=back

=head2 Packing

Packing combines consecutive scalar values onto the same physical line.

=over 4

=item * pack_array_items

Maximum number of array elements that may be packed onto one line.

=item * pack_obj_items

Maximum number of object properties that may be packed onto one line.

=item * pack_nesting

Maximum nesting depth where packing is allowed.

=back

=head2 Folding

Folding collapses a container with a single content line onto one line.

=over 4

=item * fold_array_items

Maximum number of array elements that may appear in a folded array.

=item * fold_obj_items

Maximum number of object properties that may appear in a folded object.

=item * fold_nesting

Maximum nesting depth of folded containers.

=back

=head2 Grid Alignment

Grid mode aligns multiple folded rows into columns, producing
table-like output for arrays of similar objects or arrays.

=over 4

=item * grid_array_items

Maximum number of elements allowed in each folded array row.

=item * grid_obj_items

Maximum number of properties allowed in each folded object row.

=item * grid_min_lines

Minimum number of rows required before grid alignment is attempted.

=item * grid_max_lines

Maximum number of rows considered for grid alignment.

=item * grid_array_min

Minimum number of array elements required before alignment is useful.

=item * grid_obj_min

Minimum number of object properties required before alignment is useful.

=back

=head2 Joining

Joining combines adjacent folded containers onto a single line.

=over 4

=item * join_array_items

Maximum number of folded array elements that may be joined.

=item * join_obj_items

Maximum number of folded object properties that may be joined.

=item * join_nesting

Maximum nesting depth where joined folded containers are allowed.

=back

=cut
