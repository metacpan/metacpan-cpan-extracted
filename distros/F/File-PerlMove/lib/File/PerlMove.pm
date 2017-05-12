#!/usr/bin/perl -w

package File::PerlMove;

# Author          : Johan Vromans
# Created On      : Tue Sep 15 15:59:04 1992
# Last Modified By: Johan Vromans
# Last Modified On: Mon Apr 24 10:04:57 2017
# Update Count    : 177
# Status          : Unknown, Use with caution!

################ Common stuff ################

our $VERSION = "1.01";

use strict;
use warnings;
use Carp;
use File::Basename;
use File::Path;

sub move {
    my $transform = shift;
    my $filelist  = shift;
    my $options   = shift || {};
    my $result    = 0;

    croak("Usage: ", __PACKAGE__, "::move(" .
	  "operation, [ file names ], { options })")
      unless defined $transform && defined $filelist;

    # For those who misunderstood the docs.
    $options->{showonly}   ||= delete $options->{'dry-run'};
    $options->{createdirs} ||= delete $options->{'create-dirs'};

    # Create transformer.
    $transform = build_sub($transform)
      unless ref($transform) eq 'CODE';

    # Process arguments.
    @$filelist = reverse(@$filelist) if $options->{reverse};
    foreach ( @$filelist ) {
	# Save the name.
	my $old = $_;
	# Perform the transformation.
	$transform->();
	# Get the new name.
	my $new = $_;

	# Anything changed?
	unless ( $old eq $new ) {

	    # Create directories.
	    if ( $options->{createdirs} ) {
		my $dir = dirname($new);
		unless ( -d $dir ) {
		    if ( $options->{showonly} ) {
			warn("[Would create: $dir]\n");
		    }
		    else {
			mkpath($dir, $options->{verbose}, 0777);
		    }
		}
	    }

	    # Dry run.
	    if ( $options->{verbose} || $options->{showonly} ) {
		warn("$old => $new\n");
		next if $options->{showonly};
	    }

	    # Check for overwriting target.
	    if ( ! $options->{overwrite} && -e $new ) {
		warn("$new: exists\n");
		next;
	    }

	    # Perform.
	    my $res = -1;
	    if ( $options->{symlink} ) {
		$res = symlink($old, $new);
	    }
	    elsif ( $options->{link} ) {
		$res = link($old, $new);
	    }
	    else {
		$res = rename($old, $new);
	    }
	    if ( $res == 1 ) {
		$result++;
	    }
	    else {
		# Force error numbers (for locale independency).
		warn($options->{errno}
		     ? "$old: ".(0+$!)."\n"
		     : "$old: $!\n");
	    }
	}
    }

    $result;
}

sub build_sub {
    my $cmd = shift;
    # Special treatment for some.
    if ( $cmd =~ /^(uc|lc|ucfirst)$/ ) {
	$cmd = '$_ = ' . $cmd;
    }
    elsif ( $cmd =~ /^:(.+):(.+):$/ ) {
	require Encode;
	$cmd = 'Encode::from_to($_,"'.$1.'","'.$2.'")';
    }

    # Build subroutine.
    my $op = eval "sub { $cmd }";
    if ( $@ ) {
	$@ =~ s/ at \(eval.*/./;
	croak($@);
    }

    return $op;
}

1;

__END__

=head1 NAME

File::PerlMove - Rename files using Perl expressions

=head1 SYNOPSIS

  use File::PerlMove;
  File::PerlMove::move(sub { $_ = lc }, \@filelist, { verbose => 1 });

=head1 DESCRIPTION

File::PerlMove provides a single subroutine: B<File::PerlMove::move>.

B<move> takes three arguments: transform, filelist, and options.

I<transform> must be a string or a code reference. If it is not a
string, it is assumed to be a valid Perl expression that will be
turned into a anonymous subroutine that evals the expression. If the
expression is any of C<uc>, C<lc>, of C<ucfirst>, the resultant code
will behave as if these operations would modify C<$_> in-place.
Note, however, that using any of these operations is useless on file
systems that are case insensitive, like MS Windows and Mac.

When I<transform> is invoked it should transform a file name in C<$_>
into a new file name.

I<filelist> must be an array reference containing the list of file
names to be processed.

I<options> is a hash reference containing options to the operation.

Options are enabled when set to a non-zero (or otherwise 'true')
value. Possible options are:

=over 8

=item B<showonly>

Show the changes, but do not rename the files.

=item B<link>

Link instead of rename.

=item B<symlink>

Symlink instead of rename. Note that not all platforms support symlinking,

=item B<reverse>

Process the files in reversed order.

=item B<overwrite>

Overwrite existing files.

=item B<createdirs>

Create target directories if necessary.

=item B<verbose>

More verbose information.

=back

=head1 EXPORTS

None.

=head1 EXAMPLES

See B<pmv> for examples.

=head1 AUTHOR

Johan Vromans <jvromans@squirrel.nl>

=head1 SEE ALSO

App::perlmv (and perlmv), File::Rename (and rename).

=head1 COPYRIGHT

This programs is Copyright 2004,2010,2017 Squirrel Consultancy.

This program is free software; you can redistribute it and/or modify
it under the terms of the Perl Artistic License or the GNU General
Public License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

=cut
