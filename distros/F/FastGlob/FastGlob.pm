#!/usr/local/bin/perl
package FastGlob;

require 5.005;

=head1 NAME

FastGlob - A faster glob() implementation

=head1 SYNOPSIS

        use FastGlob qw(glob);
        @list = &glob('*.c');

=head1 DESCRIPTION

This module implements globbing in perl, rather than forking a csh.
This is faster than the built-in glob() call, and more robust (on
many platforms, csh chokes on C<echo *> if too many files are in the
directory.)

There are several module-local variables that can be set for 
alternate environments, they are listed below with their (UNIX-ish)
defaults.

        $FastGlob::dirsep = '/';        # directory path separator
        $FastGlob::rootpat = '\A\Z';    # root directory prefix pattern
        $FastGlob::curdir = '.';        # name of current directory in dir
        $FastGlob::parentdir = '..';    # name of parent directory in dir
        $FastGlob::hidedotfiles = 1;    # hide filenames starting with .

So for MS-DOS for example, you could set these to:

        $FastGlob::dirsep = '\\';       # directory path separator
        $FastGlob::rootpat = '[A-Z]:';  # <Drive letter><colon> pattern
        $FastGlob::curdir = '.';        # name of current directory in dir
        $FastGlob::parentdir = '..';    # name of parent directory in dir
        $FastGlob::hidedotfiles = 0;    # hide filenames starting with .

And for MacOS to:

        $FastGlob::dirsep = ':';        # directory path separator
        $FastGlob::rootpat = '\A\Z';    # root directory prefix pattern
        $FastGlob::curdir = '.';        # name of current directory in dir
        $FastGlob::parentdir = '..';    # name of parent directory in dir
        $FastGlob::hidedotfiles = 0;    # hide filenames starting with .

=head1 INSTALLATION

Copy this module to the Perl 5 Library directory.

=head1 COPYRIGHT

Copyright (c) 1997-1999 Marc Mengel. All rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Marc Mengel E<lt>F<mengel@fnal.gov>E<gt>

=head1 REVISIONS

=over 4

=item Brad Appleton E<lt>F<bradapp@enteract.com>E<gt> -- v1.2 Feb 1999

Modified to use qr// (and some other minor speedups) and made callable
as a standalone script

=item Marc Mengel E<lt>F<mengel@fnal.gov>E<gt> -- v1.3 Oct 2000

Bugfixes for 
empty components (e.g. C<foo//bar>), and 
adjacent wildcards (e.g. x?? y** or x?*).

=back

=cut

use Exporter ();
$VERSION = 1.2;
@ISA = qw(Exporter);
@EXPORT = qw(&glob);
@EXPORT_OK = qw(dirsep rootpat curdir parentidr hidedotfiles);

use 5.004;
use strict;                # be good
use vars qw($dirsep $rootpat $curdir $parentdir $hidedotfiles $verbose);

# platform specifics

$dirsep = '/';
$rootpat= '\A\Z';
$curdir = '.';
$parentdir = '..';
$hidedotfiles = 1;
$verbose = 0;

#
# recursively wildcard expand a list of strings
#

sub glob($) {

    my @res; 
    my $part;
    my $found1;
    my $out;
    my $bracepat = qr(\{([^\{\}]*)\});

    # deal with {xxx,yyy,zzz} 
    @res = ();
    $found1 = 1;
    while ($found1) {
	$found1 = 0;
	for (@_) {
	    if ( m{$bracepat} ) {
		foreach $part (split(',',$1)) {
		    $out = $_;
		    $out =~ s/$bracepat/$part/;
		    push(@res, $out);
		}
		$found1 = 1;
	    } else {
		push(@res, $_);
	    }
	}
	@_ = @res;
        @res = ();
    }


    for (@_) {
	# check for and do  tilde expansion
	if ( /^\~([^${dirsep}]*)/ ) {
	    my $usr = $1;
	    my $usrdir = ( ($1 eq "") ? getpwuid($<) : getpwnam($usr) )[7];
	    if ($usrdir ne "" ) {
                s/^\~\Q$usr\E/$usrdir/;
		push(@res, $_);
	    }
	} else {
	    push(@res, $_);
        }
    }
    @_ = @res;
    @res = ();

    for (@_) {
	# if there's no wildcards, just return it
        unless (/(^|[^\\])[*?\[\]{}]/) {
	    push (@res, $_);
	    next;
        }

	# Make the glob into a regexp
	# escape + , and | 
	s/([+.|])/\\$1/go;

	# handle * and ?
	s/(?<!\\)(\*)/.*/go;
	s/(?<!\\)(\?)/./go;

	# deal with dot files
	if ( $hidedotfiles ) {
	    s/(\A|$dirsep)\.\*/$1(?:[^.].*)?/go;
	    s/(\A|$dirsep)\./$1\[\^.\]/go;
	    s/(\A|$dirsep)\[\^([^].]*)\]/$1\[\^\\.$2\]/go;
	}

	# debugging
	print "regexp is $_\n" if ($verbose);

	# now split it into directory components
	my @comps = split($dirsep);

	if ( $comps[0] =~ /($rootpat)/ ) {
	    shift(@comps);
	    push(@res, &recurseglob( "$1$dirsep", "$1$dirsep" , @comps ));
	}
	else {
	    push(@res, &recurseglob( $curdir, '' , @comps ));
	}
    }
    return sort(@res);
}

sub recurseglob($ $ @) {
    my($dir, $dirname, @comps) = @_;
    my(@res) = ();
    my($re, $anymatches, @names);


    if ( @comps == 0 ) {
        # bottom of recursion, just return the path 
        chop($dirname);  # always has gratiutous trailing slash
        @res = ($dirname);
    } elsif ($comps[0] eq '') {
        shift(@comps);
	unshift(@res, &recurseglob( "$dir$dirsep", 
				    "$dirname$dirsep",
				    @comps ));
    } else {
        $re = '\A' . shift(@comps) . '\Z';

        # slurp in the directory
        opendir(HANDLE, $dir);
        @names = readdir(HANDLE);
        closedir(HANDLE);

        # look for matches, and if you find one, glob the rest of the
        # components. We eval the loop so the regexp gets compiled in,
        # making searches on large directories faster.
        $anymatches = 0;
        print "component re is qr($re)\n" if ($verbose);
        my $regex = qr($re);
	foreach (@names) {
	    print "considering |$_|\n" if ($verbose);
	    if ( m{$regex} ) {
		if ( $#comps > -1 ) {
		    unshift(@res, &recurseglob( "$dir$dirsep$_", 
						"$dirname$_$dirsep",
						@comps ));
		} else {
		    unshift(@res, "$dirname$_" );
		}
		$anymatches = 1;
	    }
	}
    }
    return @res;
}

sub globtest(;$) {
        my $fh = shift || \*ARGV;
        my(@t0, @t1, $udiffm, $sdiffm, $udiffg, $sdiffg, @list1, @list2);
        local($,);
        my $res = 1;

        $, = " ";
        while (<$fh>) {
                chomp;
		print "pattern: $_\n";

                @t0 = times();
                @list1 =  &glob($_);
                @t1 = times();
                $udiffm = ($t1[0] + $t1[2]) - ($t0[0] + $t0[2]);
                $sdiffm = ($t1[1] + $t1[3]) - ($t0[1] + $t0[3]);

                @t0 = times();
                @list2 =  glob($_);
                @t1 = times();
                $udiffg = ($t1[0] + $t1[2]) - ($t0[0] + $t0[2]);
                $sdiffg = ($t1[1] + $t1[3]) - ($t0[1] + $t0[3]);

		if ( join(' ',sort(@list1)) ne join(' ',sort(@list2)))  {
		     print "XXX results mismatch:\n";
		     print @list1, "\n";
		     print @list2, "\n";
		     $res = 0; 
		} else {
		     print "results match:\n";
		     print @list1, "\n";
		}
                print "mine: [${udiffm}u\t${sdiffm}s]\n";
                print "glob: [${udiffg}u\t${sdiffg}s]\n";
        }
}

unless (caller) {
    if (globtest()) {
	exit 0;
    } else {
 	exit 1;
    }
}

1;
__END__
