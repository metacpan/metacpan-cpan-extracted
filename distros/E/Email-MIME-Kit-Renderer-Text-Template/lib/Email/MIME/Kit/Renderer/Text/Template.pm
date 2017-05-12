package Email::MIME::Kit::Renderer::Text::Template;
{
  $Email::MIME::Kit::Renderer::Text::Template::VERSION = '1.101302';
}
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


has template_class => (
  is  => 'ro',
  isa => 'Str',
  default => 'Text::Template',
);


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

=head1 NAME

Email::MIME::Kit::Renderer::Text::Template - render parts of your mail with Text::Template

=head1 VERSION

version 1.101302

=head1 ATTRIBUTES

=head2 template_class

This attribute stores the name of the class that will be standing in for
Text::Template, if any.  It defaults, obviously, to Text::Template.

=head2 template_args

These are the arguments that will be passed to C<fill_this_in> along with the
template, input, and a few required handlers.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
