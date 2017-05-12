use warnings;
use strict;
use lib 't';
use Test::More tests => 4;
use_ok('HTML::Template::Compiled');
use HTC_Utils qw($cache $tdir &cdir);
$HTML::Template::Compiled::MAX_RECURSE = 10; # default

{
    my $htc = HTML::Template::Compiled->new(
        path => $tdir,
        filename => "recurse.html",
        debug    => 0,
    );


    $htc->param(
        content => "1",
        child => { content => "2",
            child => { content => "3",
                child => { content => "4",
                    child => { content => "5",
                        child => { content => "6",
                            child => { content => "7",
                                child => { content => "8",
                                    child => { content => "9",
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    );
    my $out = $htc->output;
    cmp_ok($out, '=~', qr#((content: (?:\d+)).*){9}#s, "recursive ok");
    for my $max (9, 15) {
    my $out;
    eval {
    $HTML::Template::Compiled::MAX_RECURSE = $max;
    $htc->clear_params;
    $htc->param(
        content => "1",
        child => { content => "2",
            child => { content => "3",
                child => { content => "4",
                    child => { content => "5",
                        child => { content => "6",
                            child => { content => "7",
                                child => { content => "8",
                                    child => { content => "9",
                                        child => { content => "10",
                                            child => { content => "11" },
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    );
    $out = $htc->output;
    };
    #print "error: $@\n";
    #print "out: $out\n";
    if ($max == 9) {
        ok($@ && $@ =~ m/recu/, "max recursion 10 > $max");
    }
    else {
        cmp_ok($out, '=~', qr#((content: (?:\d+)).*){11}#s, "max recursion 10 < $max");
    }
    }
}


