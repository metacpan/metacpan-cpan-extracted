package LibUI::Draw 0.02 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use lib '../../lib';
    use LibUI;
    use LibUI::Draw::Path;
    use LibUI::Draw::Brush;
    use LibUI::Draw::StrokeParams;
    use LibUI::Draw::Matrix;
    #
    affix(
        LibUI::lib(),
        [ 'uiDrawStroke', 'stroke' ],
        [   Pointer [Void],
            InstanceOf ['LibUI::Draw::Path'],
            Pointer [LibUI::Draw::Brush],
            Pointer [LibUI::Draw::StrokeParams],
        ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiDrawFill',   'fill' ],
        [ Pointer [Void], InstanceOf ['LibUI::Draw::Path'], Pointer [LibUI::Draw::Brush] ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiDrawTransform', 'transform' ],
        [ Pointer [Void],    Pointer [ LibUI::Draw::Matrix() ] ] => Void
    );
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::Draw - Enumerations for LibUI::Area Drawing

=head1 SYNOPSIS



=head1 DESCRIPTION

Drawing on an LibUI::Area is easy but defining your own brushes is not. Well,
values provided here make it a little less annoying.

=head1 Functions

=head2 C<stroke( ... )>




=head2 C<fill( ... )>




=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=for stopwords checkbox backreference

=cut

