package LaTeX::Table::Themes::Beamer;
use Moose;

with 'LaTeX::Table::Themes::ThemeI';

use version; our $VERSION = qv('1.0.6');

sub _definition {
    my $themes = {
        NYC => {
            'HEADER_FONT_STYLE'  => 'bf',
            'HEADER_FONT_COLOR'  => 'white',
            'HEADER_BG_COLOR'    => 'latextbl',
            'DATA_BG_COLOR_ODD'  => 'latextbl!25',
            'DATA_BG_COLOR_EVEN' => 'latextbl!10',
            'DEFINE_COLORS'      => '\definecolor{latextbl}{RGB}{78,130,190}',
            'HEADER_CENTERED'    => 1,
            'VERTICAL_RULES'     => [ 1, 0, 0 ],
            'HORIZONTAL_RULES'   => [ 1, 1, 0 ],
            'BOOKTABS'           => 0,
            'EXTRA_ROW_HEIGHT'   => '1pt',
        },
        NYC2 => {
            'HEADER_FONT_STYLE'  => 'bf',
            'HEADER_FONT_COLOR'  => 'white',
            'HEADER_BG_COLOR'    => 'latextbl',
            'DATA_BG_COLOR_ODD'  => 'latextbl!25',
            'DATA_BG_COLOR_EVEN' => 'latextbl!10',
            'DEFINE_COLORS'      => '\definecolor{latextbl}{RGB}{78,130,190}',
            'HEADER_CENTERED'    => 1,
            'VERTICAL_RULES'     => [ 1, 0, 0 ],
            'HORIZONTAL_RULES'   => [ 1, 0, 0 ],
            'BOOKTABS'           => 0,
            'EXTRA_ROW_HEIGHT'   => '1pt',
        },
        NYC3 => {
            'HEADER_FONT_STYLE'  => 'bf',
            'HEADER_FONT_COLOR'  => 'white',
            'HEADER_BG_COLOR'    => 'latextbl',
            'DATA_BG_COLOR_ODD'  => 'latextbl!25',
            'DATA_BG_COLOR_EVEN' => 'latextbl!10',
            'DEFINE_COLORS'      => '\definecolor{latextbl}{RGB}{78,130,190}',
            'HEADER_CENTERED'    => 1,
            'VERTICAL_RULES'     => [ 1, 1, 1 ],
            'HORIZONTAL_RULES'   => [ 1, 2, 1 ],
            'BOOKTABS'           => 0,
            'EXTRA_ROW_HEIGHT'   => '1pt',
            'RULES_COLOR_GLOBAL' =>
                '\arrayrulecolor{white}\doublerulesepcolor{black}',
            'RULES_WIDTH_GLOBAL' =>
                '\setlength\arrayrulewidth{1pt}\setlength\doublerulesep{0pt}',
        },
        NYC4 => {
            'HEADER_FONT_STYLE'  => 'bf',
            'HEADER_FONT_COLOR'  => 'white',
            'HEADER_BG_COLOR'    => 'latextbl',
            'DATA_BG_COLOR_ODD'  => 'latextbl!25',
            'DATA_BG_COLOR_EVEN' => 'latextbl!10',
            'DEFINE_COLORS'      => '\definecolor{latextbl}{RGB}{78,130,190}',
            'HEADER_CENTERED'    => 1,
            'VERTICAL_RULES'     => [ 0, 0, 0 ],
            'HORIZONTAL_RULES'   => [ 1, 1, 0 ],
            'BOOKTABS'           => 0,
            'EXTRA_ROW_HEIGHT'   => '1pt',
            'RULES_COLOR_GLOBAL' =>
                '\arrayrulecolor{black}\doublerulesepcolor{black}',
            'RULES_WIDTH_GLOBAL' =>
                '\setlength\arrayrulewidth{1pt}\setlength\doublerulesep{0pt}',
        },
        Redmond => {
            'HEADER_FONT_STYLE'  => 'bf',
            'HEADER_FONT_COLOR'  => 'white',
            'HEADER_BG_COLOR'    => 'black',
            'DATA_BG_COLOR_ODD'  => 'latextbl!25',
            'DATA_BG_COLOR_EVEN' => 'latextbl!10',
            'DEFINE_COLORS'      => '\definecolor{latextbl}{RGB}{78,130,190}',
            'STUB_ALIGN'         => 'l',
            'VERTICAL_RULES'     => [ 0, 0, 0 ],
            'HORIZONTAL_RULES'   => [ 0, 2, 1 ],
            'BOOKTABS'           => 0,
            'RULES_COLOR_GLOBAL' =>
                '\arrayrulecolor{white}\doublerulesepcolor{black}',
            'RULES_WIDTH_GLOBAL' =>
                '\setlength\arrayrulewidth{1pt}\setlength\doublerulesep{0pt}',
            'EXTRA_ROW_HEIGHT' => '1pt',
        },
        Redmond2 => {
            'HEADER_FONT_STYLE'  => 'bf',
            'HEADER_FONT_COLOR'  => 'white',
            'HEADER_BG_COLOR'    => 'black',
            'DATA_BG_COLOR_ODD'  => 'latextbl!25',
            'DATA_BG_COLOR_EVEN' => 'latextbl!10',
            'DEFINE_COLORS'      => '\definecolor{latextbl}{RGB}{78,130,190}',
            'STUB_ALIGN'         => 'l',
            'VERTICAL_RULES'     => [ 0, 0, 0 ],
            'HORIZONTAL_RULES'   => [ 0, 2, 0 ],
            'BOOKTABS'           => 0,
            'RULES_COLOR_GLOBAL' =>
                '\arrayrulecolor{white}\doublerulesepcolor{black}',
            'RULES_WIDTH_GLOBAL' =>
                '\setlength\arrayrulewidth{1pt}\setlength\doublerulesep{0pt}',
            'EXTRA_ROW_HEIGHT' => '1pt',
        },
    };
    return $themes;
}

1;
__END__

=head1 NAME

LaTeX::Table::Themes::Beamer - Colorful LaTeX table themes optimized for presentations.

=head1 PROVIDES

This module provides following themes:

  NYC
  NYC2  # same, but without midline after header
  NYC3  # with a white grid
  NYC4  # with black horizontal lines
  Redmond
  Redmond2 # same, but without horizontal lines 

=head1 REQUIRES

The themes defined in this module require following LaTeX packages:

  \usepackage{array}
  \usepackage{colortbl}
  \usepackage{xcolor}

=head1 SEE ALSO

L<LaTeX::Table>, L<LaTeX::Table::Themes::ThemeI>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006-2010 C<< <limaone@cpan.org> >> 

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

# vim: ft=perl sw=4 ts=4 expandtab
