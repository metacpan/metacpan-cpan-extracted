#!/usr/bin/perl -w

use lib '.'; use lib 't';
use WMTest; webmake_t_init("csvtable");
use Test; BEGIN { plan tests => 7 };

# ---------------------------------------------------------------------------

%patterns = (

q{<table> <tr> <td> this </td> <td> is
</td> <td> a </td> <td> test}, 'csv1',

q{<td> this </td> </tr> <tr> <th> a </th> <th>
title </th> <th> line </th> <th> cool </th> </tr>}, 'csv2',


q{<td> that's plenty </td> <td> i </td> <td>
should </td> <td> think </td> </tr> </table>}, 'csv3',

);

# ---------------------------------------------------------------------------

ok (wmrun ("-F -f data/$testname.wmk", \&patterns_run_cb));
ok_all_patterns();

