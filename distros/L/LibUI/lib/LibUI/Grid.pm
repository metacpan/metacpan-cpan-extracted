package LibUI::Grid 0.02 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use parent 'LibUI::Control';
    use LibUI::Align;
    use LibUI::At;
    #
    affix(
        LibUI::lib(),
        [ 'uiGridAppend', 'append' ],
        [   InstanceOf ['LibUI::Grid'],
            InstanceOf ['LibUI::Control'],
            Int, Int, Int, Int, Int, LibUI::Align, Int, LibUI::Align
        ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiGridInsertAt', 'insertAt' ],
        [   InstanceOf ['LibUI::Grid'],
            InstanceOf ['LibUI::Control'],
            InstanceOf ['LibUI::Control'],
            LibUI::At, Int, Int, Int, LibUI::Align, Int, LibUI::Align
        ] => Void
    );
    affix( LibUI::lib(), [ 'uiGridPadded', 'padded' ], [ InstanceOf ['LibUI::Grid'] ] => Int );
    affix(
        LibUI::lib(),
        [ 'uiGridSetPadded',          'setPadded' ],
        [ InstanceOf ['LibUI::Grid'], Int ] => Void
    );
    affix( LibUI::lib(), [ 'uiNewGrid', 'new' ], [Void] => InstanceOf ['LibUI::Grid'] );
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::Grid - Control Container to Arrange Containing Controls in a Grid

=head1 SYNOPSIS

    use LibUI ':all';
    use LibUI::Grid;
    use LibUI::Window;
    use LibUI::Align qw[Center Fill];
    use LibUI::At    qw[Bottom];
    use LibUI::Label;
    Init && die;
    my $window = LibUI::Window->new( 'Hi', 320, 100, 0 );
    $window->setMargined( 1 );
    my $grid   = LibUI::Grid->new();
    my $lbl    = LibUI::Label->new('Top Left');
    $grid->append( $lbl,                           0, 0, 1, 1, 1, Fill, 1, Fill );
    $grid->append( LibUI::Label->new('Top Right'), 1, 0, 1, 1, 1, Fill, 1, Fill );
    $grid->insertAt( LibUI::Label->new('Bottom Center and Span two cols'),
        $lbl, Bottom, 2, 1, 1, Center, 1, Center );
    $window->setChild($grid);
    $window->onClosing(
        sub {
            Quit();
            return 1;
        },
        undef
    );
    $window->show;
    Main();

=head1 DESCRIPTION

A LibUI::Grid object represents a control container to arrange containing
controls in a grid.

Contained controls are arranged on an imaginary grid of rows and columns.
Controls can be placed anywhere on this grid, spanning multiple rows and/or
columns.

Additionally placed controls can be programmed to expand horizontally and/or
vertically, sharing the remaining space among other expanded controls.

Alignment options are available via L<LibUI::Align> attributes to determine the
controls placement within the reserved area, should the area be bigger than the
control itself.

Controls can also be placed in relation to other controls using L<LibUI::At>
attributes.

=head1 Functions

Not a lot here but... well, it's just a tab box.

=head2 C<new( ... )>

    my $grid = LibUI::Grid->new( );

Creates a new form.

=head2 C<append( ... )>

    $grid->append( LibUI::Label->new('Top Left'),
        0, 0, 1, 1, 1, Fill, 1, Fill );
    $grid->append( LibUI::Label->new('Top Right'),
        1, 0, 1, 1, 1, Fill, 1, Fill );

Appends a control to the grid.

Expected parameters include:

=over

=item C<$child> - LibUI::Control instance to insert

=item C<$left> - Placement as number of columns from left

=item C<$top> - Placement as number of rows from the top

=item C<$xspan> - Number of columns to span

=item C<$yspan> - Number of rows to span

=item C<$hexpand> - Boolean value; true to expand reserved area horizontally; otherwise false

=item C<$halign> - Horizontal alignment of the control within the reserved space

=item C<$vexpand> - Bolean value; true to expand reserved area vertically; otherwise false

=item C<$valign> - Vertical alignment of the control within the reserved space

=back

See L<LibUI::Align> for possible values of C<$halign> and C<$valign>.

=head2 C<insertAt( ... )>

    my $grid   = LibUI::Grid->new();
    my $lbl    = LibUI::Label->new('Top Left');
    $grid->append( $lbl, 0, 0, 1, 1, 1, Fill, 1, Fill );
    $grid->append( LibUI::Label->new('Top Right'),
        1, 0, 1, 1, 1, Fill, 1, Fill );
    # Insert below $lbl and span two columns
    $grid->insertAt( LibUI::Label->new('Bottom Center and Stretch'),
        $lbl, Bottom, 2, 1, 1, Center, 1, Center );

Appends a control to the grid.

Expected parameters include:

=over

=item C<$child> - LibUI::Control instance to insert

=item C<$existing> - The existing LibUI::Control instance to position relatively to

=item C<$at> - Placement specifier in relation to C<$existing> control

=item C<$xspan> - Number of columns to span

=item C<$yspan> - Number of rows to span

=item C<$hexpand> - Boolean value; true to expand reserved area horizontally; otherwise false

=item C<$halign> - Horizontal alignment of the control within the reserved space

=item C<$vexpand> - Bolean value; true to expand reserved area vertically; otherwise false

=item C<$valign> - Vertical alignment of the control within the reserved space

=back

See L<LibUI::Align> for possible values of C<$halign> and C<$valign>.

See L<LibUI::At> for possible values of C<$at>.

=head2 C<padded( )>

    if( $grid->padded ) {
        ...;
    }

Returns whether or not controls within the grid are padded.

Padding is defined as space between individual controls.

=head2 C<setPadded( ... )>

    $grid->setPadded( 1 );

Sets whether or not controls within the grid are padded.

Padding is defined as space between individual controls. The padding size is
determined by the OS defaults.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

