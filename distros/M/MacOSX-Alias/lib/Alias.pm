# $Id$
package MacOSX::Alias;
use strict;

use warnings;
no warnings;

use base qw(Exporter);
use subs qw();
use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS);

use Carp qw(carp croak);
use MacPerl qw(GetFileInfo);
use Mac::Errors;
use Mac::Files;
use Mac::Resources;

@EXPORT_OK   = qw(read_alias make_alias);
%EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

$VERSION = '0.11';

=head1 NAME

MacOSX::Alias - Read or create Mac OS X aliases

=head1 SYNOPSIS

	use MacOSX::Alias qw(read_alias make_alias);

	my $path    = read_alias( $filename );
	my $boolean = make_alias( $target_name, $alias_name );


=head1 DESCRIPTION

=over

=item read_alias( ALIAS )

Returns the target file path on success, and C<undef> on failure.

=cut

# http://use.perl.org/~pudge/journal/10437
sub read_alias
	{
	my( $alias_path ) = shift;

	my $link = eval {
		my $res = FSpOpenResFile( $alias_path, 0 ) or croak( $Mac::Errors::MacError );
		# get resource by index; get first "alis" resource
		my $alis = GetIndResource( 'alis', 1 ) or croak( $Mac::Errors::MacError );
		ResolveAlias( $alis );
		};

	if( $@ ) { warn "$@\n"; return; }

	return $link;
	}

=item make_alias( TARGET, ALIAS )

Returns true on success, and C<undef> on failure.

=cut

# http://use.perl.org/~pudge/journal/10437
sub make_alias
	{
	my( $target, $alias ) = @_;

	eval {
		croak( "Target file [$target] does not exist" ) unless -e $target;

		# workaround for Mac::Carbon bug that requires existing file
		open my $fh, "> $alias" or croak( $! );
		close $fh;

		# set "alias" attribute
		my $finfo = FSpGetFInfo( $alias )   or croak( $Mac::Errors::MacError );
		$finfo->fdFlags( $finfo->fdFlags | 0x8000 ); # kIsAlias
		FSpSetFInfo( $alias, $finfo )       or croak( $Mac::Errors::MacError );

		# get target's creator, type, and alias
		my( $creator, $type ) = GetFileInfo( $target );
		my $alis = NewAlias( $target )      or croak( $Mac::Errors::MacError );

		# make resource file, open it, add the resource, and close it
		FSpCreateResFile( $alias, $creator, $type, 0)
		                                    or croak( $Mac::Errors::MacError );

		my $res = FSpOpenResFile($alias, 0) or croak( $Mac::Errors::MacError );
		AddResource($alis, 'alis', 0, '')   or croak( $Mac::Errors::MacError );
		CloseResFile($res);
		};

	if( $@ ) { warn "$@\n"; return; }

	return 1;
	}

=back

=head1 TO DO


=head1 SEE ALSO


=head1 SOURCE AVAILABILITY

This source is in Github

	git://github.com/briandfoy/macosx-alias.git

=head1 AUTHORS

Chris Nandor C<< <cnandor@cpan.org> >>

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007-2008, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
