# -*- perl -*-

use strict;
use Config;
use File::Basename qw(&basename &dirname);
use Cwd;

# This forces PL files to create target in same directory as PL file.
# This is so that make depend always knows where to find PL derivatives.
my $origdir = cwd;
chdir dirname($0);
my $script = basename($0, '.PL');
$script .= '.com' if $^O eq 'VMS';

unlink($script);
open OUT, ">$script" or die "open for writing $script: $!";

print OUT <<"!GROK!THIS!";
$Config{startperl}
    eval 'exec $Config{perlpath} -S \$0 \${1+"\$@"}'
	if \$running_under_some_shell;
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';
#!perl -w

use strict;
use vars qw($VERSION $TEST_MODE);
$VERSION = 0.2;

use Getopt::Long;

use Pod::Find qw(pod_find simplify_name);

my %opt = ( banner => 1 );

# compatibility hack for previous version(s) of pod2html
my %oldopt;

die unless(GetOptions(\%opt, qw(
  banner!
  converter=s
  suffix=s
  filesuffix=s
  dir=s
  libpods=s
  navigation!
  localtoc!
  toc!
  idx!
  tocname=s
  idxname=s
  toctitle=s
  idxtitle=s
  idxopt=s
  ps!
  psdir=s
  psfont=s
  papersize=s
  inc!
  script!
  stylesheet=s
  warnings!
  verbose!
  help|h
  version|V),
    'flush' => \$oldopt{flush},
    'htmlroot=s' => \$oldopt{htmlroot}, # can be ignored
    'index!' => \$oldopt{'index'},
    'infile=s' => \$oldopt{infile},
    'netscape!' => \$oldopt{netscape}, # ignore
    'outfile=s' => \$oldopt{outfile},
    'podpath=s' => \$oldopt{podpath}, # can be ignored
    'podroot=s' => \$oldopt{podroot},
    'recurse!' => \$oldopt{recurse}, # ignored now
    'title=s' => \$oldopt{title}
));

my %addopts = ();

if($oldopt{infile}) {
  @ARGV = ( $oldopt{infile} );
}

if($oldopt{outfile}) {
  $addopts{-outfile} = $oldopt{outfile};
}

if($oldopt{podroot}) {
  push(@ARGV, $oldopt{podroot});
}

# process libpods
if($opt{libpods}) {
  # replace single : with , (old style)
  $opt{libpods} =~ s/(?<!:):(?!:)/,/g;
}

if(defined $oldopt{'index'}) {
  $opt{localtoc} = $oldopt{'index'};
}

if(defined $oldopt{title}) {
  $addopts{-title} = $oldopt{title};
}

my $converter = $opt{converter} || 'Marek::Pod::HTML';
eval "use $converter qw(pod2html);";
die "Fatal: Cannot load convertor module '$converter':\n$@\n"
    if($@);

if($opt{help}) {
  use Config;
  exec "$Config{scriptdir}/perldoc -F $0";
}
elsif($opt{version}) {
    print "$0 Version $VERSION\n";
}
else {

    my %pods = ();
    my @dirs = ();

    foreach(@ARGV) {
        if(-d) {
            push(@dirs,$_);
        }
        elsif(/[*?]/) {
            foreach (glob($_)) {
                if(-d) {
                    push(@dirs,$_);
                }
                else {
                    my $name = simplify_name($_);
                    $pods{$_} = $name;
                }
            }
        }
        else {
           my $name = simplify_name($_);
           $pods{$_} = $name;
       }
    }
    my %search;

    if(@dirs || $opt{inc} || $opt{script}) {
        warn "+++ Searching for POD documents\n";
        %search = pod_find({
            -inc => $opt{inc},
            -script => $opt{script},
            -verbose => $opt{verbose}
          }, @dirs)
    }

    map { $pods{$_} = $search{$_} } keys %search;

    # run as a filter
    # we have to save it temporarily because we need two passes
    my $tmp;
    unless(%pods) {
        my $self = $0;
        $self =~ s:^.*/::;
        $tmp = "/tmp/$self.$$";
        open(TEMP, ">$tmp") || die "Cannot write temp file: $!\n";
        while(<STDIN>) {
            print TEMP;
        }
        close(TEMP);
        $pods{$tmp} = 'stdin';
        $addopts{-filter} = 1;
        $opt{navigation} = 0 unless defined $opt{navigation};
    }

    warn "+++ Starting conversion\n" if($opt{verbose});

    pod2html( {
        -banner => $opt{banner},
        -converter => $converter,
        -suffix => $opt{suffix},
        -filesuffix => $opt{filesuffix},
        -dir => $opt{dir},
        -libpods => $opt{libpods},
        -navigation => $opt{navigation},
        -localtoc => $opt{localtoc},
        -toc => $opt{toc},
        -idx => $opt{idx},
        -tocname => $opt{tocname},
        -idxname => $opt{idxname},
        -toctitle => $opt{toctitle},
        -idxtitle => $opt{idxtitle},
        -ps => $opt{ps},
        -psdir => $opt{psdir},
        -psfont => $opt{psfont},
        -papersize => $opt{papersize},
        -warnings => $opt{warnings},
        -verbose => $opt{verbose},
        -stylesheet => $opt{stylesheet},
        -idxopt => $opt{idxopt},
        %addopts
    }, { %pods });

    unlink $tmp if($tmp);
}

exit 0 unless($TEST_MODE);
1; # this is for the module test

__END__

=head1 NAME

pod2html - convert Perl POD documentation to HTML

=head1 SYNOPSIS

B<pod2html> S<[ B<-converter> I<module> ]>
S<[ B<-suffix> I<suffix> ]> S<[ B<-filesuffix> I<suffix> ]>
S<[ B<-dir> I<path> ]> S<[ B<-libpods> I<pod1,pod2,...> ]>
S<[ B<->(B<no>)B<localtoc> ]> 
S<[ B<->(B<no>)B<navigation> ]> 
S<[ B<->(B<no>)B<toc> ]> S<[ B<-tocname> I<filename> ]>
S<[ B<-toctitle> I<title> ]>
S<[ B<->(B<no>)B<idx> ]> S<[ B<-idxopt> I<options> ]>
S<[ B<-idxname> I<filename> ]>
S<[ B<-idxtitle> I<title> ]>
S<[ B<->(B<no>)B<ps> ]> 
S<[ B<-psdir> I<path> ]> S<[ B<-psfont> I<font> ]>
S<[ B<-papersize> I<format> ]>
S<[ B<->(B<no>)B<inc> ]> 
S<[ B<->(B<no>)B<script> ]> 
S<[ B<->(B<no>)B<warnings> ]> 
S<[ B<->(B<no>)B<verbose> ]> 
S<[ B<->(B<no>)B<banner> ]> 
S<[ B<-stylesheet> I<link> ]>
S<[ I<dir1> , I<dir2> , ... ]>
S<[ I<pod1> , I<pod2> , ... ]>

=head1 DESCRIPTION

B<mpod2html> converts Perl POD documentation to HTML. This was
originally meant as a replacement for the existing core
C<pod2html>, but has turned out to be a heavy-weight, fancy
HTML converter that needs quite a lot of additional modules.
There are a lot of other Pod to HTML converters out there that
may suit you needs better.

See L<SEE ALSO> below for sources of more details.

An important note: B<mpod2html> will cross-link I<only>
those documents that are processed in one conversion
session. The benefit is that you will get I<only>
working hyperlinks, no "dead ends". The downside is that
you cannot simply convert one additional Pod and everything
will be nicely crosslinked. Future versions of this module
(or a complete rewrite) may support a caching mechanism 
for the hyperlink destination, such that additional Pods
converted to HTML will have working hyperlinks to the
existing, already converted Pods; but updating all
existing HTML files for links to the newly converted Pod
is rather cumbersome.

=head1 OPTIONS

=over 4

=item B<-converter> I<module>

The converter class to use, defaults to C<Marek::Pod::HTML>. This hook allows
for simple customization, see also L<Marek::Pod::HTML/"Customizing">.

=item B<-suffix> I<string>

Use this string for links to other converted Pod documents. The default
is C<.html> and also sets the filename suffix unless B<-filesuffix> has
been specified. The dot must be included!

=item B<-filesuffix> I<string>

Use this string as a suffix for the output HTML files. This does not
change the suffix used in the hyperlinks to different documents. This
feature is meant to be used if some (Makefile based) postprocessing
of the generated files has to be performed, but without having to
adapt the links.

=item B<-dir> I<path>

Write the generated HTML files (can be a directory hierarchy) to this
path. The default is the current working directory.

=item B<-libpods> I<name1,name2,...>

This option activates a highly magical feature: The C<=item> nodes of
the specified Pod documents (given by Pod name, e.g. C<Pod::Parser>)
serve as destinations for highlighted text in all converted Pod
documents. Typical usage: When converting your Perl installation's
documentation, you may want to say

  pod2html -libpods perlfunc,perlvar,perlrun -script -inc

then you will get a hyperlink to L<perlvar|perlvar> in the text
C<IE<lt>$|E<gt>>.

=item B<-localtoc> | B<-nolocaltoc>

This is by default true, so that at the top of the page a local
table of contents with all the C<=head>I<n> lines is generated.

=item B<-navigation> | B<-nonavigation>

When using the default customization, this flag enables or disables
the navigation in the header of each Pod document (next/previous doc,
table of contents, index).

=item B<-toc> | B<-notoc>

If true, a table of contents is built from the processed Pod documents.

=item B<-tocname> I<name>

Use I<name> as the filename of the table of contents. Default is
F<podtoc>. The general file suffix is added to this name.

=item B<-toctitle> I<string>

The string that is used as the heading of the table of contents.
Default is `Table of Contents'.

=item B<-idx> | B<-noidx>

If true, an index is built from all processed Pod documents.

=item B<-idxopt> I<options>

Options for index building. Default is "item,x", which means that
item strings as well as text marked up with C<XE<lt>...E<gt>> 
generate entries in the index.

=item B<-idxname> I<name>

Use I<name> as the filename of the index. Default is
F<podindex>. The general file suffix is added to this name.

=item B<-idxtitle> I<string>

The string that is used as the heading of the table of contents.
Default is `Index'.

=item B<-ps> | B<-nops>

In addition to HTML, generate also Postscript output. The suffix is
F<.ps>. Default is no.

=item B<-psdir>

The root directory where to write Postscript files. Defaults to the
same as B<-dir>.

=item B<-psfont> I<fontname>

Generate Postscript files using the font I<fontname>. Default is
`Helvetica'.

=item B<-papersize> I<size>

Generate Postscript files using the paper size I<size>. Default is
`A4'.

=item B<-inc> | B<-noinc>

In addition to the files specified on the command line, use
L<Pod::Find> to traverse C<@INC> for all Pod documents. For a
decent Perl installation this will collect a I<huge> number
of files.

=item B<-script> | B<-noscript>

Similar to B<-inc>, this looks in the Perl installation
executables directory for scripts containing Pod to be
converted. Using this, you will e.g. catch C<perldoc>.

=item B<-warnings> | B<-nowarnings>

When processing the first pass, print warnings. See L<Pod::Checker>
for more information on warnings. Note: This can produce a lot of
output if the Pod source does not correspond to strict guidelines.

=item B<-verbose> | B<-noverbose>

Print more status information along the conversion process.

=item B<-banner> | B<-nobanner>

Generate a banner at the bottom of all converted files (or not).
Default is true.

=item B<-stylesheet> I<link>

The (optional) link to a style sheet, which is included in the resulting HTML
as

  <LINK TYPE="text/css" REL="stylesheet" HREF=$link>

=back

=head1 ARGUMENTS

=over 4

=item I<none>

If no arguments are specified (and neither B<-inc> nor
B<-script>), then B<mpod2html> acts as a filter, reading
STDIN and writing to STDOUT.

=item I<dir1> , I<dir2> , ...

Directories specified on the command line will be processed
recursively. This means especially that if there is e.g. 
F<Pod/Checker.pm> in the specified directory, it will be
recognized as C<Pod::Checker> (rather than C<Checker>).

=item I<pod1> , I<pod2> , ...

A list of files. Note that if you specify F<Mail/Alias.pm>, then
this is I<not> recognized as C<Mail::Alias>, with the consequence
that links in other documents pointing to C<Mail::Alias> will
not be resolved.

=back

=head1 AUTHOR

Marek Rouchal E<lt>marekr@cpan.orgE<gt>

=head1 SEE ALSO

L<Marek::Pod::HTML>,
L<HTML::Element>, L<Pod::Parser>, L<Pod::Checker>, L<HTML::Entities>

=cut

!NO!SUBS!

close OUT or die "Can't close $script: $!";
chmod 0755, $script or die "Can't reset permissions for $script: $!\n";
exec("$Config{'eunicefix'} $script") if $Config{'eunicefix'} ne ':';
chdir $origdir;
