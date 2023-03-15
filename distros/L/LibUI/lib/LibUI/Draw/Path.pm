package LibUI::Draw::Path 0.02 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    #
    typedef 'LibUI::Draw::FillMode' => Enum [qw[Winding Alternate]];
    #
    affix(
        LibUI::lib(),
        [ 'uiDrawNewPath', 'new' ],
        [ Void,            LibUI::Draw::FillMode() ] => InstanceOf ['LibUI::Draw::Path']
    );
    affix(
        LibUI::lib(),
        [ 'uiDrawFreePath', 'free' ],
        [ InstanceOf ['LibUI::Draw::Path'] ] => Void
    );
    #
    affix(
        LibUI::lib(),
        [ 'uiDrawPathNewFigure', 'newFigure' ],
        [ InstanceOf ['LibUI::Draw::Path'], Double, Double ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiDrawPathNewFigureWithArc',     'newFigureWithArc' ],
        [ InstanceOf ['LibUI::Draw::Path'], Double, Double, Double, Double, Double, Int ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiDrawPathLineTo', 'lineTo' ],
        [ InstanceOf ['LibUI::Draw::Path'], Double, Double ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiDrawPathArcTo', 'arcTo' ],
        [ InstanceOf ['LibUI::Draw::Path'], Double, Double, Double, Double, Double, Int ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiDrawPathBezierTo', 'bezierTo' ],
        [ InstanceOf ['LibUI::Draw::Path'], Double, Double, Double, Double, Double, Double ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiDrawPathCloseFigure', 'closeFigure' ],
        [ InstanceOf ['LibUI::Draw::Path'] ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiDrawPathAddRectangle', 'addRectangle' ],
        [ InstanceOf ['LibUI::Draw::Path'], Double, Double, Double, Double ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiDrawPathEnded', 'ended' ],
        [ InstanceOf ['LibUI::Draw::Path'] ] => Int
    );
    affix( LibUI::lib(), [ 'uiDrawPathEnd', 'end' ], [ InstanceOf ['LibUI::Draw::Path'] ] => Void );
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::Draw::Path - Button to be Clicked by the User to Trigger an Action

=head1 SYNOPSIS

    TODO

=head1 DESCRIPTION

TODO

=head1 Functions

Not a lot here but... well, it's just a struct.

=head2 C<new( ... )>

    my $path = LibUI::Draw::Path->new( $mode );

Creates a new draw path.

Expected parameters include:

=over

=item C<fillMode> - a LibUI::Draw::FillMode value

=back

=head2 C<free( )>

    $path->free;

Frees the path's memory.

=head2 C<newFigure( ... )>

    $path->newFigure( 100, 100 );

Creates a new drawing figure.

Expected parameters include:

=over

=item C<x>

=item C<y>

=back

=head2 C<newFigureWithArc( ... )>

    $path->newFigureWithArc( 100, 100, 30, 90, 20, 0 );

Creates a new drawing figure.

Expected parameters include:

=over

=item C<xCenter>

=item C<yCenter>

=item C<radius>

=item C<startAngle>

=item C<sweep>

=item C<negative>

=back

=head2 C<lineTo( ... )>

    $path->newFigure( 100, 100 );

Draws a line to a given point.

Expected parameters include:

=over

=item C<x>

=item C<y>

=back

=head2 C<arcTo( ... )>

    $path->arcTo( 100, 100, 30, 90, 20, 0 );

Draws an arc to a given point.

Expected parameters include:

=over

=item C<xCenter>

=item C<yCenter>

=item C<radius>

=item C<startAngle>

=item C<sweep>

=item C<negative>

=back

=head2 C<bezierTo( ... )>

    $path->bezierTo( 100, 100, 30, 90, 200, 150 );

Draws a bezier curve to a given point.

Expected parameters include:

=over

=item C<x1>

=item C<y1>

=item C<x2>

=item C<y2>

=item C<endX>

=item C<endY>

=back

=head2 C<closeFigure( )>

    $path->closeFigure( );

Closes the current path.

=head2 C<addRectangle( ... )>

    $path->addRectangle( 100, 100, 50, 50 );

Adds a rectangle to the path with a given size at a given position.

Expected parameters include:

=over

=item C<x>

=item C<y>

=item C<width>

=item C<height>

=back

=head2 C<ended( )>

    my $done = $path->ended( );

Returns a boolean value indicating if the path is finished.

=head2 C<end( )>

   $path->end( );

Ends the path.

=head1 Enumerations


=head2 Fill Mode

This enum is defined as C<LibUI::Draw::FillMode>.

Values include:

=over

=item C<Winding>

=item C<Alternate>

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=for stopwords checkbox backreference bezier struct enum

=cut

