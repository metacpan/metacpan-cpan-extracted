package LibUI::TextStretch 0.01 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix qw[UIntEnum typedef];
    use parent 'Exporter';
    my @enum = (
        qw[
            UltraCondensed
            ExtraCondensed
            Condensed
            SemiCondensed
            Normal
            SemiExpanded
            Expanded
            ExtraExpanded
            UltraExpanded
        ]
    );
    typedef 'LibUI::TextStretch' => UIntEnum [@enum];
    our %EXPORT_TAGS;
    our @EXPORT_OK = @{ $EXPORT_TAGS{all} } = LibUI::TextStretch()->{values};
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::TextStretch - Inter-character Spacing of a Font Descriptor

=head1 SYNOPSIS

    use LibUI::TextStretch qw[:all];

=head1 DESCRIPTION

Some font families offer additional faces in which the characters are narrower
than the normal face (condensed faces) or wider than the normal face (expanded
faces).

These values are used by L<LibUI::FontDescriptor>. You may import them
individually or with the C<:all> tag.

=head1 Values

=over

=item C<UltraCondensed>

=item C<ExtraCondensed>

=item C<Condensed>

=item C<SemiCondensed>

=item C<Normal>

=item C<SemiExpanded>

=item C<Expanded>

=item C<ExtraExpanded>

=item C<UltraExpanded>

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

