package IO::ReadPreProcess;

# The idea is to provide an 'intelligent' bottom end read function for scripts.
# Read lines, process .if/.else/.fi, do .include .let .print - and more.
# It provides IO::Handle-ish functions to slot in easily to most scripts.

# Author: Alain D D Williams <addw@phcomp.co.uk> March 2015, 2016, 2017 Copyright (C) the author.
# SCCS: @(#)ReadPreProcess.pm	1.14 08/15/17 23:19:49

use 5.006;
use strict;
use warnings;
#use Data::Dumper;
use IO::File;
use IO::Pipe;

our $errstr; # Error string

use Math::Expression;

our $VERSION = 0.85;

# Control directive recognised by getline():
my %ctlDirectives = map { $_ => 1 } qw/ break case close continue do done echo else elseif elsif endswitch error eval exit
    fi for if include last let local next noop out print read return set sub switch test unless until while /;

# Directives that can be used in a condition:
my %condDirectives = map { $_ => 1 } qw/ include read test /;

# Need to test for this ... all except first line
my %forbidden = map { $_ => 1 } qw/ function sub /;

# Block pairs: start & ends
my %blkPairs = qw/ sub done while done  until done  for done  if fi  unless fi /;
my %endings = map { $_ => 1 } qw/ done fi /;
my %loops = map { $_ => 1 } qw/ while until for /;
my %makeExpr = map { $_ => 1 } qw/ let if unless elsif elseif while until for /;
my %options = map { $_ => 1 } qw/ trace /;

# Math variables (others see POD below):
# _FileNames - array of open file names
# _LineNumbers  - array of open file names
# _IncludeDepth - how many files open
# _FileName _LineNumber - current ones
# The arrays are to allow the generation of a traceback.

# Properties not described in new
# Information about the current file is kept as references so that it can be pushed down a stack (think: .include) and popped when it is closed.
#
# Lines contains refs else we would need to update before pushing
sub new
{
    my $class = shift;
    my $self = bless {
	FrameStk =>	[],	# Frames
	Frame =>	undef,	# Reference to current frame (last in FrameStk)

	subs =>		{},	# Keys are known sub
	Streams =>	{},	# Input streams

	out =>		"",	# Name of current output stream, empty string is return line to program

	# Public properties:
	MaxLoopCount =>	50,	# Max times that a loop can go round
	Raw =>		0,	# Return input as it is seen
	PipeOK =>	0,	# True if allowed to open a pipe
	Trim =>		1,	# Trim input lines
	OnError =>	'warn',	# Can set to: warn, die, ''
	OutStreams =>	{},	# Key: name, value: Stream

	Place =>	'??',	# Last read location: current file/line#

	DirStart =>	'.',	# Directive start sequence
	TopIsFd =>	0,	# First file pre-opened, ie Fd passed to open()
	Error =>	0,	# Set true on error, functions then just return undef

        trace =>	0,	# 1 trace directives, 2 trace generated input
	@_
    }, $class;

    # These output streams are given for free:
    $self->{OutStreams}->{STDOUT} = *STDOUT{IO} unless( defined($self->{OutStreams}->{STDOUT}));
    $self->{OutStreams}->{STDERR} = *STDERR{IO} unless( defined($self->{OutStreams}->{STDERR}));

    # Produce an escaped version of the directive start string. All the RE special prefix with a backslash.
    # This will be used at the start of an RE but we want it taken literally.
    unless(defined($self->{DirStartRE})) {
        $self->{DirStartRE} = $self->{DirStart};
        $self->{DirStartRE} =~ s/([\$.()\[\]*+?\\^|])/\\$1/g;
    }
    # This is not worth it:
    # $self->{dirLineRE} = qr/^($self->{DirStartRE})(\w*)\s*(.*)/;
    # $self->{commentRE} = qr/^$self->{DirStartRE}#/;

    $self->{Math} = new Math::Expression(PermitLoops => 1, EnablePrintf => 1)
	unless(defined $self->{Math});

    unless($self->{Math}->{VarHash}->{_Initialised}) {
        $self->{Math}->ParseToScalar('_FileNames := EmptyList; _LineNumbers := EmptyList; _IncludeDepth := 0; _Initialised := 1');
        $self->{Math}->ParseToScalar('_ARGS := (); _ := _EOF := 0');
        $self->{Math}->ParseToScalar('_CountGen := _CountSkip := _CountDirect := _CountFrames := _CountOpen := 0');
    }

    # We do some things a lot - compile them, that is the expensive part:
    my %math = (
    	SetLineMath => '_LineNumbers[-1] := _LineNumber',
        m_openFrame => 'push(_FileNames, _FileName); push(_LineNumbers, _LineNumber); ++_IncludeDepth',
        m_closeFrame => 'pop(_FileNames); pop(_LineNumbers); --_IncludeDepth; _FileName := ""; _LineNumber := 0; if(count(_FileNames)){_FileName := _FileNames[-1]; _LineNumber := _LineNumbers[-1]}',
    );

    while (my($p, $e) = each %math) {
        $self->{$p} = $self->{Math}->Parse($e);
    }

    # Take some out - cause problems if there since we try to set them again
    my %opts;
    for (qw/ Fd File /) {
        if(defined($self->{$_})) {
            $opts{$_} = $self->{$_};
            delete $self->{$_};
        }
    }

    # Attempt to open the file if passed:
    if(defined($opts{File})) {
        if(defined($opts{Fd})) {
            # Already open, note name, push to include stack:
            $self->openFrame(binmode => '', %opts, Name => $opts{File}, LineNumber => 0, Generate => 1, ReturnFrom => 1);
        } else {
            return undef unless($self->open(binmode => '', %opts));
        }
    }

    $self
}

# Open a file. Args:
# * File - a name - mandatory
# * Fd   - a file handle that it is already open on - optional
# Return $self on OK, undef on error
# Pushes the current file on a stack that allows restore by close()
sub open
{
    my $self = shift;
    my %args = @_;

    return $self->SetError('open() must be given File argument', 1)
        if( !defined $args{File});

    # But elsewhere File is called Name - which could be a sub name
    $args{Name} = $args{File};
    delete $args{File};

    # Get it open on $self->{Fd}
    my $Fd;
    if( !defined $args{Fd}) {
        return undef unless($Fd = $self->openFile($args{Name}));
    } else {
        # Use already opened Fd
        $Fd = $args{Fd};
        $self->{TopIsFd} = 1;
    }

    $self->openFrame(%args, Fd => $Fd, LineNumber => 0, Generate => 1, ReturnFrom => 1);
}

# Open a file, apply any binmode, return FD
sub openFile
{
    my ($self, $name) = @_;
    my $Fd;

    return $self->SetError("Open of file '$name' failed: $! at $self->{Place}")
        unless($Fd = IO::File->new($name, 'r'));

    $self->{Math}->{VarHash}->{_CountOpen}->[0]++;

    $Fd->binmode($self->{Frame}->{binmode}) if($self->{Frame}->{binmode});

    $Fd
}

# Internal routine.
# Assign the new values and push onto their own stack so that, after a later open()
# it can be popped by a close() of that later file.
sub openFrame
{
    my $self = shift;
    my %args = @_;
    my $vh = $self->{Math}->{VarHash};

    # Create the new frame:
    my %f = ( PushedInput => [], @_ );

    # Create var _ARGS if argument Args:
    if(defined($args{Args})) {
        $f{LocalVars} = {_ARGS => $vh->{_ARGS}};
        delete $vh->{_ARGS};
        $vh->{_ARGS} = $args{Args};
        delete $f{Args};
    }

    # One of Code or Fd must be passed
    # Must have the following, if not set copy from enclosing frame:
    for my $p (qw/ Code CodeLine Name LineNumber Fd Generate binmode /) {

        $f{$p} = $args{$p} if(defined($args{$p}));

        if(defined($self->{Frame}) && defined($self->{Frame}->{$p})) {
            $f{$p} = $self->{Frame}->{$p} unless(defined($f{$p}));
        }
    }

    $f{FrameStart} = "$f{Name}:$f{LineNumber}";

    push(@{$self->{FrameStk}}, \%f);
    $self->{Frame} = \%f;

    $vh->{_CountFrames}->[0]++;
    $vh->{_LineNumber}->[0] = $f{LineNumber};
    $vh->{_FileName}->[0] = $f{Name};
    $self->{Math}->EvalToScalar($self->{m_openFrame});


    $self; # success
}

# Close a file - this might mean closeing more than 1 frame
# An important block is a (.include) file.
# Check $self->{Fd} for there being an open file.
# Return false on error
sub close
{
    my $self = shift;

    # Unwind until we find a ReturnFrom:
    my $rf;
    do {
        $rf = $self->{Frame}->{ReturnFrom};
        return undef
            unless($self->closeFrame);
    } until($rf);

    $self
}

# Closes the current frame, pops back the previous one - if there was one
sub closeFrame
{
    my $self = shift;

    return $self->SetError("Cannot close when there is not a frame open", 1)
        unless(defined $self->{Frame}->{Code} or defined $self->{Frame}->{Fd});

    # If error: this will be an OS level error
    return $self->SetError("IO::File I/O error: $!")
        if($self->error);

    # Don't close - we don't want to close STDIN, could cause problems
    # Rely on the IO::File object for files that we have opened ourselves being unreferenced and thus closed.
    # $self->{Fd}->close;

    # Pop back the previous state/file - if there was one
    # Pop the description/state for the file just closed and assign
    # state for the file just revealed - what is now at the top of the stack:

    # Pop any local vars:
    if($self->{Frame}->{LocalVars}) {
        my $alist = $self->{Frame}->{LocalVars};
        my $vh = $self->{Math}->{VarHash};
	while (my ($k, undef) = each %$alist) {
            delete($vh->{$k});
            $vh->{$k} = $alist->{$k} if(defined($alist->{$k}));
        }
    }


    my $old = pop(@{$self->{FrameStk}});
    $self->{Frame} = $self->{FrameStk}->[-1];

    $self->{Frame}->{CodeLine} = $old->{CodeLine} if($self->{Frame}->{Code} && $old->{CpMove});

    # Get arith variables in sync
    $self->{Math}->EvalToScalar($self->{m_closeFrame});

    $self
}

# This package is intended to read text files - so straight binmode is prob not wanted.
# But binmode is also used to allow different encoding - eg :utf8
# Return true on success, on error undef with error in $!
# Record the mode in the frame, inherited by child frames
sub binmode
{
    my ($self, $mode) = @_;

    return $self->SetError("binmode: a file has not been opened", 1) unless $self->{Frame}->{Fd};

    $self->{Frame}->{binmode} = $mode;

    $self->{Frame}->{Fd}->binmode($mode)	# Pass the call straight down
        unless(ref $self->{Frame}->{Fd} eq 'ARRAY');
}

# Return 1 if the next read will return EOF or the file is not open:
sub eof
{
    my $self = shift;
    return 1 unless($self->{Fd});
    return !@{$self->{Fd}} if(ref $self->{Fd} eq 'ARRAY');
    $self->{Fd}->eof;
}

# Get the name of the file to open
# Args:
# * name
# * just return undef if cannot open, don't print error - optional
# First process escapes
# If it starts '$', the next word is a variable, use the value(s) like $PATH - search
# Else resolve
sub ResolveFilename
{
    my ($self, $name, $noerr) = @_;

    # If it starts '$'
    if(substr($name, 0, 1) eq '$') {
        return $self->SetError("Bad syntax include file name: '$name' at $self->{Place}", 1)
            unless($name =~ m:^\$(\w+)(/.+)$:i);
        my ($var, $rest) = ($1, $2);

        my ($pt, @val);
        return $self->SetError("Bad expression in include: '$name' at $self->{Place}", 1)
            unless(($pt = $self->{Math}->Parse($var)) && (@val = $self->{Math}->Eval($pt)));

	# Search down path:
        for my $pref (@val) {
            my $fp = $self->GetPath("$pref$rest");
            return undef unless $fp;
            return $fp # Grab it if it exists
                if(-e $fp);
        }

        return undef if($noerr);

        return $self->SetError("Cannot find a file in search '$name'. $var='@val' at $self->{Place}", 1)
    }

    # Plain file name:
    return $self->GetPath($name);
}

# If it is absolute (starts '/'): accept
# If it starts '#' it is relative to the process's CWD, remove '#' & accept
# The rest are relative to the current file name: prepend any directory name
# Don't try to canonicalise a/b/../c to a/c - think symlinks.
sub GetPath
{
    my ($self, $name) = @_;

    # Absolute path:
    return $name if index($name, '/') == 0;

    # Relative to our CWD:
    if(substr($name, 0, 1) eq '#') {
        $name = substr($name, 1);    # Remove #
        $name = substr($name, 1)     # Remove / after #
            while(substr($name, 0, 1) eq '/');
        return $name;
    }

    # Everything else is relative to the current file

    # Cannot have a relative name if the current file was passed as Fd
    return $self->SetError("Cannot include file relative to file descriptor. '$name' at $self->{Place}", 1)
        if($self->{TopIsFd} && @{$self->{FrameStk}} == 1);
    # **** This refers to self->file - on stack & called Name

    # Find the last opened file name
    my $last;
    return undef
        unless($last = $self->GetLastFileName);

    # Note RE ensures that $currDir is '' if $last does not contain '/':
    my ($currDir) = $last =~ m:^(.*?/?)[^/]+$:;

    $currDir . $name
}

# Get the name of the last file opened, dig down the stack
sub GetLastFileName
{
    my ($self) = @_;

    my $frames = @{$self->{FrameStk}};

    while(--$frames >= 0) {
        return $self->{FrameStk}->[$frames]->{Name} if(exists($self->{FrameStk}->[$frames]->{Fd}));
    }

    return $self->SetError("Cannot find previous file name at $self->{Place}", 1);
}

# Line parsed for escapes: \0 \e \v{varname}. varname is: /\w+/i
# Arg is a string that is processed & returned
sub ProcEscapes
{
    my ($self, $arg) = @_;

    my $ret = '';

    while($arg =~ s/^([^\\]*)\\(.)//) {
        $ret .= $1;
        if($2 eq '0') {
            ; # nothing
        } elsif($2 eq 'e') {
            $ret .= '\\';
        } elsif($2 eq 'v') {
            return $self->SetError("Invalid escape \\v$arg at $self->{Place}", 1)
                unless($arg =~ s/^{(\w+|\w+\[\w+\])}//i);
            my $vn = $1;
            my $vv = $self->{Math}->ParseToScalar($1);
            return $self->SetError("Invalid variable in \\v{$1} at $self->{Place}", 1)
                unless(defined($vv));
            $ret .= $vv;
        } else {
            return $self->SetError("Invalid escape \\$2 at $self->{Place}", 1);
        }
    }
    return $self->SetError("Trailing \\ on line at $self->{Place}", 1)
        if($arg =~ /\\/);

    $ret . $arg;
}

# Split the argument string on spaces into an array of strings.
# If a portion starts with a quote, it may contain a space
# If $doEsc each result is processed by ProcEscapes()
# Return the result or false
sub SplitArgs
{
    my ($self, $arg, $doEsc) = @_;
    my @args = ();

    $arg =~ s/^\s*//;
    while($arg ne '') {
        my $c1 = substr($arg, 0, 1);
        if($c1 eq '"' or $c1 eq "'") {
            # Extract the string delimited by quotes
            return $self->SetError("Bad quoted string at $self->{Place}", 1)
                unless($arg =~ s/^(["'])((\\{2})*|(.*?[^\\](\\{2})*))\1\s*//);
            my $m = $2;
            $m =~ s/\\([\\'"])/$1/g;    # Remove embedded escapes, eg: \" => "
            push(@args, $m);
        } else {
            $arg =~ s/^(\S+)\s*//;
            push(@args, $1);
        }

    }

    @args = map { $self->ProcEscapes($_) } @args if($doEsc);

    @args
}

# Read & store a sub or function to hash in $self->{subs}->{Name}
# Don't start a frame since we are just reading this in
# Return true if OK
sub readSub
{
    my ($self, $direc, $InLine, $arg) = @_;

# Check that $self->{Frame}->{Fd} is an open file

    my $code = { };

    my @args;

    return $self->SetError("Missing $direc name at $self->{Place}", 1) unless($arg ne '');

    # Also need to check that name & args are IDs
    return undef unless(@args = $self->SplitArgs($arg, 0));

    # First is the name:
    $code->{Name} = shift @args;
    return $self->SetError("Error: bad sub name '$code->{Name}' at $self->{Place}")
        unless($code->{Name} =~ /^\w+$/);

    return $self->SetError("Error: Redefinition of sub '$code->{Name}' at $self->{Place}")
        if(exists($self->{subs}->{$code->{Name}}));

    $self->{subs}->{$code->{Name}} = $code;
    $code->{ArgNames} = @args;

    # sub args can have names:
    $code->{ArgNames} = \@args if(@args);

    $code->{Block} = $direc;    # Info only

    $self->ReadBlock($InLine, $code);

    $code->{LastLine}--;	# Remove .done
    $code->{FirstLine}++;	# Remove .sub

    1
}

# $direct is while/until/for
# $arg is loop condition/rest-of-line
# May start: -innn to specify max iterations
# **** THINKS ****
# Loops are found in 2 ways:
# (1) Reading from a {Fd} - ie in getline()
# (2) When in a sub or an enclosing loop
# We always buffer a loop, so the only difference is where/how it is found
# The purpose of this sub is for case (1), need to initiate a buffer creation
# If (1) read into a buffer/code and return a ref to the code
# If (2) set up $code and return that
sub ReadLoop
{
    my ($self, $direc, $InLine, $arg) = @_;

    my $frame = $self->{Frame};

    my $code = { Block => $direc };

    $self->ReadBlock($InLine, $code);

    $code
}

# Read a block (sub or loop) to arg \%code
# If this finds a loop - note it as within what we read -- works for sub & nested loops
# $InLine is the line just read
sub ReadBlock
{
    my ($self, $InLine, $code) = @_;

    # Record where this was found:
    my $h={ FileName => $self->{Frame}->{Name}, FileLine => $self->{Frame}->{LineNumber}};
    while (my($k,$v)= (each %$h)){
        $code->{$k} = $v;
    }

    $code->{start} = "$code->{FileName}:$code->{FileLine}";

    my $started = "started $code->{start}";
    my @blocks;

    my $frame = $self->{Frame};
    my $lineNo;    # when reading existing array

    $code->{FirstLine} = 0;
    $code->{Lines} = [];

    my $lineCnt = 0;

    while(1) {

        my $line = { Txt => $InLine, '#' => $. };

	# Quick return if it cannot be a directive line - or one that we recognise
        # If not generating - skip to next
        unless($InLine =~ /^($self->{DirStartRE})(\w+)\s*(.*)/ and
              (defined($ctlDirectives{$2}) or defined($self->{subs}->{$2}))) {
            push @{$code->{Lines}}, $line unless(defined $frame->{Code});
            $lineCnt++;
         } else {

            my $leadin = $1; # String that identified the directive
            my $dir = $2;    # Directive
            my $arg = $3;    # Its argument

            if(exists $loops{$dir}) {
		# Loop buster:
		my $max = $self->{MaxLoopCount};
		$max = $1 if($arg =~ s/^-i\s*(\d+)\s*//);
                $line->{LoopMax} = $max;

                # Get loop condition:
		return $self->SetError("Missing $dir condition at $self->{Place}", 1) unless($arg ne '');
                my $cond = $arg;
                $line->{Not} = $dir eq 'until';

                if($dir eq 'for') {
                    # Break out, 3 expressions, preserve trailing ones
                    my @e = split /;;/, $arg, 4;
                    return $self->SetError("Bad for loop, expecting: 'init ;; condition ;; expression' at $self->{Place}", 1)
                        unless(@e == 3);

                    $line->{Init} = $e[0] if($e[0] =~ /\S/);

                    $e[1] = '1' unless($e[1] =~ /\S/);    # Set default condition - true
                    $cond = $e[1];

                    if($e[2] =~ /\S/) {
                        return $self->SetError("$dir for expression '$e[2]' fails to compile at $self->{Place}", 1)
                            unless($line->{For3} = $self->{Math}->Parse($e[2]));
                    }
                }

                # Compile the condition below:
                $cond =~ s/^\s*//;
                $arg = $cond;
            }
            if(exists $makeExpr{$dir}) {
                # Precompile expression unless it is a .sub (starts '.'):
                if(substr($arg, 0, length($self->{DirStart})) eq $self->{DirStart}) {
                    $line->{SubCond} = $arg;
                } else {
		    return $self->SetError("$dir condition/expression fails to compile '$arg' at $self->{Place}", 1)
                        unless($arg =~ /\S/ and ($line->{Expr} = $self->{Math}->Parse($arg)));
                }
            }

            if(defined($blkPairs{$dir})) {
                # Start of block
                push @blocks, {type => $dir, LoopStart => @{$code->{Lines}}+0 };
            } elsif(defined($blkPairs{$blocks[-1]->{type}}) and $blkPairs{$blocks[-1]->{type}} eq $dir) {
                # End of block

                my $blk = pop @blocks;

                # Consistency check
                return $self->SetError("$leadin$dir followed by '$1' but match is '$blk->{type}' at $self->{Place}", 1)
                    if($arg =~ /(\S+)/ and $blk->{type} ne $1);

                # If loop add LoopStart/LoopEnd
                if(exists $loops{$blk->{type}}) {
                    my $start = $blk->{LoopStart};
                    my $topl = $code->{Lines}->[$start];
                    $topl->{LoopStart} = $start;
                    $topl->{LoopEnd} = @{$code->{Lines}}+1;
                }

            } elsif(defined($endings{$dir})) {
                return $self->SetError("Unexpected $leadin$dir at $self->{Place} in $code->{Block} $started", 1)
            }

            # Buffer in array
            push @{$code->{Lines}}, $line;
            $lineCnt++;

            last if($dir eq 'done' and @blocks == 0);
        }

        # Next line
        do {
            return $self->SetError("Unexpected EOF at $self->{Place} while reading $code->{Block} $started", 1)
        } unless($InLine = (ref $self->{Frame}->{Fd} eq 'ARRAY') ? shift @{$self->{Frame}->{Fd}} : $self->{Frame}->{Fd}->getline);

        $self->{Place} = "line $. of $self->{Frame}->{Name}";
    }

    $code->{LastLine} = $code->{FirstLine} + $lineCnt - 1;
}

# Run a sub: open a frame, process arguments
sub RunSub
{
    my ($self, $dir, $arg) = @_;
    my @args = $self->SplitArgs($arg, 1);
    my $code = $self->{subs}->{$dir}; # Code read earlier

    # New frame to run the sub
    $self->openFrame(Code => $code, Block => $dir, Args => [@args],
        LineNumber => $code->{FileLine}, Name => $code->{FileName},
        CodeLine => $code->{FirstLine}, ReturnFrom => 1);
    my $frame = $self->{Frame};
    delete $frame->{Fd};

    # If argument names are supplied, set as local vars:
    if($code->{ArgNames} && @{$code->{ArgNames}}) {
        my $vh = $self->{Math}->{VarHash};
        foreach my $vname (@{$code->{ArgNames}}) {
            my $vval = $vh->{$vname};
            $frame->{LocalVars}->{$vname} = $vval;
            delete($vh->{$vname});

            $vh->{$vname} = [shift @args] if(@args);
        }
    }
}


# Evaluate the condition, return true/false, or undef on error
# This could be a Math expression or a .sub returned value
# BEWARE: This could open a new frame to set up a sub, return to run it and frame.CondReReun
# will make the .if/... return here to see what the .return was.
sub EvalCond
{
    my ($self, $replay, $dir, $place, $arg) = @_;
    my ($iftree, $true, $esc);

    # Is the condition a sub-call/directive ?
    if(($esc = exists($replay->{SubCond})) or
       (substr($arg, 0, length($self->{DirStart})) eq $self->{DirStart} and $arg =~ /^$self->{DirStartRE}(\w+)\s*(.*)/)) {

	# If buffered code (loop/sub) get the arg string and break to subroutine and its arguments:
        ($arg = $replay->{SubCond}) =~ /^$self->{DirStartRE}(\w+)\s*(.*)/ if($esc);

        my ($sub, $args) = ($1, $2);

        my $intDir = 0; # If true: $sub is allowed internal directive
        unless( exists $self->{subs}->{$sub}) {
            return $self->SetError("Unknown sub '$sub' in $dir at $place", 1)
                unless exists($condDirectives{$sub});
            $intDir = 1;
        }

        unless($self->{Frame}->{CondReRun}) {
            # First time through:
            # Set up the sub, return to main loop to run it
            $self->{Frame}->{CondReRun} = 10;

	    # Cause the .if/.while/... to be run again.
            # If buffered back up a line, else push back to input for this frame
            if($esc) {
                $self->{Frame}->{CodeLine}--;
            } else {
		push @{$self->{Frame}->{PushedInput}}, "$self->{DirStart}$dir $arg";
            }

	    if($intDir) {
                # Create a frame with just 1 line to run internal command
                $self->openFrame(CodeLine => 0, Code => {Lines => [{ Txt => $arg, '#' => 1 }], LastLine => 0 } ); 
            } else {
                # Run the sub
                $self->RunSub($sub, $args);
            }

            $self->{Frame}->{CondReRun} = 1;	# Cause return here
            $self->{Frame}->{intDir} = $intDir;	# Directive or sub ?
            $self->{Frame}->{Generate} = 1;	# Cause sub/directive to run

            return 0;

        } else {
            # 2nd time:
            # Get the command 'exit' code & tidy up:

            delete $self->{Frame}->{CondReRun} unless($esc);
            $true = $self->{Math}->{VarHash}->{_}->[-1];
            $self->closeFrame  # Close internal command frame
                if($self->{Frame}->{intDir});

	    delete $self->{Frame}->{CondReRun} if($esc);
        }

    } else {
        # It is a conventional expression
        if($replay and exists $replay->{Expr}) {
            $iftree = $replay->{Expr};
        } else {
            return $self->SetError("Bad $self->{DirStart}$dir expression $place in $self->{Frame}->{Name} '$arg'", 1)
                unless($iftree = $self->{Math}->Parse($arg));
        }

        $true = $self->{Math}->EvalToScalar($iftree);
    }

    $true = ! $true if($replay->{Not});

    $true
}



# Return true on error
sub error
{
    my $self = shift;

    $self->{Error} or (defined($self->{Frame}) and $self->{Frame}->{Fd} and
        (ref $self->{Frame}->{Fd} ne 'ARRAY') and $self->{Frame}->{Fd}->error)
}

# As IO::Handle, clear recent error
sub clearerr
{
    my $self = shift;

    $self->{Error} = 0;
    return 0 if(ref $self->{Frame}->{Fd} eq 'ARRAY');
    return -1 unless $self->{Fd} && $self->{Fd}->opened;

    $self->{Fd}->clearerr
}

# Record the error at $errstr and maybe $!, note that there has been an error, return undef
# Arg is description of the error
# Optional extra arg. If true set $! to EINVAL - use this eg where file format error
sub SetError
{
    my ($self, $errm, $einval) = @_;

    $self->{Error} = 1;
    $errstr = $errm;

    die  "$errm\n" if($self->{OnError} eq 'die' );
    warn "$errm\n" if($self->{OnError} eq 'warn');

    if($einval) {
        use Errno;
        $! = &Errno::EINVAL;
    }

    return undef
}

# Put line(s) to be read as input
sub putline {
    my $self = shift;

    push @{$self->{Frame}->{PushedInput}}, @_
}

# Wrapper for _getline()
# The point is that we might be outputting to a stream rather than returning
# a line of input to the program.
sub getline {
    my $self = shift;

    while(1) {
        my $l = $self->_getline;

        return $l if($self->{out} eq "");    # No stream set, return to caller

        $self->writeToStream($self->{out}, $l);
    }
}

# Write the argument line $l to the output $stream
# It can be an IO::FILE, array or subroutine
sub writeToStream {
    my ($self, $stream, $l) = @_;

    my $strm = $self->{OutStreams}->{$stream};

    if( !defined($strm)) {
        # This could result in many messages
        $self->SetError("Output stream unknown: '$stream'");
        return;
    }
    if(ref $strm eq 'IO::File' or ref $strm eq 'IO::Handle') {
        print $strm $l;
        return;
    }
    if(ref $strm eq 'CODE') {
        &$strm($l);
        return;
    }
    if(ref $strm eq 'ARRAY') {
        push @$strm, $l;
        return;
    }
    # Should not get here
    $self->SetError("At $self->{Place}: Output stream '$stream' is not an IO::File or IO::Handle or array or subroutine, but is: " . ref $strm);
}

# Called when every line is read
# One problem with this is that it cannot store anything in a local variable
# as it returns once it finds a line that it cannot process itself.
# Store in the object.
# Can't store 'static' since there may be different files open for different purposes.
# getline() getlines() close() are deliberately compatible with IO::Handle. new() is not, it is more complicated.
sub _getline {
    my $self = shift;

    return $self->SetError("A file has not been opened at $self->{Place}", 1)
        unless defined $self->{Frame}->{Code} or defined $self->{Frame}->{Fd};

    my $doneDone = 0;    # Last directive was .done
    my $vh = $self->{Math}->{VarHash};

    while(1) {

        return undef
            if $self->{Error};

        return undef
            unless(@{$self->{FrameStk}});

        my $lineno;
        my $frame = $self->{Frame};
        my $replay;

	if(defined ($_ = pop @{$frame->{PushedInput}})) {
            # Line pushed back to input
            $lineno = $frame->{LineNumber};
        } elsif(exists $frame->{Code}) {
            # Loop or sub
            # End of code ?
            if($frame->{CodeLine} > $frame->{Code}->{LastLine}) {
                $self->closeFrame;
                next;
            }

            $replay = $frame->{Code}{Lines}->[$frame->{CodeLine}++];
            $_ = $replay->{Txt};
            $lineno = $replay->{'#'};
        } else {
            # From file or in-memory array
            $_ = (ref $frame->{Fd} ne 'ARRAY') ? $frame->{Fd}->getline : shift @{$frame->{Fd}};

            # EOF:
            unless($_) {

                # EOF. Close the file. This may pop another one if there are multiple open files (.include)
                return undef
                    unless($self->closeFrame);

                next    # There is still a frame to look at
                    if($self->{Frame});

                # EOF. Return undef
                return undef;
            }

            if($self->{Raw}) {
                $vh->{_CountGen}->[0]++;
                return $_;
            }

            $lineno = $.;
            chomp;
        }

        # Store the line number in a silly number of places:
        $frame->{LineNumber} = $lineno;
        $vh->{'_LineNumber'} = [$lineno]; # do directly for speed
	$self->{Math}->Eval($self->{SetLineMath});

	# Something that knows where the current line is:
	my $place = "line $lineno of $frame->{Name}";
	$self->{Place} = $place;

EVAL_RESTART:	# Restart parsing here after a .eval

        # Ignore comments
        if(/^$self->{DirStartRE}#/) {
            warn "$place: $_\n" if($self->{trace});
	    next;
        }

        s/\s*$// if($self->{Trim});

	# Quick return if it cannot be a directive line - or one that we recognise
        # If not generating - skip to next
        unless(/^($self->{DirStartRE})(\w+)\s*(.*)/ and
              (defined($ctlDirectives{$2}) or defined($self->{subs}->{$2}))) {
	    unless($frame->{Generate}) {
                $vh->{_CountSkip}->[0]++;
                next;
            }

            warn "$place: $_\n" if($self->{trace} > 1);

	    $vh->{_CountGen}->[0]++;
            return $_ . $/;	# Put the line terminator back on
        }

	# Must be a directive:
        my $leadin = $1; # String that identified the directive
        my $dir = $2;    # Directive
        my $arg = $3;    # Its argument

        warn "$place: $_\n" if($self->{trace} and $frame->{Generate});

        $vh->{_CountDirect}->[0]++;

        # Process .if/.else/.fi .unless
        # Because we can have nested if/... we need a stack of how the conditions evaluated
        if($dir eq 'if' or $dir eq 'unless') {
            # start a new frame with .if
            # Unless we are here a 2nd time as evaluating: .if .subroutine; in which case the frame is already open
            $self->openFrame( Type => $dir, Else => 0, CpMove => 1) unless($frame->{CondReRun});
            $frame = $self->{Frame};

            $frame->{ParentGenerate} = $frame->{DidGenerate} = $frame->{Generate};

            # Don't evaluate the .if if we are not generating, the expression could have side effects
            # Don't compile it either - faster; but means that we only see errors if we try
            if($frame->{Generate}) {
                $replay->{Not} = $dir eq 'unless';

		my $gen = $self->EvalCond($replay, $dir, $place, $arg);
                return $gen unless defined $gen;
                $frame = $self->{Frame};
                next if($frame->{CondReRun});
                $frame->{DidGenerate} = $frame->{Generate} = $gen;
            }

            next;
        }
        if($dir eq 'elseif' or $dir eq 'elsif') {
            return $self->SetError("${leadin}$dir but an ${leadin}if/${leadin}unless has not been seen, at $place", 1)
                unless($frame->{Type} eq 'if' or $frame->{Type} eq 'unless');
            return $self->SetError("Cannot have ${leadin}$dir at $place to ${leadin}if after ${leadin}else at line $frame->{Else}", 1)
                if($frame->{Else});

	    # Don't record that we have seen it, related errors always refer to the .if

            # We do the test only if the .if was false - exactly the same as .else below
            # Do a test if the .if was false and all parents (enclosing .ifs) are true, set the truth of Generate property.

            if($frame->{ParentGenerate} and !$frame->{DidGenerate}) {
 		my $gen = $self->EvalCond($replay, $dir, $place, $arg);
                $frame = $self->{Frame};
                return $gen unless defined $gen;
                $frame = $self->{Frame};

                next if($frame->{CondReRun});
                $frame->{DidGenerate} = $frame->{Generate} = $gen;
            } else {
               $frame->{Generate} = 0; # Which it might already be
            }

            next;
        }
        if($dir eq 'else') {

            return $self->SetError("${leadin}else but an ${leadin}if has not been seen, at $place", 1)
                unless($frame->{Type} eq 'if' or $frame->{Type} eq 'unless');
            return $self->SetError("Another ${leadin}else at $place to ${leadin}if starting line $frame->{FrameStart}, first .else at line $frame->{Else}", 1)
                if($frame->{Else});

	    $frame->{Else} = $lineno;    # Note where the .else was

            if($frame->{DidGenerate}) {
                $frame->{Generate} = 0;
            } else {
                $frame->{Generate} = $frame->{ParentGenerate};
            }

            next;
        }
        if($dir eq 'fi') {
            return $self->SetError("${leadin}fi but an ${leadin}if has not been seen, $place", 1)
                unless($frame->{Type} eq 'if' or $frame->{Type} eq 'unless');

	    $self->closeFrame;
            next;
        }

	# None of the rest unless generating:
        next unless $frame->{Generate};

        if($dir eq 'let') {
            my $iftree;
            if($replay and exists $replay->{Expr}) {
                $iftree = $replay->{Expr};
            } else {
                return $self->SetError("Bad ${leadin}let expression $place '$arg'", 1)
                    unless($iftree = $self->{Math}->Parse($arg));
            }
            $self->{Math}->EvalToScalar($iftree);
            # Don't care what the result is

            next;
        }

        # Return a line parsed for escapes
        if($dir eq 'echo') {
            $vh->{_CountGen}->[0]++;
            return $self->ProcEscapes($arg) . $/;
        }

        # Start of loop
        if(exists $loops{$dir}) { # 'while' 'until' 'for'
            # Create a new frame with an indicator that this is a loop frame
            # With 'for' execute the initialisation expression and record the loop expression
            # For/while/until all look the same (until has a truth invert flag)
            # On 'EOF' of the recorded array, detect that it is a loop frame:
            # - execute any loop expression
            # - evaluate the loop condition; closeFrame on false; reset CodeLine on true

            my $code;
            my @args = $self->SplitArgs($arg, 1);
            my $oframe = $frame;

	    # First time:
            unless($doneDone or $frame->{CondReRun}) {
                $self->openFrame(Block => $dir);
                $frame = $self->{Frame};
            }

            # If reading from a stream grab the loop to an array:
            unless(exists $frame->{Code}) {
                return $code unless($code = $self->ReadLoop($dir, $_, $arg));
                $frame->{Code} = $code;
                $frame->{CodeLine} = $code->{FirstLine} + 1;
                delete $frame->{Fd};
            }

            # New loop, initialise it:
            unless($doneDone or $frame->{CondReRun}) {
		$replay = $frame->{Code}{Lines}->[$frame->{CodeLine} - 1];

		$frame->{LoopMax} = $replay->{LoopMax};
                $frame->{LoopCnt} = 0;
                $frame->{LoopStart} = $replay->{LoopStart};
                $frame->{LoopEnd} = $replay->{LoopEnd};

		# Set CodeLine to Line after end - in parent frame (which might be from stream and ignore it)
		$oframe->{CodeLine} = $frame->{LoopEnd};

                # Evaluate any loop initialisation
                $self->{Math}->ParseToScalar($replay->{Init}) if(exists $replay->{Init});
            }
            $doneDone = 0;

	    # Beware: might be here twice
	    unless($frame->{CondReRun}) {
	    	# Trap run away loops:
            	return $self->SetError("Maximum iterations ($frame->{LoopMax}) exceeded at $frame->{FrameStart}", 1)
                    if($frame->{LoopMax} && ++$frame->{LoopCnt} > $frame->{LoopMax});

            	# evaluation loop expression (not on first time)
	    	$self->{Math}->EvalToScalar($replay->{For3}) if(exists $replay->{For3} and $frame->{LoopCnt} != 1);
            }

            # Evaluate the loop condition - if true keep looping
            my $bool = $self->EvalCond($replay, $dir, $place, $arg);
            next if($frame->{CondReRun});
            $self->closeFrame if( !$bool);

            next;
        }

        # Should only be seen at end of loop - which is buffered
        if($dir eq 'done') {
            return $self->SetError("Unexpected '$leadin$dir' at $place", 1)
                unless(exists $frame->{LoopMax});

            # Next to run is loop start:
            $frame->{CodeLine} = $frame->{LoopStart};
            $doneDone = 1;
            next;
        }

        if($dir eq 'break' or $dir eq 'last') {
            my $loops = 1;
            $loops = $1 if($arg =~ /\s*(\d+)/);

            # Unwind until we find a LoopEnd, then close that frame
            my $le;
            do {
                # Can't break out of sub:
                return $self->SetError("'$leadin$dir' too many loops at $place", 1)
                    if(exists $self->{Frame}->{ReturnFrom});

                $le = exists $self->{Frame}->{LoopEnd};
                return undef
                    unless($self->closeFrame);
            } until($le and --$loops <= 0);
            next;
        }

        if($dir eq 'continue' or $dir eq 'next') {
            my $loops = 1;
            $loops = $1 if($arg =~ /\s*(\d+)/);

            # Unwind until we find LoopStart, reset to that
            my $ls;
            while(1) {
                return $self->SetError("'$leadin$dir' too many loops at $place", 1)
                    if(exists $self->{Frame}->{ReturnFrom});

                if(($ls = exists $self->{Frame}->{LoopStart}) && --$loops <= 0) {
                    $self->{Frame}->{CodeLine} = $self->{Frame}->{LoopStart};
                    last;
                }

                return undef
                    unless($self->closeFrame);
            };

	    $doneDone = 1;    # This is like .done
            next;
        }

	# Local variable
        if($dir eq 'local') {
            # Push to previous var hash for this stack frame
            # This will be undone by closeFrame()
            foreach my $vname (split ' ', $arg) {
                my $vval = $vh->{$vname};
                $frame->{LocalVars}->{$vname} = $vval;
                delete($vh->{$vname});
            }
            next;
        }

	# Include another file
        if($dir eq 'include') {
            my (@push, @args, $stream, $fd);
            my $level = 0;

            if($arg =~ s/^-s\s*(\w+)\s*//i) {
                $stream = $1;
                return $self->SetError("Stream '$stream' already open at $place")
                    if(exists($self->{Streams}->{$stream}));
            }

            return undef unless(@args = $self->SplitArgs($arg, 1));
            return $self->SetError("Missing include file at $place") unless(@args);
            my $fn = shift @args;

            # Push the include ?
            if(!defined($stream) and $fn =~ /^-p(\d*)$/) {
                $level = $1 eq '' ? 1 : $1;    # Default 1

                return $self->SetError("Attempt to push too far (" . (scalar @{$self->{FrameStk}}) . " available) at $place")
                    if($level > @{$self->{FrameStk}});
                return $self->SetError("Missing include file at $place") unless(@args);
                $fn = shift @args;
            }

            # Opening a pipe to read from ?
            if(substr($fn, 0, 1) eq '|') {
                return $self->SetError("Not allowed to open pipe at $place")
                    unless($self->{PipeOK});

                # Replace the command if written '|cmd'
                $fn = $fn eq '|' ? shift(@args) : substr($fn, 1);

                $fd = IO::Pipe->new;
                return $self->SetError("Open of pipe '$fn' failed: $! at $place")
                    unless($fd);

                $fd->reader($fn, @args);

                $fn = "| $fn";    # For messages, etc, only

                $vh->{_CountOpen}->[0]++;
            } elsif($fn =~ /^(@\w+)$/i) {
                return $self->SetError("Unknown in-memory stream '$1' at $place")
                    unless(defined($self->{OutStreams}->{$1}));
                $fd = $self->{OutStreams}->{$1};
            } else {
                return undef unless(defined($fn = $self->ResolveFilename($fn)));
                return $self->SetError("Cannot open file '$arg' at $place as $!")
                    unless($fd = $self->openFile($fn));
            }

            # Either store on a named stream or push to a frame
            if(defined($stream)) {
                $self->{Streams}->{$stream} = $fd;
            } else {
                $self->openFrame(Name => $fn, Fd => $fd, Args => [@args], Generate => 1, LineNumber => 0, ReturnFrom => 1);
                delete $self->{Frame}->{Code} if( !$level);  # Back to input from file unless pushed elsewhere
                if($level) {
                    # Insert opened stream/frame down in the stackframes:
                    my $str = pop @{$self->{FrameStk}};
                    splice @{$self->{FrameStk}}, -$level, 0, $str;
                }
            }

            next;
        }

        # Kill the script with optional exit code
        if($dir eq 'exit') {
            my $code = 2;
            if($arg ne '') {
                $code = $self->{Math}->ParseToScalar($arg);
                unless($code =~ /^\d+$/) {
                    print "Exit expression at $place was not numeric: $code\n";
                    $code = 2;
                }
            }
            exit $code;
        }

        # Print a line, -e print to stderr, -o stream write to named stream
        # Line parsed for escapes
        if($dir eq 'print') {
            my $stream = 'STDOUT';
            $stream = 'STDERR' if($arg =~ s/^-e\b\s*//);
            $stream = $1 if($arg =~ s/^-o\s*(@?\w+)\b\s*//i);

            return undef unless(defined($arg = $self->ProcEscapes($arg)));
            $self->writeToStream($stream, "$arg\n");
            next;
        }

        # Set the current output stream
        if($dir eq 'out') {
            if($arg eq "") {
                $self->{out} = "";
            } elsif($arg =~ s/^(-c)?\s*(@\w+)\s*$//i) {
                # Create the memory stream if -c option
                $self->{OutStreams}->{$2} = [] if(defined $1);

                $self->SetError("Output in-memory stream unknown: '$2' at $place")
                    unless(defined $self->{OutStreams}->{$2});
                $self->{out} = $2;
            } elsif($arg =~ s/^(\w+)\s*$//i) {
                $self->SetError("Unknown output stream '$1' at $place")
                    unless(defined($self->{OutStreams}->{$1}));
                $self->{out} = $1;
            } else {
                return $self->SetError("Bad or missing stream name '$arg' at $place");
            }
            next;
        }

        # Close this file, return to the one that .included it - if any
        # This may result in EOF. Check at loop top
        if($dir eq 'return') {
            # Evaluate expression after .return - in context of the .sub
            my $ret = undef;
            $ret = $self->{Math}->ParseToScalar($arg) if($arg =~ /\S/);
            $vh->{_} = [$ret];
            return undef
                unless($self->close);

            next;
        }

        # Eval: rewrite the line and try again
        if($dir eq 'eval') {
            return undef unless($_ = $self->ProcEscapes($arg));
            next if(/^$self->{DirStartRE}#/);
            $place = "Evaled: $place";
            goto EVAL_RESTART;
        }

        # Close a named stream
        if($dir eq 'close') {
            return $self->SetError("Missing option '-n stream' to ${leadin}close at $place", 1)
                unless($arg =~ s/^-s\s*(\w+)\s*//i);

            my $stream = $1;

            return $self->SetError("Unknown input stream '$stream' in ${leadin}read at $place", 1)
                unless(exists($self->{Streams}->{$stream}));

            delete($self->{Streams}->{$stream});    # Close it

            next;
        }

        # Read next line into var
        if($dir eq 'read') {
            my ($stream, $fd, $mem);

            $stream = $1 if($arg =~ s/^-s\s*(\w+)\s+//i);

            # In-memory stream:
            if($arg =~ s/^(@\w+)\s+//i) {
                return $self->SetError("Unknown in-memory stream $1 at $place")
                    unless(defined $self->{OutStreams}->{$1});
                $mem = $1;
            }

            my ($vname) = $arg =~ /^(\w+)/i;
            return $self->SetError("Missing argument to ${leadin}read at $place", 1) unless($vname);

            # Find stream or Fd on stack:
            if(defined($stream)) {
                return $self->SetError("Unknown input stream '$stream' in ${leadin}read at $place", 1)
                    unless($fd = $self->{Streams}->{$stream});
            } else {
                # Find an open file
                my $f = $frame;
                my $i = @{$self->{FrameStk}} - 1;
                until(exists($f->{Fd})) {
                    $f = $self->{FrameStk}->[--$i];
                }
                $fd = $f->{Fd};
            }

            my $eof = 1;
            if($_ = (defined $mem) ? shift @{$self->{OutStreams}->{$mem}} : $fd->getline) {
                chomp;
                $eof = 0;
                s/\s*$// if($self->{Trim});
            } else {
                $_ = '';
            }

            $vh->{$vname} = [$_];
            $vh->{'_EOF'} = [0 + $eof];
            $vh->{'_'}    = [1 - $eof];
            next;
        }

        # No operation
        next if($dir eq 'noop');

        # Subroutine definition
        if($dir eq 'sub') {
            return undef
                unless($self->readSub($dir, $_, $arg));
            next;
        }

        if($dir eq 'test') {
            my %an = ('-f' => 2, '-m' => 2);
            my @args = $self->SplitArgs($arg, 1);
            return $self->SetError("'$leadin$dir' bad or missing argument '$arg' at $place", 1)
                unless(@args and exists($an{$args[0]}) and @args == $an{$args[0]});

            if($args[0] eq '-f') {
                my ($fn, @stat);
                $vh->{_} = [0]; # assume error
                if(($fn = $self->ResolveFilename($args[1], 1)) and (@stat = stat $fn)) {
                    $vh->{_} = [1]; # OK
                    $vh->{_STAT} = [@stat];
                    $vh->{_TestFile} = [$fn];
                }
                next;
            }

            if($args[0] eq '-m') {
                $vh->{_} = [0]; # assume error
                if(defined($self->{OutStreams}->{$args[1]})) {
                    $vh->{_} = [1]; # OK
                    $vh->{_COUNT} = [scalar @{$self->{OutStreams}->{$args[1]}}];
                }
                next;
            }
        }

        if($dir eq 'error') {
            $arg = "Error at $place" if($arg eq '');
            return $self->SetError($arg);
        }

        if($dir eq 'set') {
            return $self->SetError("'$leadin$dir' bad argument '$arg' at $place")
                unless(($arg =~ /^(\w+)=(\d+)/i) and $options{$1});
            $self->{$1} = $2;
            next;
        }

        return $self->SetError("Use of reserved directive '$leadin$dir' at $place", 1)
            if($dir eq 'function' or $dir eq 'do' or $dir eq 'case' or $dir eq 'switch' or $dir eq 'endswitch');

	# User defined sub.
        # At the bottom so cannot redefine an inbuilt directive
        if(exists($self->{subs}->{$dir})) {
            $self->RunSub($dir, $arg);

            next;
        }

        # Should not happen
        return $self->SetError("Unknown directive '$leadin$dir' at $place", 1);
    }
}

# Return the rest of input as an array
sub getlines
{
    my $self = shift;
    my @lines = ();

    return $self->SetError("A file has not been opened", 1)
        unless $self->{Fd};

    return $self->SetError("getlines called in a scalar context", 1)
        unless(wantarray);

    while(my $line = $self->getline) {
        push @lines, $line;
    }

    @lines
}

# Enable the object to be used in the diamond operator:
use overload '<>' => \&getline, fallback => 1;

1;

__END__

=head1 NAME

IO::ReadPreProcess - Macro processing built into IO::File replacement

=head1 SYNOPSIS

    use IO::ReadPreProcess;

    my $fh = new IO::ReadPreProcess(File => './input.file') or
        die "Startup error: $IO::ReadPreProcess::errstr\n";

    while(<$fh>) {
        print $_;    # Or other processing of input
    }

    die($IO::ReadPreProcess::errstr . "\n")
        if($fn->error);

The input file may contain:

    This line will be returned by getline
    .# This is a comment
    .let this := 'that'
    Another line
    .if this eq 'that'
    Another line returned
    .print The variable this has the value \v{this}
    .else
    This line will not be seen
    .fi
    This line returned
    .include another.file
    Line returned after the contents of another.file

=head1 DESCRIPTION

Provide an 'intelligent' bottom end read function for scripts,
what is read is pre-processed before the script sees it.
Your program does not need code to conditionally discard some input, include
files and substitute values.

An easy way of reading input where some lines are read conditionally and other
files included: .if/.else/.elseif/.fi, do: .include .let .print, loops: .while
.for; subroutine definition & call; write to other streams - and more.

Provides IO::Handle-ish functions and input diamond - thus easy to slot in to existing scripts.

The preprocessing layer has variables that can be set and read by your perl code.
In the input files they are set via C<.let> directives, and can be made part of your
script's input with C<.echo> and C<\v{xxx}>.

C<IO::ReadPreProcess> returns lines from the input stream.
This may have directives that include:

=over 4

=item

set variables to arithmetic or string expressions

=item

conditionally return lines

=item

include other files

=item

print to stdout or stderr

=back

Conditions are done by C<Math::Expression>.

=head1 CONSTRUCTOR

C<new> returns an C<IO::ReadPreProcess> object, C<undef> on error.

Arguments to C<new>

=over 4

=item C<File> and C<Fd>

Arguments C<File> and C<Fd>, see method C<open>.
If one of these is not given, method C<open> must be called.

=item C<Trim>

If this is true (default) then input lines will be trimmed of spaces.

=item C<Math>

A C<Math::Expression> object that will be used for expression evaluation.
If this is not given a new object will be instantiated with C<< PermitLoops => 1, EnablePrintf => 1 >>.

If you share a C<Math::Expression> object between different C<IO::ReadPreProcess> objects
then the different files being read will see the same variables.

=item C<DirStart> and C<DirStartRE>

C<DirStart> is the string at the start of a line that introduces a directive, the default is full stop C<.>.
If you wish to change this, provide this option. So to use directives like C<< #if >> go:

    new IO::ReadPreProcess(File => 'fred', DirStart> => '#')

Before use the characters that are special in Regular Expressions will have a backslash C<\>
prepended, this string is stored in C<DirStartRE>.
If the option C<DirStartRE> is provided this transformation will not be done and the provided string will be used directly, thus more complex
start sequences can be used.

Eg: allow the start sequence to be either C<.> or C<%>:

    new IO::ReadPreProcess(File => 'fred', DirStartRE> => '[.%]')

=item C<Raw>

If this is given and true then processing of directives does not happen, they are returned by C<getline>.
You may change this property as input is read but take care to avoid errors, eg: a C<.if> is read in Raw mode
but its C<.fi> in Cooked mode; a complaint will result as the C<.fi> did not have an C<.if>.

C<Raw> might set when in an C<.include>. When the end of that file is reached the previous file (that had
the C<.include> directive) will be returned to and lines read from there.

Default: 0

=item C<OnError>

What should happen when an error happens. Values:

=over 4

=item C<warn>

Print a message to C<STDERR> with C<warn>, this is the default.

=item C<die>

Print a message to C<STDERR> with C<die> which terminates the program.

=item C<>

Do nothing. The application should check the method C<error> and look at C<$IO::ReadPreProcess::errstr>.

=back

=item PipeOK

Pipes are only allowed with C<.include> if the property C<PipeOK> is true (default false).

=item MaxLoopCount

Loops (C<while>, C<until> and C<for>) will abort after this number of iterations.
The count restarts if the loop is restarted.
A value of C<0> disables this test.

This may be overridden on an individual loop with the C<-i> option.

Default 50.

=item OutStreams

This defines output streams that may be written to by C<.out> and C<.print -o>. The
streams can either be C<IO::File>, an array or a reference to a function (when the line will be passed as
the only argument).

The members C<STDOUT> and C<STDERR> are added if not passed, given values C<*STDOUT{IO}> and C<*STDERR{IO}>.
Names must match the RE C</\w+/>.

Eg:

    my $lf = IO::File->new('logFile', 'w+');
    my @lines;
    sub func {
        say "func called '$_[0]'";
    }

    OutStreams => { fun => \&func, log => $lf, buf => \@lines }

This provides the ability to write to multiple places, however the file (or function) must
be opened by the Perl script. C<IO::ReadPreProcess> does not provide the ability to
open new files.

C<.out> can create in-memory streams. These have names like C<@divert> (ie match C</@\w+/i>).
In-memory streams can be written to by C<.out> & C<.print -o> and read by C<.include> & C<.read>.

=back

=head1 PUBLIC PROPERTIES

The properties C<Trim>, C<OnError>, C<MaxLoopCount>, C<OutStreams>, C<PipeOK> and C<Raw> (see C<new>)
may be directly assigned to at any time.

Eg:

    $fh->Raw = 1;

Also the following:

=over 4

=item C<Math>

Note that there are many useful values that you can get here,
some set by C<IO::ReadPreProcess> (see below), others by C<.let> directives.
You can thus communicate with the preprocessing layer.

Eg:

You can set C<Math> variables like this:

    $fh->{Math}->VarSetScalar('FirstName', 'Henry');

You can get C<Math> variable values like this:

    $name = $fh->{Math}->ParseToScalar('FirstName');

    $fileName = $fh->{Math}->ParseToScalar('_FileName');

=item C<Place>

A string that can be used in messages to the user about the current input place.
The value will be like:

    line 201 of slides/regular-expressions.mod

Eg:

    warn "Something wrong at $fh->{Place}\n";

=back

=head1 METHODS

=over 4

=item C<new>

This has been discussed above.

=item C<open>

The argument is the name of the file to be opened and read from.
This method need not be used if the information is given to C<new>.
C<open> returns an C<IO::ReadPreProcess> object, C<undef> on error.

=over 4

=item C<File>

gives the name of the file to be opened. This is mandatory.

=item C<Fd>

B<If> this is given it provides a file descriptor (from C<IO::File>) that is already open for reading.
In which case C<File> (which must still be given) is a name that is used in error messages.
This is useful if you want to read from C<stdin> or a pipe.

=back

If there is an error in opening a file look at C<$IO::ReadPreProcess::errstr>;

Example:

    $fh->open(Fd => \*STDIN, File => 'Standard input', OutStreams => { log => $lf });

=item C<close>

Closes the current input file. If the current file was opened by a C<.include>, the
next line that is read will be the one after the C<.include> directive.

This will not normally be used by applications.

C<close> returns an C<IO::ReadPreProcess> object, C<undef> on error.

** Also used to end a block

=item C<getline>

will return a line from input. This line is not necessarily the next one in the input
file since directives (see below) may specify that some lines are not returned or that
input is taken from another file.

As an alternative, the object (what is returned by C<new>) may be used in the diamond operator
which really calls C<getline>.

After all input has been read this returns C<undef>.

    while(my $line = $fh->getline) {
        ...
    }

Returns C<undef> on error.

=item C<getlines>

Returns the rest of input as an array.

This must be called in a list context.

Returns C<undef> on error.

=item C<putline>

The argument list will be put as input on the current frame and these will be 'read'
as the very next input. Useful for running a .sub. Eg:

    $fh->putline('.show Frodo 35');

=item C<binmode>

This package is intended to read text files, thus setting binary data is probably not a good idea.
C<binmode> also allows different (layer) encoding to be supported, eg:

    $fh->binmode(':utf8');

Any C<binmode> settings will be applied to all files subsequently opened, eg: because of C<.include>.

Returns true on success, C<undef> on error.

See perl's C<binmode> function.

=item C<eof>

Returns 1 if the next read will return End Of File or the file is not open.

=item C<error>

Returns true of there has been an error. See C<clearerr>.

=item C<clearerr>

Clears any error indicator.

=back

=head1 DIRECTIVES

Input files may contain directives. These all start with a full stop (C<.>) at the start of line,
this may be changed with C<DirStart>.
There may not be spaces before the C<.>.

Lines starting with directives other than the ones below will be returned to the application.

Conditions are done by C<Math::Expression>.

=over 4

=item C<.#>

These lines are treated as comment and are removed from input.

=item C<.let>

The argument is an expression as understood by C<Math::Expression>. Then result is ignored.
This may be used to set one or more variables.

Eg:

=over 4

    .let count := 0; page := 1
    .let ++count
    .let if(count > 10) { ++page; count := 0 }

=back

=item C<.if> C<.elseif> C<.elseif> C<.else> C<.fi> C<.unless>

The rest of the C<.if> line is evaluated by C<Math::Expression> and if the result is true the following lines
will be returned.
An optional C<.else> reverses the sense of the C<.if> as regards (not) returning lines.
C<.if> may be nested.
A C<.if> must have a matching and ending C<.fi>.
C<.elseif> may be used where a C<.else> can be found and must be followed by a condition.
C<.elsif> is a synonym for C<.elseif>.

C<.unless> is the same as C<.if> except that the truthness of the result is considered inverted.

Text following C<.fi> or C<.else> will be ignored - you may use as comment.

The condition may be a defined subroutine which will be run and the value set by C<.return> used
as the boolean. The arguments are processed as if by C<.print>.

    .if .someSub arg1 \v{someVariable}
    Conditional text
    .fi

The condition may also be one of the directives: C<.include> C<.read> C<.test>

=item C<.print>

The rest of the line will be printed to C<stdout>.

If the line starts C<-e> it will be written to output stream C<STDERR>.

If the line starts C<-o strm> it will be written to output stream C<strm>.
C<strm> may be an in-memory stream.

Eg:

    .print -o log Something interesting has happened!
    .print -o @divert A line to be read back later

The following escapes will be recognised and substitutions performed:

=over 4

=item C<\e>

generates the escape character C<\>.

=item C<\0>

generates the empty string.
You might use this if you wanted to C<.print> a line starting with C<-e>.

=item C<\v{var}>

interpolates variable C<var> or array member C<array[index]> from C<Math::Expression>.
C<var> must match the regular expression: /\w+|\w+\[\w+\]/i

=back

=item C<.echo>

Escape substitution is performed as with C<.print> and the line returned by C<getline>.
This allows variables to be used in the input the application reads without it being aware
of what is going on.

    .echo Index=\v{i} person=\v{names[i]}

=item C<.include>

The first argument is a file path that is opened and lines from this returned
to the application.

Paths that start C</> are absolute and are just accepted.

Path that start C<#> are taken to be with respect to the current working directory of
the process. The C<#> is removed and the path accepted.

    .# Include a file 'header' from a generic 'snippets' directory:
    .include #snippets/header

Other paths are relative to the file being processed, the directory path is prepended
and the result used. If such a path is used in a file opened by C<Fd> an error results.

    .# Include a file in the same directory as the current file:
    .include common_module

If the path starts C<$> the next word is a variable name. The value is prepended to
the rest of the path and the file tested for existence as above (eg test starts C</>,
C<#> and others). If the variable is an array the paths are tried until one is found. Eg:

    .let dirs := split(':', '.:mydir:#builddir:/home/you/yourdir:/usr/local/ourdir')
    .include $dirs/good_file.txt

Words that follow are deemed arguments and made available within the include via the array C<_ARGS>.
See C<.sub>.

    .# header can generate different headers, ask for one suitable for a report:
    .include #snippets/header report

The file path and arguments are processed for escapes as C<.print>.

The file path and arguments may contain spaces if they are surrounded by quotes (C<'">).

If the path starts C<|> the rest of the line is a pipe that will be run and read from.
Pipes are only allowed if the property C<PipeOK> is true (default false).
B<WARNING> this will run an arbitrary command, you must be confident of the source
and contents of the files being processed.

If the first arguments are C<-s name> the file is opened on a named stream that may be
used by C<.read> and should be closed with C<.close>.

If the first argument is C<-pn> the file stream is put C<n> frames below the current one.
A new frame is created for every file opened, C<if>, C<while>, C<sub> executed, ...
(C<n> is an optional number, default: 1)

If the path starts with an C<@> (ie matches C</@\w+/i>) the include reads from the
in-memory stream that was created with an earlier C<.out>. Eg:

    .include @divert

=item C<.close>

This is only needed to close named streams. The C<-s name> option is needed.

=item C<.out>

This diverts output to the output stream (see: C<OutStreams>) mentioned.
Lines generated will be sent there until a C<.out> directive without an argument.

Eg:

    .out index
    Meals in London
    Times of the last tube trains
    .out

In-memory streams must be created before they are used, this is done with the C<-c> option.
C<-c> may be used on an existing stream and will throw away any existing content.

Eg:

    .out -c @buf
    Text diverted to @buf
    .out

=item C<.local>

Marks the arguments as variable names that are local to the current block (C<.include>, C<.while>, C<.sub>, ...).
When the block returns the previous value will be restored.
The values restored are the values of the variables at the time the C<.local> is seen.
Note that variable scope is dynamic, not lexical.

This happens automatically for C<_ARGS> on an C<.include> and \c{.sub} and named \c{.sub} arguments.

=item C<.return>

This ends reading a file early, the previous file is picked up on the line
after the C<.include>. At the top level (ie first file) end of file is returned to the application.

Within a C<.sub> this may be used to return a value. The value of the last expression in a C<.sub> is not automatically
used as a return value.

C<.return> may be followed by an expression; this will be assigned to the variable C<_> (underscore).
Default C<undef>:

    .return count + 1

=item C<.exit>

The application will be terminated.

Any text after on the line will be processed by C<Math::Expression> and if
it is a number it is used as an exit code. If none is specified the exit code will be 2.

=item C<.eval>

The rest of the line is processed for escapes as C<.print>. It is then treated as if
it had just been read. The processed line might even start with a command that is
recognised by this module, eg this ends up setting variable C<a> to the value 3:

    .let a := 1; b := 2; var := 'a'
    .print a=\v{a} b=\v{b}
    .eval .let \v{var} := 3
    .print a=\v{a} b=\v{b}

Do not use C<.eval> to generate a conditional or loop, eg: C<.if>; C<.while>.

=item C<.read>

Read the next line of input into a variable. The line is trimmed of the trailing newline (chomped).
It is trimmed of white space if C<Trim>.
The variable C<_EOF> is assigned 0.

At end of file the variable is assigned the empty string and the variable C<_EOF> is assigned 1.
The variable C<_> is set to 1 on read success.

This will be of most use with a stream opened with a C<-p> or C<-s> option:

    .include -p | hostname
    .read host
    .echo This machine is called \v{host}

    .include -s who | whoami
    .read -s who me
    .echo Logged in as \v{me}
    .close -s who

If the first argument is an in-memory stream (ie a name that starts with C<@>) a line is read from that. Eg:

    .read @divert line

=item C<.sub>

Defines a subroutine on the following lines, ending with C<.done>. The subroutine is called
by invoking it C<.name>.

Arguments may be passed to the subroutine and are available in the array C<_ARGS>.
Following the C<name> optional names may be given, these are variables as C<.local>
and, when called, any arguments are copied there.
Beware: these are copies, ie separate from what is in C<_ARGS>.

    .sub show name age
    Hobbits live in the Shire
    .echo \v{name} is \v{age} years old
    .echo That name again: \v{_ARGS[0]}
    .done
    .show 'Bilbo Baggins' 50

You can get the original argument string with C<join>, beware this will not give the exact
argument string since if two words are separated by more than one space the extra spaces
will be lost.

    .sub manyArgs
    .let allArg := join(' ', _ARGS); na := count(_ARGS)
    .echo All \v{na} arguments as a string '\v{allArg}'
    .done
    .manyArgs all cats have whiskers

=item C<.noop>

This is a no-operation and does nothing.

=item C<.while>

This starts a loop that continues as long as the expression (see C<.if>) is true.
The loop is terminated by the line C<.done>.

If the option C<-inn> is given, the loop limit is set to C<nn> for this loop. See default C<MaxLoopCount>.
There may be spaces between C<-i> and C<nn>.

    .let i := 0
    .while -i 100 i++ < 100
    Part of a .while loop
    .echo i has the value \v{i}
    .done

Loops are buffered in memory.
C<.include> within a loop is not buffered, ie read on every iteration.

=item C<.until>

This is the same as C<.while> except that the loop stops when the expression becomes true.

=item C<.for>

This starts a loop.
The loop is terminated by the line C<.done>.

This has the form:

    .for init ;; condition ;; incr

Note that the C<;;> will be seen even if inside a quoted string.

As with C<.while> and C<.until> you may use the C<-i> option.
C<init> is run once before the loop starts; C<condition> is as C<.while>; C<incr> is run after every iteration.
C<init> and C<incr> are processed by C<Math::Expression>, ie no subs allowed.

Eg:

    Count down begins
    .for i := 10 ;; i > 0 ;; i--
    .echo \v{i}
    .done
    Blast off!

    .sub foo num
    .return num > 2
    .done

    .for i := 5 ;; .foo \v{i} ;; i--
    something ...
    .done

=item C<.break> C<.last>

Terminate the current loop.
These directives are synonyms.

These may be followed by the number of loops to terminate, default 1.

=item C<.continue> C<.next>

Abandon the rest of the current loop, start the next iteration.
These directives are synonyms.

These may be followed by a number, inner ones are terminated, that loop number has its iteration started, default 1.

=item C<.done>

Ends blocks: C<.while> C<.until> C<.for> C<.sub>.
If may be followed by the type of block that it ends, if so a consistency check is made.

Eg:

    .for i := 0 ;; i < 5 ;; i++
    Text output
    .done for

=item C<.test>

Various tests. This will set C<_> to C<0> or C<1>.

=over 4

=item C<-f>

This returns true if the argument file exists. The file path is as for C<.include> except that pipes
are not allowed. This also sets the array C<_STAT> with information about the file (see below)
and C<_TestFile> will be the path found - ie after the C<#>, C<$>, ... is resolved.

Eg:

    .if .test -f $dirs/good_file.txt
    .print -e Including \v{_TestFile}, size \v{_STAT[7]} bytes.
    .include $dirs/good_file.txt
    .fi

=back

=item C<-m>

This returns true if the argument in-memory stream exists.
If it exists, the variable C<_COUNT> is set to the number of lines in the stream.

=item C<.error>

An error is returned to the application, ie C<undef> is returned.
The remaining text on the line is processed, see C<OnError> above.

=item C<.set>

Permits the setting of run time options. These may also be given as arguments to C<new>:

=over 4

=item C<trace=n>

Set the trace level to C<n>. C<1> traces directives, C<2> traces directives and generated input.

=back

=item C<.case> C<.do> C<.endswitch> C<.function> C<.switch>

These are reserved directives that may be used in the future.

=back

=head1 C<Math::Expression> variables

Any starting C<_> are reserved for future use

The following variables will be assigned to:

=over 4

=item C<_FileName>

The name of the current C<File>.

=item C<_LineNumber>

The number of the line just read.

=item C<_FileNames>

Array of files being read.
The file last C<.include>d is in C<_FileNames[-1]>.

=item C<_LineNumbers>

Array of line numbers as C<_FileNames>.

=item C<_IncludeDepth>

The number of files that are open for reading.
The file passed to C<new> or C<open> is number 1.

=item C<_>

Value of the last C<.return>.

=item C<_ARGS>

Arguments provided to a C<.sub> or C<.include>.

=item C<_TIME>

The current time (seconds), supplied by C<Math::Expression>.

=item C<_EOF>

Set to C<1> if C<.read> finds End Of File, else set to C<0>.

=item C<_CountGen>

Count of lines generated.

=item C<_CountSkip>

Count of lines skipped.

=item C<_CountDirect>

Count of directives processed.

=item C<_CountFrames>

Count of frames opened. For every: sub, if, loop.

=item C<_CountOpen>

Count of files opened.

=item C<EmptyArray> C<EmptyList>

Empty arrays supplied by C<Math::Expression>.

=item C<_STAT>

Array of information about the last file found by C<.test -f>.
Members are as for perl's stat function:

  0 device number of filesystem
  1 inode number
  2 file mode  (type and permissions)
  3 number of (hard) links to the file
  4 numeric user ID of file's owner
  5 numeric group ID of file's owner
  6 the device identifier (special files only)
  7 total size of file, in bytes
  8 last access time in seconds since the epoch
  9 last modify time in seconds since the epoch
 10 inode change time in seconds since the epoch
 11 preferred block size for file system I/O
 12 actual number of blocks allocated

=item C<_TestFile>

The name of the last file found by C<.test -f>.

=item C<_Initialised>

Internal use, prevent double initialisation of variables.

=back

=head1 ERRORS

Most methods return C<undef> if there is an error. There will be a reason in C<$IO::ReadPreProcess::errstr>.
The error could be from C<IO::Handle> (where C<$!> might be helpful) or an error in the file format in which case C<$!>
will be set to C<EINVAL>.

Beware: C<getline> returns C<undef> on end of file as well as error. Checking the method C<error> will distinguish the two cases.

Note also the property C<OnError> (see above).

=head1 EXAMPLES

The script below sets some variables that are passed on the command line,
more from include files and then reads stdin.
The variables that are set can be used to control what it reads.

    use IO::ReadPreProcess;
    use Getopt::Long;
    use Math::Expression;

    # One arithmetic instance so that variables are visible in all files:
    my $ArithEnv = new Math::Expression( PermitLoops => 1, EnablePrintf => 1 );

    my @let = ();
    my @includes = ();
    my $verbose = 0;
    my $help = 0;

    # Look at command line options ... add other options here:
    GetOptions(help => \$help, 'include=s' => \@includes, 'let=s' => \@let, verbose => \$verbose);

    Usage if $help;

    # Evaluate all --let
    # Look like: --let='advanced := 1'
    for (@let) {
        say "Evaluating: $_" if $verbose;
        die "Invalid --let='$_'\n"
            unless(defined $ArithEnv->ParseToScalar($_));
    }

    # Read all --include
    # These must not yeild anything other than blank lines
    # The point is that we evaluate .let, etc.
    for my $file (@includes) {        
        say "Including: $file" if $verbose;
 
        my $inc = IO::ReadPreProcess->new(File => $file, Math => $ArithEnv, OnError => 'die', PipeOK => 1) or
            die "$0: Opening include '$file': $IO::ReadPreProcess::errstr\n";                       

        # All that is next should be empty lines:
        while (<$inc>) {
            die "Non empty line found via '--include $file' at $inc->{Place}\n"
                if /\S/;
        }
    }

    # If not stdin, maybe loop over @ARGV:
    my $fh = new IO::ReadPreProcess(Fd => \*STDIN, File => 'Standard input', Math => $ArithEnv) or
        die "Startup error: $IO::ReadPreProcess::errstr\n";

    while(<$fh>) {
	...

	die "Error ... at: $fh->{Place}\n"
	    if(...);
    }

    # Use pre-processor variable
    print "Sum output " . $ArithEnv->ParseToScalar('sum') . "\n";

Most of the interest lies in the input:

    .let sum := 0
    A line of input

    .# Check to see if this is advanced
    .if advanced

    Complicated stuff
    .let level := 'advanced'

    .if advanced > 1

    .# Bring in an extra file:
    .include extra_files/very_complex
    .let sum = sum + 2

    .fi advanced > 1
    .else

    Simple stuff
    .let level := 'simple'

    .fi

    .# Bring in an extra file where _ARGS[0] is either 'advanced' or 'simple':
    .include extra_files/extra_module \v{level}

    .print Showing material that is \v{level}


For more examples see the test suite.

At the end of the run you might want to do this:

    # Some stats, for fun:
    say STDERR $ArithEnv->ParseToScalar('printf("Preprocessing: lines generated %d, skipped %d. Directives %d, frames opened %d, files opened %d", _CountGen, _CountSkip, _CountDirect, _CountFrames, _CountOpen)');

=head1 SECURITY

Do be aware that a C<.include> will open any file for which the process has permissions.
So there is scope for an input file to pass the contents of arbitrary
files into your program; this also applies to any files that the initial input file
may, directly or indirectly, C<.include>.

If a pipe is created: read this section twice.

Summary: be aware of the provenance of all input files.

=head1 BUGS

When used in the diamond operator in a list context only one line will be returned.
This is due to a problem in the perl module C<overload>.

Please report any bugs or feature requests to C<bug-io-readpreprocess at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-ReadPreProcess>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IO::ReadPreProcess


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IO-ReadPreProcess>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IO-ReadPreProcess>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IO-ReadPreProcess>

=item * Search CPAN

L<http://search.cpan.org/dist/IO-ReadPreProcess/>

=back


=head1 AUTHOR

Alain Williams, C<< <addw@phcomp.co.uk> >> April 2015, 2017.

=head1 COPYRIGHT

Copyright (C) 2015, 2017 Alain Williams.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/> for more information.

=head1 ABSTRACT

Provide an 'intelligent' bottom end read function for scripts.

=cut

Something to help you understand some of the data structures:

Property Frame of the object.
These are in FrameStk

Frames are created for:

* every active file
* every active sub
* every active loop
* if ?

Properties of Frame (not all of these at the same time):

    Code	Hash code properties; this is a CodeBuf (the name only exists in this description)
    CodeLine	Line # (array index: Lines) of next line to execute

    Fd		File handle of current file
    FdLine	A line of input instead of reading from Fd; will be deleted once read

    PushedInput	An array reference, lines may be pushed here and will be 'read' in preference
		to input from Code or Fd.

    binmode	If true: to be applied to any file opened in the frame

    Fd or CodeBuf is defined, not both

    LocalVars	Hash of varname => value - previous (pushed) values for varname, etc
    		This replaces VarStkFlag VarStk

    Name	Name of open file, name of sub or file where the code was read from

    LineNumber	Number of current line being executed - from File

    FrameStart	Name:LineNumber

    Generate	True if generating (think .if), inherited from previous.
    DidGenerate	Used to decide if a .else* should be run
    Else	Value is line number of a .else

    If also has:
        Type	if/unless
    type	Used in ReadBlock() to check block open/end keywords.

    CpMove	If true: on frame close, any CodeLine to be copied to parent frame.

    ReturnFrom	If true a .return will unwind to here and return to the previous.

    Other properties for loops
    	LoopMax	Max iterations - 0 == no limit - this is copied from code->{LoopMax}
		This is also used to identiy the frame as a loop frame
	LoopCnt	Count of iterations so far
	Loop	Just to note that it is a loop frame

    CondReRun	Rerun the condition in main loop, as: .if .subroutine/.directive
    intDir	Running an internal directive, eg: .if .read var

In the line:
    SubCond	.subroutine args -- when used as a condition, eg: .if .test -f xxxx

CodeBuf - for loops

    Lines	ref to array of Line that contains the code
    FirstLine	First line # in Lines
    LastLine	Last line # in Lines
    Block	'while' 'until' 'for'

Subs read into hash, CodeBuf:

    Lines	ref to array of Line that contains the code
    FirstLine	First line # in Lines
    LastLine	Last line # in Lines
    Block	'sub'
    Name	Name of Sub
    FileName	that the sub came from
    FileLine	line # of start of sub in FileName
    ArgNames	Optional array of argument names

Line - one line of buffered code:

    Txt		Text - string, the line of code/text
    #		Line # in File or Sub
    Expr	May be present, compiled .set/.if/.unless/.elsif/.elseif expression
		and loop condition
    Loop	The while/for line will have this.
    		LoopBuf - ie first/lastLine

    The line that is the first of a loop has something like:

    Lines	ref to array that contains the code, could be same as Subs:Lines
    First	# of first line of loop in Lines
    Last	# of last line of loop in Lines, this will be the one with .done
    Init	Loop initialisation
    Expr	Loop condition
    For3	For Loop 3rd expression
    Not		Invert loop condition (ie it is '.until')
    LoopEnd	Line # after loop, ie after the .done -- NO - just pop the frame
    LoopStart	In the .done, the array index of the .while/.until/.for
    LoopStart/LoopEnd are in the line of start of the loop, they are copied to the frame


