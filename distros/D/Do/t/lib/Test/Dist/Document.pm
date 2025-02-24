package Test::Dist::Document;

use Do 'Class';

use Test::Dist::Output;

has file => (
  is => 'ro',
  isa => 'InstanceOf["Test::Dist::File"]',
  req => 1
);

has name => (
  is => 'ro',
  isa => 'ArrayRef'
);

has abstract => (
  is => 'ro',
  isa => 'ArrayRef'
);

has synopsis => (
  is => 'ro',
  isa => 'ArrayRef'
);

has description => (
  is => 'ro',
  isa => 'ArrayRef'
);

has headers => (
  is => 'ro',
  isa => 'ArrayRef'
);

has footers => (
  is => 'ro',
  isa => 'ArrayRef'
);

has inherits => (
  is => 'ro',
  isa => 'ArrayRef'
);

has integrates => (
  is => 'ro',
  isa => 'ArrayRef'
);

has libraries => (
  is => 'ro',
  isa => 'ArrayRef'
);

has attributes => (
  is => 'ro',
  isa => 'ArrayRef'
);

has exports => (
  is => 'ro',
  isa => 'ArrayRef'
);

has functions => (
  is => 'ro',
  isa => 'ArrayRef'
);

has methods => (
  is => 'ro',
  isa => 'ArrayRef'
);

has routines => (
  is => 'ro',
  isa => 'ArrayRef'
);

method BUILD($args) {
  $self->construct;

  return $self;
}

method output() {
  return Test::Dist::Output->new(document => $self);
}

method construct() {
  my $list = $self->construct_sections;

  for my $item (@$list) {
    my $list;

    my $type = $item->{type};

    if ($type->[0] eq 'export') {
      $list = 'exports';
    }
    elsif ($type->[0] eq 'method') {
      $list = 'methods';
    }
    elsif ($type->[0] eq 'function') {
      $list = 'functions';
    }
    else {
      $list = 'routines';
    }

    push @{$self->{$list}}, $item;
  }

  my $head = $self->construct_headers;
  my $tail = $self->construct_footers;
  my $attr = $self->construct_attributes;

  if (exists $attr->{inherits}) {
    $attr->{inherits} = [grep !!$_, @{$attr->{inherits}}];
  }
  if (exists $attr->{integrates}) {
    $attr->{integrates} = [grep !!$_, @{$attr->{integrates}}];
  }

  $self->{$_} = $attr->{$_} for keys %$attr;
  $self->{$_} = $head->{$_} for keys %$head;
  $self->{$_} = $tail->{$_} for keys %$tail;

  return $self;
}

method construct_data($file, @list) {
  my $data = {};
  my $pdoc = $self->file->parse($file);

  $data->{$_} = $pdoc->content($_) for @list;

  return $data;
}

method construct_attributes() {
  my $data = $self->construct_data($self->file->use_file, qw(
    name
    abstract
    synopsis
    description
    inherits
    integrates
    libraries
    attributes
  ));

  return $data;
}

method construct_sections() {
  my $data = [map $self->construct_section("$_"), @{$self->file->can_files}];

  return $data;
}

method construct_section($file) {
  my $data = $self->construct_data($file, qw(
    name
    usage
    description
    signature
    type
  ));

  return $data;
}

method construct_headers() {
  my @list = qw(headers);
  my $data = $self->construct_data($self->file->use_file, @list);

  return $data;
}

method construct_footers() {
  my @list = qw(footers);
  my $data = $self->construct_data($self->file->use_file, @list);

  return $data;
}

1;
