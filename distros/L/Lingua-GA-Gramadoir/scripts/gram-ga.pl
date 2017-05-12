#!/usr/bin/perl

=head1 NAME

gram-ga.pl - Command-line interface to An GramadE<oacute>ir

=head1 SYNOPSIS

B<gram-ga.pl> [I<options>] [I<FILE>...]

=head1 DESCRIPTION

This script checks the grammar of Irish language input
I<FILE>s (or standard input if no files are named).  The default behavior 
is to write a summary of possible errors to standard output.

=head1 OPTIONS

=over 4

=item B<-a>, B<--all>,
    B<--iomlan>     

report all errors (i.e. do not use ~/.neamhshuim)

=item B<-f>, B<--incode>,
    B<--ionchod>=I<ENC>

specify the character encoding of the text to be checked

=item B<-t>, B<--outcode>,
    B<--aschod>=I<ENC> 

specify the character encoding for output

=item B<--interface>,
    B<--comheadan>=xx

choose the language for error messages

=item B<--color>, B<--colour>,
    B<--dath>=I<COLOR> 

specify the color to use for highlighting errors

=item B<-l>, B<--list>,
    B<--litriu>     

write misspelled words to standard output

=item B<--moltai>,
    B<--aspell>     

suggest corrections for misspellings

=item B<-o>, B<--output>,
    B<--aschur>=I<FILE>

write output to I<FILE>

=item B<-h>, B<--cabhair>,
    B<--help>       

display this help and exit

=item B<-v>, B<--leagan>,
    B<--version>    

output version information and exit


=item B<--api>        

output a simple XML format for use with other applications

=item B<--html>       

produce HTML output for viewing in a web browser

=item B<--no-unigram>

do not resolve ambiguous parts of speech by frequency

=item B<--xml>        

write tagged XML stream to standard output, for debugging


=back

=head1 FILES

If there are words you wish to be ignored by the grammar checker
(proper names, etc.) you can place them in a file called I<.neamhshuim>
in your home directory, one word per line.

=head1 REQUIRES

Perl 5.8, Lingua::GA::Gramadoir

=head1 SEE ALSO

=over 4

=item *
L<http://borel.slu.edu/gramadoir/>

=item *
L<Lingua::GA::Gramadoir>

=item *
L<perl(1)>

=back

=head1 AUTHOR

Kevin P. Scannell, E<lt>kscanne@gmail.comE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004, 2005, 2007 Kevin P. Scannell

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

use strict;
use warnings;

use Getopt::Long qw(:config gnu_getopt);
use Term::ANSIColor;
use Lingua::GA::Gramadoir;
use Lingua::GA::Gramadoir::Languages;
# use open OUT => ':utf8';  # bad bad bad
#  gram-ga.pl -v 
# !=  gram-ga.pl -v > file; cat file

my $lh;
my $clar;
my $VERSION = '0.70';

sub gettext
{
	my ( $string, @rest ) = @_;

	$string =~ s/\\n/\n/g;
	$string =~ s/\[/~[/g;
	$string =~ s/\]/~]/g;
	$string =~ s/\%s/[_1]/;
	$string =~ s/\%s/[_2]/;
	return $lh->maketext($string, @rest);
}

sub localized_die
{
	my ( $signal ) = @_;
	my $msg;

	if ( $signal =~ m/^Unknown option: (.*)/ ) {
		my $arg = $1;
		chomp $arg;
		$msg = gettext('unrecognized option %s', '`'.$arg.'\'');
	}
	elsif ( $signal =~ m/^Option (.*) requires an argument/ ) {
		$msg = gettext('option %s requires an argument', '`'.$1.'\'');
	}
	elsif ( $signal =~ m/^Option (.*) does not take/ ) {
		$msg = gettext('option %s does not allow an argument', '`'.$1.'\'');
	}
	elsif ( $signal =~ m/^getopt/ ) {
		$msg = gettext('error parsing command-line options');
	}
	elsif ( $signal =~ m/^Invalid attribute name ([^ ]*)/ ) {
		$msg = gettext('Unable to set output color to %s', $1);
	}
	elsif ( $signal =~ m/^gram: maketext (.*)/ ) {
		$msg = gettext('Language %s is not supported.', $1);
	}
	else {
		die $signal;
	}
	my $dieclar = gettext('An Gramadoir');  # can't use global $clar yet
	my $tryhelp = gettext('Try %s for more information.', '`gram-ga.pl --help\'');
	print STDERR "$dieclar: $msg\n$tryhelp\n";
	exit 1;
}

$lh = Lingua::GA::Gramadoir::Languages->get_handle();
$SIG{__DIE__} = 'localized_die';
# scalars for global options
use vars qw($api $aschur $aspell $comheadan $dath $help $html $iomlan $ionchod $aschod $litriu $version $xml $nounigram);
$dath = 'bold red';
$ionchod = 'ISO-8859-1';
$aschod = 'utf8';
eval { 
	local $SIG{__WARN__} = 'localized_die';
	GetOptions (	
		'all|iomlan|a'          => \$iomlan,
		'api'                   => \$api,
		'aspell|moltai'         => \$aspell,
		'list|litriu|l'         => \$litriu,
		'color|colour|dath=s'	=> \$dath,
		'incode|ionchod|f=s'    => \$ionchod,
		'outcode|aschod|t=s'    => \$aschod,
		'no-unigram'		=> \$nounigram,
		'help|cabhair|h'        => \$help,
		'html'			=> \$html,
		'interface|comheadan=s' => \$comheadan,
		'output|aschur|o=s'     => \$aschur,
		'version|leagan|v'      => \$version,
		'xml'                   => \$xml,
		) 
};
die "getopt error" if $@;

$xml = 1 if $nounigram;
unless ($dath eq "none") {
eval { color $dath };
}

if ($aschur) {
	unless ($^O eq 'MSWin32') {
		$aschur =~ s#^~(\w*)#$1 ? (getpwnam($1))[7] : ( $ENV{HOME} || $ENV{LOGDIR} || (getpwuid($>))[7] )#e;
	}
	open(OUTSTREAM, ">:encoding($aschod)", $aschur) or
		warn "Can't open $aschur: $!\n";
}
else {
	open(OUTSTREAM, ">&=STDOUT") or
		warn "Couldn't alias STDOUT: $!\n";
	binmode OUTSTREAM, ":encoding($aschod)";  # must be after alias
}

binmode STDERR, ":encoding($aschod)";

if ($comheadan) {
	$lh = Lingua::GA::Gramadoir::Languages->get_handle($comheadan);
	die "gram: maketext $comheadan" unless $lh;
}
# $lh->fail_with('failure_handler_auto'); 

# TRANSLATORS: Please leave untranslated, but add an acute accent to the
# "o" in "Gramadoir" if available in your character set and encoding.
# If you must translate, this is the Irish for (literally) "The Grammarian"
$clar = gettext('An Gramadoir');

if ($version) {
	my $vstring = gettext('version %s', $VERSION);
	my $copyright = 'Copyright (C) 2003-2007 Kevin P. Scannell';
	my $gpl = gettext('This is free software; see the source for copying conditions.  There is NO\\nwarranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE,\\nto the extent permitted by law.');
	if ($html) {
		$copyright =~ s#(Kevin P. Scannell)#<a href="http://borel.slu.edu/">$1</a><br><br>#;
		print OUTSTREAM "<p>\n<a href=\"http://borel.slu.edu/gramadoir/\">$clar</a>, $vstring<br>\n$copyright\n<i>$gpl</i></p><hr>\n";
	}
	else {
		print OUTSTREAM "$clar, $vstring\n$copyright\n$gpl\n";
	}
	close OUTSTREAM;
	exit 0;
}
if ($help) {
	my @helpmessages = (
gettext(
'Usage: %s [OPTIONS] [FILES]', "gram-ga.pl"),
"",
gettext(
"Options for end-users:"),
# TRANSLATORS: ~/.neamhshuim is an "ignore file" like those with spellcheckers
"  -a, --all,",
gettext(
"    --iomlan       report all errors (i.e. do not use ~/.neamhshuim)"),
"  -f, --incode,",
gettext(
"    --ionchod=ENC  specify the character encoding of the text to be checked"),
"  -t, --outcode,",
gettext(
"    --aschod=ENC   specify the character encoding for output"),
"  --interface,",
gettext(
"    --comheadan=xx choose the language for error messages"),
"  --color, --colour,",
gettext(
"    --dath=COLOR   specify the color to use for highlighting errors"),
"  -l, --list,",
gettext(
"    --litriu       write misspelled words to standard output"),
"  --moltai,",
gettext(
"    --aspell       suggest corrections for misspellings"),
"  -o, --output,",
gettext(
"    --aschur=FILE  write output to FILE"),
"  -h, --cabhair,",
gettext(
"    --help         display this help and exit"),
"  -v, --leagan,",
gettext(
"    --version      output version information and exit"),
"",
gettext(
"Options for developers:"),
gettext(
"    --api          output a simple XML format for use with other applications"),
gettext(
"    --html         produce HTML output for viewing in a web browser"),
# TRANSLATORS: By default, if there is no rule in the disambiguation module
# for selecting the correct part of speech of an ambiguous word, the program
# chooses the part of speech with the highest frequency.  This is sometimes
# called "unigram" tagging.   The --no-unigram option turns this behavior off.
gettext(
"    --no-unigram   do not resolve ambiguous parts of speech by frequency"),
# TRANSLATORS: The grammar checker works by passing the input text
# through a sequence of filters which add XML markup indicating
# important grammatical information.  The --xml option displays the
# marked up file as an aid in debugging.
gettext(
"    --xml          write tagged XML stream to standard output, for debugging"),
"",
gettext(
"If no file is given, read from standard input."),
"",
gettext(
'Send bug reports to <%s>.','kscanne@gmail.com'),
""
);

	print OUTSTREAM join("\n", @helpmessages);
	close OUTSTREAM;
	exit 0;
}

my $gr = new Lingua::GA::Gramadoir(
	fix_spelling => $aspell,
	use_ignore_file => ! $iomlan,
	unigram_tagging => ! $nounigram,
	interface_language => $comheadan,
	input_encoding => $ionchod,
);

binmode STDIN, ":bytes";
unshift(@ARGV, '-') unless @ARGV;
while ($ARGV = shift @ARGV) {
	unless ($ARGV eq "-") {
		unless ( -e $ARGV ) {
		        warn "$clar: $ARGV: ".gettext('There is no such file.')."\n";
     			next;
		}
		if ( -d $ARGV ) {
		        warn "$clar: $ARGV: ".gettext('Is a directory')."\n";
     			next;
		}
		unless ( -f $ARGV ) {
		        warn "$ARGV is Not a plain file\n";
     			next;
		}
		unless ( -r $ARGV ) {
		        warn "$clar: $ARGV: ".gettext('Permission denied')."\n";
     			next;
		}
   		unless (open(ARGV, "<:bytes", $ARGV)) {
			warn "Can't open $ARGV: $!\n";
     			next;
    		}
	}
	local $/;  # slurp a file at a time
	$_ = <ARGV>;
	warn gettext('%s: warning: problem closing %s\n', $clar, $ARGV) unless close ARGV;
	if ($litriu) {
		my $missp = $gr->spell_check($_);
		foreach (@$missp) {
			print OUTSTREAM "$_\n";
		}
	}
	elsif ($xml) {
		print OUTSTREAM $gr->xml_stream($_);
	}
	elsif ($api) {
		print OUTSTREAM '<?xml version="1.0" encoding="utf-8" standalone="no"?>'."\n".'<!DOCTYPE matches SYSTEM "http://borel.slu.edu/dtds/api-output.dtd">'."\n<matches>\n";
		my $apierr = $gr->grammatical_errors($_);
		foreach (@$apierr) {
			print OUTSTREAM "$_\n";
		}
		print OUTSTREAM "</matches>\n";
	}
	else {   # vanilla or html
		my $status = gettext('Currently checking %s', $ARGV);
		print OUTSTREAM "$status\n" unless ($ARGV eq "-");
		my $errs = $gr->grammatical_errors($_);
		foreach my $error (@$errs) {
			(my $ln, my $msg, my $snt, my $offset, my $len) = $error =~ m/^<error fromy="([0-9]+)".* msg="([^"]+)".* context="([^"]+)" contextoffset="([0-9]+)" errorlength="([0-9]+)"\/>$/;
			my $errortext = substr($snt,$offset,$len);
			$ln++;   # people count lines from 1
			my $s = "<br><br>$ln: ".substr($snt,0,$offset);
			if ($html) {
				$s .= "<b class=gramadoir>$errortext</b>";
			}
			else {
				if ($dath eq "none") {
					$s .= $errortext;
				}
				else {
					$s .= colored($errortext,$dath);
				}
			}
			$s .= substr($snt,$offset+$len)."<br>\n$msg\n\n";  # don't add punctuation
			if (!$html) {
				$s =~ s/<br>//g;
				$s =~ s/&quot;/"/g;
				$s =~ s/&lt;/</g;
				$s =~ s/&gt;/>/g;
				$s =~ s/&amp;/&/g;
			}
			print OUTSTREAM $s;
		} # loop over errors
	}  # vanilla/html block
}  # loop over files

close OUTSTREAM;
exit 0;
