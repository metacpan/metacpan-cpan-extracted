use strict;
use warnings;
package String::Formatter::Cookbook;
{
  $String::Formatter::Cookbook::VERSION = '0.102084';
}
# ABSTRACT: ways to put String::Formatter to use
1;

__END__

=pod

=head1 NAME

String::Formatter::Cookbook - ways to put String::Formatter to use

=head1 VERSION

version 0.102084

=head1 OVERVIEW

String::Formatter is a pretty simple system for building formatting routines,
but it can be hard to get started without an idea of the sort of things that
are possible.

=encoding utf-8

=head1 BASIC RECIPES

=head2 constants only

The simplest stringf interface you can provide is one that just formats
constant strings, allowing the user to put them inside other fixed strings with
alignment:

  use String::Formatter stringf => {
    input_processor => 'forbid_input',
    codes => {
      a => 'apples',
      b => 'bananas',
      w => 'watermelon',
    },
  };

  print stringf('I eat %a and %b but never %w.');

  # Output:
  # I eat apples and bananas but never watermelon.

If the user tries to parameterize the string by passing arguments after the
format string, an exception will be raised.

=head2 sprintf-like conversions

Another common pattern is to create a routine that behaves like Perl's
C<sprintf>, but with a different set of conversion routines.  (It will also
almost certainly have much simpler semantics than Perl's wildly complex
behavior.)

  use String::Formatter stringf => {
    codes => {
      s => sub { $_ },     # string itself
      l => sub { length }, # length of input string
      e => sub { /[^\x00-\x7F]/ ? '8bit' : '7bit' }, # ascii-safeness
    },
  };

  print stringf(
    "My name is %s.  I am about %l feet tall.  I use an %e alphabet.\n",
    'Ricardo',
    'ffffff',
    'abcchdefghijklllmnñopqrrrstuvwxyz',
  );

  # Output:
  # My name is Ricardo.  I am about 6 feet tall.  I use an 8bit alphabet.

B<Warning>: The behavior of positional string replacement when the conversion
codes mix constant strings and code references is currently poorly nailed-down.
Do not rely on it yet.

=head2 named conversions

This recipe acts a bit like Python's format operator when given a dictionary.
Rather than matching format code position with input ordering, inputs can be
chosen by name.

  use String::Formatter stringf => {
    input_processor => 'require_named_input',
    string_replacer => 'named_replace',

    codes => {
      s => sub { $_ },     # string itself
      l => sub { length }, # length of input string
      e => sub { /[^\x00-\x7F]/ ? '8bit' : '7bit' }, # ascii-safeness
    },
  };

  print stringf(
    "My %{which}s name is %{name}s.  My name is %{name}l letters long.",
    {
      which => 'first',
      name  => 'Marvin',
    },
  );

  # Output:
  # My first name is Marvin.  My name is 6 letters long.

Because this is a useful recipe, there is a shorthand for it:

  use String::Formatter named_stringf => {
    codes => {
      s => sub { $_ },     # string itself
      l => sub { length }, # length of input string
      e => sub { /[^\x00-\x7F]/ ? '8bit' : '7bit' }, # ascii-safeness
    },
  };

=head2 method calls

Some objects provide methods to stringify them flexibly.  For example, many
objects that represent timestamps allow you to call C<strftime> or something
similar.  The C<method_replace> string replacer comes in handy here:

  use String::Formatter stringf => {
    input_processor => 'require_single_input',
    string_replacer => 'method_replace',

    codes => {
      f => 'strftime',
      c => 'format_cldr',
      s => sub { "$_[0]" },
    },
  };

  print stringf(
    "%{%Y-%m-%d}f is also %{yyyy-MM-dd}c.  Default string is %s.",
    DateTime->now,
  );

  # Output:
  # 2009-11-17 is also 2009-11-17.  Default string is 2009-11-17T15:35:11.

This recipe is available as the export C<method_stringf>:

  use String::Formatter method_stringf => {
    codes => {
      f => 'strftime',
      c => 'format_cldr',
      s => sub { "$_[0]" },
    },
  };

You can easily use this to implement an actual stringf-like method:

  package MyClass;

  use String::Formatter method_stringf => {
    -as => '_stringf',
    codes => {
      f => 'strftime',
      c => 'format_cldr',
      s => sub { "$_[0]" },
    },
  };

  sub format {
    my ($self, $format) = @_;
    return _stringf($format, $self);
  }

=head1 AUTHORS

=over 4

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

Darren Chamberlain <darren@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Ricardo Signes <rjbs@cpan.org>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
