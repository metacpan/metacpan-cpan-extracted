use strict;
use warnings;
use Test::More;
use Carp qw/croak/;

use lib '.';

BEGIN {
    use_ok("t::Templates::JustHeaders");
    use_ok("t::Templates::JustHeadersArray");
    use_ok("t::Templates::JustHeadersPassData");
    use_ok("t::Templates::JustHeadersText");
    use_ok("t::Templates::AllRows");
    use_ok("t::Templates::OddEvenRows");
    use_ok("t::Templates::IndexRows");
    use_ok("t::Templates::IndexFlagRows");
    use_ok("t::Templates::AllCells");
    use_ok("t::Templates::OddEvenCells");
    use_ok("t::Templates::IndexNutsCells");
    use_ok("t::Templates::IndexFlagCells");
    use_ok("t::Templates::HeaderCells");
    use_ok("t::Templates::IncrementRows");
    use_ok("t::Templates::RowCells");
    use_ok("t::Templates::AltClassRows");
    use_ok("t::Templates::AltClassOddRows");
    use_ok("t::Templates::AltClassRowCells");
    use_ok("t::Templates::AltClassCells");
    use_ok("t::Templates::AltClassOddCells");
    use_ok("t::Templates::AltClassHeaderCells");
    use_ok("t::Templates::AltNuts");
}
 
subtest "just_headers" => sub  {
    plan tests => 33;
    run_tests({
        class => 't::Templates::JustHeaders',
        caption => {
            title => {
                template_attr => 'title',
                class => 'some-class',
                id => 'caption-id',
                text => 'table caption',
            }
        },
        headers => {
            id => {
                template_attr => 'id',
                class => 'some-class',
                id => 'something-id',
                text => 'id',
            },
            name => {
                template_attr => 'name',
                class => 'okay',
                text => 'name',
            },
            address => {
                template_attr => 'address',
                class => 'what',
                text => 'address',
            }
        },
        table => {
            row_count => 3,
            header_count => 3,
        },
        first_header => {
            template_attr => 'id',
            class => 'some-class',
            id => 'something-id',
            text => 'id',
        },
        first_row => {
            cell_count => 3,
        },
        fr_first_cell => {
            text => '1',
        },
        fr_last_cell => {
            text => 'somewhere',
        },
        render => '<table><caption class="some-class" id="caption-id">table caption</caption><tr><th class="some-class" id="something-id">id</th><th class="okay">name</th><th class="what">address</th></tr><tr><td>1</td><td>rob</td><td>somewhere</td></tr><tr><td>2</td><td>sam</td><td>somewhere else</td></tr><tr><td>3</td><td>frank</td><td>out</td></tr></table>',
    });
};
 
subtest "just_headers_data_is_aoa" => sub  {
    plan tests => 33;
    run_tests({
        class => 't::Templates::JustHeadersArray',
        caption => {
            title => {
                template_attr => 'title',
                class => 'some-class',
                id => 'caption-id',
                text => 'table caption',
            }
        },
        headers => {
            id => {
                template_attr => 'id',
                class => 'some-class',
                id => 'something-id',
                text => 'id',
            },
            name => {
                template_attr => 'name',
                class => 'okay',
                text => 'name',
            },
            address => {
                template_attr => 'address',
                class => 'what',
                text => 'address',
            }
        },
        table => {
            row_count => 3,
            header_count => 3,
        },
        first_header => {
            template_attr => 'id',
            class => 'some-class',
            id => 'something-id',
            text => 'id',
        },
        first_row => {
            cell_count => 3,
        },
        fr_first_cell => {
            text => '1',
        },
        fr_last_cell => {
            text => 'somewhere',
        },
        render => '<table><caption class="some-class" id="caption-id">table caption</caption><tr><th class="some-class" id="something-id">id</th><th class="okay">name</th><th class="what">address</th></tr><tr><td>1</td><td>rob</td><td>somewhere</td></tr><tr><td>2</td><td>sam</td><td>somewhere else</td></tr><tr><td>3</td><td>frank</td><td>out</td></tr></table>',
    });
};
 
subtest "just_headers_pass_data_aoh" => sub  {
    plan tests => 33;
    run_tests({
        class => 't::Templates::JustHeadersPassData',
        data => [
           {
                id => 1,
                name => 'rob',
                address => 'somewhere',
            },
            {
                id => 2,
                name => 'sam',
                address => 'somewhere else',
            },
            {
                id => 3,
                name => 'frank',
                address => 'out',
            },
        ],
        caption => {
            title => {
                template_attr => 'title',
                class => 'some-class',
                id => 'caption-id',
                text => 'table caption',
            }
        },
        headers => {
            id => {
                template_attr => 'id',
                class => 'some-class',
                id => 'something-id',
                text => 'id',
            },
            name => {
                template_attr => 'name',
                class => 'okay',
                text => 'name',
            },
            address => {
                template_attr => 'address',
                class => 'what',
                text => 'address',
            }
        },
        table => {
            row_count => 3,
            header_count => 3,
        },
        first_header => {
            template_attr => 'id',
            class => 'some-class',
            id => 'something-id',
            text => 'id',
        },
        first_row => {
            cell_count => 3,
        },
        fr_first_cell => {
            text => '1',
        },
        fr_last_cell => {
            text => 'somewhere',
        },
        render => '<table><caption class="some-class" id="caption-id">table caption</caption><tr><th class="some-class" id="something-id">id</th><th class="okay">name</th><th class="what">address</th></tr><tr><td>1</td><td>rob</td><td>somewhere</td></tr><tr><td>2</td><td>sam</td><td>somewhere else</td></tr><tr><td>3</td><td>frank</td><td>out</td></tr></table>',
    });
};
 
subtest "just_headers_pass_data_aoa" => sub  {
    plan tests => 33;
    run_tests({
        class => 't::Templates::JustHeadersPassData',
        data => [
            [qw/id name address/],
            [ 1, 'rob', 'somewhere'],
            [ 2, 'sam', 'somewhere else'],
            [ 3, 'frank', 'out'],        
        ],
        caption => {
            title => {
                template_attr => 'title',
                class => 'some-class',
                id => 'caption-id',
                text => 'table caption',
            }
        },
        headers => {
            id => {
                template_attr => 'id',
                class => 'some-class',
                id => 'something-id',
                text => 'id',
            },
            name => {
                template_attr => 'name',
                class => 'okay',
                text => 'name',
            },
            address => {
                template_attr => 'address',
                class => 'what',
                text => 'address',
            }
        },
        table => {
            row_count => 3,
            header_count => 3,
        },
        first_header => {
            template_attr => 'id',
            class => 'some-class',
            id => 'something-id',
            text => 'id',
        },
        first_row => {
            cell_count => 3,
        },
        fr_first_cell => {
            text => '1',
        },
        fr_last_cell => {
            text => 'somewhere',
        },
        render => '<table><caption class="some-class" id="caption-id">table caption</caption><tr><th class="some-class" id="something-id">id</th><th class="okay">name</th><th class="what">address</th></tr><tr><td>1</td><td>rob</td><td>somewhere</td></tr><tr><td>2</td><td>sam</td><td>somewhere else</td></tr><tr><td>3</td><td>frank</td><td>out</td></tr></table>',
    });
};
 
subtest "just_headers_text" => sub {
    plan tests => 33;
    run_tests({
        class => 't::Templates::JustHeadersText',
        caption => {
            title => {
                template_attr => 'title',
                class => 'some-class',
                id => 'caption-id',
                text => 'table caption',
            }
        },
        headers => {
            id => {
                template_attr => 'id',
                class => 'some-class',
                id => 'something-id',
                text => 'User Id',
            },
            name => {
                template_attr => 'name',
                class => 'okay',
                text => 'User Name',
            },
            address => {
                template_attr => 'address',
                class => 'what',
                text => 'User Address',
            }
        },
        table => {
            row_count => 3,
            header_count => 3,
        },
        first_header => {
            template_attr => 'id',
            class => 'some-class',
            id => 'something-id',
            text => 'User Id',
        },
        first_row => {
            cell_count => 3,
        },
        fr_first_cell => {
            text => '1',
        },
        fr_last_cell => {
            text => 'somewhere',
        },
        render => '<table><caption class="some-class" id="caption-id">table caption</caption><tr><th class="some-class" id="something-id">User Id</th><th class="okay">User Name</th><th class="what">User Address</th></tr><tr><td>1</td><td>rob</td><td>somewhere</td></tr><tr><td>2</td><td>sam</td><td>somewhere else</td></tr><tr><td>3</td><td>frank</td><td>out</td></tr></table>',
    });
};
 
subtest "all_rows" => sub  {
    plan tests => 34;
    run_tests({
        class => 't::Templates::AllRows',
        caption => {
            title => {
                template_attr => 'title',
                class => 'some-class',
                id => 'caption-id',
                text => 'table caption',
            }
        },
        headers => {
            id => {
                template_attr => 'id',
                class => 'some-class',
                id => 'something-id',
                text => 'id',
            },
            name => {
                template_attr => 'name',
                class => 'okay',
                text => 'name',
            },
            address => {
                template_attr => 'address',
                class => 'what',
                text => 'address',
            }
        },
        table => {
            row_count => 3,
            header_count => 3,
        },
        first_header => {
            template_attr => 'id',
            class => 'some-class',
            id => 'something-id',
            text => 'id',
        },
        first_row => {
            cell_count => 3,
            class => 'all_rows',
        },
        fr_first_cell => {
            text => '1',
        },
        fr_last_cell => {
            text => 'somewhere',
        },
        render => '<table><caption class="some-class" id="caption-id">table caption</caption><tr><th class="some-class" id="something-id">id</th><th class="okay">name</th><th class="what">address</th></tr><tr class="all_rows"><td>1</td><td>rob</td><td>somewhere</td></tr><tr class="all_rows"><td>2</td><td>sam</td><td>somewhere else</td></tr><tr class="all_rows"><td>3</td><td>frank</td><td>out</td></tr></table>',
    });
};
 
subtest "odd_even_rows" => sub  {
    plan tests => 34;
    run_tests({
        class => 't::Templates::OddEvenRows',
        caption => {
            title => {
                template_attr => 'title',
                class => 'some-class',
                id => 'caption-id',
                text => 'table caption',
            }
        },
        headers => {
            id => {
                template_attr => 'id',
                class => 'some-class',
                id => 'something-id',
                text => 'id',
            },
            name => {
                template_attr => 'name',
                class => 'okay',
                text => 'name',
            },
            address => {
                template_attr => 'address',
                class => 'what',
                text => 'address',
            }
        },
        table => {
            row_count => 3,
            header_count => 3,
        },
        first_header => {
            template_attr => 'id',
            class => 'some-class',
            id => 'something-id',
            text => 'id',
        },
        first_row => {
            cell_count => 3,
            class => 'odd',
        },
        fr_first_cell => {
            text => '1',
        },
        fr_last_cell => {
            text => 'somewhere',
        },
        render => '<table><caption class="some-class" id="caption-id">table caption</caption><tr><th class="some-class" id="something-id">id</th><th class="okay">name</th><th class="what">address</th></tr><tr class="odd"><td>1</td><td>rob</td><td>somewhere</td></tr><tr class="even"><td>2</td><td>sam</td><td>somewhere else</td></tr><tr class="odd"><td>3</td><td>frank</td><td>out</td></tr></table>',
    });
};
 
subtest "by_row_index" => sub  {
    plan tests => 35;
    run_tests({
        class => 't::Templates::IndexRows',
        caption => {
            title => {
                template_attr => 'title',
                class => 'some-class',
                id => 'caption-id',
                text => 'table caption',
            }
        },
        headers => {
            id => {
                template_attr => 'id',
                class => 'some-class',
                id => 'something-id',
                text => 'id',
            },
            name => {
                template_attr => 'name',
                class => 'okay',
                text => 'name',
            },
            address => {
                template_attr => 'address',
                class => 'what',
                text => 'address',
            }
        },
        table => {
            row_count => 3,
            header_count => 3,
        },
        first_header => {
            template_attr => 'id',
            class => 'some-class',
            id => 'something-id',
            text => 'id',
        },
        first_row => {
            cell_count => 3,
            class => 'first',
            id => 'first-row',
        },
        fr_first_cell => {
            text => '1',
        },
        fr_last_cell => {
            text => 'somewhere',
        },
        render => '<table><caption class="some-class" id="caption-id">table caption</caption><tr><th class="some-class" id="something-id">id</th><th class="okay">name</th><th class="what">address</th></tr><tr class="first" id="first-row"><td>1</td><td>rob</td><td>somewhere</td></tr><tr class="second" id="second-row"><td>2</td><td>sam</td><td>somewhere else</td></tr><tr class="third" id="third-row"><td>3</td><td>frank</td><td>out</td></tr></table>',
    });
};
 
subtest "by_row_flag_index" => sub  {
    plan tests => 35;
    run_tests({
        class => 't::Templates::IndexFlagRows',
        caption => {
            title => {
                template_attr => 'title',
                class => 'some-class',
                id => 'caption-id',
                text => 'table caption',
            }
        },
        headers => {
            id => {
                template_attr => 'id',
                class => 'some-class',
                id => 'something-id',
                text => 'id',
            },
            name => {
                template_attr => 'name',
                class => 'okay',
                text => 'name',
            },
            address => {
                template_attr => 'address',
                class => 'what',
                text => 'address',
            }
        },
        table => {
            row_count => 3,
            header_count => 3,
        },
        first_header => {
            template_attr => 'id',
            class => 'some-class',
            id => 'something-id',
            text => 'id',
        },
        first_row => {
            cell_count => 3,
            class => 'first',
            id => 'first-row',
        },
        fr_first_cell => {
            text => '1',
        },
        fr_last_cell => {
            text => 'somewhere',
        },
        render => '<table><caption class="some-class" id="caption-id">table caption</caption><tr><th class="some-class" id="something-id">id</th><th class="okay">name</th><th class="what">address</th></tr><tr class="first" id="first-row"><td>1</td><td>rob</td><td>somewhere</td></tr><tr class="second" id="second-row"><td>2</td><td>sam</td><td>somewhere else</td></tr><tr class="third" id="third-row"><td>3</td><td>frank</td><td>out</td></tr></table>',
    });
};
 
subtest "all_cells" => sub  {
    plan tests => 35;
    run_tests({
        class => 't::Templates::AllCells',
        caption => {
            title => {
                template_attr => 'title',
                class => 'some-class',
                id => 'caption-id',
                text => 'table caption',
            }
        },
        headers => {
            id => {
                template_attr => 'id',
                class => 'some-class',
                id => 'something-id',
                text => 'id',
            },
            name => {
                template_attr => 'name',
                class => 'okay',
                text => 'name',
            },
            address => {
                template_attr => 'address',
                class => 'what',
                text => 'address',
            }
        },
        table => {
            row_count => 3,
            header_count => 3,
        },
        first_header => {
            template_attr => 'id',
            class => 'some-class',
            id => 'something-id',
            text => 'id',
        },
        first_row => {
            cell_count => 3,
        },
        fr_first_cell => {
            text => '1',
            class => 'all_cells',
        },
        fr_last_cell => {
            text => 'somewhere',
            class => 'all_cells',
        },
        render => '<table><caption class="some-class" id="caption-id">table caption</caption><tr><th class="some-class" id="something-id">id</th><th class="okay">name</th><th class="what">address</th></tr><tr><td class="all_cells">1</td><td class="all_cells">rob</td><td class="all_cells">somewhere</td></tr><tr><td class="all_cells">2</td><td class="all_cells">sam</td><td class="all_cells">somewhere else</td></tr><tr><td class="all_cells">3</td><td class="all_cells">frank</td><td class="all_cells">out</td></tr></table>',
    });
};
 
subtest "odd_even_cells" => sub  {
    plan tests => 35;
    run_tests({
        class => 't::Templates::OddEvenCells',
        caption => {
            title => {
                template_attr => 'title',
                class => 'some-class',
                id => 'caption-id',
                text => 'table caption',
            }
        },
        headers => {
            id => {
                template_attr => 'id',
                class => 'some-class',
                id => 'something-id',
                text => 'id',
            },
            name => {
                template_attr => 'name',
                class => 'okay',
                text => 'name',
            },
            address => {
                template_attr => 'address',
                class => 'what',
                text => 'address',
            }
        },
        table => {
            row_count => 3,
            header_count => 3,
        },
        first_header => {
            template_attr => 'id',
            class => 'some-class',
            id => 'something-id',
            text => 'id',
        },
        first_row => {
            cell_count => 3,
        },
        fr_first_cell => {
            text => '1',
            class => 'odd',
        },
        fr_last_cell => {
            text => 'somewhere',
            class => 'odd',
        },
        render => '<table><caption class="some-class" id="caption-id">table caption</caption><tr><th class="some-class" id="something-id">id</th><th class="okay">name</th><th class="what">address</th></tr><tr><td class="odd">1</td><td class="even">rob</td><td class="odd">somewhere</td></tr><tr><td class="odd">2</td><td class="even">sam</td><td class="odd">somewhere else</td></tr><tr><td class="odd">3</td><td class="even">frank</td><td class="odd">out</td></tr></table>',
    });
};
 
subtest "index_nuts_cells" => sub  {
    plan tests => 36;
    run_tests({
        class => 't::Templates::IndexNutsCells',
        caption => {
            title => {
                template_attr => 'title',
                class => 'some-class',
                id => 'caption-id',
                text => 'table caption',
            }
        },
        headers => {
            id => {
                template_attr => 'id',
                class => 'some-class',
                id => 'something-id',
                text => 'id',
            },
            name => {
                template_attr => 'name',
                class => 'okay',
                text => 'name',
            },
            address => {
                template_attr => 'address',
                class => 'what',
                text => 'address',
            }
        },
        table => {
            row_count => 3,
            header_count => 3,
        },
        first_header => {
            template_attr => 'id',
            class => 'some-class',
            id => 'something-id',
            text => 'id',
        },
        first_row => {
            cell_count => 3,
        },
        fr_first_cell => {
            text => '1',
            class => 'nuts',
            id => 'first-row-first-cell',
        },
        fr_last_cell => {
            text => 'somewhere',
            id => 'first-row-last-cell',
        },
        render => '<table><caption class="some-class" id="caption-id">table caption</caption><tr><th class="some-class" id="something-id">id</th><th class="okay">name</th><th class="what">address</th></tr><tr><td class="nuts" id="first-row-first-cell">1</td><td>rob</td><td class="but-works" id="first-row-last-cell">somewhere</td></tr><tr><td>2</td><td>sam</td><td>somewhere else</td></tr><tr><td>3</td><td>frank</td><td>out</td></tr></table>',
    });
};
 
subtest "index_flag_cells" => sub  {
    plan tests => 36;
    run_tests({
        class => 't::Templates::IndexFlagCells',
        caption => {
            title => {
                template_attr => 'title',
                class => 'some-class',
                id => 'caption-id',
                text => 'table caption',
            }
        },
        headers => {
            id => {
                template_attr => 'id',
                class => 'some-class',
                id => 'something-id',
                text => 'id',
            },
            name => {
                template_attr => 'name',
                class => 'okay',
                text => 'name',
            },
            address => {
                template_attr => 'address',
                class => 'what',
                text => 'address',
            }
        },
        table => {
            row_count => 3,
            header_count => 3,
        },
        first_header => {
            template_attr => 'id',
            class => 'some-class',
            id => 'something-id',
            text => 'id',
        },
        first_row => {
            cell_count => 3,
        },
        fr_first_cell => {
            text => '1',
            class => 'nuts',
            id => 'first-row-first-cell',
        },
        fr_last_cell => {
            text => 'somewhere',
            id => 'first-row-last-cell',
        },
        render => '<table><caption class="some-class" id="caption-id">table caption</caption><tr><th class="some-class" id="something-id">id</th><th class="okay">name</th><th class="what">address</th></tr><tr><td class="nuts" id="first-row-first-cell">1</td><td>rob</td><td class="but-works" id="first-row-last-cell">somewhere</td></tr><tr><td>2</td><td>sam</td><td>somewhere else</td></tr><tr><td>3</td><td>frank</td><td>out</td></tr></table>',
    });
};
 
subtest "header_cells" => sub  {
    plan tests => 37;
    run_tests({
        class => 't::Templates::HeaderCells',
        caption => {
            title => {
                template_attr => 'title',
                class => 'some-class',
                id => 'caption-id',
                text => 'table caption',
            }
        },
        headers => {
            id => {
                template_attr => 'id',
                class => 'some-class',
                id => 'something-id',
                text => 'id',
            },
            name => {
                template_attr => 'name',
                class => 'okay',
                text => 'name',
            },
            address => {
                template_attr => 'address',
                class => 'what',
                text => 'address',
            }
        },
        table => {
            row_count => 3,
            header_count => 3,
        },
        first_header => {
            template_attr => 'id',
            class => 'some-class',
            id => 'something-id',
            text => 'id',
        },
        first_row => {
            cell_count => 3,
        },
        fr_first_cell => {
            text => '1',
            class => 'something',
            id => 'some-id-1',
        },
        fr_last_cell => {
            text => 'somewhere',
            class => 'else',
            id => 'some-other-id-1',
        },
        render => '<table><caption class="some-class" id="caption-id">table caption</caption><tr><th class="some-class" id="something-id">id</th><th class="okay">name</th><th class="what">address</th></tr><tr><td class="something" id="some-id-1">1</td><td>rob</td><td class="else" id="some-other-id-1">somewhere</td></tr><tr><td class="something" id="some-id-2">2</td><td>sam</td><td class="else" id="some-other-id-2">somewhere else</td></tr><tr><td class="something" id="some-id-3">3</td><td>frank</td><td class="else" id="some-other-id-3">out</td></tr></table>',
    });
};
 
subtest "Increment_rows" => sub  {
    plan tests => 35;
    run_tests({
        class => 't::Templates::IncrementRows',
        caption => {
            title => {
                template_attr => 'title',
                class => 'some-class',
                id => 'caption-id',
                text => 'table caption',
            }
        },
        headers => {
            id => {
                template_attr => 'id',
                class => 'some-class',
                id => 'something-id',
                text => 'id',
            },
            name => {
                template_attr => 'name',
                class => 'okay',
                text => 'name',
            },
            address => {
                template_attr => 'address',
                class => 'what',
                text => 'address',
            }
        },
        table => {
            row_count => 3,
            header_count => 3,
        },
        first_header => {
            template_attr => 'id',
            class => 'some-class',
            id => 'something-id',
            text => 'id',
        },
        first_row => {
            cell_count => 3,
            class => 'rows',
            id => 'row-id-1'
        },
        fr_first_cell => {
            text => '1',
        },
        fr_last_cell => {
            text => 'somewhere',
        },
        render => '<table><caption class="some-class" id="caption-id">table caption</caption><tr><th class="some-class" id="something-id">id</th><th class="okay">name</th><th class="what">address</th></tr><tr class="rows" id="row-id-1"><td>1</td><td>rob</td><td>somewhere</td></tr><tr class="rows" id="row-id-2"><td>2</td><td>sam</td><td>somewhere else</td></tr><tr class="rows" id="row-id-3"><td>3</td><td>frank</td><td>out</td></tr></table>',
    });
};
 
subtest "row_cells" => sub  {
    plan tests => 39;
    run_tests({
        class => 't::Templates::RowCells',
        caption => {
            title => {
                template_attr => 'title',
                class => 'some-class',
                id => 'caption-id',
                text => 'table caption',
            }
        },
        headers => {
            id => {
                template_attr => 'id',
                class => 'some-class',
                id => 'something-id',
                text => 'id',
            },
            name => {
                template_attr => 'name',
                class => 'okay',
                text => 'name',
            },
            address => {
                template_attr => 'address',
                class => 'what',
                text => 'address',
            }
        },
        table => {
            row_count => 3,
            header_count => 3,
        },
        first_header => {
            template_attr => 'id',
            class => 'some-class',
            id => 'something-id',
            text => 'id',
        },
        first_row => {
            cell_count => 3,
            class => 'rows',
            id => 'row-id-1'
        },
        fr_first_cell => {
            text => '1',
            class => 'text',
            id => 'first-row-cell-1'
        },
        fr_last_cell => {
            text => 'somewhere',
            class => 'text',
            id => 'first-row-cell-3'
        },
        render => '<table><caption class="some-class" id="caption-id">table caption</caption><tr><th class="some-class" id="something-id">id</th><th class="okay">name</th><th class="what">address</th></tr><tr class="rows" id="row-id-1"><td class="text" id="first-row-cell-1">1</td><td class="text" id="first-row-cell-2">rob</td><td class="text" id="first-row-cell-3">somewhere</td></tr><tr class="rows" id="row-id-2"><td>2</td><td>sam</td><td>somewhere else</td></tr><tr class="rows" id="row-id-3"><td>3</td><td>frank</td><td>out</td></tr></table>',
    });
};
 
subtest "alt_class_rows" => sub  {
    plan tests => 34;
    run_tests({
        class => 't::Templates::AltClassRows',
        caption => {
            title => {
                template_attr => 'title',
                class => 'some-class',
                id => 'caption-id',
                text => 'table caption',
            }
        },
        headers => {
            id => {
                template_attr => 'id',
                class => 'some-class',
                id => 'something-id',
                text => 'id',
            },
            name => {
                template_attr => 'name',
                class => 'okay',
                text => 'name',
            },
            address => {
                template_attr => 'address',
                class => 'what',
                text => 'address',
            }
        },
        table => {
            row_count => 3,
            header_count => 3,
        },
        first_header => {
            template_attr => 'id',
            class => 'some-class',
            id => 'something-id',
            text => 'id',
        },
        first_row => {
            cell_count => 3,
            class => 'first-class',
        },
        fr_first_cell => {
            text => '1',
        },
        fr_last_cell => {
            text => 'somewhere',
        },
        render => '<table><caption class="some-class" id="caption-id">table caption</caption><tr><th class="some-class" id="something-id">id</th><th class="okay">name</th><th class="what">address</th></tr><tr class="first-class"><td>1</td><td>rob</td><td>somewhere</td></tr><tr class="second-class"><td>2</td><td>sam</td><td>somewhere else</td></tr><tr class="first-class"><td>3</td><td>frank</td><td>out</td></tr></table>',
    });
};
 
subtest "alt_class_row_odd" => sub  {
    plan tests => 34;
    run_tests({
        class => 't::Templates::AltClassOddRows',
        caption => {
            title => {
                template_attr => 'title',
                class => 'some-class',
                id => 'caption-id',
                text => 'table caption',
            }
        },
        headers => {
            id => {
                template_attr => 'id',
                class => 'some-class',
                id => 'something-id',
                text => 'id',
            },
            name => {
                template_attr => 'name',
                class => 'okay',
                text => 'name',
            },
            address => {
                template_attr => 'address',
                class => 'what',
                text => 'address',
            }
        },
        table => {
            row_count => 3,
            header_count => 3,
        },
        first_header => {
            template_attr => 'id',
            class => 'some-class',
            id => 'something-id',
            text => 'id',
        },
        first_row => {
            cell_count => 3,
            class => 'first-class',
        },
        fr_first_cell => {
            text => '1',
        },
        fr_last_cell => {
            text => 'somewhere',
        },
        render => '<table><caption class="some-class" id="caption-id">table caption</caption><tr><th class="some-class" id="something-id">id</th><th class="okay">name</th><th class="what">address</th></tr><tr class="first-class"><td>1</td><td>rob</td><td>somewhere</td></tr><tr><td>2</td><td>sam</td><td>somewhere else</td></tr><tr class="second-class"><td>3</td><td>frank</td><td>out</td></tr></table>',
    });
};
 
subtest "alt_class_row_cells" => sub  {
    plan tests => 35;
    run_tests({
        class => 't::Templates::AltClassRowCells',
        caption => {
            title => {
                template_attr => 'title',
                class => 'some-class',
                id => 'caption-id',
                text => 'table caption',
            }
        },
        headers => {
            id => {
                template_attr => 'id',
                class => 'some-class',
                id => 'something-id',
                text => 'id',
            },
            name => {
                template_attr => 'name',
                class => 'okay',
                text => 'name',
            },
            address => {
                template_attr => 'address',
                class => 'what',
                text => 'address',
            }
        },
        table => {
            row_count => 3,
            header_count => 3,
        },
        first_header => {
            template_attr => 'id',
            class => 'some-class',
            id => 'something-id',
            text => 'id',
        },
        first_row => {
            cell_count => 3,
        },
        fr_first_cell => {
            text => '1',
            class => 'first-class',
        },
        fr_last_cell => {
            text => 'somewhere',
            class => 'first-class',
        },
        render => '<table><caption class="some-class" id="caption-id">table caption</caption><tr><th class="some-class" id="something-id">id</th><th class="okay">name</th><th class="what">address</th></tr><tr><td class="first-class">1</td><td class="second-class">rob</td><td class="first-class">somewhere</td></tr><tr><td>2</td><td>sam</td><td>somewhere else</td></tr><tr><td>3</td><td>frank</td><td>out</td></tr></table>',
    });
};
 
subtest "alt_class_all_cells" => sub  {
    plan tests => 35;
    run_tests({
        class => 't::Templates::AltClassCells',
        caption => {
            title => {
                template_attr => 'title',
                class => 'some-class',
                id => 'caption-id',
                text => 'table caption',
            }
        },
        headers => {
            id => {
                template_attr => 'id',
                class => 'some-class',
                id => 'something-id',
                text => 'id',
            },
            name => {
                template_attr => 'name',
                class => 'okay',
                text => 'name',
            },
            address => {
                template_attr => 'address',
                class => 'what',
                text => 'address',
            }
        },
        table => {
            row_count => 3,
            header_count => 3,
        },
        first_header => {
            template_attr => 'id',
            class => 'some-class',
            id => 'something-id',
            text => 'id',
        },
        first_row => {
            cell_count => 3,
        },
        fr_first_cell => {
            text => '1',
            class => 'first-class'
        },
        fr_last_cell => {
            text => 'somewhere',
            class => 'first-class'
        },
        render => '<table><caption class="some-class" id="caption-id">table caption</caption><tr><th class="some-class" id="something-id">id</th><th class="okay">name</th><th class="what">address</th></tr><tr><td class="first-class">1</td><td class="second-class">rob</td><td class="first-class">somewhere</td></tr><tr><td class="first-class">2</td><td class="second-class">sam</td><td class="first-class">somewhere else</td></tr><tr><td class="first-class">3</td><td class="second-class">frank</td><td class="first-class">out</td></tr></table>',
    });
};
 
 
subtest "alt_class_odd_cells" => sub  {
    plan tests => 33;
    run_tests({
        class => 't::Templates::AltClassOddCells',
        caption => {
            title => {
                template_attr => 'title',
                class => 'some-class',
                id => 'caption-id',
                text => 'table caption',
            }
        },
        headers => {
            id => {
                template_attr => 'id',
                class => 'some-class',
                id => 'something-id',
                text => 'id',
            },
            name => {
                template_attr => 'name',
                class => 'okay',
                text => 'name',
            },
            address => {
                template_attr => 'address',
                class => 'what',
                text => 'address',
            }
        },
        table => {
            row_count => 3,
            header_count => 3,
        },
        first_header => {
            template_attr => 'id',
            class => 'some-class',
            id => 'something-id',
            text => 'id',
        },
        first_row => {
            cell_count => 3,
        },
        fr_first_cell => {
            text => '1',
        },
        fr_last_cell => {
            text => 'somewhere',
        },
        render => '<table><caption class="some-class" id="caption-id">table caption</caption><tr><th class="some-class" id="something-id">id</th><th class="okay">name</th><th class="what">address</th></tr><tr><td class="first-class">1</td><td>rob</td><td class="second-class">somewhere</td></tr><tr><td class="first-class">2</td><td>sam</td><td class="second-class">somewhere else</td></tr><tr><td class="first-class">3</td><td>frank</td><td class="second-class">out</td></tr></table>',
    });
};
 
subtest "alt_class_header_cells" => sub  {
    plan tests => 35;
    run_tests({
        class => 't::Templates::AltClassHeaderCells',
        caption => {
            title => {
                template_attr => 'title',
                class => 'some-class',
                id => 'caption-id',
                text => 'table caption',
            }
        },
        headers => {
            id => {
                template_attr => 'id',
                class => 'some-class',
                id => 'something-id',
                text => 'id',
            },
            name => {
                template_attr => 'name',
                class => 'okay',
                text => 'name',
            },
            address => {
                template_attr => 'address',
                class => 'what',
                text => 'address',
            }
        },
        table => {
            row_count => 3,
            header_count => 3,
        },
        first_header => {
            template_attr => 'id',
            class => 'some-class',
            id => 'something-id',
            text => 'id',
        },
        first_row => {
            cell_count => 3,
        },
        fr_first_cell => {
            text => '1',
            class => 'first-head-first-class'
        },
        fr_last_cell => {
            text => 'somewhere',
            class => 'third-head-first-class'
        },
        render => '<table><caption class="some-class" id="caption-id">table caption</caption><tr><th class="some-class" id="something-id">id</th><th class="okay">name</th><th class="what">address</th></tr><tr><td class="first-head-first-class">1</td><td class="second-head-first-class">rob</td><td class="third-head-first-class">somewhere</td></tr><tr><td class="first-head-second-class">2</td><td class="second-head-second-class">sam</td><td class="third-head-second-class">somewhere else</td></tr><tr><td class="first-head-third-class">3</td><td class="second-head-third-class">frank</td><td class="third-head-third-class">out</td></tr></table>',
    });
};
 
subtest "nuts" => sub  {
    plan tests => 36;
    run_tests({
        class => 't::Templates::AltNuts',
        caption => {
            title => {
                template_attr => 'title',
                class => 'some-class',
                id => 'caption-id',
                text => 'table caption',
            }
        },
        headers => {
            id => {
                template_attr => 'id',
                class => 'some-class',
                id => 'something-id',
                text => 'id',
            },
            name => {
                template_attr => 'name',
                class => 'okay',
                text => 'name',
            },
            address => {
                template_attr => 'address',
                class => 'what',
                text => 'address',
            }
        },
        table => {
            row_count => 3,
            header_count => 3,
        },
        first_header => {
            template_attr => 'id',
            class => 'some-class',
            id => 'something-id',
            text => 'id',
        },
        first_row => {
            cell_count => 3,
            class => 'first-class'
        },
        fr_first_cell => {
            text => '1',
            class => 'first-head-first-class one nuts'
        },
        fr_last_cell => {
            text => 'somewhere',
            class => 'third-head-first-class three nuts'
        },
        render => '<table><caption class="some-class" id="caption-id">table caption</caption><tr><th class="some-class" id="something-id">id</th><th class="okay">name</th><th class="what">address</th></tr><tr class="first-class"><td class="first-head-first-class one nuts">1</td><td class="second-head-first-class two crazy">rob</td><td class="third-head-first-class three nuts">somewhere</td></tr><tr class="second-class"><td class="first-head-second-class nuts">2</td><td class="second-head-second-class crazy">sam</td><td class="third-head-second-class nuts">somewhere else</td></tr><tr class="third-class"><td class="first-head-third-class nuts">3</td><td class="second-head-third-class crazy">frank</td><td class="third-head-third-class nuts">out</td></tr></table>',
    });
};
 
done_testing();
 
sub run_tests {
    my $args = shift;
 
    my $class = $args->{class};
 
    my $template;
    if (my $data = $args->{data}) {
        $template = $class->new({ data => $data });
    } else {
        $template = $class->new();
    }
    my $exp_caption = $args->{caption};
 
    my @cap_keys = keys %{ $exp_caption };
    my $attr = $cap_keys[0];
    ok(my $caption = $template->$attr);
     
    while ( my ( $action, $expected ) = each %{ $exp_caption->{$attr} } ) {
        is($caption->$action, $expected, "$action expected $expected");
    }
 
    my $exp_headers = $args->{headers};
 
    my @head_keys = keys %{ $exp_headers };
 
    foreach my $key (@head_keys) {
        ok(my $header = $template->$key, "okay $key");
 
        while ( my ( $action, $expected ) = each %{ $exp_headers->{$key} } ) {
            is($header->$action, $expected, "$key - $action expected $expected");
        }
    }
 
    ok(my $table = $template->table, "okay get table");
    my $exp_table = $args->{table};
 
    while ( my ( $action, $expected ) = each %{ $exp_table } ) {
        is($table->$action, $expected, "$action expected $expected");
     }
 
    ok(my $first_header = $table->get_first_header, "okay get first header");
    my $exp_first_header = $args->{first_header};
    while ( my ( $action, $expected ) = each %{ $exp_first_header } ) {
        is($first_header->$action, $expected, "first header - $action expected $expected");
    }
 
    ok(my $first_row = $table->get_first_row, "okay get first row");
     
    my $exp_first_row = $args->{first_row};
    while ( my ( $action, $expected ) = each %{ $exp_first_row } ) {
        is($first_row->$action, $expected, "first row - $action expected $expected");
    }
 
    ok(my $first_cell = $first_row->get_first_cell, "okay get first cell");
 
    my $exp_first_cell = $args->{fr_first_cell};
    while ( my ( $action, $expected ) = each %{ $exp_first_cell } ) {
        is($first_cell->$action, $expected, "first row first cell - $action expected $expected");
    }
 
    ok(my $last_cell = $first_row->get_last_cell, "get last cell");
 
    my $exp_last_cell = $args->{fr_last_cell};
    while ( my ( $action, $expected ) = each %{ $exp_last_cell } ) {
        is($last_cell->$action, $expected, "first row last cell - $action expected $expected");
    }
 
    is($template->render, $args->{render}, "$args->{render}");
}
 
1;
