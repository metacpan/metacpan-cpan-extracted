package HTTP::GetImages;

use vars qw /$EXTENSIONS_RE $EXTENSIONS_BAD $VERSION/;

$VERSION=0.343;

=head1 NAME

HTTP::GetImages - Spider to recover and store images from web pages.

=head1 SYNOPSIS

	use HTTP::GetImages;

	$_ = new HTTP::GetImages (
		dir  => '.',
		todo => ['http://www.google.com/',],
		dont => ['http://www.somewhere/ignorethis.html','http://and.this.html'],
		chat => 1,
	);

	$_->print_imgs;
	$_->print_done;
	$_->print_failed;
	$_->print_ignored;

	my $hash = $_->imgs_as_hash;
	foreach (keys %{$hash}){
		warn "$_ = ",$hash->{$_},"\n";
	}

	exit;

=head1 DESCRIPTION

This module allow syou to automate the searching, recovery and local storage
of images from the web, including those linked by anchor (C<A>), mage (C<IMG>)
and image map (C<AREA>) elements.

Supply a URI or list of URIs to process, and C<HTTP::GetImages> will recurse
over every link it finds, searching for images.

By supplying a list of URIs, you can restrict the search to certain webservers
and directories, or exclude it from certain webservers and directories.

You can also decide to reject images that are too small or too large.

=head1 DEPENDENCIES

	LWP::UserAgent;
	HTTP::Request;
	HTML::TokeParser;

=cut

use LWP::UserAgent;
use HTTP::Request;
use HTML::TokeParser;
use Carp;
use strict;
use warnings;
no strict 'refs';

=head1 PACKAGE GLOBAL VARIABLE

=head2 $CHAT

Set to above zero if you'd like a real-time report to C<STDERR>.
Defaults to off.

=cut

my $CHAT;

# Default values to apply to $self->{ext_ok}
$EXTENSIONS_RE = '(jpg|jpeg|bmp|gif|png|xbm|xmp)';

# Default values for $self->{ext_bad}
$EXTENSIONS_BAD = '(wmv|avi|rm|mpg|asf|ram|asx|mpeg|mp3)';


=head1 CONSTRUCTOR METHOD new

Besides the class reference, accepts name=>value pairs:

=over 4

=item max_attempts

The maximum attempts the agent should make to access the site. Default is three.

=item dir

the path to the directory in which to store images (no trailing oblique necessary);

=item rename

Default value is 0, which allows images to be saved with their original names.
If set with a value of 1, images will be given new names based on the time
they were saved at. If set to 2, images will be given filenames according to their
source location.

=item todo

one or more URL to process: can be an anonymous array, array reference, or scalar.

=item dont

As C<todo>, above, but URLs should be ignored.

If one of these is C<ALL>, then will ignore all B<HTML> documents
that do not match exactly those in the C<todo> array of URLs to process.
If one of these is C<NONE>, will ignore no documents.

=item ext_ok

A regular expression 'or' list of image extensions to match.

Will be applied at the end of a filename, after a point, and is insensitive to case.

Defaults to C<(jpg|jpeg|bmp|gif|png|xbm|xmp)>.

=item ext_bad

As C<ext_ok> (above), but default value is:C<(wmv|avi|rm|mpg|asf|ram|asx|mpeg|mp3)>

=item match_url

The minimum path a URL must contain. This can be a scalar or an array reference.

=item min_size.

The minimum size an image can be if it is to be saved.

=item max_size

The maximum size an image can be if it is to be saved.

=back

The object has several private variables, which
you can access for the results when the job is done.
However, do check out the public methods for accessing
these.

=over 4

=item DONE

a hash keys of which are the original URLs of the images, value being are the local filenames.

=item FAILED

a hash, keys of which are the failed URLs, values being short reasons.

=cut

sub new { my ($class) = (shift);
	warn "Making new ",__PACKAGE__ if $CHAT;
    unless (defined $class) {
    	carp "Usage: ".__PACKAGE__."->new( {key=>value} )\n";
    	return undef;
	}
	my %args;

	# Take parameters and place in object slots/set as instance variables
	if (ref $_[0] eq 'HASH'){	%args = %{$_[0]} }
	elsif (not ref $_[0]){		%args = @_ }
	else {
		carp "Usage: $class->new( { key=>values, } )";
		return undef;
	}
	my $self = bless {}, $class;

	# Slots that have default values:
	# $self->{min_size};
	# $self->{match_url}
	# $self->{dir},
	# $todo,= []
	$self->{dont} = [];
	# $MINIMGSIZE
	$self->{ext_ok} = $EXTENSIONS_RE;	# Defualt extensions to use
	$self->{ext_bad} = $EXTENSIONS_BAD; # Ditto for ignore.
	$self->{rename} = 0;
	$self->{max_attempts} = 3;

	# Set/overwrite public slots with user's values
	foreach (keys %args) {
		$self->{lc $_} = $args{$_};
		warn "$_ -> $self->{$_}\n" if $CHAT;
	}

	# Catch parameter errors
	if (not exists $self->{dir} or not defined $self->{dir}){
		croak "No 'dir' slot defined";
	}
	if (!-d $self->{dir}){
		croak "The dir to save to <$self->{dir}> could not be found or is not a directory";
	}
	if (not exists $self->{todo}){
		croak "The 'todo' slot is not defined";
	}

	# React to user slots
	if (exists $self->{chat} and defined $self->{chat}){
		$CHAT = 1;
		warn "Chat mode on";
	} else { undef $CHAT	}

	# Turn scalars into arrays for later use
	if (exists $self->{match_url} and not ref $self->{match_url}){
		$self->{match_url} = [$self->{match_url}];
	}
	if (exists $self->{todo} and not ref $self->{todo}){
		$self->{todo} = [$self->{todo}];
	}
	if (exists $self->{dont} and not ref $self->{dont}){
		$self->{dont} = [$self->{dont}];
	}
	@_ = @{$self->{todo}};
	$self->{todo} = {};
	foreach (@_){ $self->{todo}->{$_} = 1 }
	if ($self->{dont}){
		@_ = @{$self->{dont}};
		$self->{dont} = {};
		foreach (@_){ $self->{dont}->{$_} = 1 }
	}

	# Slots that are not adjustable by user:
	$self->{DONE}	= {};
	$self->{FAILED} = {};

	DOC:
	while (keys %{$self->{todo}} ){
		@_ = keys %{$self->{todo}};
		my $doc_url = shift @_;
		warn "-"x60,"\n" if $CHAT;
		my ($doc,$p);
		# If using match_url feature: ignore doc if not match start of one string
		if (exists $self->{match_url}){
			foreach (@{$self->{match_url}}){
				if ($doc_url !~ /^$_/){
					warn "URL out of scope: $doc_url $_\n" if $CHAT;
					delete $self->{todo}->{$doc_url};
					next DOC;
				} else {
					warn "URL ok by $_\n" if $CHAT;
				}
			}
		}

		if (exists $self->{FAILED}->{$doc_url} or exists $self->{DONE}->{$doc_url}){
			warn "Already done $doc_url.\n" if $CHAT;
			delete $self->{todo}->{$doc_url};
			next DOC;
		}

		if (exists $self->{dont}->{$doc_url}){
			warn "In IGNORE list: $doc_url.\n" if $CHAT;
			delete $self->{todo}->{$doc_url};
			next DOC;
		}

		if (exists $self->{dont}->{ALL} and not $self->{todo}->{$doc_url}){
			warn "Not in TODO list: $doc_url.\n" if $CHAT;
			delete $self->{todo}->{$doc_url};
			next DOC;
		}

		# Not in do list, not an image, not run with IGNORE NONE option
		if (not exists $self->{todo}->{$doc_url} and $doc_url !~ m|(\.$self->{ext_ok})$|i
		and not exists $self->{dont}->{NONE}){
			warn "Not in DO list - ignoring $doc_url .\n" if $CHAT;
			$self->{dont}->{$doc_url} = "Ignoring";
			delete $self->{todo}->{$doc_url};
			next DOC;
		}

		unless ($doc = $self->get_document($doc_url)){
			warn "Agent could not open $doc_url" if $CHAT;
			$self->{FAILED}->{$doc_url} = "Agent couldn't open document";
			delete $self->{todo}->{$doc_url};
			next DOC;
		}

		# If an image, save it
		if ($doc_url =~ m|(\.$self->{ext_ok})$|i) {
			$self->{DONE}->{$doc_url} = $self->_save_img($doc_url,$doc);
			warn "OK: $doc_url" if $CHAT;
			delete $self->{todo}->{$doc_url};
			next DOC;
		} else {
			$self->{DONE}->{$doc_url} = "Did HTML.";
			delete $self->{todo}->{$doc_url};
		}

		# Otherwise try to parse it
		unless ($p = new HTML::TokeParser( \$doc )){
			warn "* Couldn't create parser from \$doc\n" if $CHAT;
			$self->{FAILED}->{$doc_url} = "Couldn't create agent parser";
			delete $self->{todo}->{$doc_url};
			next DOC;
		}
		warn "OK - parsing document $doc_url ...\n" if $CHAT;

		while (my $token = $p->get_token){

			if (@$token[1] eq 'img' and exists @$token[2]->{src}){
				warn "*** Found image: @$token[2]->{src}\n" if $CHAT;
				my $uri = &abs_url( $doc_url, @$token[2]->{src} );
				if ($uri and not exists $self->{IGNORE0}->{$uri} and not exists $self->{DONE}->{$uri} and not exists $self->{FAILED}->{$uri}
				){
					$self->{todo}->{$uri} = 1;
				} else {
					warn "\t ignoring that img.\n" if $CHAT;
				}
			}
			elsif (@$token[1] =~ /^(area|a)$/ and exists @$token[2]->{href} and @$token[0] eq 'S'){
				warn "*** Found link: @$token[2]->{href}\n" if $CHAT;
				my $uri = &abs_url( $doc_url, @$token[2]->{href} );
				if ($uri and not exists $self->{dont}->{$uri} and not exists $self->{DONE}->{$uri} and not exists $self->{FAILED}->{$uri}
				and not (exists $self->{dont}->{ALL} and not exists $self->{todo}->{$uri})
				){
					$self->{todo}->{$uri} = 1;
				} else {
					warn "\t ignoring that link.\n" if $CHAT;
				}
			}
			elsif (@$token[1] eq 'frame' and exists(@$token[2]->{src})){	# This block (DL)
				warn "*** Found frame: @$token[2]->{src}\n" if $CHAT;
				my $uri = &abs_url( $doc_url, @$token[2]->{src} );
				if ($uri and not exists $self->{IGNORE0}->{$uri} and not exists $self->{DONE}->{$uri} and not exists $self->{FAILED}->{$uri}
				and not (exists $self->{dont}->{ALL} and not exists $self->{todo}->{$uri})				){
					$self->{todo}->{$uri} = 1;
				} else {
					warn "\t ignoring that frame.\n" if $CHAT;
				}
			}
		}	# Next token
		delete $self->{todo}->{$doc_url};
	} # Next DOC

	return $self;
} # End sub new





#
# SUB get_document
# Accepts a URL, returns the source of the document at the URL
#	or undef on failure
#
sub get_document { my ($self,$url) = (shift,shift);		# Recieve as argument the URL to access
	if ($url =~ m|(\.$self->{ext_bad})$|i) {				# (DL)
		warn "Ignoring - extension on the 'bad' list" if $CHAT;
		return undef;
	}
	my ($req,$res);
	my $ua = LWP::UserAgent->new;						# Create a new UserAgent
	for my $attempt (1..$self->{max_attempts}){
		if ($attempt!=1 and $attempt-1 == $self->{max_attempts}){
			$ua->agent('MSIE Internet Explorer 6.0 (Mozilla compatible'); # Naughty?
		} else {
			$ua->agent('Perl::'.__PACKAGE__.' v'.$VERSION);	# Give it a type name
		}
		warn "Attempt ($attempt) to access <$url>...\n"  if $CHAT;
		$req = new HTTP::Request('GET', $url); 			# Format URL request
		next if not defined $req;
		$res = $ua->request($req);						# $res is the object UA returned
		last if $res->is_success();					# If not successful
	}
	if (not defined $req){
		warn "...could not GET.\n" if $CHAT;
		return undef;
	}
	if (not $res->is_success()) {						# If not successful
		warn"...failed.\n"  if $CHAT;
		return undef
	}

	warn "...ok.\n" if $CHAT;
	# Test size
	if ((exists $self->{max_size} or exists $self->{min_size})
	and $url =~ m|(\.$self->{ext_ok})$|i) {
		$_ = length ($res->content);
		if (defined $_ and $self->{min_size} and $_ < $self->{min_size}){
			warn "Image size too small, ignoring.\n" if $CHAT;
			$self->{dont}->{$url} = "Size $_ bytes is too small.";
			return undef;
		}
		elsif (defined $_ and $self->{max_size} and $_ > $self->{max_size}){
			warn "Image size too large, ignoring.\n" if $CHAT;
			$self->{dont}->{$url} = "Size $_ bytes is too large.";
			return undef;
		}
	}
	return $res->content;							# $res->content  is the HTML the UA returned from the URL
}



# PRIVATE METHOD _save_img
#
# Accepts and the actual image source.
# Won't store same image twice.
#
# Returns the path the image was saved at.

sub _save_img { my ($self,$url,$img) = (shift,shift,shift,shift);
	local *OUT;
	my $filename;
	# Remvoe any file path from the $url
	if (exists $self->{DONE}->{$url} or exists $self->{FAILED}->{$url}){
		warn "Already got this one ($url), not saving.\n" if $CHAT;
		return undef;
	}
	$url =~ m|/([^./]+)(\.$self->{ext_ok})$|i;
	if ($self->{rename}){
		$filename = $self->{dir}.'/'.(join'',localtime).$2;
	} elsif ($self->{rename} == 2){				# )
		$filename = $url;					# } DL
		$filename =~ s/\/|\:|\~|\?/_/g;		# )
		$filename = $self->{dir}.'\\'.$filename;	# )
	} else {
		$filename = "$self->{dir}/$1$2";
	}
	warn "Saving image as <$filename>...\n"  if $CHAT;
	open OUT,">$filename" or warn "Couldn't open to save <$filename>!" and return "Failed to save.";
		binmode OUT;
		print OUT $img;
	close OUT;
	warn "...ok.\n" if $CHAT;
	return $filename;
}


#
# SUB abs_url returns an absolute URL for a $child_url linked from $parent_url
#
# DOC http://www.netverifier.com/pin/nicolette/jezfuzchr001.html
# SRC /pin/nicolette/jezfuzchr001.jpg
#
sub abs_url { my ($parent_url,$child_url) = (shift,shift);
	if ($child_url =~/^#/){
		return undef;
	}
	my $hack;
	if ($child_url =~ m|^/|) {
		$parent_url =~ s|^(http://[\w.]+)?/.*$|$1|i;
		return $parent_url.$child_url;
	}
	if ($child_url =~ m|^\.\.\/|i){
		$parent_url =~ s/\/[^\/|^~]+$//; # Strip filename (fix: DL)
		if ($parent_url =~ /\/$/){$parent_url =~ s/\/$//;}	# (DL)
		if ($child_url =~ /^\.\//){$child_url =~ s/^\.\///;}	# (DL)
		while ($child_url=~s/^\.\.\///gs ){
			$parent_url =~s/[^\/]+\/?$//;
		}
		$child_url = $parent_url.$child_url;
	} elsif ($child_url !~ m/^http:\/\//i){
		# Assume relative path needs dir
		$parent_url =~ s/\/[^\/]+$//;	# Strip filename
		if ($parent_url =~ /\/$/){ chop $parent_url }
		$child_url = $parent_url .'/'.$child_url;
	}
	return $child_url;
}


=head2 METHOD print_imgs

Print a list of the images saved.

=cut

sub print_imgs { my $self=shift;
	foreach (keys %{$self->{DONE}}){
		next if $_!~$self->{ext_ok};	# hack hack
		print "From $_\n\t$self->{DONE}->{$_}\n";
	}
}

=head2 METHOD imgs_as_hash

Returns a reference to a hash of images saved,
where keys are new image locations, values are original locations.

=cut

sub imgs_as_hash { my $self=shift;
	my $n = {};;
	foreach (keys %{$self->{DONE}}){
		next if $_!~$self->{ext_ok};	# hack hack
		$n->{$self->{DONE}->{$_}} = $_;
	}
	return $n;
}

=head2 METHOD print_done

Print a list of the URLs accessed
and return a reference to a hash of the same.

=cut

sub print_done { my $self=shift;
	foreach (keys %{$self->{DONE}}){
		print "At $_\n\t$self->{DONE}->{$_}\n";
	}
	return \$self->{DONE};
}

=head2 METHOD print_failed

Print a list of the URLs failed, and reasons
and return a reference to a hash of the same.

=cut

sub print_failed { my $self=shift;
	foreach (keys %{$self->{FAILED}}){
		print "At $_\n\t$self->{FAILED}->{$_}\n";
	}
	return \$self->{FAILED};
}

=head2 METHOD print_ignored

Print a list of the URLs ignored
and return a reference to a hash of the same.

=cut

sub print_ignored { my $self=shift;
	foreach (keys %{$self->{IGNORED}}){
		print "At $_\n\t$self->{IGNORED}->{$_}\n";
	}
	return \$self->{IGNORED};
}





1; # Return a true value for 'use'
__END__

=head1 SEE ALSO

Every thing and every one listed above under DEPENDENCIES.

=head1 REVISIONS

B<Version 0.34*>, updates by Lee Goddard:

Re-implemented the C<dont => ['ALL']> feature that got lost during the redesign of the API;
agent now makes multiple attempts to get the image.

B<Version 0.32>, updates by Lee Goddard: fixed bugs.

B<Version 0.31>, updates by Lee Goddard: added 'max_size'.

B<Version 0.3>, updates by Lee Goddard:

Made it a nicer API and tidied up some coding and added a couple of methods.
Started to add tests.

B<Version 0.25>, updates by Duncan Lamb and Lee Goddard:

=over 4

=item * The character C<~> in the URL would confuse the C<abs_url> subroutine, resolving
C<http://www.o.com/~home/page.html> to C<http://www.o.com>. It doesn't
any more.

=item * Double obliques in a link would cause an endless loop - no longer.

=item * A link refrencing its own directory with C<./> would also cause an endless
loop - but no more.

=item * C<EXTENSIONS_BAD> list added.

=item * C<NEWNAMES> updated.

=item * Frame parsing.

=item * Multiple minimum-paths for URLs added.

=back

=head1 USES

C<GetImages.pm> is proud to be part of Duncan Lamb's C<HTTP::StegTest>:

I<An example report can be found at http://64.192.146.9/ in which the library was run against several anti-American and "pro-Taliban" sites. The reports display images that changed between collections, images that tested positive for being altered by an outside program, and images which were "false positives." Over 25,000 images were tested across 10 sites.>

=head1 AUTHOR

Lee Goddard (L<LGoddard@CPAN.org|LGoddard@CPAN.org>) 05/05/2001 16:08 ff.

With updates and fixes from Duncan Lamb (L<duncan_lamb@hotmail.com|duncan_lamb@hotmail.com>), 12/2001.

=head1 COPYRIGHT

Copyright 2000-2001 Lee Goddard.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

