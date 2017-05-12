use strict;
use warnings;
use Test::Base;
use YAML;
use HTTPx::Dispatcher;
use HTTP::Request;
use t::MockAPREQ;

plan tests => 2*blocks;

filters {
    dispatcher    => [qw/_proc/],
    expected => [qw//],
};

run {
    my $block = shift;

    for my $req ( _apache_req($block), _http_req($block)) {
        my $res = $block->dispatcher->match( $req );
        $res = ((not defined $res) ? 'undef' : YAML::Dump($res));
        $res =~ s/^---\n//;
        is $res, $block->expected;
    }
};

sub _apache_req {
    my $block = shift;
    my $method = $block->method || 'GET';
    (my $uri = $block->uri) =~ s/\?.+//;
    t::MockAPREQ->new(uri => $uri, method => $method);
}

sub _http_req {
    my $block = shift;
    my $method = $block->method || 'GET';
    my $uri = "http://example.com/" . $block->uri;
    HTTP::Request->new($method, $uri);
}

my $cnt = 1;
sub _proc {
    my ($input, ) = @_;
    my $pkg = "t::Dispatcher::" . ++$cnt;
    eval <<"...";
    package $pkg;
    use HTTPx::Dispatcher;
    $input;
...

    $pkg;
}

__END__

===
--- dispatcher
connect '/', { controller => 'Root', action => 'index' }
--- uri: /
--- expected
action: index
args: {}
controller: Root

===
--- dispatcher
connect '/articles/{year}/{month}' => {
    controller => 'blog',
    action     => 'view',
};
--- uri: /articles/2003/10
--- expected
action: view
args:
  month: 10
  year: 2003
controller: blog

===
--- dispatcher
connect '/articles/{year}/{month}' => {
    controller => 'blog',
    action     => 'view',
};
--- uri: /articles/2003/10
--- expected
action: view
args:
  month: 10
  year: 2003
controller: blog

===
--- dispatcher: connect '/{controller}/{action}/{id}';
--- uri: /user/edit/2
--- expected
action: edit
args:
  id: 2
controller: user

===
--- dispatcher
connect '/articles/{year}/{month}' => {
    controller => 'blog',
    action     => 'view',
    requirements => {
        year  => qr{\d{2,4}},
        month => qr{\d{1,2}},
    }
};
--- uri: /articles/2003/10
--- expected
action: view
args:
  month: 10
  year: 2003
controller: blog

===
--- dispatcher: connect '/{controller}/{action}-{id}'
--- uri: /user/edit-3
--- expected
action: edit
args:
  id: 3
controller: user

===
--- dispatcher
connect '/edit' => {
    conditions => {
        method => 'GET',
    },
    controller => 'user',
    action => 'get_root',
};
connect '/edit' => {
    conditions => {
        method => 'POST',
    },
    controller => 'user',
    action => 'post_root',
};
--- uri: /edit
--- method: GET
--- expected
action: get_root
args: {}
controller: user

===
--- dispatcher
    connect '/edit' => {
        conditions => {
            method => 'GET',
        },
        controller => 'user',
        action => 'get_root',
    };
    connect '/edit' => {
        conditions => {
            method => 'POST',
        },
        controller => 'user',
        action => 'post_root',
    };
--- uri: /edit
--- method: POST
--- expected
action: post_root
args: {}
controller: user

=== function condition(1)
--- dispatcher
    connect '/edit' => {
        conditions => {
            function => sub { $_->method =~ /get/i },
        },
        controller => 'user',
        action => 'get_root',
    };
    connect '/edit' => {
        conditions => {
            function => sub { $_->method =~ /post/i },
        },
        controller => 'user',
        action => 'post_root',
    };
--- uri: /edit
--- method: POST
--- expected
action: post_root
args: {}
controller: user

=== function condition(2)
--- dispatcher
    connect '/edit' => {
        conditions => {
            function => sub { $_->method =~ /get/i },
        },
        controller => 'user',
        action => 'get_root',
    };
    connect '/edit' => {
        conditions => {
            function => sub { $_->method =~ /post/i },
        },
        controller => 'user',
        action => 'post_root',
    };
--- uri: /edit
--- method: GET
--- expected
action: get_root
args: {}
controller: user

=== with query
--- dispatcher
    connect '/articles/{year}/{month}' => {
        controller => 'blog',
        action     => 'view',
    };
--- uri: /articles/2003/10?query=foo
--- expected
action: view
args:
  month: 10
  year: 2003
controller: blog
