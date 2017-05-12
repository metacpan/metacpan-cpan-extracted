# hubot-adapter-mypeople #

![preview](https://pbs.twimg.com/media/BLhHYKaCUAAacSm.png:small)

Interface to the
[mypeople](https://mypeople.daum.net/mypeople/web/main.do) service for
[p5-hubot](http://search.cpan.org/~aanoaa/Hubot/lib/Hubot.pm)

## Installation ##

    $ cpanm Hubot::Adapter::Mypeople

## Run ##

    $ export HUBOT_MYPEOPLE_APIKEY='YOUR API KEY HERE'
    $ export HUBOT_MYPEOPLE_CALLBACK_PATH='/hubot/callback'    # default /
    $ hubot -a mypeople
