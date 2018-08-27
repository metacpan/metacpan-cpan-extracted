use 5.14.0;

# ABSTRACT: PkgVersion for block packages

package Dist::Zilla::Plugin::PkgVersion::Block {

our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0200';

    use Moose;
    with('Dist::Zilla::Role::FileMunger',
         'Dist::Zilla::Role::FileFinderUser' => { default_finders => [':InstallModules', ':ExecFiles'] },
         'Dist::Zilla::Role::PPI'
    );

    use PPI;
    use MooseX::Types::Perl qw/StrictVersionStr/;
    use namespace::autoclean;

    sub munge_files {
        my($self) = @_;

        if(!StrictVersionStr->check($self->zilla->version)) {
            Carp::croak('Version ' . $self->zilla->version . ' does not conform to the strict version string format.') ;
        }
        $self->munge_file($_) for @{ $self->found_files };
    }

    sub munge_file {
        my $self = shift;
        my $file = shift;

        if($file->is_bytes) {
            $self->log_debug([ "%s has 'bytes' encoding, skipping...", $file->name ]);
            return;
        }
        return $self->munge_perl($file);
    }

    sub munge_perl {
        my $self = shift;
        my $file = shift;

        my $document = $self->ppi_document_for_file($file);

        my $package_statements = $document->find('PPI::Statement::Package');
        if(!$package_statements) {
            $self->log_debug([ 'skipping %s: no package statement found', $file->name ]);
            return;
        }

        if($self->document_assigns_to_variable($document, '$VERSION')) {
            $self->log_fatal([ 'existing assignment to $VERSION in %s', $file->name ]);
        }

        my %seen;
        my $munged = 0;

        STATEMENT:
        for my $stmt (@{ $package_statements }) {
            my $package = $stmt->namespace;
            if($seen{ $package }++) {
                $self->log([ 'skipping package re-declaration for %s', $package ]);
                next STATEMENT;
            }
            if($stmt->content =~ m{ package \s* (?:\#.*)? \n \s* \Q$package}x ) {
                $self->log([ 'skipping private package %s in %s', $package, $file->name] );
                next STATEMENT;
            }
            if($package =~ m{\P{ASCII}}) {
                $self->log('non-ASCII package name is likely to cause problems');
            }

            my $count = 0;
            my $name_token = undef;

            TOKEN:
            foreach my $token ($stmt->tokens) {
                ++$count;

                last TOKEN if $count == 1 && $token ne 'package';
                last TOKEN if $count == 2 && $token !~ m{\s+};
                last TOKEN if $count == 3 && $token !~ m{\w+(::\w+)*};
                $name_token = $token if $count == 3;
                last TOKEN if $count == 4 && $token !~ m{\s+};
                last TOKEN if $count == 5 && $token ne '{';

                if($count == 5) {
                    my $version_token = PPI::Token::Comment->new(" " . $self->zilla->version);
                    $name_token->insert_after($version_token);
                    $munged = 1;
                    $self->log([ 'adding version to %s in %s', $package, $file->name ]);
                    last TOKEN;
                }
            }
        }
        $self->save_ppi_document_to_file($document, $file) if $munged;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::PkgVersion::Block - PkgVersion for block packages



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.14+-blue.svg" alt="Requires Perl 5.14+" />
<a href="https://travis-ci.org/Csson/p5-Dist-Zilla-Plugin-PkgVersion-Block"><img src="https://api.travis-ci.org/Csson/p5-Dist-Zilla-Plugin-PkgVersion-Block.svg?branch=master" alt="Travis status" /></a>
<a href="http://cpants.cpanauthors.org/release/CSSON/Dist-Zilla-Plugin-PkgVersion-Block-0.0200"><img src="http://badgedepot.code301.com/badge/kwalitee/CSSON/Dist-Zilla-Plugin-PkgVersion-Block/0.0200" alt="Distribution kwalitee" /></a>
<a href="http://matrix.cpantesters.org/?dist=Dist-Zilla-Plugin-PkgVersion-Block%200.0200"><img src="http://badgedepot.code301.com/badge/cpantesters/Dist-Zilla-Plugin-PkgVersion-Block/0.0200" alt="CPAN Testers result" /></a>
<img src="https://img.shields.io/badge/coverage-80.0%-orange.svg" alt="coverage 80.0%" />
</p>

=end html

=head1 VERSION

Version 0.0200, released 2018-08-26.

=head1 SYNOPSIS

    # dist.ini
    [PkgVersion::Block]

=head1 DESCRIPTION

This plugin turns:

    package My::Package {
        ...
    }

into:

    package My::Package 0.01 {
        ...
    }

for all packages in the distribution.

The block package syntax was introduced in Perl 5.14, so this plugin is only usable in projects that only support 5.14+.

There are no attributes. However:

=over 4

=item *

Having an existing assignment to $VERSION in the file is a fatal error.

=item *

Packages with a version number between the namespace and the block are silently skipped.

=back

=head1 KNOWN PROBLEMS

In files with more than one package block it is currently necessary to end (all but the last) package blocks with a semicolon. Otherwise only the first package will get a version number:

    package My::Package {
        ...
    };

    package My::Package::Other {
        ...
    }

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::Plugin::PkgVersion> (on which this is based)

=item *

L<Dist::Zilla::Plugin::OurPkgVersion>

=back

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Zilla-Plugin-PkgVersion-Block>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Zilla-Plugin-PkgVersion-Block>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
