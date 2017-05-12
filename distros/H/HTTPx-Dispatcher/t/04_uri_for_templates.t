use strict;
use warnings;
use Test::Base;
use YAML;
use HTTPx::Dispatcher;
use HTTPx::Dispatcher::Rule;
use HTTP::Request;

plan tests => 1*blocks;

filters {
    dispatcher => [qw/_eval/],
    uri_for    => [qw/eval/],
    expected   => [qw//],
};

run {
    my $block = shift;
    my $dispatcher = $block->dispatcher;
    is $dispatcher->uri_for( $block->uri_for ), $block->expected;
}

my $cnt = 1;
sub _eval {
    my ($input, ) = @_;
    my $pkg = "t::Dispatcher::" . ++$cnt;

    eval <<"...";
    package $pkg;
    use HTTPx::Dispatcher;
    $input;
...

    return $pkg;
}

__END__

===
--- dispatcher: connect '/{controller}/{action}/{id}';
--- uri_for:    {controller => 'blog', action => 'show', id => 3}
--- expected:   /blog/show/3

===
--- dispatcher: connect '/blog/{action}/{id}';
--- uri_for:    {action => 'show', id => 3}
--- expected:   /blog/show/3

===
--- dispatcher
connect '/blog/{action}/{id}';
connect '/{controller}/{action}/{id}';
--- uri_for:    {controller => 'entry', action => 'show', id => 3}
--- expected:   /entry/show/3

===
--- dispatcher
connect '/content/{id}' => { controller => 'Content', action => 'show'  };
--- uri_for:  { controller => 'Content', action => 'show', 'id' => 3 }
--- expected:   /content/3

===
--- dispatcher
connect '/' => { controller => 'Root', action => 'index'  };
--- uri_for:  { controller => 'Root', action => 'index' }
--- expected:   /

