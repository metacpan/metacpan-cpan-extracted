# NAME

HTML::FormHandlerX::Widget::Field::Template - render fields using templates

# VERSION

version v0.1.1

# SYNOPSIS

In a form class:

```perl
has_field foo => (
  widget        => 'Template',
  template_args => sub {
    my ($field, $args) = @_;
    ...
  },
);

sub template_renderer {
  my ( $self, $field ) = @_;

  return sub {
      my ($args) = @_;

      my $field = $args->{field};

      ...

  };
}
```

# DESCRIPTION

This is an [HTML::FormHandler](https://metacpan.org/pod/HTML::FormHandler) widget that allows you to use a
template for rendering forms instead of Perl methods.

# SEE ALSO

- [HTML::FormHandler](https://metacpan.org/pod/HTML::FormHandler)
- [Template](https://metacpan.org/pod/Template)

# SOURCE

The development version is on github at [https://github.com/robrwo/HTML-FormHandlerX-Widget-Field-Template](https://github.com/robrwo/HTML-FormHandlerX-Widget-Field-Template)
and may be cloned from [git://github.com/robrwo/HTML-FormHandlerX-Widget-Field-Template.git](git://github.com/robrwo/HTML-FormHandlerX-Widget-Field-Template.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/HTML-FormHandlerX-Widget-Field-Template/issues](https://github.com/robrwo/HTML-FormHandlerX-Widget-Field-Template/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The initial development of this module was sponsored by Science Photo
Library [https://www.sciencephoto.com](https://www.sciencephoto.com).

# CONTRIBUTOR

Mohammad S Anwar <mohammad.anwar@yahoo.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2017-2018 by Robert Rothenberg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
