package LibUI::Area::DrawParams 0.02 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    #
    typedef 'LibUI::Area::DrawParams' => Struct [
        context    => Pointer [Void],
        width      => Double,
        height     => Double,
        clipX      => Double,
        clipY      => Double,
        clipWidth  => Double,
        clipHeight => Double
    ];
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::Area::DrawParams - LibUI::Area Drawing Parameters

=head1 SYNOPSIS

    TODO

=head1 DESCRIPTION

A LibUI::Area::Handler hands drawing parameters to C<draw> callbacks.

=head1 Fields

The structure contains the following data:

=over

=item C<context> - pointer (no user serviceable parts inside)

=item C<width> - width of the drawing area (only defined in non-scrolling areas)

=item C<height> - height of the drawing area (only defined in non-scrolling areas)

=item C<clipX> - vertical clipping position

=item C<clipY> - horizontal clipping position

=item C<clipWidth> - clipping width

=item C<clipHeight> - clipping height

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

