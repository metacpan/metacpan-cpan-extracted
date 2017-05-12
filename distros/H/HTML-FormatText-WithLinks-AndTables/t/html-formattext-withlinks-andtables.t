use strict;
use HTML::FormatText::WithLinks::AndTables;
my $html = q|
<html>
    <body>
        <h1>BIG</h1>
        How's it going?<br/>
        How's it going?<br/>
        How's it going?<br/>

        How's it going?<br/>
        How's it going?<br/>
        How's it going?<br/>

<br/>
Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Donec hendrerit venenatis dolor. Suspendisse in neque id odio auctor porttitor. Cras adipiscing, orci in venenatis semper, nibh tortor posuere magna, ac blandit sapien purus et ligula. Proin et libero. Duis pellentesque, tellus a viverra pretium, lacus urna fermentum elit, et tempor nibh urna ac erat. Sed suscipit, enim in vulputate aliquam, mi ligula viverra enim, vitae mollis tortor metus ac sapien. Maecenas risus ligula, viverra eget, sagittis at, ultrices in, ante. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Nunc dictum. Praesent gravida neque quis odio. Mauris lacus nulla, iaculis eu, commodo sit amet, molestie sed, diam. In vel ligula.

        <table>
            <tr>
                <td align="right">
#1###<br/>
#2#########<br/>
#3###<br/>
#4###<br/>
#5###<br/>
                </td>
                <td>
%1%%%<br/>
%2%%%<br/>
%3%%%<br/>
%4%%%<br/>
%5%%%%%%%%%%%<br/>
                </td>
            </tr>
            <tr><td></td><td>booo!</td></tr>
            <tr>
                <td align="right">
#6###<br/>
#7#########<br/>
#8###<br/>
#9###<br/>
#10##<br/>
                </td>
                <td>
%6%%%<br/>
%7%%%<br/>
%8%%%<br/>
%9%%%<br/>
%10%%%%%%%%%%<br/>
                </td>
            </tr>
        </table>
    </body>
    <a href="http://xyz">http://xyz</a>
</html>|;
my $text = HTML::FormatText::WithLinks::AndTables->convert($html, {rm=>80,cellpadding=>2});
my $expected =
q|   BIG
   ===

   How's it going?
   How's it going?
   How's it going?
   How's it going?
   How's it going?
   How's it going?

   Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Donec hendrerit
   venenatis dolor. Suspendisse in neque id odio auctor porttitor. Cras
   adipiscing, orci in venenatis semper, nibh tortor posuere magna, ac blandit
   sapien purus et ligula. Proin et libero. Duis pellentesque, tellus a viverra
   pretium, lacus urna fermentum elit, et tempor nibh urna ac erat. Sed suscipit,
   enim in vulputate aliquam, mi ligula viverra enim, vitae mollis tortor metus
   ac sapien. Maecenas risus ligula, viverra eget, sagittis at, ultrices in,
   ante. Pellentesque habitant morbi tristique senectus et netus et malesuada
   fames ac turpis egestas. Nunc dictum. Praesent gravida neque quis odio. Mauris
   lacus nulla, iaculis eu, commodo sit amet, molestie sed, diam. In vel ligula.

              #1###    %1%%%             
        #2#########    %2%%%             
              #3###    %3%%%             
              #4###    %4%%%             
              #5###    %5%%%%%%%%%%%     

                       booo!             

              #6###    %6%%%             
        #7#########    %7%%%             
              #8###    %8%%%             
              #9###    %9%%%             
              #10##    %10%%%%%%%%%%     

   [1]http://xyz

   1. http://xyz


|;
use Test::More tests=>1;
is $text, $expected,
    'HTML::FormatText::WithLinks::AndTables->convert($html,{rm=>80,cellpadding=>2})';
