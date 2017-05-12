package File::DirList;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use File::DirList ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.05';

use DirHandle;
use Cwd;

my %sortSubs = ();

$sortSubs{'s'} = sub {    $_[0]->[7]   <=>    $_[1]->[7];   };
$sortSubs{'S'} = sub {    $_[1]->[7]   <=>    $_[0]->[7];   };
$sortSubs{'a'} = sub {    $_[0]->[8]   <=>    $_[1]->[8];   };
$sortSubs{'A'} = sub {    $_[1]->[8]   <=>    $_[0]->[8];   };
$sortSubs{'m'} = sub {    $_[0]->[9]   <=>    $_[1]->[9];   };
$sortSubs{'M'} = sub {    $_[1]->[9]   <=>    $_[0]->[9];   };
$sortSubs{'c'} = sub {    $_[0]->[10]  <=>    $_[1]->[10];  };
$sortSubs{'C'} = sub {    $_[1]->[10]  <=>    $_[0]->[10];  };
$sortSubs{'n'} = sub {    $_[0]->[13]  cmp    $_[1]->[13];  };
$sortSubs{'N'} = sub {    $_[1]->[13]  cmp    $_[0]->[13];  };
$sortSubs{'i'} = sub { uc($_[0]->[13]) cmp uc($_[1]->[13]); };
$sortSubs{'I'} = sub { uc($_[1]->[13]) cmp uc($_[0]->[13]); };
$sortSubs{'d'} = sub {    $_[1]->[14]  <=>    $_[0]->[14];  };
$sortSubs{'D'} = sub {    $_[0]->[14]  <=>    $_[1]->[14];  };


my $statFile = sub
	{
	return [lstat($_[0].'/'.$_[1]),
		    $_[1],
		    (-d _ ? (($_[1] eq '..') ? 2 : (($_[1] eq '.') ? 3 : 1)) : 0),
		    0,
		    undef
		   ];
	};

my $statLink = sub
	{
	my $res = &{$statFile}(@_);

	if (-l _)
		{
		$res->[16] = readlink($_[0].'/'.$_[1]);
		if (-e $res->[16])
			{
			$res->[15] = 1;
			(@{$res}[0..12]) = stat(_);
			$res->[14] = -d _;
			$res->[15] = 1;
			}
		else
			{
			$res->[15] = -1;
			};
		};
	return $res;
	};

sub sortList($$)
	{
	my @sortMode = split(//, $_[1]);
	my @result = sort {my $r = 0;
	                   foreach my $m (@sortMode)
	                       {
	                       if (($r = &{$sortSubs{$m}}($a, $b)) != 0)
	                           { last; };
	                       };
	                   $r; 
	                  } @{$_[0]};

	return \@result;
	};

sub list($$@)
	{
	my ($dirName, $sortMode, $noLinks, $hideDotFiles, $showSelf) = @_;

	my @list  = ();

	my $d = DirHandle->new($dirName);

	if (!defined($d))
		{ return undef; };

	my $cwd = getcwd;
	chdir($dirName);

	my $statSub = $noLinks ? $statFile : $statLink;

	while (defined(my $entry = $d->read()))
		{
		if ((($entry eq '.') && !$showSelf) || ($hideDotFiles && ($entry =~ m/^\../) && ($entry ne '..')))
			{ next; };

		push(@list,  &{$statSub}($dirName, $entry));
		};
	
	undef $d;

	chdir($cwd);

	return sortList(\@list, $sortMode);
	};

# Preloaded methods go here.

1;
__END__

=head1 NAME

File::DirList - provide a sorted list of directory content

I<Version 0.04>

=head1 SYNOPSIS

    use File::DirList;
    #
    my @list = File::DirList::list('.', 'dn', 1, 0);

=head1 DESCRIPTION

This module is used to get a list of directory content.
It is a simple wrapper around L<DirHandle> and L<sort()>

The module has two methods:

=over 4

=item C<list($dirName, $sortMode, $noLinks, $hideDotFiles, $showSelf)>

Produces a list, accepting 5 parameters:

=over 4

=item C<$dirName>

Name of the directory to list

=item C<$sortMode>

Describes how list should be sorted.

This is a string containing the following symbols, with uppercase representing the reverse sort:

=over 4

=item C<d> or C<D>

"Directory" sort. C<'d'> means all the directories will precede files, C<'D'> means reverse.

=item C<n> or C<N>

Sort by file (or subdirectory) name.

=item C<i> or C<I>

Same as C<'n'> but case insensitive.

=item C<m> or C<M>

Sort by modification time.

=item C<c> or C<C>

Sort by creation time.

=item C<a> or C<A>

Sort by access time.

=item C<s> or C<S>

Sort by size.

=back

L<$sortMode> is interpreted from left to right. If the first comparison produces an equal result
next one is used. For example, string C<I<'din'>> produces a list with all the directories preceding files,
directories and files are sorted by name case insensitively, with lowercase letters preceding upper case.

=item C<$noLinks>

If C<true> symbolic links will not be examined. Set it on platforms without symlink support.

=item C<$hideDotFiles>

If C<true> I<'dot'> files will not be reported.

=item C<$showSelf>

If C<true> I<'.'> directory entry will be reported.

=back

Returned value is an array reference, sorted as described by L<$sortMode>.

Array elements are array references representing an item.

The individual item's array contains 17 elements:

=over 4

=item C<[0..12]>

Result of L<stat()> for this item. For valid symbolic links, the L<stat> of the target item is returned.

=item C<[13]>

Name of the item.

=item C<[14]>

Is item a directory? Contains 0 for non-directory items, 1 for directories, 2 for C<'..'>, 3 for C<'.'>.
Used by L<d or D> sorting.

=item C<[15]>

Is item a link? C<0> for non-links, C<1> for valid links, C<-1> for invalid links.

=item C<[16]>

Link target. C<I<undef>> for non-links, target path for links.

=back

L<[15]> and L<[16]> are set to non-link if L<$examineLinks> is C<false>.

=item C<sortList($list, $sortMode)>

Used to re-sort a list produced by C<list()>

Parameters are

=over 4

=item C<$lis>

Reference to a list produced by C<list()>

=item C<$sortMode>

Sorting rules.

=back

Return value is similar to C<list()>

=back

=head2 EXPORT

None by default

=head1 SEE ALSO

L<DirHandle>, L<stat>, L<lstat>, L<sort>

=head1 AUTHOR

Daniel Podolsky, E<lt>tpaba@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Daniel Podolsky, E<lt>tpaba@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
