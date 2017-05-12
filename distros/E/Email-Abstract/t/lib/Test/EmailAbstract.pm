use strict;

package Test::EmailAbstract;
use Test::More;

sub new {
  my ($class, $message) = @_;
  my $simple = Email::Simple->new($message);
  bless { simple => $simple } => $class;
}

sub simple { $_[0]->{simple} }

sub _call {
  my ($wrapped, $object, $method, @args) = @_;

  if ($wrapped) {
    return $object->$method(@args);
  } else {
    return Email::Abstract->$method($object, @args);
  }
}

sub tests_per_class  { 7 }
sub tests_per_object { 8 }
sub tests_per_module {
  + 1
  + 2 * $_[0]->tests_per_class
  + 1 * $_[0]->tests_per_object
}

sub _do_tests {
  my ($self, $is_wrapped, $class, $obj, $readonly) = @_;

  if ($is_wrapped) {
    isa_ok($obj, 'Email::Abstract', "wrapped $class object");
  }

  is(
    _call($is_wrapped, $obj, 'get_header', 'Subject'),
    'Re: Defect in XBD lround',
    "Subject OK with $class"
  );

  eval { _call($is_wrapped, $obj, set_header => "Subject", "New Subject"); };

  if ($readonly) {
    like($@, qr/can't alter string/, "can't alter an unwrapped string");
  } else {
    is($@, '', "no exception on altering object via Email::Abstract");
  }

  my @receiveds = (
    q{from mailman.opengroup.org ([192.153.166.9]) by deep-dark-truthful-mirror.pad with smtp (Exim 3.36 #1 (Debian)) id 18Buh5-0006Zr-00 for <posix@simon-cozens.org>; Wed, 13 Nov 2002 10:24:23 +0000},
    q{(qmail 1679 invoked by uid 503); 13 Nov 2002 10:10:49 -0000},
  );

  my @got = _call($is_wrapped, $obj, get_header => 'Received');
  s/\t/ /g for @got;

  is_deeply(
    \@got,
    \@receiveds,
    "$class: received headers match up list context get_header",
  );

  my $got_body    = _call($is_wrapped, $obj, 'get_body');
  my $simple_body = $self->simple->body;

  # I very much do not like doing this.  Why is it needed?
  $got_body    =~ s/\x0d?\x0a?\z//;
  $simple_body =~ s/\x0d?\x0a?\z//;

  is(
    $got_body,
    $simple_body,
    "correct stringification of $class; same as reference object",
  );

  is(
    length $got_body,
    length $simple_body,
    "correct body length for $class",
  );

  eval { _call($is_wrapped, $obj, set_body => "A completely new body"); };

  if ($readonly) {
    like($@, qr/can't alter string/, "can't alter an unwrapped string");
  } else {
    is($@, '', "no exception on altering object via Email::Abstract");
  }

  if ($readonly) {
    pass("(no test; can't check altering unalterable alteration)");
  } else {
    like(
      _call($is_wrapped, $obj, 'as_string'),
      qr/Subject: New Subject.*completely new body$/ms,
      "set subject and body, restringified ok with $class"
    );
  }
}

sub class_ok  { shift->_do_tests(0, @_); }
sub object_ok { shift->_do_tests(1, @_); }

sub load {
  my ($self, $class, $arg) = @_;
  if (eval "require $class; Email::Abstract->__class_for('$class')") {
    diag "testing $class with " . $class->VERSION;
  } else {
    my $skip = $arg && $arg->{SKIP} ? $arg->{SKIP} : $self->tests_per_module;
    skip "$class: unavailable", $skip;
  }
}

1;
