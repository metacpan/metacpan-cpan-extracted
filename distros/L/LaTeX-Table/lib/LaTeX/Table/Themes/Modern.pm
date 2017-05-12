package LaTeX::Table::Themes::Modern;
use Moose;

with 'LaTeX::Table::Themes::ThemeI';

use version; our $VERSION = qv('1.0.6');

sub _definition {
    my $themes = {
        'Paris' => {
            'HEADER_FONT_STYLE'  => 'bf',
            'HEADER_CENTERED'    => 1,
            'HEADER_BG_COLOR'    => 'latextblgray',
            'DEFINE_COLORS'      => '\definecolor{latextblgray}{gray}{0.7}',
            'CAPTION_FONT_STYLE' => 'bf',
            'VERTICAL_RULES'     => [ 1, 1, 1 ],
            'HORIZONTAL_RULES'   => [ 1, 1, 0 ],
            'BOOKTABS'           => 0,
        },
        'Muenchen' => {
            'HEADER_FONT_STYLE' => 'bf',
            'STUB_ALIGN'        => 'l',
            'DEFINE_COLORS'     => '\definecolor{latextbl}{RGB}{78,130,190}',
            'CAPTION_FONT_STYLE' => 'bf',
            'DATA_BG_COLOR_EVEN' => 'latextbl!20',
            'VERTICAL_RULES'     => [ 0, 0, 0 ],
            'HORIZONTAL_RULES'   => [ 0, 0, 0 ],
            'BOOKTABS'           => 1,
            'EXTRA_ROW_HEIGHT'   => '1pt',
        },
    };
    return $themes;
}

1;
__END__

=head1 NAME

LaTeX::Table::Themes::Modern - Modern LaTeX table themes.

=head1 PROVIDES

This module provides following themes:

  Paris
  Muenchen

=head1 REQUIRES

The themes defined in this module requires following LaTeX packages:

  \usepackage{xcolor}

=head1 NOTES

You probably want to use a Sans-serif font:

  $tbl->set_fontfamily('sf');

=head1 SEE ALSO

L<LaTeX::Table>, L<LaTeX::Table::Themes::ThemeI>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006-2010 C<< <limaone@cpan.org> >> 

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

# vim: ft=perl sw=4 ts=4 expandtab
