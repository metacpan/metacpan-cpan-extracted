package MacPerl;

require Exporter;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $Target);

$VERSION = '1.06';

@ISA = qw(Exporter);

@EXPORT = qw(
	kMacPerlNeverQuit
	kMacPerlQuitIfRuntime
	kMacPerlAlwaysQuit
	kMacPerlQuitIfFirstScript
);

@EXPORT_OK = qw(
	SetFileInfo
	GetFileInfo
	Ask
	Answer
	Choose
	Pick
	Quit
	FAccess
	MakeFSSpec
	MakePath
	Volumes

	$Version
	$Architecture
	$Compiler

	Reply
	DoAppleScript
	
	LoadExternals
);

%EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK]);

sub kMacPerlNeverQuit ()		{ 0; }
sub kMacPerlQuitIfRuntime ()		{ 1; }
sub kMacPerlAlwaysQuit ()		{ 2; }
sub kMacPerlQuitIfFirstScript ()	{ 3; }

# allow caller overriding of default target with $MacPerl::Target
$Target ||= 'SystemUIServer';

# bootstrap MacPerl is already implicitly done by your MacPerl binary
unless ($^O eq 'MacOS') {
	# use Config;
	# my $dl_dlext = $Config::Config{'dlext'};
	my $dl_dlext = 'bundle';

	require DynaLoader;
	push @ISA, 'DynaLoader';
	bootstrap MacPerl;

	# because OSA is in MacPerl.bundle, not OSA.bundle
	my $file = "auto/MacPerl/MacPerl.$dl_dlext";
	foreach (@INC) {
		my $dir = "$_/auto/MacPerl";
		next unless -d $dir;
		my $try = "$dir/MacPerl.$dl_dlext";
		last if $file = -f $try && $try;
	}

	for my $mod (qw(OSA)) {
		my($xs, $symref);
		for (@DynaLoader::dl_librefs) {
			last if $symref = DynaLoader::dl_find_symbol($_, "boot_$mod");
		}
		next unless $symref;
		$xs = DynaLoader::dl_install_xsub("${mod}::bootstrap", $symref, $file);
		&$xs($mod);
	}

	no strict 'refs';
	no warnings 'redefine'; 
	*Answer	= *_CarbonAnswer{CODE};
	*Ask	= *_CarbonAsk{CODE};
	*Pick	= *_CarbonPick{CODE};
}

sub _CarbonAnswer {
	my $prompt = shift;
	my @buttons = @_ ? reverse @_ : 'OK';
	@buttons = map {
		s/^(Cancel)$/$1 /i;
		s/"(.+?)"/\xD2$1\xD3/g;
		s/"/\xD2/g;
		$_;
	} @buttons;

	my $buttons = join '","', @buttons;
	my $default = @buttons;

	if (!$Target) {
		return _CarbonText($prompt, \@buttons, $default-1);
	}

	my $result = _CarbonDoScript(<<EOS);
tell application "$Target"
	activate
	display dialog "$prompt" buttons {"$buttons"} default button $default
end tell
EOS

	$result =~ s/.*?"(.+)".*/$1/;
	$result =~ s/\\(["\\])/$1/g;
	foreach my $no (0..$#buttons) {
		return $no if $result eq $buttons[$no];
	}
}

sub _CarbonAsk {
	my($prompt, $default) = @_;
	$default ||= '';

	if (!$Target) {
		return _CarbonText($prompt, 0, $default);
	}

	my $result = _CarbonDoScript(<<EOS);
tell application "$Target"
	activate
	display dialog "$prompt" default answer "$default" buttons {"Cancel ","OK"} default button 2
end tell
EOS

	return undef if $result =~ /Cancel "}$/;
	$result =~ s/.*?"(.*)".*"OK"}/$1/;
	$result =~ s/\\(["\\])/$1/g;
	return $result;
}

sub _CarbonPick {
	my($prompt, @values) = @_;
	@values = map { s/(["\\])/\\$1/g; $_ } @values;
	my $values = join '","', @values;
	my $multiple = wantarray ? 'and multiple selections allowed' : '';

	if (!$Target) {
		return _CarbonText($prompt, \@values, '', $multiple, 1);
	}

	my $result = _CarbonDoScript(<<EOS);
tell application "$Target"
	activate
	choose from list {"$values"} with prompt "$prompt" with empty selection allowed $multiple
end tell
EOS

	return undef if $result =~ /^false|{}$/;
	$result =~ s/\\(["\\])/$1/g;
	$result =~ s/^{"|"}$//g;
	return wantarray ? split /", "/, $result : $result;
}

sub _CarbonDoScript {
	my($script) = @_;

	my $result = DoAppleScript($script);

	return $result;
}

sub _CarbonText {
	local $| = 1;
	local $\;
	my($prompt, $options, $default, $multiple, $text) = @_;

	$default = '' unless defined $default;
	my $string = $prompt;

	if (ref $options eq 'ARRAY') {
		if ($multiple) {
			print "Pick one or more of the following (separate by commas):\n";
		} else {
			print "Pick one of the following:\n";
		}

		my $num = length @$options;
		for (0 .. $#{$options}) {
			printf " [%${num}d] %s\n", $_, $options->[$_];
		}
	} else {
		$multiple = $text = '';
	}

	$string .= sprintf(' [%s]', $default) if length $default;
	$string .= ': ';

	print $string;
	chomp(my $ans = <STDIN>);

	if ($multiple) {
		$ans = [ sort { $a <=> $b } split /\s*,\s*/, $ans ];
	}

	if ($text) {
		if (ref $ans eq 'ARRAY') {
			for (@$ans) {
				$_ = $options->[$_];
			}
		} else {
			$ans = $options->[$ans];
		}
	}

	return length $ans ? ref $ans eq 'ARRAY' ? @$ans : $ans : $default;
}

1;

__END__

=head1 NAME

MacPerl - Built-in Macintosh specific routines.

=head1 SYNOPSIS

    $phone = MacPerl::Ask("Enter your phone number:");
    MacPerl::Answer("Nunc et in hora mortis nostrae", "Amen");
    $color = MacPerl::Pick("What's your favorite color baby ?", "Red", "Green", "Gold");

    MacPerl::SetFileInfo("MPS ", "TEXT", yin, yang);
    MacPerl::GetFileInfo(yin);

    MacPerl::Quit(kMacPerlAlwaysQuit);

=head1 FUNCTIONS

=over 8

=item MacPerl::Answer(PROMPT)

=item MacPerl::Answer(PROMPT,BUTTON1)

=item MacPerl::Answer(PROMPT,BUTTON1,BUTTON2)

=item MacPerl::Answer(PROMPT,BUTTON1,BUTTON2,BUTTON3)

Presents to the user a dialog with 1, 2, or 3 buttons. 

Examples:

    MacPerl::Answer("Nunc et in hora mortis nostrae", "Amen");

always returns 0.

    MacPerl::Answer("I refuse");

is equivalent to C<MacPerl'Answer("I refuse", "OK");>

    MacPerl::Answer("Delete hard disk ?", "OK", "Cancel");

returns 1 for OK, 0 for Cancel

    MacPerl::Answer("Overwrite existig file", "Overwrite", "Skip", "Cancel");

returns 2 for Overwrite, 1 for Skip, 0 for Cancel

=item MacPerl::Ask(PROMPT, DEFAULT)

=item MacPerl::Ask(PROMPT)

Asks the user for a string. A default value may be given. Returns
undef if the dialog is cancelled.

Example:

    $phone = MacPerl::Ask("Enter your phone number:");
    $name  = MacPerl::Ask("Enter your first name", "Bruce");

Useful for Australian database applications

=item MacPerl::Pick(PROMPT, VALUES)

Asks the user to pick a choice from a list. VALUES is a list of choices. 
Returns undef if the dialog is cancelled.

Examples:

    $color = MacPerl::Pick("What's your favorite color baby ?", "Red", "Green", "Gold");

=item MacPerl::SetFileInfo(CREATOR,TYPE,FILE...)

Changes the file types and creators of the file(s).

Examples:

    MacPerl::SetFileInfo("MPS ", "TEXT", yin, yang);

Turn yin and yang into MPW text files

=item MacPerl::GetFileInfo(FILE)

In scalar context, returns the file type. In array context, returns (creator,type).

Examples:

    MacPerl::GetFileInfo(yin);

Returns "TEXT" or ("MPS ", "TEXT").

=item MacPerl::DoAppleScript(SCRIPT)

Execute an AppleScript script.  Returns the text of the script result.
Script error strings are returned in C<$@>.

Example:

	my $text = MacPerl::DoAppleScript(<<END_SCRIPT) or die $@;
	tell application "BBEdit"
		make new Window
		copy "Inserting text the hard way." to character 1 of front Window
		get (characters 1 through 9 of front Window) as text
	end tell
	END_SCRIPT

B<Note>: calling DoAppleScript to tell MacPerl to do something via
AppleScript may yield unpredictable results, especially when waiting
on MacPerl to reply, such as when stringing multiple events together,
or expecting data to be returned.  Try wrapping the "tell" block in
"ignoring application responses" / "end ignoring" if necessary.

=item MacPerl::Reply(ANSWER)

Reply to current DoScript request. Useful if you are calling Perl 
scripts from other applications.

=item MacPerl::Quit(LEVEL)

B<Mac OS only.>

If LEVEL is 0, don't quit after ending the script. If 1, quit if 
running under a runtime version, if 2, always quit. If LEVEL is 3,
quit if this was the first script to be run since starting MacPerl.

=item MacPerl::LoadExternals(LIBFILE)

B<Mac OS only.>

Load XCMD and XFCN extensions contained in file LIBFILE, which is searched
along the same path as it would be for a require. The extensions are made
accessible in the current package, unless they containing an explicit package
name.

=item MacPerl::FAccess(FILE, CMD, ARGS)

B<Mac OS only.>

When called from the tool, manipulate various information of files. To 
get the command constants, it's convenient to require "FAccess.ph".

=over 8

=item $TAB = MacPerl::FAccess(FILE, F_GTABINFO)

=item MacPerl::FAccess(FILE, F_STABINFO, TAB)

Manipulate tabulator setting (in spaces per tab).

=item ($FONTNAME, $FONTSIZE) = MacPerl::FAccess(FILE, F_GFONTINFO)

=item $FONTNUM = MacPerl::FAccess(FILE, F_GFONTINFO)

=item MacPerl::FAccess(FILE, F_SFONTINFO, FONT [, SIZE])

Manipulate font and size information. Both font names and font numbers
are accepted for F_SFONTINFO; F_GFONTINFO returns a font name in an
array context, a font number in a scalar context.

=item ($STARTSEL, $ENDSEL, $DISPLAYTOP) = MacPerl::FAccess(FILE, F_GSELINFO)

=item $STARTSEL = MacPerl::FAccess(FILE, F_GSELINFO)

=item MacPerl::FAccess(FILE, F_SSELINFO, $STARTSEL, $ENDSEL [, $DISPLAYTOP])

Manipulate the MPW selection of a file.

=item ($LEFT, $TOP, $RIGHT, $BOTTOM) = MacPerl::FAccess(FILE, F_GWININFO)
=item $TOP = MacPerl::FAccess(FILE, F_GWININFO)
=item MacPerl::FAccess(FILE, F_SWININFO, LEFT, TOP [, RIGHT, BOTTOM])

Manipulate the window position.

=back

=item MacPerl::MakeFSSpec(PATH)

This command encodes a path name into an encoding (volume #, directory #,
File name) which is guaranteed to be unique for every file. Don't store
this encoding between runs of MacPerl!

=item MacPerl::MakePath(FSSPEC)

The inverse of MacPerl::MakeFSSpec(): turn an encoding into a path name.

=item MacPerl::Volumes()

In scalar context, return the FSSPEC of the startup volume. In list context, 
return FSSPECs of all volumes.

=back


=head1 SEE ALSO

L<macperl>

=cut
