use Test::More tests => 6;

BEGIN { use_ok( 'HTML::TableParser' ); }

require './t/counts.pl';

%req = ( id => 'DEFAULT',
         start => \&start,
         end => \&end,
         hdr => \&hdr,
         row => \&row );

run(%req);
