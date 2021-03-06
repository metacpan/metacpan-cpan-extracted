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

has credits => (
  is => 'ro',
  isa => 'Str',
  def => ".credits"
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
  push @$content, $self->construct_inherits;
  push @$content, $self->construct_integrates;
  push @$content, $self->construct_typelibrary;
  push @$content, $self->construct_attributes_list;
  push @$content, $self->construct_headers;
  push @$content, $self->construct_exports_list;
  push @$content, $self->construct_functions_list;
  push @$content, $self->construct_methods_list;
  push @$content, $self->construct_routines_list;
  push @$content, $self->construct_footers;
  push @$content, $self->construct_credits;

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

method construct_headers() {
  my $pdoc = $self->document;
  my $headers = $pdoc->headers;

  return () if !$headers;

  return join("\n", "", @$headers);
}

method construct_footers() {
  my $pdoc = $self->document;
  my $footers = $pdoc->footers;

  return () if !$footers;

  return join("\n", "", @$footers);
}

method construct_credits() {
  my $credits = $self->credits;

  open my $ch, "<", $credits or return ();

  my $records = [map { chomp; [split /, /] } (<$ch>)];

  close $ch;

  return () if !@$records;

  my @content;

  push @content, $self->markup_head1('credits', [
    join "\n\n", map qq($$_[1], C<+$$_[0]>), @$records
  ]);

  return join("\n", @content);
}

method construct_inherits() {
  my $inherits = $self->document->inherits;

  return () if !$inherits || !@$inherits;

  my @content;

  push @content, $self->markup_head1('inheritance', [
    "This package inherits behaviors from:",
    "", join "\n\n", map "L<$_>", @$inherits
  ]);

  return join("\n", @content);
}

method construct_integrates() {
  my $integrates = $self->document->integrates;

  return () if !$integrates || !@$integrates;

  my @content;

  push @content, $self->markup_head1('integrations', [
    "This package integrates behaviors from:",
    "", join "\n\n", map "L<$_>", @$integrates
  ]);

  return join("\n", @content);
}

method construct_typelibrary() {
  my $libraries = $self->document->libraries;

  return () if !$libraries || !@$libraries;

  my @content;

  push @content, $self->markup_head1('libraries', [
    "This package uses type constraints defined by:",
    "", join "\n\n", map "L<$_>", @$libraries
  ]);

  return join("\n", @content);
}

method construct_attributes_list() {
  my $attributes = $self->document->attributes;

  return () if !$attributes || !@$attributes;

  my @content;

  push @content, $self->markup_head1('attributes', [
    "This package has the following attributes."
  ]);

  push @content, $self->construct_attributes_item($_) for @$attributes;

  return join("\n", @content);
}

method construct_attributes_item($item) {
  my $name = qr/(\w+)/;
  my $part = qr/([^,]+)/;

  my @vars = $item =~ /$name\($part, $part, $part\)/;

  my $id = $vars[0];
  my $constraint = $vars[1] || 'Any';
  my $presence = $vars[3] || 'req';
  my $ability = $vars[4] || 'ro';

  $ability = $ability eq 'ro' ? 'read-only' : 'read-write';
  $presence = $presence eq 'req' ? 'required' : 'optional';

  my $identity = "The attribute is $ability";
  my $accepts = "accepts C<($constraint)> values";
  my $required = "and is $presence";
  my $description = "$identity, $accepts, $required.";
  my $signature = "$id($constraint)";

  return $self->markup_head2($id, ["  $signature", "", $description]);
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

method construct_exports_item($item) {
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

method construct_functions_item($item) {
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

method construct_methods_item($item) {
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

method construct_routines_item($item) {
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

  open my $th, "<", $template or confess "Can't open $template: $!";

  my $output = join "", <$th>;

  close $th;

  $content = join "\n", @$content;
  $content =~ s/^\n+|\n+$//g;

  # wrap content with template
  $output =~ s/\{content\}/$content/;
  $output =~ s/^\n+|\n+$//g;

  # transform nested pod blocks
  $output =~ s/^\+=\s*(.+?)\s*(\r?\n)/=$1$2\n/mg;

  # add leading newline to assist coalescing
  return "\n$output";
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
