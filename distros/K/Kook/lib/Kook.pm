###
### $Release: 0.0100 $
### $Copyright: copyright(c) 2009-2011 kuwata-lab.com all rights reserved. $
### $License: MIT License $
###


package Kook;
use strict;

our $VERSION = '0.0.1';


1;


__END__


=pod

=head1 NAME

Kook - task automation utility like Make, Ant, or Rake

($Release: 0.0100 $)


=head1 SYNOPSIS

Filename: Kookbook.pl

	use strict;
	use warnings;

	## properties
	my $CC = prop('CC', 'gcc');

	## default recipe
	$kook->{default} = 'build';

	## task recipe
	recipe 'build', {
	    ingreds  => ['hello.exe'],
	    desc     => 'build all files',
	    #kind    => 'task',
	};

	## file recipe
	recipe 'hello.exe', {
	    ingreds  => ['hello.o'],
	    desc     => "build 'hello' command",
	    #kind    => 'file',
	    method   => sub {
	        my $c = shift;
	        sys "$CC -o $c->{product} $c->{ingred}";
	    }
	};

	## rule recipe
	recipe '*.o', {
	    ingreds  => ['$(1).c', '$(1).h'],
	    desc     => "build '*.o' from '*.c'",
	    method   => sub {
	        my $c = shift;
	        sys "$CC -c $c->{ingred}";   # or $c->{ingreds}->[0]
	    }
	};

Command-line example:

	bash> kk -l        # or plkook -l
	Properties:
	  CC                   : "gcc"

	Task recipes (default=build):
	  build                : build all files

	File recipes:
	  hello                : build 'hello' command
	  *.o                  : build '*.o' from '*.c'

	(Tips: ingreds=>['$(1).c', if_exists('$(1).h')] is a friend of C programmer.)

	bash> kk build
	### *** hello.o (recipe=*.o)
	$ gcc -c hello.c
	### ** hello (recipe=hello)
	$ gcc -o hello hello.o
	### * build (recipe=build)


=head1 DESCRIPTION

Kook (or plKook) is a task automation utility for Perl, like Make, Ant or Rake.
Unix-like commands (cp, mv, rm, and so on) are also implemented in pure Perl.


=head2 Recipe Definition


	## task recipe
	recipe 'test', {
	    desc      => "do test",
	    method    => sub {
	        sys "prove t";
	    }
	};

	## file recipe
	recipe 'README', {
	    ingreds   => ['lib/Kook.pm'],      # 'ingreds' means 'ingredients'
	    desc      => "create 'README'",
	    kind      => 'file',               # 'file' or 'task' (optional)
	    method    => sub {
	        my ($c) = @_;
	        sys "pod2text $c->{ingred} > $c->{product}";
	    }
	};

	## rule recipe
	recipe '*.o', {
	    ingreds   => ['$(1).c', '$(1).h'], # 'ingreds' means 'ingredients'
	    desc      => "compile *.c and *.h into *.o",
	    method    => sub {
	        my ($c) = @_;
	        sys "gcc -c $c->{ingred}";
	    }
	};


=head2 Spices

In Kook, 'spices' means command-line options for recipes.

	my @versions = ('5.8.9', '5.10.1', '5.12.4');
	recipe 'test', {
	    desc    => "do test",
	    spices  => ["-a: do test with Perl ".join(", ", @versions)],
	    method  => sub {
	        my ($c, $opts) = @_;
	        if ($opts->{'a'}) {
	            for (@versions) {
	                print "##### Perl $_\n";
	                sys "/usr/local/perl/$_/bin/prove t";
	            }
	        } else {
	            sys 'prove t';
	        }
	    }
	};

Command-line example:

	bash> kk test -a       # or plkook test -a


=head2 Commands

=over 1

=item sys, sys_f

Invokes OS command.
sys_f returns without error even when OS command is failed.

	sys 'prove t';
	sys_f 'prove t';    # ignore status of 'prove' command

=item cp, cp_p, cp_r, cp_pr

Same as cp, cp -p, cp -r, cp -pr commands respectively.

	cp_pr $file1, $file2;
	cp_pr @files, $dir;
	cp_pr '*.jpg', '*.png', $dir;

=item store

Similar to cp command, but keeps file path.

	store 'lib/**/*', 't/**/*', 'dist/hello-1.0.0';

=item mv

Same as mv command in Unix.

	mv 'A.html', 'B/C.html';
	mv '*.jpg', '*.png', $dir;

=item mkdir, mkdir_p

Same as mkdir and mkdir -p commands respectively.

	mkdir_p 'dist/Hello-1.0.0/lib';

=item rm, rm_r, rm_f, rm_rf

Same as rm, rm -r, rm -f, and rm -rf commands respectively.

	rm_rf '**/*.o', '**/*.a';

=item rmdir

Same as rmdir command on Unix.

	rmdir 'emptydir';

=item cd

Change directory. If closure specified as 2nd argument, back to
current directory after calling it.

	cd 'dist/hello-1.0.0', sub {
	    sys 'find . -type f > MANIFEST';
	};

=item echo

Echo arguments and prints "\n";

	echo 'SOS';

=item edit

Edit files.

	my $version = '1.0.0';
	edit 'dist/hello-1.0.0/**/*', sub {
	    s/\$VERSION\$/$version/ge;
	    $_;
	};

=back


=head1 TODO


=over 1

=item *

[_] User's Guide

=item *

[_] Category

=item *

[_] Import Books

=item *

[_] Meta Programming

=item *

[_] Paralellize

=item *

[_] Concatenation

=back


=head1 AUTHOR

makoto kuwata E<lt>kwa@kuwata-lab.comE<gt>


=head1 LICENSE

MIT License


=cut
