package Devel::FastProf;

BEGIN {
    $VERSION = '0.08';
}

package DB;

BEGIN { $^P=0x0 }

sub sub;

BEGIN { eval "require Time::HiRes" }

BEGIN {

    require XSLoader;
    XSLoader::load('Devel::FastProf', $Devel::FastProf::VERSION);

    if ($] < 5.008008) {
        local $^W = 0;
        *_DB = \&DB;
        *DB = sub { goto &_DB }
    }

    my %config = qw( filename fastprof.out
		     usecputime 0
		     canfork 0 );

    if (defined $ENV{FASTPROF_CONFIG}) {
	for (split /\s*,\s*/, $ENV{FASTPROF_CONFIG}) {
	    if (/^(.*?)\s*=\s*(.*)$/) {
		$config{$1} = $2;
	    }
	    else {
		$config{$_} = 1;
	    }
	}
    }

    my $fn = $config{filename};
    my $cf = $config{canfork};
    if ($cf) {
	unless ($fn =~ m|^/|) {
	    # Oh, yes!
	    # I know about Cwd, but I don't want
	    # to load external modules here!!!
	    my $pwd = `pwd`;
	    chomp ($pwd);
	    $fn = "$pwd/$fn";
	}
    }

    _init($fn, $config{usecputime}, $cf);

    $^P=0x122
}

END {
    { package main; 1 }
    _finish();
}

1;


__END__

=head1 NAME

Devel::FastProf - "fast" perl per-line profiler

=head1 SYNOPSIS

  $ perl -d:FastProf my_script.pl
  $ fprofpp -t 10

=head1 ABSTRACT

Devel::FastProf tells you how much time has been spent on every line
of your program.

=head1 DESCRIPTION

C<Devel::FastProf> is a perl per-line profiler. What that means is
that it can tell you how much time is spent on every line of a perl
script (the standard L<Devel::DProf> is a per-subroutine profiler).

I have been the maintainer of L<Devel::SmallProf> for some time and
although I found it much more useful that L<Devel::DProf>, it had an
important limitation: it was terribly slow, around 50 times slower
than the profiled script being run out of the profiler.

So, I rewrote it from scratch in C, and the result is
C<Devel::FastProf>, that runs only between 3 and 5 times slower than
under normal execution... well, maybe I should have called it
C<Devel::NotSoSlowProf> ;-)

To use C<Devel::FastProf> with your programs, you have to call perl
with the C<-d> switch (see L<perlrun>) as follows:

  $ perl -d:FastProf my_script.pl

C<Devel::FastProf> will write the profiling information to a file
named C<fastprof.out> under the current directory.

To analyse the information on this file use the post processor script
L<fprofpp> included with this package.

Some options can be passed to C<Devel::FastProf> via the environment
variable C<FASTPROF_CONFIG>:

=over 4

=item filename=otherfn.out

allows to change the name of the output file.

=item usecputime

by default, C<Devel::FastProf> meassures the wall clock time spent on
every line, but if this entry is included it will use the cpu time
(user+system) instead.

=item canfork

this option has to be used if the profiled script forks new processes,
if you forget to do so, a corrupted C<fastprof.out> file could be generated.

Activating this mode causes a big performance penalty because write
operations from all the processes have to be serialized using
locks. That is why it is not active by default.

=back

This is an example of how to set those options:

  $ FASTPROF_CONFIG="usecputime,filename=/tmp/fp.out" \
      perl -d:FastProf myscript.pl


=head1 BUGS

No Windows! No threads!

Only tested on Linux. It is know not to work under Solaris.

The code of subroutines defined inside C<eval "..."> constructions
that do not include any other code will not be available on the
reports. This is caused by a limitation on the perl interpreter.

Option -g is buggy, it only works when all the modules are loaded in
the original process.

Perl 5.8.8 or later is recomended. Older versions have a bug that
cause this profiler to be slower.

If you find any bug, please, send me an e-mail to
L<sfandino@yahoo.com> or report it via the CPAN RT system.

=head1 SEE ALSO

L<fprofpp>, L<perlrun>, L<Devel::SmallProf>, L<Devel::Dprof>,
L<perldebug> and L<perldebguts>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2007 by Salvador FandiE<ntilde>o
E<lt>sfandino@yahoo.comE<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
