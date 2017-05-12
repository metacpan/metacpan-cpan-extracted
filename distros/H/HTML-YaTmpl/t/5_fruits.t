use warnings;
use Test::More tests => 37;
use HTML::YaTmpl;
my $t=HTML::YaTmpl->new( onerror=>'die', path=>['templates'] );

sub x {
  $t->template=$_[1];
  my $rc=$t->evaluate( fruits=>[qw(apples pears plums cherries)],
		       fruit_colors=>[[qw{apples red/green}],
				      [qw{pears green}],
				      [qw{plums blue/yellow}],
				      [qw{cherries red}]],
		       orange_array=>['an orange'],
		       orange=>'an orange',
		       grape=>[] );
#  warn "-------------------\n$rc-------------------\n";
  ok($rc eq $_[2],$_[0]);
}

x( 'some fruits',
   <<'EOF',
 fruits comprise
 <ul>
 <=fruits><li><:/></li>
 </=fruits></ul>
EOF
   <<'EOF' );
 fruits comprise
 <ul>
 <li>apples</li>
 <li>pears</li>
 <li>plums</li>
 <li>cherries</li>
 </ul>
EOF

x( 'fruits, men and women',
   <<'EOF',
 <=fruits><:/> and <:/> give <:/>
 </=fruits>but
 men and women give children
EOF
   <<'EOF' );
 apples and apples give apples
 pears and pears give pears
 plums and plums give plums
 cherries and cherries give cherries
 but
 men and women give children
EOF

x( 'fruits, men and women 2',
   <<'EOF',
<=fruits><:"$v and $v give $v\n"/></=fruits>but
men and women give children
EOF
   <<'EOF' );
apples and apples give apples
pears and pears give pears
plums and plums give plums
cherries and cherries give cherries
but
men and women give children
EOF

x( 'enumerated fruits',
   <<'EOF',
 <=fruits><: ++$p->{fruitcounter} />. <:/>
 </=fruits>total: <:$p->{fruitcounter}/> fruits
EOF
   <<'EOF' );
 1. apples
 2. pears
 3. plums
 4. cherries
 total: 4 fruits
EOF

x( 'more enumerated fruits',
   <<'EOF',
 <=fruits code="<: ++$p->{fruitcounter} />. <:/>
 "/>total: <:$p->{fruitcounter}/> fruits
EOF
   <<'EOF' );
 1. apples
 2. pears
 3. plums
 4. cherries
 total: 4 fruits
EOF

x( 'a table of fruits',
   <<'EOF',
 <html><body>
 <table>
 <=fruits code="<tr><td><: ++$p->{fruitcounter} /></td><td><:/></td></tr>"/>
 <tr><td>total number of fruits</td><td><:$p->{fruitcounter}/></td></tr>
 </table>
 </body></html>
EOF
   <<'EOF' );
 <html><body>
 <table>
 <tr><td>1</td><td>apples</td></tr><tr><td>2</td><td>pears</td></tr><tr><td>3</td><td>plums</td></tr><tr><td>4</td><td>cherries</td></tr>
 <tr><td>total number of fruits</td><td>4</td></tr>
 </table>
 </body></html>
EOF

x( 'obfuscated code=...',
   <<'EOF',
 <=fruits code="<li><:\"\\u$v\"/></li>"/>
EOF
   <<'EOF' );
 <li>Apples</li><li>Pears</li><li>Plums</li><li>Cherries</li>
EOF

x( 'even more obfuscated code=...',
   <<'EOF',
 <=fruits code=\<li\>\<:\"\\u$v\"/\>\</li\>/>
EOF
   <<'EOF' );
 <li>Apples</li><li>Pears</li><li>Plums</li><li>Cherries</li>
EOF

x( 'last / first code',
   <<'EOF',
 <=fruits first="<: ucfirst $v/>" last=" and <:/>" code=", <:/>"/>
 are fruits.
EOF
   <<'EOF' );
 Apples, pears, plums and cherries
 are fruits.
EOF

x( 'pre / post code',
   <<'EOF',
<=fruits pre="<select name=\"fruit\"><:\"\\n\"/>"
         code="<option><:/></option><:\"\\n\"/>"
         post="</select>"/>
EOF
   <<'EOF' );
<select name="fruit">
<option>apples</option>
<option>pears</option>
<option>plums</option>
<option>cherries</option>
</select>
EOF

x( 'last / first code 2',
   <<'EOF',
 <=fruits>
 <:first><:"\u$v"/></:first>
 <:last> and <:/></:last>
 <:code>, <:/></:code>
 </=fruits>
 are fruits.
EOF
   <<'EOF' );
 Apples, pears, plums and cherries
 are fruits.
EOF

x( 'pre / post code 2',
   <<'EOF',
 <=fruits>
 <:pre><select name="fruit">
 </:pre>
 <:post></select></:post>
 <:code><option><:/></option>
 </:code>
 </=fruits>
EOF
   <<'EOF' );
 <select name="fruit">
 <option>apples</option>
 <option>pears</option>
 <option>plums</option>
 <option>cherries</option>
 </select>
EOF

x( 'simple sort',
   <<'EOF',
 <=fruits sort="$a cmp $b">
 <:code><:/>, </:code>
 <:last><:/></:last>
 </=fruits>
EOF
   <<'EOF' );
 apples, cherries, pears, plums
EOF

x( 'map sort',
   <<'EOF',
 <=fruits map="scalar reverse $_" sort="$a cmp $b">
 <:code><:/>, </:code>
 <:last><:/></:last>
 </=fruits>
EOF
   <<'EOF' );
 seirrehc, selppa, smulp, sraep
EOF

x( 'map sort map',
   <<'EOF',
 <=fruits map="scalar reverse $_"
          sort="$a cmp $b"
          map="scalar reverse $_">
 <:code><:/>, </:code>
 <:last><:/></:last>
 </=fruits>
EOF
   <<'EOF' );
 cherries, apples, plums, pears
EOF

x( 'grep map sort map',
   <<'EOF',
 <=fruits grep="!/plum/i"
          map="scalar reverse $_"
          sort="$a cmp $b"
          map="scalar reverse $_">
 <:code><:/>, </:code>
 <:last><:/></:last>
 </=fruits>
EOF
   <<'EOF' );
 cherries, apples, pears
EOF

x( 'mixed short/long form',
   <<'EOF',
 <=fruits grep="!/plum/i">
 <:map>scalar reverse $_</:map>
 <:sort>$a cmp $b</:sort>
 <:code><:/>, </:code>
 <:last><:/></:last>
 </=fruits>
EOF
   <<'EOF' );
 seirrehc, selppa, sraep
EOF

x( 'real world example',
   <<'EOF',
 <=orange type=empty><input type="text" name="orange"></=orange>
 <=orange type=array pre="<select name=\"orange\">"
                   post="</select>">
 <option><:/></option>
 </=orange>
 <=orange type=scalar><b><:/></b></=orange>

 <=grape type=empty><input type="text" name="grape"></=grape>
 <=grape type=array pre="<select name=\"grape\">"
                   post="</select>">
 <option><:/></option>
 </=grape>
 <=grape type=scalar><b><:/></b></=grape>

 <=fruits type=empty><input type="text" name="fruit"></=fruits>
 <=fruits type=array pre="<select name=\"fruit\">"
                   post="</select>">
 <option><:/></option>
 </=fruits>
 <=fruits type=scalar><b><:/></b></=fruits>
EOF
   <<'EOF' );
 
 
 <b>an orange</b>

 <input type="text" name="grape">
 
 

 
 <select name="fruit">
 <option>apples</option>
 
 <option>pears</option>
 
 <option>plums</option>
 
 <option>cherries</option>
 </select>
 
EOF

x( 'real world 2',
   <<'EOF',
 <:for n="<:[qw/orange grape fruits/]/>" :inherit><=n><:eval :inherit><# this
 is a comment to skip the newline from the newly generated template
 /><=<:/> type=empty><input type="text" name="<:/>">
 </=<:/>><#>
 This is just another comment
 </#><=<:/> type=array pre="<select name=\"<:/>\">
 "
                       post="</select>"><:#klaus/>
 <<#/>:code>   <option><<#/>:/></option><:>#otto</:>
 </<#/>:code>
 </=<:/>><# comment
 /><=<:/> type=scalar><b><<#/>:/></b>
 </=<:/>></:eval></=n></:for>
EOF
   <<'EOF' );
 <b>an orange</b>
 <input type="text" name="grape">
 <select name="fruits">
    <option>apples</option>
    <option>pears</option>
    <option>plums</option>
    <option>cherries</option>
 </select>
EOF
#"

x( 'for many fruits',
   <<'EOF',
 <:for many_fruits="many <=fruits/>">
 <:code><=many_fruits><li><:/></li>
 </=many_fruits></:code>
 </:for>
EOF
   <<'EOF' );
 <li>many apples</li>
 <li>many pears</li>
 <li>many plums</li>
 <li>many cherries</li>
 
EOF

x( 'fruit colors',
   <<'EOF',
 <table>
 <=fruit_colors type=array><:for f="<:/>">
 <:code><tr><=f><td><:/></td></=f></tr>
 </:code>
 </:for></=fruit_colors></table>
EOF
   <<'EOF' );
 <table>
 <tr><td>apples</td><td>red/green</td></tr>
 <tr><td>pears</td><td>green</td></tr>
 <tr><td>plums</td><td>blue/yellow</td></tr>
 <tr><td>cherries</td><td>red</td></tr>
 </table>
EOF

x( 'fruit colors 2',
   <<'EOF',
 <table>
 <=fruit_colors type=array><:for f="<:/>"><tr><=f><td><:/></td></=f></tr>
 </:for></=fruit_colors></table>
EOF
   <<'EOF' );
 <table>
 <tr><td>apples</td><td>red/green</td></tr>
 <tr><td>pears</td><td>green</td></tr>
 <tr><td>plums</td><td>blue/yellow</td></tr>
 <tr><td>cherries</td><td>red</td></tr>
 </table>
EOF

x( 'fruit colors 3',
   <<'EOF',
 <table>
 <=fruit_colors type=array><:for f="<:/>">
 <tr><=f><td><:/></td></=f></tr>
 </:for></=fruit_colors></table>
EOF
   <<'EOF' );
 <table>
 
 <tr><td>apples</td><td>red/green</td></tr>
 
 <tr><td>pears</td><td>green</td></tr>
 
 <tr><td>plums</td><td>blue/yellow</td></tr>
 
 <tr><td>cherries</td><td>red</td></tr>
 </table>
EOF

x( '<:for> with an one element array',
   <<'EOF',
 <:for a="<=orange_array pre="pre" post="post"/>">
 <:code><=a code="(<:/>)"/></:code>
 </:for>
EOF
   <<'EOF' );
 (pre)(an orange)(post)
EOF

x( '<:for> with 2 4 element lists expanding to 16 elements total',
   <<'EOF',
 <:for a="PRE <=fruits pre=pre1
                       post=post1
                       grep=\"/l/\"/> <#
          />BETWEEN <=fruits pre=pre2
                             post=post2
                             grep=\"/r/\"/> POST">
 <:code><=a last="(<:/>)">(<:/>)
 </=a></:code>
 </:for>
EOF
   <<'EOF' );
 (PRE pre1 BETWEEN pre2 POST)
 (PRE pre1 BETWEEN pears POST)
 (PRE pre1 BETWEEN cherries POST)
 (PRE pre1 BETWEEN post2 POST)
 (PRE apples BETWEEN pre2 POST)
 (PRE apples BETWEEN pears POST)
 (PRE apples BETWEEN cherries POST)
 (PRE apples BETWEEN post2 POST)
 (PRE plums BETWEEN pre2 POST)
 (PRE plums BETWEEN pears POST)
 (PRE plums BETWEEN cherries POST)
 (PRE plums BETWEEN post2 POST)
 (PRE post1 BETWEEN pre2 POST)
 (PRE post1 BETWEEN pears POST)
 (PRE post1 BETWEEN cherries POST)
 (PRE post1 BETWEEN post2 POST)
EOF

SKIP: {
skip "Math::BigInt not installed", 1 unless eval { require Math::BigInt; };

x( 'square and cube numbers and factorials',
   <<'EOF',
 <:>
 sub fac {
   use Math::BigInt;
   my $x=shift;
   my $res=Math::BigInt->new(1);
   for( my $i=1; $i<=$x; $i++ ) {
     $res*=$i;
   }
   return $res;
 }
 </:><html><body>
 <table>
 <:for x="<:[map {[$_, $_**2, $_**3, fac $_]} 1..30]/>"
       h="<:[qw{n n^2 n^3 n!}]/>">
 <:code>
     <tr>
       <=h><th><:/></th> </=h>
     </tr>
   <=x>
     <:code>
       <tr>
         <:for y="<:/>">
           <:code><=y><td><:/></td> </=y></:code>
         </:for>
       </tr>
     </:code>
   </=x></:code>
 </:for></table>
 </body></html>
EOF
   <<'EOF' );
 <html><body>
 <table>
 
     <tr>
       <th>n</th> <th>n^2</th> <th>n^3</th> <th>n!</th> 
     </tr>
   
       <tr>
         <td>1</td> <td>1</td> <td>1</td> <td>1</td> 
       </tr>
     
       <tr>
         <td>2</td> <td>4</td> <td>8</td> <td>2</td> 
       </tr>
     
       <tr>
         <td>3</td> <td>9</td> <td>27</td> <td>6</td> 
       </tr>
     
       <tr>
         <td>4</td> <td>16</td> <td>64</td> <td>24</td> 
       </tr>
     
       <tr>
         <td>5</td> <td>25</td> <td>125</td> <td>120</td> 
       </tr>
     
       <tr>
         <td>6</td> <td>36</td> <td>216</td> <td>720</td> 
       </tr>
     
       <tr>
         <td>7</td> <td>49</td> <td>343</td> <td>5040</td> 
       </tr>
     
       <tr>
         <td>8</td> <td>64</td> <td>512</td> <td>40320</td> 
       </tr>
     
       <tr>
         <td>9</td> <td>81</td> <td>729</td> <td>362880</td> 
       </tr>
     
       <tr>
         <td>10</td> <td>100</td> <td>1000</td> <td>3628800</td> 
       </tr>
     
       <tr>
         <td>11</td> <td>121</td> <td>1331</td> <td>39916800</td> 
       </tr>
     
       <tr>
         <td>12</td> <td>144</td> <td>1728</td> <td>479001600</td> 
       </tr>
     
       <tr>
         <td>13</td> <td>169</td> <td>2197</td> <td>6227020800</td> 
       </tr>
     
       <tr>
         <td>14</td> <td>196</td> <td>2744</td> <td>87178291200</td> 
       </tr>
     
       <tr>
         <td>15</td> <td>225</td> <td>3375</td> <td>1307674368000</td> 
       </tr>
     
       <tr>
         <td>16</td> <td>256</td> <td>4096</td> <td>20922789888000</td> 
       </tr>
     
       <tr>
         <td>17</td> <td>289</td> <td>4913</td> <td>355687428096000</td> 
       </tr>
     
       <tr>
         <td>18</td> <td>324</td> <td>5832</td> <td>6402373705728000</td> 
       </tr>
     
       <tr>
         <td>19</td> <td>361</td> <td>6859</td> <td>121645100408832000</td> 
       </tr>
     
       <tr>
         <td>20</td> <td>400</td> <td>8000</td> <td>2432902008176640000</td> 
       </tr>
     
       <tr>
         <td>21</td> <td>441</td> <td>9261</td> <td>51090942171709440000</td> 
       </tr>
     
       <tr>
         <td>22</td> <td>484</td> <td>10648</td> <td>1124000727777607680000</td> 
       </tr>
     
       <tr>
         <td>23</td> <td>529</td> <td>12167</td> <td>25852016738884976640000</td> 
       </tr>
     
       <tr>
         <td>24</td> <td>576</td> <td>13824</td> <td>620448401733239439360000</td> 
       </tr>
     
       <tr>
         <td>25</td> <td>625</td> <td>15625</td> <td>15511210043330985984000000</td> 
       </tr>
     
       <tr>
         <td>26</td> <td>676</td> <td>17576</td> <td>403291461126605635584000000</td> 
       </tr>
     
       <tr>
         <td>27</td> <td>729</td> <td>19683</td> <td>10888869450418352160768000000</td> 
       </tr>
     
       <tr>
         <td>28</td> <td>784</td> <td>21952</td> <td>304888344611713860501504000000</td> 
       </tr>
     
       <tr>
         <td>29</td> <td>841</td> <td>24389</td> <td>8841761993739701954543616000000</td> 
       </tr>
     
       <tr>
         <td>30</td> <td>900</td> <td>27000</td> <td>265252859812191058636308480000000</td> 
       </tr>
     </table>
 </body></html>
EOF
}				# SKIP

x( '<:for> with 2 4 element lists with <:set>',
   <<'EOF',
 <:for>
 <:set inner_fruits>PRE <=fruits pre=pre1
                                 post=post1
                                 grep="/l/"/> <#
                  />BETWEEN <=fruits pre=pre2
                                     post=post2
                                     grep="/r/"/> POST</:set>
 <:code><=inner_fruits last="(<:/>)">(<:/>)
 </=inner_fruits></:code>
 </:for>
EOF
   <<'EOF' );
 (PRE pre1 BETWEEN pre2 POST)
 (PRE pre1 BETWEEN pears POST)
 (PRE pre1 BETWEEN cherries POST)
 (PRE pre1 BETWEEN post2 POST)
 (PRE apples BETWEEN pre2 POST)
 (PRE apples BETWEEN pears POST)
 (PRE apples BETWEEN cherries POST)
 (PRE apples BETWEEN post2 POST)
 (PRE plums BETWEEN pre2 POST)
 (PRE plums BETWEEN pears POST)
 (PRE plums BETWEEN cherries POST)
 (PRE plums BETWEEN post2 POST)
 (PRE post1 BETWEEN pre2 POST)
 (PRE post1 BETWEEN pears POST)
 (PRE post1 BETWEEN cherries POST)
 (PRE post1 BETWEEN post2 POST)
EOF

x( '<:eval>',
   <<'EOF',
 <:for fruits="<:[qw/apple pear/]/>"
       books="<:['The Silmarillion',
                 'The Lord of the Rings',
                 'The Hobbit or There And Back Again']/>"><#
 /><:eval what="<:[qw/book fruit/]/>"><#
 /><=what><#
 /><=<:/>s>
 <<#/>:pre>Select a <: ucfirst $v />:
 <select name="<:/>">
 <<#/>/:pre>
 <<#/>:post></select>
 <<#/>/:post>
 <<#/>:code><option><<#/>:/></option>
 <<#/>/:code>
 </=<:/>s><#
 /></=what><#
 /></:eval><#
 /></:for>
EOF
   <<'EOF' );
 Select a Book:
 <select name="book">
 <option>The Silmarillion</option>
 <option>The Lord of the Rings</option>
 <option>The Hobbit or There And Back Again</option>
 </select>
 Select a Fruit:
 <select name="fruit">
 <option>apple</option>
 <option>pear</option>
 </select>
 
EOF

x( 'eval without <:eval>',
   <<'EOF',
 <:for fruits="<:[qw/apple pear/]/>"
       books="<:['The Silmarillion',
                 'The Lord of the Rings',
                 'The Hobbit or There And Back Again']/>"><#
 /><:for what="<:[qw/book fruit/]/>" :inherit><#
 /><=what><#
 />Select a <: ucfirst $v />:
 <select name="<:/>">
 <:for el="<:$h->{$v.'s'}/>" :inherit><#
 /><=el>
 <:code><option><:/></option>
 </:code>
 </=el></select>
 </:for><#
 /></=what><#
 /></:for><#
 /></:for>
EOF
   <<'EOF' );
 Select a Book:
 <select name="book">
 <option>The Silmarillion</option>
 <option>The Lord of the Rings</option>
 <option>The Hobbit or There And Back Again</option>
 </select>
 Select a Fruit:
 <select name="fruit">
 <option>apple</option>
 <option>pear</option>
 </select>
 
EOF

x( 'bargain buy',
   <<'EOF',
 <:for>
 <:set goods><:
 [
  [apple=>'300'],
  [pear=>'90'],
  [cherry=>'82'],
  [plum=>'120'],
 ]
 /></:set>
 <:code><=goods pre="<table>" post="
 </table>">
 <tr><:for x="<:/>"><=x><td><:/></td></=x></:for><td><:cond>
 <:case "$v->[1]>150"><b>very expensive</b></:case>
 <:case "$v->[1]<100"><b>bargain</b></:case>
 <:case 1>normal prize</:case>
 </:cond></td></tr></=goods></:code>
 </:for>
EOF
   <<'EOF' );
 <table>
 <tr><td>apple</td><td>300</td><td><b>very expensive</b></td></tr>
 <tr><td>pear</td><td>90</td><td><b>bargain</b></td></tr>
 <tr><td>cherry</td><td>82</td><td><b>bargain</b></td></tr>
 <tr><td>plum</td><td>120</td><td>normal prize</td></tr>
 </table>
EOF

x( 'thumbnails',
   <<'EOF',
 <:include thumb.tmpl name=img321 link=yes/>
 <:include thumb.tmpl name=img322/>
EOF
   <<'EOF' );
  
   <a href="orig/img321.jpg"><img src="img321.jpg"></a>
 

  
   <img src="img322.jpg">
 

EOF
$t->clear_errors;

SKIP: {
 skip "ENOENT not defined",
      1
   unless( eval {
     require Errno;
     require File::Spec;
     exists($!{ENOENT});
   } );

 $!=&Errno::ENOENT;
 my $msg="$!";
 $!=0;
 eval {
   $t->template=<<'EOF',
<:include notexists.tmpl/>
EOF
   $t->evaluate;
 };
 ok( $@=~/^\QERROR while eval( <:include notexists.tmpl> ): $msg\E/,
     'including non-existing file' );
 $t->clear_errors;
}

SKIP: {
 skip "EISDIR or EACCES not defined",
      1
   unless( eval {
     require Errno;
     require File::Spec;
     exists($!{EISDIR}) or exists($!{EACCES});
   } );

 my $dir=File::Spec->curdir;
 $!=&Errno::EISDIR;
 $msg="$!";
 $!=&Errno::EACCES;
 my $msg1="$!";
 $!=0;
 eval {
   $t->template=<<"EOF",
<:include "$dir"/>
EOF
   $t->evaluate;
 };
 ok( ($@=~/^\QERROR while eval( <:include $dir> ): $msg\E/ or
      $@=~/^\QERROR while eval( <:include $dir> ): $msg1\E/),
     'including directory' );
 $t->clear_errors;
}

x( 'macro bargain buy',
   <<'EOF',
 <:defmacro td><td align="center"><=val/></td></:defmacro><#
 /><:defmacro tr><tr><:for x="<:/>"><#
 /><=x><:m td val="<:/>"/></=x></:for><:macro td>
 <:set val><:cond>
 <:case "$v->[1]>150"><b>very expensive</b></:case>
 <:case "$v->[1]<100"><b>bargain</b></:case>
 <:case 1>normal prize</:case>
 </:cond></:set>
 </:macro></tr> </:defmacro><#
 /><:for>
 <:set goods><:
 [
  [apple=>'300'],
  [pear=>'90'],
  [cherry=>'82'],
  [plum=>'120'],
 ]
 /></:set>
 <:code><=goods pre="<table>" post="
 </table>">
 <:m tr/></=goods></:code>
 </:for>
EOF
   <<'EOF' );
 <table>
 <tr><td align="center">apple</td><td align="center">300</td><td align="center"><b>very expensive</b></td></tr> 
 <tr><td align="center">pear</td><td align="center">90</td><td align="center"><b>bargain</b></td></tr> 
 <tr><td align="center">cherry</td><td align="center">82</td><td align="center"><b>bargain</b></td></tr> 
 <tr><td align="center">plum</td><td align="center">120</td><td align="center">normal prize</td></tr> 
 </table>
EOF

x( 'another macro bargain buy',
   <<'EOF',
 <:for>
 <:set goods><:
 [
  [apple=>'300'],
  [pear=>'90'],
  [cherry=>'82'],
  [plum=>'120'],
 ]
 /></:set>
 <:code><=goods pre="<table>" post="
 </table>">
 <:m tr/></=goods></:code>
 </:for>
EOF
   <<'EOF' );
 <table>
 <tr><td align="center">apple</td><td align="center">300</td><td align="center"><b>very expensive</b></td></tr> 
 <tr><td align="center">pear</td><td align="center">90</td><td align="center"><b>bargain</b></td></tr> 
 <tr><td align="center">cherry</td><td align="center">82</td><td align="center"><b>bargain</b></td></tr> 
 <tr><td align="center">plum</td><td align="center">120</td><td align="center">normal prize</td></tr> 
 </table>
EOF

x( 'yet another macro bargain buy',
   <<'EOF',
 <:set goods><:
 [
  [apple=>'300'],
  [pear=>'90'],
  [cherry=>'82'],
  [plum=>'120'],
 ]
 /></:set><=goods pre="<table>" post="
 </table>">
 <:m tr/></=goods>
EOF
   <<'EOF' );
 <table>
 <tr><td align="center">apple</td><td align="center">300</td><td align="center"><b>very expensive</b></td></tr> 
 <tr><td align="center">pear</td><td align="center">90</td><td align="center"><b>bargain</b></td></tr> 
 <tr><td align="center">cherry</td><td align="center">82</td><td align="center"><b>bargain</b></td></tr> 
 <tr><td align="center">plum</td><td align="center">120</td><td align="center">normal prize</td></tr> 
 </table>
EOF

x( '<:set> inside <:code>',
   <<'EOF',
<:for x="<=fruits/>"><:code><=x><:set n><=n>.<:/></=n></:set><=n/> <:/>
</=x></:code></:for>
EOF
   <<'EOF' );
. apples
.. pears
... plums
.... cherries

EOF

__END__

x( '',
   <<'EOF',
EOF
   <<'EOF' );
EOF

# Local Variables:
# mode: cperl
# End:
