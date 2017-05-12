package HTML::TreeBuilderX::ASP_NET;
use 5.010;
use strict;
use warnings;

use Moose;
use HTML::TreeBuilderX::ASP_NET::Types qw( htmlAnchorTag htmlFormTag );
use HTTP::Request::Form;
use HTML::Element;
use Carp;

our $VERSION = '0.09';

use mro 'c3';
with 'MooseX::Traits';

has '+_trait_namespace' => (
	isa => 'Str'
	, default => 'HTML::TreeBuilderX::ASP_NET::Roles'
);

has 'hrf' => (
	isa          => 'HTTP::Request::Form'
	, is         => 'ro'
	, handles    => qr/.*/
	, lazy_build => 1
);

has 'element' => (
	isa         => htmlAnchorTag
	, is        => 'ro'
	, predicate => 'has_element'
);

has 'form' => (
	isa          => htmlFormTag
	, is         => 'ro'
	, lazy_build => 1
);

has 'eventTriggerArgument' => (
	isa          => 'HashRef'
	, is         => 'ro'
	, lazy_build => 1
);

has 'baseURL' => ( isa => 'Maybe[URI]', is => 'ro' );

has 'debug' => ( isa => 'Bool', is => 'ro', default => 0 );

sub httpRequest {
	my ( $self, @args ) = @_;
	$self->press(@args);
}

sub _build_eventTriggerArgument {
	my $self = shift;

	Carp::croak
		'User must provide an eventTriggerArgument, '
		. ' or an element to generate one from'
		unless $self->has_element
	;

	parseDoPostBack( $self->element );

}

sub _build_form {
	my $self = shift;

	Carp::croak
		'Please construct with either an HTML::Element of tag <form>'
		. ' or with a child HTML::Element of a <form>'
		unless $self->has_element
	;

	my $form = $self->element->look_up( _tag => 'form' );

	Carp::croak 'Please ensure there is a parent <form>'
		. ' of the provided HTML::Element <'.$self->element->tag.'>'
		unless defined $form
	;

	$form

}

around 'form' => sub {
	my ( $sub, $self, @args ) = @_;

	my $form = $self->$sub( @args );
	$form->push_content($_) for createInputElements($self->eventTriggerArgument);

	$form;
	
};

sub _build_hrf {
	my $self = shift;

	HTTP::Request::Form->new(
		$self->form
		, $self->baseURL
		, $self->debug
	);

}

##
## END Moose, the other two funcs are helpers
##
sub parseDoPostBack {
	my ($element) = @_;

	(
		$element->attr('href')
		// $element->attr('onchange')
	)  =~  /__doPostBack\((.*)\)/;

	$1 =~ s/\\'/'/g;
	my $args = $1;
	my ( $eventTarget, $eventArgument ) = split /\s*,\s*/, $args;

	Carp::croak 'Please submit a valid __doPostBack'
		unless $eventTarget && $eventArgument
	;

	s/^'// && s/'$// for ($eventTarget, $eventArgument);

	return { $eventTarget, $eventArgument };

}

sub createInputElements {
	my $hash = shift;

	Carp::croak 'createInputElements requires a HashRef'
		unless ref $hash eq 'HASH'
	;

	my ( $eventTarget, $eventArgument ) = %$hash;
	my @elements = (
		HTML::Element->new(
			'input'
			, name  => '__EVENTTARGET'
			, value => $eventTarget
		)
		, HTML::Element->new(
			'input'
			, name  => '__EVENTARGUMENT'
			, value => $eventArgument
		)
	);

	\@elements;

}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

HTML::TreeBuilderX::ASP_NET - Scrape ASP.NET/VB.NET sites which utilize Javascript POST-backs.

=head1 SYNOPSIS

	my $ua = LWP::UserAgent->new;
	my $resp = $ua->get('http://uniqueUrl.com/Server.aspx');
	my $root = HTML::TreeBuilder->new_from_content( $resp->content );
	my $a = $root->look_down( _tag => 'a', id => 'nextPage' );
	my $aspnet = HTML::TreeBuilderX::ASP_NET->new({
		element   => $a
		, baseURL =>$resp->request->uri ## takes into account posting redirects
	});
	my $resp = $ua->request( $aspnet->httpResponse );

	## or the easy cheating way see the SEE ALSO section for links
	my $aspnet = HTML::TreeBuilderX::ASP_NET->new_with_traits( traits => ['htmlElement'] );
	$form->look_down(_tag=> 'a')->httpResponse

=head1 DESCRIPTION

Scrape ASP.NET sites which utilize the language's __VIEWSTATE, __EVENTTARGET, __EVENTARGUMENT, __LASTFOCUS, et al. This module returns a HTTP::Response from the form with the use of the method C<-E<gt>httpResponse>.

In this scheme many of the links on a webpage will apear to be javascript functions. The default Javascript function is C<__doPostBack(eventTarget, eventArgument)>. ASP.NET has two hidden fields which record state: __VIEWSTATE, and __LASTFOCUS. It abstracts each link with a method that utilizes an HTTP post-back to the server. The Javascript behind C<__doPostBack> simply appends __EVENTTARGET=$eventTarget&__EVENTARGUMENT=$eventArgument onto the POST request from the parent form and submits it. When the server receives this request it decodes and decompresses the __VIEWSTATE and uses it along with the new __EVENTTARGET and __EVENTARGUMENT to perform the action, which is often no more than serializing the data back into the __VIEWSTATE.

Sometimes developers cloak the C<__doPostBack(target,arg)> with names akin to C<changepage(arg)> which simply call C<__doPostBack("target", arg)>. This module will handle this use case as well using the explicit an eventTriggerArugment in the constructor.

This flow is a bane on RESTLESS http and makes no sense whatsoever. Thanks Microsoft.

      .-------------------------------------------------------------------.
      |                            HTML FORM 1                            |
      | <form action="Server.aspx" method="post">                         |
      | <input type="hidden" name="__VIEWSTATE" value="encryptedXML-FOO"> |
      | <a>1</a> |                                                        |
      | <a href="javascript:__doPostBack('gotopage','2')">2</a>           |
      | ...                                                               |
      '-------------------------------------------------------------------'
                                        |
                                        v
                       _________________________________
                       \                                \
                        ) User clicks the link named "2" )
                       /________________________________/
                                        |
                                        v
   .------------------------------------------------------------------------.
   | POST http://aspxnonsensery/Server.aspx                                 |
   | Content-Length: 2659                                                   |
   | Content-Type: application/x-www-form-urlencoded                        |
   |                                                                        |
   | __VIEWSTATE=encryptedXML-FOO&__EVENTTARGET=gotopage1&__EVENTARGUMENT=2 |
   '------------------------------------------------------------------------'
                                        |
                                        v
    .----------------------------------------------------------------------.
    |                             HTML FORM 2                              |
    |                       (different __VIEWSTATE)                        |
    | <form action="Server.aspx" method="post">                            |
    | <input type="hidden" name="__VIEWSTATE" value="encryptedXML-BAR">    |
    | <a href="javascript:__doPostBack('gotopage','1')">1</a> |            |
    | <a>2</a>                                                             |
    | ...                                                                  |
    '----------------------------------------------------------------------'

=head2 METHODS

B< IN ADDITION TO ALL OF THE METHODS FROM L<HTTP::Request::Form> >

=over 4

=item ->new({ hashref })

Takes a HashRef, returns a new instance some of the possible key/values are:

=over 4

=item form => $htmlElement

optional: You explicitly send the HTML::Elmenet representing the form.  If you do not one will be implicitly deduced from the $self->element, making element=>$htmlElement a requirement

=item eventTriggerArgument => $hashRef

Not needed if you supply an element.  This takes a HashRef and will create HTML::Elements that mimmick hidden input fields. From which to tack onto the $self->form.

=item element => $htmlElement

Not needed if you send an eventTriggerArgument. Attempts to deduce the __EVENTARGUMENT and __EVENTTARGET from the 'href' attribute of the element just as if the two were supplied explicitly.  It will also be used to deduce a form by looking up in the HTML tree if one is not supplied.

=item debug => *0|1

optional: Sends the debug flag H:R:F, default is off.

=item baseURL => $uri

optional: Sets the base of the URL for the post action

=back

=item ->httpRequest

Returns an L<HTTP::Request> object for the HTTP POST

=item ->hrf

Explicitly return the underlying L<HTTP::Request::Form> object. All methods fallback here anyway, but this will return that object directly.

=back

=head2 FUNCTIONS

None of these are exported...

=over 4

=item createInputElements( {eventTarget => eventArgument} )

Helper function takes two values in an HashRef. Assumes the key is the __EVENTTARGET and value the __EVENTARGUMENT, returns two L<HTML::Element> pseudo-input fields with the information.

=item parseDoPostBack( $str )

Accepts a string that is often the "href" attribute of an HTTP::Element. It simple parses out the call to Javascript, using regexes, and makes the two args useable to perl in the form of an HashRef.

=back

=head1 SEE ALSO

=over 4

=item	L<HTML::TreeBuilderX::ASP_NET::Roles::htmlElement>

For an easy way to glue the two together

=item L<HTTP::Request>

For the object the method htmlElement returns

=item L<HTTP::Request::Form>

For a base class, to which all methods are valid

=item HTML::Element

For the base class of all HTML tokens

=back

=head1 AUTHOR

Evan Carroll, C<< <me at evancarroll.com> >>

=head1 BUGS

None, though *much* more support should be added to ->element. Not everthing is a simple anchor tag.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc HTML::TreeBuilderX::ASP_NET


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-TreeBuilderX-ASP_NET>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-TreeBuilderX-ASP_NET>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-TreeBuilderX-ASP_NET>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-TreeBuilderX-ASP_NET>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2008 Evan Carroll, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

