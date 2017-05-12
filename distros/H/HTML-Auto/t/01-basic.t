#!perl -T

use Test::More tests => 5;
use HTML::Auto qw/matrix h v/;
use Data::Dumper;

my $tests = {
  'simple h test' => {
    test => "h('l','r')",
    gold => '<div> <div style="float: left;">l</div> <div style="float: left;">r</div> <span style="clear: both;"></div> </div>'
  },
  'simple v test' => {
    test => "v('u','d')",
    gold => '<div>u</div> <div>d</div>'
  },
  'simple matrix test' => {
    test => 'matrix([qw/c1 c2/],[qw/l1 l2/],[ [1,0], [0,1] ])',
    gold => '<style type="text/css"> span.vertical { -webkit-transform: rotate(180deg); -moz-transform: rotate(180deg); transform: rotate(180deg); writing-mode: tb-rl; filter: flipv fliph; display: block; width: 20px; white-space: nowrap; } table.auto th { padding-top: 24px; padding-bottom: 10px; padding-left: 5px; padding-right: 5px; width: 20px; background-color: #aaaaaa; } table.auto td { text-align: center; width: 30px; background-color: #eeeeee; padding: 6px; } table.auto td.fst { width: 80px; font-weight: bold; background-color: #aaaaaa; padding: 5px; } th.empty { background-color: white !important; } table.auto td.mid { background-color: #cccccc; } td:hover { background-color: #aaaaaa; } td.more_info { position:relative; z-index:24; text-decoration:none; cursor: default; color: black; width: 80px; } td.more_info:hover{ z-index:25; } td.more_info td { width: auto; } td.more_info span { display: none; } td.more_info:hover span { display:block; position:absolute; border:1px solid #ccc; min-width:24em; background-color:#fff; color:#000; text-align: left; font-size: 80%; text-decoration: none; } </style> <table class="auto"> <tr> <th class="empty"> </th> <th> <span class="vertical">c1</span></th> <th> <span class="vertical">c2</span></th> </tr> <tr> <td class="fst">l1</td> <td >1 </td> <td >0 </td> </tr> <tr> <td class="fst">l2</td> <td >0 </td> <td >1 </td> </tr> </table>'
  },
  'simple matrix test (with highlighted diagonal)' => {
    test => 'matrix([qw/c1 c2/],[qw/l1 l2/],[ [1,0], [0,1] ],{diagonal=>1})',
    gold => '<style type="text/css"> span.vertical { -webkit-transform: rotate(180deg); -moz-transform: rotate(180deg); transform: rotate(180deg); writing-mode: tb-rl; filter: flipv fliph; display: block; width: 20px; white-space: nowrap; } table.auto th { padding-top: 24px; padding-bottom: 10px; padding-left: 5px; padding-right: 5px; width: 20px; background-color: #aaaaaa; } table.auto td { text-align: center; width: 30px; background-color: #eeeeee; padding: 6px; } table.auto td.fst { width: 80px; font-weight: bold; background-color: #aaaaaa; padding: 5px; } th.empty { background-color: white !important; } table.auto td.mid { background-color: #cccccc; } td:hover { background-color: #aaaaaa; } td.more_info { position:relative; z-index:24; text-decoration:none; cursor: default; color: black; width: 80px; } td.more_info:hover{ z-index:25; } td.more_info td { width: auto; } td.more_info span { display: none; } td.more_info:hover span { display:block; position:absolute; border:1px solid #ccc; min-width:24em; background-color:#fff; color:#000; text-align: left; font-size: 80%; text-decoration: none; } </style> <table class="auto"> <tr> <th class="empty"> </th> <th> <span class="vertical">c1</span></th> <th> <span class="vertical">c2</span></th> </tr> <tr> <td class="fst">l1</td> <td class="mid" >1 </td> <td >0 </td> </tr> <tr> <td class="fst">l2</td> <td >0 </td> <td class="mid" >1 </td> </tr> </table>'
	},
  'matrix with pop-up test and highlighted diagonal' => {
	test => 'matrix([qw/c1 c2/],[qw/l1 l2/], [ [1,2], [3, { v=> 4, more_info => "This is a pop-up!" }]],{diagonal=>1})',
	gold => '<style type="text/css"> span.vertical { -webkit-transform: rotate(180deg); -moz-transform: rotate(180deg); transform: rotate(180deg); writing-mode: tb-rl; filter: flipv fliph; display: block; width: 20px; white-space: nowrap; } table.auto th { padding-top: 24px; padding-bottom: 10px; padding-left: 5px; padding-right: 5px; width: 20px; background-color: #aaaaaa; } table.auto td { text-align: center; width: 30px; background-color: #eeeeee; padding: 6px; } table.auto td.fst { width: 80px; font-weight: bold; background-color: #aaaaaa; padding: 5px; } th.empty { background-color: white !important; } table.auto td.mid { background-color: #cccccc; } td:hover { background-color: #aaaaaa; } td.more_info { position:relative; z-index:24; text-decoration:none; cursor: default; color: black; width: 80px; } td.more_info:hover{ z-index:25; } td.more_info td { width: auto; } td.more_info span { display: none; } td.more_info:hover span { display:block; position:absolute; border:1px solid #ccc; min-width:24em; background-color:#fff; color:#000; text-align: left; font-size: 80%; text-decoration: none; } </style> <table class="auto"> <tr> <th class="empty"> </th> <th> <span class="vertical">c1</span></th> <th> <span class="vertical">c2</span></th> </tr> <tr> <td class="fst">l1</td> <td class="mid" >1 </td> <td >2 </td> </tr> <tr> <td class="fst">l2</td> <td >3 </td> <td class="more_info mid" >4 <span>This is a pop-up!</span> </td> </tr> </table>',
  },
};

foreach (keys %$tests) {
  ok(run($tests->{$_}->{test}) eq $tests->{$_}->{gold}, $_);
}

sub run {
    clean(eval $_[0]);
}

sub clean {
  my ($str) = @_;
  $str =~ s/^\s+|\s+$//sg;
  $str =~ s/\s+/ /sg;
  return $str;
}
