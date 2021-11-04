#!/usr/bin/env perl 

use t::setup;
use FindApp::Utils qw(
    :foreign
    :package
    :syntax
    :list
);

my $MIN_GROUPS    = 4;
my $MIN_SUBGROUPS = $MIN_GROUPS - 1;

my $BAD_ARGS   = qr/invalid arguments/;
my $BAD_DEF    = qr/default origin must be/;
my @ATTRS      = map {uc} qw(origin default groups);

require_ok(my $Test_Class   = __TEST_CLASS__         );
require_ok(my $Root_Class   = -$Test_Class           );
require_ok(my $Parent_Class =  $Test_Class - 1       );
require_ok(my $Group_Class  =  $Test_Class + "Group" );

UNPACKAGE for $Test_Class, $Parent_Class, $Root_Class, $Group_Class;

sub attribute_tests {
    my $ob = $Root_Class->new;
    ok $ob, "created $Root_Class object";
    for my $attr (@ATTRS) {
        ok $Test_Class->can($attr),                "test class $Test_Class class can $attr";
        ok $Parent_Class->can($attr),              "parent class $Parent_Class class can $attr";
        ok $Root_Class->can($attr),                "root class $Root_Class class can $attr";
        ok $ob->can($attr),                        "root class $Root_Class object can $attr";
        is $ob->$attr, "${Test_Class}::${attr}",   "object->$attr eq ${Test_Class}::${attr}";
        ok exists $ob->{$ob->$attr},               "$attr exists";
    }

}

# These go here because they're in the State class, but we can't actually
# do any real state testing.
sub app_root_tests {
    my @fake_attrs = qw(app_root has_app_root);
    my $ob = $Root_Class->new;

    ok !$ob->has_app_root,                         "no has_app_root yet";
    is  $ob->app_root, undef,                      "and app_root is undef";

    my $target = "/eureka/el/dorado";

    # This is a fake attribute, which really just goes off this:
    my $first = $ob->group("root")->found->set($target)->first; 
    is $first, $target,                            "tried to set root found to $target";
    ok $ob->has_app_root,                          "now has_app_root think it has found it";
    is $ob->app_root, $target,                     "and app_root is indeed $target";
}

sub throw_tests { 
    my $ob = $Root_Class->new;

    throws_ok { $ob->default_origin("bad") }    $BAD_DEF,  "default_origin bad"  . " throws $BAD_DEF";
    # defeat stupid prototype on &throws_ok
    local   *arg;
    sub      arg       (&@);
    function arg => sub(&@) { &throws_ok(shift, $BAD_ARGS, "@_"                  . " throws $BAD_ARGS") };

    # This would be cleaner with a nice #define macro.
    arg { $ob->has_origin   (0)      } has_origin   => 0           ;
    arg { $ob->has_origin   (1)      } has_origin   => 1           ;
    arg { $ob->has_origin   (0, 1)   } has_origin   => 0, 1        ;
    arg { $ob->origin       (undef)  } origin       => "undef"     ;
    arg { $ob->origin       (1, 2)   } origin       => 1, 2        ;
    arg { $ob->reset_origin (0)      } reset_origin => 0           ;
    arg { $ob->reset_origin (1)      } reset_origin => 1           ;
    arg { $ob->prefers_dot  (0)      } prefers_dot  => 0           ;
    arg { $ob->prefers_dot  (1)      } prefers_dot  => 1           ;
    arg { $ob->prefers_dot  (undef)  } prefers_dot  => "undef"     ;
    arg { $ob->has_app_root (0)      } has_app_root => 0           ;
    arg { $ob->has_app_root (1)      } has_app_root => 1           ;
    arg { $ob->has_app_root (0, 1)   } has_app_root => 0, 1        ;
    arg { $ob->app_root     (undef)  } app_root     => "undef"     ;
    arg { $ob->app_root     (0)      } app_root     => 0           ;
    arg { $ob->app_root     (1)      } app_root     => 1           ;
    arg { $ob->app_root     (0, 1)   } app_root     => 0, 1        ;
 
}

sub origin_tests {
    my  $ob = $Root_Class->new;

    ok !$ob->has_origin,                                "no origin on new object";
    is  $ob->default_origin, "script",                  "origin defaults to script";
    ok !$ob->prefers_dot,                               "object does not prefer dot";

    my $dir    = dirname($0);
    ok $dir,                                            "dir $dir not insane";
    my $origin = $ob->origin;
    ok index($origin, $dir, -length($dir)),             "unset origin $origin ends in $dir";

    my $new_origin = "s/ome/wher/e";

    ok  $ob->origin($new_origin),                       "origin ob $new_origin";
    is  $ob->origin, $new_origin,                       "ob->origin is now $new_origin";
    is  $ob->reset_origin, $new_origin,                 "ob->reset_origin is $new_origin";
    ok !$ob->has_origin,                                "object no longer has an origin";
    is  $ob->default_origin("cwd"), "cwd",              "default_origin now cwd";
    ok  $ob->prefers_dot,                               "object now prefers dot";

    my $cwd = +getcwd;

    ok !$ob->has_origin,                                "object still has no origin";
    is  $ob->origin, $cwd,                              "origin is now $cwd";
    ok  $ob->has_origin,                                "object now has an origin";

}

sub groups_tests {
    my  $ob = $Root_Class->new;

    my $group;
    ok $group = $ob->group,                              "found a group set";
    is reftype($group), "HASH",                          "and it's a hash ref"; 
    cmp_ok scalar(keys %$group),  ">=", $MIN_GROUPS,     "at least $MIN_GROUPS groups";

    while (my($name, $perms) = each %$group) {
        cmp_ok $ob->group($name), "==",    $perms,       "group($name) found same subgroup";
        is     $ob->group(lc $name)->name, $name,        "name of group(\L$name\E) is $name";
        is     $ob->group(uc $name)->name, $name,        "name of group(\U$name\E) is $name";
        is     blessed($perms),            $Group_Class, "type of group($name) is $Group_Class";
    }

    my @groups      = $ob->groups;
    my @group_names = $ob->group_names;
    my $name_count  = @groups;
    cmp_ok scalar(@groups), "==", scalar(@group_names),  "same number of groups as group_names ($name_count)";

    @groups         = $ob->subgroups;
    @group_names    = $ob->subgroup_names;
    $name_count     --;
    cmp_ok scalar(@groups), "==", scalar(@group_names),  "same number of subgroups as subgroup_names ($name_count)";

    ok !grep(/^root$/, @group_names),                    "root is not a subgroup";

}

sub envar_tests {
    my $ob = $Root_Class->new;

    my %exported = map { $_ => 1 } $ob->exported_envars;

    ok  $exported{ '$Root' },                            q($Root_Class is an exported envar);
    ok !$exported{ '@Root' },                            q(@Root isn't an exported envar);

    for my $name ($ob->subgroup_names) {
        my $varname = ucfirst $name;
        ok $exported{ '$' . $varname },                  "\$$varname is an exported envar";
        ok $exported{ '@' . $varname },                  "\@$varname is an exported envar";
    }

}

sub canonical_subdirs_tests {
    my $ob = $Root_Class->new;

    my @mindirs = +BLM;
    my @subdirs = $ob->canonical_subdirs;

    my $subdirs = @subdirs;
    cmp_ok $subdirs, ">=", $MIN_SUBGROUPS,              "(@subdirs)=$subdirs >= $MIN_SUBGROUPS canonical subdirs";

    my %have = map { $_ => 1 } @subdirs;
    my %want = map { $_ => 1 } @mindirs;

    ok !$have{root},                                    "don't have root as canonical subdir";
    ok !$want{root},                                    "don't want root as canonical subdir";

    my @extras = sort grep { !$want{$_} } keys %have;
    delete @want{@subdirs};

    (ok !%want,                                         "found minimal subdirs " . commify_and(@mindirs))
        || diag "subdirs missing: "                                              . commify_and(sort keys %want);

    @extras && diag "found these extra subdirs beyond minimal set: "             . commify_and(@extras);
}


sub cannery_tests {
    my @methods = qw(
        canonical_subdirs
        exported_envars

        allocate_groups
        group
        group_names
        groups
        subgroup_names
        subgroups

        prefers_dot

        has_origin
        default_origin
        origin
        reset_origin

        has_app_root
        app_root
    );

    my $ob = $Root_Class->new;

    for my $method (@methods) {
        ok $ob->can($method),           "$Root_Class can $method";
    }

}

run_tests();


__END__
