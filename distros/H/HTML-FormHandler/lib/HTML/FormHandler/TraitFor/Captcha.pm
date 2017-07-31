package HTML::FormHandler::TraitFor::Captcha;
# ABSTRACT: generate and validate captchas
$HTML::FormHandler::TraitFor::Captcha::VERSION = '0.40068';
use HTML::FormHandler::Moose::Role;
use GD::SecurityImage;
use HTTP::Date;

requires('ctx');

has_field 'captcha' => ( type => 'Captcha', label => 'Verification' );


sub get_captcha {
    my $self = shift;
    return unless $self->ctx;
    my $captcha;
    $captcha = $self->ctx->session->{captcha};
    return $captcha;
}


sub set_captcha {
    my ( $self, $captcha ) = @_;
    return unless $self->ctx;
    $self->ctx->session( captcha => $captcha );
}


sub captcha_image_url {
    return '/captcha/image';
}

use namespace::autoclean;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::TraitFor::Captcha - generate and validate captchas

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

A role to use in a form to implement a captcha field.

   package MyApp::Form;
   use HTML::FormHandler::Moose;
   with 'HTML::FormHandler::TraitFor::Captcha';

or

   my $form = MyApp::Form->new( traits => ['HTML::FormHandler::TraitFor::Captcha'],
       ctx => $c );

Needs a context object set in the form's 'ctx' attribute which has a session
hashref in which to store a 'captcha' hashref, such as is provided by Catalyst
session plugin.

=head1 METHODS

=head2 get_captcha

Get a captcha stored in C<< $form->ctx->{session} >>

=head1 set_captcha

Set a captcha in C<< $self->ctx->{session} >>

=head2 captcha_image_url

Default is '/captcha/image'. Override in a form to change.

   sub captcha_image_url { '/my/image/url/' }

Example of a Catalyst action to handle the image:

    sub image : Local {
        my ( $self, $c ) = @_;
        my $captcha = $c->session->{captcha};
        $c->response->body($captcha->{image});
        $c->response->content_type('image/'. $captcha->{type});
        $c->res->headers->expires( time() );
        $c->res->headers->header( 'Last-Modified' => HTTP::Date::time2str );
        $c->res->headers->header( 'Pragma'        => 'no-cache' );
        $c->res->headers->header( 'Cache-Control' => 'no-cache' );
    }

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
