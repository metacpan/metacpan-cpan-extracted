package File::Locate;

use 5.00503;
use strict;
use Carp;
use Symbol;

require Exporter;
require DynaLoader;
use AutoLoader;
use vars qw($VERSION @ISA @EXPORT);
@ISA = qw(Exporter DynaLoader);

@EXPORT = qw(locate);

$VERSION = '0.62';

bootstrap File::Locate $VERSION;

use Data::Dumper;

sub locate {
    my $file;

    # eeh...C for loop 
    for (my $i = 1; $i < @_; $i++) {
	if ($_[$i] =~ /^-/) {
	    $i++; next;
	} elsif (ref $_[$i]) {
            next;
        }
	$file = $_[$i];
	last;
    }

    if (not $file) {
	$file = $ENV{ LOCATE_PATH };
	croak "No locate database specified (and none in LOCATE_PATH either)" if not $file;
	push @_, $file;	
    }

    my $fh = gensym;
    open $fh, $file or croak "Could not open database '$file': $!";
    read($fh, my($buf), 7);
    my @buf = unpack "c7", $buf;
    if ($buf eq "\0LOCATE") {
	return _locate(@_);
    } elsif ($buf[0] == ord('0') || $buf[0] == ord('1') and $buf[1] == 0) {
	return _slocate(@_);
    } else {
	croak "$file: This is neither a locate- nor slocate-database";
    }
}
	
1;
__END__

=head1 NAME

File::Locate - Search the (s)locate-database from Perl

=head1 SYNOPSIS

    use File::Locate;

    print join "\n", locate "mp3", "/usr/var/locatedb";

    # or only test of something is in the database

    if (locate("mp3", "/usr/var/locatedb")) {
        print "yep...sort of mp3 there";
    }

    # do regex search
    print join "\n", locate "^/usr", -rex => 1, "/usr/var/locatedb";

=head1 ABSTRACT

    Search the (s)locate-database from Perl

=head1 DESCRIPTION

File::Locate provides the C<locate()> function that scans the locate database for a given substring or POSIX regular expression. The module can handle both plain old locate databases as well as the more hip slocate format.

=head1 FUNCTIONS

The module exports exactly one function.

=over 4

=item * locate (I<$pattern>, [ I<$database> ], [ I<-rex => 1> ], [ I<< -rexopt => 'e'|'i'|'ie' >> ], [ I<$coderef> ])

Scans a slocate/locate-db file for a given I<$pattern>. I<$pattern> may contain globbing-characters or it can be a POSIX regular expression if I<-rex> is true. It figures out the type of I<$database> and does the right thing. If I<$database> is neither a locate- nor a slocate-db, it will croak.

C<locate()> can take three additional parameters. A string is taken to be the I<$database> that should be searched:

    print locate "*.mp3", "/usr/var/locatedb";

If no database is given, locate() looks up the value of the LOCATE_PATH environment variable and uses its value as the database. If this string is empty, it gives up.

Passing a code-reference makes locate() call the code for each match it finds in the database. The current match will be in C<$_>:

    locate "*.mp3", sub { print "MP3 found: $_\n" };

This means that no huge return list has to be built and it is therefore more suitable for scans that return a lot of matches.

Eventually, you can specify two options I<-rex> and I<-rexopt>. When I<-rex> is true, the pattern will be treated as a POSIX regular expression. Note that those are B<not> Perl regular expressions but the rather limited regular expressions that you might know from programs such as grep(1) and the lot. Per default, a match is tried case-sensitively.

With I<-rexopt> you have slightly finer control over the regex matching. Setting it to C<i> will make the pattern case-insensitive. Setting it to C<e> allows you to use the Extended regular expressions as defined by POSIX. Those two values can be bundled to C<< -rexopt => 'ie' >> should you so desire.

All arguments except the first (I<$pattern>) can be given in arbitrary order. Therefore, the following lines are all equivalent:

    locate $pat, -rex => 1, "locatedb", sub { print $_ };
    locate $pat, sub { print $_ }, -rex => 1, "locatedb";
    locate $pat, "locatedb", sub { print $_ }, -rex => 1;
    # etc.

In list context it returns all entries found. In scalar context, it returns a true or a false value depending on whether any matching entry has been found. It is a short-cut performance-wise in that it immediately returns after anything has been found.

If I<$coderef> is provided, the function never returns anything regardless of context.

=back

=head2 EXPORT

C<locate()> is exported by default. If you don't want that, then pull in the module like that:

    use File::Locate ();

You have to call the function fully qualified in this case: C<File::Locate::locate()>.

=head1 SEE ALSO

The manpages of your locate(1L)/slocate(1L) program if available.

=head1 AUTHOR

Tassilo von Parseval <tassilo.von.parseval@rwth-aachen.de>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2007 by Tassilo von Parseval

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2, or (at your option) any later version.

=cut
