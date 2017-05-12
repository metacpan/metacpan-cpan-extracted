#!/usr/bin/perl -w

use strict;

use HTML::Mason::Tests;

my $tests = make_tests();
$tests->run;

sub make_tests
{
    my $group = HTML::Mason::Tests->new( name => 'filters',
					 description => 'Filter Component' );


#------------------------------------------------------------

    $group->add_support( path => 'filter_test/filter',
			 component => <<'EOF',
<%once>
my %words = (1,'one',2,'two',3,'three',4,'four',5,'five');
</%once>
<%perl>
my $c = $m->content;
$c = '' unless defined $c;  # avoid uninitialized value warnings
$c =~ s/^\s+//;
$c =~ s/\s+$//;
if ($words{$c}) {
	$m->print($words{$c});
} else {
	$m->print("content returned '".$c."'");
}
</%perl>
EOF
		       );

#------------------------------------------------------------

$group->add_support( path => 'filter_test/repeat',
		 component => <<'EOF',
<%args>
$var
@list
</%args>
<%perl>
for (@list) {
	$$var = $_;
	$m->print($m->content);
}
</%perl>
EOF
	       );

#------------------------------------------------------------

    $group->add_support( path => 'filter_test/repeat2',
			 component => <<'EOF',
<%args>
@list
</%args>
<% foreach (@list) { %>\
<%= $m->content %>
<% } %>\
EOF
		       );

#------------------------------------------------------------

    $group->add_support( path => 'filter_test/null',
			 component => <<'EOF',
EOF
		       );

#------------------------------------------------------------

    $group->add_support( path => 'filter_test/echo',
			 component => <<'EOF',
<% $m->print($m->content); %>\
EOF
		       );

#------------------------------------------------------------

    $group->add_support( path => 'filter_test/double',
			 component => <<'EOF',
<&| filter &>1</&>
<&| filter &><%= $m->content %></&>
EOF
		       );

#------------------------------------------------------------

    $group->add_test( name => 'repeat',
		      path => 'filter_test/test1',
		      call_path => 'filter_test/test1',
		      description => 'Tests a filter which outputs the content multiple times, with different values',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',
<% my $a; %>\
<ul>
<&| repeat , var => \$a, list => [1,2,3,4,5] &>
<li><%= $a %>
</&>
</ul>

EOF
		      expect => <<'EOF',
<ul>

<li>1

<li>2

<li>3

<li>4

<li>5

</ul>

EOF
		     );

#------------------------------------------------------------

    $group->add_test( name => 'filter',
		      path => 'filter_test/test2',
		      call_path => 'filter_test/test2',
		      description => 'Tests a filter changes the contents',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',
<&| filter &>1</&>
<br>
<&| filter &>2</&>
<br>
<&| filter &>hi</&>
<br>
end
EOF
		      expect => <<'EOF',
one
<br>
two
<br>
content returned 'hi'
<br>
end
EOF
		     );

#------------------------------------------------------------

    $group->add_test( name => 'nested',
		      path => 'filter_test/test3',
		      call_path => 'filter_test/test3',
		      description => 'Tests nested filters',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',
<% my $i; %>\
<&| repeat , var => \$i , list => [5,4,3,2,1] &>
<&| filter &> <%= $i %> </&> <p>
</&>
done!
EOF
		      expect => <<'EOF',

five <p>

four <p>

three <p>

two <p>

one <p>

done!
EOF
		     );

#------------------------------------------------------------

    $group->add_test( name => 'contentless',
		      path => 'filter_test/test4',
		      call_path => 'filter_test/test4',
		      description => 'test a filter with no content',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',
nothing <& filter &> here
EOF
		      expect => <<'EOF',
nothing content returned '' here
EOF
		     );

#------------------------------------------------------------

    $group->add_test( name => 'default_content',
		      path => 'filter_test/test5',
		      call_path => 'filter_test/test5',
		      description => 'test a filter which does not access content',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',
outside <&| null &> inside </&> outside
EOF
		      expect => <<'EOF',
outside  outside
EOF
		     );

#------------------------------------------------------------

    $group->add_test(	name => 'current_component',
			path => 'filter_test/test6',
			call_path => 'filter_test/test6',
			call_args => {arg=>1},
			description => 'test $m->current_comp inside filter content',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
			component => <<'EOF',
<%= $m->current_comp->name %>
<&| echo &>
<%= $m->current_comp->name %>
<&| echo &>
<%= $m->current_comp->name %>
<%= $m->caller_args(0) %>
</&>
</&>
EOF
			expect => <<'EOF',
test6

test6

test6
arg1
EOF
		);

#------------------------------------------------------------

    $group->add_test(	name => 'various_tags',
			path => 'filter_test/test7',
			call_path => 'filter_test/test7',
			description => 'test various tags in content',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
			component => <<'EOF',
<%method lala>
component call
</%method>
<&| filter &>
<% $m->print("this is a perl line "); %>\
<%= "substitution tag" %>
<& SELF:lala &>
<%perl>
$m->print("perl tag");
</%perl>
</&>
EOF
			expect => <<'EOF',
content returned 'this is a perl line substitution tag

component call

perl tag'
EOF
		);

#------------------------------------------------------------

    $group->add_test(	name => 'filter_with_filter',
			path => 'filter_test/test8',
			call_path => 'filter_test/test8',
			description => 'test interaction with filter section',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
			component => <<'EOF',
<&| filter &>hi ho</&>
<%filter>
s/content returned/simon says/
</%filter>
EOF
			expect => <<'EOF',
simon says 'hi ho'
EOF
		);

#------------------------------------------------------------

    $group->add_test(	name => 'top_level_content',
			description => 'test $m->content at top level is empty',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
			component => <<'EOF',
top level content is '<%= $m->content %>'
EOF
			expect => <<'EOF',
top level content is ''
EOF
		);

#------------------------------------------------------------

    $group->add_test(	name => 'filter_content',
			path => 'filter_test/test10',
			call_path => 'filter_test/test10',
			description => 'test filtering $m->content',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
			component => <<'EOF',
top
<&| double &>guts</&>
EOF
			expect => <<'EOF',
top
one
content returned 'guts'
EOF
		);

#------------------------------------------------------------

    $group->add_test(	name => 'subcomponent_filter',
			description => 'test method as filter',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
			component => <<'EOF',
<%def sad>
<%= $m->content %>? I can't help it!
</%def>
<%method happy>
<%= $m->content %>, be happy!
</%method>
<&| SELF:happy &>don't worry</&>
<&| sad &>why worry</&>
EOF
			expect => <<'EOF',

don't worry, be happy!


why worry? I can't help it!
EOF
		);

#------------------------------------------------------------

    $group->add_test( name => 'dollar_underscore',
		      description => 'Test using $_ in a filter',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',
<&| filter_test/repeat2, list => [1,2,3] &>$_ is <%= $_ %></&>
EOF
		      expect => <<'EOF',
$_ is 1
$_ is 2
$_ is 3
EOF
		    );

#------------------------------------------------------------

    $group->add_test( name => 'multi_filter',
		      description => 'Test order of multiple filters',
		      interp_params => { lexer_class => 'MasonX::Lexer::MSP' },
		      component => <<'EOF',
<&| .lc &>\
<&| .uc &>\
MixeD CAse\
</&>\
</&>\
<%def .uc>\
<%= uc $m->content %>\
</%def>
<%def .lc>\
<%= lc $m->content %>\
</%def>
EOF
		      expect => <<'EOF',
mixed case
EOF
		    );

#------------------------------------------------------------

    return $group;
}


