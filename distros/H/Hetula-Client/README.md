# Hetula Perl Client

Client library for https://github.com/kivilahtio/Hetula

## Installation

`cpanm Hetula::Client`

## Usage

Installation adds a program hetula-client in your system $PATH

`hetula-client --help`

## Dev installation

Hetula::Client uses Dist::Zilla for packaging.

### Clone

cd /home/hetula
git clone https://github.com/kivilahtio/libhetula-client-perl.git

### Build, test, install

Install deps
```
cpanm Dist::Zilla
cpanm $(dzil authordeps)
cpanm $(dzil installdeps)
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

