#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use HTML::Make::Calendar 'calendar';
use File::Slurper 'write_text';
my $css =<<EOF;
<style>
.cal-month {
display:grid;
grid-template-columns: repeat(7, fr);
}
.cal-day {
list-style-type: none;
height: 2em;
}
.cal-mon {
grid-column-start: 1;
background: #fe9;
}
.cal-tue {
grid-column-start: 2;
background: #9ef;
}
.cal-wed {
grid-column-start: 3;
background: #e9f;
}
.cal-thu {
grid-column-start: 4;
background: #f9e;
}
.cal-fri {
grid-column-start: 5;
background: #9fe;
}
.cal-sat {
grid-column-start: 6;
background: #9f9;
}
.cal-sun {
grid-column-start: 7;
background: #979;
}

</style>
EOF
my $cal = calendar (weekless => 1, month_html => 'ul', day_html => 'li');
my $text = $css . $cal->text ();
write_text ('/usr/local/www/data/weekless.html', $text);

