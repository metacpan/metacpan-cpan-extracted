use strict;
use warnings;

use HTML::Mason::Tests;

my $tests = make_tests();
$tests->run;

sub make_tests
{
    my $group = HTML::Mason::Tests->tests_class->new( name => 'request',
                                                      description => 'request object functionality' );


#------------------------------------------------------------

    $group->add_support( path => '/support/abort_test',
                         component => <<'EOF',
<%args>
$val => 50
</%args>
Some more text

% $m->abort($val);

But this will never be seen
EOF
                       );


#------------------------------------------------------------

    $group->add_support( path => '/sections/perl',
                         component => <<'EOF',
foo
EOF
                       );


#------------------------------------------------------------

    $group->add_support( path => '/support/various_test',
                         component => <<'EOF',
Caller is <% $m->caller->title %> or <% $m->callers(1)->title %> or <% $m->callers(-2)->title %>.
The top level component is <% $m->callers(-1)->title %> or <% $m->request_comp->title %>.
The full component stack is <% join(",",map($_->title,$m->callers)) %>.
My argument list is (<% join(",",$m->caller_args(0)) %>).
The top argument list is (<% join(",",$m->request_args()) %>) or (<% join(",",$m->caller_args(-1)) %>).

% foreach my $path (qw(various_test /request/sections/perl foobar /shared)) {
%   my $full_path = HTML::Mason::Tools::absolute_comp_path($path, $m->current_comp->dir_path);
Trying to fetch <% $path %> (full path <% $full_path %>):
%   if ($m->comp_exists($path)) {
%     if (my $comp = $m->fetch_comp($path)) {
<% $path %> exists with title <% $comp->title %>.
%     } else {
<% $path %> exists but could not fetch object!
%     }
%   } else {
<% $path %> does not exist.
%   }
% }

% $m->print("Output via the out function.");

/request/file outputs <% int(length($m->scomp("/request/file"))/10) %>0+ characters.
EOF
                       );


#------------------------------------------------------------

    $group->add_support( path => 'various_helper',
                         component => <<'EOF',
<& support/various_test, %ARGS &>
EOF
                       );

#------------------------------------------------------------

    $group->add_test( name => 'abort',
                      description => 'test $m->abort method (autoflush on)',
                      interp_params => { autoflush => 1 },
                      component => <<'EOF',
Some text

% eval {$m->comp('support/abort_test')};
% if (my $err = $@) {
%   if ($m->aborted) {
Component aborted with value <% $err->aborted_value %>
%   } else {
Got error
%   }
% }
EOF
                      expect => <<'EOF',
Some text

Some more text

Component aborted with value 50
EOF
                    );


#------------------------------------------------------------

    $group->add_test( name => 'abort_0',
                      description => 'test $m->abort method with value of 0',

                      component => <<'EOF',
Some text

% eval {$m->comp('support/abort_test', val => 0)};
% if (my $err = $@) {
%   if ($m->aborted($err)) {
Component aborted with value <% $err->aborted_value %>
%   } else {
Got error
%   }
% }
EOF
                      expect => <<'EOF',
Some text

Some more text

Component aborted with value 0
EOF
                    );


#------------------------------------------------------------

    $group->add_test( name => 'abort',
                      description => 'test $m->abort method (autoflush off)',
                      component => <<'EOF',
Some text

% eval {$m->comp('support/abort_test')};
% if (my $err = $@) {
%   if ($m->aborted) {
Component aborted with value <% $err->aborted_value %>
%   } else {
Got error
%   }
% }
EOF
                      expect => <<'EOF',
Some text

Some more text

Component aborted with value 50
EOF
                    );


#------------------------------------------------------------

    $group->add_test( name => 'file',
                      description => 'tests $m->file method',
                      component => <<'EOF',
Now I will print myself:

% my $output = $m->file("file");
% $output =~ s/\cM//g;
<% $output %>
EOF
                      expect => <<'EOF',
Now I will print myself:

Now I will print myself:

% my $output = $m->file("file");
% $output =~ s/\cM//g;
<% $output %>
EOF
                    );


#------------------------------------------------------------

    $group->add_test( name => 'file_in_subcomp',
                      description => 'tests $m->file method in subcomponent',
                      component => <<'EOF',
Here I am:

<& .sub &>
<%def .sub>
% my $f = $m->file('file_in_subcomp'); $f =~ s/\r\n?/\n/g;
<% $f %>
</%def>
EOF
                      expect => <<'EOF',
Here I am:


Here I am:

<& .sub &>
<%def .sub>
% my $f = $m->file('file_in_subcomp'); $f =~ s/\r\n?/\n/g;
<% $f %>
</%def>
EOF
                    );


#------------------------------------------------------------

    $group->add_test( name => 'list_out',
                      description => 'tests that $m->print can handle a list of arguments',
                      component => <<'EOF',
Sending list of arguments:

<% 'blah','boom','bah' %>

<%perl>
 $m->print(3,4,5);
 my @lst = (7,8,9);
 $m->print(@lst);
</%perl>
EOF
                      expect => <<'EOF',
Sending list of arguments:

blahboombah

345789
EOF
                    );


#------------------------------------------------------------

    $group->add_test( name => 'req_obj',
                      description => 'tests various operations such as comp calls, $m->current_comp',
                      component => <<'EOF',
<%def .subcomp>
% if ($count < 5) {
<& $m->current_comp, count=>$count+1 &>
% } else {
<& /shared/display_req_obj &>
% }
<%args>
$count
</%args>
</%def>

<% '-' x 10 %>

One level request:
<& /shared/display_req_obj &>

<% '-' x 10 %>

Many level request:
<& .subcomp, count=>0 &>

<% '-' x 10 %>
EOF
                      expect => <<'EOF',

----------

One level request:
My depth is 2.

I am not a subrequest.

The top-level component is /request/req_obj.

My stack looks like:
-----
/shared/display_req_obj
/request/req_obj
-----



----------

Many level request:






My depth is 8.

I am not a subrequest.

The top-level component is /request/req_obj.

My stack looks like:
-----
/shared/display_req_obj
/request/req_obj:.subcomp
/request/req_obj:.subcomp
/request/req_obj:.subcomp
/request/req_obj:.subcomp
/request/req_obj:.subcomp
/request/req_obj:.subcomp
/request/req_obj
-----









----------
EOF
                    );


#------------------------------------------------------------

    $group->add_test( name => 'various',
                      call_args => {junk=>5},
                      description => 'tests caller, callers, fetch_comp, process_comp_path, comp_exists and scomp',
                      component => <<'EOF',
<& various_helper, junk=>$ARGS{junk}+1 &>
EOF
                      expect => <<'EOF',
Caller is /request/various_helper or /request/various_helper or /request/various_helper.
The top level component is /request/various or /request/various.
The full component stack is /request/support/various_test,/request/various_helper,/request/various.
My argument list is (junk,6).
The top argument list is (junk,5) or (junk,5).

Trying to fetch various_test (full path /request/support/various_test):
various_test exists with title /request/support/various_test.
Trying to fetch /request/sections/perl (full path /request/sections/perl):
/request/sections/perl exists with title /request/sections/perl.
Trying to fetch foobar (full path /request/support/foobar):
foobar does not exist.
Trying to fetch /shared (full path /shared):
/shared does not exist.

Output via the out function.
/request/file outputs 120+ characters.
EOF
                    );

#------------------------------------------------------------

    $group->add_support( path => '/autohandler_test2/autohandler',
                         component => <<'EOF',
This is the first autohandler
Remaining chain: <% join(',',map($_->title,$m->fetch_next_all)) %>
<& $m->fetch_next, level => 1 &>\
EOF
                       );

#------------------------------------------------------------

    $group->add_support( path => '/autohandler_test2/dir1/autohandler',
                         component => <<'EOF',
This is the second autohandler
Remaining chain: <% join(',',map($_->title,$m->fetch_next_all)) %>
% foreach (@_) {
<% $_ %>
% }
<& $m->fetch_next, level => 2 &>\
EOF
                       );

#------------------------------------------------------------

    $group->add_test( name => 'fetch_next',
                      path => '/autohandler_test2/dir1/fetch_next',
                      call_path => '/autohandler_test2/dir1/fetch_next',
                      description => 'Test $m->fetch_next and $m->fetch_next_all',
                      component => <<'EOF',
This is the main component (called by level <% $ARGS{level} %>)
Remaining chain: <% join(',',map($_->title,$m->fetch_next_all)) %>
% foreach (@_) {
<% $_ %>
% }
EOF
                      expect => <<'EOF',
This is the first autohandler
Remaining chain: /request/autohandler_test2/dir1/autohandler,/request/autohandler_test2/dir1/fetch_next
This is the second autohandler
Remaining chain: /request/autohandler_test2/dir1/fetch_next
level
1
This is the main component (called by level 2)
Remaining chain: 
level
2
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'print',
                      description => 'Test print function from a component',
                      component => <<'EOF',
This is first.
% print "This is second.\n";
This is third.
EOF
                      expect => <<'EOF',
This is first.
This is second.
This is third.
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'printf',
                      description => 'Test printf function from a component',
                      component => <<'EOF',
This is first.
% printf '%s', "This is second.\n";
This is third.
EOF
                      expect => <<'EOF',
This is first.
This is second.
This is third.
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'autoflush_print',
                      description => 'Test print function from a component with autoflush on',
                      interp_params => { autoflush => 1 },
                      component => <<'EOF',
This is first.
% print "This is second.\n";
This is third.
EOF
                      expect => <<'EOF',
This is first.
This is second.
This is third.
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'autoflush_printf',
                      description => 'Test printf function from a component with autoflush on',
                      interp_params => { autoflush => 1 },
                      component => <<'EOF',
This is first.
% printf '%s', "This is second.\n";
This is third.
EOF
                      expect => <<'EOF',
This is first.
This is second.
This is third.
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'flush_print',
                      description => 'Test print function from a component in conjunction with $m->flush_buffer call',
                      component => <<'EOF',
This is first.
% print "This is second.\n";
% $m->flush_buffer;
This is third.
EOF
                      expect => <<'EOF',
This is first.
This is second.
This is third.
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'flush_print_autoflush',
                      description => 'Test print function from a component with autoflush on in conjunction with $m->flush_buffer call',
                      interp_params => { autoflush => 1 },
                      component => <<'EOF',
This is first.
% print "This is second.\n";
% $m->flush_buffer;
This is third.
EOF
                      expect => <<'EOF',
This is first.
This is second.
This is third.
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'flush_filter',
                      description => 'Test $m->flush_buffer in presence of filter',
                      component => <<'EOF',
one
% $m->flush_buffer;
% $m->clear_buffer;
two
<%filter>
$_ .= $_;
</%filter>
EOF
                      expect => <<'EOF',
one
one
two
two
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'clear_buffer',
                      description => 'Test $m->clear_buffer in a normal component',
                      component => <<'EOF',
one
% $m->clear_buffer;
two
EOF
                      expect => <<'EOF',
two
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'clear_filter',
                      description => 'Test $m->clear_buffer in presence of filter',
                      component => <<'EOF',
one
% $m->clear_buffer;
two
<%filter>
$_ .= $_;
</%filter>
EOF
                      expect => <<'EOF',
two
two
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'autoflush_disabled',
                      description => 'Using autoflush when disabled generates an error',
                      interp_params => { autoflush => 1, enable_autoflush => 0 },
                      component => <<'EOF',
Hi
EOF
                      expect_error => qr/Cannot use autoflush unless enable_autoflush is set/,
                    );

#------------------------------------------------------------

    $group->add_test( name => 'instance',
                      description => 'Test HTML::Mason::Request->instance',
                      component => <<'EOF',
<% $m eq HTML::Mason::Request->instance ? 'yes' : 'no' %>
EOF
                      expect => <<'EOF',
yes
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'abort_and_filter',
                      description => 'Test that an abort in a filtered component still generates _some_ output, and that filter is run only once',
                      component => <<'EOF',
filter

% eval { $m->comp('support/abort_test') };
<%filter>
$_ = uc $_;
$_ =~ s/\s+$//;
$_ .= "\nfilter ran once";
</%filter>
EOF
                      expect => <<'EOF',
FILTER

SOME MORE TEXT
filter ran once
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'abort_and_filter_2',
                      description => 'Test that $m->aborted can be checked in a filter section',
                      component => <<'EOF',
filter

% $m->abort;
<%filter>
unless ( $m->aborted )
{
    $_ = uc $_;
    $_ =~ s/\s+$//;
    $_ .= "\nfilter ran once";
}
</%filter>
EOF
                      expect => <<'EOF',
filter
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'abort_and_store',
                      description => 'Test that an abort in a store\'d component still generates _some_ output',
                      component => <<'EOF',
filter

% my $foo;
% eval { $m->comp( { store => \$foo }, 'support/abort_test') };
<% $foo %>
EOF
                      expect => <<'EOF',
filter

Some more text

EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'clear_and_abort',
                      description => 'Test the clear_and_abort() method',
                      component => <<'EOF',
Some output
% $m->flush_buffer;
More output
% $m->clear_and_abort();
EOF
                      expect => <<'EOF',
Some output
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'reexec',
                      description => 'test that $m cannot be reexecuted',
                      component => <<'EOF',
<%init>
$m->exec;
</%init>
EOF
                      expect_error => qr/Can only call exec\(\) once/,
                    );

#------------------------------------------------------------

    $group->add_test( name => 'caller_in_subcomp',
                      description => 'tests $m->caller() in subcomponent',
                      component => <<'EOF',
<%def .foo>
 <% $m->caller->name %>
</%def>
<& .foo &>
EOF
                      expect => <<'EOF',

 caller_in_subcomp
EOF
                    );


#------------------------------------------------------------

    $group->add_test( name => 'caller_at_top_level',
                      description => 'tests $m->caller() from top component',
                      component => <<'EOF',
caller is <% defined($m->caller) ? "defined" : "undefined" %>
callers(5) is <% defined($m->callers(5)) ? "defined" : "undefined" %>
caller_args(7) is <% defined($m->callers(7)) ? "defined" : "undefined" %>
EOF
                      expect => <<'EOF',
caller is undefined
callers(5) is undefined
caller_args(7) is undefined
EOF
                    );


#------------------------------------------------------------

    $group->add_support( path => '/support/longjump_test3',
                         component => <<'EOF',
Depth is <% $m->depth %>.
The full component stack is <% join(",",map($_->title,$m->callers)) %>.
EOF
                       );

    $group->add_support( path => '/support/subdir/longjump_test2',
                         component => <<'EOF',
This is longjump_test2
% no warnings 'uninitialized'; next;
EOF
                       );

    $group->add_support( path => '/support/longjump_test1',
                         component => <<'EOF',
<& longjump_test3 &>
% foreach my $i (0..2) {
<& subdir/longjump_test2 &>
% }
<& longjump_test3 &>
EOF
                       );

    # It is possible to accidentally call 'next' from a component and
    # jump out to the last loop or block in a previous component.
    # While this cannot be supported behavior (since necessary cleanup
    # and plugin code is skipped), we'd like to avoid a Mason request
    # stack corruption at a minimum.
    #
    $group->add_test( name => 'longjump',
                      description => 'Accidentally calling next to exit a component does not corrupt stack',
                      component => <<'EOF',
<& support/longjump_test1 &>
EOF
                      expect => <<'EOF',
Depth is 3.
The full component stack is /request/support/longjump_test3,/request/support/longjump_test1,/request/longjump.

This is longjump_test2

This is longjump_test2

This is longjump_test2

Depth is 3.
The full component stack is /request/support/longjump_test3,/request/support/longjump_test1,/request/longjump.
EOF
                      # This just shuts the test code up
                      expect_warnings => qr/.*/,
                    );

#------------------------------------------------------------

    $group->add_support( path => '/support/callers_out_of_bounds2',
                         component => <<'EOF',
hi
EOF
                       );

#------------------------------------------------------------

    $group->add_support( path => '/support/callers_out_of_bounds1',
                         component => <<'EOF',
<& callers_out_of_bounds2 &>
% foreach my $i (-4 .. 4) {
callers(<% $i %>) is <% defined($m->callers($i)) ? $m->callers($i)->title : 'not defined' %>
% }
EOF
                       );

#------------------------------------------------------------

    $group->add_test( name => 'callers_out_of_bounds',
                      description => 'tests $m->callers() for out of bounds indexes',
                      component => <<'EOF',
<& support/callers_out_of_bounds1 &>
EOF
                      expect => <<'EOF',
hi

callers(-4) is not defined
callers(-3) is not defined
callers(-2) is /request/support/callers_out_of_bounds1
callers(-1) is /request/callers_out_of_bounds
callers(0) is /request/support/callers_out_of_bounds1
callers(1) is /request/callers_out_of_bounds
callers(2) is not defined
callers(3) is not defined
callers(4) is not defined
EOF
                    );


#------------------------------------------------------------

    $group->add_test( name => 'call_self',
                      description => 'Test $m->call_self',
                      component => <<'EOF',
called
<%init>
my $out;
if ( $m->call_self( \$out, undef ) )
{
    $m->print($out);
    return;
}
</%init>
EOF
                      expect => <<'EOF',
called
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'call_self_retval',
                      description => 'Test that we can get return value of component via $m->call_self',
                      component => <<'EOF',
called
<%init>
my @return;
if ( $m->call_self( undef, \@return ) )
{
    $m->print( "0: $return[0]\n1: $return[1]\n" );
    return;
}
return ( 'foo', 'bar' );
</%init>
EOF
                      expect => <<'EOF',
0: foo
1: bar
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'call_self_output_and_retval',
                      description => 'Test that we can get return value and output of component via $m->call_self',
                      component => <<'EOF',
called
<%init>
my $out;
my @return;
if ( $m->call_self( \$out, \@return ) )
{
    $m->print( "${out}0: $return[0]\n1: $return[1]\n" );
    return;
}
</%init>
<%cleanup>
return ( 'foo', 'bar' );
</%cleanup>
EOF
                      expect => <<'EOF',
called
0: foo
1: bar
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'call_self_with_filter',
                      description => 'Test that $m->call_self works in presence of filter',
                      component => <<'EOF',
called
<%filter>
$_ = uc $_;
$_ .= ' filtered';
</%filter>
<%init>
my $out;
if ( $m->call_self( \$out, undef ) )
{
    $m->print($out);
    return;
}
</%init>
EOF
                      expect => <<'EOF',
CALLED
 filtered
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'subcomp_from_shared',
                      description => 'Test calling a subcomponent inside shared block',
                      component => <<'EOF',
<%shared>
$m->comp('subcomp');
</%shared>
<%def subcomp>
a subcomp
</%def>
EOF
                      expect_error =>
                      qr/cannot call a method or subcomponent from a <%shared> block/,
                    );

#------------------------------------------------------------

    $group->add_test( name => 'method_in_shared',
                      description => 'Test calling a method inside shared block',
                      component => <<'EOF',
<%shared>
$m->comp('SELF:meth');
</%shared>
<%method meth>
a method
</%method>
EOF
                      expect_error =>
                      qr/cannot call a method or subcomponent from a <%shared> block/,
                    );

#------------------------------------------------------------

    $group->add_test( name => 'notes',
                      description => 'Test the notes() method',
                      component => <<'EOF',
% $m->notes('key', 'value');
k: <% $m->notes('key') %>
k2: <% $m->notes->{key} %>
EOF
                      expect =>
                      qr/k: value\s+k2: value/,
                    );

#------------------------------------------------------------

    $group->add_test( name => 'flush_and_store',
                      description => q{Test that $m->flush_buffer is ignored in a store'd component},
                      interp_params => { autoflush => 1 },
                      component => <<'EOF',
<%def .world>\
World\
</%def>

% my $world;
% $m->comp( { store => \$world }, '.world');
Hello, <% $world %>!

% $world = $m->scomp('.world');
Hello, <% $world %>!
EOF
                      expect => <<'EOF',

Hello, World!

Hello, World!
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'flush_and_scomp_recursive',
                      description => 'Test that $m->flush_buffer is ignored in a recursive scomp() call',
                      interp_params => { autoflush => 1 },
                      component => <<'EOF',
<%def .orld>\
orld\
</%def>

<%def .world>\
W<& .orld &>\
</%def>

% my $world = $m->scomp('.world');
Hello, <% $world %>!
EOF
                      expect => <<'EOF',


Hello, World!
EOF
                    );

#------------------------------------------------------------

    return $group;
}
