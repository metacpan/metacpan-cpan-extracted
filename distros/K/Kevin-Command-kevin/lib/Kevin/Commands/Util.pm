
package Kevin::Commands::Util;
$Kevin::Commands::Util::VERSION = '0.6.0';
use Mojo::Base -strict;

# Borrowed from https://github.com/docker/go-units/blob/master/duration.go

sub _human_duration {
  my $seconds = shift;

  return 'less than a second' if $seconds < 1;
  return '1 second' if $seconds == 1;
  return sprintf '%d seconds', $seconds if $seconds < 60;

  my $minutes = int($seconds / 60);
  return 'about a minute' if $minutes == 1;
  return sprintf '%d minutes', $minutes if $minutes < 46;

  my $hours = int($seconds / (60 * 60) + 0.5);
  return 'about an hour' if $hours == 1;
  return sprintf '%d hours', $hours      if $hours < 48;
  return sprintf '%d days',  $hours / 24 if $hours < 24 * 7 * 2;
  return sprintf '%d weeks',  $hours / (24 * 7) if $hours < 24 * 30 * 2;
  return sprintf '%d months', $hours / (24 * 30) if $hours < 24 * 365 * 2;

  return sprintf '%d years', $hours / (24 * 365);
}

sub _created_since {
  ucfirst _human_duration(shift) . ' ago';
}

sub _running_since {
  'Up ' . _human_duration(shift);
}

sub _job_status {
  my ($info, $now) = (shift, shift);

  my $state = $info->{state};
  if ($state eq 'active') {
    return 'Waiting ' . _human_duration($now - $info->{delayed})
      if $info->{delayed};

    return 'Running';
  }

  if ($state eq 'failed' || $state eq 'finished') {
    return
      ucfirst $state . ' ' . _human_duration($now - $info->{finished}) . ' ago';
  }

  return 'Inactive';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kevin::Commands::Util

=head1 VERSION

version 0.6.0

=head1 AUTHOR

Adriano Ferreira <ferreira@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Adriano Ferreira.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
