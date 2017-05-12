use strict;
use warnings;

use Test::Most;

exit main(@ARGV);

sub main {
    BEGIN { use_ok('Lingua::ManagementSpeak') };
    ok( my $ms = Lingua::ManagementSpeak->new, 'new Lingua::ManagementSpeak' );

    isnt(
        $ms->words(
            'pronoun article sub_conjunc power_word verb aux_verb adjective ' .
            'noun to_be conj_adverb conjuntor adverb phrase maybe_1/2_phrase'
        ), '' || undef || 0, 'words()'
    );

    isnt( $ms->sentence,        '' || undef || 0, 'sentense()'     );
    isnt( $ms->sentence(1),     '' || undef || 0, 'sentense(1)'    );
    isnt( $ms->paragraph,       '' || undef || 0, 'paragraph()'    );
    isnt( $ms->paragraph(2),    '' || undef || 0, 'paragraph(2)'   );
    isnt( $ms->paragraph(2, 3), '' || undef || 0, 'paragraph(2, 3)');

    ok(
        eval( join( '+', map {1} ( $ms->paragraph(3) =~ /\./g ) ) ) == 3,
        'paragraph(2) returns two sentences'
    );

    ok( $ms->paragraphs(2) == 2,       'paragraphs(2) returns two paragraphs'       );
    ok( $ms->paragraphs(2, 1) == 2,    'paragraphs(2, 1) returns two paragraphs'    );
    ok( $ms->paragraphs(2, 1, 3) == 2, 'paragraphs(2, 1, 3) returns two paragraphs' );
    ok( $ms->bullets() == 5,           'bullets() returns five bullet items'        );
    ok( $ms->bullets(3) == 3,          'bullets(3) returns three bullet items'      );
    ok( $ms->header(),                 'header()'                                   );
    ok( $ms->header(5),                'header(5)'                                  );
    ok( $ms->structure >= 5,           'structure() returns >= 5 headers'           );
    ok( $ms->structure(3, 3, 5) >= 5,  'structure(3, 3, 5) returns >= 5 headers'    );

    ok( $ms->body, 'body()' );
    ok(
        $ms->body( {
            p_min   => 2,
            p_max   => 4,
            p_s_min => 1,
            p_s_max => 1,
            b_freq  => 20,
            b_min   => 4,
            b_max   => 6
        } ), 'body() with all parameters explicitly defined',
    );

    ok( $ms->document, 'document()' );
    ok(
        $ms->document(
            [ 1, 2, 2, 1, 2 ],
            {
                p_min   => 1,
                p_max   => 2,
                p_s_min => 1,
                p_s_max => 3,
                b_freq  => 40,
                b_min   => 3,
                b_max   => 4
            }
        ), 'document() with all parameters explicitly defined'
    );

    ok( $ms->to_html($ms->document), 'to_html(document())' );

    done_testing();
    return 0;
}
