package HTML::Zoom::ZConfig;

use strictures 1;

my %DEFAULTS = (
  parser => 'HTML::Zoom::Parser::BuiltIn',
  producer => 'HTML::Zoom::Producer::BuiltIn',
  filter_builder => 'HTML::Zoom::FilterBuilder',
  selector_parser => 'HTML::Zoom::SelectorParser',
  stream_utils => 'HTML::Zoom::StreamUtils',
);

my $ALL_DEFAULT;

sub new {
  my ($class, $args) = @_;
  return $ALL_DEFAULT if $ALL_DEFAULT && !keys %{$args||{}};
  my $new = {};
  foreach my $arg_name (keys %DEFAULTS) {
    $new->{$arg_name} = $args->{$arg_name} || $DEFAULTS{$arg_name};
    if (ref($new->{$arg_name})) {
      $new->{$arg_name} = $new->{$arg_name}->with_zconfig($new);
    } else {
      require(do { (my $m = $new->{$arg_name}) =~ s/::/\//g; "${m}.pm" });
      $new->{$arg_name} = $new->{$arg_name}->new({ zconfig => $new });
    }
  }
  $ALL_DEFAULT = $new if !keys %{$args||{}};
  bless($new, $class);
}

sub parser { shift->{parser} }
sub producer { shift->{producer} }
sub filter_builder { shift->{filter_builder} }
sub selector_parser { shift->{selector_parser} }
sub stream_utils { shift->{stream_utils} }

1;
