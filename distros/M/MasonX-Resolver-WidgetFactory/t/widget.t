use strict;
use warnings;

use MasonX::Resolver::WidgetFactory;
use MasonX::Resolver::Multiplex;
use HTML::Mason::Resolver::File;
use HTML::Mason::Tests;

my $tests = make_tests();
$tests->run;

{ 
  package HTML::Mason::Commands;
  sub _make_interp { $tests->_make_interp(@_) }
}

sub make_tests {
  my $group = HTML::Mason::Tests->tests_class->new(
    name => "widget",
    description => "WidgetFactory resolver tests",
  );

  my $ip = sub {
    return {
      resolver => MasonX::Resolver::Multiplex->new(
        resolvers => [
          MasonX::Resolver::WidgetFactory->new(
            prefix => '/w',
            @_,
          ),
          HTML::Mason::Resolver::File->new,
        ],
      )
    };
  };

  $group->add_test(
    name => 'basic',
    description => 'basic functionality test',
    interp_params => $ip->(),
    component => <<'',
<& /w/input, id => "test" &>

    expect => <<'',
<input id="test" name="test" />

  );

  $group->add_test(
    name => 'missing',
    description => 'request for missing widget',
    interp_params => $ip->(),
    component => <<'',
<& /w/no_such &>,

    expect_error => qr/could not find component for path/,
  );

  $group->add_test(
    name => 'missing',
    description => 'request for missing widget',
    interp_params => $ip->(strict => 1),
    component => <<'',
<& /w/no_such &>,

    expect_error => qr/factory does not provide/,
  );

  $group->add_test(
    name => 'content_default',
    description => 'cwc -- default param',
    interp_params => $ip->(),
    component => <<'',
<&| /w/link, href => 'http://test.com' &><span>My Link</span></&>

    expect => <<'',
<a href="http://test.com"><span>My Link</span></a>

  );

  $group->add_test(
    name => 'content_explicit',
    description => 'cwc -- explicit param',
    interp_params => $ip->(),
    component => <<'',
<&| /w/link, href => 'http://test.com', -content => 'text' &>"Hello"</&>

    expect => <<'',
<a href="http://test.com">&quot;Hello&quot;</a>

  );

  $group->add_test(
    name => 'content_missing',
    description => 'cwc -- no param',
    interp_params => $ip->(),
    component => <<'',
<&| /w/input, name => "test" &>Test value</&>

    expect_error => qr/no -content argument given/,
  );

  return $group;
}
