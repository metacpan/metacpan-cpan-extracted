package IO::K8s::Role::MiddlewareBuilder;
# ABSTRACT: Role for building Traefik middleware configuration
our $VERSION = '1.100';
use Moo::Role;

sub rate_limit {
    my ($self, %opts) = @_;
    my $spec = $self->spec // {};
    $spec->{rateLimit} = {
        $opts{average} ? (average => $opts{average}) : (),
        $opts{burst}   ? (burst   => $opts{burst})   : (),
        $opts{period}  ? (period  => $opts{period})  : (),
    };
    $self->spec($spec);
    return $self;
}

sub basic_auth {
    my ($self, %opts) = @_;
    my $spec = $self->spec // {};
    $spec->{basicAuth} = {
        $opts{secret} ? (secret => $opts{secret}) : (),
        $opts{realm}  ? (realm  => $opts{realm})  : (),
    };
    $self->spec($spec);
    return $self;
}

sub strip_prefix {
    my ($self, @prefixes) = @_;
    my $spec = $self->spec // {};
    $spec->{stripPrefix} = {
        prefixes => \@prefixes,
    };
    $self->spec($spec);
    return $self;
}

sub redirect_https {
    my ($self) = @_;
    my $spec = $self->spec // {};
    $spec->{redirectScheme} = {
        scheme    => 'https',
        permanent => 1,
    };
    $self->spec($spec);
    return $self;
}

sub add_request_header {
    my ($self, $key, $value) = @_;
    my $spec = $self->spec // {};
    my $headers = $spec->{headers} //= {};
    my $custom = $headers->{customRequestHeaders} //= {};
    $custom->{$key} = $value;
    $self->spec($spec);
    return $self;
}

sub add_response_header {
    my ($self, $key, $value) = @_;
    my $spec = $self->spec // {};
    my $headers = $spec->{headers} //= {};
    my $custom = $headers->{customResponseHeaders} //= {};
    $custom->{$key} = $value;
    $self->spec($spec);
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Role::MiddlewareBuilder - Role for building Traefik middleware configuration

=head1 VERSION

version 1.100

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
