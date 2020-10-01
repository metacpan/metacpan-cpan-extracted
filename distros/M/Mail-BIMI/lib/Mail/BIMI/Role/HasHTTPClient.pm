package Mail::BIMI::Role::HasHTTPClient;
# ABSTRACT: Class to model a HTTP client
our $VERSION = '2.20200930.1'; # VERSION
use 5.20.0;
use Moose::Role;
use Mail::BIMI::Prelude;
use HTTP::Tiny::Paranoid;

has http_client => ( is => 'rw', lazy => 1, builder => '_build_http_client',
  documentation => 'HTTP::Tiny::Paranoid (or similar) object used for HTTP operations' );
requires 'http_client_max_fetch_size';


{
  my $http_client;
  sub _build_http_client($self) {
    return $http_client if $http_client;
    my $agent = 'Mail::BIMI ' . ( $Mail::BIMI::Version // 'dev' );
    $http_client = HTTP::Tiny::Paranoid->new(
      agent => $agent,
      max_size => $self->http_client_max_fetch_size,
      timeout => $self->bimi_object->options->http_client_timeout,
      verify_SSL => 1,     # Certificates MUST verify
    );
    return $http_client;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::BIMI::Role::HasHTTPClient - Class to model a HTTP client

=head1 VERSION

version 2.20200930.1

=head1 DESCRIPTION

Role for classes which require a HTTP Client implementation

=head1 REQUIRES

=over 4

=item * L<HTTP::Tiny::Paranoid|HTTP::Tiny::Paranoid>

=item * L<Mail::BIMI::Prelude|Mail::BIMI::Prelude>

=item * L<Moose::Role|Moose::Role>

=back

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
