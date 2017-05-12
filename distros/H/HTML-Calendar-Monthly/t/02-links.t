#! perl

use strict;
use warnings;
use Test::More tests => 1;
use HTML::Calendar::Monthly;

my $cal = HTML::Calendar::Monthly->new( { year => 2009, month => 4 });

$cal->add_link( 5, "foo.html" );
$cal->add_link( 15, "bar.html" );

my $ref = do { local $/; <DATA> };
is( $cal->calendar_month, $ref, "empty calendar");

__END__
<table class='hc_month'>
  <tr>
    <th>Ma</th>
    <th>Di</th>
    <th>Wo</th>
    <th>Do</th>
    <th>Vr</th>
    <th>Za</th>
    <th>Zo</th>  </tr>
  <tr>
    <td class='hc_empty'></td>
    <td class='hc_empty'></td>
    <td class='hc_date'>1</td>
    <td class='hc_date'>2</td>
    <td class='hc_date'>3</td>
    <td class='hc_date'>4</td>
    <td class='hc_date_linked'><a href='foo.html'>5</a></td>
  </tr>
  <tr>
    <td class='hc_date'>6</td>
    <td class='hc_date'>7</td>
    <td class='hc_date'>8</td>
    <td class='hc_date'>9</td>
    <td class='hc_date'>10</td>
    <td class='hc_date'>11</td>
    <td class='hc_date'>12</td>
  </tr>
  <tr>
    <td class='hc_date'>13</td>
    <td class='hc_date'>14</td>
    <td class='hc_date_linked'><a href='bar.html'>15</a></td>
    <td class='hc_date'>16</td>
    <td class='hc_date'>17</td>
    <td class='hc_date'>18</td>
    <td class='hc_date'>19</td>
  </tr>
  <tr>
    <td class='hc_date'>20</td>
    <td class='hc_date'>21</td>
    <td class='hc_date'>22</td>
    <td class='hc_date'>23</td>
    <td class='hc_date'>24</td>
    <td class='hc_date'>25</td>
    <td class='hc_date'>26</td>
  </tr>
  <tr>
    <td class='hc_date'>27</td>
    <td class='hc_date'>28</td>
    <td class='hc_date'>29</td>
    <td class='hc_date'>30</td>
    <td class='hc_empty'></td>
    <td class='hc_empty'></td>
    <td class='hc_empty'></td>
  </tr>
</table>
