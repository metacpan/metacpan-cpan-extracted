package Dist::Zilla::PluginBundle::FAYLAND;
$Dist::Zilla::PluginBundle::FAYLAND::VERSION = '0.16';
# ABSTRACT: Dist::Zilla like FAYLAND when you build your dists

use Moose;
use Moose::Autobox;
with 'Dist::Zilla::Role::PluginBundle';

use Dist::Zilla::PluginBundle::Filter;

sub bundle_config {
    my ($self, $section) = @_;
    my $class = (ref $self) || $self;

    my $arg = $section->{payload};

    my @plugins = Dist::Zilla::PluginBundle::Filter->bundle_config({
            name    => "$class/Classic",
            payload => {
                bundle => '@Classic',
                remove => [qw(PodVersion BumpVersion Readme)],
            }});

    my $prefix = 'Dist::Zilla::Plugin::';
    my @extra = map { ["$class/$prefix$_->[0]" => "$prefix$_->[0]" => $_->[1]] } (
        [PodWeaver           => {}],
        ['Test::Compile'     => {}],
        [PerlTidy            => {}],
        [Repository          => {}],
        [ReadmeFromPod       => {}],
        [CheckChangeLog      => {}],
        [MetaJSON            => {}],
        [MinimumPerlFast     => {}],
        ['Git::Contributors' => {}]);

    push @plugins, @extra;

    eval "require $_->[1]; 1;" or die for @plugins;    ## no critic Carp

    return @plugins;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::FAYLAND - Dist::Zilla like FAYLAND when you build your dists

=head1 VERSION

version 0.16

=head1 SYNOPSIS

    # dist.ini
    [@FAYLAND]

It is equivalent to:

    [@Filter]
    bundle = @Classic
    remove = PodVersion
    remove = BumpVersion
    remove = Readme

    [PodWeaver]
    [Test::Compile]
    [PerlTidy]
    [Repository]
    [ReadmeFromPod]
    [CheckChangeLog]
    [MetaJSON]
    [MinimumPerlFast]
    [Git::Contributors]

=head3 bundle_config

=head1 AUTHOR

Fayland Lam <fayland@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
