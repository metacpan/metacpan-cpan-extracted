#!/usr/bin/perl -w

use strict;
use HTML::Mason::Tests;

my $tests = make_tests();
$tests->run;


sub make_tests
{
    my $group = HTML::Mason::Tests->new( name => 'component',
					 description => 'Component object functionality' );


#------------------------------------------------------------

    $group->add_test( name => 'context',
		      description => 'Tests list/scalar context propogation in comp calls',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',
Context checking:

List:\
<% my $discard = [$m->comp('.subcomp')]; %>\


Scalar:\
<% scalar $m->comp('.subcomp'); %>\


Scalar:\
<& .subcomp &>

<%def .subcomp>
<% $m->print( wantarray ? ('an','array') : 'scalar' ); %>\
</%def>
EOF
		      expect => <<'EOF',
Context checking:

List:
anarray

Scalar:
scalar

Scalar:
scalar

EOF
		    );


#------------------------------------------------------------

    $group->add_test( name => 'scomp',
		      description => 'Test scomp Request method',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',

<% my $text = $m->scomp('.subcomp', 1,2,3); %>\
-----
<%= $text %>

<%def .subcomp>
 Hello, you say <%= join '', @_ %>.
</%def>
EOF
		      expect => <<'EOF',

-----

 Hello, you say 123.


EOF
		    );


#------------------------------------------------------------

    $group->add_test( name => 'mfu_count',
		      description => 'Test mfu_count component method',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',
<%= $m->current_comp->mfu_count %>
<% $m->current_comp->mfu_count(75); %>\
<%= $m->current_comp->mfu_count %>
EOF
		      expect => <<'EOF',
1
75
EOF
		    );

#------------------------------------------------------------

    $group->add_test( name => 'store',
                      description => 'Test store parameter to component call',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
                      component => <<'EOF',

<% my $buffy; %>\
<% my $rtn; %>\
<% $rtn = $m->comp({store => \$buffy}, '.subcomp', 1,2,3,4); %>\
-----
<%= $buffy %>
returned <%= $rtn %>

<%def .subcomp>
 Hello, you say <%= join '', @_ %>.
<% return 'foo'; %>\
</%def>
EOF
                      expect => <<'EOF',

-----

 Hello, you say 1234.

returned foo

EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'flush_clear',
		      description => 'Flush then clear',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',
Foo
<% $m->flush_buffer; %>\
Bar
<% $m->clear_buffer; %>\
Baz
EOF
		      expect => <<'EOF',
Foo
Baz
EOF
		    );

#------------------------------------------------------------

    $group->add_support( path => 'flush_clear_filter_comp',
			 component => <<'EOF',
Foo
<% $m->flush_buffer; %>\
Bar
<% $m->clear_buffer; %>\
Baz
<%filter>
s/^/-/gm;
</%filter>
EOF
		       );

#------------------------------------------------------------

    $group->add_test( name => 'flush_clear_filter',
		      description => 'Flush then clear with filter section',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',
before
<& flush_clear_filter_comp &>
after
EOF
		      expect => <<'EOF',
before
-Foo
-Baz

after
EOF
		    );

#------------------------------------------------------------

    return $group;
}

