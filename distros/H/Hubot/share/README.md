# p5-hubot #

Perl 5
[AnyEvent](http://search.cpan.org/~mlehmann/AnyEvent-7.02/lib/AnyEvent.pm)
based [hubot](https://github.com/github/hubot) reimplementation.

![perl5](http://news.mynavi.jp/news/2011/03/02/009/images/001l.jpg)
![hubot](https://github-images.s3.amazonaws.com/blog/2011/hubot.png)

## Installation ##

- [CPAN](http://search.cpan.org)

        $ cpanm Hubot
        $ hubot --help

- [github](https://github.com)

        $ git clone git://github.com/aanoaa/p5-hubot.git
        $ cd p5-hubot/
        $ grep -Prho '^use +[^(?:Hubot)]([^ ;]+)' lib/ | perl -e 'while(<>) { $h{(split / /)[1]}++ } print keys %h' | cpanm
        $ perl -Ilib bin/hubot

## Configuration ##

Checkout each documentation what you will use for.
and describe each script name to `hubot-scripts.json`

## Deploy onto heroku ##

    https://github.com/aanoaa/heroku-buildpack-perl
