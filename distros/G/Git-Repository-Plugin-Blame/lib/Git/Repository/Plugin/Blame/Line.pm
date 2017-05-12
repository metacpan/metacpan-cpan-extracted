package Git::Repository::Plugin::Blame::Line;

use warnings;
use strict;
use 5.006;

use Carp;


=head1 NAME

Git::Repository::Plugin::Blame::Line - Store the git blame information for a line of code.


=head1 VERSION

Version 1.4.0

=cut

our $VERSION = '1.4.0';


=head1 SYNOPSIS

	use Git::Repository::Plugin::Blame::Line;
	my $line = Git::Repository::Plugin::Blame::Line->new(
		line_number       => $line_number,
		line              => $line,
		commit_attributes => \%commit_attributes,
		commit_id         => $commit_id,
	);

	print "The line number is " . $line->get_line_number() . "\n";
	print "The line is " . $line->get_line() . "\n";
	print "The commit ID is " . $line->get_commit_id() . "\n";
	print "The commit attributes are: \n";
	while ( my ( $name, $value ) = each( %{ $line->get_commit_attributes() } ) )
	{
		print "   - $name: $value\n";
	}


=head1 DESCRIPTION

This module stores the git blame information for a line of code.


=head1 METHODS

=head2 new()

Create a new Git::Repository::Plugin::Blame::Line object.

	my $line = Git::Repository::Plugin::Blame::Line->new(
		line_number       => $line_number,
		line              => $line,
		commit_attributes => \%commit_attributes,
		commit_id         => $commit_id,
	);

All parameters are mandatory:

=over 4

=item * 'line_number'

The number of this line in the file that git blame was applied to.

=item * 'line'

The text/code of this line in the file that git blame was applied to.

=item * 'commit_attributes'

A hashref of attributes for the last commit that modified this line.

=item * 'commit_id'

The ID of the last commit that modified this line.

=back

=cut

sub new
{
	my ( $class, %args ) = @_;

	# Verify parameters.
	foreach my $arg ( qw( line_number commit_id ) )
	{
		croak "The argument '$arg' must be defined to create a Git::Repository::Plugin::Blame::Line object"
			if !defined( $args{$arg} ) || ( $args{$arg} eq '' );
	}
	croak "The argument 'line' must be defined to create a Git::Repository::Plugin::Blame::Line object"
		if !defined( $args{'line'} );

	croak "The argument 'line_number' must be a strictly positive integer"
		if $args{'line_number'} !~ /^\d+$/;

	my $commit_attributes = $args{'commit_attributes'};
	croak "The argument 'commit_attributes' must be a hashref to create a Git::Repository::Plugin::Blame::Line object"
		if !defined( $commit_attributes ) || ( ref( $commit_attributes ) ne 'HASH' );

	# Clean emails in commit attributes.
	foreach my $name ( keys %$commit_attributes )
	{
		next unless $name =~ /^(?:author|committer)-mail$/x;
		$commit_attributes->{ $name } =~ s/^<//;
		$commit_attributes->{ $name } =~ s/>$//;
	}

	# Create and return the object.
	return bless(
		{
			line_number       => $args{'line_number'},
			line              => $args{'line'},
			commit_attributes => $args{'commit_attributes'},
			commit_id         => $args{'commit_id'},
		},
		$class
	);
}


=head2 get_line_number()

Return the number of this line in the file that git blame was applied to.

	my $line_number = $line->get_line_number();

=cut

sub get_line_number
{
	my ( $self ) = @_;

	return $self->{'line_number'};
}


=head2 get_line()

Return the text/code of this line in the file that git blame was applied to.

	my $line = $line->get_line();

=cut

sub get_line
{
	my ( $self ) = @_;

	return $self->{'line'};
}


=head2 get_commit_id()

Return the SHA-1 of the last commit that modified this line.

	my $commit_id = $line->get_commit_id();

=cut

sub get_commit_id
{
	my ( $self ) = @_;

	return $self->{'commit_id'};
}


=head2 get_commit_attributes()

Return the hashref of attributes for the last commit that modified this line.

	my $commit_attributes = $line->get_commit_attributes();

=cut

sub get_commit_attributes
{
	my ( $self ) = @_;

	return $self->{'commit_attributes'};
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/Git-Repository-Plugin-Blame/issues>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Git::Repository::Plugin::Blame::Line


You can also look for information at:

=over 4

=item * GitHub (report bugs there)

L<https://github.com/guillaumeaubert/Git-Repository-Plugin-Blame/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Git-Repository-Plugin-Blame>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Git-Repository-Plugin-Blame>

=item * MetaCPAN

L<https://metacpan.org/release/Git-Repository-Plugin-Blame>

=back


=head1 AUTHOR

L<Guillaume Aubert|https://metacpan.org/author/AUBERTG>,
C<< <aubertg at cpan.org> >>.


=head1 COPYRIGHT & LICENSE

Copyright 2012-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.

=cut

1;
