package LibUI::FontDescriptor 0.01 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use parent 'Exporter';
    use LibUI::TextWeight;
    use LibUI::TextItalic;
    use LibUI::TextStretch;
    #
    typedef 'LibUI::FontDescriptor' => Struct [
        family  => Str,
        size    => Double,
        weight  => LibUI::TextWeight,
        italic  => LibUI::TextItalic,
        stretch => LibUI::TextStretch
    ];
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::At - Placement Specifier to Define Placement in Relation to Another
Control

=head1 Values

=over

=item C<family> - Name of the font

=item C<size> - Font size

=item C<weight> - Font weight as L<LibUI::TextWeight>

=item C<italic> - Font italic state as L<LibUI::TextItalic>

=item C<stretch> - Inter-character spacing as L<LibUI::TextStretch>

=back

=head1 See Also

L<LibUI::FontButton>

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

