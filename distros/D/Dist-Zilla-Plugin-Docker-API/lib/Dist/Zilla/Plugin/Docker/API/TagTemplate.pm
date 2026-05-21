package Dist::Zilla::Plugin::Docker::API::TagTemplate;
# ABSTRACT: Template expansion for Docker image tags
our $VERSION = '0.103';
use Moo;

has zilla => (
    is       => 'ro',
    required => 1,
);

has plugin_name => (
    is       => 'ro',
    required => 1,
);

my %var_map = (
    n => 'name',
    v => 'version',
    V => 'version_major',
    t => 'trial',
    g => 'git_short_sha',
    G => 'git_full_sha',
    b => 'branch',
    d => 'build_root',
    o => 'source_root',
    a => 'archive',
    p => 'plugin_name',
    vmaj => 'version_major',
    vmin => 'version_minor',
);

my %known_var = map { $_ => 1 } keys %var_map;

sub expand {
    my ($self, $template, %vars) = @_;

    $template //= '';

    $template =~ s/%(\d+)/'%'.sprintf('%02d',$1)/eg;

    my $result = $template;
    $result =~ s/%([a-zA-Z][a-zA-Z0-9_]*)/_expand_var($1, %vars)/ge;

    return $result;
}

sub _extract_vars {
    my ($self, $template) = @_;
    my @vars;
    while ($template =~ /%([a-zA-Z][a-zA-Z0-9_]*)/g) {
        push @vars, $1 if $known_var{$1};
    }
    return @vars;
}

sub _expand_var {
    my ($var, %vars) = @_;

    my $key = $var_map{$var} // $var;
    my $value = $vars{$key} // '';

    if ($var eq 'V' || $var eq 'vmaj' || $var eq 'vmin') {
        my $version = $vars{version} // '';
        if ($version =~ /^(\d+)/) {
            $value = $1;
            if ($var eq 'vmin' && $version =~ /^\d+\.(\d+)/) {
                $value = $1;
            }
        }
    }

    return $value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Docker::API::TagTemplate - Template expansion for Docker image tags

=head1 VERSION

version 0.103

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-dist-zilla-plugin-docker-api/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
