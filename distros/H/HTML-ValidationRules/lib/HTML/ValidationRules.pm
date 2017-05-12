package HTML::ValidationRules;
use 5.008001;
use strict;
use warnings;

our $VERSION = '0.02';

use HTML::ValidationRules::Parser;

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

sub parser {
    my ($self) = @_;
    $self->{parser} ||= HTML::ValidationRules::Parser->new(%$self);
}

sub load_rules {
    my ($self, %args) = @_;
    $self->parser->load_rules(%args);
}

!!1;

__END__

=encoding utf8

=head1 NAME

HTML::ValidationRules - Extract Validation Rules from HTML Form
Element

=head1 SYNOPSIS

  # form.html
  <!doctype html>
  <html>
    <head>
      <meta charset="UTF-8">
      <title>HTML5::ValidationRules</title>
    </head>
    <body>
      <form method="post" action="/post">
        <input type="text" name="text" pattern="[A-Za-z0-9]+" maxlength="255" />
        <input type="url" name="url" maxlength="255" required />
        <input type="email" name="email" maxlength="255" required="required" />
        <input type="number" name="number" min="200" max="800" />
        <textarea name="textarea" maxlength="1000" required></textarea>
        <input type="range"" name="range" min="20" max="80" />
        <input type="submit" value="submit" />
      </form>
    </body>
  </html>

  # in your code
  use HTML::ValidationRules;

  my $parser = HTML::ValidationRules->new;
  my $rules  = $parser->load_rules(file => 'form.html');

  # rules will be extracted as follows:
  # [
  #     text     => [ [ HTML_PATTERN => '[A-Za-z0-9]+' ], [ HTML_MAXLENGTH => 255 ] ],
  #     url      => [ HTML_URL    => [ HTML_MAXLENGTH => 255 ], 'NOT_BLANK'         ],
  #     email    => [ HTML_EMAIL  => [ HTML_MAXLENGTH => 255 ], 'NOT_BLANK'         ],
  #     number   => [ HTML_NUMBER => [ HTML_MIN => 200 ], [ HTML_MAX => 800 ]       ],
  #     textarea => [ [ HTML_MAXLENGTH => 1000 ], 'NOT_BLANK'                       ],
  #     range    => [ HTML_RANGE => [ HTML_MIN => 20 ], [ HTML_MAX => 80 ]          ],
  # ]

  # then do validation using FormValidator::Simple
  use FormValidator::Simple qw(HTML);

  my $query  = CGI->new;
  my $result = FormValidator::Simple->check($query => $rules);

  # or FormValidator::Lite
  use FormValidator::Lite;
  FormValidator::Lite->load_constraints('HTML');

  my $query     = CGI->new;
  my $validator = FormValidator::Lite->new($query);
  my $result    = $validator->check(@$rules);

=head1 DESCRIPTION

HTML::ValidationRules regards HTML form element as validation rules
definition and extract rules from it.

=head1 WARNING

B<This software is under the heavy development and considered ALPHA
quality now. Things might be broken, not all features have been
implemented, and APIs will be likely to change. YOU HAVE BEEN WARNED.>

=head1 METHODS

=head2 new(C<%args>)

=over

  my $parser = HTML::ValidationRules->new(
      options => { ... } #=> options for HTML::Parser
  );

Returns a new HTML::ValidationRules object.

=back

=head2 load_rules(C<%args>)

=over

  my $rules = $parser->load_rules(file => 'form.html');

Parse HTML and extract validation rules from form element (defined as
HTML5 client-side form validation spec, but not all of
them). C<$rules> has compatible form as args for
L<FormValidator::Simple> and L<FormValidator::Lite>'s check() method.

C<%args> are supposed to contain one of them below:

=over

=item * file

Path to a file or filehandle.

=item * html

String of HTML.

=back

=back

=head1 SUPPORTED ATTRIBUTES

HTML C<input>, C<textare>, and C<select> elements can have some
attributes related to validation. This module hasn't support all the
attrs defined in HTML5 spec yet, just has done below so far:

=over

=item * max (input)

=item * maxlength (input, textarea)

=item * min (input)

=item * pattern (input)

=item * required (input, textarea, select)

=item * type (input)

=over

=item * type:url

=item * type:email

=item * type:number

=item * type:range

=back

=back

=head1 BUGS

The C<pattern> attribute is interpreted as a Perl regular expression,
not a JavaScript regular expression as defined by the HTML spec.
Please use common subset of Perl and JavaScript regular expression
languages to keep compatibility with both Perl and Web browsers.

=head1 AUTHORS

=over 4

=item * Kentaro Kuribayashi E<lt>kentarok@gmail.comE<gt>

=item * Wakaba <w@suika.fam.cx>

=back

=head1 SEE ALSO

=over

=item * L<http://www.whatwg.org/specs/web-apps/current-work/multipage/#client-side-form-validation>

=item * L<http://www.whatwg.org/specs/web-apps/current-work/multipage/#the-input-element>

=item * L<http://www.whatwg.org/specs/web-apps/current-work/multipage/#the-textarea-element>

=back

=head1 LICENSE

Copyright (C) Kentaro Kuribayashi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
