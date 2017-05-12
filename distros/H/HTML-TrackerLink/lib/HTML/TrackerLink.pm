package HTML::TrackerLink;

# HTML::TrackerLink is a package for automatically finding tracker references
# in the form of 'Keyword 12345' or '#12345', and converting them into links into
# the external tracking system.

# See POD below for more details

use 5.006;
use strict;

use vars qw{$VERSION $errstr};
BEGIN {
	$VERSION = '1.03';
	$errstr  = '';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;

	# Create our object
	my $self = bless {
		keywords => {},
	}, $class;
	return $self unless @_;

	# Handle arguments
	if ( @_ == 1 ) {
		# Should be a tracker URL for the default search
		my $url = shift;
		return undef unless $self->_check_url( $url );

		# Set the default search
		$self->{default} = $url;

	} elsif ( @_ == 2 ) {
		# Should be a single keyword/url pair
		my ($keyword, $url) = @_;
		return undef unless $self->_check_keyword( $keyword );
		return undef unless $self->_check_url( $url );

		# Set the keyword
		$self->{keywords}->{lc $keyword} = $url;

		# Set the default search to be the same
		$self->{default_keyword} = $keyword;

	} elsif ( scalar(@_) % 2 == 0 ) {
		# Multiple keyword/url pairs
		my %keywords = @_;
		foreach my $keyword ( sort keys %keywords ) {
			my $url = $keywords{$keyword};
			unless ( $self->_check_keyword( $keyword ) ) {
				return $self->_error( "Invalid keyword '$keyword': "
					. $self->errstr );
			}
			unless ( $self->_check_url( $url ) ) {
				return $self->_error( "Bad URL for keyword '$keyword': "
					. $self->errstr );
			}

			# Set the keyword
			$self->{keywords}->{$keyword} = $url;
		}

	} else {
		return $self->_error( 'Arguments must be in keyword/url pairs' );
	}

	$self;
}

# Return the currently defined keywords
sub keywords {
	if ( wantarray ) {
		return sort keys %{ $_[0]->{keywords} };
	} else {
		return scalar keys %{ $_[0]->{keywords} };
	}
}





#####################################################################
# Main Methods

# Get or set a keyword search
sub keyword {
	my $self = shift;
	my $keyword = $self->_check_keyword($_[0]) ? lc shift : return undef;
	return $self->{keywords}->{$keyword} unless @_;

	# Set the tracker URL
	my $url = $self->_check_url($_[0]) ? shift : return undef;
	$self->{keywords}->{$keyword} = $url;
}

# Get the current default search
sub default {
	my $self = shift;
	return $self->{default_keyword}
		? $self->{keywords}->{ $self->{default_keyword} }
		: $self->{default} unless @_;

	# Try to set the default search
	my $url = $self->_check_url($_[0]) ? shift : return undef;

	# In case they are using a keyword, remove it
	delete $self->{default_keyword};
	$self->{default} = $url;
}

# Make the default search the same as a particular keyword
sub default_keyword {
	my $self = shift;
	my $keyword = $self->_check_keyword($_[0]) ? lc shift : return undef;

	# Does the keyword exist?
	unless ( exists $self->{keywords}->{$keyword} ) {
		return $self->_error( "The keyword '$keyword' does not exist" );
	}

	# In case they are using an explicit default search, remove it
	delete $self->{default};

	$self->{default_keyword} = $keyword;
}

# Process and return a string
sub process {
	my $self = shift;
	my $text = (@_ and defined $_[0]) ? shift
		: return $self->_error( 'You did not provide a string to process' );

	# Prepare the transforms
	my @replace = ();
	if ( $self->keywords ) {
		my $any_keyword = '(?:' . join('|', $self->keywords) .')';
		push @replace, [
			qr/\b($any_keyword)\s+\#?(\d+)/is,
			sub { $self->_replace(
				$self->{keywords}->{lc $_[3]}, $_[2], $_[4],
			) },
		];
	}
	if ( $self->default ) {
		push @replace, [
			qr/\#(\d+)/s,
			sub { $self->_replace(
				$self->default, $_[2], $_[3],
			) },
		];
	}

	# Hand off to the main substitution method
	return $self->_subst( $text, @replace );
}

# Implement the parallel substitution
sub _subst {
	my $self  = shift;
	my $input = shift;

	# Map the match regex to capture everything BEFORE the match,
	# and the entire pattern provided.
	# (We'll provide them as the first params)
	my @try = map { [ qr/\G(.*?)($_->[0])/s => $_->[1] ] } @_;
	unless ( @try ) {
		# Handle the pathological no-replace case
		return $input;
	}

	# Start the main loop
	my $position = 0;
	my $len      = length $input;
	my $output   = '';
	while ( $position < $len ) {
		my $found = undef;
		my @start = ();
		my @end   = ();
		foreach my $r ( @try ) {
			# Skip if it is not in the string
			pos $input = $position;
			next unless $input =~ $r->[0];

			# Skip if it DOESN'T match earlier
			if ( $found and $start[2] <= $-[2] ) {
				next;
			}

			# This is the best option.
			# Save the matching regex
			$found = $r->[1];
			@start = @-;
			@end   = @+;
		}

		# Break out if no more matches
		last unless $found;

		# Append the pre-match string to the output
		$output .= substr( $input, $start[1], $end[1] - $start[1] );

		# Pass the rest to the transform function
		my $rv = $found->(
			map {
				substr( $input, $start[$_], $end[$_] - $start[$_] )
			} 0 .. $#end
		);
		unless ( defined $rv ) {
			# Transform is signaling an error
			return undef;
		}

		# Transform completed ok
		$output .= $rv;

		# Move the match position for the next iteration
		$position = $end[2];
	}

	# Append the remainder of the string
	return $output . substr( $input, $position );
}

# Return any error message
sub errstr { $errstr }





#####################################################################
# Support Methods

sub _check_keyword {
	my $self = shift;
	my $kw = shift or return $self->_error( 'You did not provide a keyword' );
	return $self->_error( 'Keyword contains non-word characters' ) if $kw =~ /\W/;
	return $self->_error( 'Keyword cannot start with a number' )   if $kw =~ /^\d/;
	return 1;
}

sub _check_url {
	my $self = shift;
	my $url = shift or return $self->_error( 'You did not provide a tracker URL' );
	unless ( $url =~ m!^https?://[\w.]+/! ) {
		return $self->_error( 'The tracker URL format appears to be invalid' );
	}
	unless ( $url =~ /\%n/ ) {
		return $self->_error( 'The tracker URL does not contain a %n placeholder' );
	}
	return 1;
}

# Generates the link in the replacer
sub _replace {
	my ($self, $url, $text, $id) = @_;

	# Create the link
	$url =~ s/\%n/$id/g;
	return "<a href='$url'>$text</a>";
}

sub _error { $errstr = $_[1]; undef }

1;

__END__

=pod

=head1 NAME

HTML::TrackerLink - Autogenerates links to Bug/Tracker systems

=head1 SYNOPSIS

  # Create a linker for only #12345 for a single tracker system
  my $linker = HTML::TrackerLink->new( 'http://host/path?id=%n' );
  
  # Create a linker for a single named ( 'Bug #12345' ) system
  $linker = HTML::TrackerLink->new( 'bug', 'http://host/path?id=%n' );
  
  # Create a linker for multiple named systems
  $linker = HTML::TrackerLink->new(
          'bug'     => 'http://host1/path?id=%n',
          'tracker' => 'http://host2/path?id=%n',
          );
  
  # For the multiple linker, make it default to an arbitrary system
  $linker->default( 'http://host/path?id=%n' );
  
  # For the multiple linker, make it default to one of the keywords
  $linker->default_keyword( 'bug' );
  
  # Process a string, and add links
  my $string = 'Fix for bug 1234, described in client request CT #1234';
  $string = $linker->process( $string );

=head1 DESCRIPTION

HTML::TrackerLink is a package for automatically generating links to one or
more external systems from references found in ordinary text, such as CVS
commit messages. It tries to do this as intelligently and as flexibly as
possible.

=head2 Tracker URL Format

Most tracking systems ( bugs, client requests etc, henceforth known as a
'Tracker' ) use a numeric ID number as a key for the tracker item. Web
interfaces to these systems will generally contain a URL like the following.

  Mozilla Bugzilla 100,000th Bug Example URL
  http://bugzilla.mozilla.org/show_bug.cgi?id=100000

HTML::TrackerLink takes as arguments a generic form of this URL, created by
replacing the number of the tracker item, with the symbol '%n'. For the
previous example.

  HTML::TrackerLink URL for Mozilla Bugzilla
  http://bugzilla.mozilla.org/show_bug.cgi?id=%n

When HTML::TrackerLink find a valid reference while processing, it will
replace the %n with the id it finds, and replace the reference in the source
string with a resulting link.

Any tracker URL arguments passed to HTML::TrackerLink will be checked to
make sure that they actually contain the %n placeholder.

=head2 Default Tracker and Keyworded Trackers

HTML::TrackerLink does two types of searches in the source text, a 'default'
search, and 'keyword' searches.

A default search will look B<only> for a number with a preceding hash,
like '#12345'. Note that the default search will NOT match with naked numbers,
such as '12345'.

A keyword search is a little more flexible. For a 'bug' keyword search, the
following would all be valid, and matched against.

  bug 12345        # Simplest form
  Bug 12345        # Case insensitive
  BuG     12345    # Case insensitive and allows multiple spaces
  bug #12345       # Normal hashed number form
  Bug #12345       # Again, case insensitive

The keyword search would B<NOT> match with the following

  bug12345         # Must be seperated by whitespace
  bug#12345        # Even in this case
  bigbug 12345     # 'bug' must be a seperate word

All of these searches are performed condurrently, meaning that given both a
default search, and a C<'bug'> keyword search, the following would match the
way you would expect it to.

  Client issue #435 ( Bug #1532 ) fixed

The C<'Bug #1532'> would link to your bug tracking system, and the C<'#435'> would
link to your client feedback tracking system, which is the default.

=head2 Keyword Format

The keyword can be up to 32 characters long, containing only word characters,
and cannot start with a number. Irrelevant of the case passed, the keywords
are stored internally in lowercase. As such, you cannot have two seperate
keyword searchs for C<'bug'>, and C<'BUG'>.

=head1 METHODS

=head2 new

The C<new> constructor takes a variety of arguments and returns a new
HTML::TrackerLink processing object.

Arguments to C<new> are accepted in one of the following formats.

=over 4

=item new

A empty HTML::LinkTracker object is created without any trackers set

=item new $tracker_url

If a single argument is passed, the argument is assume be the tracker URL for
a the default search.

=item new $keyword => $tracker_url

If two arguments are passed, they are assumed to be a single keyword search.
In the case where the HTML::TrackerLink object is created with only one
keyword, the default search will ALSO be set to the same tracker, so that in
systems with only one possible place to link to, people that forget the
keyword will still get their references linked to.

It also catches a cases where there is a message like C<'This resolves Bug #12,
#13, #14 and #15'>.

=item new $keyword1 => $tracker_url1, $keyword2 => $tracker_url2 [, ...]

If more than two arguments are passed, they are assumed to be a set of keyword
searches. In this case, the default search will NOT be set, as we cannot be
sure I<which> case the default should go to.

To assign the default in this case, you should use the C<default> or
C<default_keyword> methods.

=back

In all cases, the C<new> method will returns a new HTML::TrackerLink object on
success, or C<undef> if an error has occured. ( Invalid keyword/URL formats
etc ).

=head2 keywords

Returns a list containing all current defined keywords

=head2 keyword $keyword [, $tracker_url ]

If passed a single argument, returns the current URL for the keyword, or
C<undef> if the keyword does not exist.

If passed two arguments, it will add a new keyword search, or replace an
existing one, returning true on success, or C<undef> if the keyword or
tracker URL are invalid.

=head2 default [ $tracker_url ]

If passed, explicitly sets the tracker URL to be used for the default search.

Returns the default search URL

Returns C<undef> if attempting to set an invalid tracker_url

=head2 default_keyword $tracker_url

Sets the default search to be the same as an already existing keyword search.

Returns true on success.

Returns C<undef> if the keyword does not exist.

=head2 process $string

The C<process> methods takes a string as argument, and applies the searches to
it.

Returns the processed string on success.

Returns C<undef> on error.

=head2 errstr

When an error occurs, the C<errstr> method allows you to get access to the
error message. C<errstr> can be called as either a static or object method.

i.e. The following are equivalent

  # Calling errstr as a static method
  my $linker = HTML::TrackerLink->new( 'badurl' );
  die HTML::TrackerLink->errstr;

  # Calling errstr as an object method
  my $linker = HTML::TrackerLink->new( 'badurl' );
  die $linker->errstr;

=head1 TO DO

Although the code for this module was extracted from a known working
application, this package itself has only basic tests. Please report
any bugs encountered.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-TrackerLink>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2002 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
