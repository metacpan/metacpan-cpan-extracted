#!/usr/bin/perl -w

package File::PerlMove;

# Author          : Johan Vromans
# Created On      : Tue Sep 15 15:59:04 1992
# Last Modified By: Johan Vromans
# Last Modified On: Tue Dec 15 14:59:21 2020
# Update Count    : 223
# Status          : Unknown, Use with caution!

################ Common stuff ################

our $VERSION = "2.01";

use strict;
use warnings;
use Carp;
use File::Basename;
use File::Path;
use parent qw(Exporter);

our @EXPORT = qw( pmv );

sub move {
    my $transform = shift;
    my $filelist  = shift;
    my $options   = shift || {};
    pmv( $transform, $filelist, { %$options, legacy => 1 } );
}

sub pmv {
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
    $transform = build_sub( $transform, $options )
      unless ref($transform) eq 'CODE';

    # Process arguments.
    @$filelist = reverse(@$filelist) if $options->{reverse};
    foreach ( @$filelist ) {
	# Save the name.
	my $old = $_;

	# Perform the transformation.
	my $new;
	if ( $options->{legacy}) {
	    # Legacy operates on $_.
	    $transform->();
	    $new = $_;
	}
	else {
	    $new = $transform->($_);
	}

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
    my ( $cmd, $options ) = @_;

    # If it is a verb, try extensions and builtins.
    # foo           File::PerlMove::foo => &File::PerlMove::foo::foo
    # foo=bar       File::PerlMove::foo => &File::PerlMove::foo::bar
    # xx::foo       xx::foo => &xx::foo::foo
    # xx::foo=bar   xx::foo => &xx::foo::bar
    if ( $cmd =~ /^((?:\w|::)+)(?:=(\w+))?$/ ) {
	my $pkg = $1;
	my $sub = $2;
	if ( !defined($sub) ) {
	    if ( $pkg =~ /^(.*)::(\w+)$/ ) {
		$sub = $2;
	    }
	    else {
		$sub = $pkg;
	    }
	}
	$pkg = __PACKAGE__."::".$pkg unless $pkg =~ /::/;
	warn("OP: $pkg => $sub\n") if $options->{trace};

	# Extensions.
	if ( eval "require $pkg" ) {
	    if ( my $op = $pkg->can($sub) ) {
		return "$pkg => $sub" if $options->{testing};
		return $op;
	    }
	    else {
		croak("$pkg does not provide a subroutine $sub");
	    }
	}
	# Builtins.
	elsif ( my $op = (__PACKAGE__."::BuiltIn")->can($cmd) ) {
	    return __PACKAGE__."::BuiltIn => $cmd" if $options->{testing};
	    return $op;
	}
	croak("No such operation: $cmd");
    }

    # Recode.
    if ( $cmd =~ /^:(.+):(.+):$/ ) {
	return 'Encode::from_to($_,"'.$1.'","'.$2.'")' if $options->{testing};
	require Encode;
	$cmd = 'Encode::from_to($_,"'.$1.'","'.$2.'")';
    }

    # Hopefully a regex. Build subroutine.
    return "sub { \$_ = \$_[0]; $cmd; \$_ }" if $options->{testing};
    my $op = eval "sub { \$_ = \$_[0]; $cmd; \$_ }";
    if ( $@ ) {
	$@ =~ s/ at \(eval.*/./;
	croak($@);
    }

    return $op;
}

package File::PerlMove::BuiltIn;

sub lc { CORE::lc($_[0]) }
sub uc { CORE::uc($_[0]) }
sub ucfirst { CORE::ucfirst($_[0]) }

1;

__END__

=head1 NAME

File::PerlMove - Rename files using Perl expressions

=head1 SYNOPSIS

  use File::PerlMove qw(pmv);
  pmv( sub { lc($_[0]) }, \@filelist, { verbose => 1 });

=head1 DESCRIPTION

File::PerlMove provides a single subroutine: B<File::PerlMove::pmv>.

B<pmv> takes three arguments: transform, filelist, and options.

I<transform> must be a string or a code reference. If it is a string,
it is assumed to be a valid Perl expression that will be evaluated to
modify C<$_>.

When I<transform> is invoked it should transform a file name passes as
argument into a new file name.

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

=item B<legacy>

If I<transform> is a code reference, it is called with the old name as
argument and must return the new, transformed name.

If B<legacy> is true, the code reference adheres to the old API where
the routine modifies the filename stored in C<$_>.

=item B<verbose>

More verbose information.

=back

=head1 EXPORTS

The main subroutine pmv() can be exported on demand.

=head1 EXTENSIONS

If the I<transform> argument is a verb, File::PerlMove will try to load
(require) a package File::PerlMove::I<verb>. This package B<must> define
a subroutine File::PerlMove::I<verb>::I<verb>. This subroutine is then used to perform
the transformation.

If such a package cannot be loaded it may be the name of a builtin routine.
See L</BUILTINS>.

If the transform argument is in the form I<pkg>B<=>I<verb> then
File::PerlMove::I<pkg> is used instead of File::PerlMove::I<verb>.
This makes it possible to have extension modules that define multiple
transform routines.

If the package name contains C<::> it is taken to be the full package name. For example,

    t::foo=bar

will load package t::foo and call subroutine t::foo::bar.

=head1 BUILTINS

If the I<transform> argument is a verb and not an extension (see L</EXTENSIONS>),
it may be the name of a builtin routine.

Currently supported builtins:

=over 8

=item B<lc>

Performs a lowercase operation.

=item B<uc>

Performs an uppercase operation.

=item B<ucfirst>

Upcases the first letter.

=item B<tc>

Performs a titlecase operation.

=back

Note, however, that using any of these operations is useless on file
systems that are case insensitive, like MS Windows and Mac.

=head1 EXAMPLES

See B<pmv> for examples.

=head1 AUTHOR

Johan Vromans <jvromans@squirrel.nl>

=head1 SEE ALSO

App::perlmv (and perlmv), File::Rename (and rename).

=head1 COPYRIGHT

This programs is Copyright 2004,2010,2017,2020 Squirrel Consultancy.

This program is free software; you can redistribute it and/or modify
it under the terms of the Perl Artistic License or the GNU General
Public License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

=cut
