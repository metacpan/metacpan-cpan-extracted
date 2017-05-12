#!perl
#
# popular-browsers.t
#
# confirm that module is working 'correctly' for popular browsers
use strict;
use warnings;

use Test::More 0.88 tests => 5;
use HTTP::Headers::UserAgent;

my @data =
(

    {
        label   => 'Chrome 15 on WinNT',
        ua      => 'Mozilla/5.0 (Windows NT 5.1) AppleWebKit/535.2 (KHTML, like Gecko) Chrome/15.0.872.0 Safari/535.2',
        browser => 'Chrome',
        version => '15.0',
        os      => 'winnt',
    },

    {
        label   => 'Safari 4.1 on MacOS',
        ua      => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_7; en-us) AppleWebKit/533.4 (KHTML, like Gecko) Version/4.1 Safari/533.4',
        browser => 'Safari',
        version => '4.1',
        os      => 'macos',
    },

    {
        label   => 'Internet Explorer 9 on WinNT',
        ua      => 'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0; SLCC2; Media Center PC 6.0; InfoPath.3; MS-RTC LM 8; Zune 4.7)',
        browser => 'IE',
        version => '9.0',
        os      => 'winnt',
    },

    {
        label   => 'Opera 10.6 on Linux',
        ua      => 'Opera/9.80 (X11; Linux i686; U; en) Presto/2.5.27 Version/10.60',
        browser => 'Opera',
        version => '10.60',
        os      => 'linux',
    },

    {
        label   => 'Firefox 4.2 on Linux',
        ua      => 'Mozilla/5.0 (X11; Linux x86_64; rv:2.2a1pre) Gecko/20110324 Firefox/4.2a1pre',
        browser => 'Firefox',
        version => '4.2',
        os      => 'linux',
    },

);
my ($ua_string, $ua);

foreach my $datum (@data)
{
    $ua_string = $datum->{'ua'};
    $ua = HTTP::Headers::UserAgent->new($ua_string);
    ok(   defined($ua)
       && $ua->browser eq $datum->{'browser'}
       && $ua->version eq $datum->{'version'}
       && $ua->os      eq $datum->{'os'},
       $datum->{'label'});
}

exit 0;

