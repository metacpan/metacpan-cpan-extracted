package MakeMakerFix;

=head1 NAME

MakeMakerFix - MakeMaker correction for site install with prefix specified

=head1 SYNOPSIS

 in Makefile.PL:

	use strict;

	my $fname = 'Convert.pm';

	use lib "./t"; use MakeMakerFix;
	my ($name, $abstract, $author) = from($fname);

	use ExtUtils::MakeMaker;
	WriteMakefile(
	    'NAME'		=> $name,
	    'VERSION_FROM'	=> $fname,
	    'ABSTRACT'		=> $abstract,
	    'AUTHOR'		=> $author,
	    'PM_PREREQ'		=> { 'File::Stat::Bits' => 0 }
	);

B<or:>

	use strict;
	use lib "./t"; use MakeMakerFix;
	WriteMakefile(	'Convert.pm',
			'PREREQ_PM' => { 'File::Stat::Bits' => 0 },
			'postamle'  => "..."
		     );


 perl Makefile.PL prefix=$HOME

 export PERL5LIB=$HOME/lib/site_perl
 export MANPATH=$HOME/man:$MANPATH


=head1 DESCRIPTION

This module provided as an enhancement and some bug fix to Makefile
generation by Makefile.PL of any other module package.
It should be distributed within any other module package
but itself never will be installed.

The module should be placed under 't' subdirectory in order to prevent
the PAUSE server to index it.

=over 4

=item *

This module overrides MakeMaker's Makefile constants section
if prefix=something given to parameters of Makefile.PL.
In absense of this non-standard parameter MakeMaker's behaviour
does not changed.

B<Don't mix prefix and PREFIX parameters.>

Try to install module in your home directory with
PREFIX=~ LIB=~/lib/site_perl
parameters and you will see, what for this module is needed.


=item *

Additionally, this module allows uninstall target to remove installed files
and after that to remove empty directories.


=item *

Additionally, this module provides function from(FILE), which extracts
perl module's name, abstract, author from module file for using as
ExtUtils::MakeMaker::WriteMakefile NAME, ABSTRACT, AUTHOR parameters.
It is like non-existent NAME_FROM, AUTHOR_FROM.

Note, that ABSTRACT_FROM (ExtUtils::MM_Unix::parse_abstract())
works incorrectly with package names which are contains more then single '::'
(to be precise, with DISTNAMEs which are contains more then single '-').

The perl module must have properly formatted POD's =head1 NAME
and =head1 AUTHOR sections.


=item *

Additionally, this module provides its own function WriteMakefile(FROM_FILE),
which is wrapper around ExtUtils::MakeMaker::WriteMakefile(). It calls later
with parameters extracted from specified module file.


=item *

Additionally, this module excludes itself from default modules list to install
with help of overridable libscan() method.

=back

=cut

require 5.004;
use strict;
use Carp;

BEGIN
{
    use Exporter;
    use vars qw($VERSION @ISA @EXPORT $prefix $lib $archname $postamble);

    $VERSION = do { my @r = (q$Revision: 1.13 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

    @ISA = ('Exporter');

    $prefix    = undef;
    $lib       = undef;
    $archname  = undef;
    $postamble = undef;	# my own WriteMakefile() parameter


    @EXPORT = qw( &from &WriteMakefile );

    foreach (my $i=0; $i < @ARGV; ++$i)
    {
	if ( $ARGV[$i] =~ m{^prefix=.*$} )
	{
	    (undef,$prefix) = split(/=/, splice(@ARGV, $i, 1), 2);
	    $prefix = glob $prefix if $prefix =~ m/^~/;
	    last;
	}
    }

    $lib = '$(PREFIX)/lib/site_perl' if defined $prefix;

    { use Config; $archname = $Config{'archname'} };
}


package MY;

sub constants
{
    my $inherited = shift->SUPER::constants(@_);
    my $myconsts;

    if ( defined $MakeMakerFix::prefix )
    {
	$myconsts = "

# --- MakeMakerFix overrides MakeMaker's constants section:

INSTALLDIRS = site
PREFIX      = $MakeMakerFix::prefix

SITELIBEXP  = $MakeMakerFix::lib
SITEARCHEXP = $MakeMakerFix::lib/$MakeMakerFix::archname
";
	$myconsts .= '
INSTALLSITELIB  = $(SITELIBEXP)
INSTALLSITEARCH = $(SITEARCHEXP)

# fix doc_site_install::
INSTALLARCHLIB  = $(INSTALLSITEARCH)

INSTALLBIN      = $(PREFIX)/bin
INSTALLSCRIPT   = $(PREFIX)/bin
INSTALLSITEBIN  = $(PREFIX)/bin

INSTALLMAN1DIR     = $(PREFIX)/man/man1
INSTALLSITEMAN1DIR = $(INSTALLMAN1DIR)

INSTALLMAN3DIR     = $(PREFIX)/man/man3
INSTALLSITEMAN3DIR = $(INSTALLMAN3DIR)
';
    }

    $inherited . $myconsts;
}


sub dist
{
    my $dist = shift->SUPER::dist(@_);

    return $dist . '

# remove distfiles before creating new one
PREOP=$(RM_F) $(DISTVNAME).tar* $(DISTVNAME).zip $(DISTVNAME).shar

'
}


sub postamble
{
return '

# --- MakeMakerFix forces uninstall target:

UNINSTALL = $(PERL) -MExtUtils::Install -e \'uninstall($$ARGV[0],1,0);\'

# Remove all empty directories.
# Sort so they are removable in bottom-up order.
uninstall_from_sitedirs ::
	find $(INSTALLSITELIB) -type d ! -name . ! -name .. | \
	sort -r | xargs rmdir 2>/dev/null || true

' . $MakeMakerFix::postamble;
}


sub libscan
{
    my $path = shift->SUPER::libscan(@_);

    $path=0 if $path and $path =~ m/MakeMakerFix\.pm$/;

    return $path;
}


package MakeMakerFix;

=head1 FUNCTIONS

=over 4

=item B<($name, $abstract, $author) = from( FILENAME )>

Returns list which contains: package name, abstract, author
extracted from specified file.

=item B<WriteMakefile( FROM_FILENAME [, ATTRIBUTE => VALUE [, ...] ] )>

Call ExtUtils::MakeMaker::WriteMakefile() with parameters extracted
from specified module file.

Rest of optional parameters is parameters for
ExtUtils::MakeMaker::WriteMakefile().

My own parameter 'postamble' may be used to specify string
used in addition to overridable MY::postamble() method.

=back

=cut

sub from
{
    my $filename = shift;
    local *FH;
    open  (FH, $filename) or croak "Could not open '$filename': $!";
    local $/ = undef;
    my $file = <FH>;	# file contents
    close FH;

    my ($name, $abstract);
    {
	$file =~ m/^=head1\s+NAME\s*^(.+)\s+-\s+(.*)$/m;
	$name     = $1;
	$abstract = $2;
    }

    $file =~ m/^=head1\s+AUTHOR(S)?\s*^(.+)$/m;
    my $author   = $2;

    return ($name, $abstract, $author);
}


sub WriteMakefile
{
    my $fname = shift;
    my ($name, $abstract, $author) = from($fname);

    my %args = @_;

    # my postamble attribute
    if ( exists $args{'postamble'} )
    {
	$postamble = $args{'postamble'};
	delete $args{'postamble'};
    }

    if ( exists $args{'clean'} )
    {
	$args{'clean'}->{'FILES'} .= ' README *.tar *.tar.gz';
    }

    # generate README _before_ MakeMaker run:
    system("pod2text $fname >README") == 0
	or die "pod2text $fname >README failed: $?";

    use ExtUtils::MakeMaker;
    ExtUtils::MakeMaker::WriteMakefile(
	'NAME'		=> $name,
	'VERSION_FROM'	=> $fname,
	'ABSTRACT'	=> $abstract,
	'AUTHOR'	=> $author,
	%args
    );
}


=head1 SEE ALSO

L<ExtUtils::MakeMaker>;

L<ExtUtils::MM_Unix>;


=head1 AUTHOR

Dmitry Fedorov <dm.fedorov@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2003 Dmitry Fedorov <dm.fedorov@gmail.com>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License,
or (at your option) any later version.

=head1 DISCLAIMER

The author disclaims any responsibility for any mangling of your system
etc, that this script may cause.

=cut


1;

