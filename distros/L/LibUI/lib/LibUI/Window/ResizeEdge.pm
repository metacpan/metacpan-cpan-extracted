package LibUI::Window::ResizeEdge 0.02 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    #
    typedef 'LibUI::Window::ResizeEdge' => Enum [
        qw[windowResizeEdgeLeft
            windowResizeEdgeTop
            windowResizeEdgeRight
            windowResizeEdgeBottom
            windowResizeEdgeTopLeft
            windowResizeEdgeTopRight
            windowResizeEdgeBottomLeft
            windowResizeEdgeBottomRight]
    ];
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::Window::ResizeEdge - Enumerations Use to Initiate User-Driven Mouse
Resize of the Window

=head1 SYNOPSIS

    TODO

=head1 DESCRIPTION

A L<LibUI::Area> can be resized. To initiate a user-driven resize, you may pass
any of the values defined here.

These values may be used as bitmasks.

=head1 Enum Values

Here's the current list of values:

=over

=item C<windowResizeEdgeLeft>

=item C<windowResizeEdgeTop>

=item C<windowResizeEdgeRight>

=item C<windowResizeEdgeBottom>

=item C<windowResizeEdgeTopLeft>

=item C<windowResizeEdgeTopRight>

=item C<windowResizeEdgeBottomLeft>

=item C<windowResizeEdgeBottomRight>

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=for stopwords bitmasks

=cut

