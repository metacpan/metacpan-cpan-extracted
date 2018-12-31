package Devel::TraceUse;
$Devel::TraceUse::VERSION = '2.096';
# detect being loaded via -d:TraceUse and disable the debugger features we
# don't need. better names for evals (0x100) and anon subs (0x200).
BEGIN {
    if (!defined &DB::DB && $^P & 0x02) {
        $^P = 0x100 | 0x200;
    }
}

BEGIN {
    unshift @INC, \&trace_use;
    *CORE::GLOBAL::require = sub {
        my ($arg) = @_;

        # ensure our hook remains first in @INC
        @INC = ( \&trace_use, grep "$_" ne \&trace_use . '', @INC )
          if $INC[0] ne \&trace_use;

        # let require do the heavy lifting
        CORE::require($arg);
    };
}

# initialize the tree of require calls
my $root = (caller)[1];

# keys in %TRACE:
# - ranked:    modules load attemps in chronological order
# - loaded_by: track "filename"s loaded by "filepath" (value from %INC)
# - used:      track loaded modules by "filename" (parameter to require)
# - loader:    track potential proxy modules
#
# %TRACE is built incrementally by trace_use, and augmented by post_process
my %TRACE;

my %reported;    # track reported "filename"
my $rank  = 0;   # record the loading order of modules
my $quiet = 1;   # no output until decided otherwise
my $output_fh;   # optional write filehandle where results will be output

# Hide core modules (for the specified version)?
my $hide_core = 0;

sub import {
    my $class = shift;

    # ensure "use Devel::TraceUse ();" will produce no output
    $quiet = 0;

    # process options
    for(@_) {
        if(/^hidecore(?::(.*))?/) {
            $hide_core = numify( $1 ? $1 : $] );
        } elsif (/^output:(.*)$/) {
            open $output_fh, '>', $1 or die "can't open $1: $!";
        } else {
            die "Unknown argument to $class: $_\n";
        }
    }
}

my @caller_info = qw( package filepath line );

### %TRACE CONSTRUCTION

# Keys used in the data structure:
# - filename: parameter passed to use/require
# - module:   module, computed from filename
# - rank:     rank of loading
# - eval:     was this use/require done in an eval?
# - loaded:   list of files loaded from this one
# - filepath: file that was actually loaded from disk (obtained from %INC)
# - caller:   information on the caller (same keys + everything from caller())

sub trace_use
{
    my ( $code, $filename ) = @_;

    # $filename may be an actual filename, e.g. with do()
    # try to compute a module name from it
    my $module = $filename;
    $module =~ s{/}{::}g
        if $module =~ s/\.pm$//;

    # chronological list of modules we tried to load
    push @{ $TRACE{ranked} }, my $info = {
        filename => $filename,
        module   => $module,
        rank     => ++$rank,
        eval     => '',
    };

    # info about the loading module
    # (our require override adds one frame)
    my $caller = $info->{caller} = {};
    @{$caller}{@caller_info} = caller(1);

    # try to compute a "filename" (as received by require)
    $caller->{filename} = $caller->{filepath};

    # some values seen in the wild:
    # - "(eval $num)[$path:$line]" (debugger)
    # - "$filename (autosplit into $path)" (AutoLoader)
    if ( $caller->{filename} =~ /^(\(eval \d+\))(?:\[(.*):(\d+)\])?$/ ) {
        $info->{eval}       = $1;
        $caller->{filename} = $caller->{filepath} = $2;
        $caller->{line}     = $3;
    }

    # clean up path
    $caller->{filename}
        =~ s!^(?:@{[ join '|', map quotemeta, reverse sort @INC ]})/?!!;

    # try to compute the package associated with the file
    $caller->{filepackage} = $caller->{filename};
    $caller->{filepackage} =~ s/\.(pm|al)\s.*$/.$1/;
    $caller->{filepackage} =~ s{/}{::}g
        if $caller->{filepackage} =~ s/\.pm$//;

    # record who tried to load us (and store our index)
    push @{ $TRACE{loaded_by}{ $caller->{filepath} } }, $info->{rank} - 1;

    # record potential proxies
    if ( $caller->{filename} ) {
        my $level = 1;    # our require override adds one frame
        my $subroutine;
        while ( $subroutine = ( caller ++$level )[3] || '' ) {
            last if $subroutine =~ /::/;
        }
        $TRACE{loader}{ join "\0", @{$caller}{qw( filename line )}, $subroutine }++;
    }

    # let Perl ultimately find the required file
    return;
}

# some post-processing that requires the modules to have been actually loaded
sub post_process {

    # process the list of loading attempts in reverse order:
    # if a module shows up more than once, then all occurences
    # are failures to load, except maybe the last one
    for my $module ( reverse @{ $TRACE{ranked} || [] } ) {
        my $filename = $module->{filename};

        # module was successfully loaded
        if ( exists $INC{$filename} ) {
            $TRACE{used}{$filename} ||= $module;
        }
    }

    # map "filename" to "filepath" for everything that was loaded
    while ( my ( $filename, $filepath ) = each %INC ) {
        if ( exists $TRACE{used}{$filename} ) {
            $TRACE{used}{$filename}{loaded} = delete $TRACE{loaded_by}{$filepath} || [];
            $TRACE{used}{$filename}{filepath} = $filepath;
        }
    }

    # extract version
    for my $mod ( @{ $TRACE{ranked} } ) {
        $mod->{version} = ${"$mod->{module}\::VERSION"};
    }
}

### UTILITY FUNCTIONS

# we don't want to use version.pm on old Perls
sub numify {
    my ($version) = @_;
    $version =~ y/_//d;
    my @parts = split /\./, $version;

    # %Module::CoreList::version's keys are x.yyyzzz *numbers*
    return 0+ join '', shift @parts, '.', map sprintf( '%03s', $_ ), @parts;
}

### OUTPUT FORMATTERS

sub show_trace_visitor {
    my ( $mod, $pos, $output_cb, @args ) = @_;

    my $caller = $mod->{caller};
    my $message = sprintf( '%4s.', $mod->{rank} ) . '  ' x $pos;
    $message .= "$mod->{module}";
    $message .= defined $mod->{version} ? " $mod->{version}," : ',';
    $message .= " $caller->{filename}"
        if defined $caller->{filename};
    $message .= " line $caller->{line}"
        if defined $caller->{line};
    $message .= " $mod->{eval}"
        if $mod->{eval};
    $message .= " [$caller->{package}]"
        if $caller->{package} ne $caller->{filepackage};
    $message .= " (FAILED)"
        if !exists $mod->{filepath};

    $output_cb->($message, @args);
}

sub visit_trace
{
    my ( $visitor, $mod, $pos, @args ) = @_;

    my $hide = 0;

    if ( ref $mod ) {
        if($hide_core) {
            $hide = exists $Module::CoreList::version{$hide_core}{$mod->{module}};
        }
        $visitor->( $mod, $pos, @args ) unless $hide;
        $reported{$mod->{filename}}++;
    }
    else {
        $mod = { loaded => delete $TRACE{loaded_by}{$mod} };
    }

    visit_trace( $visitor, $_, $hide ? $pos : $pos + 1, @args )
        for map $TRACE{ranked}[$_], @{ $mod->{loaded} };
}

sub dump_proxies
{
    my $output = shift;

    my @hot_loaders =
      sort { $TRACE{loader}{$b} <=> $TRACE{loader}{$a} }
      grep { $TRACE{loader}{$_} > 1 }
      keys %{ $TRACE{loader} };

    return unless @hot_loaders;

    $output->("Possible proxies:");

    for my $loader (@hot_loaders) {
        my ( $filename, $line, $subroutine ) = split /\0/, $loader;
        $output->(sprintf("%4d %s line %d%s",
                $TRACE{loader}{$loader},
                $filename, $line,
                    (length($subroutine) ? ", sub $subroutine" : '')));
    }
}

sub dump_result
{
    return if $quiet;

    post_process();

    # let people know more accurate information is available
    warn "Use -d:TraceUse for more accurate information.\n" if !$^P;

    # load Module::CoreList if needed
    if ($hide_core) {
        local @INC = grep { $_ ne \&trace_use } @INC;
        local %INC = %INC;    # don't report it loaded
        local *trace_use = sub {};
        require Module::CoreList;
        warn sprintf "Module::CoreList %s doesn't know about Perl %s\n",
            $Module::CoreList::VERSION, $hide_core
            if !exists $Module::CoreList::version{$hide_core};
    }

    my $output = defined $output_fh
           ? sub { print $output_fh "$_[0]\n" }
           : sub { warn "$_[0]\n" };

    # output the diagnostic
    $output->("Modules used from $root:");
    visit_trace( \&show_trace_visitor, $root, 0, $output );

    # anything left?
    if ( %{ $TRACE{loaded_by} } ) {
        visit_trace( \&show_trace_visitor, $_, 0, $output )
          for sort keys %{ $TRACE{loaded_by} };
    }

    # did we miss some modules?
    if (my @missed
        = sort grep { !exists $reported{$_} && $_ ne 'Devel/TraceUse.pm' }
        keys %INC
        )
    {
        $output->("Modules used, but not reported:") if @missed;
        $output->("  $_") for @missed;
    }

    dump_proxies($output);

    close $output_fh if defined $output_fh;
}

### HOOK INSTALLATION

# If perl runs with -c we want to dump
CHECK {
    # "perl -c" ?
    dump_result() if $^C;
}

END { dump_result() }

1;

__END__

=encoding iso-8859-1

=head1 NAME

Devel::TraceUse - show the modules your program loads, recursively

=head1 VERSION

version 2.096

=head1 SYNOPSIS

An apparently simple program may load a lot of modules.  That's useful, but
sometimes you may wonder exactly which part of your program loads which module.

C<Devel::TraceUse> can analyze a program to see which part used which module.
I recommend using it from the command line:

  $ perl -d:TraceUse your_program.pl

This will display a tree of the modules ultimately used to run your program.
(It also runs your program with only a little startup cost all the way through
to the end.)

  Modules used from your_program.pl:
     1.  strict 1.04, your_program.pl line 1 [main]
     2.  warnings 1.06, your_program.pl line 2 [main]
     3.  Getopt::Long 2.37, your_program.pl line 3 [main]
     4.    vars 1.01, Getopt/Long.pm line 37
     5.      warnings::register 1.01, vars.pm line 7
     6.    Exporter 5.62, Getopt/Long.pm line 43
     9.      Exporter::Heavy 5.62, Exporter.pm line 18
     7.    constant 1.13, Getopt/Long.pm line 226
     8.    overload 1.06, Getopt/Long.pm line 1487 [Getopt::Long::CallBack]

The load order is listed on the first column. The version is displayed
after the module name, if available. The calling package is
shown between square brackets if different from the package that can
be inferred from the file name. Extra information is also provided
if the module was loaded from within and C<eval>.

C<Devel::TraceUse> will also report modules that failed to be loaded,
under the modules that tried to load them.

In the very rare case when C<Devel::TraceUse> is not able to attach
a loaded module to the tree, it will be reported at the end.

If a particular line of code is used at least 2 times to load modules,
it is considered as part of a "module loading proxy subroutine", or just "proxy".
C<L<base>::import>, C<L<parent>::import>,
C<L<Module::Runtime>::require_module> are such subroutines, among others.
If proxies are found, the list is reported like this:

     <occurences> <filename> line <line>[, sub <subname>]

Example:

    Possible proxies:
      59 Module/Runtime.pm, line 317, sub require_module
      13 base.pm line 90, sub import
       3 Module/Pluggable/Object.pm line 311, sub _require

Even though using C<-MDevel::TraceUse> is possible, it is preferable to
use C<-d:TraceUse>, as the debugger will provide more accurate information.
You will be reminded in the output.

If you want to know only the modules loaded during the compile phase, use
the standard C<-c> option of perl (see L<perlrun>):

  $ perl -c -d:TraceUse your_program.pl

=head2 Parameters

You can hide the core modules that your program used by providing parameters
at C<use> time:

  $ perl -d:TraceUse[=<option1>:<value1>[,<option2>:<value2>[...]]]

=over 4

=item C<hidecore>

  $ perl -d:TraceUse=hidecore your_program.pl

This will not renumber the modules so the core module's positions will be
visible as gaps in the numbering. In some cases evidence may also be visible of
the core module's usage (e.g. a caller shown as L<base> or L<parent>).

You may also specify the version of Perl for which you want to hide the core
modules (the default is the running version):

  $ perl -d:TraceUse=hidecore:5.8.1 your_program.pl

The version string can be given as I<x.yyy.zzz> (dot-separated) or
I<x.yyyzzz> (decimal). For example, the strings C<5.8.1>, C<5.08.01>,
C<5.008.001> and C<5.008001> will all represent Perl version 5.8.1,
and C<5.5.30>, C<5.005_03> will all represent Perl version 5.005_03.

=item C<output>

  $ perl -d:TraceUse=output:out.txt your_program.pl

This will output the TraceUse result to the given file instead of warn.

Note that TraceUse warnings will still be output as warnings.

The output file is opened at initialization time, so there should be no
surprise in relative path interpretation even if your program changes
the current directory.

=back

=head1 SEE ALSO

There are plenty of modules on CPAN for getting a list of your code's
dependencies. They fall into three general classes:

=over 4

=item 1.

Those that tell you what modules were actually loaded at
run-time, like C<Devel-TraceUse>, through introspection.

This is often done by looking at C<%INC>, but other approaches
include over-riding the C<require> built-in, or adding a coderef
to the head of C<@INC> (see L<perldoc require|http://perldoc.perl.org/functions/require.html>
for more details of that approach).
This may not give you the full list of dependencies,
because different modules may be loaded depended on
the path taken through the code.

=item 2.

Those that parse the code, to determine dependencies.

This may catch some dependencies missed by the previous category,
but in turn may miss modules that are dynamically loaded, or where
the code doesn't match the regexps / parsing techniques used to find
C<use>, C<require> and friends.

=item 3.

Those that look at the declared dependencies in distributions'
metadata files (C<META.yml> and C<META.json>).

=back

=head2 Introspectors

L<App::FatPacker::Trace> and L<Devel::Dependencies>
just gives a flat list of dependencies.
L<Devel::VersionDump> is similar, but also displays the version of each module found.

Instead of listing the names of modules loaded, L<Devel::Loaded> lists
the full paths to the modules. This might help you spot issues caused by
the same module being in multiple directories on your C<@INC> path, I guess.

L<Devel::Modlist> prints a table of the modules used, and the version
of the module installed (I<not> the version that was specified when C<use>ing
the module). It can also map modules to CPAN distributions, and list the
distributions you're dependent on.

L<Devel::TraceDeps> overrides the C<do> and C<require> built-ins,
so it can get finer-grained information about which modules were used
by which module. It generates information about the dependencies,
which you can then process with L<Devel::TraceDeps::Scan>.

L<Devel::TraceLoad> also overrides C<require>, but it doesn't override C<do>,
so it might miss some dependencies in older code.

L<Module::PrintUsed> looks at C<%INC> to identify dependencies, and prints a table
with module name, version, and the local path where it was loaded from.

=head2 Parsers

L<Module::Dependency::Grapher> parses locally installed modules to
determine the full dependency graph, which it can then dump as ASCII or
one of several graph formats.

L<Module::Extract::Use> uses L<PPI> to parse a source file and extract
modules used. It only reports the first level of dependencies.

L<Module::Used> also uses L<PPI> and provides a nice clean API, also only
providing the first level of dependencies.

L<Perl::PrereqScanner> is yet another PPI-based scanner, but is probably the best
of the lot. L<App::PrereqGrapher> uses C<Perl::PrereqScanner> to recursively
identify dependencies, then generate a graph in a number of formats;
the L<prereq-grapher|https://metacpan.org/pod/distribution/App-PrereqGrapher/bin/prereq-grapher>
provides a command-line interface to all of that.

L<Module::ExtractUse> (not to be confused with the previous module!)
uses L<Parse::RecDescent> to parse perl files looking for C<use> and C<require>
statements. It doesn't recurse, so you just get the first level of dependencies.


=head2 Metadata spelunkers

L<CPAN::FindDependencies> fetches C<META.yml> or C<Makefile.PL> files
from L<search.cpan.org|http://search.cpan.org>, so it takes a while to run.

L<Dist::Requires> looks at the tarball for a module (or the extracted directory structure)
and determines the immediate dependencies. It doesn't find the next level of dependencies
and beyond, which L<CPAN::FindDependencies> does.

L<Module::Depends::Tree> uses L<CPANPLUS> to grab tarballs for distributions then
extracts dependency information from metadata files.
It includes a front-end script called C<deptree>.


=head1 AUTHORS

chromatic, C<< <chromatic@wgz.org> >>

Philippe Bruhat, C<< <book@cpan.org> >>

=head2 Contributors

C<hidecore> option contributed by David Leadbeater, C<< <dgl@dgl.cx> >>.

C<output> option contributed by Olivier Mengué (C<< <dolmen@cpan.org> >>).

C<perl -c> support contributed by Olivier Mengué (C<< <dolmen@cpan.org> >>).

Proxy detection owes a lot to Olivier Mengué (C<< <dolmen@cpan.org> >>),
who submitted several patches and discussed the topic with me on IRC.

The thorough L</SEE ALSO> section was written by Neil Bowers (C<< <neilb@cpan.org> >>).

=head1 BUGS

Please report any bugs or feature requests to
C<bug-devel-traceuse at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-TraceUse>.  We can both track it there.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Devel::TraceUse

You can also look for information at:

=over 4

=item * I<Perl Hacks>, hack #74

O'Reilly Media, 2006.

L<http://shop.oreilly.com/product/9780596526740.do>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-TraceUse>

=item * MetaCPAN

L<https://metacpan.org/release/Devel-TraceUse>

=back

=head1 COPYRIGHT

Copyright 2006 chromatic, most rights reserved.

Copyright 2010-2018 Philippe Bruhat (BooK), for the rewrite.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
