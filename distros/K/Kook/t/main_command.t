###
### $Release: 0.0100 $
### $Copyright: copyright(c) 2009-2011 kuwata-lab.com all rights reserved. $
### $License: MIT License $
###

use strict;
use warnings;
no warnings 'void';   # suppress 'Useless use of ... in void context'
use Data::Dumper;
use Cwd;
use File::Path;
use Oktest;
use Oktest::Util qw(read_file write_file system3);

use Kook::Main;


### hello.h
my $HELLO_H_TXT = <<'END';
	/*extern char *command;*/
	#define COMMAND "hello"
	void print_args(int argc, char *argv[]);
END
$HELLO_H_TXT =~ s/^\t//mg;

### hello1.c
my $HELLO1_C = <<'END';
	#include "hello.h"
	/*char *command = "hello";*/
	int main(int argc, char *argv[]) {
	    print_args(argc, argv);
	    return 0;
	}
END
$HELLO1_C =~ s/^\t//mg;

### hello2.c
my $HELLO2_C = <<'END';
	#include <stdio.h>
	#include "hello.h"
	void print_args(int argc, char *argv[]) {
	    int i;
	    printf("%s: argc=%d\n", COMMAND, argc);
	    for (i = 0; i < argc; i++) {
	        printf("%s: argv[%d]: %s\n", COMMAND, i, argv[i]);
	    }
	}
END
$HELLO2_C =~ s/^\t//mg;

### Kookbook.pl
my $KOOKBOOK = <<'END';
	use Cwd ('getcwd');

	my $CC = prop('CC', 'gcc');

	$kook->{default} = 'build';

	recipe "build", {
	    desc => "build all files",
	    ingreds => ["hello"],
	};

	recipe "hello", {
	    #ingreds => ["foo.o", "bar.o"],
	    desc    => "build hello command",
	    kind    => "file",
	    ingreds => ["hello1.o", "hello2.o"],
	    method  => sub {
	        my ($c) = @_;
	        my $s = join " ", @{$c->{ingreds}};
	        sys "$CC -o $c->{product} $s";
	    }
	};

	recipe "*.o", {
	    ingreds => ['$(1).c', 'hello.h'],
	    desc    => "compile *.c",
	    method  => sub {
	        my ($c) = @_;
	        sys "$CC -c $c->{ingred}";
	    }
	};

	recipe "hello.h", {
	    ingreds => ["hello.h.txt"],
	    method => sub {
	        my ($c) = @_;
	        sys "cp $c->{ingred} $c->{product}";
	    }
	};

	recipe "test1", {
	    desc   => "test of spices",
	    spices => ["-v: verbose", "-f file: file", "-i[N]: indent", "-D:", "--name=str: name string"],
	    method => sub {
	        my ($c, $opts, $rest) = @_;
	        #my @arr = map { repr($_).'=>'.repr($opts->{$_}) } sort keys %$opts;
	        #print "opts={", join(", ", @arr), "}\n";
	        my $s = join ", ", map { repr($_).'=>'.repr($opts->{$_}) } sort keys %$opts;
	        print "opts={", $s, "}\n";
	        print "rest=", repr($rest), "\n";
	    }
	};

	my $prop1 = prop('prop1', 12345);
	my $prop2 = prop('prop2', ['a', 'b', 'c']);
	my $prop3 = prop('prop3', {'x'=>10, 'y'=>20});
	my $prop4 = private_prop('prop4', 'hoge');   # private

	recipe "show-props", {
	    method => sub {
	        print '$prop1 = ', repr($prop1), "\n";
	        print '$prop2 = ', repr($prop2), "\n";
	        print '$prop3 = ', repr($prop3), "\n";
	        print '$prop4 = ', repr($prop4), "\n";
	    }
	};

	recipe "cwd", {
	    method => sub {
	        echo getcwd();
	    }
	};
END
$KOOKBOOK =~ s/^\t//mg;


###
### invoke recipe
###

topic "Kook::MainCommand", sub {

    before_all {
        mkdir "_sandbox" unless -d "_sandbox";
        chdir "_sandbox"  or die;
        write_file("hello.h.txt", $HELLO_H_TXT);
        write_file("hello1.c",    $HELLO1_C);
        write_file("hello2.c",    $HELLO2_C);
        write_file("Kookbook.pl", $KOOKBOOK);
    };

    after_all {
        chdir "..";
        rmtree "_sandbox"  or die;
    };

    before {
        my ($c) = @_;
        my ($skip) = @_;
        if ($c->{spec} =~ /^\(1st|2nd|3rd|4th\)/) {
            # pass
        }
        else {
            #for (qw(hello hello1.o hello2.o hello.h)) { unlink $_ if -f $_; }
        }
    };

    after {
        my ($c) = @_;
        if ($c->{spec} =~ /^\(1st|2nd|3rd|4th\)/) {
            # pass
        }
        else {
            #unlink(glob("hello*"));
            for (qw(hello hello1.o hello2.o hello.h)) { unlink $_ if -f $_; }
        }
    };


    ## 1st
    spec "(1st) recipe is invoked then hello should be created", sub {
        my $output = `plkook build`;
        my $expected = <<'END';
	### **** hello.h (recipe=hello.h)
	$ cp hello.h.txt hello.h
	### *** hello1.o (recipe=*.o)
	$ gcc -c hello1.c
	### *** hello2.o (recipe=*.o)
	$ gcc -c hello2.c
	### ** hello (recipe=hello)
	$ gcc -o hello hello1.o hello2.o
	### * build (recipe=build)
END
        $expected =~ s/^\t//mg;
        OK ($output) eq $expected;
    };

    ## 2nd
    spec "(2nd) invoked again then all recipes should be skipped)", sub {
        sleep 1;
        my $output = `plkook build`;
        my $expected = <<'END';
	### * build (recipe=build)
END
        $expected =~ s/^\t//mg;
        OK ($output) eq $expected;
    };

    ## 3rd
    spec "(3rd) only hello.h is touched then hello recipe should be skipped because content of *.o is not changed", sub {
        my $now = time();
        utime $now, $now, "hello.h";
        my $output = `plkook build`;
        my $expected = <<'END';
	### *** hello1.o (recipe=*.o)
	$ gcc -c hello1.c
	### *** hello2.o (recipe=*.o)
	$ gcc -c hello2.c
	### ** hello recipe=hello
	$ touch hello   # skipped
	### * build (recipe=build)
END
        $expected =~ s/^\t//mg;
        OK ($output) eq $expected;
    };

    ## 4th
    spec "(4th) hello.h.txt is updated then all recipes should not be skipped)", sub {
        sleep 1;
        my $s = $HELLO_H_TXT;
        $s =~ s/hello/HELLO/;
        write_file("hello.h.txt", $s);
        my $output = `plkook build`;
        my $expected = <<'END';
	### **** hello.h (recipe=hello.h)
	$ cp hello.h.txt hello.h
	### *** hello1.o (recipe=*.o)
	$ gcc -c hello1.c
	### *** hello2.o (recipe=*.o)
	$ gcc -c hello2.c
	### ** hello (recipe=hello)
	$ gcc -o hello hello1.o hello2.o
	### * build (recipe=build)
END
        $expected =~ s/^\t//mg;
        OK ($output) eq $expected;
    };


    ###
    ### options
    ###

    ### -h
    spec "prints help when option -h specified", sub {
        my $output = `plkook -hlL`;
        #my $main = Kook::MainCommand->new(["-hlL"], "plkook");
        #$main->invoke();
        my $expected = <<'END';
	plkook - build tool like Make, Rake, Ant, or Cook
	  -h                  : help
	  -V                  : version
	  -D[N]               : debug level (default: 1)
	  -q                  : quiet
	  -f file             : kookbook
	  -F                  : forcedly
	  -n                  : not execute (dry run)
	  -l                  : list public recipes
	  -L                  : list all recipes
	  -R                  : search Kookbook in parent directory recursively
	  --name=value        : property name and value
	  --name              : property name and value(=True)
END
        $expected =~ s/^\t//mg;
        OK ($output) eq $expected;
    };

    ### -V
    spec "prints version when option -V specified", sub {
        my $output = `plkook -V`;
        my $expected = "".$Kook::VERSION."\n";
        OK ($output) eq $expected;
        OK (length($output)) > 5;     # not empty
    };

    ### -l
    spec "prints task list when option -l specified", sub {
        my $output = `plkook -l`;
        my $expected = <<'END';
	Properties:
	  CC                   : "gcc"
	  prop1                : 12345
	  prop2                : ["a","b","c"]
	  prop3                : {"y" => 20,"x" => 10}

	Task recipes (default=build):
	  build                : build all files
	  test1                : test of spices
	    -v                     verbose
	    -f file                file
	    -i[N]                  indent
	    --name=str             name string

	File recipes:
	  hello                : build hello command
	  *.o                  : compile *.c

	(Tips: it is able to separate properties into 'Properties.pl' file.)
END
        $expected =~ s/^\t//mg;
        $output   =~ s/^\(Tips:.*\n//m;
        $expected =~ s/^\(Tips:.*\n//m;
        OK ($output) eq $expected;
    };

    ### -L
    spec "prints all of task list when option -L specified", sub {
        my $output = `plkook -L`;
        my $expected = <<'END';
	Properties:
	  CC                   : "gcc"
	  prop1                : 12345
	  prop2                : ["a","b","c"]
	  prop3                : {"y" => 20,"x" => 10}
	  prop4                : "hoge"

	Task recipes (default=build):
	  build                : build all files
	  test1                : test of spices
	    -v                     verbose
	    -f file                file
	    -i[N]                  indent
	    --name=str             name string
	  show-props           : 
	  cwd                  : 

	File recipes:
	  hello                : build hello command
	  hello.h              : 
	  *.o                  : compile *.c

	(Tips: it is able to separate properties into 'Properties.pl' file.)
END
        $expected =~ s/^\t//mg;
        $output   =~ s/^\(Tips:.*\n//m;
        $expected =~ s/^\(Tips:.*\n//m;
        OK ($output) eq $expected;
    };

    ### -D
    spec "prints debug info when option -D specified", sub {
        #print STDERR `which plkook`, "\n";
        my $output = `plkook -D build`;
        my $expected = <<'END';
	*** debug: ++ Cookbook#find_recipe(): target=build, func=, product=build
	*** debug: ++ Cookbook#find_recipe(): target=hello, func=, product=hello
	*** debug: ++ Cookbook#find_recipe(): target=hello1.o, func=, product=*.o
	*** debug: ++ Cookbook#find_recipe(): target=hello.h, func=, product=hello.h
	*** debug: ++ Cookbook#find_recipe(): target=hello2.o, func=, product=*.o
	*** debug: + begin build
	*** debug: ++ begin hello
	*** debug: +++ begin hello1.o
	*** debug: ++++ material 'hello1.c'
	*** debug: ++++ begin hello.h
	*** debug: +++++ material 'hello.h.txt'
	*** debug: ++++ create hello.h (recipe=hello.h)
	### **** hello.h (recipe=hello.h)
	$ cp hello.h.txt hello.h
	*** debug: ++++ end hello.h (content changed)
	*** debug: +++ create hello1.o (recipe=*.o)
	### *** hello1.o (recipe=*.o)
	$ gcc -c hello1.c
	*** debug: +++ end hello1.o (content changed)
	*** debug: +++ begin hello2.o
	*** debug: ++++ material 'hello2.c'
	*** debug: ++++ pass hello.h (already cooked)
	*** debug: +++ create hello2.o (recipe=*.o)
	### *** hello2.o (recipe=*.o)
	$ gcc -c hello2.c
	*** debug: +++ end hello2.o (content changed)
	*** debug: ++ create hello (recipe=hello)
	### ** hello (recipe=hello)
	$ gcc -o hello hello1.o hello2.o
	*** debug: ++ end hello (content changed)
	*** debug: + perform build (recipe=build)
	### * build (recipe=build)
	*** debug: + end build (content changed)
END
        $expected =~ s/^\t//mg;
        OK ($output) eq $expected;
        #OK ($output) eq "";
    };

    ### -D2
    spec "prints more detailed debug info when option -D2 specified", sub {
        my $output = `plkook -D2 build`;
        my $expected = <<'END';
	*** debug: specific task recipes: ["build","test1","show-props","cwd"]
	*** debug: specific file recipes: ["hello","hello.h"]
	*** debug: generic  task recipes: []
	*** debug: generic  file recipes: ["*.o"]
	*** debug: ++ Cookbook#find_recipe(): target=build, func=, product=build
	*** debug: ++ Cookbook#find_recipe(): target=hello, func=, product=hello
	*** debug: ++ Cookbook#find_recipe(): target=hello1.o, func=, product=*.o
	*** debug: ++ Cookbook#find_recipe(): target=hello.h, func=, product=hello.h
	*** debug: ++ Cookbook#find_recipe(): target=hello2.o, func=, product=*.o
	*** debug: + begin build
	*** debug: ++ begin hello
	*** debug: +++ begin hello1.o
	*** debug: ++++ material 'hello1.c'
	*** debug: ++++ begin hello.h
	*** debug: +++++ material 'hello.h.txt'
	*** debug: ++++ cannot skip: product 'hello.h' not found.
	*** debug: ++++ create hello.h (recipe=hello.h)
	### **** hello.h (recipe=hello.h)
	$ cp hello.h.txt hello.h
	*** debug: ++++ end hello.h (content changed)
	*** debug: +++ cannot skip: product 'hello1.o' not found.
	*** debug: +++ create hello1.o (recipe=*.o)
	### *** hello1.o (recipe=*.o)
	$ gcc -c hello1.c
	*** debug: +++ end hello1.o (content changed)
	*** debug: +++ begin hello2.o
	*** debug: ++++ material 'hello2.c'
	*** debug: ++++ pass hello.h (already cooked)
	*** debug: +++ cannot skip: product 'hello2.o' not found.
	*** debug: +++ create hello2.o (recipe=*.o)
	### *** hello2.o (recipe=*.o)
	$ gcc -c hello2.c
	*** debug: +++ end hello2.o (content changed)
	*** debug: ++ cannot skip: product 'hello' not found.
	*** debug: ++ create hello (recipe=hello)
	### ** hello (recipe=hello)
	$ gcc -o hello hello1.o hello2.o
	*** debug: ++ end hello (content changed)
	*** debug: + cannot skip: task recipe should be invoked in any case.
	*** debug: + perform build (recipe=build)
	### * build (recipe=build)
	*** debug: + end build (content changed)
END
        $expected =~ s/^\t//mg;
        OK ($output) eq $expected;
        #
        sleep 1;
        my $now = time();
        utime $now, $now, "hello.h";
        $output = `plkook -D2 build`;
        $expected = <<'END';
	*** debug: specific task recipes: ["build","test1","show-props","cwd"]
	*** debug: specific file recipes: ["hello","hello.h"]
	*** debug: generic  task recipes: []
	*** debug: generic  file recipes: ["*.o"]
	*** debug: ++ Cookbook#find_recipe(): target=build, func=, product=build
	*** debug: ++ Cookbook#find_recipe(): target=hello, func=, product=hello
	*** debug: ++ Cookbook#find_recipe(): target=hello1.o, func=, product=*.o
	*** debug: ++ Cookbook#find_recipe(): target=hello.h, func=, product=hello.h
	*** debug: ++ Cookbook#find_recipe(): target=hello2.o, func=, product=*.o
	*** debug: + begin build
	*** debug: ++ begin hello
	*** debug: +++ begin hello1.o
	*** debug: ++++ material 'hello1.c'
	*** debug: ++++ begin hello.h
	*** debug: +++++ material 'hello.h.txt'
	*** debug: ++++ recipe for 'hello.h' can be skipped.
	*** debug: ++++ skip hello.h (recipe=hello.h)
	*** debug: +++ child file 'hello.h' is newer than product 'hello1.o'.
	*** debug: +++ cannot skip: there is newer file in children than product 'hello1.o'.
	*** debug: product 'hello1.o' is renamed to '/var/folders/FD/FDjI6Ce4H7eSxs5w+QNj+k+++TI/-Tmp-/5UHUs_n8qN'
	*** debug: +++ create hello1.o (recipe=*.o)
	### *** hello1.o (recipe=*.o)
	$ gcc -c hello1.c
	*** debug: +++ end hello1.o (content not changed, mtime updated)
	*** debug: temporary file '/var/folders/FD/FDjI6Ce4H7eSxs5w+QNj+k+++TI/-Tmp-/5UHUs_n8qN' is removed.
	*** debug: +++ begin hello2.o
	*** debug: ++++ material 'hello2.c'
	*** debug: ++++ pass hello.h (already cooked)
	*** debug: +++ child file 'hello.h' is newer than product 'hello2.o'.
	*** debug: +++ cannot skip: there is newer file in children than product 'hello2.o'.
	*** debug: product 'hello2.o' is renamed to '/var/folders/FD/FDjI6Ce4H7eSxs5w+QNj+k+++TI/-Tmp-/lQlyRgrTBk'
	*** debug: +++ create hello2.o (recipe=*.o)
	### *** hello2.o (recipe=*.o)
	$ gcc -c hello2.c
	*** debug: +++ end hello2.o (content not changed, mtime updated)
	*** debug: temporary file '/var/folders/FD/FDjI6Ce4H7eSxs5w+QNj+k+++TI/-Tmp-/lQlyRgrTBk' is removed.
	*** debug: ++ recipe for 'hello' can be skipped.
	### ** hello recipe=hello
	*** debug: ++ touch and skip hello (recipe=hello)
	$ touch hello   # skipped
	*** debug: + cannot skip: task recipe should be invoked in any case.
	*** debug: + perform build (recipe=build)
	### * build (recipe=build)
	*** debug: + end build (content changed)
END
        $expected =~ s/^\t//mg;
        $output   =~ s/temporary file '.*' is removed/temporary file '...' is removed/g;
        $output   =~ s/is renamed to '.*'/is renamed to '...'/g;
        $expected =~ s/temporary file '.*' is removed/temporary file '...' is removed/g;
        $expected =~ s/is renamed to '.*'/is renamed to '...'/g;
        OK ($output) eq $expected;
    };

    ### -q
    spec "prints nothing when option -q specified", sub {
        pre_cond ("hello")->not_exist();
        my $output = `plkook -q build`;
        OK ($output) eq "";
        OK ("hello")->file_exists();
    };

    ### -f file
    spec "changes bookname when option -f specified", sub {
        rename "Kookbook.pl", "_Kookbook.xxx";
        at_end { rename "_Kookbook.xxx", "Kookbook.pl" };
        pre_cond ("hello")->not_exist();
        pre_cond ("hello1.o")->not_exist();
        my $output = `plkook -f _Kookbook.xxx hello1.o`;
        OK ("hello")->not_exist();
        OK ("hello1.o")->file_exists();
    };

    spec "reports error when argument is not passed to '-f'", sub {
        my ($output, $errmsg) = Oktest::Util::system3('plkook test1 -f');
        OK ($output) eq "### * test1 (recipe=test1)\n";
        OK ($errmsg) eq "-f: file required.\n";
    };

    ### -F
    spec "invokes commands forcedly when option -F specified", sub {
        my $output = `plkook build`;
        my $expected = $output;
        #
        $output = `plkook build`;
        OK ($output) eq "### * build (recipe=build)\n";
        #
        $output = `plkook -F build`;
        OK ($output) eq $expected;
    };

    ### -n
    spec "not execute when option -n specified", sub {
        pre_cond ("hello.h")->not_exist();
        pre_cond ("hello")->not_exist();
        my $output = `plkook -n build`;
        OK ("hello.h")->not_exist();
        OK ("hello")->not_exist();
        my $expected = <<'END';
	### **** hello.h (recipe=hello.h)
	$ cp hello.h.txt hello.h
	### *** hello1.o (recipe=*.o)
	$ gcc -c hello1.c
	### *** hello2.o (recipe=*.o)
	$ gcc -c hello2.c
	### ** hello (recipe=hello)
	$ gcc -o hello hello1.o hello2.o
	### * build (recipe=build)
END
        $expected =~ s/^\t//mg;
        OK ($output) eq $expected;
    };

    ### -R
    spec "search Kookbook in parent directory when option -R specified", sub {
        my $cwd;
        $cwd = getcwd();
        CORE::mkdir "foo";
        CORE::mkdir "foo/bar";
        chdir "foo/bar";
        at_end {
            chdir $cwd;
            CORE::rmdir "foo/bar";
            CORE::rmdir "foo";
        };
        #
        my ($output, $errmsg);
        ($output, $errmsg) = system3('plkook cwd');
        OK ($output) eq "";
        OK ($errmsg) eq "Kookbook.pl: not found.\n";
        #
        ($output, $errmsg) = system3('plkook -f Kookbook.pl cwd');
        OK ($output) eq "";
        OK ($errmsg) eq "-f Kookbook.pl: not found.\n";
        #
        ($output, $errmsg) = system3('plkook -R cwd');   # change cwd to parent dir
        my $expected = <<END;
	### * cwd (recipe=cwd)
	\$ echo $cwd
	$cwd
END
        $expected =~ s/^\t//mg;
        OK ($output) eq $expected;
        OK ($errmsg) eq "";
        #
    };


    ###
    ### spices
    ###

    case_when "spices specified", sub {

        spec "passes them into method block", sub {
            my ($output, $errmsg) = system3('plkook test1 -vDf file1.txt -i AAA BBB');
            my $expected = <<'END';
	### * test1 (recipe=test1)
	opts={"D"=>1, "f"=>"file1.txt", "i"=>1, "v"=>1}
	rest=["AAA","BBB"]
END
            $expected =~ s/^\t//mgm;
            OK ($output) eq $expected;
            OK ($errmsg) eq "";
        };

        spec "reports error when invalid option (-ifoo) specified", sub {
            my ($output, $errmsg) = system3('plkook test1 -ifoo AAA BBB');
            OK ($output) eq "### * test1 (recipe=test1)\n";
            OK ($errmsg) eq "-ifoo: integer required.\n";
        };

    };


    ###
    ### others
    ###

    ## $kook->{default}
    spec 'invokes $kook->{default} task when it is specified', sub {
        my ($output, $errmsg) = system3('plkook');
        my $expected = <<'END';
	### **** hello.h (recipe=hello.h)
	$ cp hello.h.txt hello.h
	### *** hello1.o (recipe=*.o)
	$ gcc -c hello1.c
	### *** hello2.o (recipe=*.o)
	$ gcc -c hello2.c
	### ** hello (recipe=hello)
	$ gcc -o hello hello1.o hello2.o
	### * build (recipe=build)
END
        $expected =~ s/^\t//mg;
        OK ($output) eq $expected;
        OK ($errmsg) eq "";
    };

    ## properties
    spec "show default properties", sub {
        my ($output, $errmsg) = system3('plkook show-props');
        my $expected = <<'END';
	### * show-props (recipe=show-props)
	$prop1 = 12345
	$prop2 = ["a","b","c"]
	$prop3 = {"y" => 20,"x" => 10}
	$prop4 = "hoge"
END
        $expected =~ s/^\t//mg;
        OK ($output) eq $expected;
        OK ($errmsg) eq "";
    };

    spec "show properties with specified values", sub {
        my ($output, $errmsg) = system3('plkook --prop1=456 --prop4=geji show-props');
        my $expected = <<'END';
	### * show-props (recipe=show-props)
	$prop1 = 456
	$prop2 = ["a","b","c"]
	$prop3 = {"y" => 20,"x" => 10}
	$prop4 = "geji"
END
        $expected =~ s/^\t//mg;
        OK ($output) eq $expected;
        OK ($errmsg) eq "";
    };


    ###
    ### error: invalid options
    ###

    spec "reports error when not-an-integer specified for -D", sub {
        my ($output, $errmsg) = system3('plkook -Dh build');
        OK ($output) eq "";
        OK ($errmsg) eq "-Dh: integer required.\n";
    };

    spec "reports error when argument is not passed for -f", sub {
        my ($output, $errmsg) = system3('plkook -f');
        OK ($output) eq "";
        OK ($errmsg) eq "-f: file required.\n";
    };

    spec "reports error when argument file of -f is not found", sub {
        my ($output, $errmsg) = system3('plkook -foobar');
        OK ($output) eq "";
        OK ($errmsg) eq "-f oobar: not found.\n";
    };

    spec "reports error when argument of -f is directory", sub {
        my ($output, $errmsg) = system3('plkook -f..');
        OK ($output) eq "";
        OK ($errmsg) eq "-f ..: not a file.\n";
    };

    ### error: no recipe or material
    spec "reports error when there is no recipes which matches to specified topic", sub {
        pre_cond ("Kookbook.pl")->file_exists();  ### DEBUG
        Oktest::Util::write_file("/tmp/Kookbook.pl", Oktest::Util::read_file("Kookbook.pl"));
        my ($output, $errmsg) = system3('plkook foobar');
        OK ($output) eq "";
        OK ($errmsg) eq "foobar: no such recipe or material.\n";
        #
        ($output, $errmsg) = system3('plkook hello3.o');
        OK ($output) eq "";
        OK ($errmsg) eq "hello3.c: no such recipe or material (required for 'hello3.o').\n";
    };

    ### error: no product specified
    spec "reports error when no product specified", sub {
        my $s = read_file('Kookbook.pl');
        #$s =~ s/^(\$kook_default.*)$/#$1/m;
        $s =~ s/^(\$kook->\{default\}.*)$/#$1/m;
        write_file('Kookbook.pl', $s);
        my ($output, $errmsg) = system3('plkook');
        my $expected = <<'END';
	*** plkook: target is not given.
	*** 'plkook -l' or 'plkook -L' shows recipes and properties.
	*** (or set '$kook->{default}' in your kookbook.)
END
        $expected =~ s/^\t//mg;
        OK ($errmsg) eq $expected;
        OK ($output) eq "";
    };


};


Oktest::main() if $0 eq __FILE__;
1;
