use strict;
use warnings;

use lib '../lib';

use HTML::Composer;
use Test::More;

my $h = HTML::Composer->new();

sub attrs_str {
    my ($href) = @_;
    my $s = '';
    for my $k ( sort keys %$href ) {
        my $v =
          ref( $href->{$k} ) eq 'ARRAY'
          ? join( ' ', @{ $href->{$k} } )
          : $href->{$k};
        $s .= ' ' . $k . '="' . $v . '"';
    }
    return $s;
}

{
    my @body_elems;
    my $expected_body = '';

    for my $i ( 1 .. 200 ) {
        my $parity     = $i % 2 ? 'odd' : 'even';
        my $computed   = $i * $i;
        my $card_attrs = { class => [ 'card', $parity ], id => "card-$i" };
        my $a_attrs    = { href  => "/item/$i" };

        push @body_elems,
          div => $card_attrs => [
            h3 => ["Item $i"],
            p  => ["Paragraph $i. Computed: $computed."],
            a  => $a_attrs => ["Link $i"],
          ];

        $expected_body .= '<div'
          . attrs_str($card_attrs) . '>'
          . '<h3>Item '
          . $i . '</h3>'
          . '<p>Paragraph '
          . $i
          . '. Computed: '
          . $computed . '.</p>' . '<a'
          . attrs_str($a_attrs)
          . '>Link '
          . $i . '</a>'
          . '</div>';
    }

    my $expected =
        '<!DOCTYPE html><html lang="en">'
      . '<head><meta charset="UTF-8"><title>Generated Page</title></head>'
      . '<body>'
      . $expected_body
      . '</body></html>';

    my $html = $h->html(
        { lang => 'en' },
        [
            head => [
                meta  => { charset => 'UTF-8' },
                title => ['Generated Page'],
            ],
            body => \@body_elems,
        ]
    );

    is $html, $expected, '200 article cards: full string equality';

    my @open_divs  = ( $html =~ /(<div )/g );
    my @close_divs = ( $html =~ /(<\/div>)/g );
    my @h3s        = ( $html =~ /(<h3>)/g );
    my @anchors    = ( $html =~ /(<a )/g );
    my @odd_cards  = ( $html =~ /class="card odd"/g );
    my @even_cards = ( $html =~ /class="card even"/g );

    is scalar @open_divs,  200, '200 opening <div> tags';
    is scalar @close_divs, 200, '200 closing </div> tags';
    is scalar @h3s,        200, '200 <h3> tags';
    is scalar @anchors,    200, '200 <a> tags';
    is scalar @odd_cards,  100, '100 odd cards (items 1,3,5,...)';
    is scalar @even_cards, 100, '100 even cards (items 2,4,6,...)';

    # Spot-check first, middle, and last cards
    like $html,
      qr{<div class="card odd" id="card-1"><h3>Item 1</h3>},
      'first card (id=card-1) is present and correct';
    like $html,
qr{<div class="card even" id="card-100"><h3>Item 100</h3>.*?Computed: 10000\.},
      'middle card (id=card-100) has correct computed value (100*100=10000)';
    like $html,
      qr{<div class="card even" id="card-200">.*?</div>},
      'last card (id=card-200) is present';
}

# ---------------------------------------------------------------------------
# Test 2 — table with 100 data rows
#
# Structure:
#   table#scores
#     thead  tr  th[#] th[Name] th[Value]
#     tbody  100 × tr  td.n td.label td.val
# ---------------------------------------------------------------------------
{
    my @tbody_rows;
    my $expected_tbody = '';

    for my $i ( 1 .. 100 ) {
        my $val = ( $i * 13 ) % 97;

        push @tbody_rows,
          tr => [
            td => { class => 'n' }     => ["$i"],
            td => { class => 'label' } => ["Row $i"],
            td => { class => 'val' }   => ["$val"],
          ];

        $expected_tbody .= '<tr>'
          . '<td class="n">'
          . $i . '</td>'
          . '<td class="label">'
          . "Row $i" . '</td>'
          . '<td class="val">'
          . $val . '</td>' . '</tr>';
    }

    my $expected =
        '<!DOCTYPE html><html>'
      . '<head><title>Score Table</title></head>'
      . '<body>'
      . '<table id="scores">'
      . '<thead><tr><th>#</th><th>Name</th><th>Value</th></tr></thead>'
      . '<tbody>'
      . $expected_tbody
      . '</tbody>'
      . '</table>'
      . '</body></html>';

    my $html = $h->html(
        [
            head => [ title => ['Score Table'] ],
            body => [
                table => { id => 'scores' } => [
                    thead => [
                        tr => [
                            th => ['#'],
                            th => ['Name'],
                            th => ['Value'],
                        ],
                    ],
                    tbody => \@tbody_rows,
                ],
            ],
        ]
    );

    is $html, $expected, '100-row table: full string equality';

    my @trs = ( $html =~ /(<tr>)/g );
    my @tds = ( $html =~ /(<td )/g );
    my @ths = ( $html =~ /(<th>)/g );

    is scalar @trs, 101, '101 <tr> tags (1 header + 100 body rows)';
    is scalar @tds, 300, '300 <td> tags (3 columns × 100 rows)';
    is scalar @ths, 3,   '3 <th> tags (header row only)';

    my $val_1   = ( 1 * 13 ) % 97;
    my $val_50  = ( 50 * 13 ) % 97;
    my $val_97  = ( 97 * 13 ) % 97;
    my $val_100 = ( 100 * 13 ) % 97;

    is $val_97, 0, 'sanity: row 97 val is 0 (zero text-content edge case)';

    like $html,
qr{<td class="n">1</td><td class="label">Row 1</td><td class="val">$val_1</td>},
      'row 1 has correct n/label/val cells';
    like $html,
qr{<td class="n">50</td><td class="label">Row 50</td><td class="val">$val_50</td>},
      'row 50 has correct n/label/val cells';
    like $html,
qr{<td class="n">97</td><td class="label">Row 97</td><td class="val">0</td>},
      'row 97 renders "0" text content correctly (zero is falsy in Perl)';
    like $html,
qr{<td class="n">100</td><td class="label">Row 100</td><td class="val">$val_100</td>},
      'row 100 has correct n/label/val cells';
}

done_testing;
