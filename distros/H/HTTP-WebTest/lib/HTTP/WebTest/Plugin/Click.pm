# $Id: Click.pm,v 1.18 2003/09/05 20:01:51 m_ilya Exp $

package HTTP::WebTest::Plugin::Click;

=head1 NAME

HTTP::WebTest::Plugin::Click - Click buttons and links on web page

=head1 SYNOPSIS

    plugins = ( ::Click )

    test_name = Some test
        click_link = Name of the link
    end_test

    test_name = Another test
        click_button = Name of the button
    end_test

=head1 DESCRIPTION

This plugin lets you use the names of links and buttons on HTML pages to
build test requests.

=cut

use strict;
use HTML::TokeParser;
use URI;

use base qw(HTTP::WebTest::Plugin);

=head1 TEST PARAMETERS

=for pod_merge copy opt_params

=head2 click_button

Given name of submit button (i.e. C<<input type="submit"E<gt>> tag or
C<<input type="image"E<gt>> inside of C<<formE<gt>> tag) on previously
requested HTML page, builds test request to the submitted page.

Note that you still need to pass all form parameters yourself using
C<params> test parameter.

=head3 Example

See example in L<HTTP::WebTest::Cookbook|HTTP::WebTest::Cookbook>.

=head2 click_link

Given name of link (i.e. C<<aE<gt>> tag) on previosly requested HTML
page, builds test request to the linked page.

=head3 Example

See example in L<HTTP::WebTest::Cookbook|HTTP::WebTest::Cookbook>.

=head2 form_name

Give form name attribute (i.e. C<<form name="foo"E<gt>>) on previously
requested HTML page, builds test request to the submitted page.

Note that you still need to pass all form parameters yourself using
C<params> test parameter.

=cut

sub param_types {
    return q(click_button scalar
             click_link   scalar
             form_name    scalar);
}

sub prepare_request {
    my $self = shift;

    $self->validate_params(qw(click_button click_link form_name));

    # get current request object
    my $request = $self->webtest->current_request;

    # get number of previous test if any
    my $prev_test_num = $self->webtest->current_test_num - 1;
    return if $prev_test_num < 0;

    # get previous response object
    my $response = $self->webtest->tests->[$prev_test_num]->response;

    # no response - nothing to do
    return unless defined $response;

    # do nothing unless it is HTML
    return unless $response->content_type eq 'text/html';

    # get various params we handle
    my $click_button = $self->test_param('click_button');
    my $click_link   = $self->test_param('click_link');
    my $form_name    = $self->test_param('form_name');

    if(defined $click_link) {
	# find matching link
	my $link = $self->find_link(response => $response,
				    pattern  => $click_link);

	$request->base_uri($link)
	    if defined $link;
    } elsif(defined $click_button) {
	# find action which corresponds to requested submit button
	my $action = $self->find_form(response => $response,
				      pattern  => $click_button);

	$request->base_uri($action)
	    if defined $action;
    } elsif(defined $form_name) {
	# find action which corresponds to requested form name
	my $action = $self->find_form(response  => $response,
				      form_name => $form_name);

	$request->base_uri($action)
	    if defined $action;
    }
}

sub find_base {
    my $self = shift;
    my $response = shift;

    my $base = $response->base;
    my $content = $response->content;

    # look for base tag inside of head tag
    my $parser = HTML::TokeParser->new(\$content);
    my $token = $parser->get_tag('head');
    if(defined $token) {
	$token = $parser->get_tag('base', '/head');
	if($token->[0] eq 'base') {
	    $base = $token->[1]{href};
	}
    }

    return $base;
}

sub find_link {
    my $self = shift;
    my %param = @_;

    my $response = $param{response};
    my $pattern  = $param{pattern};

    my $base    = $self->find_base($response);
    my $content = $response->content;

    # look for matching link tag
    my $parser = HTML::TokeParser->new(\$content);
    my $link = undef;
    while(my $token = $parser->get_tag('a')) {
	my $uri = $token->[1]{href};
	next unless defined $uri;
	if($token->[0] eq 'a') {
	    my $text = $parser->get_trimmed_text('/a');
	    if($text =~ /$pattern/i) {
		$link = $uri;
		last;
	    }
	}
    }

    # we haven't found anything
    return unless defined $link;

    # return link
    return URI->new_abs($link, $base);
}

sub find_form {
    my $self = shift;
    my %param = @_;

    my $response = $param{response};
    my $pattern  = $param{pattern};
    my $form_name = $param{form_name};

    my $base    = $self->find_base($response);
    my $content = $response->content;

    # look for form
    my $parser = HTML::TokeParser->new(\$content);
    my $uri = undef;
  FORM:
    while(my $token = $parser->get_tag('form')) {
	# get action from form tag param
	my $action = $token->[1]{action} || $base;

	if ( $token->[1]{name} and $form_name
	     and ( $token->[1]{name} eq $form_name ) ){
	  $uri = $action;
	  last FORM;
	}
	next unless $pattern;
	# find matching submit button or end of form
	while(my $token = $parser->get_tag('input', '/form')) {
	    my $tag = $token->[0];

	    if($tag eq '/form') {
		# end of form: let's look for another form
		next FORM;
	    }

	    # check if right input control is found
	    my $type  = $token->[1]{type} || 'text';
	    my $name  = $token->[1]{name} || '';
	    my $value = $token->[1]{value} || '';
	    my $src   = $token->[1]{src} || ''; # to handle image submit button
	    next unless $type =~ /^(?:submit|image)$/i;
	    next unless grep /$pattern/i, $name, $value, $src;

	    # stop searching
	    $uri = $action;
	    last FORM;
	}
    }

    # we haven't found anything
    return unless defined $uri;

    # return method and link
    return URI->new_abs($uri, $base);
}

=head1 COPYRIGHT

Copyright (c) 2001-2003 Ilya Martynov.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::API|HTTP::WebTest::API>

L<HTTP::WebTest::Plugin|HTTP::WebTest::Plugin>

L<HTTP::WebTest::Plugins|HTTP::WebTest::Plugins>

=cut

1;
