# DESCRIPTION

Enables airplane mode for your dzil plugin bundle. This means all network
plugins are removed from loading and aborts a release via the plugin
[Dist::Zilla::Plugin::BlockRelease](https://metacpan.org/pod/Dist::Zilla::Plugin::BlockRelease).

    # In your dist.ini
    [@Author::EXAMPLE]
    airplane = 1 ; or DZIL_AIRPLANE=1 in your shell

# SYNOPSIS

    package Dist::Zilla::PluginBundle::Author::EXAMPLE;
    use Moose;

    with 'Dist::Zilla::Role::PluginBundle::Airplane';

    sub build_airplane_mode {
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
