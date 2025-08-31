package Dist::Zilla::PluginBundle::YANICK::Contributing;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: add a CONTRIBUTING.md file to the package
$Dist::Zilla::PluginBundle::YANICK::Contributing::VERSION = '0.32.1';

use 5.20.0;
use warnings;

use Moose;
use Dist::Zilla::File::InMemory;

with qw/
    Dist::Zilla::Role::Plugin
    Dist::Zilla::Role::FileGatherer
    Dist::Zilla::Role::TextTemplate
/;

use experimental 'signatures';

has '+zilla' => (
    handles => { 
        distribution_name => 'name',
        authors           => 'authors',
    }
);

sub gather_files ($self) {
    $self->add_file(
        Dist::Zilla::File::InMemory->new({ 
            content => $self->fill_in_string(
                file_template(), {   
                    distribution => $self->distribution_name,
                },
            ),
            name    => 'CONTRIBUTING.md',
        })
    );
}

sub file_template {
    return <<'END_CONTRIBUTING';

# Contributing to {{ $distribution }}

So you want to contribute to this package? Or fork it? Or play with it, or
whatever? Excellent! Here, let me try to make it easier for you.

## Dist::Zilla and branch structure

This package, like many of mine, uses [Dist::Zilla](https://metacpan.org/dist/Dist-Zilla).
Dist::Zilla (`dzil` to its friends) is a distribution builder 
that helps (tremendously) with the nitty gritty of grooming 
and releasing packages to CPAN. It tidies up the
documentation, add boilerplate files, update versions,
and... do a *bunch* of other things. Because it does so
much, it can be scary for some people. But it really doesn't need
to be. 

This repository has two core branches:

* `main` -- the working branch, holding the pre-dzil-munging code. 

* `releases` -- contains the dzil-munged code released to
CPAN.

Which means that if you don't want to bother with
Dist::Zilla at all, checkout `releases` and work on it.
Since it's the "real" code that made it to CPAN, all it
working -- the package itself, the tests, everything. And
totally feel free to use this branch as a base for a PR.
I'll be very grateful for the work, and I'll take on the last
step of porting the patching to `main`, noooo problem.

### I'm brave, I want to be on `main`

Good for you! 

The good news is that dzil mostly tinker with stuff the 
working code doesn't care about, so you probably won't have
to do anything special. In most cases, tinkering with the
code will look like:

    $ cpanm --installdeps . 
    $ ... tinker, tinker ...
    $ prove -l t 

Now, if you want to generate the CPAN-ready tarball, or go
full YANICK on things. You'll have to install both
Dist::Zilla and my plugin bundle:

    $ cpanm Dist::Zilla Dist::Zilla::PluginBundle::YANICK

and then you should be able to do all things dzilly;

    # generate the tarball 
    $ dzil build 

    # run all the tests on the final code 
    $ dzil test 

Now, a honest caveat: `Dist::Zilla::PluginBundle::YANICK` is
tailored to my exact needs; it does a lot, and some of it
is not guaranteed to work on somebody else's system. If you
try to use it and you hit something weird, just let me know,
and I'll do my best to help you.

Aaaand that's pretty all I think you need to get started. Good luck! :-)
END_CONTRIBUTING
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::YANICK::Contributing - add a CONTRIBUTING.md file to the package

=head1 VERSION

version 0.32.1

=head1 SYNOPSIS

In dist.ini:

    [PluginBundle::YANICK::Contributing]

=head1 DESCRIPTION

C<Dist::Zilla::PluginBundle::YANICK::Covenant> adds the file
'I<CONTRIBUTING.md>' to the distribution. Right now that file 
mostly explains how to deal with the dzil'ed nature of my repos.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
