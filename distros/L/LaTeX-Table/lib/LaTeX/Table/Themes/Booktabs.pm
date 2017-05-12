package LaTeX::Table::Themes::Booktabs;
use Moose;

with 'LaTeX::Table::Themes::ThemeI';

use version; our $VERSION = qv('1.0.6');

sub _definition {
    my $themes = {
        'Zurich' => {
            'HEADER_FONT_STYLE' => 'bf',
            'HEADER_CENTERED'   => 1,
            'STUB_ALIGN'        => 'l',
            'VERTICAL_RULES'    => [ 0, 0, 0 ],
            'HORIZONTAL_RULES'  => [ 1, 1, 0 ],
            'BOOKTABS'          => 1,
        },
        'Meyrin' => {
            'STUB_ALIGN'       => 'l',
            'VERTICAL_RULES'   => [ 0, 0, 0 ],
            'HORIZONTAL_RULES' => [ 1, 1, 0 ],
            'BOOKTABS'         => 1,
        },
        'Evanston' => {
            'HEADER_FONT_STYLE' => 'bf',
            'STUB_ALIGN'        => 'l',
            'VERTICAL_RULES'    => [ 0, 0, 0 ],
            'HORIZONTAL_RULES'  => [ 1, 1, 0 ],
            'RULES_CMD'         => [
                '\toprule', '\midrule[\heavyrulewidth]',
                '\midrule', '\bottomrule'
            ],
        },
    };
    return $themes;
}

1;
__END__

=head1 NAME

LaTeX::Table::Themes::Booktabs - Publication quality LaTeX table themes.

=head1 PROVIDES

This module provides following themes:

  Meyrin   # as described in the booktabs documentation
  Zurich   # header centered and in bold font
  Evanston # as described in Lapo Filippo Mori's tutorial

=head1 REQUIRES

The themes defined in this module require following LaTeX packages:

  \usepackage{booktabs}

=head1 SEE ALSO

L<LaTeX::Table>, L<LaTeX::Table::Themes::ThemeI>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006-2010 C<< <limaone@cpan.org> >> 

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

# vim: ft=perl sw=4 ts=4 expandtab
