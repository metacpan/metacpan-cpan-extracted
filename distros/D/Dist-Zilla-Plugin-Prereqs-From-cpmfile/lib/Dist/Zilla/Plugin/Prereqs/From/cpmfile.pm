package Dist::Zilla::Plugin::Prereqs::From::cpmfile v0.0.3 {
    use 5.34.0;
    use Moose;

    use experimental 'signatures';
    use Module::cpmfile;

    with 'Dist::Zilla::Role::PrereqSource', 'Dist::Zilla::Role::MetaProvider';

    has cpmfile => (
        is => 'ro',
        lazy => 1,
        builder => '_build_cpmfile',
    );

    sub _build_cpmfile ($self, @) {
        $self->log("parsing cpm.yml to extract prereqs");
        Module::cpmfile->load("cpm.yml");
    }

    sub register_prereqs ($self, @) {
        $self->cpmfile->prereqs->walk(undef, undef, sub ($phase, $type, $package, $options, @) {
            $self->zilla->register_prereqs(
                {phase => $phase, type => $type},
                $package => $options->{version} || 0,
            );
        });
    }

    sub metadata ($self, @) {
        my $features = $self->cpmfile->features;
        return +{} if !$features;

        my $optional_features = {};
        for my $name (sort keys $features->%*) {
            $optional_features->{$name} = {
                description => $features->{$name}{description},
                prereqs => $features->{$name}{prereqs}->cpanmeta->as_string_hash,
            };
        }
        return { optional_features => $optional_features };
    }

    __PACKAGE__->meta->make_immutable;
}

1;
__END__

=encoding utf-8

=head1 NAME

Dist::Zilla::Plugin::Prereqs::From::cpmfile - Register prereqs from cpmfile

=head1 SYNOPSIS

  ; dist.ini
  [Prereqs::From::cpmfile]

=head1 DESCRIPTION

Dist::Zilla::Plugin::Prereqs::From::cpmfile registers prereqs from I<cpmfile>.

=head1 SEE ALSO

L<Dist::Zilla::Plugin::Prereqs::FromCPANfile>

L<Module::cpmfile>

=head1 AUTHOR

Shoichi Kaji <skaji@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2021 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
