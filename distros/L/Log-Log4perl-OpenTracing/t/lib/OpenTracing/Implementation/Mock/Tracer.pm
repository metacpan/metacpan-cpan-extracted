package OpenTracing::Implementation::Mock::Tracer;

sub new               { my ($class, %data) = @_; bless \%data, $class }
sub get_scope_manager { ... }
sub get_active_span   { ... }
sub start_active_span { ... }
sub start_span        { ... }
sub inject_context    { my $self = shift; return $self->{context} }
sub extract_context   { ... }

1;