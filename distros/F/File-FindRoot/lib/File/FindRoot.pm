use v5.36;
use utf8;

package File::FindRoot;
use strict;

use warnings;

use Carp           ();
use Cwd            ();
use File::Basename ();
use File::Spec     ();

our $VERSION = '0.003';

=encoding utf8

=head1 NAME

File::FindRoot - Find the directory that's the root for a project

=head1 SYNOPSIS

	use File::FindRoot;

Start looking in the current directory and in each ancestor directory
until you find one that contains the relative path. Return that directory:

	my $dir = File::FindRoot->dir_contains( $rel_path );
	unless( defined $dir ) { ... }

Or matches a pattern:

	my $dir = File::FindRoot->dir_contains( qr/$patten/ );

Start in a different directory:

	my $dir = File::FindRoot->dir_contains( $file, { start_at => $path } );

Limit the number of ancestors checked:

	my $dir = File::FindRoot->dir_contains( $file, { limit => $n } );

=head1 DESCRIPTION

Lately I've done a number of things where a program deep in a project had to
find its project config file or library directory.

=over 4

=item File::FindRoot->dir_contains( REL_PATH [, OPTIONS] )

Returns the directory that contains C<REL_PATH>, and the empty list otherwise.

=over 4

=item * callback - (default: check that path exists) a subroutine that returns true
if the current directory is the one you want based on whatever you decide.

=item * debug - (default: 0) if true, output progress information. If you do not
specify a value, it uses the defined value of the C<FILE_FINDROOT_DEBUG> environment
variable, or finally, 0.

=item * debug_fh - (default: STDERR) the output filehandle for debugging info

=item * limit - (default: inf) the maximum number of ancestors to inspect.

=item * start_at - (default: current working directory) the directory in which
to start looking. If the string is not a directory, such as a filename, it uses
the directory name of the path. Any value is turned into an absolute path.

=back

The C<callback> argument takes a code reference with three positional parameters:
the current candidate directory, the passed C<REL_PATH> argument, and the C<OPTIONS>
hash:

	my $coderef = sub ( $candidate_dir, $target, $options ) { ... };
	File::FindRoot->dir_contains( '.git', { callback => $coderef });

If you don't specify a C<callback> argument, if uses one that catfiles
the directory and target and returns the value of C<-e> on the result:

	my $coderef = sub ($candidate_dir, $target, $options) {
		-e File::Spec->catfile($candidate_dir, $target)
		};

=cut

sub dir_contains ($class, $target, $options = {}) {
	unless( ref $options eq ref {} ) {
		Carp::carp "dir_contains: options argument must be a hash reference";
		return;
		}

	$options->{'debug'}    //= $ENV{'FILE_FINDROOT_DEBUG'} // 0;
	$options->{'debug_fh'} //= *STDERR;

	my $debug = ! $options->{'debug'} ? sub {} : sub ($message) { say { $options->{'debug_fh'} } "dir_contains: $message" };

	$options->{'callback'} //= sub ($candidate_dir, $target, $options) { -e File::Spec->catfile($candidate_dir, $target) };
	unless( ref $options->{'callback'} eq ref sub {} ) {
		Carp::carp "callback value is not a subroutine reference";
		return;
		}

	$options->{'limit'}      //= (9**9**9);
	$options->{'start_at'}   //= ( $^O eq 'MSWin32' ? Cwd::getdcwd() :  Cwd::getcwd() );
	my $original = $options->{'start_at'};

	$debug->( "before preprocessing, starting at <$original>" );
	$options->{'start_at'} = File::Spec->rel2abs($options->{'start_at'}) unless File::Spec->file_name_is_absolute($options->{'start_at'});
	$options->{'start_at'} = Cwd::realpath($options->{'start_at'});
	unless( length $options->{'start_at'} ) {
		Carp::carp "Dir <$original> does not exist";
		return;
		}

	$options->{'start_at'} = File::Basename::dirname($options->{'start_at'}) if ! -d $options->{'start_at'};
	$debug->( "after preprocessing, starting at <$options->{'start_at'}>" );

	if( $options->{'limit'} < 0 ) {
		Carp::carp "Initial limit <$options->{'limit'}> was less than zero";
		return;
		}

	my $rounds = 0;
	my $candidate_dir = $options->{'start_at'};
	while( $rounds <= $options->{'limit'} ) {
		$debug->( "round <$rounds> - looking in <$candidate_dir> for <$target>" );
		if( $options->{'callback'}->( $candidate_dir, $target, $options ) ) {
			return $candidate_dir;
			}
		my $ancestor = File::Basename::dirname($candidate_dir);
		$debug->("ancestor is <$ancestor>");
		last if $candidate_dir eq $ancestor;
		$candidate_dir = $ancestor;
		$rounds++;
		}
	$debug->( "stopped at <$candidate_dir> before finding <$target>" );

	return;
	}

=back

=head1 TO DO


=head1 SEE ALSO

=over 4

=item * L<File::Find::>

=back

=head1 SOURCE AVAILABILITY

This source is in Github:

	http://github.com/briandfoy/file-findroot

=head1 AUTHOR

brian d foy, C<< <briandfoy@pobox.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2026-2026, brian d foy, All Rights Reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

1;
