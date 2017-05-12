package HTML::LinkAdd;
our $VERSION = 0.13;	# POD and link titles

use strict;
use warnings;
use HTML::TokeParser;

=head1 NAME

HTML::LinkAdd - Add hyperlinks to phrases in HTML documents

=head1 SYNOPSIS

	use HTML::LinkAdd;
	my $page = new HTML::LinkAdd(
		'testinput1.html', {
			'the clocks were striking thirteen'=>'footnotes.html#OrwellG-1',
			'updated' => ['updated.html', 'View the latest update],
	});
	warn $page -> hyperlinked;
	$page ->save ('output.html');

=head1 DESCRIPTION

A simple object that accepts a class reference, a path to a file, 
and a hash of text-phrase/link-URLs,
and supplies a method to obtain the HTML with supplied hyperlinks interpolated.

If the values of the supplied has are anonymous lists, the first value
should a URI, the second escaped text to place in the link's C<title> attribute.

The phrase to hyperlink will be skipped if it appears in a context that prevents
linking, as defined in C<%$HTML::LinkAdd::SKIP>. This is currently 
C<head>, C<script>, C<style>>, C<pre>, C<xmp>, C<textarea>, C<object>, and C<a>.

=head1 DEPENDENCIES

L<HTML::TokeParser>

=head1 CONSTRUCTOR (new)

Accepts class reference, followed by either a filename or reference to a scalar of HTML
(as L<HTML::TokeParser|HTML::TokeParser>, and a hash of phrases and hyperlinks.

Returns a scalar that is the updated HTML.

=cut

our $SKIP = { map {$_=>1} qw{
	head pre xmp textarea object a script style
} };

sub new { 
	my ($class,$input) = (shift,shift);
	
	# Lets HTML::TokeParser handle the input file/string checks:-
	warn "HTML::LinkAdd::new called without a class ref?" and return undef unless defined $class;
	warn "Useage: new $class (\$path_to_file or \\\$HTML)" and return undef if not defined $input;

	my $self = bless {
		INPUT => $input,
		HREFS => {},
		output => '',
		skipto => [],
	},$class;

	my %args = ref($_[0]) eq 'HASH'? %{$_[0]} : @_; 
	warn "new requires a hash (or ref to such) as parameter." and return undef if not scalar keys %args;
	
	foreach my $phrase (keys %args){
		my $clean = $phrase;
		$clean =~ s{\s}{ }; # Squash whitespace in the phrase
		$self->{HREFS}->{$clean} = $args{$phrase};
	}
	
	# Create new TokeParser and parse all text, comparing HTML against keys of our targets
	my $p = new HTML::TokeParser ( $self->{INPUT} )
		or warn "Counldn't instantiate HTML::TokeParser!\n$!" and return undef;
	my $token;

	while ($token = $p->get_token and not (@$token[1] eq 'html' and @$token[0] eq 'E') ){
		
		 # warn "@$token[0] @$token[1] - [",  (scalar @{ $self->{skipto} }? join(', ', @{ $self->{skipto} }) : ''), "]\n";

		if (@$token[0] eq 'T'				# Text token
			and not @{ $self->{skipto} }	# and not ignoreing head/pre, etc
		) {
		
			@$token[1] =~ s{\s+}{ };		# Squash whitespace in the text

			# If we got a text node, loop over every user-supplied phrase
			foreach my $key ( keys %{$self->{HREFS}} ) {
				if (@$token[1] =~ m/\Q$key\E/sg){
					my ($title, $href);
					if (ref $self->{HREFS}->{$key}){
						($href, $title) = @{ $self->{HREFS}->{$key} };
					}
					else {
						$href = $self->{HREFS}->{$key};	
					}
					my $subs = "<a href=\"$href\""
					. ($title? " title=\"$title\"" : '')
					. ">$key</a>";
					@$token[1] =~ s/\Q$key\E/$subs/sg;
				}
			}
		};

		my $literal;
		if (@$token[0] eq 'S') { 
			$literal = @$token[4]; 
			# Skip PRE and XMP and TEXTAREA and HEAD
			if (exists $SKIP->{ @$token[1] }){
				unshift @{$self->{skipto}}, @$token[1]; 
			}
		}
		elsif (@$token[0] eq 'E') { 
			$literal = @$token[2];
			if (@{ $self->{skipto} }
			and @$token[1] eq $self->{skipto}->[0]){
				shift @{$self->{skipto}};
			}
		}
		else {
			$literal = @$token[1];
		}
		
		$self->{output} .= $literal;
	} 
	
	return $self;
}


=head1 PUBLIC METHOD hyperlink

Returns the hyperlinked HTML docuemnt constructed by...the constructor.

=cut

sub hyperlinked { return $_[0]->{output} }


=head1 PUBLIC METHOD save

Convenience method to save the object's C<output> slot to filename passed as scalar.

Returns undef on failure, C<1> on success.

=cut

sub save { my ($self,$filename) = (shift,shift);
	warn "HTML::LinkAdd::save requires a filename as parameter 1" and return undef unless defined $filename;
	local *OUT;
	open OUT, ">$filename"
		or warn "HTML::LinkAdd::save could not open the file <$filename> for writing.\n$!" and return undef;
		print OUT $self->{output};
	close OUT;
	return 1;
}

1;	# Return cleanly


__END__;

=head1 SEE ALSO

L<HTML::TokeParse>.

=head1 TODO

Add support for linking images by source or C<ID>.

=head1 AUTHOR

Lee Goddard C<lgoddard@cpan.org>

=head1 COPYRIGHT

Copyright 2001 (C) Lee Goddard. All Rights Reserved.
This is free software and you may use, abuse, amend and distribute under the same
terms as Perl itself.


