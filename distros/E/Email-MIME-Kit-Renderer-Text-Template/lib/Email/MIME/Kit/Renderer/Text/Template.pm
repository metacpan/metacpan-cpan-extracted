package Email::MIME::Kit::Renderer::Text::Template 1.101304;
use Moose;
with 'Email::MIME::Kit::Role::Renderer';
# ABSTRACT: render parts of your mail with Text::Template

use Module::Runtime ();

sub _enref_as_needed {
  my ($self, $hash) = @_;

  my %return;
  while (my ($k, $v) = each %$hash) {
    $return{ $k } = (ref $v and not blessed $v) ? $v : \$v;
  }

  return \%return;
}

#pod =attr template_class
#pod
#pod This attribute stores the name of the class that will be standing in for
#pod Text::Template, if any.  It defaults, obviously, to Text::Template.
#pod
#pod =cut

has template_class => (
  is  => 'ro',
  isa => 'Str',
  default => 'Text::Template',
);

#pod =attr template_args
#pod
#pod These are the arguments that will be passed to C<fill_this_in> along with the
#pod template, input, and a few required handlers.
#pod
#pod =cut

has template_args => (
  is  => 'ro',
  isa => 'HashRef',
);

sub render  {
  my ($self, $input_ref, $args)= @_;

  my $hash = $self->_enref_as_needed({
    (map {; $_ => ref $args->{$_} ? $args->{$_} : \$args->{$_} } keys %$args),
  });

  my $template_class = $self->template_class;
  Module::Runtime::require_module($template_class);

  my $result = $template_class->fill_this_in(
    $$input_ref,
    %{ $self->{template_args} || {} },
    HASH   => $hash,
    BROKEN => sub { my %hash = @_; die $hash{error}; },
  );

  # :-(  -- rjbs, 2012-10-01
  die $Text::Template::ERROR unless defined $result;

  return \$result;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Email::MIME::Kit::Renderer::Text::Template - render parts of your mail with Text::Template

=head1 VERSION

version 1.101304

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 ATTRIBUTES

=head2 template_class

This attribute stores the name of the class that will be standing in for
Text::Template, if any.  It defaults, obviously, to Text::Template.

=head2 template_args

These are the arguments that will be passed to C<fill_this_in> along with the
template, input, and a few required handlers.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 CONTRIBUTOR

=for stopwords Ricardo Signes

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
