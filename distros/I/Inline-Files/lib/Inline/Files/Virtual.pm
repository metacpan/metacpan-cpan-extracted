package Inline::Files::Virtual;
$VERSION = '0.53';
use strict;
use Carp;
use Cwd qw(abs_path);

# To Do:
# - Add an EOF flag and make sure (virtual) system calls treat it right
# - Call close on an implicit open.
# - Add unlink(). Should behave properly if file is open.
# - Support this idiom for multiple FOO:
#     open FOO;
#     close FOO;
#     while (open FOO) {
#         while (<FOO>) {
#         }
#     }

# Damian. Let's leave this trace feature in for a while.
# The calls to it should be constant folded out of the bytecode anyway,
# (when DEBUG is 0) so there's no real performance penalty.
# It has helped me find many a bug :)
BEGIN {
    sub DEBUG () { 0 }
    my ($TRACING, $ARGS) = (1, 1);
    sub TRACING {$ENV{INLINE_FILES_TRACE} || $TRACING}
    sub ARGS {$ENV{INLINE_FILES_ARGS} || $ARGS}
    sub TRACE {
	$| = 1;
	local $^W;
	return unless TRACING || ARGS;
	print "=" x 79, "\n" if ARGS;
	print ((caller(1))[3], "\n") if TRACING || ARGS;
	return unless @_;
	require Data::Dumper;
	$Data::Dumper::Purity = 1;
	$Data::Dumper::Indent = 1;
	print Data::Dumper::Dumper(\@_) if ARGS;
    }
}

my %vfs;    # virtual file system
my %mfs;    # marker-to-virtual-file mapping
my %afs;    # actual file system

my (%read, %write, %append, %preserve);
@read{qw( < +> +< )} = ();
@write{qw( > +> +< >> )} = ();
@append{qw( >> )} = ();
@preserve{qw( >> +< < )} = ();

sub not_input  { "Virtual file not open for input\n" }
sub not_output { "Virtual file not open for output\n" }

sub import {
    DEBUG && TRACE(@_);
    my $caller = caller;
    no strict 'refs';
    *{"${caller}::$_"} = \&$_
      for (qw( vf_load vf_save vf_marker vf_prefix
	       vf_open vf_close vf_seek vf_tell vf_truncate vf_write 
	       DEBUG TRACE
	     ));
    1;
}

sub vf_load {
    DEBUG && TRACE(@_);
    my ($file, $header) = @_;
    my $path = './';
    $file =~ s|\\|/|g;
    ($path, $file) = ($1, $2) if $file =~ m|^(.*)/(.*)$|;
    $file = abs_path($path) . "/$file";
    return @{$afs{$file}{vfiles}} if $afs{$file};
    local ($/, *FILE);
    open FILE, $file or croak "Could not vf_load '$file'";
    my @vdata = split /(?m)($header)/, <FILE>;
    my ($offset,$linecount) = (0,1);
    unshift @vdata, "";
    my ($marker, $data, $vfiles);
    while (($marker, $data) = splice @vdata,0,2) {
        my $vfile = sprintf "$file(%-0.20d)",$offset;
        $vfs{$vfile} =
	  { data   => $data,
	    marker => $marker,
	    offset => $offset,
	    line   => $linecount,
	  };
        $offset += length($marker) + length($data);
        $linecount += linecount($marker, $data);
        push @$vfiles, $vfile;
        push @{$mfs{$marker}}, $vfile;
    }
    $afs{$file}{vfiles} = $vfiles;
    return @{$vfiles}[1..$#$vfiles]; 
}

my $new_counter = 0;
sub vf_open (*;$$$) {
    DEBUG && TRACE(@_);
    my $glob   = shift;
    my $file   = shift;
    my $symbol = shift;

    my $mode;
    if ($file && $file =~ /^(?:\|-|-\||>|<|>>|>:.*)$/) {
        $mode = $file;
        $file = $symbol;
        $symbol = shift;
    }

    no strict;
    if (defined $glob) {
	$glob = caller() . "::$glob" unless ref($glob) || $glob =~ /::/;
        # The following line somehow manages to cause failure on threaded perls.
        # The good news is that everything works just fine without it.
	# $glob = \*{$glob};
    }
    else {
	# autovivify for: open $fh, $filename
	$glob = $_[0] = \do{local *ANON};
    }

    if (!$mode) {
        # Resolve file
        $file ||= "";
        $file =~ s/^([^\w\s\/]*)\s*//i;
        $mode = $1 || "";

        if (!$mode && $file =~ s/\s*\|\s*$//) {
            $mode = $mode || "-|";
        }
    }
    unless ($file) {
        my $scalar = *{$glob}{SCALAR};
        $file = $scalar ? $$scalar : "";
        $file =~ s/^([^a-z\s\/]*)\s*//i;
        $mode = $mode || $1 || "<";
    }
    $mode ||= "<";
    $file = $mfs{$file}[0] if $file and exists $mfs{$file};

    # Create a new Inline file (for Inline::Files only)
    if (not $file and defined $Inline::Files::{get_filename}) {
	(my $marker = *{$glob}{NAME}) =~ s|.*::(.*)|$1|;
	if ($marker =~ /^[A-Z](?:_*[A-Z0-9]+)*$/) {
	    if ($file = Inline::Files::get_filename((caller)[0])) {
		$marker = "__${marker}__\n";
		my $vfile = sprintf "$file(NEW%-0.8d)", ++$new_counter;
		$vfs{$vfile} =
		  { data   => '',
		    marker => $marker,
		    offset => -1,
		    line   => -1,
		  };
		push @{$mfs{$marker}}, $vfile;
		push @{$afs{$file}{vfiles}}, $vfile;
		$file = $vfile;
	    }
	}
    }

    $! = 2, return 0 unless $file; # Can't work at this point; confuses core
    # Default to CORE::open
    unless (exists $vfs{$file}) {
        return CORE::open($glob, $mode, $file);
    }

    my $afile = $file =~ /^(.*)[(](NEW)?\d+[)]$/ ? $1 :
      croak "Internal error\n";

    # If file is virtual, tie it up, and set it up
    my $impl = tie (*$glob, 'Inline::Files::Virtual', 
		    $file, $afile, $mode, $symbol);

    $afs{$afile}{changed} = 0;
    $impl->TRUNCATE() if (exists $write{$mode}
			  and not exists $preserve{$mode});
    return 1;
}

sub linecount {
    DEBUG && TRACE();
    my $sum = 0;
    foreach (@_) { $sum += tr/\n// }
    return $sum;
}

sub vf_save {
    DEBUG && TRACE(@_);
    my @files = @_;
    @files = keys %afs unless @files;
    for my $file (@files) {
	next unless $afs{$file}{changed};
        $afs{$file}{changed}=0;
        local *FILE;
        open FILE, ">$file"
          and print FILE map { my $entry = $vfs{$_};
			       if (length $entry->{data}) {
				   chomp $entry->{data};
				   $entry->{data} .= "\n";
			       }
			       "$entry->{marker}$entry->{data}";
			   } @{$afs{$file}{vfiles}}
	and close FILE
	  or ($^W and warn "Could not vf_save '$file'\n$!")
	    and return 0;
    }
    return 1;
}

END { 
    DEBUG && TRACE(@_);
    vf_save;
}

sub vf_marker ($) {
    DEBUG && TRACE(@_);
    my ($virtual_filename) = @_;
    return $vfs{$virtual_filename}{marker};
}

sub vf_prefix ($) {
    DEBUG && TRACE(@_);
    my ($actual_filename) = @_;
    return $vfs{$afs{$actual_filename}{vfiles}[0]}{data};
}

sub vf_close (*) {
    DEBUG && TRACE(@_);
    my ($glob) = @_;
    no strict;
    $glob = caller() . "::$glob" unless ref($glob) || $glob =~ /::/;
    my $impl = tied(*$glob);
    return CORE::close $glob unless $impl;
    return vf_save();
}

sub vf_seek (*$$) {
    DEBUG && TRACE(@_);
    my ($glob, $pos, $whence) = @_;
    no strict;
    $glob = caller() . "::$glob" unless ref($glob) || $glob =~ /::/;
    my $impl = tied(*$glob);
    return seek $glob, $pos, $whence unless $impl;
    return $impl->SEEK($pos, $whence);
}

sub vf_tell (*) {
    DEBUG && TRACE(@_);
    my ($glob) = @_;
    no strict;
    $glob = caller() . "::$glob" unless ref($glob) || $glob =~ /::/;
    my $impl = tied(*$glob);
    return tell $glob unless $impl;
    return $impl->TELL();
}

sub vf_truncate (*$) {
    DEBUG && TRACE(@_);
    my ($glob, $length) = @_;
    no strict;
    $glob = caller() . "::$glob" unless ref($glob) || $glob =~ /::/;
    my $impl = tied(*$glob);
    return truncate $glob, $length unless $impl;
    return $impl->TRUNCATE($length);
}


sub vf_write (*) {
    DEBUG && TRACE(@_);
    my ($glob) = @_;
    no strict;
    $glob = caller() . "::$glob" unless ref($glob) || $glob =~ /::/;
    my $impl = tied(*$glob);
    return write $glob unless $impl;
    return $impl->WRITE();
}

sub TIEHANDLE {
    DEBUG && TRACE(@_);
    my ($class, $vfile, $afile, $mode, $symbol) = @_;
    my $vfs_entry = $vfs{$vfile} or return;
    bless { vfile => $vfs_entry, 
	    pos   => exists $append{$mode} ? length $vfs_entry->{data} : 0, 
            mode  => $mode,
            symbol => $symbol,
	    afile => $afile,
          }, $class;
}

sub STORE {
    DEBUG && TRACE(@_);
}

sub PRINT {
    DEBUG && TRACE(@_);
    my($impl,@args) = @_;
    $^W && warn(not_output), return 1 unless exists $write{$impl->{mode}};
    my $text = join '', @args;
    substr($impl->{vfile}{data},$impl->{pos},-1) = $text;
    $impl->{pos} += length $text;
    $afs{$impl->{afile}}{changed} = 1;
    return 1;
}

sub PRINTF {
    DEBUG && TRACE(@_);
    my($impl,$format,@args) = @_;
    $^W && warn(not_output), return 1 unless exists $write{$impl->{mode}};
    my $text = sprintf($format,@args);
    substr($impl->{vfile}{data},$impl->{pos},-1) = $text;
    $impl->{pos} += length $text;
    $afs{$impl->{afile}}{changed} = 1;
    return 1;
}

use vars '$AUTOLOAD';
sub AUTOLOAD {
    DEBUG && TRACE(@_);
    my $impl = shift;
    croak "$AUTOLOAD not yet implemented";
}

sub DESTROY {
    DEBUG && TRACE(@_);
}

# Inline::Files support
sub _magic_handle {
    DEBUG && TRACE(@_);
    my ($impl) = @_;
    return unless $INC{'Inline/Files.pm'} && $impl->{symbol};
    no strict 'refs';
    return tie *{$impl->{symbol}}, 'Inline::Files', $impl->{symbol};
}

sub READ {
    DEBUG && TRACE(@_);
    my($impl,$buffer,$length,$offset) = @_;
    $^W && warn(not_input), return unless exists $read{$impl->{mode}};
    $offset = $impl->{pos} unless defined $offset;
    my $remainder = length($impl->{vfile}{data})-$impl->{pos};
    $length = $remainder if $remainder < $length;
    $_[1] = substr($impl->{vfile}{data},$offset,$length);
    $impl->{pos} += $length;
    if ($length>=0) {
        return $length
    }
    elsif ($impl = _magic_handle($impl)) {
        return $impl->READ($buffer,$length,$offset);
    }
    else {
        return;
    }
}

sub READLINE {
    DEBUG && TRACE(@_);
    my ($impl) = @_;
    $^W && warn(not_input), return unless exists $read{$impl->{mode}};
    my $match = !defined($/)  ? '.*'
      : length $/     ? ".*?\Q$/\E|.*"
	:                 '.*?\n{2,}';
    my (@lines);
    my $list_context ||= wantarray;
    while (1) {
	  if ($impl->{pos} < length $impl->{vfile}{data} and 
	      $impl->{vfile}{data} =~ m{\A(.{$impl->{pos}})($match)}s) {
	      $impl->{pos} += length($2);
	      push @lines, $2;
	  }
	  else {
	      last unless $impl = _magic_handle($impl);
	      last unless $impl = $impl->MAGIC;
	      next;
	  }
	  last unless $list_context;
    }
    return $list_context ? (@lines) :
      @lines ? $lines[0] : undef;
}

sub MAGIC {
    DEBUG && TRACE(@_);
    $_[0];
}

sub GETC {
    DEBUG && TRACE(@_);
    my ($impl) = @_;
    $^W && warn(not_input), return unless exists $read{$impl->{mode}};
    my $char = substr($impl->{vfile}{data},$impl->{pos},1);
    $impl->{pos}++;
    return $char if length $char;
    return unless $impl = _magic_handle($impl);
    return $impl->GETC();
}

sub TELL {
    DEBUG && TRACE(@_);
    my ($impl) = @_;
    return $impl->{pos};
}

sub SEEK {
    DEBUG && TRACE(@_);
    my ($impl, $position, $whence) = @_;
    my $length = length $impl->{vfile}{data};
    my $pos = $impl->{pos};
    $pos = ( $whence==0 ? $position :
	     $whence==1 ? $position + $impl->{pos} :
	     $whence==2 ? $position + $length :
	     return
	   );
    return if $pos < 0; 
    $pos = $length if $pos >= $length; 
    $impl->{pos} = $pos;
    return 1;
}

sub TRUNCATE {
    DEBUG && TRACE(@_);
    my ($impl, $length) = @_;
    $length ||= 0;
    substr($impl->{vfile}{data},$length,-1) = "";
    $impl->{pos} = $length if $length < $impl->{pos};
    $afs{$impl->{afile}}{changed} = 1;
    return 1;  
}

1;

__END__

=head1 NAME

Inline::Files::Virtual - Multiple virtual files in a single file

=head1 VERSION

This document describes version 0.53 of Inline::Files::Virtual, released May 25, 2001.

=head1 SYNOPSIS

    use Inline::Files::Virtual;

    # Load actual file, extracting virtual files that start with "^<VF>\n"
    @virtual_filenames = vf_load($actual_file, "^<VF>\n");
    
    # Open one of the virtual files for reading
    open(FILE, $virtual_filenames[0]) or die;
    
    print while <FILE>;
    
    close(FILE);

    # Open one of the virtual files for appending
    open(FILE, ">> $virtual_filenames[1]") or die;
    
    print FILE "extra text";
    printf FILE "%6.2", $number;
    
    close(FILE);
    
    # Actual file will be updated at this point
    
=head1 WARNING

This module is still experimental. Careless use of it will almost
certainly cause the source code in files that use it to be overwritten.
You are I<strongly> advised to use the Inline::Files module instead.

If you chose to use this module anyway, you thereby agree that the
authors will b<under no circumstances> be responsible for any loss of
data, code, time, money, or limbs, or for any other disadvantage incurred
as a result of using Inline::Files.


=head1 DESCRIPTION

This module allows you to treat a single disk file as a collection of
virtual files, which may then be individually opened for reading or
writing. Virtual files which have been modified are written back to
their actual disk at the end of the program's execution (or earlier if
the C<vf_save> subroutine is explicitly called).

Each such virtual file is introduced by a start-of-virtual-file marker
(SOVFM). This may be any sequence (or pattern) of characters that marks
the beginning of the content of a virtual file. For example, the string
C<"--"> might be used:

        --
        Contents of virtual
        file number 1
        --
        Contents of virtual
        file number 2
        --
        Contents of virtual
        file number 3

or the pattern C</##### \w+ #####/>:

        ##### VF1 #####
        Contents of virtual
        file number 1
        ##### VF2 #####
        Contents of virtual
        file number 2
        ##### VF3 #####
        Contents of virtual
        file number 3

Note that the SOVFM is not considered to be part of the file contents.

=head2 Interface

The module exports the following methods:

=over 4

=item C<vf_load $file, $SOVFM_pattern>

This subroutine is called to load an actual disk file containing one or
more virtual files. The first argument specifies the name of the file to
be loaded as a string. The second argument specifies a pattern (as
either a string or C<qr> regex) that matches each start-of-virtual-file
marker within the file. For example, if the file
C</usr/local/details.dat> contains:

        =info names
        
        Damian
        Nathan
        Mephistopheles  
        
        =info numbers
        
        555-1212
        555-6874
        555-3452
        
        =info comment
        
        Mad
        Bad
        Dangerous to know
        
then you could load it as three virtual files with:

        @virtual_filenames =
                vf_load("/usr/local/details.dat", qr/^=info\s+\S+\s*?\n/);

Note that, because the actual file is decomposed into virtual files
using a C<split>, it is vital that the pattern does not contain any
capturing parentheses.

On success, C<vf_load> returns a list of I<virtual filenames> for the
virtual files. Each virtual filename consists of the actual name of the
file containing the virtual file, concatenated with the offset of the
virtual file's SOVFM within the actual file. For example, the above call
to C<vf_load> would return three virtual filenames:

        /usr/local/details.dat(00000000000000000000)
        /usr/local/details.dat(00000000000000000048)
        /usr/local/details.dat(00000000000000000097)
        
When any of these virtual filenames is subsequently used in an C<open>, the 
corresponding virtual file is opened.

=item C<vf_save @actual_filenames>

=item C<vf_save>

This subroutine causes the virtual files belonging to the nominated
actual file (or files) to be written back to disk. If C<vf_save> is
called without arguments, then I<all> currently loaded virtual files are
saved to their respective actual files at that point.

C<vf_save> is automatically called in an C<END> block at the termination
of any program using the module.

=item C<vf_marker $virtual_filename>

This subroutine returns the SOVFM that preceded the nominated virtual file.


=back

The module also modifies the C<open>, C<close>, C<print>, C<printf>,
C<read>, C<getline>, C<getc>, C<seek>, C<tell>, and C<truncate> built-in
functions so that they operate correctly on virtual files.

As a special case, it is also possible to use the raw SOVFM as a virtual
file name:

    use Inline::Files::Virtual;

    vf_load $filename, qr/__[A-Z]+__/;

    open FILE, "__MARKER__";

    # and in the file that was vf_load-ed

    __MARKER__
    file contents here

However, this always opens the very first virtual file with that SOVFM,
no matter how often it is called, or how many such markers appear in
the file.

=head2 Handling "implicit" virtual start-of-virtual-file markers

Sometimes an SOVFM is "implicit". That is, rather thanb being a
separate marker for the start of a virtual file, it is the first part
of the actual data of the virtual file. For example, consider the
following XML file:

        <DATA>
                <DESC>This is data set 1</DESC>
                <DATUM/>datum 1
                <DATUM/>datum 2
                <DATUM/>datum 3
        </DATA>
        <DATA>
                <DESC>This is data set 2</DESC>
                <DATUM/>datum 4
                <DATUM/>datum 5
                <DATUM/>datum 6
        </DATA>
        
Each of the C<E<lt>DATAE<gt>...E<lt>/DATAE<gt>> blocks could be treated
as a separate virtual file by specifying:

        @datasets = vf_load("data.xml", '<DATA>');
        
But this would cause the individual virtual files to contain invalid
XML, such as:

                <DESC>This is data set 1</DESC>
                <DATUM/>datum 1
                <DATUM/>datum 2
                <DATUM/>datum 3
        </DATA>

One can indicate that the nominated  SOVFMs are also part of the virtual files'
contents, by specifying the markers as a look-ahead pattern:

        @datasets = vf_load("data.xml", '(?=<DATA>)');
        
This causes C<vf_load> to identify the sequence C<E<lt>DATAE<gt>> as a
start-of-virtual-file marker but not consume it, thereby leaving it as
the initial sequence of the virtual file's content.

=head1 DIAGNOSTICS

=over 4

=item C<Could not vf_load '%s'>

The module could not open the specified disk file and read it in as a set of virtual files.

=item C<Unable to complete vf_save>

The module could not open the specified disk file and write it out as a
set of virtual files. A preceding warning may indicate which virtual
file caused the problem.

=item C<Virtual file not open for input>

An attempt was made to C<getline>, C<getc>, or C<read> a virtual file
that was opened for output only. (Warning only)

=item C<Virtual file not open for output>

An attempt was made to C<print> or C<printf> a virtual file that was
opened for input only. (Warning only)

=back

=head1 AUTHOR

Damian Conway  (damian@conway.org)

=head1 EVIL GENIUS WHO MADE HIM DO IT

Brian Ingerson (INGY@cpan.org)

=head1 COPYRIGHT

Copyright (c) 2001. Damian Conway. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
