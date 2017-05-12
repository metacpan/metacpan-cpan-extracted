use 5.10.0;
use strict;
use warnings;

package Dist::Zilla::Plugin::PodnameFromClassname;

# ABSTRACT: Insert PODNAME for Moops classes.
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1100';

use Moose;
use namespace::autoclean;
with ('Dist::Zilla::Role::FileMunger', 'Dist::Zilla::Role::FileFinderUser' => { default_finders => [':InstallModules']});

sub munge_files {
    my $self = shift;
    $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
    my $self = shift;
    my $file = shift;
    my $content = $file->content;

    my $optional_ws = qr/[\t ]*/;

    if($content !~ m{^$optional_ws# PODCLASSNAME:?$}ms) {
        $self->log_debug(["Skipping %s, no # PODCLASSNAME directive found", $file->name]);
        return;
    }
    elsif($content !~ m{^$optional_ws(?:class|library|namespace|role) +([a-zA-Z][a-zA-Z0-9_]*(?:::[a-zA-Z][a-zA-Z0-9_]*)*)}ms) {
        $self->log_debug(["Skipping %s, none of the keywords found", $file->name]);
        return;
    }
    my $classname = $1;

    $content =~ s{^($optional_ws)# PODCLASSNAME:?$}{$1# PODNAME: $classname}ms;

    $self->log(["Inserting podname for $classname"]);
    $file->content($content);

}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::PodnameFromClassname - Insert PODNAME for Moops classes.



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10+-blue.svg" alt="Requires Perl 5.10+" />
<a href="https://travis-ci.org/Csson/p5-Dist-Zilla-Plugin-PodnameFromClassname"><img src="https://api.travis-ci.org/Csson/p5-Dist-Zilla-Plugin-PodnameFromClassname.svg?branch=master" alt="Travis status" /></a>
<a href="http://cpants.cpanauthors.org/dist/Dist-Zilla-Plugin-PodnameFromClassname-0.1100"><img src="https://badgedepot.code301.com/badge/kwalitee/Dist-Zilla-Plugin-PodnameFromClassname/0.1100" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=Dist-Zilla-Plugin-PodnameFromClassname%200.1100"><img src="https://badgedepot.code301.com/badge/cpantesters/Dist-Zilla-Plugin-PodnameFromClassname/0.1100" alt="CPAN Testers result" /></a>
<img src="https://img.shields.io/badge/coverage-81.4%-orange.svg" alt="coverage 81.4%" />
</p>

=end html

=head1 VERSION

Version 0.1100, released 2016-04-02.

=head1 SYNOPSIS

In dist.ini:

    [PodnameFromClassname]

In a L<Moops> class:

    # PODCLASSNAME

    class My::Class { ... }

Results in:

    # PODNAME: My::Class

    class My::Class { ... }

=head1 DESCRIPTION

Dist::Zilla::Plugin::PodnameFromClassname is useful together with L<Moops> and L<Pod::Weaver>. Since Moops classes generally don't also have a C<package> statement C<Pod::Weaver> can't pick up the module name.

Using this plugin and adding a C<# PODCLASSNAME> line fixes that (by replacing such a line with the standard C<# PODNAME: $classname> comment). There should be only one C<# PODCLASSNAME> comment per file.

The plugin picks the first line that starts with C<class>, C<role>, C<namespace> or C<library> and uses the package name given on that line.

The comment line should match this regular expression:

    qr/^[\t ]*# PODCLASSNAME:?$/ms

Note: While this plugin was developed with L<Moops> in mind, it should work with any module that introduces any of those keywords.

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::Plugin::PodnameFromFilename>

=item *

L<Dist::Zilla>

=back

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Zilla-Plugin-PodnameFromClassname>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Zilla-Plugin-PodnameFromClassname>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
