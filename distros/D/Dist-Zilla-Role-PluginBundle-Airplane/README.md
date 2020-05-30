# DESCRIPTION

Enables airplane mode for your dzil plugin bundle. This means all network
plugins are removed from loading and aborts a release via the plugin
[Dist::Zilla::Plugin::BlockRelease](https://metacpan.org/pod/Dist%3A%3AZilla%3A%3APlugin%3A%3ABlockRelease).

    # In your dist.ini
    [@Author::EXAMPLE]
    airplane = 1 ; or DZIL_AIRPLANE=1 in your shell

# SYNOPSIS

    package Dist::Zilla::PluginBundle::Author::EXAMPLE;
    use Moose;

    with 'Dist::Zilla::Role::PluginBundle::Airplane';

    # You are required to implement this method
    sub build_network_plugins {
        return [qw(
            PromptIfStale
            Test::Pod::LinkCheck
            Test::Pod::No404s
            Git::Remote::Check
            CheckPrereqsIndexed
            CheckIssues
            UploadToCPAN
            UploadToStratopan
            Git::Push
        )];
    };

    sub configure {
        my $self = shift;

        my @plugins = ['PromptIfStale'];

        $self->add_plugins(@plugins);
    }
