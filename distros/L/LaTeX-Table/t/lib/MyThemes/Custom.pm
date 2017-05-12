package MyThemes::Custom;
use Moose;

with 'LaTeX::Table::Themes::ThemeI';

sub _definition {
    return {
        'Erfurt' => {
            'HEADER_FONT_STYLE' => 'sc',
            'HEADER_CENTERED'   => 1,
            'STUB_ALIGN'        => q{l},
            'VERTICAL_RULES'    => [ 0, 0, 0 ],
            'HORIZONTAL_RULES'  => [ 1, 1, 0 ],
            'BOOKTABS'          => 1,
        },
        'Oxford' => {
            'STUB_ALIGN'        => q{l},
            'VERTICAL_RULES'    => [ 0, 0, 0 ],
            'HORIZONTAL_RULES'  => [ 1, 1, 0 ],
            'RULES_CMD' => [ '\toprule', '\midrule', '\midrule', '\botrule' ],
        }
    };
}

1;

# vim: ft=perl sw=4 ts=4 expandtab
