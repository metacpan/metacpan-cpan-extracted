package Micro::Container;

use strict;
use warnings;
use 5.008_001;
our $VERSION = '0.03';

use parent qw(Class::Data::Inheritable);

use Carp qw(croak);

__PACKAGE__->mk_classdata(objects => {});

my %INSTANCES;
sub instance {
    my $class = shift;
    $INSTANCES{$class} ||= do {
        my $self = bless {}, $class;
        $self->{_parent_classes} = $self->_parent_classes($class);
        $self;
    };
}

sub register {
    my $self = shift;
    my $klass = ref $self;
    unless ($klass) {
        ($klass, $self) = ($self, $self->instance);
    }

    my $objects = $self->objects->{$klass} ||= {};
    while (@_) {
        my ($name, $args) = splice @_, 0, 2;
        if (ref $args eq 'CODE') {
            $objects->{$name} = $args->($self, $name);
        }
        else {
            local $Carp::CarpLevel = $Carp::CarpLevel + 1;
            $objects->{$name} = $self->load_class($name)->new(@$args);
        }
    }
}
*add = *register;

sub unregister {
    my ($self, @names) = @_;
    my $klass = ref $self;
    unless ($klass) {
        ($klass, $self) = ($self, $self->instance);
    }

    my $objects = $self->objects->{$klass} ||= {};
    for my $name (@names) {
        delete $objects->{$name};
    }
}
*remove = *unregister;

sub get {
    my ($self, $name) = @_;
    my $klass = ref $self;
    unless ($klass) {
        ($klass, $self) = ($self, $self->instance);
    }

    my $objects = $self->objects;
    my $obj = $objects->{$klass}{$name};

    # find from parent classes
    unless ($obj) {
        my $classes = $self->{_parent_classes};
        for my $class (@$classes) {
            $obj = $objects->{$class}{$name} and last;
        }
    }

    $obj or croak "$name is not registered in @{[ ref $self ]}";
}

sub load_class {
    my ($self, $class, $prefix) = @_;

    # taken from Plack::Util::load_class
    if ($prefix) {
        unless ($class =~ s/^\+// || $class =~ /^$prefix/) {
            $class = "$prefix\::$class";
        }
    }

    my $file = $class;
    $file =~ s!::!/!g;
    eval {
        require "$file.pm"; ## no critic
    };
    if (my $e = $@) {
        croak "$e";
    }

    return $class;
}

sub _parent_classes {
    my ($self, $klass, $classes) = @_;
    $classes ||= [];

    my @isa = do {
        no strict 'refs';
        @{"$klass\::ISA"};
    };
    push @$classes, @isa;

    for my $class (@isa) {
        next if $class eq __PACKAGE__;
        $self->_parent_classes($class, $classes);
    }

    return $classes;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Micro::Container - Lite weight and inheritable object container

=head1 SYNOPSIS

  package MyContainer;
  use parent 'Micro::Container';

  __PACKAGE__->register(
      JSON => [],
  );

  package MyContainer::Child;
  use parent 'MyContainer';

  __PACKAGE__->register(
      MessagePack => sub {
          my $c = shift;
          my $mp = $c->load_class('Data::MessagePack')->new;
          $mp->utf8;
          $mp;
      },
  );

  package main;
  use MyContainer::Child;

  my $container = MyContainer::Child->instance;
  say $container->get('JSON')->encode_json({ foo => 'bar' });
  my $data = $container->get('MessagePack')->decode($message_pack_string);

=head1 DESCRIPTION

Micro::Container is inheritable object container.

=head1 METHODS

=head2 instance()

Returns instance.

  package MyContainer;
  use parent 'Micro::Container';

  package main;
  use MyContainer;

  my $container = MyContainer->instance;

=head2 register(%args)

=head2 add(%args)

Register objects to container.

  package MyContainer;
  use parent 'Micro::Container';

  __PACKAGE__->register(
      'LWP::UserAgent' => [ agent => 'FooBar' ],
      JSON             => sub {
          my $c = shift;
          $c->load_class('JSON')->new->utf8;
      },
  );

=head2 unregister(@names)

=head2 remove(@names)

Remove registered objects by name.

  MyContainer->unregister('JSON', 'LWP::UserAgent');

=head2 get($name)

Get registered method.

  my $json = MyContainer->get('JSON');

=head2 load_class($class, $prefix)

Constructs a class name and C<< require >> the class.

Taken from L<< Plack::Util >>.

  $class = MyContainer->load_class('Foo');                   # Foo
  $class = MyContainer->load_class('Baz', 'Foo::Bar');       # Foo::Bar::Baz
  $class = MyContainer->load_class('+XYZ::ZZZ', 'Foo::Bar'); # XYZ::ZZZ

=head1 AUTHOR

xaicron E<lt>xaicron@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2013 - xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<< Object::Container >>.

L<< Plack::Util >>.

=cut
