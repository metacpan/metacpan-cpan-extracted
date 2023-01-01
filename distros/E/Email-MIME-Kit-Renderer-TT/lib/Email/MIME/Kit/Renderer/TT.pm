package Email::MIME::Kit::Renderer::TT 1.003;
use Moose;
with 'Email::MIME::Kit::Role::Renderer';
# ABSTRACT: render parts of your mail with Template-Toolkit

use Template 2.1;

#pod =head1 DESCRIPTION
#pod
#pod This is a renderer plugin for L<Email::MIME::Kit>, and renders message parts
#pod using L<Template Toolkit 2|Template>.  When specifying a renderer in
#pod F<manifest.json>, you might write something like this:
#pod
#pod   { ..., "renderer": "TT" }
#pod
#pod Or, to supply options:
#pod
#pod   {
#pod     ...,
#pod     "renderer": [
#pod       "TT",
#pod       { ...params go here... }
#pod     ]
#pod   }
#pod
#pod There are only three parameters that can be supplied right now:
#pod
#pod C<strict> sets the C<STRICT> Template parameter.  It defaults to 1.
#pod
#pod C<eval_perl> sets the C<EVAL_PERL> Template parameter.  It defaults to 0.
#pod
#pod C<template_parameters> can be a hashref of any parameters to be passed to the
#pod Template constructor.  Setting C<STRICT> or C<EVAL_PERL> here overrides the
#pod C<strict> and C<eval_perl> options.
#pod
#pod =cut

# XXX: _include_path or something
# XXX: we can maybe default to the kit dir if the KitReader is Dir

sub render {
  my ($self, $input_ref, $stash) = @_;
  $stash ||= {};

  my $output;
  $self->_tt->process($input_ref, $stash, \$output)
    or die $self->_tt->error;

  return \$output;
}

has eval_perl => (
  is   => 'ro',
  isa  => 'Bool',
  default => 0,
);

has strict => (
  is   => 'ro',
  isa  => 'Bool',
  default => 1,
);

has template_parameters => (
  is  => 'ro',
  isa => 'HashRef',
  default => sub { {} },
);

has _tt => (
  is   => 'ro',
  isa  => 'Template',
  lazy => 1,
  init_arg => undef,
  default  => sub {
    my ($self) = @_;
    Template->new({
      ABSOLUTE  => 0,
      RELATIVE  => 0,
      STRICT    => $self->strict,
      EVAL_PERL => $self->eval_perl,
      %{ $self->template_parameters },
    });
  },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Email::MIME::Kit::Renderer::TT - render parts of your mail with Template-Toolkit

=head1 VERSION

version 1.003

=head1 DESCRIPTION

This is a renderer plugin for L<Email::MIME::Kit>, and renders message parts
using L<Template Toolkit 2|Template>.  When specifying a renderer in
F<manifest.json>, you might write something like this:

  { ..., "renderer": "TT" }

Or, to supply options:

  {
    ...,
    "renderer": [
      "TT",
      { ...params go here... }
    ]
  }

There are only three parameters that can be supplied right now:

C<strict> sets the C<STRICT> Template parameter.  It defaults to 1.

C<eval_perl> sets the C<EVAL_PERL> Template parameter.  It defaults to 0.

C<template_parameters> can be a hashref of any parameters to be passed to the
Template constructor.  Setting C<STRICT> or C<EVAL_PERL> here overrides the
C<strict> and C<eval_perl> options.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 CONTRIBUTOR

=for stopwords Ricardo Signes

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
