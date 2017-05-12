#!/usr/bin/env perl

use strict;
use warnings;
use JavaScript::Writer;
use Test::More;

plan tests => 2;


SKIP: {
    skip "Need to implement/design tie interface", 2;

    {
        my $js = tie my %js, "JavaScript::Writer";

        $js{"lightbox"}->show;

        is $js->as_string(), q{lightbox.show();}
    }

    {
        my $js =tie my %js, "JavaScript::Writer";

        $js{"Widget.Lightbox"}->show("Hey Jude");

        is $js->as_string(), q{Widget.Lightbox.show("Hey Jude");}
    }

}
