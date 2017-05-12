package HTML::Zoom::TransformedStream;

use strictures 1;
use base qw(HTML::Zoom::FilterStream);

sub new {
  my ($class, $args) = @_;
  $args->{selector} = $args->{transform}->selector;
  $args->{match} = $args->{transform}->match;
  $args->{filters} = $args->{transform}->filters;
  my $new = $class->SUPER::new($args);
  $new->{transform} = $args->{transform};
  $new
}

sub transform { shift->{transform} }

1;
