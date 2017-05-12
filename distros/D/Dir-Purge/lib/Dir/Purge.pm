# Dir::Purge.pm -- Purge directories
# RCS Info        : $Id: Purge.pm,v 1.6 2006/09/19 12:24:01 jv Exp $
# Author          : Johan Vromans
# Created On      : Wed May 17 12:58:02 2000
# Last Modified By: Johan Vromans
# Last Modified On: Tue Sep 19 14:23:56 2006
# Update Count    : 161
# Status          : Unknown, Use with caution!

# Purge directories by strategy.
#
# This is also an exercise in weird programming techniques.

package Dir::Purge;

use strict;
use Carp;

use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
$VERSION    = "1.02";
@ISA        = qw(Exporter);
@EXPORT     = qw(&purgedir);
@EXPORT_OK  = qw(&purgedir_by_age);

my $purge_by_age;		# strategy

sub purgedir_by_age {
    my @dirs = @_;
    my $opts;
    if ( UNIVERSAL::isa ($dirs[0], 'HASH') ) {
	$opts = shift (@dirs);
	my $strat = delete $opts->{strategy};
	if ( defined $strat && $strat ne "by_age" ) {
	    croak ("Invalid option: 'strategy'");
	}
	$opts->{strategy} = "by_age";
    }
    else {
	$opts = { keep => shift(@dirs), strategy => "by_age" };
    }
    purgedir ($opts, @dirs);
}


# Common processing code. It verifies the arguments, directories and
# calls $code->(...) to do the actual purging.
# Nothing is done if any of the verifications fail.

sub purgedir {

    my (@dirs) = @_;
    my $error = 0;
    my $code = $purge_by_age;	# default: by age
    my $ctl = { tag => "purgedir" };
    my @opts = qw(keep strategy reverse include verbose test debug);

    # Get the parameters. Only the 'keep' value is mandatory.
    if ( UNIVERSAL::isa ($dirs[0], 'HASH') ) {
	my $opts  = shift (@dirs);
	@{$ctl}{@opts} = delete @{$opts}{@opts};
	if ( $ctl->{strategy} ) {
	    if ( $ctl->{strategy} eq "by_age" ) {
		$code = $purge_by_age;
	    }
	    else {
		carp ("Unsupported purge strategy: '$ctl->{strategy}'");
		$error++;
	    }
	}
	foreach (sort keys %$opts) {
	    carp ("Unhandled option \"$_\"");
	    $error++;
	}
    }
    elsif ( $dirs[0] =~ /^-?\d+$/ ) {
	$ctl->{keep} = shift (@dirs);
    }

    unless ( $ctl->{keep} ) {
	croak ("Missing 'keep' value");
    }
    elsif ( $ctl->{keep} < 0 ) {
	# Hmm. I would like to deprecate this, but on the other hand,
	# a negative 'subscript' fits well in Perl.
	#carp ("Negative 'keep' value is deprecated, ".
	#      "use 'reverse => 1' instead");
	$ctl->{keep} = -$ctl->{keep};
	$ctl->{reverse} = !$ctl->{reverse};
    }

    $ctl->{verbose} = 1 unless defined ($ctl->{verbose});
    $ctl->{verbose} = 9 if $ctl->{debug};

    if ( $ctl->{include} ) {
	if ( !ref($ctl->{include}) ) {
	    croak("Invalid value for 'include': " . $ctl->{include});
	}
	elsif ( UNIVERSAL::isa($ctl->{include}, 'CODE') ) {
	    # OK
	}
	elsif ( UNIVERSAL::isa($ctl->{include}, 'Regexp') ) {
	    my $pat = $ctl->{include};
	    $ctl->{include} = sub { $_[0] =~ $pat };
	}
	else {
	    croak("Invalid value for 'include': " . $ctl->{include});
	}
    }

    # Thouroughly check the directories, and refuse to do anything
    # in case of problems.
    warn ("$ctl->{tag}: checking directories\n") if $ctl->{verbose} > 1;
    foreach my $dir ( @dirs ) {
	# Must be a directory.
	unless ( -d $dir ) {
	    carp (-e _ ? "$dir: not a directory" : "$dir: not existing");
	    $error++;
	    next;
	}
	# We need write access since we are going to delete files.
	unless ( -w _ ) {
	    carp ("$dir: no write access");
	    $error++;
	}
	# We need read access since we are going to get the file list.
	unless ( -r _ ) {
	    carp ("$dir: no read access");
	    $error++;
	}
	# Probably need this as well, don't know.
	unless ( -x _ ) {
	    carp ("$dir: no access");
	    $error++;
	}
    }

    # If errors, bail out unless testing.
    if ( $error ) {
	if ( $ctl->{test} ) {
	    carp ("$ctl->{tag}: errors detected, continuing");
	}
	else {
	    croak ("$ctl->{tag}: errors detected, nothing done");
	}
    }

    # Process the directories.
    foreach my $dir ( @dirs ) {
	$code->($ctl, $dir);
    }
};

# Everything else is assumed to be small building-block routines to
# implement a plethora of purge strategies.
# Actually, I cannot think of any right now.

# Gather file names and additional info.
my $gather = sub {
    my ($ctl, $dir, $what) = @_;

    local (*DIR);
    opendir (DIR, $dir)
      or croak ("dir: $!");	# shouldn't happen -- we've checked!
    my @files;
    foreach ( readdir (DIR) ) {
	next if $ctl->{include} && !$ctl->{include}->($_, $dir);
	next if /^\./;
	next unless -f "$dir/$_";
	push (@files, [ "$dir/$_", $what->("$dir/$_") ]);
    }
    closedir (DIR);

    warn ("$ctl->{tag}: $dir: ", scalar(@files), " files\n")
      if $ctl->{verbose} > 1;
    warn ("$ctl->{tag}: $dir: @{[map { $_->[0] } @files]}\n")
      if $ctl->{debug};

    \@files;
};

# Sort the list on the supplied info.
my $sort = sub {
    my ($ctl, $files) = @_;

    my @sorted = map { $_->[0] } sort { $a->[1] <=> $b->[1] } @$files;
    warn ("$ctl->{tag}: sorted: @sorted\n") if $ctl->{debug};
    \@sorted;
};

# Remove the files to keep from the list.
my $reduce = sub {
    my ($ctl, $files) = @_;

    if ( $ctl->{reverse} ) {
	# Keep the newest files (tail of the list).
	splice (@$files, @$files-$ctl->{keep}, $ctl->{keep});
    }
    else {
	# Keep the oldest files (head of the list).
	splice (@$files, 0, $ctl->{keep});
    }
    $files;
};

# Remove the files in the list.
my $purge = sub {
    my ($ctl, $files) = @_;

    # Remove the selected files.
    foreach ( @$files ) {
	if ( $ctl->{test} ) {
	    warn ("$ctl->{tag}: candidate: $_\n");
	}
	else {
	    warn ("$ctl->{tag}: removing $_\n") if $ctl->{verbose};
	    unlink ($_) or carp ("$_: $!");
	}
    }
};

# Processing routine: purge by file age.
$purge_by_age = sub {
    my ($ctl, $dir) = @_;

    warn ("$ctl->{tag}: purging directory $dir (by age, keep $ctl->{keep})\n")
      if $ctl->{verbose} > 1;

    # Gather, with age info.
    my $files = $gather->($ctl, $dir, sub { -M _ });

    # Is there anything to do?
    if ( @$files <= $ctl->{keep} ) {
	warn ("$ctl->{tag}: $dir: below limit\n") if $ctl->{verbose} > 1;
	return;
    }

    # Sort, reduce and purge.
    $purge->($ctl, $reduce->($ctl, $sort->($ctl, $files)));
};

1;

__END__

=head1 NAME

Dir::Purge - Purge directories to a given number of files.

=head1 SYNOPSIS

  perl -MDir::Purge -e 'purgedir (5, @ARGV)' /spare/backups

  use Dir::Purge;
  purgedir ({keep => 5, strategy => "by_age", verbose => 1}, "/spare/backups");

  use Dir::Purge qw(purgedir_by_age);
  purgedir_by_age (5, "/spare/backups");

=head1 DESCRIPTION

Dir::Purge implements functions to reduce the number of files in a
directory according to a strategy. It currently provides one strategy:
removal of files by age.

By default, the module exports one user subroutine: C<purgedir>.

The first argument of C<purgedir> should either be an integer,
indicating the number of files to keep in each of the directories, or
a reference to a hash with options. In either case, a value for the
number of files to keep is mandatory.

The other arguments are the names of the directories that must be
purged. Note that this process is not recursive. Also, hidden files
(name starts with a C<.>) and non-plain files (e.g., directories,
symbolic links) are not taken into account.

All directory arguments and options are checked before anything else
is done. In particular, all arguments should point to existing
directories and the program must have read, write, and search
(execute) access to the directories.

One additional function, C<purgedir_by_age>, can be exported on
demand, or called by its fully qualified name. C<purgedir_by_age>
calls C<purgedir> with the "by age" purge strategy preselected. Since
this happens to be the default strategy for C<purgedir>, calling
C<purgedir_by_age> is roughly equivalent to calling C<purgedir>.

=head1 WARNING

Removing files is a quite destructive operation. Supply the C<test>
option, described below, to dry-run before production.

=head1 OPTIONS

Options are suppled by providing a hash reference as the first
argument. The following calls are equivalent:

  purgedir ({keep => 3, test => 1}, "/spare/backups");
  purgedir_by_age ({keep => 3, test => 1}, "/spare/backups");
  purgedir ({strategy => "by_age", keep => 3, test => 1}, "/spare/backups");

All subroutines take the same arguments.

=over 4

=item keep

The number of files to keep.
A negative number will reverse the strategy. See option C<reverse> below.

=item strategy

Specifies the purge strategy.
Default (and only allowed) value is "by_age".

This option is for C<purgedir> only. The other subroutines should not
be provided with a C<strategy> option.

=item include

If this is a reference to a subroutine, this subroutine is called with
arguments ($file,$dir) and must return true for the file to be
included in the list of candidates,

If this is a regular expression, the file file will be included only
if the expression matches the file name.

=item reverse

If true, the strategy will be reversed. For example, if the strategy
is "by_age", the oldest files will be kept instead of the newest
files.

Another way to reverse the strategy is using a negative C<keep> value.
This is not unlike Perl's array subscripts, which count from the end if
negative.

A negative C<keep> value can be combined with C<reverse> to reverse
the reversed strategy again.

=item verbose

Verbosity of messages. Default value is 1, which will report the names
of the files being removed. A value greater than 1 will produce more
messages about what's going on. A value of 0 (zero) will suppress
messages.

=item debug

For internal debugging only.

=item test

If true, no files will be removed. For testing.

=back

=head1 EXPORT

Subroutine C<purgedir> is exported by default.

Subroutine C<purgedir_by_age> may be exported on demand.

Calling purgedir_by_age() is roughly equivalent to calling purgedir()
with an options hash that includes C<strategy => "by_age">.

The variable $Dir::Purge::VERSION may be used to inspect the version
of the module.

=head1 AUTHOR

Johan Vromans (jvromans@squirrel.nl) wrote this module.

=head1 COPYRIGHT AND DISCLAIMER

This program is Copyright 2000 by Squirrel Consultancy. All rights
reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either: a) the GNU General Public License as
published by the Free Software Foundation; either version 1, or (at
your option) any later version, or b) the "Artistic License" which
comes with Perl.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See either the
GNU General Public License or the Artistic License for more details.

=cut
