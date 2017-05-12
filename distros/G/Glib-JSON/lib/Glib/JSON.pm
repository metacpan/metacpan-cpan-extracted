package Glib::JSON;
$Glib::JSON::VERSION = '0.002';
use strict;
use warnings;
use Carp qw/croak/;
use Exporter;
use Glib;
use Glib::IO;
use Glib::Object::Introspection 0.016;

our @ISA = qw(Exporter);

my $_JSON_GLIB_BASENAME = 'Json';
my $_JSON_GLIB_VERSION = '1.0';
my $_JSON_GLIB_PACKAGE = 'Glib::JSON';

sub import {
  my $class = shift;

  Glib::Object::Introspection->setup (
    basename => $_JSON_GLIB_BASENAME,
    version => $_JSON_GLIB_VERSION,
    package => $_JSON_GLIB_PACKAGE,
  );
}

1;

__END__

=head1 NAME

Glib::JSON - Perl interface to the JSON-GLib library

=head1 SYNOPSIS

  use Glib::JSON;

  # build a JSON structure
  my $builder = Glib::JSON::Builder->new();

  # {
  #   "url" : "http://www.gnome.org/img/flash/two-thirty.png"
  #   "size" : [ 652, 242 ]
  # }
  $builder->begin_object();

  $builder->set_member_name("url");
  $builder->add_string_value("http://www.gnome.org/img/flash/two-thirty.png");

  $builder->set_member_name("size");
  $builder->begin_array();
  $builder->add_int_value(652);
  $builder->add_int_value(242);
  $builder->end_array();

  $builder->end_object();

  # generate the JSON string
  my $generator = Glib::JSON::Generator->new();
  $generator->set_root($builder->get_root());
  my $data = $generator->to_data();

  # load the string into a JSON document
  my $parser = Glib::JSON::Parser->new();
  $parser->load_from_data($data);

  # parse the document
  my $reader = Glib::JSON::Reader->new();
  $reader->set_root($parser->get_root());

  $reader->read_member("url");
  my $url = $reader->get_string_value();
  $render->end_member();

  $render->read_member("size");
  $reader->read_element(0);
  my $width = $reader->get_int_value();
  $reader->end_element();
  $reader->read_element(1);
  my $height = $reader->get_int_value();
  $reader->end_element();
  $reader->end_member();

=head1 DESCRIPTION

Glib::JSON is a Perl module that provides access to the JSON-GLib library
through introspection.

Glib::JSON allows parsing and generating JSON documents through a simple,
DOM-like API; it also provides cursor-based API to parse and generate JSON
documents.

Glib::JSON is integrated with the GLib and GObject data types, and can
easily serialize and deserialize JSON data from and to GObject instances.

=head1 SEE ALSO

=over

=item L<Glib>

=item L<Glib::Object::Introspection>

=back

=head1 AUTHORS

=encoding utf8

=over

=item Emmanuele Bassi <ebassi@gnome.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014  Emmanuele Bassi

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

=cut
