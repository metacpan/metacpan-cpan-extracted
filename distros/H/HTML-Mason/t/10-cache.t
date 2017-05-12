use strict;
use warnings;

use HTML::Mason::Tests;
use HTML::Mason::Tools;

# Skip if flock not implemented.
eval { my $fh = do { local *FH; *FH; }; open $fh, $0; flock $fh,1; };
if ($@)
{
    print "1..0 # Skipped: flock() is not available on this system\n";
    exit;
}

# Skip if Cache::FileCache not present.
eval { require Cache::FileCache };
if ($@)
{
    print "1..0 # Skipped: Cache::FileCache is not installed\n";
    exit;
}

my $tests = make_tests();
$tests->run;

sub make_tests
{
    my $group = HTML::Mason::Tests->tests_class->new( name => 'cache',
                                                      description => 'Test caching' );

#------------------------------------------------------------

    $group->add_test( name => 'cache_packages',
                      description => 'test that Mason cache packages get created',
                      component => <<'EOF',
% my $cache;
% $cache = $m->cache(cache_class=>'Cache::FileCache');
<% ref($cache) %>
<% $HTML::Mason::Cache::FileCache::VERSION + 0 %>
<% HTML::Mason::Tools::pkg_loaded('HTML::Mason::Cache::FileCache') ? 'loaded' : 'not loaded' %>
% $cache = $m->cache(cache_class=>'MemoryCache');
<% ref($cache) %>
<% $HTML::Mason::Cache::MemoryCache::VERSION + 0%>
<% HTML::Mason::Tools::pkg_loaded('HTML::Mason::Cache::FileCache') ? 'loaded' : 'not loaded' %>
EOF
                      expect => <<'EOF',
HTML::Mason::Cache::FileCache
1
loaded
HTML::Mason::Cache::MemoryCache
1
loaded
EOF
                    );

#------------------------------------------------------------

    $group->add_support( path => 'support/cache_test',
                         component => <<'EOF',
<% $result %>
This was<% $cached ? '' : ' not' %> cached.

<%init>
my $cached = 0;
my $result;
my $return;
unless ($result = $m->cache->get('fandango')) {
    $result = "Hello Dolly.";
    $return = $m->cache->set('fandango', $result) || '';
} else {
    $cached = 1;
}
</%init>
EOF
                       );


#------------------------------------------------------------

    $group->add_test( name => 'cache',
                      description => 'basic caching functionality',
                      component => <<'EOF',
% for (my $i=0; $i<3; $i++) {
<& support/cache_test &>
% }
EOF
                      expect => <<'EOF',
Hello Dolly.
This was not cached.


Hello Dolly.
This was cached.


Hello Dolly.
This was cached.


EOF
                    );


#------------------------------------------------------------

    $group->add_test( name => 'keys',
                      description => q|test multiple keys and $m->cache->get_keys|,
                      component => <<'EOF',
<%init>
foreach my $key (qw(foo bar baz)) {
    $m->cache->set($key, $key);
}
my @keys = sort $m->cache->get_keys;
$m->print("keys in cache: ".join(",",@keys)."\n");
foreach my $key (qw(foo bar baz)) {
    my $value = $m->cache->get($key) || "undefined";
    $m->print("value for $key is $value\n");
}
$m->cache->remove('foo');
$m->cache->remove('bar');
$m->print("expiring foo and bar...\n");
foreach my $key (qw(foo bar baz)) {
    my $value = $m->cache->get($key) || "undefined";
    $m->print("value for $key is $value\n");
}
</%init>
EOF
                      expect => <<'EOF',
keys in cache: bar,baz,foo
value for foo is foo
value for bar is bar
value for baz is baz
expiring foo and bar...
value for foo is undefined
value for bar is undefined
value for baz is baz
EOF
                    );

#------------------------------------------------------------

    $group->add_support ( path => 'support/cache_self',
                          component => <<'EOF',
x is <% $x %>
<%args>
$x
</%args>
<%init>
return if $m->cache_self;
</%init>
EOF
                        );

#------------------------------------------------------------

    $group->add_test( name => 'cache_self',
                      description => 'test $m->cache_self',
                      component => <<'EOF',
<& support/cache_self, x => 1 &>
<& support/cache_self, x => 99 &>
EOF
                      expect => <<'EOF',
x is 1

x is 1
EOF
                    );

#------------------------------------------------------------

    $group->add_support ( path => 'support/cache_self_expires_in',
                          component => <<'EOF',
x is <% $x %>
<%args>
$x
</%args>
<%init>
return if $m->cache_self( expires_in => '3s' );
</%init>
EOF
                        );

    $group->add_test( name => 'cache_self_expires_in',
                      description => 'test that $m->cache_self respects expires_in parameter',
                      component => <<'EOF',
<& support/cache_self_expires_in, x => 1 &>
<& support/cache_self_expires_in, x => 2 &>
% sleep 5;
<& support/cache_self_expires_in, x => 99 &>
EOF
                      expect => <<'EOF',
x is 1

x is 1

x is 99
EOF
                    );

#------------------------------------------------------------

    $group->add_support ( path => 'support/cache_self_expire_in',
                          component => <<'EOF',
x is <% $x %>
<%args>
$x
</%args>
<%init>
return if $m->cache_self( expire_in => '2s' );
</%init>
EOF
                        );

#------------------------------------------------------------

    $group->add_test( name => 'cache_self_expire_in',
                      description => 'test that $m->cache_self respects expire_in parameter',
                      component => <<'EOF',
<& support/cache_self_expire_in, x => 1 &>
<& support/cache_self_expire_in, x => 2 &>
% sleep 5;
<& support/cache_self_expire_in, x => 99 &>
EOF
                      expect => <<'EOF',
x is 1

x is 1

x is 99
EOF
                    );

#------------------------------------------------------------

    $group->add_support ( path => 'support/cache_self_expire_if',
                          component => <<'EOF',
x is <% $x %>
<%args>
$x
</%args>
<%init>
return if $m->cache_self( expire_if => sub { $x == 3 } );
</%init>
EOF
                        );

#------------------------------------------------------------

    $group->add_test( name => 'cache_self_expire_if',
                      description => 'test that $m->cache_self respects expire_if parameter',
                      component => <<'EOF',
<& support/cache_self_expire_if, x => 1 &>
<& support/cache_self_expire_if, x => 2 &>
<& support/cache_self_expire_if, x => 3 &>
<& support/cache_self_expire_if, x => 4 &>
EOF
                      expect => <<'EOF',
x is 1

x is 1

x is 3

x is 3
EOF
                    );

#------------------------------------------------------------

    $group->add_support ( path => 'support/cache_self_with_key',
                          component => <<'EOF',
x is <% $x %>
<%args>
$x
$key
</%args>
<%init>
return if $m->cache_self( key => $key );
</%init>
EOF
                        );

#------------------------------------------------------------

    $group->add_test( name => 'cache_self_key',
                      description => 'test $m->cache_self with a key',
                      component => <<'EOF',
<& support/cache_self_with_key, x => 1, key => 1 &>
<& support/cache_self_with_key, x => 99, key => 99 &>
<& support/cache_self_with_key, x => 1000, key => 1 &>
EOF
                      expect => <<'EOF',
x is 1

x is 99

x is 1
EOF
                    );

#------------------------------------------------------------

    $group->add_support ( path => 'support/cache_self_and_die',
                          component => <<'EOF',
<%init>
return if $m->cache_self;
die "argh!";
</%init>
EOF
                        );

#------------------------------------------------------------

    $group->add_test( name => 'cache_self_error',
                      description => 'test $m->cache_self with an error to make sure errors are propogated',
                      component => <<'EOF',
<& support/cache_self_and_die, x => 1, key => 1 &>
EOF
                      expect_error => qr/argh! at .*/,
                    );

#------------------------------------------------------------

    $group->add_test( name => 'cache_self_scomp',
                      description => 'make sure that $m->cache_self cooperates with $m->scomp',
                      component => <<'EOF',
<% $m->scomp( 'support/cache_self', x => 1 ) %>
<% $m->scomp( 'support/cache_self', x => 99 ) %>
EOF
                      expect => <<'EOF',
x is 1

x is 1
EOF
                    );

#------------------------------------------------------------

    $group->add_support ( path => 'support/cache_self_filtered',
                          component => <<'EOF',
x is <% $x %>
<%args>
$x
$key => 1
</%args>
<%init>
return if $m->cache_self( key => $key );
</%init>
<%filter>
$_ = uc $_;
$_ .= ' filtered';
</%filter>
EOF
                        );

#------------------------------------------------------------

    $group->add_test( name => 'cache_self_filtered',
                      description => 'test $m->cache_self with a filter block',
                      component => <<'EOF',
<& support/cache_self_filtered, x => 1 &>
<& support/cache_self_filtered, x => 99 &>
EOF
                      expect => <<'EOF',
X IS 1
 filtered
X IS 1
 filtered
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'cache_self_filtered_scomp',
                      description => 'test $m->cache_self with a filter block callled via $m->scomp',
                      component => <<'EOF',
<% $m->scomp( 'support/cache_self_filtered', key => 2, x => 1 ) %>
<% $m->scomp( 'support/cache_self_filtered', key => 2, x => 99 ) %>
EOF
                      expect => <<'EOF',
X IS 1
 filtered
X IS 1
 filtered
EOF
                    );

#------------------------------------------------------------

    $group->add_support ( path => 'support/cache_self_filtered_2',
                          component => <<'EOF',
x is <% $x %>
<%args>
$x
</%args>
<%init>
return if $m->cache_self;
</%init>
<%filter>
s/(\d+)/$1+1/ge;
</%filter>
EOF
                        );

#------------------------------------------------------------

    $group->add_test( name => 'cache_self_filtered_2',
                      description => 'make sure that results are only filtered once',
                      component => <<'EOF',
<& support/cache_self_filtered_2, x => 1 &>
<& support/cache_self_filtered_2, x => 99 &>
EOF
                      expect => <<'EOF',
x is 2

x is 2
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'expire_if',
                      description => 'test expire_if',
                      component => <<'EOF',
<% join(', ', $value1 || 'undef', $value2 || 'undef', $value3 || 'undef') %>
<%init>
my $time = time;
my $cache = $m->cache;
$cache->set('main', 'gardenia');
my $value1 = $cache->get('main', expire_if=>sub { $_[0]->get_created_at <= $time-1 });
my $value2 = $cache->get('main', expire_if=>sub { $_[0]->get_created_at >= $time });
my $value3 = $cache->get('main');
</%init>
EOF
                      expect => <<'EOF',
gardenia, undef, undef
EOF
                    );


#------------------------------------------------------------

    $group->add_test( name => 'busy_lock',
                      description => 'test busy_lock',
                      component => <<'EOF',
<% join(', ', $value1 || 'undef', $value2 || 'undef') %>
<%init>
my $time = time;
my $cache = $m->cache;
$cache->set('main', 'gardenia', 0);
my $value1 = $cache->get('main', busy_lock=>'10 sec');
my $value2 = $cache->get('main');
</%init>
EOF
                      expect => <<'EOF',
undef, gardenia
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'busy_lock_expiration',
                      description => 'test busy_lock expiration',
                      component => <<'EOF',
<% join(', ', $value1 || 'undef', $value2 || 'undef') %>
<%init>
my $time = time;
my $cache = $m->cache;
$cache->set('main', 'gardenia', 0);
my $value1 = $cache->get('main', busy_lock=>'1 sec');
sleep(1);
my $value2 = $cache->get('main');
</%init>
EOF
                      expect => <<'EOF',
undef, undef
EOF
                    );

#------------------------------------------------------------

    $group->add_support ( path => 'support/cache_self_die',
                          component => <<'EOF',
die
<%init>
return if $m->cache_self;
die 'foo';
</%init>
EOF
                        );

    $group->add_test( name => 'cache_self_death',
                      description => 'test $m->cache_self and death',
                      component => <<'EOF',
<%init>
$m->comp( 'support/cache_self_die' );
</%init>
EOF
                      expect_error => qr/foo at/,
                    );

#------------------------------------------------------------

    $group->add_support ( path => 'support/cache_self_abort2',
                          component => <<'EOF',
going to abort, a = <% $ARGS{a} %>
% $m->abort();
EOF
                        );

    $group->add_support( path => 'support/cache_self_abort',
                         component => <<'EOF',
<%init>
return if $m->cache_self;
$m->comp( 'cache_self_abort2', a=>5 );
</%init>
EOF
                       );

    $group->add_test( name => 'cache_self_abort',
                      description => 'test $m->cache_self and abort',
                      component => <<'EOF',
<%init>
eval { $m->comp( 'support/cache_self_abort', a=>5 ) };
eval { $m->comp( 'support/cache_self_abort', a=>10 ) };
</%init>
EOF
                      expect => <<'EOF'
going to abort, a = 5
going to abort, a = 5
EOF
                    );

#------------------------------------------------------------

    $group->add_support( path => 'support/cache_self_with_subexec2',
                         component => <<'EOF',
This is the subrequest, a = <% $ARGS{a} %>
EOF
                       );

    $group->add_support( path => 'support/cache_self_with_subexec',
                         component => <<'EOF',
% return if $m->cache_self;
% $m->subexec('cache_self_with_subexec2', a=>$ARGS{a});
EOF
                       );

    $group->add_test( name => 'cache_self_with_subexec',
                      description => 'test $m->subexec in presence of $m->cache_self',
                      component => <<'EOF',
<& support/cache_self_with_subexec, a=>5 &>
<& support/cache_self_with_subexec, a=>10 &>
EOF
                         expect => <<'EOF',
This is the subrequest, a = 5

This is the subrequest, a = 5
EOF
                    );

#------------------------------------------------------------

    $group->add_support( path => 'declined/dhandler',
                         component => <<'EOF',
decline was called
EOF
                       );

    $group->add_test( name => 'declined/cache_self_decline',
                      description => 'test $m->decline in presence of $m->cache_self',
                      component => <<'EOF',
% return if $m->cache_self;
% $m->decline;
EOF
                      expect => <<'EOF',
decline was called
EOF
                    );

#------------------------------------------------------------

    return $group;
}

