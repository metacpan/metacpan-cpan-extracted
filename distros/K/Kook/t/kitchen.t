###
### $Release: 0.0100 $
### $Copyright: copyright(c) 2009-2011 kuwata-lab.com all rights reserved. $
### $License: MIT License $
###

use strict;
use warnings;
no warnings 'void';   # suppress 'Useless use of ... in void context'
use Data::Dumper;
use File::Path;
use File::Basename;

use Oktest;
use Oktest::Util qw(write_file capture);

use Kook;
use Kook::Cookbook;
use Kook::Kitchen;
use Kook::Config;
use Kook::Util qw(mtime);


###
### helpers
###
sub _create_kitchen {
    my ($kookbook_content) = @_;
    my $bookname = '_Kookbook.pl';
    write_file($bookname, $kookbook_content);
    my $cookbook = Kook::Cookbook->new($bookname);
    my $kitchen = Kook::Kitchen->new($cookbook);
    unlink $bookname;
    return $kitchen;
}




###
### pre_task
###

topic "Kook::Kitchen", sub {

    my $CWD;

    before_all {
        $CWD = Cwd::getcwd();
        mkdir "_sandbox" unless -d "_sandbox";
        chdir "_sandbox"  or die $!;
    };

    after_all {
        #unlink glob('hello*');
        chdir $CWD  or die $!;
        rmtree "_sandbox"  or die $!;
    };



    ###
    ### Kook::Kitchen  # tree, not looped
    ###

    case_when "recipe tree has no loop", sub {

        my $HELLO_C = <<'END';
	#include <stdio.h>
	#include "hello.h"
	int main(int argc, char *argv[]) {
	    printf("%s: argc=%d\n", command, argc);
	    return 0;
	}
END

        my $HELLO_H = <<'END';
	char *command = "hello";
END

        my $INPUT_NOT_LOOPED = <<'END';
	recipe "build", {
	    desc => "build all files",
	    ingreds => ["a.out"],
	};
	
	recipe "a.out", {
	    #ingreds => ["foo.o", "bar.o"],
	    ingreds => ["hello.o"],
	    method => sub {
	        my ($c) = @_;
	        sys "gcc *.o";
	    }
	};
	
	recipe "*.o", {
	    ingreds => ['$(1).c', '$(1).h'],
	    method => sub {
	        my ($c) = @_;
	        sys "gcc -c $c->{ingred}";
	    }
	};
END

        ### create 'hello.c' and 'hello.h'
        before_all {
            write_file('hello.c', $HELLO_C);
            write_file('hello.h', $HELLO_H);
        };
        after_all {
            unlink glob('hello*');
            unlink 'a.out' if -f 'a.out';
        };

        my $kitchen;
        before {
            $kitchen = _create_kitchen($INPUT_NOT_LOOPED);
        };


        ### create_cooking_tree()  # not looped
        my $root;
        topic "#create_cooking_tree()", sub {

            spec "returns Cooking object", sub {
                #no warnings;
                $root = $kitchen->create_cooking_tree("build");
                #
                OK ($root)->is_a('Kook::Cooking');
                OK ($root->{product}) eq "build";
                OK ($root->{children})->length(1);
                #
                my $cooking = $root->{children}->[0];
                OK ($cooking)->is_a('Kook::Cooking');
                OK ($cooking->{product}) eq "a.out";
                OK ($cooking->{children})->length(1);
                #
                $cooking = $cooking->{children}->[0];
                OK ($cooking)->is_a('Kook::Cooking');
                OK ($cooking->{product}) eq "hello.o";
                OK ($cooking->{children})->length(2);
                #
                my $hello_c = $cooking->{children}->[0];
                OK ($hello_c)->is_a('Kook::Material');
                OK ($hello_c->{product}) eq "hello.c";
                OK ($hello_c->{children})->is_falsy();
                my $hello_h = $cooking->{children}->[1];
                OK ($hello_h)->is_a('Kook::Material');
                OK ($hello_h->{product}) eq "hello.h";
                OK ($hello_h->{children})->is_falsy();
            };

        };

        ### check_cooking_tree()
        topic "#check_cooking_tree()", sub {

            spec "reports no errors when no loop found", sub {
                ### check_cooking_tree()      # not looped
                eval {
                    $kitchen->check_cooking_tree($root);
                };
                OK ($@) eq "";
            };

        };

        ### start_cooking()
        topic "#start_cooking()", sub {

            ## ------------------- 1st
            spec "generates product files on 1st time", sub {
                pre_cond ('hello.o')->not_exist();
                pre_cond ('a.out')  ->not_exist();
                my $output = capture {
                    $kitchen->start_cooking("build");
                };
                OK ("hello.o")->file_exists();
                OK ("a.out")->file_exists();
                #
                my $expected = <<'END';
### *** hello.o (recipe=*.o)
$ gcc -c hello.c
### ** a.out (recipe=a.out)
$ gcc *.o
### * build (recipe=build)
END
                ;
                OK ($output) eq $expected;
            };

            ## ------------------- 2nd (sleep 1 sec)
            spec "skips recipe invocation after 1 second", sub {
                sleep 1;
                my $ts_hello_o = mtime("hello.o");
                my $ts_a_out   = mtime("a.out");
                my $output = capture {
                    $kitchen->start_cooking("build");
                };
                OK (mtime("hello.o")) == $ts_hello_o;
                OK (mtime("a.out")) == $ts_a_out;
                my $expected = <<'END';
### * build (recipe=build)
END
                ;
                OK ($output) eq $expected;
            };

            ## ------------------- 3rd (touch hello.h)
            spec "invokes recipes (but skipped) after ingredients are touched", sub {
                my $now = time();
                utime $now, $now, "hello.h";
                my $ts_hello_o = mtime("hello.o");
                my $ts_a_out   = mtime("a.out");
                my $output = capture {
                    $kitchen->start_cooking("build");
                };
                OK (mtime("hello.o")) > $ts_hello_o;
                OK (mtime("a.out")) > $ts_a_out;
                #
                my $expected = <<'END';
### *** hello.o (recipe=*.o)
$ gcc -c hello.c
### ** a.out recipe=a.out
$ touch a.out   # skipped
### * build (recipe=build)
END
                ;
                OK ($output) eq $expected;
            };

            ## ------------------- 4th (edit hello.h)
            spec "invokes recipes (and not skip) when content of ingredients are changed", sub {
                sleep 1;
                my $ts_hello_o = mtime("hello.o");
                my $ts_a_out   = mtime("a.out");
                write_file("hello.h", "char *command = \"HELLO\";\n");
                my $output = capture {
                    $kitchen->start_cooking("build");
                };
                OK (mtime("hello.o")) > $ts_hello_o;
                OK (mtime("a.out")) > $ts_a_out;
                #
                my $expected = <<'END';
### *** hello.o (recipe=*.o)
$ gcc -c hello.c
### ** a.out (recipe=a.out)
$ gcc *.o
### * build (recipe=build)
END
                ;
                OK ($output) eq $expected;
            };

        };

    };


    ###
    ### Kook::Kitchen  # DAG, not looped
    ###
    case_when "recipe tree is DAG", sub {

        my $HELLO_H_TXT = <<'END';
	/*extern char *command;*/
	#define COMMAND "hello"
	void print_args(int argc, char *argv[]);
END
        ;
        my $HELLO1_C = <<'END';
	#include "hello.h"
	/*char *command = "hello";*/
	int main(int argc, char *argv[]) {
	    print_args(argc, argv);
	    return 0;
	}
END
        ;
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
        ;
        before_all {
            write_file("hello.h.txt", $HELLO_H_TXT);
            write_file("hello1.c", $HELLO1_C);
            write_file("hello2.c", $HELLO2_C);
        };
        after_all {
            unlink glob('hello*');
        };


        ### Kookbook.pl
        my $_input = <<'END';
	recipe "build", {
	    desc => "build all files",
	    ingreds => ["hello"],
	};

	recipe "hello", {
	    #ingreds => ["foo.o", "bar.o"],
	    ingreds => ["hello1.o", "hello2.o"],
	    kind => "file",
	    method => sub {
	        my ($c) = @_;
	        my $s = join " ", @{$c->{ingreds}};
	        sys "gcc -o $c->{product} $s";
	    }
	};

	recipe "*.o", {
	    ingreds => ['$(1).c', 'hello.h'],
	    method => sub {
	        my ($c) = @_;
	        sys "gcc -c $c->{ingred}";
	    }
	};

	recipe "hello.h", {
	    ingreds => ["hello.h.txt"],
	    method => sub {
	        my ($c) = @_;
	        sys "cp $c->{ingred} $c->{product}";
	    }
	};
END
        my $kitchen;
        before {
            $kitchen = _create_kitchen($_input);
        };

        ### create_cooking_tree()  # DAG
        my $root;
        topic "#create_cooking_tree()", sub {

            spec "returns Cooking object", sub {
                $root = $kitchen->create_cooking_tree("hello");
                #
                OK ($root)->is_a('Kook::Cooking');
                OK ($root->{product}) eq "hello";
                OK ($root->{children})->length(2);
                #
                my $hello1_o = $root->{children}->[0];
                OK ($hello1_o->{product}) eq "hello1.o";
                OK ($hello1_o->{ingreds})->equals(["hello1.c", "hello.h"]);
                OK ($hello1_o->{recipe}->{product}) eq "*.o";
                OK ($hello1_o->{children})->length(2);
                #
                my $hello2_o = $root->{children}->[1];
                OK ($hello2_o->{product}) eq "hello2.o";
                OK ($hello2_o->{ingreds})->equals(["hello2.c", "hello.h"]);
                OK ($hello2_o->{recipe}->{product}) eq "*.o";
                OK ($hello2_o->{children})->length(2);
                #
                my $hello1_c = $hello1_o->{children}->[0];
                OK ($hello1_c->{product}) eq "hello1.c";
                my $hello1_h = $hello1_o->{children}->[1];
                OK ($hello1_h->{product}) eq "hello.h";
                #
                my $hello2_c = $hello2_o->{children}->[0];
                OK ($hello2_c->{product}) eq "hello2.c";
                my $hello2_h = $hello2_o->{children}->[1];
                OK ($hello2_h->{product}) eq "hello.h";
                #
                OK ($hello1_h) == $hello2_h;   # DAG
                OK ($hello1_h->{children}->[0]->{product}) eq "hello.h.txt";
                OK ($hello2_h->{children}->[0]->{product}) eq "hello.h.txt";
            };

        };

        ### check_cooking_tree()      # DAG
        topic "#check_cooking_tree()", sub {

            spec "reports no errors", sub {
                eval {
                    $kitchen->check_cooking_tree($root);
                };
                OK ($@) eq "";
            };

        };

        ### start_cooking()   # DAG
        topic "#start_cooking()", sub {

            ## ------------------- 1st
            spec "generates product files on 1st time", sub {
                pre_cond ("hello")->not_exist();
                pre_cond ("hello1.o")->not_exist();
                pre_cond ("hello2.o")->not_exist();
                pre_cond ("hello.h")->not_exist();
                my $output = capture {
                    $kitchen->start_cooking("hello");
                };
                OK ("hello")->file_exists();
                OK ("hello1.o")->file_exists();
                OK ("hello2.o")->file_exists();
                OK ("hello.h")->file_exists();
                #
                my $expected = <<'END'
### *** hello.h (recipe=hello.h)
$ cp hello.h.txt hello.h
### ** hello1.o (recipe=*.o)
$ gcc -c hello1.c
### ** hello2.o (recipe=*.o)
$ gcc -c hello2.c
### * hello (recipe=hello)
$ gcc -o hello hello1.o hello2.o
END
                ;
                OK ($output) eq $expected;
            };

            ## ------------------- 2nd (sleep 1 sec, all recipes should be skipped)
            spec "skips all recipes after 1 second slept", sub {
                sleep 1;
                my $ts_hello    = mtime("hello");
                my $ts_hello1_o = mtime("hello1.o");
                my $ts_hello2_o = mtime("hello2.o");
                my $ts_hello_h  = mtime("hello.h");
                my $output = capture {
                    $kitchen->start_cooking("hello");
                };
                OK (mtime("hello"))    == $ts_hello;
                OK (mtime("hello1.o")) == $ts_hello1_o;
                OK (mtime("hello2.o")) == $ts_hello2_o;
                OK (mtime("hello.h"))  == $ts_hello_h;
                #
                my $expected = "";
                OK ($output) eq $expected;
            };

            ## ------------------- 3rd (touch hello.h, hello should be skipped
            spec "skips recipe if intermediate content is not changed", sub {
                #$Kook::Config::DEBUG_LEVEL = 2;
                my $now = time();
                utime $now, $now, "hello.h";
                my $ts_hello    = mtime("hello");
                my $ts_hello1_o = mtime("hello1.o");
                my $ts_hello2_o = mtime("hello2.o");
                my $output = capture {
                    $kitchen->start_cooking("hello");
                };
                OK (mtime("hello.h.txt")) < $now;
                OK (mtime("hello"))    > $ts_hello;
                OK (mtime("hello1.o")) > $ts_hello1_o;
                OK (mtime("hello2.o")) > $ts_hello2_o;
                #
                my $expected = <<'END';
### ** hello1.o (recipe=*.o)
$ gcc -c hello1.c
### ** hello2.o (recipe=*.o)
$ gcc -c hello2.c
### * hello recipe=hello
$ touch hello   # skipped
END
                ;
                OK ($output) eq $expected;
            };

            ## ------------------- 4th (edit hello.h.txt, hello should not be skipped)
            spec "doesn't skip recipes if intermediate content is changed", sub {
                sleep 1;
                my $ts_hello    = mtime("hello");
                my $ts_hello1_o = mtime("hello1.o");
                my $ts_hello2_o = mtime("hello2.o");
                my $s = $HELLO_H_TXT;
                $s =~ s/hello/HELLO/;
                write_file("hello.h.txt", $s);
                my $output = capture {
                    $kitchen->start_cooking("hello");
                };
                OK (mtime("hello"))    > $ts_hello;
                OK (mtime("hello1.o")) > $ts_hello1_o;
                OK (mtime("hello2.o")) > $ts_hello2_o;
                #
                my $expected = <<'END';
### *** hello.h (recipe=hello.h)
$ cp hello.h.txt hello.h
### ** hello1.o (recipe=*.o)
$ gcc -c hello1.c
### ** hello2.o (recipe=*.o)
$ gcc -c hello2.c
### * hello (recipe=hello)
$ gcc -o hello hello1.o hello2.o
END
                OK ($output) eq $expected;
            };

        };

    };


    ###
    ### Kook::Kitchen  # LOOPED
    ###
    case_when "recipe tree has loop", sub {

        my $HELLO_H_TXT = <<'END';
	extern char *command;
END

        my $HELLO_C = <<'END';
	#inclue <stdio.h>
	#include "hello.h"
	int main(int argc, char *argv[]) {
	    printf("command=%s\n", command);
	    return 0;
	}
END

        my $_input = <<'END';
	recipe "build", {
	    desc => "build all files",
	    ingreds => ["hello"],
	};

	recipe "hello", {
	    ingreds => ["hello.o"],
	    kind => "file",
	    method => sub {
	        my ($c) = @_;
	        sys "gcc -o $c->{product} $c->{ingred}";
	    }
	};

	recipe "*.o", {
	    ingreds => ['$(1).c', 'hello.h'],
	    method => sub {
	        my ($c) = @_;
	        sys "gcc -c $c->{ingred}";
	    }
	};

	recipe "*.h", {
	    ingreds => ['$(1).h.txt'],
	    method => sub {
	        my ($c) = @_;
	        sys "cp $c->{ingred} $c->{product}";
	    }
	};

	recipe '*.h.txt', {
	    ingreds => ['$(1).o'],
	    method => sub {
	        my ($c) = @_;
	    }
	};
END

        before_all {
            write_file("hello.h.txt", $HELLO_H_TXT);
            write_file("hello.c",     $HELLO_C);
        };

        my $kitchen;
        before {
            $kitchen = _create_kitchen($_input);
        };

        ### create_cooking_tree()     # LOOPED
        my $root;
        topic "#create_cooking_tree()", sub {

            spec "returns Cooking object", sub {
                $root = $kitchen->create_cooking_tree("build");
                OK ($root)->is_a('Kook::Cooking');
                # TODO
            };

        };

        ### check_cooking_tree()      # LOOPED
        topic "#check_cooking_tree()", sub {

            spec "reports error that recipe tree has loop", sub {
                eval {
                    $kitchen->check_cooking_tree($root);
                };
                my $expected = "build: recipe is looped (hello.o->hello.h->hello.h.txt->hello.o).\n";
                OK ($@) eq $expected;
            };

        };

    };


    ###
    ### Kook::Kitchen  # spices
    ###
    case_when "recipe has spices", sub {

        my $_input = <<'END';
	recipe "test1", {
	    spices => ["-v: verbose", "-f file: file", "-D:", "--name=str: name string"],
	    method => sub {
	        my ($c, $opts, $rest) = @_;
	        #my @arr = map { repr($_).'=>'.repr($opts->{$_}) } sort keys %$opts;
	        #print "opts={", join(", ", @arr), "}\n";
	        my $s = join ", ", map { repr($_).'=>'.repr($opts->{$_}) } sort keys %$opts;
	        print "opts={", $s, "}\n";
	        print "rest=", repr($rest), "\n";
	    }
	};
END
        ;
        my $kitchen;
        before {
            $kitchen = _create_kitchen($_input);
        };
        ##
        topic "#start_cooking()", sub {

            spec "parses command-line options and passes them into method function", sub {
                my $output = capture {
                    $kitchen->start_cooking("test1", "-vDf", "file1.txt", "--name=hoge", "AAA", "BBB");
                };
                my $expected = <<'END';
	### * test1 (recipe=test1)
	opts={"D"=>1, "f"=>"file1.txt", "name"=>"hoge", "v"=>1}
	rest=["AAA","BBB"]
END
                ;
                $expected =~ s/\t//g;
                OK ($output) eq $expected;
            };

        };

    };


};


Oktest::main() if $0 eq __FILE__;
1;
