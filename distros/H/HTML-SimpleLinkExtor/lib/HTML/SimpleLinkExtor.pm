package HTML::SimpleLinkExtor;
use strict;

use warnings;
no warnings;

use subs qw();
use vars qw( $AUTOLOAD );

use AutoLoader;
use Carp qw(carp);
use HTML::LinkExtor;
use LWP::UserAgent;
use URI;

our $VERSION = '1.272';

use parent qw(HTML::LinkExtor);

our %AUTO_METHODS = qw(
    background attribute
	href	attribute
	src		attribute

	a		tag
	area	tag
	base    tag
	body    tag
	img		tag
	frame	tag
	iframe  tag

	script	tag
	);


sub DESTROY { 1 };

sub AUTOLOAD {
	my $self = shift;
	my $method = $AUTOLOAD;

	$method =~ s/.*:://;

	unless( exists $AUTO_METHODS{$method} ) {
		carp __PACKAGE__ . ": method $method unknown";
		return;
		}

	$self->_extract( $method );
	}

sub can {
	my( $self, @methods ) = @_;

	foreach my $method ( @methods ) {
		return 0 unless $self->_can( $method );
		}

	return 1;
	}

sub _can {
	no strict 'refs';

	return 1 if exists $AUTO_METHODS{ $_[1] };
	return 1 if defined &{"$_[1]"};

	return 0;
	}

sub _init_links {
	my $self  = shift;
	my $links = shift;
	do {
		delete $self->{'_SimpleLinkExtor_links'};
		return
		} unless ref $links eq ref [];

	$self->{'_SimpleLinkExtor_links'} = $links;

	$self;
	}

sub _link_refs {
	my $self = shift;

	my @link_refs;
	# XXX: this is a bad way to do this. I should check if the
	# value is a reference. If I want to reset the links, for
	# instance, I can't just set it to [] because it then goes
	# through this branch. In _init_links I have to use a delete
	# which I really don't like. I don't have time to rewrite this
	# right now though --brian, 20050816
	if( ref $self->{'_SimpleLinkExtor_links'} ) {
		@link_refs = @{$self->{'_SimpleLinkExtor_links'}};
		}
	else {
		@link_refs = map {
			HTML::SimpleLinkExtor::LinkRef->new( $_ )
			} $self->SUPER::links();
		$self->_init_links( \@link_refs );
		}

	# defined() so that an empty string means "do not resolve"
	unless( defined $self->{'_SimpleLinkExtor_base'} ) {
		my $count = -1;
		my $found =  0;
		foreach my $link ( @link_refs ) {
			$count++;
			next unless $link->[0] eq 'base' and $link->[1] eq 'href';
			$found = 1;
			$self->{'_SimpleLinkExtor_base'} = $link->[-1];
			last;
			}

		#remove the BASE HREF link - Good idea, bad idea?
		#splice @link_refs, $count, 1, () if $found;
		}

	$self->_add_base(\@link_refs);

	return @link_refs;
	}

sub _extract {
	my $self      = shift;
	my $type      = shift;

	my $method  = $AUTO_METHODS{$type} eq 'tag' ? 'tag' : 'attribute';

	my @links = map  { $_->linkref }
	            grep { $_->$method() eq $type }
	            $self->_link_refs;

	return @links;
	}

sub _add_base {
	my $self      = shift;
	my $array_ref = shift;

	my $base      = $self->{'_SimpleLinkExtor_base'};
	return unless $base;

	foreach my $tuple ( @$array_ref ) {
		foreach my $index ( 1 .. $#$tuple ) {
			next unless exists $AUTO_METHODS{ $tuple->[$index] };

			my $url = URI->new( $tuple->[$index + 1] );
			next unless ref $url;
			$tuple->[$index + 1] = $url->abs($base);
			}
		}
	}

=encoding utf8

=head1 NAME

HTML::SimpleLinkExtor - Extract links from HTML

=head1 SYNOPSIS

	use HTML::SimpleLinkExtor;

	my $extor = HTML::SimpleLinkExtor->new();
	$extor->parse_file($filename);
	#--or--
	$extor->parse($html);

	$extor->parse_file($other_file); # get more links

	$extor->clear_links; # reset the link list

	#extract all of the links
	@all_links   = $extor->links;

	#extract the img links
	@img_srcs    = $extor->img;

	#extract the frame links
	@frame_srcs  = $extor->frame;

	#extract the hrefs
	@area_hrefs  = $extor->area;
	@a_hrefs     = $extor->a;
	@base_hrefs  = $extor->base;
	@hrefs       = $extor->href;

	#extract the body background link
	@body_bg     = $extor->body;
	@background  = $extor->background;

	@links       = $extor->schemes( 'http' );

=head1 DESCRIPTION

THIS IS AN ABANDONED MODULE. THERE IS NO SUPPORT. YOU CAN ADOPT IT
IF YOU LIKE: https://pause.perl.org/pause/query?ACTION=pause_04about#takeover

This is a simple HTML link extractor designed for the person who does
not want to deal with the intricacies of C<HTML::Parser> or the
de-referencing needed to get links out of C<HTML::LinkExtor>.

You can extract all the links or some of the links (based on the HTML
tag name or attribute name). If a C<< <BASE HREF> >> tag is found,
all of the relative URLs will be resolved according to that reference.

This module is simply a subclass around C<HTML::LinkExtor>, so it can
only parse what that module can handle.  Invalid HTML or XHTML may
cause problems.

If you parse multiple files, the link list grows and contains the
aggregate list of links for all of the files parsed. If you want to
reset the link list between files, use the clear_links method.

=head2 Class Methods

=over

=item $extor = HTML::SimpleLinkExtor->new()

Create the link extractor object.

=item $extor = HTML::SimpleLinkExtor->new('')

=item $extor = HTML::SimpleLinkExtor->new($base)

Create the link extractor object and resolve the relative URLs
accoridng to the supplied base URL. The supplied base URL overrides
any other base URL found in the HTML.

Create the link extractor object and do not resolve relative
links.

=cut

sub new {
	my $class = shift;
	my $base  = shift;

	my $self = new HTML::LinkExtor;
	bless $self, $class;

	$self->{'_SimpleLinkExtor_base'} = $base;
	$self->{'_ua'} = LWP::UserAgent->new;
	$self->_init_links;

	return $self;
	}

=item HTML::SimpleLinkExtor->ua;

Returns the internal user agent, an C<LWP::UserAgent> object.

=cut

sub ua { $_[0]->{_ua} }

=item HTML::SimpleLinkExtor->add_tags( TAG [, TAG ] )

C<HTML::SimpleLinkExtor> keeps an internal list of HTML tags (such as
'a' and 'img') that have URLs as values. If you run into another tag
that this module doesn't handle, please send it to me and I'll add it.
Until then you can add that tag to the internal list. This affects
the entire class, including previously created objects.

=cut

sub add_tags {
	my $self = shift;
	my $tag  = lc shift;

	$AUTO_METHODS{ $tag } = 'tag';
	}

=item HTML::SimpleLinkExtor->add_attributes( ATTR [, ATTR] )

C<HTML::SimpleLinkExtor> keeps an internal list of HTML tag attributes
(such as 'href' and 'src') that have URLs as values. If you run into
another attribute that this module doesn't handle, please send it to
me and I'll add it. Until then you can add that attribute to the
internal list. This affects the entire class, including previously
created objects.

=cut

=item can()

A smarter C<can> that can tell which attributes are also methods.

=cut

sub add_attributes {
	my $self = shift;
	my $attr = lc shift;

	$AUTO_METHODS{ $attr } = 'attribute';
	}

=item HTML::SimpleLinkExtor->remove_tags( TAG [, TAG ] )

Take tags out of the internal list that C<HTML::SimpleLinkExtor> uses
to extract URLs. This affects the entire class, including previously
created objects.

=cut

sub remove_tags {
	my $self = shift;
	my $tag  = lc shift;

	delete $AUTO_METHODS{ $tag };
	}

=item HTML::SimpleLinkExtor->remove_attributes( ATTR [, ATTR] )

Takes attributes out of the internal list that
C<HTML::SimpleLinkExtor> uses to extract URLs. This affects the entire
class, including previously created objects.

=cut

sub remove_attributes {
	my $self = shift;
	my $attr = lc shift;

	delete $AUTO_METHODS{ $attr };
	}

=item HTML::SimpleLinkExtor->attribute_list

Returns a list of the attributes C<HTML::SimpleLinkExtor> pays
attention to.

=cut

sub attribute_list {
	my $self = shift;

	grep { $AUTO_METHODS{ $_ } eq 'attribute' } keys %AUTO_METHODS;
	}

=item HTML::SimpleLinkExtor->tag_list

Returns a list of the tags C<HTML::SimpleLinkExtor> pays attention to.
These tags have convenience methods.

=back

=cut

sub tag_list {
	my $self = shift;

	grep { $AUTO_METHODS{ $_ } eq 'tag' } keys %AUTO_METHODS;
	}

=head2 Object methods

=over 4

=item $extor->parse_file( $filename )

Parse the file for links. Inherited from C<HTML::Parser>.

=cut


=item $extor->parse_url( $url [, $ua] )

Fetch URL and parse its content for links.

=cut

sub parse_url {
	my $data = $_[0]->ua->get( $_[1] )->content;

	return unless $data;

	$_[0]->parse( $data );
	}

=item $extor->parse( $data )

Parse the HTML in C<$data>. Inherited from C<HTML::Parser>.

=item $extor->clear_links

Clear the link list. This way, you can use the same parser for
another file.

=cut

sub clear_links { $_[0]->_init_links( [] ) }

=item $extor->links

Return a list of the links.

=cut

sub links {
	map  { $_->linkref }
	grep { $_[0]->_is_an_allowed_tag( $_->tag ) }
	$_[0]->_link_refs
	}

sub _is_an_allowed_tag {
	exists $AUTO_METHODS{$_[1]}
		and
	$AUTO_METHODS{$_[1]} eq 'tag'
	}

=item $extor->img

Return a list of the links from all the SRC attributes of the
IMG.

=cut

=item $extor->frame

Return a list of all the links from all the SRC attributes of
the FRAME.

=cut

sub frames { ( $_[0]->frame, $_[0]->iframe ) }

=item $extor->iframe

Return a list of all the links from all the SRC attributes of
the IFRAME.

=item $extor->frames

Returns the combined list from frame and iframe.

=item $extor->src

Return a list of the links from all the SRC attributes of any
tag.

=item $extor->a

Return a list of the links from all the HREF attributes of the
A tags.

=item $extor->area

Return a list of the links from all the HREF attributes of the
AREA tags.

=item $extor->base

Return a list of the links from all the HREF attributes of the
BASE tags.  There should only be one.

=item $extor->href

Return a list of the links from all the HREF attributes of any
tag.

=item $extor->body, $extor->background

Return the link from the BODY tag's BACKGROUND attribute.

=item $extor->script

Return the link from the SCRIPT tag's SRC attribute

=item $extor->schemes( SCHEME, [ SCHEME, ... ] )

Return the links that use any of SCHEME. These must be absolute URLs (which
might include those converted to absolute URLs by specifying a
base). SCHEME is case-insensitive. You can specify more than one
scheme.

In list context it returns the links. In scalar context it returns
the count of the matching links.

=cut

sub schemes {
	my( $self, @schemes ) = @_;

	my %schemes = map { lc, lc } @schemes;

	my @links =
		grep {
			my $scheme = eval { lc URI->new( $_ )->scheme };
			exists $schemes{ $scheme };
			}
		map { $_->linkref }
		$self->_link_refs;

	wantarray ? @links : scalar @links;
	}

=item $extor->absolute_links

Returns the absolute URLs (which might include those converted to
absolute URLs by specifying a base).

In list context it returns the links. In scalar context it returns
the count of the matching links.

=cut

sub absolute_links {
	my $self = shift;

	my @links =
		grep {
			my $scheme = eval { lc URI->new( $_ )->scheme };
			length $scheme;
			}
		map { $_->linkref }
		$self->_link_refs;

	wantarray ? @links : scalar @links;
	}

=item $extor->relative_links

Returns the relatives URLs (which might exclude those converted to
absolute URLs by specifying a base or having a base in the document).

In list context it returns the links. In scalar context it returns
the count of the matching links.


=cut

sub relative_links {
	my $self = shift;

	my @links =
		grep {
			my $scheme = eval { URI->new( $_ )->scheme };
			! defined $scheme;
			}
		map { $_->linkref }
			$self->_link_refs;

	wantarray ? @links : scalar @links;
	}

=back

=head1 TO DO

This module doesn't handle all of the HTML tags that might
have links.  If someone wants those, I'll add them, or you
can edit C<%AUTO_METHODS> in the source.

=head1 CREDITS

Will Crain who identified a problem with IMG links that had
a USEMAP attribute.

=head1 SOURCE AVAILABILITY

This module is in Github

	https://github.com:CPAN-Adoptable-Modules/html-simplelinkextor.git

=head1 AUTHORS

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2004-2019, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=cut

BEGIN {
package
	HTML::SimpleLinkExtor::LinkRef;
use Carp qw(croak);

sub new {
	my( $class, $arrayref ) = @_;
	croak "Not an array reference argument!" unless ref $arrayref eq ref [];
	bless $arrayref, $class;
	}

sub tag       { $_[0]->[0] }
sub attribute { $_[0]->[1] }
sub linkref   { $_[0]->[2] }
}

1;

__END__
