# SYNOPSIS

    # dist.ini
    [CheckChangeLog]

    # or
    [CheckChangeLog]
    filename = Changes.pod

# DESCRIPTION

    This plugin will examine your changes file after a build to make sure it has an entry for your distributions current version prior to a release.

# File name conventions

    With no arguments CheckChangeLog will only look in files named Changes and ChangeLog (case insensitive) within the root directory of your dist. Note you can always pass a filename argument if you have an unconvential name and place for your changelog.

# METHODS

## after\_build

## has\_version($content\_str, $version\_str)

# AUTHORS

Fayland Lam, `<fayland at gmail.com>`
