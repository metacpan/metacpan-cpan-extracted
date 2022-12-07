package LibUI::TextWeight 0.01 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix qw[UIntEnum typedef];
    use parent 'Exporter';
    my @enum = (
        [ Minimum    => 0 ],
        [ Thin       => 100 ],
        [ UltraLight => 200 ],
        [ Light      => 300 ],
        [ Book       => 350 ],
        [ Normal     => 400 ],
        [ Medium     => 500 ],
        [ SemiBold   => 600 ],
        [ Bold       => 700 ],
        [ UltraBold  => 800 ],
        [ Heavy      => 900 ],
        [ UltraHeavy => 950 ],
        [ Maximum    => 1000 ]
    );
    typedef 'LibUI::TextWeight' => UIntEnum [@enum];
    our %EXPORT_TAGS;
    our @EXPORT_OK = @{ $EXPORT_TAGS{all} } = LibUI::TextWeight()->{values};
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::TextWeight - Weight or Boldness of a Font Descriptor

=head1 SYNOPSIS

    use LibUI::TextWeight qw[:all];

=head1 DESCRIPTION

These values are used by L<LibUI::FontDescriptor>. You may import them
individually or with the C<:all> tag.

=head1 Values

=over

=item C<Minimum>

=item C<Thin>

=item C<UltraLight>

=item C<Light>

=item C<Book>

=item C<Normal>

=item C<Medium>

=item C<SemiBold>

=item C<Bold>

=item C<UltraBold>

=item C<Heavy>

=item C<UltraHeavy>

=item C<Maximum>

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

