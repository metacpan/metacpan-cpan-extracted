# SYNOPSIS

In your `dist.ini`:

    [@Author::WATERKIP]

# DESCRIPTION

This is a [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) plugin bundle. It is somewhat equal to the
following `dist.ini`:

    TODO: Show what is done

# METHODS

## configure

Configure the author plugin

## commit\_files\_after\_release

Commit files after a release

## release\_option

Define the release options. Choose between:

`cpan` or `stratopan`. When fake release is used, this overrides these two options

# SEE ALSO

I took inspiration from [Dist::Zilla::PluginBundle::Author::ETHER](https://metacpan.org/pod/Dist::Zilla::PluginBundle::Author::ETHER)
