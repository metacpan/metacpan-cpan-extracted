package Log::Info::SubAppender;

# Log::Log4perl::Appender subclass that just calls arbitrary code

use base qw( Log::Log4perl::Appender );

use Carp  qw( carp confess );

sub new {
  my ($class, %params) = @_;
  bless \%params, $_[0];
}

sub name { $_[0]->{name} }

sub log {
  my ($self, %params) = @_;
  my $msg = $params{message};
  eval {
    $self->{subr}->($self->{full_p} ? \%params : $msg, $self);
  }; if ( $@ ) {
    carp(sprintf "Invocation of appender subr %s failed (msg: %s)\n  $@\n",
                 $self->name, $msg);
  }
}

sub DESTROY {}

1; # keep require happy
