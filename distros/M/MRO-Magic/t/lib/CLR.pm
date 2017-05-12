use strict;
use warnings;
package CLR_X; # class-less root
# Our test example will be a very, very simple classless/prototype calling
# system. -- rjbs, 2008-05-16

sub new {
  my ($class, %attrs) = @_;
  my $root = {
    new => sub {
      my ($parent, %attrs) = @_;
      bless { %attrs, parent => $parent } => $class;
    },
    get => sub {
      my ($self, $attr) = @_;
      my $curr = $self;
      while ($curr) {
        return $curr->{$attr} if exists $curr->{$attr};
        $curr = $curr->{parent};
      }
      return undef;
    },
    set => sub {
      my ($self, $attr, $value) = @_;
      return $self->{$attr} = $value;
    },
    %attrs,
    parent => undef,
  };

  bless $root => $class;
}

my %STATIC = (new => \&new);

use MRO::Magic
  passthru   => [ qw(import export DESTROY AUTOLOAD) ],
  metamethod => sub {
  my ($invocant, $method, $args) = @_;

  unless (ref $invocant) {
    die "no metaclass method $method on $invocant"
      unless my $code = $STATIC{$method};

    return $code->($invocant, @$args);
  }

  my $curr = $invocant;
  while ($curr) {
    return $curr->{$method}->($invocant, @$args) if exists $curr->{$method};
    $curr = $curr->{parent};
  }

  my $class = ref $invocant;
  die "unknown method $method called on $class object";
};

{ package CLR; use mro 'CLR_X'; }

1;
