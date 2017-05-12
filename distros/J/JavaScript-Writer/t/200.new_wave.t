#!/usr/bin/env perl

use strict;
use warnings;

use JavaScript::Writer;
use Test::More;

plan tests => 11;

{
    js->new;
    js("true")->do(sub {
        js->alert(42);
    });

    is js->as_string, "if(true){alert(42);}";
}


{
    js->new;
    js->while("true", sub {
        js->alert(42);
    });

    is js->as_string, qq{while(true){alert(42);}};
}

{
    js->new;
    js("Widget.Lightbox")->show("Nihao");
    is js->as_string, qq{Widget.Lightbox.show("Nihao");};
}

{
    js->new;
    js("3s")->latter(
        sub {
            js->alert(42);
            js("1s")->latter(
                sub {
                    js->alert(43);
                }
            );
            js->alert(44);
        }
    );

    is js->as_string, "setTimeout(function(){alert(42);setTimeout(function(){alert(43);}, 1000);alert(44);}, 3000);";
};

{
    js->new;
    js("3s")->latter(
        sub {
            $_[0]->alert(42);
        }
    );

    is js->as_string, "setTimeout(function(){alert(42);}, 3000);"
};

{
    js->new;

    js("3s")->latter(
        sub {
            js->alert(42);
        }
    );

    is js->as_string, "setTimeout(function(){alert(42);}, 3000);"
};

{
    js->alert(42);
    js->new->alert(43);

    is js->as_string, "alert(43);"
};

{
    js->alert(42);
    js->new;
    js->alert(43);

    is js->as_string, "alert(43);"
};

{
    js->new->let(a => "foo", b => 3);
    is js->as_string, q{var a = "foo";var b = 3;};
}

{
    js->new->let(a => sub { $_[0]->alert(42); });
    is js->as_string, q{var a = function(){alert(42);};};
}


{
    js->new;

    js->let( a => \ "b");

    is js->as_string, q{var a = b;};
}

