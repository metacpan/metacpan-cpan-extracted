package File::Tasks::Provider;

# See POD at end for docs

use strict;
use Scalar::Util ();
use Params::Util qw{_INSTANCE _SCALAR _ARRAY};

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.07';	
}

my @COMPATIBLE_CLASSES = qw{
	Archive::Builder::File
	};





#####################################################################
# Main Methods


sub compatible {
	my $class = shift;
	my $it    = shift;

	# Check the basic data types
	return '' unless defined $it;
	return !! length $it unless ref $it;
	return 1 unless ref $it;
	return 1 if _SCALAR($it);
	return 1 if _ARRAY($it);

	# We don't handle any other data types
	my $its_class = Scalar::Util::blessed $it;
	return '' unless $its_class;

	# Check for an allowed object class
	foreach ( @COMPATIBLE_CLASSES ) {
		return 1 if _INSTANCE($its_class, $_);
	}

	'';
}

sub content {
	my $either = shift;
	my $it     = defined $_[0] ? shift : return undef;

	# Handle the basic data types
	return \$it unless ref $it;
	return $it if _SCALAR($it);
	if ( _ARRAY($it) ) {
		$it = ($it->[0] =~ /\n$/)
			? join('', @$it)
			: join('', map { "$_\n" } @$it);
		return \$it;
	}

	# Handle the various compatible object classes
	if ( _INSTANCE($it, 'Archive::Builder::File') ) {
		return $it->content;
	}

	undef;
}

1;

__END__

=pod

=head1 NAME

File::Tasks::Provider - Handles content providers for File::Tasks

=head1 DESCRIPTION

The main intent of L<File::Tasks> is to take a set of content and apply
it to a filesystem in some way.

The C<File::Tasks::Provider> class is in change of making sure that
L<File::Tasks> can handle a wide variety of different types of content
providers.

Mostly at present this just means C<SCALAR> references, strings, C<ARRAY>
refs and so on. But it should be extendable to handle many different
things from which content can be extracted.

=head1 METHODS

=head2 compatible $source

The C<compatible> method takes a single argument and checks to see
if it can be used as a content source for L<File::Tasks>.

Returns true if it can, or false if not.

=head2 content $source

The C<content> method extracts the content from the source and returns
it as a reference to a C<SCALAR>, or returns C<undef> on error.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Tasks>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2005 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

