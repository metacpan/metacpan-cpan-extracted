# This code is part of Perl distribution Mail-Message version 4.03.
# The POD got stripped from this file by OODoc version 3.06.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2026 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::Parser::Perl;{
our $VERSION = '4.03';
}

use parent 'Mail::Box::Parser';

use strict;
use warnings;

use Log::Report   'mail-message', import => [ qw/__x error fault info warning trace/ ];

use List::Util    qw/sum/;
use IO::File      ();

use Mail::Message::Field ();

my $empty_line = qr/^\015?\012?$/;

#--------------------

sub init(@)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	$self->{MBPP_mode}     = $args->{mode} || 'r';
	$self->{MBPP_filename} = $args->{filename} || ref $args->{file}
		or error __x"filename or handle required to create a parser.";

	$self->start(file => $args->{file});
	$self;
}

#--------------------

sub filename() { $_[0]->{MBPP_filename} }
sub openMode() { $_[0]->{MBPP_mode} }
sub file()     { $_[0]->{MBPP_file} }

#--------------------

sub start(@)
{	my ($self, %args) = @_;
	$self->openFile(%args) or return;
	$self->takeFileInfo;

	trace "opened folder ".$self->filename." to be parsed";
	$self;
}


sub stop()
{	my $self = shift;
	trace "close parser for file " . $self->filename;
	$self->closeFile;
}


sub restart()
{	my $self     = shift;
	$self->closeFile;
	$self->openFile(@_) or return;
	$self->takeFileInfo;
	trace "restarted parser for file " . $self->filename;
	$self;
}


sub fileChanged()
{	my $self = shift;
	my ($size, $mtime) = (stat $self->filename)[7,9];
	return 0 if !defined $size || !defined $mtime;
	$size != $self->{MBPP_size} || $mtime != $self->{MBPP_mtime};
}


sub filePosition(;$)
{	my $self = shift;
	@_ ? $self->file->seek(shift, 0) : $self->file->tell;
}


sub readHeader()
{	my $self  = shift;
	my $file  = $self->file or return ();
	my @ret   = ($file->tell, undef);
	my $line  = $file->getline;

  LINE:
	while(defined $line)
	{	last LINE if $line =~ $empty_line;
		my ($name, $body) = split /\s*\:\s*/, $line, 2;

		unless(defined $body)
		{	warning __x"unexpected end of header in {file}:\n {line}", file => $self->filename, line => $line;

			if(@ret && $self->fixHeaderErrors)
			{	$ret[-1][1] .= ' '.$line;  # glue err line to previous field
				$line = $file->getline;
				next LINE;
			}

			$file->seek(-length $line, 1);
			last LINE;
		}

		length $body or $body = "\n";

		# Collect folded lines
		while($line = $file->getline)
		{	$line =~ m!^[ \t]! ? ($body .= $line) : last;
		}

		$body =~ s/\015//g;
		push @ret, [ $name, $body ];
	}

	$ret[1]  = $file->tell;
	@ret;
}

sub _is_good_end($)
{	my ($self, $where) = @_;

	# No seps, then when have to trust it.
	my $sep  = $self->activeSeparator // return 1;
	my $file = $self->file;
	my $here = $file->tell;
	$file->seek($where, 0) or return 0;

	# Find first non-empty line on specified location.
	my $line = $file->getline;
	$line    = $file->getline while defined $line && $line =~ $empty_line;

	# Check completed, return to old spot.
	$file->seek($here, 0);
	$line // return 1;

		substr($line, 0, length $sep) eq $sep
	&& ($sep ne 'From ' || $line =~ m/ (?:19[6-9]|20[0-3])[0-9]\b/ );
}

sub readSeparator()
{	my $self  = shift;
	my $sep   = $self->activeSeparator // return ();
	my $file  = $self->file;
	my $start = $file->tell;

	my $line  = $file->getline;
	while(defined $line && $line =~ $empty_line)
	{	$start = $file->tell;
		$line  = $file->getline;
	}

	$line // return ();
	$line      =~ s/[\012\015]+$/\n/;

	substr($line, 0, length $sep) eq $sep
		and return ($start, $line);

	$file->seek($start, 0);
	();
}

sub _readStrippedLines(;$$)
{	my ($self, $exp_chars, $exp_lines) = @_;
	my $seps    = $self->separators;
	my $file    = $self->file;
	my $lines   = [];
	my $msgend;

	if(@$seps)
	{
		LINE:
		while(1)
		{	my $where = $file->getpos;
			my $line  = $file->getline or last LINE;

			foreach my $sep (@$seps)
			{	substr($line, 0, length $sep) eq $sep or next;

				# Some apps fail to escape lines starting with From
				next if $sep eq 'From ' && $line !~ m/ 19[789][0-9]| 20[0-9][0-9]/;

				$file->setpos($where);
				$msgend = $file->tell;
				last LINE;
			}

			push @$lines, $line;
		}

		if(@$lines && $lines->[-1] =~ s/\015?\012\z//)
		{	# Keep an empty line to signal the existence of a preamble, but
			# remove a second.
			pop @$lines if @$seps==1 && @$lines > 1 && length($lines->[-1])==0;
		}
	}
	else # File without separators.
	{	$lines = ref $file eq 'Mail::Box::FastScalar' ? $file->getlines : [ $file->getlines ];
	}

	my $bodyend = $file->tell;
	if($self->stripGt)
	{	s/^\>(\>*From\s)/$1/ for @$lines;
	}

	unless($self->trusted)
	{	s/\015$// for @$lines;
		# input is read as binary stream (i.e. preserving CRLF on Windows).
		# Code is based on this assumption. Removal of CR if not trusted
		# conflicts with this assumption. [Markus Spann]
	}

	($bodyend, $lines, $msgend);
}

sub _take_scalar($$)
{	my ($self, $begin, $end) = @_;
	my $file = $self->file;
	$file->seek($begin, 0);

	my $buffer;
	$file->read($buffer, $end-$begin);
	$buffer =~ s/\015//gr;
}

sub bodyAsString(;$$)
{	my ($self, $exp_chars, $exp_lines) = @_;
	my $file  = $self->file;
	my $begin = $file->tell;

	if(defined $exp_chars && $exp_chars>=0)
	{	# Get at once may be successful
		my $end = $begin + $exp_chars;

		if($self->_is_good_end($end))
		{	my $body = $self->_take_scalar($begin, $end);
			$body =~ s/^\>(\>*From\s)/$1/gm if $self->stripGt;
			return ($begin, $file->tell, $body);
		}
	}

	my ($end, $lines) = $self->_readStrippedLines($exp_chars, $exp_lines);
	($begin, $end, join('', @$lines));
}

sub bodyAsList(;$$)
{	my ($self, $exp_chars, $exp_lines) = @_;
	my $file  = $self->file;
	my $begin = $file->tell;

	my ($end, $lines) = $self->_readStrippedLines($exp_chars, $exp_lines);
	($begin, $end, $lines);
}

sub bodyAsFile($;$$)
{	my ($self, $out, $exp_chars, $exp_lines) = @_;
	my $file  = $self->file;
	my $begin = $file->tell;

	my ($end, $lines) = $self->_readStrippedLines($exp_chars, $exp_lines);

	$out->print($_) for @$lines;
	($begin, $end, scalar @$lines);
}

sub bodyDelayed(;$$)
{	my ($self, $exp_chars, $exp_lines) = @_;
	my $file  = $self->file;
	my $begin = $file->tell;

	if(defined $exp_chars)
	{	my $end = $begin + $exp_chars;

		if($self->_is_good_end($end))
		{	$file->seek($end, 0);
			return ($begin, $end, $exp_chars, $exp_lines);
		}
	}

	my ($end, $lines) = $self->_readStrippedLines($exp_chars, $exp_lines);
	my $chars = sum(map length, @$lines);
	($begin, $end, $chars, scalar @$lines);
}


sub openFile(%)
{	my ($self, %args) = @_;

	#XXX IO::File is hard to remove because of the mode to be translated
	my $fh = $self->{MBPP_file} = $args{file} ||
		IO::File->new($self->filename, $args{mode} || $self->openMode)
		or return;

	$fh->binmode(':raw')
		if $fh->can('binmode') || $fh->can('BINMODE');

	$self->resetSeparators;
	$self;
}


sub closeFile()
{	my $self = shift;
	$self->resetSeparators;

	my $file = delete $self->{MBPP_file} or return;
	$file->close;
	$self;
}


sub takeFileInfo()
{	my $self = shift;
	@$self{ qw/MBPP_size MBPP_mtime/ } = (stat $self->filename)[7,9];
}

#--------------------

#--------------------

sub DESTROY
{	my $self = shift;
	$self->stop;
	$self->SUPER::DESTROY;
}

1;
