# This code is part of Perl distribution Mail-Box version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

# This code is part of distribution Mail-Message.  Meta-POD processed with
# OODoc into POD and HTML manual-pages.  See README.md
# Copyright Mark Overmeer.  Licensed under the same terms as Perl itself.

package Mail::Box::Test;{
our $VERSION = '4.00';
}

use parent 'Exporter';

use strict;
use warnings;

use Log::Report      'mail-box', import => [ qw// ];

use File::Copy            qw/copy/;
use List::Util            qw/first/;
use File::Spec::Functions qw/catdir catfile devnull/;;
use File::Temp            qw/tempdir/;
use Cwd                   qw/getcwd/;
use Sys::Hostname         qw/hostname/;
use Test::More;


our @EXPORT = qw/
	clean_dir copy_dir
	unpack_mbox2mh unpack_mbox2maildir
	compare_lists listdir
	compare_message_prints reproducable_text
	compare_thread_dumps

	$folderdir
	$workdir
	$src $unixsrc $winsrc
	$fn  $unixfn  $winfn
	$cpy $cpyfn
	$raw_html_data
	$crlf_platform $windows
/;

our ($logfile, $folderdir);
our ($src, $unixsrc, $winsrc);
our ($fn,  $unixfn,  $winfn);
our ($cpy, $cpyfn);
our ($crlf_platform, $windows);
our $workdir;

BEGIN {
	$windows       = $^O =~ m/mswin32/i;
	$crlf_platform = $windows;

	$folderdir     = catdir 't','folders';
	$workdir       = tempdir(CLEANUP => 1);

	$logfile = catfile getcwd(), 'run-log';
	$unixfn  = 'mbox.src';
	$winfn   = 'mbox.win';
	$cpyfn   = 'mbox.cpy';

	$unixsrc = catfile $folderdir, $unixfn;
	$winsrc  = catfile $folderdir, $winfn;
	$cpy     = catfile $workdir, $cpyfn;

	($src, $fn) = $windows ? ($winsrc, $winfn) : ($unixsrc, $unixfn);

	# ensure to test the Perl Parser not the C-Parser (separate distribution)
	require Mail::Box::Parser::Perl;
	Mail::Box::Parser->defaultParserType('Mail::Box::Parser::Perl');
}

#
# CLEAN_DIR
# Clean a directory structure, typically created by unpack_mbox()
#

sub clean_dir($);
sub clean_dir($)
{	my $dir = shift;
	opendir my $dh, $dir or return;

	my @items = map m/(.*)/ && "$dir/$1",   # untainted
		grep !/^\.\.?$/, readdir $dh;

	foreach (@items)
	{	if(-d)  { clean_dir $_ }
		else    { unlink $_ }
	}

	closedir $dh;
	rmdir $dir;
}

#
# COPY_DIR FROM, TO
# Copy directory to other place (not recursively), cleaning the
# destination first.
#

sub copy_dir($$)
{	my ($orig, $dest) = @_;

	clean_dir $dest;

	mkdir $dest
		or die "Cannot create copy destination $dest: $!\n";

	opendir my $dh, $orig
		or die "Cannot open directory $orig: $!\n";

	foreach my $name (map { !m/^\.\.?$/ && m/(.*)/ ? $1 : () } readdir $dh)
	{	my $from = catfile($orig, $name);
		next if -d $from;

		my $to   = catfile($dest, $name);
		copy($from, $to) or die "Couldn't copy $from,$to: $!\n";
	}

	close $dh;
}

# UNPACK_MBOX2MH
# Unpack an mbox-file into an MH-directory.
# This skips message-nr 13 for testing purposes.
# Blanks before "From" are removed.

sub unpack_mbox2mh($$)
{	my ($file, $dir) = @_;

	clean_dir $dir;
	mkdir $dir, 0700;

	my $count = 1;
	my $blank;

	open my $fh, '<:raw', $file or die;
	open my $out, '>:raw', devnull;

	local $_;
	while(<$fh>)
	{	if( /^From / )
		{	$out->close;
			undef $blank;
			open $out, '>', "$dir/".$count++ or die;
			$count++ if $count==13;  # skip 13 for test
			next;                    # from line not included in file.
		}

		$out->print($blank) if defined $blank;

		if( m/^\015?\012$/ )
		{	$blank = $_;
			next;
		}

		undef $blank;
		$out->print($_);
	}
	$out->close;
	$fh->close;
}

# UNPACK_MBOX2MAILDIR
# Unpack an mbox-file into an Maildir-directory.

our @maildir_names =
(   '8000000.localhost.23:2,',
	'90000000.localhost.213:2,',
	'110000000.localhost.12:2,',
	'110000001.l.42:2,',
	'110000002.l.42:2,',
	'110000002.l.43:2,',
	'110000004.l.43:2,',
	'110000005.l.43:2,',
	'110000006.l.43:2,',
	'110000007.l.43:2,D',
	'110000008.l.43:2,DF',
	'110000009.l.43:2,DFR',
	'110000010.l.43:2,DFRS',
	'110000011.l.43:2,DFRST',
	'110000012.l.43:2,F',
	'110000013.l.43:2,FR',
	'110000014.l.43:2,FRS',
	'110000015.l.43:2,FRST',
	'110000016.l.43:2,DR',
	'110000017.l.43:2,DRS',
	'110000018.l.43:2,DRST',
	'110000019.l.43:2,FS',
	'110000020.l.43:2,FST',
	'110000021.l.43:2,R',
	'110000022.l.43:2,RS',
	'110000023.l.43:2,RST',
	'110000024.l.43:2,S',
	'110000025.l.43:2,ST',
	'110000026.l.43:2,T',
	'110000027.l.43:2,',
	'110000028.l.43:2,',
	'110000029.l.43:2,',
	'110000030.l.43:2,',
	'110000031.l.43:2,',
	'110000032.l.43:2,',
	'110000033.l.43:2,',
	'110000034.l.43:2,',
	'110000035.l.43:2,',
	'110000036.l.43:2,',
	'110000037.l.43:2,',
	'110000038.l.43',
	'110000039.l.43',
	'110000040.l.43',
	'110000041.l.43',
	'110000042.l.43',
);

sub unpack_mbox2maildir($$)
{	my ($file, $dir) = @_;
	clean_dir $dir;

	@maildir_names==45 or die;
	mkdir $dir or die;
	mkdir catfile($dir, 'cur') or die;
	mkdir catfile($dir, 'new') or die;
	mkdir catfile($dir, 'tmp') or die;

	open my $fh, '<:raw', $file or die;
	open my $out, '>:raw', devnull;

	my $msgnr      = 0;
	my $last_empty = 0;
	my $blank;

	local $_;
	while(<$fh>)
	{	if( m/^From / )
		{	$out->close;
			undef $blank;
			my $now      = time;
			my $hostname = hostname;

			my $msgfile  = catfile $dir, ($msgnr > 40 ? 'new' : 'cur'), $maildir_names[$msgnr++];

			open $out, ">:raw", $msgfile
				 or die "Create $msgfile: $!\n";

			next;                    # from line not included in file.
		}

		$out->print($blank) if defined $blank;

		if( m/^\015?\012$/ )
		{	$blank = $_;
			next;
		}

		undef $blank;
		$out->print($_);
	}

	$out->close;
	$fh->close;
}

#
# Compare two lists.
#

sub compare_lists($$)
{	my ($first, $second) = @_;
#warn "[@$first]==[@$second]\n";
	return 0 unless @$first == @$second;
	for(my $i=0; $i<@$first; $i++)
	{	return 0 unless $first->[$i] eq $second->[$i];
	}
	1;
}

#
# Compare the text of two messages, rather strict.
# On CRLF platforms, the Content-Length may be different.
#

sub compare_message_prints($$$)
{	my ($first, $second, $label) = @_;

	if($crlf_platform)
	{	s/Content-Length: \d+/Content-Length: <removed>/g for $first, $second;
	}

	is($first, $second, $label);
}

#
# Strip message text down the things which are the same on all
# platforms and all situations.
#

sub reproducable_text($)
{	my $text  = shift;
	my @lines = split /^/m, $text;
	foreach (@lines)
	{	s/((?:references|message-id|date|content-length)\: ).*/$1<removed>/i;
		s/boundary-\d+/boundary-<removed>/g;
	}
	join '', @lines;
}

#
# Compare two outputs of thread details.
# On CRLF platforms, the reported sizes are ignored.
#

sub compare_thread_dumps($$$)
{	my ($first, $second, $label) = @_;

	if($crlf_platform)
	{	$first  =~ s/^..../    /gm;
		$second =~ s/^..../    /gm;
	}

	is($first, $second, $label);
}

#
# List directory
# This removes '.' and '..'
#

sub listdir($)
{	my $dir = shift;
	opendir my $list, $dir or return ();
	my @entities = grep !/^\.\.?$/, readdir $list;
	closedir $list;
	@entities;
}

#
# A piece of HTML text which is used in some tests.
#

our $raw_html_data = <<'TEXT';
<HTML>
<HEAD>
<TITLE>My home page</TITLE>
</HEAD>
<BODY BGCOLOR=red>

<H1>Life according to Brian</H1>

This is normal text, but not in a paragraph.<P>New paragraph
in a bad way.

And this is just a continuation.  When texts get long, they must be
auto-wrapped; and even that is working already.

<H3>Silly subsection at once</H3>
<H1>and another chapter</H1>
<H2>again a section</H2>
<P>Normal paragraph, which contains an <IMG
SRC=image.gif>, some
<I>italics with linebreak
</I> and <TT>code</TT>

<PRE>
And now for the preformatted stuff
   it should stay as it was
      even   with   strange blanks
  and indentations
</PRE>

And back to normal text...
<UL>
<LI>list item 1
    <OL>
    <LI>list item 1.1
    <LI>list item 1.2
    </OL>
<LI>list item 2
</UL>
</BODY>
</HTML>
TEXT

1;
