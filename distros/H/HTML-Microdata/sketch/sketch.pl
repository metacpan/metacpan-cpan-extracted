#!/usr/bin/env perl

use utf8;
use strict;
use warnings;
use lib lib => glob 'modules/*/lib';

use HTML::Microdata;


my $microdata = HTML::Microdata->extract(<<EOF);
<body itemscope itemtype="http://microformats.org/profile/hcalendar#vevent">
 ...
 <h1 itemprop="summary">Bluesday Tuesday: Money Road</h1>
 ...
 <time itemprop="dtstart" datetime="2009-05-05T19:00:00Z">May 5th @ 7pm</time>
 (until <time itemprop="dtend" datetime="2009-05-05T21:00:00Z">9pm</time>)
 ...
 <a href="http://livebrum.co.uk/2009/05/05/bluesday-tuesday-money-road"
    rel="bookmark" itemprop="url">Link to this page</a>
 ...
 <p>Location: <span itemprop="location">The RoadHouse</span></p>
 ...
 <p><input type=button value="Add to Calendar"
           onclick="location = getCalendar(this)"></p>
 ...
 <meta itemprop="description" content="via livebrum.co.uk">
</body>
EOF

use Data::Dumper;
warn Dumper $microdata->as_json;
