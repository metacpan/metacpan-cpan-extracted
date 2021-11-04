#!/usr/bin/env perl 

use t::setup;

use FindApp::Utils <:{foreign,package,syntax,list}>;

require_ok(my $Class  = __TEST_CLASS__ );
require_ok(my $Top   = -$Class        );
require_ok(my $Parent =  $Class  - 1   );
require_ok(my $Group  =  $Parent->add(<State Group>));

UNPACKAGE for $Class, $Parent, $Top, $Group;

my $Have_Run_The_Finder = 0;

run_tests();

sub cannery_tests {

    my @methods = qw(
        constraint_text         
        copy_founds_to_globals  
        export_to_env          
        findapp               
        findapp_and_export   
        findapp_root        
        findapp_root_from_path  
        path_passes_constraints
        reset_all_groups      
        shell_settings       
        show_shell_var      
    );

    for my $method (@methods) {
        ok $Class->can($method),         "$Class can $method";
    }

}

sub erasure_tests {

    # Some of these were erased; others just 
    # aren't supposed to be on this class.

    my @erased_mine = qw(
        constraint_failure     
        generate_helper_methods 
        apply                   
    );

    my @erased_imports = qw(
        alldir_map
        debug
        ENTER_TRACE
        getcwd
        method_map
        PACKAGE
        panic
        UNPACKAGE
    );

    my @not_my_methods = qw(
        app_root
        copy
        import
        new
        old
        origin
        unbless
    );

    # The latter set is expecially important to make sure are gone
    # from the main object, to make sure nothing leaks.
    my @missing = (@erased_mine, @erased_imports);
    for my $func (@missing) {
        ok !$Top->can($func),   "root class $Top can't $func";
    }

    push @missing, @not_my_methods;
    for my $func (@missing) {
        ok !$Class->can($func), "test class $Class can't $func";
    }

}

sub reset_tests {
    my $ob = $Top->new;

    lives_ok { $ob->reset_all_groups }           "reset found initially";

    $ob->set_bindirs_found("/some/bin");
    $ob->set_libdirs_found("/some/lib");
    $ob->set_mandirs_found("/some/man");

    cmp_ok $ob->get_bindirs_found, "eq", "/some/bin",   "found bindir set";
    cmp_ok $ob->get_libdirs_found, "eq", "/some/lib",   "found libdir set";
    cmp_ok $ob->get_mandirs_found, "eq", "/some/man",   "found mandir set";

    $ob->add_bindirs_found("/more/bin");
    $ob->add_libdirs_found("/more/lib");
    $ob->add_mandirs_found("/more/man");

    my $want = 2;
    my @found = $ob->get_bindirs_found;
    cmp_ok scalar(@found), "==", $want,         "found $want bindirs set: @found";

    my @dirnames = $ob->canonical_subdirs;
    ok @dirnames, "found @dirnames";
    for my $dir (@dirnames) { 
        cmp_ok $ob->group($dir)->found->count, "==", $want,   
                                                "group($dir)->found->count is $want $dir dirs set";
        @found = $ob->group($dir)->found;
        cmp_ok scalar(@found), "==", $want,     "fetched $want $dir dirs set";
        my $meth = "get_${dir}dirs_found";
        @found = $ob->$meth; 
        my $found = @found;
        cmp_ok $found, "==", $want,             "$meth found $want $dir dirs set before reset";
        my $string = "/more/$dir /some/$dir"; 
        cmp_ok "@found", "eq", $string,         "$meth found $string";
    }

    lives_ok { $ob->reset_all_groups }           "reset found again";

    for my $dir (@dirnames) { 
        cmp_ok $ob->group($dir)->found->count, "==", 0,   "found 0 $dir dirs set after reset";
        my $meth = "get_${dir}dirs_found";
        my @found = $ob->$meth; 
        my $found = @found;
        cmp_ok $found, "==", 0,                 "$meth found 0 $dir dirs set after reset";
    }
}

sub constraint_test_tests {
    my $ob = $Top->new;

    my $text = $ob->constraint_text;
    my $want = "lib/ in root";
    is $text, $want,                            "found expected initial constraint: $want";

    $ob->rootdir_wanted->reset;
    $text = $ob->constraint_text;
    is $text, "",                               "found no constraint after resetting root wanted";

    my @dirnames = $ob->canonical_subdirs;
    $ob->rootdir_wanted->set(@dirnames);
    $text = $ob->constraint_text;
    $want = "bin, lib, and man in root";
    is $text, $want,                            "found expected constraint after setting root wanted";

    $ob->rootdir_wanted->reset;
    $text = $ob->constraint_text;
    is $text, "",                               "found no constraint after resetting root wanted";

    for my $dir (@dirnames) {
        $ob->allowed($dir)->set($dir);
    }
    $ob->add_bindirs_allowed("scripts");

    $ob->set_bindirs_wanted(<four call ing birds>);
    $ob->set_libdirs_wanted(<three french hens>);
    $ob->set_mandirs_wanted(<two turtledoves>);
    $ob->set_rootdir_wanted(<a partridge in a pear tree>);
    $text = $ob->constraint_text;
    $want = q(a, in, partridge, pear, and tree in root; birds, call, four, and ing in bin or scripts; french, hens, and three in lib; and turtledoves and two in man);
    is $text, $want,        "found expected constraint after setting up Christmas song";

    $ob->rootdir_wanted->reset;
    $ob->libdirs_wanted->reset;
    $text = $ob->constraint_text;
    $want = q(birds, call, four, and ing in bin or scripts and turtledoves and two in man);
    is $text, $want,        "found expected constraint after pruning Christmas tree";

}

sub environment_tests {
    my $ob = $Top->new;
    my @vars = <APP_ROOT PATH MANPATH PERL5LIB>;
    for my $var (@vars) { 
        is $ob->show_shell_var($var), q(),      "shell var $var would be empty on empty args";
    }

    my @dirs = qw(/eu/re/ka fixme);

    $dirs[-1] = "/my/root/rhymes/with/foot";
    check_mono_variable($ob, APP_ROOT => @dirs);

    $dirs[-1] = "/my/execs";
    check_poly_variable($ob, PATH => @dirs);

    $dirs[-1] = "/my/missing/documentation/TODO";
    check_poly_variable($ob, MANPATH => @dirs);

    $dirs[-1] = "/my/missing/documentation/TODO";
    check_poly_variable($ob, PERL5LIB => @dirs);

    $dirs[-1] = "/my/invented/config/dir";
    check_mono_variable($ob, BOGOVAR => @dirs);

}

sub check_mono_variable { check_variable(0, @_) }
sub check_poly_variable { check_variable(1, @_) }
sub check_variable {
    my($is_poly, $self, $name, @list) = @_;
    my $bucky =      '$' . $name;
    my $want  = join ":" , @list;
    my $str = $self->show_shell_var($name, @list);
    ok    chomp($str),                  "chomped terminal newline from $name str";
    like        $str,  qr/\b$name\b/,   "found subdir name $name in '$str'";
    if ($is_poly) { 
        isnt  index($str, $bucky), -1,  "$name is poly so found old value for it";
    } else {
        is    index($str, $bucky), -1,  "$name isn't poly so found no old value for it";
    }
    isnt      index($str, $want),  -1,  "found $want in setting";
}

sub settings_tests {
    my $ob = $Top->new;

    my $shellese = $ob->shell_settings;
    is $shellese, q(),                          "shellese empty on new object";

    my($home) = <~>;
    my @bins  = </{some,other}/bin>;
    my @libs  = </{my,your,their}dir/lib>;
    my @mans  = "/lost/docs";

    my @test_dirs = ($home, @bins, @libs, @mans);
    my $test_dirs = @test_dirs;
    is $test_dirs, 7,                           "plan to load 7 dirs";

    $ob->set_rootdir_found($home);
    $ob->set_bindirs_found(@bins);
    $ob->set_libdirs_found(@libs);
    $ob->set_mandirs_found(@mans);

    for my $dir ($ob->canonical_subdirs) {
        my $own_dir = "$home/$dir";
        $ob->group($dir)->found->add($own_dir);
        push @test_dirs, $own_dir;
        $test_dirs++;
    }

    $shellese = $ob->shell_settings;
    isnt($shellese, q(),                        "shellese no longer empty")
        && note $shellese;
    like $shellese, qr/;\R\z/,                  "shellese ends in semicolon, return";

    my @vars = <APP_ROOT PATH MANPATH PERL5LIB>;
    for my $var (@vars) { 
        isnt index($shellese,     $var ), -1,   "shellese contains var $var";
        is   index($shellese, "XYZ$var"), -1,   "shellese lacks var XYZ$var";
    }

    my $line_count =()= $shellese =~ /;\R/g;
    my $var_count  =    @vars;
    is $line_count, $var_count,                 "found as many lines as variables ($line_count)";

    for my $want_dir (@test_dirs) {
        isnt index($shellese, $want_dir), -1,   "shellese contains dir $want_dir";
    }

}

# This is a little tricky because it only works 
# for real paths, not made-up ones for tests.
sub findapp_tests {
    my $ob = $Top->new;

    $ob->default_origin("script");
    $ob->use_no_devperls;

    rootdir_has $ob qw{
        README
        Changes
        Makefile.PL
        bin/
        lib/
        t/setup.pm
    };

    libdirs_are $ob qw{
        lib
        t/lib
    };
    
    libdirs_have $ob qw{
        FindApp.pm
        FindApp::Utils
        FindApp::Test::Utils
    };
   
    bindirs_are $ob qw{
        bin
    };
  
    bindirs_have $ob qw{
        findapp
    };
 
    mandirs_have $ob qw{
        man1/
        man3/
    };

    mandirs_are $ob qw{
        t/testroot/sample_man
    };

    my $ctext = $ob->constraint_text;
    note("Distribution directory expects to have $ctext.");

    require File::Spec;
    my @bad_dirs  = (
        File::Spec->rootdir,
        File::Spec->tmpdir,
        qw( 
            /
            /tmp
            /usr/tmp
            /adsflkj 
            /ab\cd/ef\yzyyx 
        ),
    );
    my @glad_dirs = map { dirname abs_path } $0, $INC{"$Top.pm"};

    # The glad dirs will fail because this is specifically
    # an absolute path check not a check for anywhere above that point.
    for my $dir (@bad_dirs, @glad_dirs) {
        ok !$ob->path_passes_constraints($dir), "$dir fails constraint tests";
    }

    # Unlike this one, which keeps going up from the starting point, 
    # applying constraints till it finds one that works.
    for my $dir (@glad_dirs) {
        my $root = $ob->findapp_root_from_path($dir);
        isnt $root, undef, "found app root starting from $dir";
        #ok $root, 
    }

    lives_ok { 
        $ob->findapp;
        $Have_Run_The_Finder++;
    } "HIP HIP HURRAY! invoking ob->findapp lives ok";

    #diag($ob);

    note($ob->shell_settings);

    for my $dir ($ob->group_names) {
        my @got = $ob->group($dir)->found;
        ok 0+@got, "group $dir found at least one item: @got";
    }

}

# This relies on ordering: its name started with "global"
# will run after the finder, starting with "findapp".
# The first test will fail if this requirement isn't met.
sub global_variable_tests {
    ok($Have_Run_The_Finder, "findapp has run, and so copy_founds_to_globals must have run");

    package Sneaky::Pete;
    use Test::More;
    BEGIN { use_ok("FindApp::Vars", ":app") }

    for ($Root) { 
        ok length,          q[$Root not empty]    ;
        ok -d,             qq[root dir $_ exists] ;
    }

    # These numbers derive from the findapp_tests
    # run above.
    is 0+@Bin, 1,           q[@Bin has 1 bin dir] ;
    is 0+@Lib, 2,           q[@Lib has 2 lib dirs];
    is 0+@Man, 1,           q[@Man has 1 man dir] ;

    for (@Bin) { ok -d,    qq[bin dir $_ exists]  }
    for (@Lib) { ok -d,    qq[lib dir $_ exists]  }
    for (@Man) { ok -d,    qq[man dir $_ exists]  }
 }


__END__
