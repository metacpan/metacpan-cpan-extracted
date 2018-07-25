package Ion::Test;
# ABSTRACT: Utilities used by Ion unit tests
$Ion::Test::VERSION = '0.08';
use common::sense;

BEGIN{
  require Test2::V0;

  if ($^O =~ /mswin32/i) {
    my $ok;
    local $SIG{CHLD} = sub{ $ok = 1 };
    kill 'CHLD', 0;

    Test2::V0::skip_all('broken perl detected: $SIG{CHLD}')
      unless $ok;
  }

  Test2::V0::skip_all('broken perl detected: $SIG{USR1}')
    unless exists $SIG{USR1};

  require AnyEvent::Impl::Perl;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Ion::Test - Utilities used by Ion unit tests

=head1 VERSION

version 0.08

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
