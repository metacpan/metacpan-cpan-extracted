package MyTestView;

use Markapl;

template "/foo.html" => sub {
    outs "foo.html output";
};

template "/foo/bar.html" => sub {
    outs "bar.html output";
};


template '/rowcell.html' => sub {
    table {
        row {
            cell { "HI" }
        }
    }
};

sub linklist {
    my @link = @_;
    ul {
        for my $l (@link) {
            li {
                a( href => $l->[1] ) { $l->[0] }
            };
        }
    };
}

template '/linklist.html' => sub {
    html {
        head { title { "Test" } };
        body {
            h1 { "Hi" };

            linklist(
                ["Currency", "/currency"],
                ["Foo", "/foo"],
            );
        }
    };
};

template '/var-in-attribute.html' => sub {
    my $root = "/foo";
    ul {
        li { a(href => $root) { "Home" }; };
        li { a(href => "$root/fun") { "Have Fun" }; };
        li { a(href => "$root/logout") { "Logout" }; };
    }
};

template '/perlbuiltin.html' => sub {
    html_q { "Here is a short quotation here is a short quotation" };
};

template '/stash1.html' => sub {
    my $title = get("title");
    h1 { $title };
};

template '/undef-attribute-value.html' => sub {
    script(async => undef, src => "foo.js");
};

1;
