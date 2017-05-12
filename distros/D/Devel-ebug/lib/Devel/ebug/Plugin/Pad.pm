package Devel::ebug::Plugin::Pad;
$Devel::ebug::Plugin::Pad::VERSION = '0.59';
use strict;
use warnings;
use base qw(Exporter);
our @EXPORT = qw(pad pad_human);

# find the pad
sub pad {
  my($self) = @_;
  my $response = $self->talk({ command => "pad" });
  return $response->{pad};
}

# human-readable pad
sub pad_human {
  my($self) = @_;
  my $pad = $self->pad;
  foreach my $var (keys %$pad) {
    if ($var =~ /^@/) {
      my @values = @{$pad->{$var}};
      my $value = $self->stack_trace_human_args(@values);
      $pad->{$var} = $value;
    } elsif ($var =~ /^%/) {
      $pad->{$var} = '(...)';
    } else {
      my $value = $pad->{$var};
      $value = $self->stack_trace_human_args($value);
      $value =~ s/^\(//;
      $value =~ s/\)$//;
      $pad->{$var} = $value;
    }
  }
  return $pad;
}

1;
