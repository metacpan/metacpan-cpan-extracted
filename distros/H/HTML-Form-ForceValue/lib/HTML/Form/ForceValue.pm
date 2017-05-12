use strict;
use warnings;
package HTML::Form::ForceValue;
# ABSTRACT: who cares what values are legal, anyway?
$HTML::Form::ForceValue::VERSION = '0.009';
# =head1 SYNOPSIS
#
#   use Test::WWW::Mechanize tests => 5;
#   use HTML::Form::ForceValue;
#
#   my $mech = WWW::Mechanize->new;
#
#   # We're going to test our form.
#   $mech->get_ok("http://cgi.example.com/form");
#
#   $mech->set_fields(
#     name => 'Crazy Ivan',
#     city => 'Vladivostok',
#   );
#
#   # What if insane bot tries to claim it's from USSR?
#   $mech->form_name("user_info")->find_input("country")->force_value("su");
#
#   $mech->submit;
#
# =head1 DEPRECATION NOTICE
#
# As of C<libwww-perl> 5.817, HTML::Form has a strict mode, which restricts form
# values to the options given.  Without strict mode, values may be set to
# anything you like, making this module unnecessary.  It remains on the CPAN for
# use by those who choose not to upgrade their LWP, but in general this code is
# now obsolete.
#
# =head1 DESCRIPTION
#
# L<HTML::Form|HTML::Form> is a very useful module that provides objects to
# represent HTML forms.  They can be filled in, and the filled-in values can be
# converted into an HTTP::Request for submission to a server.
#
# L<WWW::Mechanize|WWW::Mechanize> makes this even easier by providing a very
# easy to automate user agent that provides HTML::Form objects to represent
# forms.  L<Test::WWW::Mechanize|Test::WWW::Mechanize> hangs some testing
# features on Mech, making it easy to automatically test how web applications
# behave.
#
# One really important thing to test is how a web application responds to invalid
# input.  Unfortunately, HTML::Form protects you from doing this by throwing an
# exception when an invalid datum is assigned to an enumerated field.
# HTML::Form::ForceValue mixes in to HTML::Form classes to provide C<force_value>
# methods which behave like C<value>, but will automatically add any invalid
# datum to the list of valid data.
#
# =cut

sub import {
  my $class = shift;
  HTML::Form::ForceValue::Form->import(@_);
  HTML::Form::ForceValue::Form::Input->import(@_);
}

package HTML::Form::ForceValue::Form;
$HTML::Form::ForceValue::Form::VERSION = '0.009';
use Sub::Exporter 0.960 -setup => {
  into    => 'HTML::Form',
  exports => [ qw(force_value) ],
  groups  => [ default => [ '-all' ] ],
};

sub force_value {
  my ($self, $name, $value) = @_;

  my $input = $self->find_input($name);

  unless ($input) {
    $input = HTML::Form::ListInput->new(
      type     => 'option',
      name     => $name,
      menu     => [ { value => $value, name => $value } ],
      current  => 0,
      multiple => 1,
    );

    $input->add_to_form($self);
  }

  $input->force_value($value);
}

package HTML::Form::ForceValue::Form::Input;
$HTML::Form::ForceValue::Form::Input::VERSION = '0.009';
use Sub::Exporter -setup => {
  into     => 'HTML::Form::Input',
  exports  => [ qw(force_value) ],
  groups   => [ default => [ '-all' ] ],
};

sub force_value {
  my ($self, $value) = @_;
  my $old = $self->value;
  eval { $self->value($value); };
  if ($@ and $@ =~ /Illegal value/) {
    push @{$self->{menu}}, { name => $value, value => $value };
    return $self->value($value);
  }
  return $old;
}

# =head1 WARNING
#
# This implementation is extremely crude.  This feature should really be in
# HTML::Form (in my humble opinion), and this module should cease to exist once
# it is.  In the meantime, just keep in mind that I spent a lot more time
# packaging this than I did writing it.  I<Caveat importor!>
#
# =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Form::ForceValue - who cares what values are legal, anyway?

=head1 VERSION

version 0.009

=head1 SYNOPSIS

  use Test::WWW::Mechanize tests => 5;
  use HTML::Form::ForceValue;

  my $mech = WWW::Mechanize->new;

  # We're going to test our form.
  $mech->get_ok("http://cgi.example.com/form");

  $mech->set_fields(
    name => 'Crazy Ivan',
    city => 'Vladivostok',
  );

  # What if insane bot tries to claim it's from USSR?
  $mech->form_name("user_info")->find_input("country")->force_value("su");

  $mech->submit;

=head1 DESCRIPTION

L<HTML::Form|HTML::Form> is a very useful module that provides objects to
represent HTML forms.  They can be filled in, and the filled-in values can be
converted into an HTTP::Request for submission to a server.

L<WWW::Mechanize|WWW::Mechanize> makes this even easier by providing a very
easy to automate user agent that provides HTML::Form objects to represent
forms.  L<Test::WWW::Mechanize|Test::WWW::Mechanize> hangs some testing
features on Mech, making it easy to automatically test how web applications
behave.

One really important thing to test is how a web application responds to invalid
input.  Unfortunately, HTML::Form protects you from doing this by throwing an
exception when an invalid datum is assigned to an enumerated field.
HTML::Form::ForceValue mixes in to HTML::Form classes to provide C<force_value>
methods which behave like C<value>, but will automatically add any invalid
datum to the list of valid data.

=head1 DEPRECATION NOTICE

As of C<libwww-perl> 5.817, HTML::Form has a strict mode, which restricts form
values to the options given.  Without strict mode, values may be set to
anything you like, making this module unnecessary.  It remains on the CPAN for
use by those who choose not to upgrade their LWP, but in general this code is
now obsolete.

=head1 WARNING

This implementation is extremely crude.  This feature should really be in
HTML::Form (in my humble opinion), and this module should cease to exist once
it is.  In the meantime, just keep in mind that I spent a lot more time
packaging this than I did writing it.  I<Caveat importor!>

=head1 AUTHOR

Ricardo SIGNES

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
