package Test::Dist::Output;

use Do 'Class';

use Carp;

has document => (
  is => 'ro',
  isa => 'InstanceOf["Test::Dist::Document"]',
  req => 1
);

has content => (
  is => 'ro',
  isa => 'ArrayRef'
);

has template => (
  is => 'ro',
  isa => 'Str',
  def => "bin/pod.txt"
);

method BUILD($args) {
  $self->construct;

  return $self;
}

method construct() {
  my $content = $self->{content} = [];

  push @$content, $self->construct_name;
  push @$content, $self->construct_abstract;
  push @$content, $self->construct_synopsis;
  push @$content, $self->construct_description;

  push @$content, $self->construct_exports_list;
  push @$content, $self->construct_functions_list;
  push @$content, $self->construct_methods_list;
  push @$content, $self->construct_routines_list;

  return $self;
}

method construct_name() {
  my $pdoc = $self->document;
  my $name = $pdoc->name;

  return $self->markup_head1('name', $name);
}

method construct_abstract() {
  my $pdoc = $self->document;
  my $abstract = $pdoc->abstract;

  return $self->markup_head1('abstract', $abstract);
}

method construct_synopsis() {
  my $pdoc = $self->document;
  my $synopsis = $pdoc->synopsis;

  return $self->markup_head1('synopsis', $synopsis); ;
}

method construct_description() {
  my $pdoc = $self->document;
  my $description = $pdoc->description;

  return $self->markup_head1('description', $description); ;
}

method construct_exports_list() {
  my $exports = $self->document->exports;

  return () if !$exports || !@$exports;

  my @content;

  push @content, $self->markup_head1('exports', [
    "This package can export the following functions."
  ]);

  @$exports = sort { $a->{name}[0] cmp $b->{name}[0] } @$exports;

  push @content, $self->construct_exports_item($_) for @$exports;

  return join("\n", @content);
}

method construct_exports_item(HashRef $item) {
  my $name = $item->{name};
  my $desc = $item->{description};
  my $uses = $item->{usage};
  my $sign = $item->{signature};

  $sign->[0] =~ s/^\s*/  /;

  my @ex_item = $self->markup_item("$$name[0] example", join("\n", @$uses));
  my $ex_over = $self->markup_over(@ex_item);

  my $data = [$$sign[0], "", @$desc, $ex_over];

  $self->markup_head2($$name[0], $data);
}

method construct_functions_list() {
  my $functions = $self->document->functions;

  return () if !$functions || !@$functions;

  my @content;

  push @content, $self->markup_head1('functions', [
    "This package implements the following functions."
  ]);

  @$functions = sort { $a->{name}[0] cmp $b->{name}[0] } @$functions;

  push @content, $self->construct_functions_item($_) for @$functions;

  return join("\n", @content);
}

method construct_functions_item(HashRef $item) {
  my $name = $item->{name};
  my $desc = $item->{description};
  my $uses = $item->{usage};
  my $sign = $item->{signature};

  $sign->[0] =~ s/^\s*/  /;

  my @ex_item = $self->markup_item("$$name[0] example", join("\n", @$uses));
  my $ex_over = $self->markup_over(@ex_item);

  my $data = [$$sign[0], "", @$desc, $ex_over];

  $self->markup_head2($$name[0], $data);
}

method construct_methods_list() {
  my $methods = $self->document->methods;

  return () if !$methods || !@$methods;

  my @content;

  push @content, $self->markup_head1('methods', [
    "This package implements the following methods."
  ]);

  @$methods = sort { $a->{name}[0] cmp $b->{name}[0] } @$methods;

  push @content, $self->construct_methods_item($_) for @$methods;

  return join("\n", @content);
}

method construct_methods_item(HashRef $item) {
  my $name = $item->{name};
  my $desc = $item->{description};
  my $uses = $item->{usage};
  my $sign = $item->{signature};

  $sign->[0] =~ s/^\s*/  /;

  my @ex_item = $self->markup_item("$$name[0] example", join("\n", @$uses));
  my $ex_over = $self->markup_over(@ex_item);

  my $data = [$$sign[0], "", @$desc, $ex_over];

  $self->markup_head2($$name[0], $data);
}

method construct_routines_list() {
  my $routines = $self->document->routines;

  return () if !$routines || !@$routines;

  my @content;

  push @content, $self->markup_head1('routines', [
    "This package implements the following routines."
  ]);

  @$routines = sort { $a->{name}[0] cmp $b->{name}[0] } @$routines;

  push @content, $self->construct_routines_item($_) for @$routines;

  return join("\n", @content);
}

method construct_routines_item(HashRef $item) {
  my $name = $item->{name};
  my $desc = $item->{description};
  my $uses = $item->{usage};
  my $sign = $item->{signature};

  $sign->[0] =~ s/^\s*/  /;

  my @ex_item = $self->markup_item("$$name[0] example", join("\n", @$uses));
  my $ex_over = $self->markup_over(@ex_item);

  my $data = [$$sign[0], "", @$desc, $ex_over];

  $self->markup_head2($$name[0], $data);
}

method render() {
  my $content = $self->content;
  my $template = $self->template;

  open my $fh, "<", $template or confess "Can't open $template: $!";

  my $output = join "", <$fh>;

  close $fh;

  $content = join "\n", @$content;
  $content =~ s/^\n+|\n+$//g;

  # wrap content with template
  $output =~ s/\{content\}/$content/;
  $output =~ s/^\n+|\n+$//g;

  # transform nested pod blocks
  $output =~ s/^\+=\s*(.+?)\s*(\r?\n)/=$1$2\n/mg;

  return $output;
}

method persist() {
  my $file = $self->document->file->pod_file;

  open my $fh, ">", $file or confess "Can't open $file: $!";

  print $fh $self->render;
  close $fh;

  return $self;
}

method markup_item($name, $data) {
  return ("=item $name\n", "$data\n");
}

method markup_over(@items) {
  return join("\n", "", "=over 4", "", @items, "=back");
}

method markup_head1($name, $data) {
  return join("\n", "", "=head1 \U$name", "", @{$data}, "", "=cut");
}

method markup_head2($name, $data) {
  return join("\n", "", "=head2 \L$name", "", @{$data}, "", "=cut");
}

1;
