#!perl

use strict;
use warnings;
use Devel::Leak::Object qw(GLOBAL_bless);
use JavaScript qw(:all);

{
  package ThisObjectWillLeak;

  sub new {
    my($class, $num) = @_;
    return bless { n => $num }, $class;
  }

  sub whoami {
    my $self = shift;
    return "Leaky object #$self->{n}";
  }
}

{
  package ThisObjectWillNotLeak;

  sub new {
    my($class, $num) = @_;
    return bless { n => $num }, $class;
  }

  sub whoami {
    my $self = shift;
    return "Sealed object #$self->{n}";
  }
}

our $rt;
our $cx;

sub dont_leak_an_object {
  my $sealed = ThisObjectWillNotLeak->new(shift);
  $cx->bind_object(sealed => $sealed);
  return;
}

sub leak_an_object {
  my $leaky = ThisObjectWillLeak->new(shift);
  return $leaky;
}

sub write {
  my $msg = shift;
  print "$msg\n";
}

foreach my $cxloop (1 .. 5) {
  print "Context #$cxloop\n";
  $rt = JavaScript::Runtime->new;
  $cx = JavaScript::Context->new($rt);

  foreach my $i ('ThisObjectWillLeak', 'ThisObjectWillNotLeak') {
    $cx->bind_class(
      name => $i,
      constructor => sub {},
      methods => { whoami => $i->can('whoami') },
      flags => JS_CLASS_NO_INSTANCE,
      package => $i
    );
  }

  $cx->bind_function(leak_an_object => \&leak_an_object);
  $cx->bind_function(dont_leak_an_object => \&dont_leak_an_object);
  $cx->bind_function(write => \&write);

  foreach my $i (1 .. 10) {
    $cx->eval("leaky = leak_an_object($i)");
    $cx->eval("dont_leak_an_object($i)");
    $cx->eval("write(leaky.whoami())");
    $cx->eval("write(sealed.whoami())");
  }
}
