package Emacs::EPL;

use Fcntl;

sub debug_fh {
    if (! $debugging) {
	carp ("Only call debug() when \$debugging is true");
	return (undef);
    }
    if ($debugging eq 'stderr') {
	if ($child_of_emacs) {
	    $debugging = 0;
	    carp ("Can't debug to 'stderr' under Emacs, use a filename");
	    return (undef);
	}
	return (*Emacs::REAL_STDERR);
    }
    if (ref ($debugging) eq 'SCALAR') {
	local (*OUT);
	require IO::Scalar;
	tie (*OUT, 'IO::Scalar', $debugging);
	return (\*OUT);
    }
    if (! ref ($debugging)) {
	my $d = $debugging;
	$debugging =~ s#^(\s)#./$1#;
	if (open (DEBUG, ">> $debugging\0")) {
	    $debugging = \*DEBUG;
	    select ((select ($debugging), $| = 1) [0]);
	}
	else {
	    $debugging = 0;
	    carp ("Can't debug to '$d': $!");
	}
    }
    return ($debugging);
}

sub Emacs::EPL::Debug::debug {
    my ($fh);
    $fh = debug_fh ();
    return unless $fh;
    local $debugging;  # Avoid loops.
    print $fh @_;
}

1;
__END__

=head1 NAME

Emacs::EPL::Debug - Demand-loaded protocol debugging support

=head1 SYNOPSIS

    $Emacs::EPL::debug = 'stderr'; # or filename, scalarref, handle
    Emacs::EPL::debug (@strings);

=head1 DESCRIPTION

See the Texinfo documentation about debugging options.

=head1 COPYRIGHT

Copyright (C) 2001 by John Tobey,
jtobey@john-edwin-tobey.org.  All rights reserved.

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; see the file COPYING.  If not, write to the
  Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
  MA 02111-1307  USA


=head1 SEE ALSO

L<Emacs::Lisp>, L<Emacs>.

=cut
