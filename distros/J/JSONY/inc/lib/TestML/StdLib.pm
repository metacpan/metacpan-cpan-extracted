use strict; use warnings;
package TestML::StdLib;
use TestML::Boolean();

sub new {
  my ($class, $run) = @_;
  bless {run => $run}, $class;
}

sub argv {
  [@ARGV];
}

sub block {
  my ($self, $selector) = @_;
  return $self->{run}{block}
    if not defined $selector;
  for my $block (@{$self->{run}{ast}{data}}) {
    if ($block->{label} eq $selector) {
      return $block;
    }
  }
  return undef;
}

sub blocks {
  my ($self) = @_;
  [@{$self->{run}{ast}{data}}];
}

sub bool {
  my ($self, $value) = @_;
  (defined($value) and not TestML::Boolean::isFalse($value))
  ? TestML::Boolean::true
  : TestML::Boolean::false;
}

sub cat {
  my ($self, @strings) = @_;
  my $strings = ref($strings[0]) eq 'ARRAY'
  ? $strings[0]
  : [@strings];
  CORE::join '', @$strings;
}

sub count {
  my ($self, $list) = @_;
  scalar @$list;
}

sub env {
  \%ENV;
}

sub error {
  my ($self, $msg) = (@_, '');
  TestMLError->new($msg);
}

sub false {
  TestML::Boolean::false();
}

sub fromjson {
  my ($self, $value) = @_;
  $self->_json->decode($value);
}

sub join {
  my ($self, $list, $separator) = @_;
  $separator = ' ' unless defined $separator;
  CORE::join $separator, @$list;
}

sub lines {
  my ($self, $text) = @_;
  chomp $text;
  [split "\n", $text];
}

sub msg {
  my ($self, $error) = (@_);
  $error->msg;
}

sub none {
  return ();
}

sub null {
  undef;
}

sub split {
  my ($self, $string, $delim, $limit) = @_;
  $delim ||= ' ';
  $limit ||= -1;
  [split $delim, $string, $limit];
}

sub sum {
  my ($self, @list) = @_;
  my $list = ref($list[0]) eq 'ARRAY' ? $list[0] : [@list];
  require List::Util;
  List::Util::sum(@$list);
}

sub text {
  my ($self, $list) = @_;
  CORE::join "\n", @$list, '';
}

sub tojson {
  my ($self, $value) = @_;
  $self->_json->encode($value);
}

sub throw {
  my ($self, $msg) = @_;
  $self->{run}{thrown} = TestMLError->new($msg);
  return 0;
}

sub type {
  my ($self, @value) = @_;
  return 'none' unless @value;
  $self->{run}->type($self->{run}->cook($value[0]));
}

sub true {
  TestML::Boolean::true();
}

#------------------------------------------------------------------------------
my $json;
sub _json {
  require JSON::PP;
  $json ||= JSON::PP->new
    ->pretty
    ->indent_length(2)
    ->canonical(1)
    ->allow_nonref;
}

#------------------------------------------------------------------------------
package TestMLError;

sub new {
  my ($class, $msg) = @_;

  return bless {
    msg => $msg
  }, $class;
}

sub msg { $_[0]->{msg} }

1;
