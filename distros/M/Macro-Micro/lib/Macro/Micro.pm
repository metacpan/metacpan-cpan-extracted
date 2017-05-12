use strict;
use warnings;
package Macro::Micro;
{
  $Macro::Micro::VERSION = '0.054';
}
# ABSTRACT: really simple templating for really simple templates

use Carp ();


my $DEFAULT_MACRO_FORMAT = qr/(?<!\\)([\[<] (\w+) [>\]])/x;

sub new {
  my ($class, %arg) = @_;

  my $self = bless { } => $class;

  $arg{macro_format} = $DEFAULT_MACRO_FORMAT unless $arg{macro_format};

  $self->macro_format($arg{macro_format});

  return $self;
}


sub macro_format {
  my $self = shift;

  return $self->{macro_format} unless @_;

  my $macro_format = shift;
  Carp::croak "macro format must be a regexp reference"
    unless ref $macro_format eq 'Regexp';

  $self->{macro_format} = $macro_format;
}


sub register_macros {
  my ($self, @macros) = @_;

  for (my $i = 0; $i < @macros; $i += 2) {
    my ($name, $value) = @macros[ $i, $i+1 ];
    Carp::croak "macro value must be a string or code reference"
      if (ref $value) and (ref $value ne 'CODE');

    if (not ref $name) {
      $self->{macro}{$name} = $value;
    } elsif (ref $name eq 'Regexp') {
      $self->{macro_regexp}{$name} = [ $name, $value ];
    } else {
      Carp::croak "macro name '$name' must be a string or a regexp";
    }
  }

  return $self;
}


sub clear_macros {
  my ($self, @macros) = @_;

  if (@macros) {
    Carp::croak "partial deletion not implemented";
  } else {
    delete @$self{qw(macro macro_regexp)};
  }

  return;
}


sub get_macro {
  my ($self, $macro_name) = @_;

  return $self->{macro}{$macro_name} if exists $self->{macro}{$macro_name};

  foreach my $regexp (values %{ $self->{macro_regexp} }) {
    return $regexp->[1] if $macro_name =~ $regexp->[0];
  }

  return;
}


sub expand_macros {
  my ($self, $object, $stash) = @_;

  if (eval { $object->isa('Macro::Micro::Template') }) {
    return $self->_expand_template($object, $stash);
  }

  $self->fast_expander($stash)->($object);
}

sub _expand_template {
  my ($self, $object, $stash) = @_;
  # expects to be passed ($whole_macro, $macro_inside_delim, $whole_text)
  my $expander = sub {
    my $macro = $self->get_macro($_[1]);
    return $_[0] unless defined $macro;
    return ref $macro ? $macro->($_[1], $_[2], $stash)||'' : $macro;
  };

  return ${ $object->_text } unless $object->_parts;

  return join '', map { ref $_ ? $expander->(@$_[0, 1], $object->_text) : $_ }
                  $object->_parts;
}


sub expand_macros_in {
  my ($self, $object, $stash) = @_;

  Carp::croak "object of in-place expansion must be a scalar reference"
    if (not ref $object)
    or (ref $object ne 'SCALAR');

  my $fast_expander = $self->fast_expander($stash);

  $$object = $fast_expander->($$object);
}


sub string_expander {
  my ($self, $stash) = @_;

  my $expander = $self->macro_expander($stash);
  my $regex    = $self->macro_format;

  my $applicator = sub {
    my ($object) = @_;

    return unless defined $object;
    Carp::croak "object of expansion must not be a reference" if ref $object;

    $object =~ s/$regex/$expander->($1,$2)/eg;

    return $object;
  }
}

BEGIN { *fast_expander = \&string_expander }


sub macro_expander {
  my ($self, $stash) = @_;

  my %cached;

  if (values %{ $self->{macro_regexp} }) {
    return sub {
      return $cached{ $_[0] } if defined $cached{ $_[0] };

      my $macro = $self->get_macro($_[1]);

      $cached{ $_[0] } = defined $macro
                       ? ref $macro
                         ? $macro->($_[1], $_[2], $stash)||'' : $macro
                       : $_[0];

      return $cached{ $_[0] };
    };
  } else {
    return sub {
      return $cached{ $_[0] } if defined $cached{ $_[0] };

      my $macro = $self->{macro}{ $_[1] };

      $cached{ $_[0] } = defined $macro
                       ? ref $macro
                         ? $macro->($_[1], $_[2], $stash)||'' : $macro
                       : $_[0];

      return $cached{ $_[0] };
    };
  }
}



sub study {
  my ($self, $text) = @_;

  my $macro_format = $self->macro_format;

  my @total;

  my $pos;
  while ($text =~ m/\G(.*?)$macro_format/gsm) {
    my ($snippet, $whole, $name) = ($1, $2, $3);
    push @total, (length $snippet ? $snippet : ()),
                 ($whole ? [ $whole, $name ] : ());
    $pos = pos $text;
  }

  push @total, substr $text, $pos if defined $pos;

  return Macro::Micro::Template->_new(\$text, \@total);
}

{
  package Macro::Micro::Template;
{
  $Macro::Micro::Template::VERSION = '0.054';
}
  sub _new   { bless [ $_[1], $_[2] ] => $_[0] }
  sub _parts { @{ $_[0][1] } }
  sub _text  {    $_[0][0]   }
}

"[MAGIC_TRUE_VALUE]";

__END__

=pod

=head1 NAME

Macro::Micro - really simple templating for really simple templates

=head1 VERSION

version 0.054

=head1 SYNOPSIS

  use Macro::Micro;

  my $expander = Macro::Micro->new;

  $expander->register_macros(
    ALIGNMENT => "Lawful Good",
    HEIGHT    => sub {
      my ($macro, $object, $stash) = @_;
      $stash->{race}->avg_height;
    },
  );

  $expander->expand_macros_in($character, { race => $human_obj });

  # character is now a Lawful Good, 5' 6" human

=head1 DESCRIPTION

This module performs very basic expansion of macros in text, with a very basic
concept of context and lazy evaluation.

=head1 METHODS

=head2 new

  my $mm = Macro::Micro->new(%arg);

This method creates a new Macro::Micro object.

There is only one valid argument:

  macro_format - this is the format for macros; see the macro_format method

=head2 macro_format

  $mm->macro_format( qr/.../ );

This method gets or sets the macro format regexp for the expander.

The format must be a reference to a regular expression, and should have two
capture groups.  The first should return the entire string to be replaced in
the text, and the second the name of the macro found.

The default macro format is:  C<< qr/([\[<] (\w+) [>\]])/x >>

In other words: a probably-valid-identiifer inside angled or square backets.

=head2 register_macros

  $mm->register_macros($name => $value, ... );

This method register one or more macros for later expansion.  The macro names
must be either strings or a references to regular expression.  The values may
be either strings or references to code.

These macros may later be used for expansion by C<L</expand_macros>>.

=head2 clear_macros

  $mm->clear_macros;

This method clears all registered macros.

=head2 get_macro

  my $macro = $mm->get_macro($macro_name);

This returns the currently-registered value for the named macro.  If the given
macro name is not registered exactly, the name is checked against any regular
expression macros that are registered.  The first of these to match is
returned.

At present, the regular expression macros are checked in an arbitrary order.

=head2 expand_macros

  my $rewritten = $mm->expand_macros($text, \%stash);

This method returns the result of rewriting the macros found the text.  The
stash is a set of data that may be used to expand the macros.

The text is scanned for content matching the expander's L</macro_format>.  If
found, the macro name in the found content is looked up with C<L</get_macro>>.
If a macro is found, it is used to replace the found content in the text.

A macros whose value is text is expanded into that text.  A macros whose value
is code is expanded by calling the code as follows:

  $replacement = $macro_value->($macro_name, $text, \%stash);

Macros are not expanded recursively.

=head2 expand_macros_in

  $mm->expand_macros_in($object, \%stash);

This rewrites the content of C<$object> in place, using the expander's macros
and the provided stash of data.

At present, only scalar references can be rewritten in place.  In the future,
there will be a system to define how various classes of objects should be
rewritten in place, such as email messages.

=head2 string_expander

  my $string_expander = $mm->string_expander($stash);

  my $rewritten_text = $string_expander->($original_text);

This method returns a closure which will expand the macros in text passed to
it using the expander's macros and the passed-in stash.

C<fast_expander> is provided as an alias for legacy code.

=head2 macro_expander

  my $macro_expander = $mm->macro_expander(\%stash);

This method returns a coderef that can be called as follows:

  $macro_expander->($macro_string, $macro_name);

It should return the string to be used to replace the macro string that was
found.

=head2 study

  my $template = $expander->study($text);

Given a string, this returns an object which can be used as an argument to
C<expand_macros>.  Macro::Micro will find and mark the locations of macros in
the text so that calls to expand the macros will not need to search the text.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
