=head1 NAME

Mac::Carbon - Access to Mac OS Carbon API

=head1 SYNOPSIS

	use Mac::Carbon;
	use Mac::Carbon qw(:files :morefiles);


=head1 DESCRIPTION

This module provides documentation of the Mac::Carbon modules, and
acts as a frontend to them.

Mac::Carbon is a collection of perl modules for accessing the Carbon API
under Mac OS X.  It is a port of the Toolbox modules written by Matthias
Neeracher for MacPerl.

This module will load in all the Carbon modules, and export all of the
functions, constants, and other variables.  An export tag is set up for
each module, so they may be selected individually.

This module exists primarily because in Mac OS X, all the Carbon
functions are imported into a C program with a single header,
Carbon.h, so Mac OS X users may prefer to load in the entire Carbon
API with a single module.

For detailed information on the Carbon API (highly recommended, as
a familiarity with Carbon is assumed in the POD), see apple.com.

	http://developer.apple.com/techpubs/macosx/Carbon/

The documentation is also located on your system, if you have the Developer
Tools installed, at /Developer/Documentation/Carbon/.

Also of significant use are the related header files on your system.  Use
the `locate` command to find them.  They contain current documentation and
notes for the API.

The modules were written for Mac OS originally, and are in part being
ported to Carbon.  You may also be interested in the original documentation.

	http://developer.apple.com/techpubs/macos8/


=head1 TOOLBOX MAPPINGS

Swiped from Mac/Toolbox.pod in the MacPerl distribution.

The Macintosh Operating System provides a rich API with thousands of I<toolbox>
calls. The MacPerl toolbox modules aim to make as much as possible of this
functionality available to MacPerl programmers. The mapping of the toolbox 
interfaces into MacPerl is intended to be

=over 4

=item 1.

Convenient to use for Perl programmers.

=item 2.

As close as possible to the C interfaces.

=back

This translates into a mapping strategy which is discussed in the following 
sections.


=head2 Function mappings

MacPerl toolbox calls take their input arguments in the same order as the 
corresponding toolbox functions. Output arguments are never passed by reference, 
but returned from the calls. If there are several output arguments, a list is
returned. If an error occurs, the function returns C<undef> or C<()> and the 
error code is available in the C<$^E> variable.

	$port = GetPort();
	SetPort($port);
	$desc = AECreateDesc("TEXT", "Hello, World") or die $^E;


=head2 Data structure mappings

Complex data structures are mapped into blessed references. Data fields are 
available through member functions which return the value of a field if called
without an argument and change the value if called with an argument.

	$rect = Rect->new(10, 20, 110, 220);
	$rect->top;
	$rect->right(250);



=head1 MAC OS X DIFFERENCES

The modules follow the same API under Mac OS X as Mac OS, except that
the non-Carbon API is not supported (for example, C<NewHandle> is
supported, but C<NewHandleSys> is not).  Calling a function not
supported by Carbon will generate an exception.

In each module's documentation, functions that work only under Mac OS
(non-Carbon) are marked with B<Mac OS only.>  Those that work only
under Mac OS X (Carbon) are marked with B<Mac OS X only.>  A complete
list is at the end of this document.

The MacPerl package is automatically bootstrapped in MacPerl; it is
included here, though the app-specific functions (Reply, Quit) are not
supported, and the MacPerl package must be loaded explicitly (e.g.,
C<use MacPerl;>).  Also, Ask/Answer/Pick are provided via AppleScript,
talking to the SystemUIServer process.

The Mac-specific error codes are put in C<$^E> as in MacPerl, but C<$^E>
does not automatically convert the numeric error into a string in string
context.  See brian d foy's L<Mac::Errors> module on the CPAN for this:

	use Mac::Errors '$MacError';
	my $info1 = FSpGetCatInfo($file1) or die $^E + 0;    # error number
	my $info2 = FSpGetCatInfo($file2) or die $MacError;  # error string

L<Mac::Errors> is not included with or required by Mac::Carbon, but it is
highly recommended.

C<$!> is set at the same time C<$^E> is set.  This is different behavior
from MacPerl, but similar to other platforms.  On MacPerl, C<$^E> is
signed, and on Unix it is unsigned, so to get the numeric value from
C<$^E>, just add 0, as above.  Could be worse.

Files are passed back and forth using Unix/POSIX filespecs (if you care
about the gory details, a portion of the GUSI API has been reimplemented
here, and it handles the conversions).  Similarly, times are converted
back and forth from the Mac OS epoch to the Unix epoch.

The support functions are in F<Carbon.h>.  See that file for descriptions
of the issues, including bugs and possibilities for bugs, involved.


=head1 64-BIT PERL

Significant portions of the Carbon API are unavailable to 64-bit programs on Mac
OS X.  Perhaps a subset of the API could be made available to a 64-bit perl
(for more information see Apple's "64-Bit Guide for Carbon Developers"),
and might in the future, but it's simpler at this point to just run perl in
32-bit mode.

There's a few ways to do this.  Most obviously, you could simply build a 32-bit
perl.  I always build my own perl, and I just compile it for 32 bits.

There's also two methods mentioned in L<man perl> under Mac OS X 10.6:
you can set an environment variable, or set a system preference.  For the
environment use:

	VERSIONER_PERL_PREFER_32_BIT=yes

And for the system preference, execute this line in your terminal:
	
	defaults write com.apple.versioner.perl Prefer-32-Bit -bool yes


=head1 INTEL ISSUES

There are very few issues on Intel.  They mostly center around the fact that
a Mac four-char-code is often treated as a string in Perl-space, but in C-space
is an integer.  The conversion process results in various errors.

Four-char-code types include typeType, typeEnumerated, typeProperty,
typeKeyword, and typeApplSignature.

There are a few Don't Do Thats to keep in mind.

=over 4

=item *

Don't change the type of an existing AEDesc; coerce it to a new desc instead,
with AECoerceDesc().  This is generally good advice anyway.

=item *

Don't pass four-char-codes as arguments to AEBuild*; there's no easy way for
the called function to know what type the argument is going to be passed as,
and to fix the data before it is passed.  Four-char-codes can be literals
in AEBuild formats; this is a better method to use, when possible.  For example:

	AEBuild(q{'----':type(@)}, typeProperty);  # don't
	AEBuild(q{'----':type(prop)});             # do

=item *

Similarly, when using AEStream, don't pass a four-char-code to WriteData(),
if you can avoid it.  Use one of the methods that allow type specification
(such as WriteDesc and WriteKeyDesc).

=item *

Don't try to parse binary data when you don't have to; use the API.  For
example, one of the example files for Mac::Speech parsed the creator ID
out of the binary data structure instead of calling the API, and got the
string reversed.

=back


=head1 PACKAGES AND EXPORT TAGS

See each individual module for more information on use.  See F<README>
for more information about modules not included here.

	Mac::AppleEvents	appleevents
	Mac::Components		components
	Mac::Files		files
	Mac::Gestalt		gestalt
	Mac::InternetConfig	internetconfig
	Mac::Memory		memory
	Mac::MoreFiles		morefiles
	Mac::Notification	notification
	Mac::OSA		osa	
	Mac::Processes		processes
	Mac::Resources		resources
	Mac::Sound		sound
	Mac::Speech		speech
	Mac::Types		types
	MacPerl			macperl

=cut

package Mac::Carbon;

use strict;
use base 'Exporter';
use vars qw(@EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

$VERSION = '0.82';

# we are just a frontend, so loop over the modules, and
# suck up everything in @EXPORT
BEGIN {
	my @modules = qw(
		AppleEvents
		Components
		Files
		Gestalt
		InternetConfig
		Memory
		MoreFiles
		Notification
		OSA
		Processes
		Resources
		Sound
		Speech
		Types
	);

	# oh oh, it's magic ...
	for (@modules) {
		no strict 'refs';
		my $mod = 'Mac::' . $_;
		eval "use $mod";
		die if $@;

		my @export = @{$mod . '::EXPORT'};
		push @EXPORT, @export;
		$EXPORT_TAGS{ lc $_ } = \@export;
	}

	# MacPerl is special, as almost everything is in EXPORT_OK
	use MacPerl ':all';
	push @EXPORT, @MacPerl::EXPORT, @MacPerl::EXPORT_OK;
	$EXPORT_TAGS{ 'macperl' } = [@MacPerl::EXPORT, @MacPerl::EXPORT_OK];

	@EXPORT_OK = @EXPORT;
	$EXPORT_TAGS{ 'all' } = \@EXPORT;
}

1;

__END__

=head1 UNSUPPORTED FUNCTIONS

=head2 Functions supported only in Mac OS

The functions below are supported only in Mac OS, and not in Mac OS X,
either because they are not supported by Carbon, or make no sense
on Mac OS X.

=over 4


=item Mac::AppleEvents

=over 4

=item AECountSubDescItems

=item AEDescToSubDesc

=item AEGetKeySubDesc

=item AEGetNthSubDesc

=item AEGetSubDescBasicType

=item AEGetSubDescData

=item AEGetSubDescType

=item AESubDescIsListOrRecord

=item AESubDescToDesc

=back


=item Mac::Files

=over 4

=item Eject

=back


=item Mac::InternetConfig

=over 4

=item ICChooseConfig

=item ICChooseNewConfig

=item ICGeneralFindConfigFile

=item ICGetConfigReference

=item ICGetComponentInstance

=item ICSetConfigReference

=back


=item Mac::Memory

=over

=item CompactMemSys

=item FreeMemSys

=item GetApplLimit

=item MaxBlockSys

=item MaxBlockSysClear

=item MaxMemSys

=item NewEmptyHandleSys

=item NewHandleSys

=item NewHandleSysClear

=item NewPtrSys

=item NewPtrSysClear

=item PurgeMemSys

=item ReserveMemSys

=back


=item Mac::Processes

=over 4

=item LaunchDeskAccessory

=back


=item Mac::Resources

=over 4

=item CreateResFile

=item OpenResFile

=item RGetResource

=back


=item Mac::Sound

=over 4

=item Comp3to1

=item Comp6to1

=item Exp1to3

=item Exp1to6

=item MACEVersion

=item SndControl

=item SndPauseFilePlay

=item SndRecordToFile

=item SndStartFilePlay

=item SndStopFilePlay

=item SPBRecordToFile

=back


=item MacPerl

=over 4

=item Choose

=item ErrorFormat

=item FAccess

=item LoadExternals

=item Quit

=item Reply

=back

=back


=head2 Functions supported only in Mac OS X

The functions below are supported only in Mac OS X, and not in Mac OS,
either because they are newer APIs, or make no sense on Mac OS.

=over 4

=item Mac::Processes

=over 4

=item GetProcessForPID

=item GetProcessPID

=item LSFindApplicationForInfo

=back


=item Mac::Resources

=over 4

=item FSCreateResourceFile

=item FSOpenResourceFile

=back

=back


=head1 KNOWN BUGS

See L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mac-Carbon> for more information.

=over 4

=item *

Need more tests for:

=over 4

=item Mac::Memory

Should be more comprehensive for very little-used functions; main functionality is tested OK.

=item Mac::Sound

Same.

=item Mac::Resources

Tested really only in other test suites, like Mac::Sound.  Should be more comprehensive.

=item Mac::Components

Same.

=item Mac::Files

Very good, but could do more exhausative FindFolder() tests.

=item Mac::Processes

Tests not very good, but tested pretty extensively by Mac::Glue and friends.

=item Mac::MoreFiles

Same.

=item Mac::OSA

Same.

=item Mac::InternetConfig

No real testing done.

=back

=item *

In a few places, we need to know a text encoding, and assume it
(such as in LSFindApplicationForInfo(), where Latin-1 is assumed).
This is likely incorrect.

=item *

FSSpecs are limited to 31 characters.  Ugh.  Provide access to newer
FSRef-based APIs.

=item *

Not specific to the Carbon versions: the Mac:: modules define classes
such as C<Handle> which probably should be something else, like
C<Mac::Handle> or C<Mac::Carbon::Handle> or C<Mac::Memory::Handle>
(other examples include C<AEDesc>, C<Point>, C<Rect>).  No one has really
complained before except on principle, but still ...

=item *

Can we support XCMDs etc. via XL?  Do we want to?

=back


=head1 AUTHOR

The Mac Toolbox modules were written by Matthias Neeracher
E<lt>neeracher@mac.comE<gt>.  They were ported to Mac OS X and
are currently maintained by Chris Nandor E<lt>pudge@pobox.comE<gt>.

=head1 THANKS

Michael Blakeley,
Emmanuel. M. Decarie,
Matthew Drayton,
brian d foy,
David Hand,
Gero Herrmann,
Peter N Lewis,
Paul McCann,
Sherm Pendley,
Randal Schwartz,
Michael Schwern,
John Siracusa,
Dan Sugalksi,
Ken Williams,
Steve Zellers.

=head1 SEE ALSO

perl(1).
