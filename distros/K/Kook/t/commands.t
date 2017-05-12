###
### $Release: 0.0100 $
### $Copyright: copyright(c) 2009-2011 kuwata-lab.com all rights reserved. $
### $License: MIT License $
###

use strict;
use warnings;
no warnings 'void';   # suppress 'Useless use of ... in void context'
use Oktest;
use Oktest::Util qw(capture read_file write_file);

use Data::Dumper;
use File::Path;
use File::Basename;
use Cwd;

use Kook::Commands qw(sys sys_f echo echo_n cp cp_p cp_r cp_pr mkdir mkdir_p rm rm_r rm_f rm_rf rmdir mv store store_p cd edit);
use Kook::Util qw(mtime);


###
### test topic
###
my $T = $ENV{'TEST'};


topic "Kook::Commands", sub {

    my $PWD = Cwd::getcwd();

    my $HELLO_C = <<'END';
/* $COPYRIGHT$ */
#include <stdio.h>
int main(int argc, char *argv[]) {
    int i;
    for (i = 0; i < argc; i++) {
        printf("argv[%d]: %s\n", i, argv[i]);
    }
    return 0;
}
END
    ;

    my $HELLO_H = <<'END';
/* $COPYRIGHT$ */
char *command = "hello";
char *release = "$_RELEASE_$";
END
    ;   #"


    ###
    ### before_all / after_all
    ###
    before_all {
        CORE::mkdir "_sandbox" unless -d "_sandbox";
        chdir "_sandbox"  or die $!;
    };

    after_all {
        chdir $PWD  or die $!;
        rmtree("_sandbox")  or die $!;
    };


    ###
    ### before / after
    ###
    before {
        $@ = undef;
        #
        write_file('hello.c', $HELLO_C);
        write_file('hello.h', $HELLO_H);
        my $t = time() - 99;
        utime $t, $t, 'hello.c';
        utime $t, $t, 'hello.h';
        #
        CORE::mkdir 'hello.d';
        CORE::mkdir 'hello.d/src';
        CORE::mkdir 'hello.d/src/lib';
        CORE::mkdir 'hello.d/src/include';
        CORE::mkdir 'hello.d/tmp';
        write_file('hello.d/src/lib/hello.c', $HELLO_C);
        write_file('hello.d/src/include/hello.h',  $HELLO_H);
        write_file('hello.d/src/include/hello2.h', $HELLO_H);
        utime $t, $t, 'hello.d/src/lib/hello.c';
        utime $t, $t, 'hello.d/src/include/hello.h';
        utime $t, $t, 'hello.d/src/include/hello2.h';
    };

    after {
        $@ = undef;
        #
        for (glob("hello*")) {
            -d $_ ? rmtree $_ : unlink $_;
        }
    };


    ###
    ### sys
    ###
    topic "sys()", sub {

        spec "runs os command", sub {
            pre_cond ('hello2.c')->not_exist();
            my $output = capture {
                sys "cat -n hello.c > hello2.c";
            };
            OK ('hello2.c')->file_exists();
            OK ($output) eq "\$ cat -n hello.c > hello2.c\n";
            #
            open my $FH, '<', 'hello.c'  or die $!;
            my @lines = <$FH>;
            close $FH;
            my $i = 0;
            my $expected = join "", map { sprintf("%6d\t%s", ++$i, $_) } @lines;
            OK (read_file('hello2.c')) eq $expected;
        };

        spec "reports error when os cmmand failed", sub {
            my $output = capture {
                eval { sys "cat -n hello999.c 2>/dev/null"; };
            };
            OK ($output) eq "\$ cat -n hello999.c 2>/dev/null\n";
            OK ($@) eq "*** command failed (status=256).\n";
        };

    };


    ###
    ### sys_f
    ###
    topic "sys_f", sub {

        spec "runs os command", sub {
            pre_cond ('hello2.c')->not_exist();
            my $output = capture {
                sys_f "cat -n hello.c > hello2.c";
            };
            OK ('hello2.c')->file_exists();
            OK ($output) eq "\$ cat -n hello.c > hello2.c\n";
            #
            open my $FH, 'hello.c'  or die $!;
            my @lines = <$FH>;
            close $FH;
            my $i = 0;
            my $expected = join "", map { sprintf("%6d\t%s", ++$i, $_) } @lines;
            OK (read_file('hello2.c')) eq $expected;
        };

        spec "error is not reported even when os cmmand failed", sub {
            my $output = capture {
                eval { sys_f "cat -n hello999.c 2>/dev/null"; };
            };
            OK ($@) eq '';
            OK ($output) eq "\$ cat -n hello999.c 2>/dev/null\n";
        };

    };


    ###
    ### echo, echo_n
    ###
    topic "echo", sub {

        spec "prints arguments.", sub {
            my $output = capture {
                echo("foo", "bar");
            };
            OK ($output) eq "\$ echo foo bar\nfoo bar\n";
        };

        spec "expands filenames when argument contains meta character.", sub {
            my $output = capture {
                echo("hello.d/src/*/hello.?");
            };
            my $expected =
                "\$ echo hello.d/src/*/hello.?\n" .
                "hello.d/src/include/hello.h hello.d/src/lib/hello.c\n".
                "";
            OK ($output) eq $expected;
        };

    };


    topic "echo_n", sub {

        spec "prints arguments but newline.", sub {
            my $output = capture {
                echo_n("foo", "bar");
            };
            OK ($output) eq "\$ echo foo bar\nfoo bar";
        };

        spec "argument contains meta character", sub {
            my $output = capture {
                echo_n("hello.d/src/*/hello.?");
            };
            my $expected =
                "\$ echo hello.d/src/*/hello.?\n" .
                "hello.d/src/include/hello.h hello.d/src/lib/hello.c\n" .
                "";
            chomp $expected;
            OK ($output) eq $expected;
        };

    };


    ###
    ### cp, cp_p
    ###
    my $_test_cp = sub {
        my ($func, $cmd) = @_;
        my $op = $func =~ /_pr?$/ ? '==' : '>';

        spec "copy file to file", sub {
            pre_cond ("hello2.c")->not_exist();
            my $output = capture {
                eval "$func('hello.c', 'hello2.c');";
            };
            OK ("hello2.c")->file_exists();
            OK ($output) eq "\$ $cmd hello.c hello2.c\n";
            OK (read_file("hello2.c")) eq $HELLO_C;
            OK (mtime('hello2.c'))->cmp($op, mtime('hello.c'));
        };

        spec "copy file to dir", sub {
            my $src = "./hello.c";
            my $base = basename($src);
            my $dst = "hello.d/tmp";
            pre_cond ("$dst/$base")->not_exist();
            my $output = capture {
                eval "$func(\$src, \$dst);";
            };
            OK ("$dst/$base")->file_exists();
            #
            OK ($output) eq "\$ $cmd $src $dst\n";
            OK (read_file("$dst/$base")) eq $HELLO_C;
            OK (mtime("$dst/$base"))->cmp($op, mtime($src));
        };

        spec "ERROR when dir to dir", sub {
            my ($src, $dst) = ("hello.d/src", "hello.d/tmp/hoge");
            my $output = capture {
                eval "$func(\$src, \$dst);";
            };
            OK ($@) eq "$func: hello.d/src: cannot copy directory (use 'cp_r' instead).\n";
            OK ($dst)->not_exist();
        };

        spec "ERROR when dir to file", sub {
            my ($src, $dst) = ("hello.d/src", "hello.h");
            pre_cond ($dst)->file_exists();
            my $output = capture {
                eval "$func(\$src, \$dst);";
            };
            OK ($@) eq "$func: hello.d/src: cannot copy directory to file.\n";
        };

        spec "copy files into dir", sub {
            my ($src, $dst) = ("hello.d/src", "hello.d/tmp");
            unlink glob("$dst/*");
            my $output = capture {
                eval "$func('$src/lib/hello.c', '$src/include/hello.h', '$src/include/hello2.h', \$dst);";
            };
            die $@ if $@;
            OK ($output) eq "\$ $cmd $src/lib/hello.c $src/include/hello.h $src/include/hello2.h $dst\n";
            OK ("$dst/hello.c")->file_exists();
            OK ("$dst/hello.h")->file_exists();
            OK ("$dst/hello2.h")->file_exists();
            OK (mtime("$dst/hello.c")) ->cmp($op, mtime("$src/lib/hello.c"));
            OK (mtime("$dst/hello.h")) ->cmp($op, mtime("$src/include/hello.h"));
            OK (mtime("$dst/hello2.h"))->cmp($op, mtime("$src/include/hello2.h"));
        };

        spec "handles metachars", sub {
            my ($src, $dst) = ("hello.d/src", "hello.d/tmp");
            unlink glob("$dst/*");
            my $output = capture {
                eval "$func('$src/lib/*.c', '$src/include/*.h', \$dst)";
            };
            die $@ if $@;
            #
            OK (mtime("$dst/hello.c")) ->cmp($op, mtime("$src/lib/hello.c"));
            OK (mtime("$dst/hello.h")) ->cmp($op, mtime("$src/include/hello.h"));
            OK (mtime("$dst/hello2.h"))->cmp($op, mtime("$src/include/hello2.h"));
        };

    };

    topic "cp", sub {
        $_test_cp->("cp", "cp");
    };

    topic "cp_p", sub {
        $_test_cp->("cp_p", "cp -p");
    };


    ###
    ### cp_r, cp_pr
    ###
    my $_test_cp_r = sub {
        my ($func, $cmd) = @_;
        my $op = $func =~ /_pr?$/ ? '==' : '>';

        spec "copy dir to dir which exists", sub {
            pre_cond ('hello.d/tmp')->dir_exists();
            pre_cond ('hello.d/tmp/src')->not_exist();
            my $output = capture {
                eval "$func('hello.d/src', 'hello.d/tmp');";
            };
            die $@ if $@;
            #
            OK ($output) eq "\$ $cmd hello.d/src hello.d/tmp\n";
            OK ('hello.d/tmp/src')->dir_exists();
            OK ('hello.d/tmp/src/lib')->dir_exists();
            OK ('hello.d/tmp/src/lib/hello.c')->file_exists();
            OK ('hello.d/tmp/src/include')->dir_exists();
            OK ('hello.d/tmp/src/include/hello.h')->file_exists();
            OK ('hello.d/tmp/src/include/hello2.h')->file_exists();
            OK (mtime('hello.d/tmp/src/lib/hello.c'))     ->cmp($op, mtime('hello.d/src/lib/hello.c'));
            OK (mtime('hello.d/tmp/src/include/hello.h')) ->cmp($op, mtime('hello.d/src/include/hello.h'));
            OK (mtime('hello.d/tmp/src/include/hello2.h'))->cmp($op, mtime('hello.d/src/include/hello2.h'));
            rmtree('hello.d/tmp/src');
        };

        spec "copy dir to dir which doesn't exist", sub {
            pre_cond ('hello.d/tmp/src2')->not_exist();
            my $output = capture {
                eval "$func('hello.d/src', 'hello.d/tmp/src2');";
            };
            die $@ if $@;
            #
            OK ($output) eq "\$ $cmd hello.d/src hello.d/tmp/src2\n";
            OK ('hello.d/tmp/src2')->dir_exists();
            OK ('hello.d/tmp/src2/lib')->dir_exists();
            OK ('hello.d/tmp/src2/lib/hello.c')->file_exists();
            OK ('hello.d/tmp/src2/include')->dir_exists();
            OK ('hello.d/tmp/src2/include/hello.h')->file_exists();
            OK ('hello.d/tmp/src2/include/hello2.h')->file_exists();
            OK (mtime('hello.d/tmp/src2/lib/hello.c'))     ->cmp($op, mtime('hello.d/src/lib/hello.c'));
            OK (mtime('hello.d/tmp/src2/include/hello.h')) ->cmp($op, mtime('hello.d/src/include/hello.h'));
            OK (mtime('hello.d/tmp/src2/include/hello2.h'))->cmp($op, mtime('hello.d/src/include/hello2.h'));
            rmtree('hello.d/tmp/src2');
        };

        spec "ERROR when dir to file", sub {
            my ($src, $dst) = ("hello.d/src", "hello.h");
            pre_cond ($dst)->file_exists();
            my $output = capture {
                eval "$func(\$src, \$dst);";
            };
            OK ($@) eq "$func: hello.d/src: cannot copy directory to file.\n";
        };

        spec "files and directories into exisiting dir", sub {
            write_file('hello.d/hello.c', $HELLO_C);
            write_file('hello.d/hello.h', $HELLO_H);
            my $t = time() - 99;
            utime $t, $t, ('hello.d/hello.c', 'hello.d/hello.h');
            #
            pre_cond ('hello.d/tmp/hello.c')->not_exist();
            pre_cond ('hello.d/tmp/hello.h')->not_exist();
            pre_cond ('hello.d/tmp/src')->not_exist();
            my $output = capture {
                eval "$func('hello.d/hello.c', 'hello.d/hello.h', 'hello.d/src', 'hello.d/tmp')";
            };
            die $@ if $@;
            OK ($output) eq "\$ $cmd hello.d/hello.c hello.d/hello.h hello.d/src hello.d/tmp\n";
            #
            OK ('hello.d/tmp/hello.c')->file_exists();
            OK ('hello.d/tmp/hello.h')->file_exists();
            OK ('hello.d/tmp/src')    ->dir_exists();
            OK ('hello.d/tmp/src/lib')->dir_exists();
            OK ('hello.d/tmp/src/lib/hello.c')->file_exists();
            OK ('hello.d/tmp/src/include')    ->dir_exists();
            OK ('hello.d/tmp/src/include/hello.h')->file_exists();
            OK ('hello.d/tmp/src/include/hello2.h')->file_exists();
            OK (mtime('hello.d/tmp/hello.c')) ->cmp($op, mtime('hello.d/hello.c'));
            OK (mtime('hello.d/tmp/hello.h')) ->cmp($op, mtime('hello.d/hello.h'));
            OK (mtime('hello.d/tmp/src/lib/hello.c'))      ->cmp($op, mtime('hello.d/src/lib/hello.c'));
            OK (mtime('hello.d/tmp/src/include/hello.h'))  ->cmp($op, mtime('hello.d/src/include/hello.h'));
            OK (mtime('hello.d/tmp/src/include/hello2.h')) ->cmp($op, mtime('hello.d/src/include/hello2.h'));
            rmtree('hello.d/tmp/src');
            unlink glob('hello.d/tmp/*');
        };

        spec "handles meta-chracters", sub {
            write_file('hello.d/hello.c', $HELLO_C);
            write_file('hello.d/hello.h', $HELLO_H);
            my $t = time() - 99;
            utime $t, $t, ('hello.d/hello.c', 'hello.d/hello.h');
            #
            OK ('hello.d/tmp/hello.c') ->not_exist();
            OK ('hello.d/tmp/hello.h') ->not_exist();
            OK ('hello.d/tmp/src')     ->not_exist();
            my $output = capture {
                eval "$func('hello.d/hello.*', 'hello.d/sr?', 'hello.d/tmp')";
            };
            die $@ if $@;
            OK ($output) eq "\$ $cmd hello.d/hello.* hello.d/sr? hello.d/tmp\n";
            #
            OK ('hello.d/tmp/hello.c')  ->file_exists();
            OK ('hello.d/tmp/hello.h')  ->file_exists();
            OK ('hello.d/tmp/src')      ->dir_exists();
            OK ('hello.d/tmp/src/lib')  ->dir_exists();
            OK ('hello.d/tmp/src/lib/hello.c')      ->file_exists();
            OK ('hello.d/tmp/src/include')          ->dir_exists();
            OK ('hello.d/tmp/src/include/hello.h')  ->file_exists();
            OK ('hello.d/tmp/src/include/hello2.h') ->file_exists();
            OK (mtime('hello.d/tmp/hello.c')) ->cmp($op, mtime('hello.d/hello.c'));
            OK (mtime('hello.d/tmp/hello.h')) ->cmp($op, mtime('hello.d/hello.h'));
            OK (mtime('hello.d/tmp/src/lib/hello.c'))      ->cmp($op, mtime('hello.d/src/lib/hello.c'));
            #OK (mtime('hello.d/tmp/src/include/hello.h'))  ->cmp($op, mtime('hello.d/src/include/hello.h'));
            #OK (mtime('hello.d/tmp/src/include/hello2.h')) ->cmp($op, mtime('hello.d/src/include/hello2.h'));
            rmtree('hello.d/tmp/src');
            unlink glob('hello.d/tmp/*');
        };

        spec "ERROR: files and directories into not-exisiting dir", sub {
            pre_cond ('hello.d/tmp2')->not_exist();
            my $output = capture {
                eval "$func('hello.d/hello.c', 'hello.d/hello.h', 'hello.d/src/lib', 'hello.d/tmp2')";
            };
            OK ($@) eq "$func: hello.d/tmp2: directory not found.\n";
        };

    };

    topic "cp_r", sub {
        $_test_cp_r->("cp_r", "cp -r");
    };

    topic "cp_pr", sub {
        $_test_cp_r->("cp_pr", "cp -pr");
    };


    ###
    ### mkdir, mkdir_p
    ###
    topic "mkdir", sub {

        spec "create directory when unexisted path is specified", sub {
            my ($path1, $path2) = ('hello.d/foo', 'hello.d/bar');
            pre_cond ($path1 && ! -e $path2)->not_exist();
            my $output = capture {
                &mkdir($path1, $path2);
            };
            #
            OK ($output) eq "\$ mkdir $path1 $path2\n";
            OK ($path1)->dir_exists();
            OK ($path2)->dir_exists();
        };

        spec "throws error when existing path is specified", sub {
            my $path = "hello.d/tmp";
            pre_cond ($path)->dir_exists();
            my $output = capture {
                eval { mkdir($path); };
            };
            #
            OK ($output) eq "\$ mkdir $path\n";
            OK ($@) eq "mkdir: $path: already exists.\n";
        };

        spec "throws error when deep path is specified", sub {
            my $path = "hello.d/tmp3/test";
            pre_cond ("hello.d/tmp3")->not_exist();
            my $output = capture {
                eval { mkdir($path); };
            };
            #
            OK ($output) eq "\$ mkdir $path\n";
            OK ($@) eq "mkdir: hello.d/tmp3/test: No such file or directory\n";
        };

    };
    #
    topic "mkdir_p", sub {

        spec "create directory recursively when deep path specified", sub {
            my ($path1, $path2) = ('hello.d/foo/d1', 'hello.d/bar/d2');
            pre_cond ($path1 && ! -e $path2)->not_exist();
            my $output = capture {
                mkdir_p($path1, $path2);
            };
            #
            OK ($output) eq "\$ mkdir -p $path1 $path2\n";
            OK ($path1)->dir_exists();
            OK ($path2)->dir_exists();
        };

        spec "throws error when file name is specified", sub {
            my $path = "hello.d/src/lib/hello.c";
            OK ($path)->file_exists();
            my $output = capture {
                eval { mkdir_p($path); };
            };
            #
            OK ($output) eq "\$ mkdir -p $path\n";
            OK ($@) eq "mkdir_p: $path: already exists.\n";
        };

    };


    ###
    ### rm, rm_f, rm_r, rm_rf
    ###
    topic "rm", sub {

        spec "remove files when filenames are specified", sub {
            my ($path1, $path2) = "hello.d/hello.*", "hello.d/tmp/foo.c";
            write_file("hello.d/hello.c", $HELLO_C);
            write_file("hello.d/hello.h", $HELLO_H);
            write_file("hello.d/tmp/foo.c", $HELLO_C);
            OK ("hello.d/hello.c")  ->file_exists();
            OK ("hello.d/hello.h")  ->file_exists();
            OK ("hello.d/tmp/foo.c")->file_exists();
            #
            my $output = capture {
                rm("hello.d/hello.*", "hello.d/tmp/foo.c");
            };
            die $@ if $@;
            #
            OK ("hello.d/hello.c")  ->not_exist();
            OK ("hello.d/hello.h")  ->not_exist();
            OK ("hello.d/tmp/foo.c")->not_exist();
            OK ($output) eq "\$ rm hello.d/hello.* hello.d/tmp/foo.c\n";
        };

        spec "throws error when directory name is specified", sub {
            my $path = "hello.d/tmp";
            my $output = capture {
                eval { rm($path); };
            };
            #
            OK ($@) eq "rm: $path: can't remove directory (try 'rm_r' instead).\n";
            OK ($output) eq "\$ rm $path\n";
        };

        spec "throws error when unexisting filename specified", sub {
            my $output = capture {
                eval { rm("hello.d/tmp/bar.txt"); };
            };
            #
            OK ($@) eq "rm: hello.d/tmp/bar.txt: not found.\n";
        };

    };
    #
    topic "rm_f", sub {

        spec "no errors even when unexisitng filename specified", sub {
            my $path = "hello.d/tmp/bar.txt";
            OK ($path)->not_exist();
            my $output = capture {
                eval { rm_f($path); };
            };
            die $@ if $@;
            #
            OK ($output) eq "\$ rm -f $path\n";
        };

        spec "throws error when directory name is specified", sub {
            my $path = "hello.d/tmp";
            my $output = capture {
                eval { rm_f($path); };
            };
            #
            OK ($@) eq "rm_f: $path: can't remove directory (try 'rm_r' instead).\n";
            OK ($output) eq "\$ rm -f $path\n";
        };

    };
    #
    topic "rm_r", sub {

        spec "remove directory recursively when directory is specified", sub {
            write_file("hello.d/hello.c", $HELLO_C);
            OK ("hello.d/hello.c") ->file_exists();
            OK ("hello.d/src")     ->dir_exists();
            OK ("hello.d/tmp")     ->dir_exists();
            #
            my $output = capture {
                rm_r("hello.d/*");
            };
            die $@ if $@;
            #
            OK ("hello.d/hello.c") ->not_exist();
            OK ("hello.d/src")     ->not_exist();
            OK ("hello.d/tmp")     ->not_exist();
            OK ($output) eq "\$ rm -r hello.d/*\n";
        };

        spec "throws error when unexisting filename or directory name specified", sub {
            my $path = "hello.d/tmp3";
            my $output = capture {
                eval { rm_r($path); };
            };
            #
            OK ($@) eq "rm_r: $path: not found.\n";
            OK ($output) eq "\$ rm -r $path\n";
        };

    };
    #
    topic "rm_rf", sub {

        spec "no errors even when unexisitng file or directory specified", sub {
            my $path = "hello.d/tmp3";
            pre_cond ($path)->not_exist();
            #
            my $output = capture {
                eval { rm_rf($path); };
            };
            die $@ if $@;
            #
            OK ($output) eq "\$ rm -rf $path\n";
        };

        spec "remove directories when file or directory specified", sub {
            write_file("hello.d/hello.c", $HELLO_C);
            pre_cond ("hello.d/hello.c") ->file_exists();
            pre_cond ("hello.d/src")     ->dir_exists();
            pre_cond ("hello.d/tmp")     ->dir_exists();
            my $path = "hello.d/*";
            #
            my $output = capture {
                eval { rm_rf($path); };
            };
            die $@ if $@;
            #
            pre_cond ("hello.d/hello.c") ->not_exist();
            pre_cond ("hello.d/src")     ->not_exist();
            pre_cond ("hello.d/tmp")     ->not_exist();
            OK ($output) eq "\$ rm -rf $path\n";
        };

    };


    ###
    ### rmdir
    ###
    topic "rmdir", sub {

        spec "removes empty directory", sub {
            my $path = "hello.d/tmp";
            pre_cond ($path)->dir_exists();
            #
            my $output = capture {
                rmdir $path;
            };
            die $@ if $@;
            #
            OK ($output) eq "\$ rmdir $path\n";
            OK ($path)->not_exist();
        };

        spec "throws error when non-existing directory specified", sub {
            my $path = "hello.d/tmp3";
            pre_cond ($path)->not_exist();
            #
            my $output = capture {
                eval { rmdir $path; };
            };
            #
            OK ($output) eq "\$ rmdir $path\n";
            OK ($@) eq "rmdir: $path: not found.\n";
        };

        spec "not-empty directory specified then report error", sub {
            my $path = "hello.d/src";
            pre_cond ($path)->dir_exists();
            #
            my $output = capture {
                eval { rmdir $path; };
            };
            #die $@ if $@;
            #
            OK ($output) eq "\$ rmdir $path\n";
            OK ($@) eq "rmdir: hello.d/src: Directory not empty\n";
            OK ($path)->dir_exists();
        };

    };


    ###
    ### mv
    ###
    topic "mv", sub {

        spec "move file to new", sub {
            my ($path1, $path2) = ("hello.c", "hello.d/tmp/foo.c");
            pre_cond ($path1)->file_exists();
            pre_cond ($path2)->not_exist();
            #
            my $output = capture {
                mv($path1, $path2);
            };
            die $@ if $@;
            #
            OK ($path1)->not_exist();
            OK ($path2)->file_exists();
            OK ($output) eq "\$ mv $path1 $path2\n";
        };

        spec "move dir to new", sub {
            my ($path1, $path2) = ("hello.d/src", "hello.d/src3");
            pre_cond ($path1)->dir_exists();
            pre_cond ($path2)->not_exist();
            #
            my $output = capture {
                mv($path1, $path2);
            };
            die $@ if $@;
            #
            OK ($path1)->not_exist();
            OK ($path2)->dir_exists();
            OK ($output) eq "\$ mv $path1 $path2\n";
        };

        spec "move file to file", sub {
            my ($path1, $path2) = ("hello.c", "hello.h");
            pre_cond ($path1)->file_exists();
            pre_cond ($path2)->file_exists();
            #
            my $output = capture {
                mv($path1, $path2);
            };
            die $@ if $@;
            #
            OK ($path1)->not_exist();
            OK ($path2)->file_exists();
            OK ($output) eq "\$ mv $path1 $path2\n";
        };

        spec "move file to dir", sub {
            my ($path1, $path2) = ("hello.d/src/lib/hello.c", "hello.d/tmp");
            pre_cond ($path1)->file_exists();
            pre_cond ($path2)->dir_exists();
            #
            my $output = capture {
                mv($path1, $path2);
            };
            die $@ if $@;
            #
            OK ($path1)->not_exist();
            OK ("$path2/hello.c")->file_exists();
            OK ($output) eq "\$ mv $path1 $path2\n";
        };

        spec "move dir to dir", sub {
            my ($path1, $path2) = ("hello.d/src", "hello.d/tmp");
            pre_cond ($path1)->dir_exists();
            pre_cond ($path2)->dir_exists();
            #
            my $output = capture {
                mv($path1, $path2);
            };
            die $@ if $@;
            #
            OK ($path1)->not_exist();
            OK ("$path2/src")->dir_exists();
            OK ($output) eq "\$ mv $path1 $path2\n";
        };

        spec "move dir to file then report error", sub {
            my ($path1, $path2) = ("hello.d/src", "hello.c");
            pre_cond ($path1)->dir_exists();
            pre_cond ($path2)->file_exists();
            #
            my $output = capture {
                eval { mv($path1, $path2); };
            };
            #
            OK ($@) eq "mv: $path2: not a directory.\n";
            OK ($output) eq "\$ mv $path1 $path2\n";
        };

        spec "move unexisting file then report error", sub {
            my ($path1, $path2) = ("hello.d/tmp3", "hello.d/tmp");
            OK ($path1)->not_exist();
            #
            my $output = capture {
                eval { mv($path1, $path2); };
            };
            #
            OK ($@) eq "mv: $path1: not found.\n";
            OK ($output) eq "\$ mv $path1 $path2\n";
        };

        #
        spec "move files or directories into a directory", sub {
            my @src = ("hello.{c,h}", "hello.d/src/*");
            my $dst = "hello.d/tmp";
            pre_cond ($dst)->dir_exists();
            pre_cond ("hello.c")->file_exists();
            pre_cond ("hello.h")->file_exists();
            pre_cond ("hello.d/src/lib")->dir_exists();
            pre_cond ("hello.d/src/include")->dir_exists();
            pre_cond ("$dst/hello.c")->not_exist();
            pre_cond ("$dst/hello.h")->not_exist();
            pre_cond ("$dst/lib")->not_exist();
            pre_cond ("$dst/include")->not_exist();
            #
            my $output = capture {
                mv(@src, $dst);
            };
            die $@ if $@;
            #
            OK ($output) eq "\$ mv ".join(' ', @src)." $dst\n";
            OK ("hello.c")->not_exist();
            OK ("hello.h")->not_exist();
            OK ("hello.d/src/lib")    ->not_exist();
            OK ("hello.d/src/include")->not_exist();
            OK ("$dst/hello.c")->file_exists();
            OK ("$dst/hello.h")->file_exists();
            OK ("$dst/lib")    ->dir_exists();
            OK ("$dst/include")->dir_exists();
        };

        spec "move files or directories into non-existing directory then report error", sub {
            my @src = ("hello.{c,h}", "hello.d/src/*", "hello.txt");
            my $dst = "hello.d/tmp";
            pre_cond ("hello.c")->file_exists();
            pre_cond ("hello.h")->file_exists();
            pre_cond ("hello.txt")->not_exist();
            #
            my $output = capture {
                eval { mv(@src, $dst); };
            };
            #
            OK ($@) eq "mv: hello.txt: not found.\n";
            OK ("hello.c")->file_exists();
            OK ("hello.h")->file_exists();
        };

    };


    ###
    ### store, store_p
    ###
    my $_test_store = sub {
        my ($func, $cmd, $op) = @_;

        spec "copy files to dir with keeping file path", sub {
            my $dst = "hello.d/tmp";
            #
            my $output = capture {
                eval "$func('*.{c,h}', 'hello.d/**/*.{c,h}', '$dst')";
            };
            die $@ if $@;
            #
            OK ($output) eq "\$ $cmd *.{c,h} hello.d/**/*.{c,h} $dst\n";
            OK ("hello.c")                          ->file_exists();
            OK ("hello.h")                          ->file_exists();
            OK ("hello.d/src/lib/hello.c")          ->file_exists();
            OK ("hello.d/src/include/hello.h")      ->file_exists();
            OK ("hello.d/src/include/hello2.h")     ->file_exists();
            OK ("$dst/hello.c")                     ->file_exists();
            OK ("$dst/hello.h")                     ->file_exists();
            OK ("$dst/hello.d/src/lib/hello.c")     ->file_exists();
            OK ("$dst/hello.d/src/include/hello.h") ->file_exists();
            OK ("$dst/hello.d/src/include/hello2.h")->file_exists();
            OK (mtime("$dst/hello.c")) ->cmp($op, mtime("hello.c"));
            OK (mtime("$dst/hello.h")) ->cmp($op, mtime("hello.h"));
            OK (mtime("$dst/hello.d/src/lib/hello.c")) ->cmp($op, mtime("hello.d/src/lib/hello.c"));
            OK (mtime("$dst/hello.d/src/include/hello.h")) ->cmp($op, mtime("hello.d/src/include/hello.h"));
            OK (mtime("$dst/hello.d/src/include/hello2.h")) ->cmp($op, mtime("hello.d/src/include/hello2.h"));
        };

        spec "reports error when only an argument specified", sub {
            my $output = capture {
                eval "$func('hello.d/tmp');";
            };
            OK ($@) eq "$func: at least two file or directory names are required.\n";
        };

        spec "reports error when destination directory doesn't exist", sub {
            my $output = capture {
                eval "$func('*.foo', 'foo.d');";
            };
            OK ($@) eq "$func: foo.d: directory not found.\n";
        };

        spec "reports error destination is not a directory", sub {
            my $output = capture {
                eval "$func('*.foo', 'hello.c');";
            };
            OK ($@) eq "$func: hello.c: not a directory.\n";
        };

        spec "reports error when source file doesn't exist", sub {
            my $output = capture {
                eval "$func('hello.c', '*.foo', 'hello.d/tmp');";
            };
            OK ($@) eq "$func: *.foo: not found.\n";
            OK ('hello.d/tmp/hello.c')->not_exist();
        };

    };
    #
    topic "store", sub {
        $_test_store->('store', 'store', '>');
    };
    topic "store_p", sub {
        $_test_store->('store_p', 'store -p', '==');
    };


    ###
    ### cd
    ###
    topic "cd", sub {

        spec "change directory when directory name", sub {
            my $cwd = getcwd();
            #
            my $output = capture {
                cd "hello.d/src/lib";
            };
            die $@ if $@;
            #
            OK ($output) eq "\$ cd hello.d/src/lib\n";
            OK (getcwd()) eq "$cwd/hello.d/src/lib";
            #
            chdir $cwd;
        };

        spec "back to current directory when both dirname and closure are specified", sub {
            my $cwd = getcwd();
            #
            my $output = capture {
                cd "hello.d/src/include", sub { echo "*.h" };
            };
            die $@ if $@;
            #
            my $expected =
                "\$ cd hello.d/src/include\n" .
                "\$ echo *.h\n" .
                "hello.h hello2.h\n" .
                "\$ cd -  # back to $cwd\n" .
                "";
            OK ($output) eq $expected;
            OK (getcwd()) eq $cwd;
        };

        spec "reports error when unexisting directory specified", sub {
            my $cwd = getcwd();
            my $path = "hello.d/tmp3";
            pre_cond ($path)->not_exist();
            #
            my $output = capture {
                eval { cd $path; };
            };
            #
            OK ($@) eq "cd: $path: directory not found.\n";
            OK (getcwd()) eq $cwd;
        };

        spec "reports error when file name specified", sub {
            my $cwd = getcwd();
            my $path = "hello.d/src/lib/hello.c";
            pre_cond ($path)->file_exists();
            #
            my $output = capture {
            eval { cd $path; };
            };
            #
            OK ($@) eq "cd: $path: not a directory.\n";
            OK (getcwd()) eq $cwd;
        };

        spec "reports error when directory name is not specified", sub {
            my $cwd = getcwd();
            #
            my $output = capture {
                eval { cd; };
            };
            #
            OK ($@) eq "cd: directory name required.\n";
            OK (getcwd()) eq $cwd;
        };

    };


    ###
    ### edit
    ###
    topic "edit", sub {

        spec "edit file contents when filenames specified with closure", sub {
            my $output = capture {
                #edit { s/\$COPYRIGHT\$/MIT License/g; $_ } "hello.d/**/*.c", "hello.d/**/*.h";
                edit "hello.d/**/*.c", "hello.d/**/*.h", sub { s/\$COPYRIGHT\$/MIT License/g; $_ };
            };
            die $@ if $@;
            #
            my $expected;
            OK ($output) eq "\$ edit hello.d/**/*.c hello.d/**/*.h\n";
            $expected = $HELLO_C;
            $expected =~ s/\$COPYRIGHT\$/MIT License/g;
            OK ($expected) ne $HELLO_C;
            OK (read_file("hello.d/src/lib/hello.c")) eq $expected;
            $expected = $HELLO_H;
            $expected =~ s/\$COPYRIGHT\$/MIT License/g;
            OK ($expected) ne $HELLO_H;
            OK (read_file("hello.d/src/include/hello.h")) eq $expected;
            OK (read_file("hello.d/src/include/hello2.h")) eq $expected;
        };

        spec "do nothing when directory names are specified", sub {
            my $output = capture {
                #edit { s/\$COPYRIGHT\$/MIT License/g; $_ } "hello.d/src";
                edit "hello.d/src", sub { s/\$COPYRIGHT\$/MIT License/g; $_ };
            };
            die $@ if $@;
            #
            OK ($@) eq '';
        };

        spec "reports error when closure is not specified", sub {
            eval { edit "hello.d/src"; };
            OK ($@) eq "edit(): last argument should be closure.\n";
        };

        spec "reports error when closure returns false value", sub {
            my $expected = "edit(): closure should return non-empty string but %s returned.\n";
            my $output = capture {
                $@ = undef;
                eval { edit "hello.d/**/*", sub { undef }; };
                OK ($@) eq sprintf($expected, 'undef');
                $@ = undef;
                eval { edit "hello.d/**/*", sub { "" }; };
                OK ($@) eq sprintf($expected, 'empty string');
                $@ = undef;
                eval { edit "hello.d/**/*", sub { 0 }; };
                OK ($@) eq sprintf($expected, 'zero');
                $@ = undef;
            };
        };

        spec "reports error when closure returns number", sub {
            my $output = capture {
                my $expected = "edit(): closure should return non-empty string but %s returned.\n";
                eval { edit "hello.d/**/*", sub { 123 }; };
                OK ($@) eq sprintf($expected, 123);
                $@ = undef;
                #eval { edit "hello.d/**/*", sub { 3.14 }; };
                #OK ($@) eq sprintf($expected, 3.14);
                #OK ($@) eq $expected;
                #$@ = undef;
                eval { edit "hello.d/**/*", sub { 0 == 0 }; };
                OK ($@) eq sprintf($expected, 1);
            };
        };

    };


};


Oktest::main() if $0 eq __FILE__;
1;
