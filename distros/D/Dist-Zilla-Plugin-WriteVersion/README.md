# Dist::Zilla::Plugin::WriteVersion

Write the version to all Perl files and scripts

## Installation

`cpanm Dist::Zilla::Plugin::WriteVersion`

## Usage

Add this to you dist.ini

`[WriteVersion]`

## Dev installation

This uses Dist::Zilla for packaging.

### Clone

git clone https://github.com/kivilahtio/Dist-Zilla-Plugin-WriteVersion.git

### Build, test, install

Install deps

Remember to pass -Ilib to dzil commands, because dzil needs this module to build itself!
```
cpanm Dist::Zilla
dzil -Ilib authordeps --missing | cpanm
dzil -Ilib installdeps --missing | cpanm
```

Dev your feature.

Then

```
dzil smoke
```

### Releasing new versions

```
dzil release
```

