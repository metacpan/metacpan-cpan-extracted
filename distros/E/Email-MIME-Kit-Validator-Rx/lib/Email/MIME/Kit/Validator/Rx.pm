package Email::MIME::Kit::Validator::Rx;
{
  $Email::MIME::Kit::Validator::Rx::VERSION = '0.200001';
}
use Moose;
with 'Email::MIME::Kit::Role::Validator';
# ABSTRACT: validate assembly stash with Rx (from JSON in kit)

use Data::Rx 0.007;
use Data::Rx::TypeBundle::Perl 0.005;
use JSON;
use Moose::Util::TypeConstraints;
use Try::Tiny;


has prefix => (
  is  => 'ro',
  isa => 'HashRef',
  default => sub { {} },
);

has type_plugins => (
  is  => 'ro',
  isa => 'ArrayRef[Str]',
  default    => sub { [] },
);

has rx => (
  is  => 'ro',
  isa => class_type('Data::Rx'),
  lazy     => 1,
  init_arg => undef,
  builder  => 'build_default_rx_object',
);

sub build_default_rx_object {
  my ($self) = @_;
  my $rx = Data::Rx->new({
    prefix       => $self->prefix,
  });

  for my $plugin ($self->all_default_type_plugins, @{ $self->type_plugins }) {
    eval "require $plugin; 1" or die;
    $rx->register_type_plugin($plugin);
  }

  my $prefix = $self->prefix;
  for my $key (keys %$prefix) {
    $rx->add_prefix($key, $prefix->{ $key });
  }

  return $rx;
}

sub all_default_type_plugins {
  # shamlessly stolen from Moose::Object::BUILDALL -- rjbs, 2009-03-06
  my ($self) = @_;
  my @plugins;
  for my $method (
    reverse
    $self->meta->find_all_methods_by_name('accumulate_default_type_plugins')
  ) {
    push @plugins, $method->{code}->execute($self);
  }

  return @plugins;
}

sub accumulate_default_type_plugins {
  return ('Data::Rx::TypeBundle::Perl');
}

has schema => (
  reader   => 'schema',
  writer   => '_set_schema',
  isa      => 'Object', # It'd be nice to have a better TC -- rjbs, 2009-03-06
  init_arg => undef,
);

has schema_struct => (
  reader    => '_schema_struct',
  init_arg  => 'schema',
);

has schema_path => (
  reader    => '_schema_path',
  writer    => '_set_schema_path',
  isa       => 'Str',
  init_arg  => 'path',
);

has combine => (
  is          => 'ro',
  initializer => sub {
    my ($self, $value, $set) = @_;
    confess "invalid combine logic: $value"
      unless defined $value and $value eq 'all';
    $set->($value);
  },
);

sub BUILD {
  my ($self) = @_;

  $self->_do_goofy_schema_initialization;
}

sub _do_goofy_schema_initialization {
  my ($self) = @_;

  my @paths = grep { defined } ref $self->_schema_path
            ? @{ $self->_schema_path }
            : $self->_schema_path;

  my @structs = grep { defined } (ref $self->_schema_struct eq 'ARRAY')
              ? @{ $self->_schema_struct }
              : $self->_schema_struct;

  confess("multiple schemata provided but no combine logic given")
    if @paths + @structs > 1 and ! $self->combine;

  @paths = ('rx.json') unless @paths or @structs;

  for my $path (@paths) {
    # Sure, someday we can add another decoder layer here to allow schemata in
    # YAML.  Whatever. -- rjbs, 2009-03-06
    my $rx_json_ref = $self->kit->get_kit_entry($path);
    my $rx_data = JSON->new->decode($$rx_json_ref);
    push @structs, $rx_data;
  }

  my $schema = @structs > 1
             ? $self->rx->make_schema({ type => '//all', of => \@structs })
             : $self->rx->make_schema($structs[0]);

  $self->_set_schema($schema);
}

sub validate {
  my ($self, $stash) = @_;

  try {
    $self->schema->assert_valid($stash);
  } catch {
    Carp::confess("assembly parameters don't pass validation: $_");
  };

  return 1;
}

no Moose;
no Moose::Util::TypeConstraints;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Email::MIME::Kit::Validator::Rx - validate assembly stash with Rx (from JSON in kit)

=head1 VERSION

version 0.200001

=head1 SYNOPSIS

Email::MIME::Kit::Validator::Rx is a Validator plugin for Email::MIME::Kit that
allows an Rx schema to be used to validate kit assembly data.

A simple mkit's manifest might include the following:

  {
    "renderer" : "TT",
    "validator": "Rx",
    "header"   : [ ... mail headers ... ],
    "type"     : "text/plain",
    "path"     : "path/to/template.txt"
  }

In this simple configuration, the use of "Rx" as the validator will load the
plugin in its simplest configuration.  It will look for a file called
F<rx.json> in the kit and will load its contents (as JSON) and use them as a
schema to validate the data passed to the it's C<assemble> method.

More complex configurations are simple.

This configuration supplies an alternate filename for the JSON file:

  "validator": [ "Rx", { "path": "rx-schema.json" } ],

This configuration supplies the schema definition inline:

  "validator": [
    "Rx",
    {
      "schema": {
        "type"   : "//rec",
        "required": {
          "subject": "//str",
          "rcpt"   : { "type": "/perl/obj", "isa": "Email::Address" }
        }
      }
    }
  ]

Notice, above, the C</perl/> prefix.  By default,
L<Data::Rx::TypeBundle::Perl|Data::Rx::TypeBundle::Perl> is loaded along with
the core types.

If a C<combine> argument is given, multiple schema definitions may be provided.
They will be combined with the logic named by the combine argument.  In this
release, only "all" is valid, and will require all schemata to match.  Here is
an example:

  "validator": [
    "Rx",
    {
      "combine": "all",
      "path"   : "rx.json",
      "schema" : [
        { "type": "//rec", "rest": "//any", "required": { "foo": "//int" } },
        { "type": "//rec", "rest": "//any", "required": { "bar": "//int" } },
      ]
    }
  ]

This definition will create an C<//all> schema with three entries: the schema
found in F<rx.json> and the two schemata given in the array value of C<schema>.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
