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

use Kook::Util qw(read_file write_file ob_start ob_get_clean has_metachar meta2rexp repr flatten first glob2);


###
### before_all, after_all
###


my $INPUT = "foo\nbar\nbaz\n";
my $FILENAME = "_test.tmp";

topic "Kook::Util", sub {


    before_all {
        mkdir "_sandbox" unless -d "_sandbox";
        chdir "_sandbox"  or die $!;
    };

    after_all {
        chdir ".."  or die $!;
        rmtree "_sandbox"  or die $!;
    };


    ###
    ### read_file() and write_file()
    ###
    topic '::write_file()', sub {

        spec "creates new file and write file content", sub {
            pre_cond ($FILENAME)->not_exist();
            write_file($FILENAME, $INPUT);
            at_end { unlink $FILENAME };
            OK ($FILENAME)->file_exists();
            # "file size is same as content length"
            OK (-s $FILENAME) == length($INPUT);
        };

    };

    topic "::read_file()", sub {

        spec "reads file content", sub {
            write_file($FILENAME, $INPUT);
            at_end { unlink $FILENAME };
            OK (read_file($FILENAME)) eq $INPUT;
        };

    };


    ###
    ### ob_start(), ob_get_clean()
    ###
    topic "::ob_get_clean()", sub {

        spec "returns output after ob_start() called", sub {
            ob_start();
            print "YES";
            my $output = ob_get_clean();
            OK ($output) eq "YES";
        };

    };

    topic "::ob_start()", sub {

        spec "can be called more than once", sub {
            ob_start();    # 2nd time
            print "NO";
            my $output = ob_get_clean();
            OK ($output) eq "NO";
        };

    };


    ###
    ### has_metachar()
    ###
    topic "Kook::Util:has_metachar", sub {

        spec "returns true if metachar exists", sub {
            OK (has_metachar("*.html")) == 1;
            OK (has_metachar("index.htm?")) == 1;
            OK (has_metachar("index.{txt,htm}")) == 1;
        };

        spec "returns false if metachar doesn't exist", sub {
            OK (has_metachar("index.html"))         ->is_falsy(); #  == (0==1);
        };

        spec "returns false if metachar is escaped by backslash", sub {
            OK (has_metachar("\\*.html"))           ->is_falsy(); #  == (0==1);
            OK (has_metachar("index.htm\\?"))       ->is_falsy(); #  == (0==1);
            OK (has_metachar("index.\\{txt,html}")) ->is_falsy(); #  == (0==1);
        };

    };


    ###
    ### meta2rexp()
    ###
    topic "::meta2rexp", sub {

        spec "converts metachars into regular expression", sub {
            OK (meta2rexp("*.html")) eq '^(.*?)\.html$';
            OK (meta2rexp("index.htm?")) eq '^index\\.htm(.)$';
            OK (meta2rexp("index.{txt,html,xml}")) eq '^index\\.(txt|html|xml)$';
            OK (meta2rexp("index.{a.b,c-d}")) eq '^index\\.(a\\.b|c\\-d)$';
            OK (meta2rexp("*-???.{txt,html,xml}")) eq '^(.*?)\\-(...)\\.(txt|html|xml)$';
        };

    };


    ###
    ### repr()
    ###
    topic "::repr()", sub {

        spec "returns string which represents data structure", sub {
            OK (repr(["foo\n", 123, undef])) eq '["foo\n",123,undef]';
            my $s = repr({'x'=>10, 'y'=>20});
            OK ($s eq '{"x" => 10,"y" => 20}' || $s eq '{"y" => 20,"x" => 10}') == (1==1);
        };

    };


    ###
    ### flatten()
    ###
    topic "::flatten()", sub {

        spec "expands nested array", sub {
            my $arr = ["foo", ["bar", ["baz"]]];
            my @arr2 = flatten(@$arr);
            OK (\@arr2)->equals(["foo", "bar", "baz"]);
        };

    };


    ###
    ### first()
    ###
    topic "::first()", sub {

        spec "returns the first item which matched to condition.", sub {
            my $item = first { $_ =~ /k/ } "Haruhi", "Mikuru", "Yuki";
            OK ($item) eq "Mikuru";
        };

    };


    ###
    ### glob2()
    ###
    topic "::glob2", sub {

        before_all {
            mkdir "hello.d";
            mkdir "hello.d/src";
            mkdir "hello.d/src/lib";
            mkdir "hello.d/src/include";
            mkdir "hello.d/tmp";
            write_file("hello.c", "---");
            write_file("hello.h", "---");
            write_file("hello.d/src/lib/hello.c", "---");
            write_file("hello.d/src/include/hello.h", "---");
            write_file("hello.d/src/include/hello2.h", "---");
        };

        after_all {
            rmtree("hello.d");
            unlink "hello.c", "hello.h";
        };

        spec "supports '**/' pattern", sub {
            my @expected = qw(hello.d/src/include/hello.h hello.d/src/include/hello2.h);
            my @actual = glob2("hello.d/**/*.h");
            OK (repr(\@actual)) eq repr(\@expected);
        };

        spec "allows to combinate '**/' and '{}'", sub {
            my @expected = qw(hello.c hello.h hello.d/src/include/hello.h hello.d/src/include/hello2.h hello.d/src/lib/hello.c);
            my @actual = glob2("**/*.{c,h}");
            OK (repr(\@actual)) eq repr(\@expected);
        };

        spec "returns empty if not matched", sub {
            my @actual = glob2("**/*.jpg");
            OK (@actual)->is_falsy();
        };

    };


};



###
### Kook::Util::CommandOptionParser
###
topic "Kook::Util::CommandOptionParser", sub {


    ### short opts
    my $short_optdef_strs = [
        "-h: help",
        "-f file: filename",
        "-n N: number",
        "-P[pass]: password",
        "-i[N]: indent",
    ];
    my $short_optdefs_expected = {
        'h' => 1,
        'f' => 'file',
        'n' => 'N',
        'P' => '[pass]',
        'i' => '[N]',
    };
    my $short_helps_expected = [
        ['-h',       'help'],
        ['-f file',  'filename'],
        ['-n N',     'number'],
        ['-P[pass]', 'password'],
        ['-i[N]',    'indent'],
    ];

    ### long opts
    my $long_optdef_strs = [
        "--help: Help",
        "--file=path: Filename",
        "--number=N: Number",
        "--password[=pass]: Password",
        "--indent[=N]: Indent",
    ];
    my $long_optdefs_expected = {
        "help"     => 1,
        "file"     => "path",
        "number"   => "N",
        "password" => "[pass]",
        "indent"   => "[N]",
    };
    my $long_helps_expected = [
        ["--help", "Help"],
        ["--file=path", "Filename"],
        ["--number=N", "Number"],
        ["--password[=pass]", "Password"],
        ["--indent[=N]", "Indent"],
    ];


    topic "->new()", sub {

        ### new()
        #my $parser;
        #my $optdef_strs;
        #$parser = Kook::Util::CommandOptionParser->new();
        #OK (\%{$parser->{optdefs}})->equals([]);
        #OK (\@{$parser->{helps}})->equals([]);

        spec "accepts definition of short options", sub {
            #my ($optdefs, $helps) = $parser->parse_optdefs($short_optdef_strs);
            #OK ($optdefs)->equals($short_optdefs_expected);
            #OK ($helps)  ->equals($short_helps_expected);
            my $parser = Kook::Util::CommandOptionParser->new($short_optdef_strs);
            OK ($parser->{optdefs})->equals($short_optdefs_expected);
            OK ($parser->{helps})  ->equals($short_helps_expected);
        };

        spec "accepts definition of long options", sub {
            #my ($optdefs, $helps) = $parser->parse_optdefs($long_optdef_strs);
            #OK ($optdefs)->equals($long_optdefs_expected);
            #OK ($helps)  ->equals($long_helps_expected);
            my $parser = Kook::Util::CommandOptionParser->new($long_optdef_strs);
            OK ($parser->{optdefs})->equals($long_optdefs_expected);
            OK ($parser->{helps})  ->equals($long_helps_expected);
        };

    };


    topic "#parse()", sub {

        spec "parses short options", sub {
            my $parser = Kook::Util::CommandOptionParser->new($short_optdef_strs);
            my ($opts, $rests) = $parser->parse(["-hffile.txt", "-n", "123", "-Pass", "-i2", "AAA", "BBB"]);
            OK ($opts) ->equals({"h"=>1, "f"=>"file.txt", "n"=>'123', "P"=>"ass", "i"=>'2'});  # or "i"=>2
            OK ($rests)->equals(["AAA", "BBB"]);
            ($opts, $rests) = $parser->parse(["-hP", "-i", "CCC", "DDD"]);
            OK ($opts) ->equals({"h"=>1, "P"=>1, "i"=>1});
            OK ($rests)->equals(["CCC", "DDD"]);
        };

        spec "parses long options", sub {
            my $parser = Kook::Util::CommandOptionParser->new($long_optdef_strs);
            my ($opts, $rests) = $parser->parse(["--help", "--file=foo.txt", "--number=123", "--password=pass", "--indent=2", "AAA", "BBB"]);
            OK ($opts) ->equals({"help"=>1, "file"=>"foo.txt", "number"=>'123', "password"=>"pass", "indent"=>'2'});
            OK ($rests)->equals(["AAA", "BBB"]);
            ($opts, $rests) = $parser->parse(["--password", "--indent", "CCC", "DDD"]);
            OK ($opts) ->equals({"password"=>1, "indent"=>1});
            OK ($rests)->equals(["CCC", "DDD"]);
        };

        spec "stops option parting if '--' exists", sub {
            my $parser = Kook::Util::CommandOptionParser->new($short_optdef_strs);
            my ($opts, $rests) = $parser->parse(["-hf", "file.txt", "--", "-n", "123"]);
            OK ($opts) ->equals({"h"=>1, "f"=>"file.txt"});
            OK ($rests)->equals(["-n", "123"]);
        };

    };


    topic "#help()", sub {

        spec "returns help message", sub {
            my @optdefs = ();
            push @optdefs, @$short_optdef_strs, @$long_optdef_strs;
            my $parser = Kook::Util::CommandOptionParser->new(\@optdefs);
            my $help_expected = <<'END';
  -h                  : help
  -f file             : filename
  -n N                : number
  -P[pass]            : password
  -i[N]               : indent
  --help              : Help
  --file=path         : Filename
  --number=N          : Number
  --password[=pass]   : Password
  --indent[=N]        : Indent
END
            ;
            OK ($parser->help()) eq $help_expected;
        };

    };


    topic "#parse2()", sub {

        spec "accepts any long options as properties", sub {
            my $parser = Kook::Util::CommandOptionParser->new($short_optdef_strs);
            my ($opts, $longopts, $rests) = $parser->parse2(["-hf", "file.txt", "--name=value", "--flag", "-i", "AAA", "BBB"]);
            OK ($opts)    ->equals({"h"=>1, "f"=>"file.txt", "i"=>1});
            OK ($longopts)->equals({"name"=>"value", "flag"=>1});
            OK ($rests)   ->equals(["AAA", "BBB"]);
        };

    };


};


Oktest::main() if $0 eq __FILE__;
1;
