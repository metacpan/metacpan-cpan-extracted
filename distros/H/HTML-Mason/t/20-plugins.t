use strict;
use warnings;

use HTML::Mason::Tests;

package HTML::Mason::Plugin::TestBeforeAndAfterRequest;
use base qw(HTML::Mason::Plugin);
sub start_request_hook {
    my ($self, $context) = @_;
    print "Before Request\n";
}
sub end_request_hook {
    print "After Request\n";
}

package HTML::Mason::Plugin::TestBeforeAndAfterComponent;
use base qw(HTML::Mason::Plugin);
sub start_component_hook {
    my ($self, $context) = @_;
    print "Before Component " . $context->comp->title . "\n";
}
sub end_component_hook {
    my ($self, $context) = @_;
    print "After Component " . $context->comp->title . "\n";
}

# test the ordering of plugin calls
package HTML::Mason::Plugin::TestAllCalls;
use base qw(HTML::Mason::Plugin);
sub start_request_hook {
    my ($self, $context) = @_;
    my $rcomp = $context->request->request_comp()->title;
    print "AllCalls Request Start on: $rcomp\n";
}
sub end_request_hook {
    my ($self, $context) = @_;
    my $rcomp = $context->request->request_comp()->title;
    print "AllCalls Request Finish on: $rcomp\n";
}
sub start_component_hook {
    my ($self, $context) = @_;
    print "AllCalls Before Component " . $context->comp->title . "\n";
}
sub end_component_hook {
    my ($self, $context) = @_;
    print "AllCalls After Component " . $context->comp->title . "\n";
}

package HTML::Mason::Plugin::TestResetEachRequest;
use base qw(HTML::Mason::Plugin);
sub start_request_hook {
    my ($self, $context) = @_;
    my $rcomp = $context->request->request_comp->title();
    print "PreRequest: " . ++ $self->{count} . " : $rcomp\n";
}
sub end_request_hook {
    my ($self, $context) = @_;
    my $rcomp = $context->request->request_comp->title();
    print "PostRequest: " . ++ $self->{count} . " : $rcomp\n";
}
sub start_component_hook {
    my ($self, $context) = @_;
    print "PreComponent: " . ++ $self->{count} . " : " . $context->comp->title() ."\n";
}
sub end_component_hook {
    my ($self, $context) = @_;
    print "PostComponent: " . ++ $self->{count} . " : " . $context->comp->title() ."\n";
}

package HTML::Mason::Plugin::TestErrorStartRequest;
use base qw(HTML::Mason::Plugin);
sub start_request_hook {
    my ($self, $context) = @_;
    die("plugin error on start request " . $context->request->request_comp->title);
}

package HTML::Mason::Plugin::TestErrorEndRequest;
use base qw(HTML::Mason::Plugin);
sub end_request_hook {
    my ($self, $context) = @_;
    die("plugin error on end request " . $context->request->request_comp->title);
}

package HTML::Mason::Plugin::TestErrorStartComponent;
use base qw(HTML::Mason::Plugin);
sub start_component_hook {
    my ($self, $context) = @_;
    die("plugin error on start component " . $context->comp->title);
}

package HTML::Mason::Plugin::TestErrorEndComponent;
use base qw(HTML::Mason::Plugin);
sub end_component_hook {
    my ($self, $context) = @_;
    die("plugin error on end component " . $context->comp->title);
}

package HTML::Mason::Plugin::TestModifyReturnEndComponent;
use base qw(HTML::Mason::Plugin);
sub end_component_hook {
    my ($self, $context) = @_;
    my $result = $context->result;
    if (defined($result->[0])) {
        $result->[0] = $result->[0] * 2;
    }
}

package HTML::Mason::Plugin::TestModifyReturnEndRequest;
use base qw(HTML::Mason::Plugin);
sub end_request_hook {
    my ($self, $context) = @_;
    my $result = $context->result;
    if (defined($result->[0])) {
        $result->[0] = $result->[0] * 2;
    }
}

package HTML::Mason::Plugin::TestCatchErrorEndComponent;
use base qw(HTML::Mason::Plugin);
sub end_component_hook {
    my ($self, $context) = @_;
    my $error = $context->error;
    if (defined($$error)) {
        print "Caught error " . $$error . " and trapping it.\n";
        $$error = undef;
    }
}

package HTML::Mason::Plugin::TestCatchErrorEndRequest;
use base qw(HTML::Mason::Plugin);
sub end_request_hook {
    my ($self, $context) = @_;
    my $error = $context->error;
    if (defined($$error)) {
        print "Caught error " . $$error . " and trapping it.\n";
        $$error = undef;
    }
}

package HTML::Mason::Plugin::TestEndRequestModifyOutput;
use base qw(HTML::Mason::Plugin);
sub end_request_hook {
    my ($self, $context) = @_;
    my $content_ref = $context->output;
    $$content_ref = uc($$content_ref);
}

package main;

my $tests = make_tests();
$tests->run;

sub make_tests
{

  my $group = HTML::Mason::Tests->tests_class->new( name => 'plugins',
                                                    description => 'request and component plugin hooks'
                                                    );

#------------------------------------------------------------

  # comp A calls comp B two times.
  $group->add_support( path => '/support/A.m',
                       component => <<'EOF',
Component A Start
<& B.m &>
<& B.m &>
Component A Finish
EOF
                );

#------------------------------------------------------------


  $group->add_support( path => '/support/B.m',
                       component => <<'EOF',
Component B Start
Component B Finish
EOF
                );

#------------------------------------------------------------


  $group->add_support( path => '/support/error.m',
                       component => <<'EOF',
% die("uh oh");
EOF
                );


#------------------------------------------------------------

  $group->add_test( name => 'before_and_after_request',
                    description => 'a simple plugin for requests',
                    interp_params => 
                    {
                     plugins => ['HTML::Mason::Plugin::TestBeforeAndAfterRequest'],
                    },
                    component => '<& support/A.m &>',
                    expect => <<'EOF',
Before Request
Component A Start
Component B Start
Component B Finish

Component B Start
Component B Finish

Component A Finish
After Request
EOF
                    
                  );


#------------------------------------------------------------

  $group->add_test( name => 'before_and_after_component',
                    description => 'a simple plugin for components',
                    interp_params => 
                    {
                     plugins => ['HTML::Mason::Plugin::TestBeforeAndAfterComponent'],
                    },
                    component => '<& support/A.m &>',
                    expect => <<'EOF',
Before Component /plugins/before_and_after_component
Before Component /plugins/support/A.m
Component A Start
Before Component /plugins/support/B.m
Component B Start
Component B Finish
After Component /plugins/support/B.m

Before Component /plugins/support/B.m
Component B Start
Component B Finish
After Component /plugins/support/B.m

Component A Finish
After Component /plugins/support/A.m
After Component /plugins/before_and_after_component
EOF
                    
                  );

#------------------------------------------------------------

  $group->add_test( name => 'two_plugins',
                    description => 'using two different plugins',
                    interp_params => 
                    {
                     plugins => ['HTML::Mason::Plugin::TestBeforeAndAfterComponent', 'HTML::Mason::Plugin::TestBeforeAndAfterRequest'],
                    },
                    component => '<& support/A.m &>',
                    expect =><<'EOF',
Before Request
Before Component /plugins/two_plugins
Before Component /plugins/support/A.m
Component A Start
Before Component /plugins/support/B.m
Component B Start
Component B Finish
After Component /plugins/support/B.m

Before Component /plugins/support/B.m
Component B Start
Component B Finish
After Component /plugins/support/B.m

Component A Finish
After Component /plugins/support/A.m
After Component /plugins/two_plugins
After Request
EOF
                  );

  $group->add_test( name => 'plugin_ordering',
                    description => 'make sure plugins are called in reverse order when ending',
                    interp_params => 
                    {
                     plugins => ['HTML::Mason::Plugin::TestAllCalls','HTML::Mason::Plugin::TestBeforeAndAfterRequest', 'HTML::Mason::Plugin::TestBeforeAndAfterComponent'],
                    },
                    component => '<& support/A.m &>',
                    expect =><<'EOF',
AllCalls Request Start on: /plugins/plugin_ordering
Before Request
AllCalls Before Component /plugins/plugin_ordering
Before Component /plugins/plugin_ordering
AllCalls Before Component /plugins/support/A.m
Before Component /plugins/support/A.m
Component A Start
AllCalls Before Component /plugins/support/B.m
Before Component /plugins/support/B.m
Component B Start
Component B Finish
After Component /plugins/support/B.m
AllCalls After Component /plugins/support/B.m

AllCalls Before Component /plugins/support/B.m
Before Component /plugins/support/B.m
Component B Start
Component B Finish
After Component /plugins/support/B.m
AllCalls After Component /plugins/support/B.m

Component A Finish
After Component /plugins/support/A.m
AllCalls After Component /plugins/support/A.m
After Component /plugins/plugin_ordering
AllCalls After Component /plugins/plugin_ordering
After Request
AllCalls Request Finish on: /plugins/plugin_ordering
EOF
                  );

#------------------------------------------------------------

  $group->add_test( name => 'two_of_the_same_plugin',
                    description => 'two_of_the_same_plugin',
                    interp_params => 
                    {
                     plugins => ['HTML::Mason::Plugin::TestBeforeAndAfterComponent', 'HTML::Mason::Plugin::TestBeforeAndAfterComponent'],
                    },
                    component => '<& support/A.m &>',
                    expect =><<'EOF',
Before Component /plugins/two_of_the_same_plugin
Before Component /plugins/two_of_the_same_plugin
Before Component /plugins/support/A.m
Before Component /plugins/support/A.m
Component A Start
Before Component /plugins/support/B.m
Before Component /plugins/support/B.m
Component B Start
Component B Finish
After Component /plugins/support/B.m
After Component /plugins/support/B.m

Before Component /plugins/support/B.m
Before Component /plugins/support/B.m
Component B Start
Component B Finish
After Component /plugins/support/B.m
After Component /plugins/support/B.m

Component A Finish
After Component /plugins/support/A.m
After Component /plugins/support/A.m
After Component /plugins/two_of_the_same_plugin
After Component /plugins/two_of_the_same_plugin
EOF
                    );


  $group->add_test( name => 'reset_each_request',
                    description => 'use the same plugin twice, they should be different objects',
                    interp_params => 
                    {
                     plugins => ['HTML::Mason::Plugin::TestResetEachRequest', 'HTML::Mason::Plugin::TestResetEachRequest'],
                    },
                    component => '<& support/A.m &>',
                    expect =><<'EOF',
PreRequest: 1 : /plugins/reset_each_request
PreRequest: 1 : /plugins/reset_each_request
PreComponent: 2 : /plugins/reset_each_request
PreComponent: 2 : /plugins/reset_each_request
PreComponent: 3 : /plugins/support/A.m
PreComponent: 3 : /plugins/support/A.m
Component A Start
PreComponent: 4 : /plugins/support/B.m
PreComponent: 4 : /plugins/support/B.m
Component B Start
Component B Finish
PostComponent: 5 : /plugins/support/B.m
PostComponent: 5 : /plugins/support/B.m

PreComponent: 6 : /plugins/support/B.m
PreComponent: 6 : /plugins/support/B.m
Component B Start
Component B Finish
PostComponent: 7 : /plugins/support/B.m
PostComponent: 7 : /plugins/support/B.m

Component A Finish
PostComponent: 8 : /plugins/support/A.m
PostComponent: 8 : /plugins/support/A.m
PostComponent: 9 : /plugins/reset_each_request
PostComponent: 9 : /plugins/reset_each_request
PostRequest: 10 : /plugins/reset_each_request
PostRequest: 10 : /plugins/reset_each_request
EOF
                    );
  

#------------------------------------------------------------

  $group->add_test( name => 'error_on_start_request',
                    description => 'a plugin that dies',
                    interp_params => 
                    {
                     plugins => ['HTML::Mason::Plugin::TestErrorStartRequest'],
                    },
                    component => '<& support/A.m &>',
                    expect_error => 'plugin error on start request /plugins/error_on_start_request',
                  );


#------------------------------------------------------------

  $group->add_test( name => 'error_on_end_request',
                    description => 'a plugin that dies',
                    interp_params => 
                    {
                     plugins => ['HTML::Mason::Plugin::TestErrorEndRequest'],
                    },
                    component => '<& support/A.m &>',
                    expect_error => 'plugin error on end request /plugins/error_on_end_request',
                  );


#------------------------------------------------------------

  $group->add_test( name => 'error_on_start_component',
                    description => 'a plugin that dies',
                    interp_params => 
                    {
                     plugins => ['HTML::Mason::Plugin::TestErrorStartComponent'],
                    },
                    component => '<& support/A.m &>',
                    expect_error => 'plugin error on start component /plugins/error_on_start_component',
                  );

#------------------------------------------------------------

  $group->add_test( name => 'error_on_end_component',
                    description => 'a plugin that dies',
                    interp_params => 
                    {
                     plugins => ['HTML::Mason::Plugin::TestErrorEndComponent'],
                    },
                    component => '<& support/A.m &>',
                    expect_error => 'plugin error on end component /plugins/error_on_end_component',
                  );

#------------------------------------------------------------

  $group->add_test( name => 'not_persistent_across_requests',
                    description => 'different plugin for each request',
                    interp_params => 
                    {
                     plugins => ['HTML::Mason::Plugin::TestResetEachRequest'],
                    },
                    component => '% $m->subexec("support/A.m"); ',
                    expect =><<'EOF',
PreRequest: 1 : /plugins/not_persistent_across_requests
PreComponent: 2 : /plugins/not_persistent_across_requests
PreRequest: 1 : /plugins/support/A.m
PreComponent: 2 : /plugins/support/A.m
Component A Start
PreComponent: 3 : /plugins/support/B.m
Component B Start
Component B Finish
PostComponent: 4 : /plugins/support/B.m

PreComponent: 5 : /plugins/support/B.m
Component B Start
Component B Finish
PostComponent: 6 : /plugins/support/B.m

Component A Finish
PostComponent: 7 : /plugins/support/A.m
PostRequest: 8 : /plugins/support/A.m
PostComponent: 3 : /plugins/not_persistent_across_requests
PostRequest: 4 : /plugins/not_persistent_across_requests
EOF
                  );

#------------------------------------------------------------

  my $PersistentPlugin = HTML::Mason::Plugin::TestResetEachRequest->new();
  $group->add_test( name => 'persistent_across_requests',
                    description => 'same plugin across a subrequest',
                    interp_params => 
                    {
                     plugins => [$PersistentPlugin],
                    },
                    component => '% $m->subexec("support/A.m"); ',
                    expect =><<'EOF',
PreRequest: 1 : /plugins/persistent_across_requests
PreComponent: 2 : /plugins/persistent_across_requests
PreRequest: 3 : /plugins/support/A.m
PreComponent: 4 : /plugins/support/A.m
Component A Start
PreComponent: 5 : /plugins/support/B.m
Component B Start
Component B Finish
PostComponent: 6 : /plugins/support/B.m

PreComponent: 7 : /plugins/support/B.m
Component B Start
Component B Finish
PostComponent: 8 : /plugins/support/B.m

Component A Finish
PostComponent: 9 : /plugins/support/A.m
PostRequest: 10 : /plugins/support/A.m
PostComponent: 11 : /plugins/persistent_across_requests
PostRequest: 12 : /plugins/persistent_across_requests
EOF
                    );

#------------------------------------------------------------

  $group->add_support ( path => '/support/return_numbers',
                        component => <<'EOF',
<%def .five><%perl>return 5;</%perl></%def>
<%def .six><%perl>return 6;</%perl></%def>
% return $m->comp('.five') + $m->comp('.six');
EOF
                    );

  $group->add_test( name => 'modify_return_end_component',
                    description => 'an end_component plugin that modifies its return value',
                    interp_params => 
                    {
                     plugins => ['HTML::Mason::Plugin::TestModifyReturnEndComponent'],
                    },
                    component => '<% $m->comp("support/return_numbers") %>',
                    expect => '44',
                  );

  $group->add_test( name => 'modify_return_end_request',
                    description => 'an end_request plugin that modifies its return value',
                    interp_params => 
                    {
                     plugins => ['HTML::Mason::Plugin::TestModifyReturnEndRequest'],
                    },
                    component => '<% $m->subexec("support/return_numbers") %>',
                    expect => '22',
                  );

#------------------------------------------------------------

  $group->add_test( name => 'catch_error_end_component',
                    description => 'an end_component plugin that modifies its arguments to trap errors',
                    interp_params => 
                    {
                     plugins => ['HTML::Mason::Plugin::TestCatchErrorEndComponent'],
                    },
                    component => '<& support/error.m &>',
                    expect => qr{Caught error uh oh},
                  );

  $group->add_test( name => 'catch_error_end_request',
                    description => 'an end_request plugin that modifies its arguments to trap errors',
                    interp_params => 
                    {
                     plugins => ['HTML::Mason::Plugin::TestCatchErrorEndRequest'],
                    },
                    component => '<& support/error.m &>',
                    expect => qr{Caught error uh oh},
                  );

#------------------------------------------------------------

  $group->add_test( name => 'modify_content_end_request',
                    description => 'modify content at end of request',
                    interp_params => 
                    {
                     plugins => ['HTML::Mason::Plugin::TestEndRequestModifyOutput'],
                    },
                    component => '<%def .something>capitalized</%def>I will be <& .something &>',
                    expect => <<'EOF',
I WILL BE CAPITALIZED
EOF
                  );

  return $group;

}
