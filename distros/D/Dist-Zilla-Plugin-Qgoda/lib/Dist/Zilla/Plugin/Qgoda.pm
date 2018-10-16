#! /bin/false

# Copyright (C) 2018 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software. It comes without any warranty, to
# the extent permitted by applicable law. You can redistribute it
# and/or modify it under the terms of the Do What the Fuck You Want
# to Public License, Version 2, as published by Sam Hocevar. See
# http://www.wtfpl.net/ for more details.

# Heavily inspired by Dist::Zilla::Plugin::Web::NPM::Package;

package Dist::Zilla::Plugin::Qgoda;

use Moose;

with (
    'Dist::Zilla::Role::FileGatherer',
    'Dist::Zilla::Role::BuildRunner',
);

use Dist::Zilla::File::FromCode;
use Qgoda;

use JSON 2;
use Path::Class;

use File::ShareDir;
use Cwd;

has 'language' => (
    is => 'rw',
    lazy => 1,
    default => sub { 'Perl' },
);

# This is ignored for Perl plug-ins.
#has 'type' => ()

has 'name' => (
    is          => 'rw',
    lazy        => 1,
    default => sub {
        return lc($_[0]->zilla->name)
    }
);

has 'keyword' => (
    is => 'rw',
    lazy => 1,
    default => sub { return '' }
);

has 'license' => (
    is => 'rw',
    lazy => 1,
    default => sub { $_[0]->zilla->license }
);

has 'bugs' => (
    is => 'rw',
    lazy => 1,
    default => sub { $_[0]->zilla->distmeta->{resources}->{bugtracker}->{web} }
);

has 'version' => (
    is          => 'rw',
    lazy        => 1,
    default => sub {
        my $version = $_[0]->zilla->version;

        $version .= '.0' if $version !~ m!\d+\.\d+\.\d+!;

        # Strip leading zeros.
        $version =~ s/\.0+(\d+)/.$1/g;

        return $version
    }
);

has 'author' => (
    is          => 'rw',
    lazy        => 1,
    default => sub {
        return $_[0]->zilla->authors->[0]
    }
);

has 'description' => (
    is          => 'rw',
    lazy        => 1,
    default => sub {
        return $_[0]->zilla->abstract
    }
);

has 'homepage' => (
    is          => 'rw',
    lazy        => 1,
    default => sub {
        my $meta = $_[0]->zilla->distmeta;

        return $meta->{ resources } && $meta->{ resources }->{ homepage }
    }
);

has 'repository' => (
    is          => 'rw',
    lazy        => 1,
    default => sub {
        my $meta = $_[0]->zilla->distmeta;

        return $meta->{ resources } && $meta->{ resources }->{ repository }
    }
);

has 'contributor' => (
    is          => 'rw',
    lazy        => 1,
    default => sub {
        my @authors = @{$_[0]->zilla->authors};

        shift @authors;

        return \@authors;
    }
);


has 'main' => (
    is          => 'rw',
    lazy        => 1,
    default => sub {
        return 'index.pl';
    }
);

has 'dependency' => (
    is          => 'rw',
    lazy        => 1,
    default     => sub { [] }
);

has 'devDependency' => (
    is          => 'rw',
    lazy        => 1,
    default     => sub { [] }
);

has 'peerDependency' => (
    is => 'rw',
    lazy => 1,
    default => sub { ["Qgoda ^$Qgoda::VERSION"] }
);

has 'engine' => (
    is          => 'rw',
    lazy        => 1,
    default     => sub { [] }
);

has 'bin' => (
    is          => 'rw',
    default     => sub { [] }
);

has 'links_deps' => (
    is          => 'rw',
    default     => 1
);

sub build {}

sub gather_files {
    my ($self) = @_;

    $self->add_file(Dist::Zilla::File::FromCode->new({
        name => file('package.json') . '',
        code => sub {
            my $package = {};
            $package->{$_} = $self->$_ for qw(name version description homepage
                                                repository author main);
            $package->{contributors} = $self->contributor;
            $package->{dependencies} =
                $self->convert_versions($self->dependency)
                    if @{$self->dependency} > 0;
            $package->{devDependencies} =
                $self->convert_versions($self->devDependency)
                    if @{$self->devDependency} > 0;
            $package->{peerDependencies} =
                $self->convert_versions($self->peerDependency)
                    if @{$self->peerDependency} > 0;
            $package->{engines}
                =  $self->convert_engines($self->engine) if @{$self->engine} > 0;
            $package->{ directories }   = {
                "lib" => "./lib",
                "t" => "./t",
            };
            $package->{keywords} = $self->keyword;
            $package->{bugs} = $self->bugs if $self->bugs;
            $package->{bin} = $self->convert_dependencies($self->bin)
                if @{$self->bin} > 0;
            if ($self->license) {
                my $license = ref $self->{license};
                $license =~ s/.*:://;
                $package->{license} = $license;
            }

            $package->{scripts} = {
                test => 'make test'
            };

            # Qgoda specific stuff.
            my $qgoda = $package->{qgoda} = {};
            $qgoda->{language} = $self->language;

            return JSON->new->utf8(1)->pretty(1)->encode($package)
        }
    }));
}

sub convert_versions {
    my ($self, $deps) = @_;

    my %hash = map {
        my ($package, $spec) = split /[ \011-\015]+/, $_;
        $package => $spec; 
    } @$deps;

    return \%hash;
}

sub mvp_multivalue_args {
    qw(contributor dependency devDependency engine bin keyword)
}

no Moose;
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;

=head1 NAME

Dist::Zilla::Plugin::Qgoda - Write a package.json for Qgoda plug-ins.

=head1 SYNOPSIS

In your F<dist.ini>:

    [Qgoda]
    language        = 'Perl'

    name            = my-plug-in ; default: lowercased distribution name
    version         = 1.2.3       ; version, appended with ".0" to conform semver
                                  ; (if not provided)
    author          = Your Name <you@example.com>

    contributor     = Helper 1 <helper1@example.com>
    contributor     = Helper 2 <helper2@example.com>

    description     = Does a thing. 
    keyword         = thing
    keyword         = perl

    homepage        = http://www.example.com/
    repository      = git://git.example.com
    bugs            = http://tracker.example.com/my-plug-in

    main            = 'index.pl'

    dependency      = foo ^1.2.3
    dependency      = bar ~>^4.5.6
    devDependency   = foo ^1.2.3
    devDependency   = bar ~>^4.5.6
    peerDependency  = Qgoda ~>1.2.3
    peerDependency  = other-package ^4.5.6

    engine          = node ~>^8.0.4
    engine          = dode ^1.5.4

    bin             = bin_name ./bin/path/to.js

All fields are optional and have sane defaults!

=head1 DESCRIPTION

Generate the "package.json" file for your distribution, based on the content of
"dist.ini".

This module was heavily inspired by L<Dist::Zilla::Plugin::Web::NPM::Package>.

=head1 COPYRIGHT

This library is free software. It comes without any warranty, to the
extent permitted by applicable law. You can redistribute it and/or
modify it under the terms of the Do What the Fuck You Want to Public
License, Version 2, as published by Sam Hocevar. See
http://www.wtfpl.net/ for more details.
