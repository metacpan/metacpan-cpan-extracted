package File::CachingFind;
#
# Copyright 2002 Thomas Dorner
#
# Author: see end of file
# Created: 9. April 2002
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

=head1 NAME

File::CachingFind - find files within cached search paths (e.g. include files)

=head1 SYNOPSIS

    use File::CachingFind;

    $includes = File::CachingFind->new(Path => ['/usr/local/include',
						'/usr/include']);
    $stdio = $includes->findFirstInPath('stdio.h');


=head1 DESCRIPTION

C<File::CachingFind> is useful for repeated file searches within a
path of directories.  It caches the contents of its search and
supports two different methods of fuzzy search, a normalize function
and regular expressions.  See the different METHODS for details.

=head1 METHODS

=over 4

=cut

#########################################################################

require 5.006;
use strict;
use warnings;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = '0.67';

use Carp;
use Cwd 'abs_path';
use DirHandle;

#########################################################################

=item B<new> - create a new File::CachingFind object

    $obj = File::CachingFind->new(Path =>
				      $reference_to_list_of_directories,
				  Normalize => $reference_to_function,
				  Filter => $regular_expression,
				  NoSoftlinks => $true_or_false);

Example:

    $win32_includes =
	File::CachingFind->new
	(Path =>
	     ['.!', '/cygdrive/C/Programme/DevStudio/VC/include'],
	 Normalize => sub{lc @_},
	 Filter => '\.h$');

This is the constructor for a cache to the filenames of one or more
directories.  It has one mandatory and three optional parameters.  The
cache build is a hash using the normalized filename without any
directory parts in it as a key for retrieval.  Each key of course can
point to one or more real, full filenames.

=over 4

=item B<    Path>

is the mandatory parameter.  It must contain a reference to list of
directories.  Both relative and absolute paths are possible.  Normally
the directory itself and all its subdirectories are cached.  If the
directory name is followed by (ends with) an exclamation mark, the
subdirectories are ignored.

=item B<    Normalize>

is an optional code reference.  The function referenced to must take
exactly one string parameter (the filename withot its directory parts)
as input and returns the string in a normalized fashion.  If this
result is not the empty string it's used as key for the cache
(otherwise the filename is ignored).  If no code reference is given,
the unmodified filename is used as key for the cache.

=item B<    Filter>

is an optional regular expression used for caching only certain files
of the directories (those matching the regular expression).  If no
filter is given, every file is cached.

=item B<    NoSoftlinks>

is an optional flag telling if the caching of softlinks should be
inhibited.  Normally the names of ordinary files as well as the name
of softlinks are cached.  Set the flag to true, if this is not wanted.

=back

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub new
{
    my $this = shift;
    my $class = ref($this) || $this;
    my %newObject = ();
    local $_;

    # clone object (if applicable):
    if (ref($this))
    {
	$newObject{Path} = $this->{Path};
	$newObject{Norm} = $this->{Norm};
	$newObject{Filter} = $this->{Filter};
	$newObject{NoLink} = $this->{NoLink};
    }

    # analyze parameters:
    my %args = @_;
    foreach (keys %args)
    {
	if (/^Path$/i)
	{
	    croak $_, ' is not a reference to an array'
		unless 'ARRAY' eq ref($args{$_});
	    $newObject{Path} = $args{$_};
	}
	elsif (/^Normali[zs]e$/i)
	{
	    croak $_, ' is not a reference to a function'
		unless 'CODE' eq ref($args{$_});
	    $newObject{Norm} = $args{$_};
	}
	elsif (/^Filter$/i)
	{
	    croak $_, ' is not scalar' unless '' eq ref($args{$_});
	    $newObject{Filter} = $args{$_};
	}
	elsif (/^NoSoftlinks$/i)
	{
	    croak $_, ' is not scalar' unless '' eq ref($args{$_});
	    $newObject{NoLink} = $args{$_};
	}
	else
	{
	    croak 'unknown parameter ', $_, ' passed to ', __PACKAGE__;
	}
    }

    # check for completeness:
    croak 'no path defined' unless defined $newObject{Path};

    # cache files with full names and priorities in object:
    my %fullname = ();
    $newObject{Fullname} = \%fullname;
    my %priority = ();
    $newObject{Priority} = \%priority;
    my $priority = 0;
    foreach (@{$newObject{Path}})
    {
	my $recursive = ! s/!$//; # handle no-recursive flag
	next unless -d $_;
	_parse_directory(\%newObject, abs_path($_), $recursive, ++$priority);
    }

    # now we're finished:
    bless \%newObject, $class;
}


#########################################################################

=item B<findInPath> - locate all files with a given (normalized) name

    @list = $obj->findInPath($a_file_name);

Example:

    @time_h = $includes->findInPath('time.h');

This method returns all full filenames (including the directory parts)
of all files in the cache of the object, which have the same
normalized filename as the parameter passed to this method.  The
parameter itself will be normalized as well before comparizion.

On a standard Unix system the list in aboves example should at least
contain /usr/include/time.h and /usr/include/sys/time.h, provided
$includes is similar to the one defined at the very beginning of this
documentation.

If no file is found, an empty list is returned.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub findInPath
{
    my ($this, $name) = @_;
    # apply normalization:
    $name = &{$this->{Norm}}($name) if $this->{Norm};
    # return list:
    if (! defined $this->{Fullname}->{$name})
    {
	return ();
    }
    elsif ('' eq ref($this->{Fullname}->{$name}))
    {
	return ($this->{Fullname}->{$name});
    }
    elsif ('ARRAY' eq ref($this->{Fullname}->{$name}))
    {
	return @{$this->{Fullname}->{$name}};
    }
    else
    {
	confess('internal error in ', __PACKAGE__,
		'(please report this bug): unexpected reference type "',
		ref($this->{Fullname}->{$name}), '"');
    }
}

#########################################################################

=item B<findFirstInPath> - locate first file with a given (normalized) name

    @list = $obj->findFirstInPath($a_file_name);

Example:

    $includes2 =
	File::CachingFind->new(Path => ['/usr/include!',
					'/usr/include/sys!']);
    $time_h = $includes2->findFirstInPath('time.h');

This method returns the first full filename (including the directory
parts) of all files in the cache of the object.  The search is similar
to the one in the method B<findInPath>.  The function will search the
cache in the order of the paths given to the constructor (B<new>).

On a standard Unix system above example returns /usr/include/time.h.
A call to C<$includes-E<gt>findFirstInPath('time.h')> (see
B<findInPath>) would return either /usr/include/time.h or
/usr/include/sys/time.h (indeterministic).

If no file is found, undef is returned.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub findFirstInPath
{
    my ($this) = @_;
    my @list = findInPath(@_);
    return undef if 0 == @list;
    @list = sort {$this->{Priority}->{$a} <=> $this->{Priority}->{$b}} @list;
    return $list[0];
}

#########################################################################

=item B<findBestInPath> - locate best file with a given (normalized) name

    @list = $obj->findBestInPath($a_file_name,
				 $reference_to_comparison_function);

Example:

    $time_h =
	$includes2->findBestInPath
	    ('time.h',
	     sub{ length($_[1]) <=> length($_[0]) });

This method returns the best full filename (including the directory
parts) of all files in the cache of the object.  The search is similar
to the one in the method B<findInPath>.  All files found are compared
using the given comparision function (similar to comparision functions
given to sort, except that it uses real parameters).  If more than one
file remains, the order of the paths given to the constructor (B<new>)
will be considered as well (as in B<findFirstInPath>).

On a standard Unix system above example returns
/usr/include/sys/time.h as it has a longer full filename than
/usr/include/time.h.

If no file is found, undef is returned.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub findBestInPath
{
    my ($this, $name, $rCompare) = @_;
    croak 'third parameter is not a reference to a function'
	unless 'CODE' eq ref($rCompare);
    my @list = findInPath($this, $name);
    return undef if 0 == @list;
    @list =
	sort {
	    my $order = &$rCompare($a, $b);
	    return
		$order != 0 ? $order :
		    $this->{Priority}->{$a} <=> $this->{Priority}->{$b}
	} @list;
    return $list[0];
}

#########################################################################

=item B<findMatch> - locate all files matching a regular expression

    @list = $obj->findMatch($regular_expression);

Example:

    @std_h = $includes2->findMatch('^(?i:std)');

This method returns all full filenames (including the directory parts)
of all files in the cache of the object, which match the given regular
expression.  Note, that the regular expression won't be normalized,
I<you> have to make sure that it matches the normalized filenames.

On a standard Unix system the list in aboves example should at least
contain /usr/include/stdio.h and /usr/include/stdlib.h, provided
$includes2 is similar to the used in prior examples.  Your mileage may
vary, especially on different systems.  Note that the example uses a
case insensitive match.

If no file is found, an empty list is returned.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub findMatch
{
    my ($this, $regexp) = @_;
    my @result = ();
    # loop all files:
    while (my ($name, $files) = each %{$this->{Fullname}})
    {
	next unless $name =~ m/$regexp/;
	if ('' eq ref($files))		{ push @result, $files; }
	elsif ('ARRAY' eq ref($files))	{ push @result, @{$files}; }
	else
	{
	    confess('internal error in ', __PACKAGE__,
		    '(please report this bug): unexpected reference type "',
		    ref($files), '"');
	}
    }
    return @result;
}

#########################################################################

=item B<findFirstMatch> - locate first file matching a regular expression

    @list = $obj->findFirstMatch($regular_expression);

Example:

    $std_h = $includes2->findFirstMatch('^std');

This method returns the first full filename (including the directory
parts) of all files in the cache of the object matching the given
regular expression.  It works similar to B<FindFirstInPath> and will
search the cache in the order of the paths given to the constructor
(B<new>).  Thus it may be of limited use as the algorithm chosing
between more than one file of the same path is indeterministic.
B<findBestMatch> would be a better choice in most circumstances though
it is a bit slower most of the times.

On a standard Unix system above example returns /usr/include/stdio.h
or /usr/include/stdlib.h or another matching file (indeterministic).

If no file is found, undef is returned.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub findFirstMatch
{
    my ($this) = @_;
    my @list = findMatch(@_);
    return undef if 0 == @list;
    @list = sort {$this->{Priority}->{$a} <=> $this->{Priority}->{$b}} @list;
    return $list[0];
}

#########################################################################

=item B<findBestMatch> - locate best file matching a regular expression

    @list = $obj->findBestMatch($regular_expression,
				$reference_to_comparison_function);

Example:

    $std_h =
	$includes2->findBestMatch
	    ('^std',
	     sub{ length($_[0]) <=> length($_[1]) });

This method returns the best full filename (including the directory
parts) of all files in the cache of the object matching the given
regular expression.  As in B<findBestInPath> all files found are
compared using the given comparision function followed by the order of
the paths given to the constructor (B<new>).

On a standard Unix system above example returns /usr/include/stdio.h
unless there is another include with an even shorter name beginning
with /usr/include/std.

If no file is found, undef is returned.

=cut

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub findBestMatch
{
    my ($this, $regexp, $rCompare) = @_;
    croak 'third parameter is not a reference to a function'
	unless 'CODE' eq ref($rCompare);
    my @list = findMatch($this, $regexp);
    return undef if 0 == @list;
    @list =
	sort {
	    my $order = &$rCompare($a, $b);
	    return
		$order != 0 ? $order :
		    $this->{Priority}->{$a} <=> $this->{Priority}->{$b}
	} @list;
    return $list[0];
}

#########################################################################
#########################################################################
#########	internal methods / functions following		#########
#########################################################################
#########################################################################

#########################################################################
# call:					(recursive, only used in new)	#
#	_parse_directory($rNewObject, $directory, $recursive,		#
#			 $priority);					#
# parameters:								#
#	$rNewObject	reference to (yet) unblessed new object		#
#	$dir		directory (full absolute path!) to parse	#
#	$recursive	flag, if subdirectories should be parsed as well#
#	$priority	priority of the current path			#
# description:								#
#	The function parses the directory $directory and puts its	#
#	relevant filenames and directories into $rNewObject->{Fullname}.#
#	The priority is cached in $rNewObject->{Priority}.		#
# global variables used:						#
#	-								#
# returns:								#
#	-								#
#########################################################################
sub _parse_directory
{
    my ($rNewObject, $directory, $recursive, $priority) = @_;
    local $_;
    # loop directory:
    my $dirh = new DirHandle $directory;
    while (defined($_ = $dirh->read))
    {
	next if m/^\.\.?$/o;	# ignore . and ..
	my $fullname = $directory.'/'.$_;
	# handle directories:
	if (-d $fullname)
	{
	    _parse_directory($rNewObject, $fullname, $recursive, $priority)
		if $recursive;
	    next;
	}
	lstat $fullname;
	# filter non-files / non-links (if applicable):
	if (! -f _)
	{
	    next if -l _ and $rNewObject->{NoLink};
	}
	# apply filter:
	if (defined $rNewObject->{Filter})
	{
	    next unless m/$rNewObject->{Filter}/;
	}
	# apply normalization:
	$_ = &{$rNewObject->{Norm}}($_) if $rNewObject->{Norm};
	# put filename/fullname in cache:
	if (! defined $rNewObject->{Fullname}->{$_})
	{
	    $rNewObject->{Fullname}->{$_} = $fullname;
	}
	elsif ('' eq ref($rNewObject->{Fullname}->{$_}))
	{
	    $rNewObject->{Fullname}->{$_} =
		[ $rNewObject->{Fullname}->{$_}, $fullname ];
	}
	elsif ('ARRAY' eq ref($rNewObject->{Fullname}->{$_}))
	{
	    push @{$rNewObject->{Fullname}->{$_}}, $fullname;
	}
	else
	{
	    confess('internal error in ', __PACKAGE__,
		    '(please report this bug): unexpected reference type "',
		    ref($rNewObject->{Fullname}->{$_}), '"');
	}
	# cache priority:
	$rNewObject->{Priority}->{$fullname} = $priority;
    }
}

1;
__END__

=back

=head1 KNOWN BUGS

Directory names ending with an exclamation mark can't be handled yet!

Softlinks creating a cyclic directory structure will cause an infinite
loop.

If the same file is found more than once using different paths in the
constructor (B<new>), it will be cached more than once!  This is
considered a feature, not a bug.

=head1 SEE ALSO

perl(1).

=head1 AUTHOR

Thomas Dorner, E<lt>dorner (AT) cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2009 by Thomas Dorner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
