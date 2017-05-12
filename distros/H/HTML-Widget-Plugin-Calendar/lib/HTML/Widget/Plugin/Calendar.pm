use strict;
use warnings;
package HTML::Widget::Plugin::Calendar;
# ABSTRACT: simple construction of jscalendar inputs
$HTML::Widget::Plugin::Calendar::VERSION = '0.022';
use parent qw(HTML::Widget::Plugin Class::Data::Inheritable);

use HTML::Element;
use HTML::TreeBuilder;
use Data::JavaScript::Anon;

#pod =head1 SYNOPSIS
#pod
#pod   $factory->calendar({
#pod     name   => 'date_of_birth',
#pod     format => '%Y-%m-%d',
#pod     value  => $user->date_of_birth,
#pod   });
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module plugs in to HTML::Widget::Factory and provides a calendar widget
#pod using the excellent jscalendar.
#pod
#pod =head1 METHODS
#pod
#pod =head2 C< provided_widgets >
#pod
#pod This plugin provides the following widgets: calendar, calendar_js
#pod
#pod =cut

sub provided_widgets { qw(calendar calendar_js) }

#pod =head2 calendar
#pod
#pod =cut

sub calendar {
  my ($self, $factory, $arg) = @_;
  $arg->{attr}{name} ||= $arg->{attr}{id};

  Carp::croak "you must supply a widget id for calendar"
    unless $arg->{attr}{id};

  $arg->{jscalendar} ||= {};
  $arg->{jscalendar}{showsTime} = 1 if $arg->{time};

  $arg->{format}
    ||= '%Y-%m-%d' . ($arg->{jscalendar}{showsTime} ? ' %H:%M' : '');

  my $widget = HTML::Element->new('input');
  $widget->attr($_ => $arg->{attr}{$_}) for keys %{ $arg->{attr} };
  $widget->attr(value => $arg->{value}) if exists $arg->{value};

  my $button;

  unless ($arg->{no_button}) {
    $button = HTML::Element->new(
      'button',
      id => $arg->{attr}{id} . "_button"
    );
    $button->push_content($arg->{button_label} || '...');
  }

  my $script = HTML::Element->new('script', type => 'text/javascript');
  my $js
    = sprintf "Calendar.setup(%s);",
      Data::JavaScript::Anon->anon_dump({
        inputField => $widget->attr('id'),
        ifFormat   => $arg->{format},
        ($arg->{no_button} ? () : (button => $button->attr('id'))),
        %{ $arg->{jscalendar} },
      })
    ;

  # we need to make this an HTML::Element literal to avoid escaping the JS
  $js = HTML::Element->new('~literal', text => $js);

  $script->push_content($js);

  return join q{},
    $self->calendar_js($factory, $arg),
    map { $_->as_XML } ($widget, ($arg->{no_button} ? () : $button), $script),
  ;
}

#pod =head2 C< calendar_js >
#pod
#pod This method returns the JavaScript needed to use the calendar.  It will only
#pod return the JavaScript the first time it's called.
#pod
#pod Normally it's called when the calendar widget is used, but it may be called
#pod manually to force the JavaScript to be placed in your document at the location
#pod of your choosing.
#pod
#pod =cut

sub calendar_js {
  my ($self, $factory, $arg) = @_;

  return '' if $factory->{$self}->{output_js}++;

  my $base = $self->calendar_baseurl;
  Carp::croak "calendar_baseurl is not defined" if not defined $base;

  $base =~ s{/\z}{}; # to avoid baseurl//yourface or baseurlyourface

  my $scripts = <<END_HTML;
  <script type="text/javascript" src="$base/calendar.js"></script>
  <script type="text/javascript" src="$base/lang/calendar-en.js"></script>
  <script type="text/javascript" src="$base/calendar-setup.js"></script>
END_HTML

}

#pod =head2 C< calendar_baseurl >
#pod
#pod This method sets or returns the plugin's base URL for the jscalendar files.
#pod This must be set or calendar plugin creation will throw an exception.
#pod
#pod =cut

__PACKAGE__->mk_classdata( qw(calendar_baseurl) );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Widget::Plugin::Calendar - simple construction of jscalendar inputs

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  $factory->calendar({
    name   => 'date_of_birth',
    format => '%Y-%m-%d',
    value  => $user->date_of_birth,
  });

=head1 DESCRIPTION

This module plugs in to HTML::Widget::Factory and provides a calendar widget
using the excellent jscalendar.

=head1 METHODS

=head2 C< provided_widgets >

This plugin provides the following widgets: calendar, calendar_js

=head2 calendar

=head2 C< calendar_js >

This method returns the JavaScript needed to use the calendar.  It will only
return the JavaScript the first time it's called.

Normally it's called when the calendar widget is used, but it may be called
manually to force the JavaScript to be placed in your document at the location
of your choosing.

=head2 C< calendar_baseurl >

This method sets or returns the plugin's base URL for the jscalendar files.
This must be set or calendar plugin creation will throw an exception.

=head1 AUTHOR

Ricardo SIGNES

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
