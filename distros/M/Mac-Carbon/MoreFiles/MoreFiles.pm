=head1 NAME

Mac::MoreFiles - Sophisticated file management routines

=head1 SYNOPSIS

    use Mac::MoreFiles;

    $application = $Application{"MrPL"};

=head1 DESCRIPTION

=cut

use strict;

package Mac::MoreFiles;

BEGIN {
	use MacPerl ();
	use Mac::Processes ();
	use Exporter   ();
	use DynaLoader ();
	
	use vars qw($VERSION @ISA @EXPORT %Application);
	$VERSION = '1.04';
	@ISA = qw(Exporter DynaLoader);
	@EXPORT = qw(
		FSpCreateMinimum
		FSpShare
		FSpUnshare
		FSpFileCopy
		FSpDirectoryCopy
		FSpIterateDirectory
		FSpDTGetAPPL
		FSpDTSetComment
		FSpDTGetComment
		FSpDTCopyComment
		
		%Application
	);
}

package Mac::MoreFiles::_ApplHash;

BEGIN {
	use Tie::Hash ();

	use vars qw(@ISA);
	
	@ISA = qw(Tie::StdHash);
}

sub FETCH {
	my($self, $id) = @_;

	if (!$self->{$id}) {
		my($app);
		if ($^O eq 'MacOS') {
			for my $vol (MacPerl::Volumes()) {
				$app = Mac::MoreFiles::FSpDTGetAPPL(hex(substr($vol, 1, 4)), $id);
				last if $app;
			}
		} else {
			$app = Mac::Processes::LSFindApplicationForInfo($id);
		}
		$self->{$id} = $app;
	}
	return $self->{$id};
}

package Mac::MoreFiles;

=head2 Variables

=over 4

=item %Application

The C<%Application> hash will return the path to the application for a given 
signature, searching on all mounted volumes.

=back

=cut
tie %Application, q(Mac::MoreFiles::_ApplHash);

bootstrap Mac::MoreFiles;

=include MF.xs

=head1 AUTHOR

Written by Matthias Ulrich Neeracher E<lt>neeracher@mac.comE<gt>,
documentation by Bob Dalgleish E<lt>bob.dalgleish@sasknet.sk.caE<gt>.
Currently maintained by Chris Nandor E<lt>pudge@pobox.comE<gt>.

=cut

1;

__END__
