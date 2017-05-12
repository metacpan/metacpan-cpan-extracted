#!/usr/bin/perl -w

use strict;

use HTML::Mason::Tests;

my $tests = make_tests();
$tests->run;

sub make_tests
{
    my $group = HTML::Mason::Tests->new( name => 'errors',
					 description => 'Test that errors are generated properly' );

#------------------------------------------------------------

    $group->add_support( path => '/support/error_helper',
			 component => <<'EOF',
<%init>
eval { $m->comp('error1')  };
$m->comp('error2');
</%init>
EOF
		       );

#------------------------------------------------------------

    $group->add_support( path => '/support/error1',
			 component => <<'EOF',
<% die "terrible error"; %>\
EOF
		       );

#------------------------------------------------------------

    $group->add_support( path => '/support/error2',
			 component => <<'EOF',
<% die "horrible error";			  %>\
EOF
		       );

#------------------------------------------------------------

    $group->add_test( name => '_make_error',
		      description => 'Exercise possible failure for Parser.pm _make_error method',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',
<%args>
foo
</%args>
EOF
		      expect_error => qr|Invalid <%args> section line|
		    );

#------------------------------------------------------------

    $group->add_test( name => 'backtrace',
		      description => 'Make sure trace for second error is accurate when first error is caught by eval',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',
<%init>
$m->comp('support/error_helper');
</%init>
EOF
		      expect_error => q|horrible error.*|
		    );

#------------------------------------------------------------

    return $group;
}
