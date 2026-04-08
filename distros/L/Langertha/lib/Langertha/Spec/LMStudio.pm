package Langertha::Spec::LMStudio;
# ABSTRACT: Pre-computed OpenAPI operations for LM Studio native API
our $VERSION = '0.400';

# AUTO-GENERATED style table (maintained in-repo).
# Source: share/lmstudio.yaml (2 operations)

my $DATA;

sub data {
  $DATA //= {
    server_url => 'http://localhost:1234',
    operations => {
      'chat' => { method => 'POST', path => '/api/v1/chat', content_type => 'application/json' },
      'listModels' => { method => 'GET', path => '/api/v1/models' },
    },
  };
  return $DATA;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Spec::LMStudio - Pre-computed OpenAPI operations for LM Studio native API

=head1 VERSION

version 0.400

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
