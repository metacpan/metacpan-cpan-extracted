###
### $Release: 0.0100 $
### $Copyright: copyright(c) 2009-2011 kuwata-lab.com all rights reserved. $
### $License: MIT License $
###

use strict;
use warnings;
no warnings 'void';   # suppress 'Useless use of ... in void context'
use Oktest;
use Oktest::Util qw(write_file);
use Data::Dumper;
use File::Path;

use Kook::Cookbook;


my $INPUT = <<'END';
	recipe "ex1", {
	    desc => "example #1",
	    method => sub {
	        my ($c) = @_;
	        print "product=$c->{product}\n";
	    }
	};

	recipe "*.html", {
	    desc => "generate *.html from *.txt",
	    ingreds => ["$(1).txt"],
	    method => sub {
	        my ($c) = @_;
	        print "txt2html $c->{ingred} > $c->{product}";
	    }
	};

	recipe "index.html", ["index.wiki"], {   # short notation
	    desc => "generate index.html",
	    method => sub {
	        my ($c) = @_;
	        print "wiki2html index.wiki > index.html";
	    }
	};
END
$INPUT =~ s/^\t//g;


topic "Kook::Cookbook", sub {

    my $CWD = Cwd::getcwd();

    before_all {
        mkdir "_sandbox" unless -d "_sandbox";
        chdir "_sandbox"  or die $!;
    };

    after_all {
        chdir $CWD  or die $!;
        rmtree "_sandbox"  or die $!;
    };


    topic "->new()", sub {

        my $bookname = '_Kookbook.pl';
        before_all {
            write_file($bookname, $INPUT);
        };
        after_all {
            unlink $bookname;
        };

        my $cookbook;
        before {
            $cookbook = Kook::Cookbook->new($bookname);
        };


        spec "keeps bookname", sub {
            OK ($cookbook->{bookname}) eq $bookname;
        };

        spec "loads specific task recipe", sub {
            ### specific task recipe
            my $recipes = $cookbook->{specific_task_recipes};
            my $len = @$recipes;
            OK ($len) == 1;
            my $recipe1 = $recipes->[0];
            OK ($recipe1->{product}) eq "ex1";
            OK ($recipe1->{kind}) eq "task";
            OK ($recipe1->{desc}) eq "example #1";
            OK ($recipe1->{method})->is_ref('CODE');
        };

        spec "loads generic file recipe", sub {
            ### generic file recipe
            my $recipes = $cookbook->{generic_file_recipes};
            my $len = @$recipes;
            OK ($len) == 1;
            my $recipe2 = $recipes->[0];
            OK ($recipe2->{product}) eq "*.html";
            OK ($recipe2->{kind})    eq "file";
            OK ($recipe2->{desc})    eq "generate *.html from *.txt";
            OK ($recipe2->{ingreds})->equals(["$(1).txt"]);
            OK ($recipe2->{method})->is_ref('CODE');
        };

        spec "load specific file recipe", sub {
            ### specific file recipe
            my $recipes = $cookbook->{specific_file_recipes};
            my $len = @$recipes;
            OK ($len) == 1;
            my $recipe3 = $recipes->[0];
            OK ($recipe3->{product}) eq "index.html";
            OK ($recipe3->{kind})    eq "file";
            OK ($recipe3->{desc})    eq "generate index.html";
            OK ($recipe3->{ingreds})->equals(["index.wiki"]);
            OK ($recipe3->{method})->is_ref('CODE');
        };

    };


    topic "#find_recipe()", sub {

        my $cookbook;
        before {
            $cookbook = Kook::Cookbook->new();
            $cookbook->load($INPUT, 'Kookbook.pl');
        };

        spec "returns specific task recipe if name matched to specific task recipe", sub {
            my $recipe = $cookbook->find_recipe("ex1");
            OK ($recipe)->is_a('Kook::Recipe');
            OK ($recipe->{product}) eq "ex1";
            OK ($recipe->{kind})    eq "task";
        };

        spec "returns generic file recipe if name matched to generic file recipe", sub {
            my $recipe = $cookbook->find_recipe("foo.html");
            OK ($recipe)->is_a('Kook::Recipe');
            OK ($recipe->{product}) eq "*.html";
            OK ($recipe->{kind}) eq "file";
        };

        spec "return specific file recipe if name matched to specific file recipe", sub {
            my $recipe = $cookbook->find_recipe("index.html");
            OK ($recipe)->is_a('Kook::Recipe');
            OK ($recipe->{product}) eq "index.html";
            OK ($recipe->{kind}) eq "file";
        };

    };


};


Oktest::main() if $0 eq __FILE__;
1;
