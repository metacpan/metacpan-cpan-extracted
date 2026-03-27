package IO::K8s::Role::Loadbalanced;
# ABSTRACT: Role for traffic distribution (weighted backends, mirroring)
our $VERSION = '1.100';
use Moo::Role;

sub set_weighted {
    my ($self, $name, $weight) = @_;
    my $spec = $self->spec // {};
    my $weighted = $spec->{weighted} //= { services => [] };
    my $services = $weighted->{services};

    # Update existing or add new
    my $found = 0;
    for my $svc (@$services) {
        if ($svc->{name} eq $name) {
            $svc->{weight} = $weight;
            $found = 1;
            last;
        }
    }
    push @$services, { name => $name, weight => $weight } unless $found;
    $self->spec($spec);
    return $self;
}

sub mirror_to {
    my ($self, $name, %opts) = @_;
    my $spec = $self->spec // {};
    my $mirroring = $spec->{mirroring} //= {};
    my $mirrors = $mirroring->{mirrors} //= [];
    push @$mirrors, {
        name => $name,
        $opts{percent} ? (percent => $opts{percent}) : (),
    };
    $self->spec($spec);
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Role::Loadbalanced - Role for traffic distribution (weighted backends, mirroring)

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
