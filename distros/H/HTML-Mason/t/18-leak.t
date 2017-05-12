use strict;
use warnings;

use HTML::Mason::Tests;
use HTML::Mason::Tools qw(can_weaken);

BEGIN
{
    unless ( can_weaken )
    {
        print "Your installation does not include Scalar::Util::weaken\n";
        print "1..0\n";
        exit;
    }
}

my $tests = make_tests();
$tests->run;

{
    package InterpWatcher;
    my $_destroy_count = 0;
    
    use base qw(HTML::Mason::Interp);
    sub DESTROY { $_destroy_count++ }
    sub _destroy_count   { $_destroy_count   }
    sub _clear_destroy_count { $_destroy_count = 0 }
}

{
    package RequestWatcher;
    my $_destroy_count = 0;
    
    use base qw(HTML::Mason::Request);
    sub DESTROY { $_destroy_count++ }
    sub _destroy_count   { $_destroy_count   }
    sub _clear_destroy_count { $_destroy_count = 0 }
}

{
    # Unfortunately cannot override component class, even by setting
    # comp_class, because it is hardcoded in
    # Resolver/FileBased.pm. This works as long as Component.pm
    # doesn't have any of these methods.
    #
    package HTML::Mason::Component;
    my $_destroy_count = 0;
    
    sub DESTROY { $_destroy_count++ }
    sub _destroy_count   { $_destroy_count   }
    sub _clear_destroy_count { $_destroy_count = 0 }
}

{
    package SubcomponentWatcher;
    my $_destroy_count = 0;
    
    use base qw(HTML::Mason::Component::Subcomponent);
    sub DESTROY { $_destroy_count++ }
    sub _destroy_count   { $_destroy_count   }
    sub _clear_destroy_count { $_destroy_count = 0 }
}

sub make_tests
{
    my $group = HTML::Mason::Tests->tests_class->new( name => '18-leak.t',
                                                      description => 'Tests that various memory leaks are no longer with us' );

    $group->add_test( name => 'interp_destroy',
                      description => 'Test that interps with components in cache still get destroyed',
                      component => <<'EOF',
<%perl>
{ 
    my $interp = InterpWatcher->new();
    my $comp = $interp->make_component( comp_source => 'foo' );
}
$m->print("destroy_count = " . InterpWatcher->_destroy_count . "\n");

{
    my $interp = InterpWatcher->new();
    my $comp = $interp->make_component( comp_source => 'foo' );
}
$m->print("destroy_count = " . InterpWatcher->_destroy_count . "\n");
</%perl>
EOF
                      expect => <<'EOF',
destroy_count = 1
destroy_count = 2
EOF
                    );

#------------------------------------------------------------

    $group->add_support( path => '/support/no_error_comp',
                         component => <<'EOF',
No error here.
EOF
                       );

#------------------------------------------------------------

    $group->add_support( path => '/support/compile_error_comp',
                         component => <<'EOF',
<%
EOF
                       );

#------------------------------------------------------------

    $group->add_support( path => '/support/runtime_error_comp',
                         component => <<'EOF',
% die "bleah";
EOF
                       );

#------------------------------------------------------------

    $group->add_support( path => '/support/recursive_caller_1',
                         component => <<'EOF',
<%perl>
$m->comp("recursive_caller_2", %ARGS);
return;
</%perl>
EOF
                       );

#------------------------------------------------------------

    $group->add_support( path => '/support/recursive_caller_2',
                         component => <<'EOF',
<%perl>
my $anon_comp = $ARGS{anon_comp};
$m->comp($anon_comp, %ARGS) if $m->depth < 16;
return;
</%perl>
EOF
                       );

#------------------------------------------------------------

    $group->add_test( name => 'request_destroy',
                      description => 'Test that requests get destroyed after top-level component error',
                      interp_params => { request_class => 'RequestWatcher' },
                      component => <<'EOF',
<%perl>
eval { $m->subexec('support/no_error_comp') };
$m->print("destroy_count = " . RequestWatcher->_destroy_count . "\n");
eval { $m->subexec('support/compile_error_comp') };
$m->print("destroy_count = " . RequestWatcher->_destroy_count . "\n");
eval { $m->subexec('support/not_found_comp') };
$m->print("destroy_count = " . RequestWatcher->_destroy_count . "\n");
</%perl>
EOF
                      expect => <<'EOF',
No error here.
destroy_count = 1
destroy_count = 2
destroy_count = 3
EOF
                    );

#------------------------------------------------------------

    $group->add_support( path => '/support/def_and_method',
                         component => <<'EOF',
<%init>
$m->comp('.def');
$m->comp('SELF:method');
return;
</%init>

<%def .def>
This is a def
</%def>

<%method method>
This is a method
</%method>
EOF
                       );

#------------------------------------------------------------

    $group->add_test( name => 'component_destroy',
                      description => 'Test that components get freed when cleared from the main cache',
                      interp_params => { code_cache_max_size => 0 },
                      component => <<'EOF',
<%perl>
HTML::Mason::Component->_clear_destroy_count;
$m->subexec('support/no_error_comp');
$m->print("destroy_count = " . HTML::Mason::Component->_destroy_count . "\n");
$m->subexec('support/no_error_comp');
$m->print("destroy_count = " . HTML::Mason::Component->_destroy_count . "\n");
eval { $m->subexec('support/runtime_error_comp') };
$m->print("destroy_count = " . HTML::Mason::Component->_destroy_count . "\n");
eval { $m->subexec('support/runtime_error_comp') };
$m->print("destroy_count = " . HTML::Mason::Component->_destroy_count . "\n");
</%perl>
EOF
                      expect => <<'EOF',
No error here.
destroy_count = 1
No error here.
destroy_count = 2
destroy_count = 3
destroy_count = 4
EOF
                       );

#------------------------------------------------------------

    $group->add_test( name => 'component_destroy_static_source',
                      description => 'Test that components get freed in static source mode',
                      interp_params => { static_source => 1 },
                      component => <<'EOF',
<%perl>
HTML::Mason::Component->_clear_destroy_count;
my $anon_comp_text = q|
<%init>
$m->comp("/18-leak.t/support/recursive_caller_1", %ARGS);
return;
</%init>
|;
my $anon_comp = $m->interp->make_component( comp_source => $anon_comp_text );
$m->subexec('support/recursive_caller_1', anon_comp=>$anon_comp);
$m->interp->flush_code_cache;
$m->print("destroy_count = " . HTML::Mason::Component->_destroy_count . "\n");
$m->subexec('support/recursive_caller_1', anon_comp=>$anon_comp);
$m->interp->flush_code_cache;
$m->print("destroy_count = " . HTML::Mason::Component->_destroy_count . "\n");
</%perl>
EOF
                      expect => <<'EOF',
destroy_count = 2
destroy_count = 4
EOF
                       );

#------------------------------------------------------------

    $group->add_test( name => 'subcomponent_destroy',
                      description => 'Test that defs and methods don\'t cause components to leak',
                      interp_params => { subcomp_class => 'SubcomponentWatcher',
                                         code_cache_max_size => 0 },
                      component => <<'EOF',
<%perl>
HTML::Mason::Component->_clear_destroy_count;
$m->subexec('support/def_and_method');
$m->print("destroy_count = " . HTML::Mason::Component->_destroy_count . ", " . SubcomponentWatcher->_destroy_count . "\n");
$m->subexec('support/def_and_method');
$m->print("destroy_count = " . HTML::Mason::Component->_destroy_count . ", " . SubcomponentWatcher->_destroy_count . "\n");
</%perl>
EOF
                      expect => <<'EOF',

This is a def

This is a method
destroy_count = 1, 2

This is a def

This is a method
destroy_count = 2, 4
EOF
                       );

#------------------------------------------------------------

    return $group;
}
