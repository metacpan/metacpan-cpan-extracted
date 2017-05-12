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
use File::Basename;
use Oktest;
use Oktest::Util qw(write_file);

use Kook::Main;


use IPC::Open3;
use Symbol;

sub _system {
    my ($command) = @_;
    my ($IN, $OUT, $ERR) = (gensym, gensym, gensym);
    open3($IN, $OUT, $ERR, $command);
    my @output = <$OUT>;
    my @error  = <$ERR>;
    close $IN;
    close $OUT;
    close $ERR;
    return join("", @output), join("", @error);
}


my $SCRIPT = <<'END';
	#!/usr/bin/env plkook -X
	
	$kook_desc = 'example of plkook scripting framework feature';
	
	recipe "print", {
	    desc  => "print args",
	    method => sub {
	        my ($c, $opts, $rest) = @_;
	        for (@$rest) {
	            print $_, "\n";
	        }
	    }
	};
	
	recipe "echo", {
	    desc  => "echo arguments",
	    spices => [
	        "-v: version",
	        "-f file: filename",
	        "-D:",
	        "-i[N]: indent",
	        "--keyword=kw1,kw2,...: keyword strings",
	    ],
	    method => sub {
	        my ($c, $opts, $rest) = @_;
	        my @arr = map { repr($_).'=>'.repr($opts->{$_}) } sort keys %$opts;
	        print "opts={", join(', ', @arr), "}\n";
	        print "rest=", repr($rest), "\n";
	    }
	};
END
$SCRIPT =~ s/^\t//mg;



topic "Kook::MainApplication", sub {


    before_all {
        mkdir "_sandbox" unless -d "_sandbox";
        chdir "_sandbox"  or die;
        write_file("peko", $SCRIPT);
        chmod 0755, "peko";
    };

    after_all {
        chdir "..";
        rmtree "_sandbox";
    };


    case_when "'-h' option specified...", sub {

        spec "prints help message", sub {
            my ($output, $errmsg) = _system("./peko -h");
            my $expected = <<'END';
		peko - example of plkook scripting framework feature
		
		sub-commands:
		  print           : print args
		  echo            : echo arguments
		
		(Type 'peko -h subcommand' to show options of sub-commands.)
END
            $expected =~ s/^\t\t//mg;
            OK ($output) eq $expected;
            OK ($errmsg) eq "";
        };

        spec "prints help message of subcommand when subcommand specified", sub {
            my ($output, $errmsg) = _system("./peko -h echo");
            my $expected = <<'END';
		peko echo - echo arguments
		  -v                   : version
		  -f file              : filename
		  -i[N]                : indent
		  --keyword=kw1,kw2,... : keyword strings
END
            $expected =~ s/^\t\t//mg;
            OK ($output) eq $expected;
            OK ($errmsg) eq "";
        };

        spec "reports error when unknown subcommand specified.", sub {
            my ($output, $errmsg) = _system("./peko -h foobar");
            OK ($output) eq "";
            OK ($errmsg) eq "foobar: sub command not found.\n";
        };

    };


    case_when "invoked normaly...", sub {

        spec "invokes sub-command when specified.", sub {
            my ($output, $errmsg) = _system("./peko print AAA BBB");
            OK ($output) eq "AAA\nBBB\n";
        };

        spec "reports error when unknown sub-command specified", sub {
            my ($output, $errmsg) = _system("./peko hoge");
            OK ($output) eq "";
            OK ($errmsg) eq "hoge: sub-command not found.\n";
        };


    };


    case_when "spices are specified...", sub {

        spec "invokes sub-commands with spices when they are specified", sub {
            my ($output, $errmsg) = _system("./peko echo -vDffile.txt -i AAA BBB");
            my $expected = <<'END';
		opts={"D"=>1, "f"=>"file.txt", "i"=>1, "v"=>1}
		rest=["AAA","BBB"]
END
            $expected =~ s/^\t\t//mg;
            OK ($output) eq $expected;
            OK ($errmsg) eq "";
        };


        spec "reports error when invalid spice specified", sub {
            my ($output, $errmsg) = _system("./peko echo -ifoo AAA BBB");
            OK ($output) eq "";
            OK ($errmsg) eq "-ifoo: integer required.\n";
        };

        spec "reports error when required argument is not speicified", sub {
            my ($output, $errmsg) = _system("./peko echo -f");
            OK ($output) eq "";
            OK ($errmsg) eq "-f: file required.\n";
        };

    };


};


Oktest::main() if $0 eq __FILE__;
1;
