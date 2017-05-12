package HTML::XSSLint;

use strict;
use vars qw($VERSION);
$VERSION = 0.01;

require LWP::UserAgent;
use base qw(LWP::UserAgent);

use Digest::MD5;
use HTML::XSSLint::Result;
use HTML::Form;
use HTTP::Request;
use URI;

sub _croak { require Carp; Carp::croak(@_); }

sub audit {
    my($self, $uri) = @_;
    $uri = URI->new($uri);

    my $request  = HTTP::Request->new(GET => $uri);
    my $response = $self->request($request);
    $response->is_success or _croak("Can't fetch $uri");

    my @forms = HTML::Form->parse($response->content, $uri);
    return wantarray ? (map $self->do_audit($_), @forms) : $self->do_audit($forms[0]);
}

sub do_audit {
    my($self, $form) = @_;
    my $params   = $self->make_params($form->inputs);
    my $request  = $self->fillin_and_click($form, $params);
    my $response = $self->request($request);
    $response->is_success or _croak("Can't fetch " . $form->action);

    my @names = $self->compare($response->content, $params);
    return HTML::XSSLint::Result->new(
	form => $form,
	names => \@names,
    );
}

sub make_params {
    my($self, @inputs) = @_;
    my %params = map {
	my $value = $self->random_string;
	($_->name => "<>$value");
    } grep {
	defined($_->name) && length($_->name)
    } @inputs;
    return \%params;
}

sub random_string {
    my $self = shift;
    return substr(Digest::MD5::md5_hex(rand() . {} . $$ . time), 0, 8);
}

sub fillin_and_click {
    my($self, $form, $params) = @_;
    local *HTML::Form::ListInput::value = \&hf_li_value; # hack it
    for my $name (keys %$params) {
	$form->value($name => $params->{$name});
    }
    return $form->click;
}

sub compare {
    my($self, $html, $params) = @_;
    return grep {
	my $value = $params->{$_};
	$html =~ /$value/;
    } keys %$params;
}

sub hf_li_value {
    my $self = shift;
    my $old = $self->{value};
    $self->{value} = shift if @_;
    $old;
}

1;
__END__

=head1 NAME

HTML::XSSLint - audit XSS vulnerability of web pages

=head1 SYNOPSIS

  use HTML::XSSLint;

  my $agent   = HTML::XSSLint->new;

  # there may be multiple forms in a single HTML
  # if there's no from, @result is empty
  my @result  = $agent->audit($url);

  for my $result (grep { $_->vulnerable } @result) {
      my $action  = $result->action;
      my @names   = $result->names;
      my $example = $result->example;
  }

=head1 DESCRIPTION

HTML::XSSLint is a subclass of LWP::UserAgent to audit Cross Site
Scripting (XSS) vulnerability by generating random input against HTML
forms in a web page.

Note that the way this module works is not robust, so you can't say a
web page is XSS free because it passes HTML::XSSLint audit.

This module is a backend for command line utility C<xsslint> bundled
in the distribution. See L<xsslint> for details.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This module comes with B<NO WARRANTY>.

=head1 SEE ALSO

L<xsslint>, L<HTML::XSSLint::Result>, L<LWP>, L<HTML::Form>

=cut
