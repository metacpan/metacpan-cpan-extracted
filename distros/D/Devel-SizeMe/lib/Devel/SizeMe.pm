package Devel::SizeMe;

# As a handy convenience, make perl -d:SizeMe automatically call heap_size
# in an END block, and also set some $^P flags to get more detail.
my $do_size_at_end; # set true below for "perl -d:SizeMe ..."
BEGIN {
    if ($^P and keys %INC == 1) {
        warn "Note: Devel::SizeMe currently disables perl debugger mode\n";
        # default $^P set by "perl -d" is 0x73f
        $^P = 0x010 # Keep info about source lines on which a sub is defined
            | 0x100 # Provide informative "file" names for evals
            | 0x200 # Provide informative names to anonymous subroutines;
            ;
        $do_size_at_end = 1;

        if (not defined $ENV{SIZEME}) {
            $ENV{SIZEME} = "| sizeme_store.pl --db=sizeme.db";
            warn qq{SIZEME env var not set, defaulting to "$ENV{SIZEME}"\n};
        }
    }
}

use strict;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS $warn $dangle);

require 5.008;
require Exporter;
require Devel::SizeMe::Core;

$VERSION = '0.19';
@ISA = qw(Exporter);

%EXPORT_TAGS = (
    all => [ qw(size total_size perl_size heap_size) ],
);
push @EXPORT_OK, map { @$_ } values %EXPORT_TAGS;

$warn = 1;
$dangle = 0; ## Set true to enable warnings about dangling pointers

END {
    Devel::SizeMe::heap_size() if $do_size_at_end;
}

1;
__END__

=head1 NAME

Devel::SizeMe - Extension for extracting detailed memory usage information

=head1 SYNOPSIS

Manual usage:

  use Devel::SizeMe qw(total_size perl_size);

  my $total_size = total_size( $ref_to_data );

  my $perl_size = perl_size();

Quick automatic usage:

    perl -d:SizeMe ...

=head1 DESCRIPTION

NOTE: This is all rather alpha and anything may change.

The functions traverse memory structures and return the total memory size in
bytes.  See L<Devel::Size> for more information.

If the C<SIZEME> env var is set then the functions also stream out detailed
information about the individual data structures. This data can be written to a
file or piped to a program for further processing.

If SIZEME env var is set to an empty string then all the *_size functions
dump a textual representation of the memory data to stderr.

If SIZEME env var is set to a string that starts with "|" then the
remainder of the string is taken to be a command name and popen() is used to
start the command and the raw memory data is piped to it.
See L<sizeme_store.pl>.

If SIZEME env var is set to anything else it is treated as the name of a
file the raw memory data should be written to.

The sizeme_store.pl script can be used to process the raw memory data.
Typically run via the SIZEME env var. For example:

    export SIZEME='|./sizeme_store.pl --text'
    export SIZEME='|./sizeme_store.pl --dot=sizeme.dot'
    export SIZEME='|./sizeme_store.pl --db=sizeme.db'

The --text output is similar to the textual representation output by the module
when the SIZEME env var is set to an empty string.

The --dot output is suitable for feeding to Graphviz.

The --db output is a SQLite database. (Very subject to change.)

Example usage:

  SIZEME='|sizeme_store.pl --db=sizeme.db' perl -MDevel::SizeMe=:all -e 'total_size(sub { })'

The sizeme_graph.pl script is a Mojolicious::Lite application that serves data to
an interactive treemap visualization of the memory use. It can be run as:

    sizeme_graph.pl daemon

and then open http://127.0.0.1:3000

Please report bugs to:

    http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-SizeMe

=head2 Automatic Mode

If loaded using the perl C<-d> option (i.e., C<perl -d:SizeMe ...>)
and it's the first module loaded then perl memory usage data will be written to
a C<sizeme.db> file in the current directory when the script ends.

=head1 FUNCTIONS

=head2 size

    $size_in_bytes = size( $ref_to_data );

Measures and returns the size of the referenced data, without including any
other data referenced by it.

=head2 total_size

    $size_in_bytes = total_size( $ref_to_data );

Like </size> but does include referenced data.

=head2 perl_size

    $size_in_bytes = perl_size();

Measures and returns the size of the entire perl interpreter. This is similar
to calling C<total_size( \%main:: )> but also includes all the perl internals.

=head2 heap_size

    $size_in_bytes = heap_size();

Measures and returns the size of the entire process heap space, with nodes
within that representing things like free space within malloc (if the malloc
implementation can report that).

The goal here is for the returned 'total heap size' to be taken directly from
the operating system and for a subnode called "unknown" to 'contain' the
difference between everything we can measure and the total heap size reported
by the operating system.

Far from accurate yet.

=head1 GETTING HELP

There's an #sizeme IRC channel on irc.perl.org and the devel-size@googlegroups.com
mailing list (also at https://groups.google.com/d/forum/devel-size)

=head1 CONTRIBUTING

The source code is at https://github.com/timbunce/devel-sizeme

=head1 COPYRIGHT

Copyright (C) 2005 Dan Sugalski,
Copyright (C) 2007-2008 Tels,
Copyright (C) 2008 BrowserUK,
Copyright (C) 2011-2012 Nicholas Clark,
Copyright (C) 2012-2013 Tim Bunce.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl v5.8.8.

=head1 SEE ALSO

L<sizeme_store.pl>, L<sizeme_graph.pl>, perl(1), L<Devel::Size>.

=cut
