package Inline::Files;
$VERSION = '0.69';
use strict;

use Inline::Files::Virtual;
use Filter::Util::Call;
use Cwd qw(abs_path);
use Carp;

my $SOVFM_pat = qr/^__[A-Z](?:_*[A-Z0-9]+)*__\n/m;
my %files;

sub import {
    DEBUG && TRACE(@_);
    $DB::single = 1;
    my ($class, @args) = @_;
    my ($package, $file, $line) = caller;

    my $path = './';
    $file =~ s|\\|/|g;
    ($path, $file) = ($1, $2) if $file =~ m|^(.*)/(.*)$|;
    $file = abs_path($path) . "/$file";
    $files{$package} = $file;

    while (@args) {
	my $next = shift @args;
	if ($next eq '-backup') {
		my $backup = shift(@args)||"$file.bak";
		local (*IN, *OUT);
		open IN, $file and open OUT, ">$backup" and
		print OUT <IN> and
		close IN and close OUT
			or croak "Cannot make backup of '$file'\n($!)";
	}
	else { croak "usage: use $class [-backup [=> 'filename']]" }
    }

    my (%symbols, $source);
    foreach my $vfile (vf_load($file, $SOVFM_pat)) {
        my $symbol = vf_marker($vfile);
        $symbol =~ s/^__|__\n//g;
        push @{$symbols{$symbol}}, $vfile;
    }

    foreach my $symbol (keys %symbols) {
        no strict 'refs';
        my $fq_symbol = "${package}::${symbol}";
        @$fq_symbol = @{$symbols{$symbol}};
        $$fq_symbol = $symbols{$symbol}[0];
        my $impl = tie *$fq_symbol, $class, $fq_symbol, -w $file;
	tie %$fq_symbol, $class."::Data", $impl;
    }

    foreach (qw( open close seek tell truncate write )) {
        no strict 'refs';
        *{"CORE::GLOBAL::$_"} = \&{"vf_$_"};
    }

    ($source = vf_prefix($file)) =~ s/(.*\n){$line}//;
    filter_add( sub {
        return 0 unless $source;
        $_ = $source;
        $source = "";
        return 1;
    } );
}

sub TIEHANDLE {
    DEBUG && TRACE(@_);
    my ($class, $symbol, $writable) = @_;
    bless { symbol => $symbol, writable => $writable }, $class;
}

sub STORE {
    DEBUG && TRACE(@_);
}

sub DESTROY {
    DEBUG && TRACE(@_);
}

sub AUTOLOAD {
    DEBUG && TRACE(@_) && 
      print "AUTOLOAD => $Inline::Files::AUTOLOAD\n";
    no strict;
    local $^W;
    my $impl = shift;
    my $symbol = $impl->{symbol};
    untie *$symbol;
    $$symbol = shift @$symbol;
    return unless $$symbol;
    my $open_mode = $impl->{writable} ? "+<" : "<";
    vf_open $symbol, "$open_mode$$symbol", $symbol  or return;
    croak "Internal error" unless tied *$symbol;
    $AUTOLOAD =~ s/.*:://;
    local $Carp::CarpLevel = 1;
    return tied(*$symbol)->$AUTOLOAD(@_);
}

sub get_filename {
    DEBUG && TRACE(@_);
    $files{$_[0]} || "";
}

package Inline::Files::Data;
use Carp;
BEGIN {
    *DEBUG = \&Inline::Files::DEBUG;
    *TRACE = \&Inline::Files::TRACE;
}

sub access {     
    DEBUG && TRACE(@_);
    no strict 'refs'; 
    tied(*{$_[0]->{impl}{symbol}});
}
my %fetch = (
	     file     => sub { access($_[0])->{afile} },
	     line     => sub { access($_[0])->{vfile}{line}},
	     offset   => sub { access($_[0])->{vfile}{offset}},
	     writable => sub { $_[0]->{impl}{writable} },
	    );

my @validkeys = keys %fetch;
my $validkey = qr/${\join '|', @validkeys}/;

sub TIEHASH { 
    DEBUG && TRACE(@_);
    my ($class, $impl) = @_;
    bless { impl=>$impl, iter=>0 }, $class;
}

sub FETCH {
    DEBUG && TRACE(@_);
    my ($self, $key) = @_;
    return undef unless $key =~ $validkey;
    return $fetch{$key}->($self);
}

sub FIRSTKEY {
    DEBUG && TRACE(@_);
    return $validkeys[$_[0]->{iter} = 0]; 
}

sub NEXTKEY  { 
    DEBUG && TRACE(@_);
    return $validkeys[++$_[0]->{iter}]; 
}

sub EXISTS   { 
    DEBUG && TRACE(@_);
    return $_[1] =~ $validkey; 
}

sub DESTROY  {
    DEBUG && TRACE(@_);
}

sub AUTOLOAD { 
    DEBUG && TRACE(@_);
    croak "Cannot modify read-only hash";
}


1;

__END__

=head1 NAME

Inline::Files - Multiple virtual files at the end of your code

=head1 VERSION

This document describes version 0.69 of Inline::Files,
released June 24, 2015.

=head1 SYNOPSIS

    use Inline::Files;

    my Code $here;

    # etc.
    # etc.
    # etc.

    __FOO__
    This is a virtual file at the end
    of the data
    
    __BAR__
    This is another
    virtual

    file
    __FOO__
    This is yet another 
    such file


=head1 WARNING

It is possible that this module may overwrite the source code in files
that use it. To protect yourself against this possibility, you are
I<strongly> advised to use the C<-backup> option described in
L<"Safety first">.

This module is still experimental. Regardless of whether you use
C<-backup> or not, by using this module you agree that the authors will
b<under no circumstances> be responsible for any loss of data, code,
time, money, or limbs, or for any other disadvantage incurred as a
result of using Inline::Files.

=head1 DESCRIPTION

Inline::Files generalizes the notion of the C<__DATA__> marker and the
associated C<E<lt>DATAE<gt>> filehandle, to an arbitrary number of markers
and associated filehandles.

When you add the line:

    use Inline::Files;

to a source file you can then specify an arbitrary number
of distinct virtual files at the end of the code. Each such virtual
file is marked by a line of the form:

    __SOME_SYMBOL_NAME_IN_UPPER_CASE__

The following text -- up to the next such marker -- is treated as a
file, whose (pseudo-)name is available as an element of the package
array C<@SOME_SYMBOL_NAME_IN_UPPER_CASE>. The name of the first virtual
file with this marker is also available as the package scalar
C<$SOME_SYMBOL_NAME_IN_UPPER_CASE>.

The filehandle of the same name is magical -- just like C<ARGV> -- in
that it automatically opens itself when first read. Furthermore -- just
like C<ARGV> -- the filehandle re-opens itself to the next appropriate
virtual file (by C<shift>-ing the first element of
C<@SOME_SYMBOL_NAME_IN_UPPER_CASE> into
C<$SOME_SYMBOL_NAME_IN_UPPER_CASE>) whenever it reaches EOF.

So, just as with C<ARGV>, you can treat all the virtual files associated
with a single symbol either as a single, multi-part file:

    use Inline::Files;

    while (<FILE>) {
        print "$FILE: $_";
    }

    __FILE__
    File 1
    here

    __FILE__
    File 2
    here

    __OTHER_FILE__
    Other file 1

    __FILE__
    File 3
    here

or as a series of individual files:

    use Inline::Files;

    foreach $filename (@FILE) {
        open HANDLE, $filename;
        print "<<$filename>>\n";
        while (<HANDLE>) {
            print;
        }
    }

    __FILE__
    File 1
    here

    __FILE__
    File 2
    here

    __OTHER_FILE__
    Other file 1

    __FILE__
    File 3
    here

Note that these two examples completely ignore the lines:

    __OTHER_FILE__
    Other file 1

which would be accessed via the C<OTHER_FILE> filehandle.

Unlike C<E<lt>ARGVE<gt>>/C<@ARGV>/C<$ARGV>, Inline::Files also makes use of
the hash associated with an inline file's symbol. That is, when you create
an inline file with a marker C<__WHATEVER__>, the hash C<%WHATEVER> will
contain information about that file. That information is:

=over

=item C<$WHATEVER{file}>

The name of the disk file in which the inlined C<__WHATEVER__> files
were defined;

=item C<$WHATEVER{line}>

The line (starting from 1) at which the current inline C<__WHATEVER__>
file being accessed by C<E<lt>WHATEVERE<gt>> started.

=item C<$WHATEVER{offset}>

The byte offset (starting from 0) at which the current inline
C<__WHATEVER__> file being accessed by C<E<lt>WHATEVERE<gt>> started.

=item C<$WHATEVER{writable}>

Whether the the current inline file being accessed by
C<E<lt>WHATEVERE<gt>> is opened for output.

=back

The hash and its elements are read-only and the entry values are only
meaningful when the corresponding filehandle is open.


=head2 Writable virtual files

If the source file that uses Inline::Files is itself writable, then the
virtual files it contains may also be opened for write access. For
example, here is a very simple persistence mechanism:

    use Inline::Files;
    use Data::Dumper;

    open CACHE or die $!;   # read access (uses $CACHE to locate file)
    eval join "", <CACHE>;
    close CACHE or die $!;

    print "\$var was '$var'\n";
    while (<>) {
        chomp;
        $var = $_;
        print "\$var now '$var'\n";
    }

    open CACHE, ">$CACHE" or die $!;    # write access
    print CACHE Data::Dumper->Dump([$var],['var']);
    close CACHE or die $!;

    __CACHE__
    $var = 'Original value';

I<Unlike> C<ARGV>, if a virtual file is part of a writable file and is
automagically opened, it is opened for full read/write access. So the
above example, could be even simpler:

    use Inline::Files;
    use Data::Dumper;

    eval join "", <CACHE>;      # Automagically opened

    print "\$var was '$var'\n";
    while (<>) {
        chomp;
        $var = $_;
        print "\$var now '$var'\n";
    }

    seek CACHE, 0, 0;
    print CACHE Data::Dumper->Dump([$var],['var']);

    __CACHE__
    $var = 'Original value';


In either case, the original file is updated only at the end of
execution, on an explicit C<close> of the virtual file's handle, or when
C<Inline::Files::Virtual::vf_save> is explicitly called.

=head2 Creating new Inline files on the fly.

You can also open up new Inline output files at run time. Simply use the open function with a valid new Inline file handle name and B<no> file name. Like this:

    use Inline::Files;

    open IFILE, '>';

    print IFILE "This line will be placed into a new Inline file\n";
    print IFILE "which is marked by '__IFILE__'\n";


=head2 Safety first

Because Inline::Files handles are often read-write, it's possible to
accidentally nuke your hard-won data. But Inline::Files can save you
from yourself.

If Inline::Files is loaded with the C<-backup> option:

    use Inline::Files -backup;

then the source file that uses it is backed up before the inline files are
extracted. The backup file is the name of the source file with the suffix
".bak" appended.

You can also specify a different name for the backup file, by associating that
name with the C<-backup> flag:

    use Inline::Files -backup => '/tmp/sauve_qui_peut';


=head1 SEE ALSO

The Inline::Files::Virtual module

The Filter::Util::Call module

=head2 BUGS ADDED BY

Alberto Simoes  (ambs@cpan.org)

=head1 UNWITTING PAWN OF AN AUTHOR

Damian Conway  (damian@conway.org)

=head1 EVIL MASTERMIND BEHIND IT ALL

Brian Ingerson (INGY@cpan.org)

=head1 COPYRIGHT

Copyright (c) 2001-2009. Damian Conway. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
