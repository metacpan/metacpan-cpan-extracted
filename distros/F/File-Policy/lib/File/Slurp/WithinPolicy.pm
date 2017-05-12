###############################################################################
# Purpose : Hide site-dependent FS policies beneath a well-known interface
# Author  : John Alden
# Created : March 2005
# CVS     : $Id: WithinPolicy.pm,v 1.4 2005/06/15 10:40:21 simonf Exp $
###############################################################################

package File::Slurp::WithinPolicy;

use strict;
use Carp;
use Exporter;
use Fcntl ':flock';
use File::Slurp();
use File::Policy;
use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS @ISA);

@ISA = qw(Exporter);
@EXPORT_OK = qw(read_file write_file append_file overwrite_file read_dir);
%EXPORT_TAGS = ('all' => \@EXPORT_OK);
$VERSION = sprintf"%d.%03d", q$Revision: 1.4 $ =~ /: (\d+)\.(\d+)/;

sub read_file {	
	File::Policy::check_safe( $_[0], 'r' );
	goto &File::Slurp::read_file;
}

sub write_file {	
	File::Policy::check_safe( $_[0], 'w' );
	goto &File::Slurp::write_file;
}

sub append_file {	
	File::Policy::check_safe( $_[0], 'w' );
	goto &File::Slurp::append_file;
}

sub overwrite_file {	
	File::Policy::check_safe( $_[0], 'w' );
	goto &File::Slurp::overwrite_file;
}

sub read_dir {	
	File::Policy::check_safe( $_[0], 'r' );
	goto &File::Slurp::read_dir;
}

1;

=head1 NAME

File::Slurp::WithinPolicy - Applies filesystem policies to File::Slurp

=head1 SYNOPSIS

  use File::Slurp::WithinPolicy qw(:all);

  my $text = read_file( 'filename' );
  my @lines = read_file( 'filename' );
  write_file( 'filename', $text );
  append_file( 'filename', $more_text );
  overwrite_file( 'filename', $text );
  my @files = read_dir( '/path/to/dir' );

=head1 DESCRIPTION

This provides the File::Slurp interface within a policy defined by File::Policy.
By default, File::Policy is a no-op and this behaves identically to File::Slurp.
System administrators may want to override the default File::Policy implementation to enforce a local filesystem policy
(see L<File::Policy>).

=head1 FUNCTIONS

=head2 read_dir

See L<File::Slurp/read_dir>

=head2 read_file

See L<File::Slurp/read_file>

=head2 write_file

See L<File::Slurp/write_file>

=head2 append_file

See L<File::Slurp/append_file>

=head2 overwrite_file

See L<File::Slurp/overwrite_file>

=head1 EXPORTS

By default, nothing is exported.
The C<:all> tag can be used to export everything.
Individual methods can also be exported.

=head1 SEE ALSO

L<File::Slurp>, L<File::Policy>

=head1 VERSION

$Revision: 1.4 $ on $Date: 2005/06/15 10:40:21 $ by $Author: simonf $

=head1 AUTHOR

John Alden <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt 

=cut
