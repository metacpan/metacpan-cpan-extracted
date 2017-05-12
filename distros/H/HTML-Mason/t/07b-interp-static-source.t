use strict;
use warnings;

use File::Spec;
use HTML::Mason::Tests;
use HTML::Mason::Tools qw(load_pkg);
use IO::File;

package HTML::Mason::Commands;
sub write_component
{
    my ($comp, $text) = @_;
    my $file = $comp->source_file;
    my $fh = new IO::File ">$file" or die "Cannot write to $file: $!";
    $fh->print($text);
    $fh->close();
}

package main;
my $tests = make_tests();
$tests->run;

sub make_tests
{
    my $group = HTML::Mason::Tests->tests_class->new( name => 'interp-static-source',
                                                      description => 'interp static source mode' );

#------------------------------------------------------------

    foreach my $i (1..4) {
        $group->add_support( path => "support/remove_component$i",
                             component => "I will be removed ($i).\n",
                           );
    }

#------------------------------------------------------------

    foreach my $i (1..4) {
        $group->add_support( path => "support/change_component$i",
                             component => "I will be changed ($i).\n",
                           );
    }

#------------------------------------------------------------

    $group->add_test( name => 'change_component_without_static_source',
                      description => 'test that on-the-fly component changes are detected with static_source=0',
                      component => <<'EOF',
<& support/change_component1 &>\
<%perl>
sleep(2);  # Make sure timestamp changes
write_component($m->fetch_comp('support/change_component1'), "I have changed!\n");
</%perl>
<& support/change_component1 &>
EOF
                      expect => <<'EOF',
I will be changed (1).
I have changed!
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'change_component_with_static_source',
                      description => 'test that changing component has no effect with static_source=1',
                      interp_params => { static_source => 1 },
                      component => <<'EOF',
<& support/change_component2 &>\
<%perl>
sleep(1);  # Make sure timestamp changes
write_component($m->fetch_comp('support/change_component2'), "I have changed!\n");
my $comp = $m->interp->load("/interp-static-source/support/change_component2");
$m->comp($comp);
</%perl>
<& support/change_component2 &>
EOF
                      expect => <<'EOF',
I will be changed (2).
I will be changed (2).
I will be changed (2).
EOF
                    );

#------------------------------------------------------------

    my $static_source_touch_file = File::Spec->catfile($group->base_path, '.__static_source_touch');
    $group->add_test( name => 'change_component_with_static_source_touch_file',
                      description => 'test that changing component has no effect until touch file is touched',
                      interp_params => { static_source => 1,
                                         static_source_touch_file => $static_source_touch_file },
                      component => <<'EOF',
<%perl>
my $path = "/interp-static-source/support/change_component3";
$m->comp($path);
sleep(1);  # Make sure timestamp changes
write_component($m->fetch_comp('support/change_component3'), "I have changed!\n");
$m->interp->check_static_source_touch_file;
$m->comp($path);
my $touch_file = $m->interp->static_source_touch_file;
my $fh = new IO::File ">$touch_file"
   or die "cannot write to '$touch_file': $!";
$fh->close();
$m->interp->check_static_source_touch_file;
$m->comp($path);
</%perl>
EOF
                      expect => <<'EOF',
I will be changed (3).
I will be changed (3).
I have changed!
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'remove_component_without_static_source',
                      description => 'test that removing source causes component not found with static_source=0',
                      component => <<'EOF',
<& support/remove_component1 &>
<%perl>
my $file = $m->fetch_comp('support/remove_component1')->source_file;
unlink($file) or die "could not unlink '$file'";
</%perl>
<& support/remove_component1 &>
EOF
                      expect_error => qr/could not find component for path/,
                    );

#------------------------------------------------------------

    $group->add_test( name => 'remove_component_with_static_source',
                      description => 'test that removing source has no effect with static_source=1',
                      interp_params => { static_source => 1 },
                      component => <<'EOF',
<%init>
# flush_code_cache actually broke this behavior at one point
$m->interp->flush_code_cache;
</%init>

<& support/remove_component2 &>
<%perl>
my $file = $m->fetch_comp('support/remove_component2')->source_file;
unlink($file) or die "could not unlink '$file'";
my $comp = $m->interp->load("/interp-static-source/support/remove_component2")
  or die "could not load component";
$m->comp($comp);
</%perl>
<& support/remove_component2 &>
EOF
                      expect => <<'EOF',

I will be removed (2).

I will be removed (2).
I will be removed (2).
EOF
                    );

#------------------------------------------------------------

    $group->add_test( name => 'flush_code_cache_with_static_source',
                      description => 'test that code cache flush & object file removal works with static_source=1',
                      interp_params => { static_source => 1 },
                      component => <<'EOF',
<& support/change_component4 &>
<%perl>
write_component($m->fetch_comp('support/change_component4'), "I have changed!\n");

# Not enough - must delete object file
$m->interp->flush_code_cache;
my $comp = $m->interp->load("/interp-static-source/support/change_component4");
$m->comp($comp);

# This should work
unlink($comp->object_file);
undef $comp;
$m->interp->flush_code_cache;
my $comp2 = $m->interp->load("/interp-static-source/support/change_component4");
$m->comp($comp2);
</%perl>
<& support/change_component4 &>
EOF
                      expect => <<'EOF',
I will be changed (4).

I will be changed (4).
I have changed!
I have changed!
EOF
                    );

    return $group;
}
