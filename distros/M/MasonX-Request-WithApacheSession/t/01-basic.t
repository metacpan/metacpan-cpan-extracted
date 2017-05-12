#!/usr/bin/perl -w

use strict;

use File::Path;
use File::Spec;
use HTML::Mason::Tests;

my $tests = make_tests();
$tests->run;

sub make_tests
{
    my $group =
	 HTML::Mason::Tests->new
	     ( name => 'basic-session',
	       description => 'Basic tests for Request::WithApacheSession subclass',
               pre_test_cleanup => 0,
             );

    my %params =
        ( request_class     => 'MasonX::Request::WithApacheSession',
          session_class     => 'Flex',
          session_store     => 'File',
          session_lock      => 'Null',
          session_generate  => 'MD5',
          session_serialize => 'Storable',
        );

    foreach ( [ session_directory => 'sessions' ],
	    )
    {
	my $dir = File::Spec->catfile( $group->data_dir, $_->[1] );
	mkpath($dir);

	$params{ $_->[0] } = $dir;
    }

    # will be used below in various ways
    use Apache::Session::Flex;
    my %session;
    tie %session, 'Apache::Session::Flex', undef,
        { Store     => 'File',
          Lock      => 'Null',
          Generate  => 'MD5',
          Serialize => 'Storable',
          Directory => $params{session_directory},
        };
    $session{bar}{baz} = 1;
    my $id = $session{_session_id};
    untie %session;

#------------------------------------------------------------

    $group->add_test
	( name => 'can_session',
	  description => 'make sure request->can("session")',
	  interp_params => \%params,
	  component => <<'EOF',
I <% $m->can('session') ? 'can' : 'cannot' %> session
EOF
	  expect => <<'EOF',
I can session
EOF
	);

#------------------------------------------------------------

    $group->add_test
	( name => 'isa_session',
	  description => 'make sure request->session->isa("Apache::Session")',
	  interp_params => \%params,
	  component => <<'EOF',
$m->session ref: <% ref $tied %>
<%init>
my $s = $m->session;
my $tied = tied(%$s);
</%init>
EOF
	  expect => <<'EOF',
$m->session ref: Apache::Session::Flex
EOF
	);

#------------------------------------------------------------

    $group->add_test
	( name => 'session_store',
	  description => 'store something in the session',
	  interp_params => \%params,
	  component => <<"EOF",
stored
<%init>
\$m->session( session_id => '$id' )->{foo} = 'bar';
</%init>
EOF
	  expect => <<'EOF',
stored
EOF
	);

#------------------------------------------------------------

    $group->add_test
	( name => 'session_read',
	  description => 'read stored data from the session',
	  interp_params => \%params,
	  component => <<"EOF",
read: <% \$m->session( session_id => '$id' )->{foo} %>
EOF
	  expect => <<'EOF',
read: bar
EOF
	);

#------------------------------------------------------------

    $group->add_test
	( name => 'session_allow_invalid',
	  description => 'test that session id can be invalid',
	  interp_params => \%params,
	  component => <<'EOF',
ok
<%init>
$m->session( session_id => 'abcdef' );
</%init>
EOF
	  expect => <<'EOF',
ok
EOF
	);

#------------------------------------------------------------

    $group->add_test
	( name => 'session_do_not_allow_invalid',
	  description => 'test that session id cannot be invalid',
	  interp_params => { %params,
			     session_allow_invalid_id => 0 },
	  component => <<'EOF',
<%init>
$m->session( session_id => 'abcdef' );
</%init>
EOF
	  expect_error => qr/Invalid session id/,
	);

#------------------------------------------------------------

    $group->add_test
	( name => 'session_always_write_on_1',
	  description => 'test always write (part 1)',
	  interp_params => \%params,
	  component => <<"EOF",
bar:baz: <% \$m->session( session_id => '$id' )->{bar}{baz} %>
<%init>
\$m->session( session_id => '$id' )->{bar}{baz} = 50;
</%init>
EOF
	  expect => <<'EOF',
bar:baz: 50
EOF
	);

#------------------------------------------------------------

    $group->add_test
	( name => 'session_always_write_2',
	  description => 'test always write (part 2)',
	  interp_params => \%params,
	  component => <<"EOF",
bar:baz: <% \$m->session( session_id => '$id' )->{bar}{baz} %>
EOF
	  expect => <<'EOF',
bar:baz: 50
EOF
	);

#------------------------------------------------------------

    $group->add_test
	( name => 'session_always_write_off_1',
	  description => 'test turning off always write (part 1)',
	  interp_params => { %params,
			     session_always_write => 0 },
	  component => <<"EOF",
bar:baz: <% \$m->session( session_id => '$id' )->{bar}{baz} %>
<%init>
\$m->session( session_id => '$id' )->{bar}{baz} = 100;
</%init>
EOF
	  expect => <<'EOF',
bar:baz: 100
EOF
	);

#------------------------------------------------------------

    $group->add_test
	( name => 'session_always_write_off_2',
	  description => 'test turning off always write (part 2)',
	  interp_params => { %params,
			     session_always_write => 0 },
	  component => <<"EOF",
bar:baz: <% \$m->session( session_id => '$id' )->{bar}{baz} %>
EOF
	  expect => <<'EOF',
bar:baz: 50
EOF
	);

#------------------------------------------------------------

    $group->add_support( path => '/as/subrequest',
                         component => <<'EOF',
foo: <% $m->session->{foo} %>
EOF
                       );

#------------------------------------------------------------

    $group->add_test( name => 'subrequest1',
                      description => 'Make sure session is shared with subrequests',
                      interp_params => \%params,
                      component => <<'EOF',
Parent
% $m->session->{foo} = 'bar';
% $m->subexec( '/basic-session/as/subrequest' );
EOF
                      expect => <<'EOF',
Parent
foo: bar
EOF
                    );

#------------------------------------------------------------

    $group->add_test
	( name => 'delete_session',
	  description => 'make sure delete_session method works',
	  interp_params => \%params,
	  component => <<'EOF',
% $m->session->{foo} = 'foo';
<% $m->session->{foo} %>
% $m->delete_session;
foo does <% exists $m->session->{foo} ? '' : 'not' %> exist
EOF
	  expect => <<'EOF',
foo
foo does not exist
EOF
	);

#------------------------------------------------------------

    return $group;
}
