package LibUI::ScrollingArea 0.02 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use LibUI::Area::Handler;
    use parent 'LibUI::Area';
    #
    affix(
        LibUI::lib(),
        [ 'uiAreaSetSize', 'setSize' ],
        [ InstanceOf ['LibUI::Area'], Int, Int ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiAreaScrollTo', 'scrollTo' ],
        [ InstanceOf ['LibUI::Area'], Double, Double, Double, Double ] => Void
    );
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::ScrollingArea - Control Representing a Canvas You May Draw On but with
Scrollbars Now

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

A LibUI::Area object represents a control you may draw on. It receives keyboard
and mouse events, supports scrolling, is DPI aware, and has several other
useful features. The control consists of the drawing area itself and horizontal
and vertical scrollbars.

A LibUI::Area is driven by an L<area handler|LibUI::Area::Handler>.

=head1 Functions

Not a lot here but... well, it's just a, interactive box.

=head2 C<new( ... )>

    my $area = LibUI::Area->new( );

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

=for stopwords scrollbars

=cut

