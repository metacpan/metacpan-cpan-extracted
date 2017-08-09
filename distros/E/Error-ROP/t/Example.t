use Test::Spec;
use Error::ROP qw(rop);

package MooseSut {
  use Error::ROP qw(rop);
  use Moose;

  has service => (is => 'ro');

  sub foo {
    my $self = shift;
    my $res = rop { $self->service->baz(40); };
    return $res
      ->then("service failed at bar" => sub { $self->_bar($_) })
      ->then('failed at frobnicate' => sub { $self->_frobnicate($_) });
  }

  sub _bar {
    my ($self, $arg) = @_;
    return $arg + 2;
  }

  sub _frobnicate {
    my ($self, $arg) = @_;
    return $arg + 39;
  }

};

package Stub {
  use Moose;

  has val => (is => 'ro');

  sub baz {
    my ($self, $arg) = @_;
    my $divisor = $self->val;
    return $arg / $divisor;
  }
};


describe "Stub" => sub {

  it "works as expected" => sub {
    my $stub = Stub->new(val => 40);
    is($stub->baz(40), 1);
  };

  it "fails as expected" => sub {
    my $stub = Stub->new(val => 0);
    my $res = eval {
      $stub->baz(40);
    };
    ok($@);
  };

};

describe "MooseSut" => sub {

  it "behaves ok when service doesn't fail" => sub {
    my $stub = Stub->new(val => 40);
    my $sut = MooseSut->new(service => $stub);
    my $res = $sut->foo;
    ok($res->is_valid && $res->value == 42);
  };

  it "behaves ok when service fails" => sub {
    my $stub = Stub->new(val => 0);
    my $sut = MooseSut->new(service => $stub);
    my $res = $sut->foo;
    ok(!$res->is_valid);
  };

};

sub compute_meaning {
    my $divisor = shift;
    return rop { 80 / $divisor }
           ->then(sub { $_ + 2 });
};

describe "When life" => sub {
    describe "has meaning," => sub {
        it "the meaning is 42" => sub {
            my $meaning = compute_meaning(2);
            ok($meaning->is_valid && $meaning->value == 42);
        };
    };
    describe "don't has meaning" => sub {
        it "the meaning is not valid" => sub {
            my $meaning = compute_meaning(0);
           ok(!$meaning->is_valid);
        };
    };
    describe "don't has meaning" => sub {
        it "the meaning is not valid and you know why" => sub {
            my $meaning = compute_meaning(0);
            ok(!$meaning->is_valid && index($meaning->failure, "Illegal division by zero at") != -1);
        };
    };
};

runtests unless caller;
1;
