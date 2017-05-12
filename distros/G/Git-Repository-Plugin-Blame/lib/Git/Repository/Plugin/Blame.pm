package Git::Repository::Plugin::Blame;

use warnings;
use strict;
use 5.006;

use Git::Repository::Plugin;
our @ISA = qw( Git::Repository::Plugin );
sub _keywords { return qw( blame ) } ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)

use Carp;
use Class::Load qw();
use Perl6::Slurp qw();
use Git::Repository::Plugin::Blame::Line;


=head1 NAME

Git::Repository::Plugin::Blame - Add a blame() method to L<Git::Repository>.


=head1 VERSION

Version 1.4.0

=cut

our $VERSION = '1.4.0';


=head1 SYNOPSIS

	# Load the plugin.
	use Git::Repository 'Blame';

	my $repository = Git::Repository->new();

	# Get the git blame information.
	my $blame_lines = $repository->blame( $file );


=head1 DESCRIPTION

This module adds a new C<blame()> method to L<Git::Repository>, which can be
used to determine what the last change for each line in a file is.


=head1 METHODS

=head2 blame()

Return the git blame information for a given file as an arrayref of
L<Git::Repository::Plugin::Blame::Line> objects.

	my $blame_lines = $repository->blame(
		$file,
		use_cache => $boolean, # default 0
	);

Arguments:

=over 4

=item * use_cache I<(default: 0)>

Cache the git blame output.

=item * ignore_whitespace I<(default: 0)>

Ignore whitespace when comparing the parent's version and the child's to find
where the lines came from.

=back

=cut

sub blame
{
	my ( $repository, $file, %args ) = @_;
	my $use_cache = delete( $args{'use_cache'} ) || 0;
	my $ignore_whitespace = delete( $args{'ignore_whitespace'} ) || 0;
	croak 'The following arguments are not valid: ' . join( ', ' , keys %args )
		if scalar( keys %args ) != 0;

	# Check if the cache is enabled and if the file has already been parsed.
	my $cache;
	if ( $use_cache )
	{
		my $class = Class::Load::load_class( 'Git::Repository::Plugin::Blame::Cache' );
		$cache = $class->new(
			repository => $repository->work_tree(),
			blame_args =>
			{
				ignore_whitespace => $ignore_whitespace,
			},
		);
		croak 'Failed to initialize cache for repository ' . $repository->work_tree()
			if !defined( $cache );

		my $blame_lines = $cache->get_blame_lines( file => $file );
		return $blame_lines
			if defined( $blame_lines );
	}

	# Run the command.
	my @commandline_options = ( '--porcelain' );
	push( @commandline_options, '-w' ) if $ignore_whitespace;
	my $command = $repository->command( 'blame', @commandline_options, $file );
	my @output = $command->final_output();

	# Parse the output.
	my ( $commit_id, $original_line_number, $final_line_number, $lines_count_in_group );
	my $commit_attributes = {};
	my $lines = [];
	foreach my $line ( @output )
	{
		if ( $line =~ /^\t(.*)$/x )
		{
			# It's a line from the file we git blamed.
			push(
				@$lines,
				Git::Repository::Plugin::Blame::Line->new(
					line_number       => $final_line_number,
					line              => defined( $1 ) ? $1 : '',
					commit_attributes => $commit_attributes->{ $commit_id },
					commit_id         => $commit_id,
				)
			);
		}
		else
		{
			# It's a git header line.
			if ( $line =~ /^([0-9a-f]+)\s(\d+)\s(\d+)\s*(\d*)$/x )
			{
				( $commit_id, $original_line_number, $final_line_number, $lines_count_in_group ) = ( $1, $2, $3, $4 );
			}
			elsif ( $line =~ m/^([\w\-]+)\s*(.*)$/x )
			{
				$commit_attributes->{ $commit_id }->{ $1 } = $2;
			}
		}
	}

	# If we have a cache object, cache the output.
	if ( defined( $cache ) )
	{
		$cache->set_blame_lines(
			file        => $file,
			blame_lines => $lines,
		);
	}

	return $lines;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/Git-Repository-Plugin-Blame/issues>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Git::Repository::Plugin::Blame


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
