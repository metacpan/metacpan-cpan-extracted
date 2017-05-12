package Dist::Zilla::Plugin::OverridePkgVersion;
use 5.008;
use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

use Moose;
with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [ ':InstallModules', ':ExecFiles' ],
    },
);

use PPI;
use MooseX::Types::Perl qw( LaxVersionStr );
use namespace::autoclean;
use version ();

sub munge_files {
    my $self = shift;
    $self->munge_file($_) for @{ $self->found_files };
    return;
}

my $comment_regex = qr{
    ^
        (\# \s+) (?:TRIAL\s+)?
        VERSION \b
        ( [ [:print:] \s ]* )
    $
}x;
my $assign_regex = qr{
    ^
        our \s* \$VERSION \s* = \s* '$version::LAX';
    $
}x;

sub munge_file {
    my ( $self, $file ) = @_;

    if ( $file->name =~ m/\.pod$/ ) {
        $self->log_debug([ 'Skipping: "%s" is pod only', $file->name ]);
        return;
    }

    my $version = $self->zilla->version;

    confess 'invalid characters in version'
        unless LaxVersionStr->check( $version );

    my $content = $file->content;

    my $doc = PPI::Document->new(\$content)
        or $self->log([ 'Skipping: "%s" error with PPI: %s', $file->name, PPI::Document->errstr ]);
    $doc->index_locations;

    return unless defined $doc;
    my $indexed;

    my $comments = $doc->find('PPI::Token::Comment');

    my $munged_version = 0;
    if ( ref $comments eq 'ARRAY' ) {
        for my $comment ( @$comments ) {
            if ( $comment =~ $comment_regex ) {
                my ($prelude, $remains) = ($1, $2);
                my $prev = $comment->sprevious_sibling;
                if ($prev && $comment->line_number == $prev->line_number) {
                    if ($prev->isa('PPI::Statement::Variable') && $prev =~ $assign_regex) {
                        while (my $next = $prev->next_sibling) {
                            last if $next == $comment;
                            $prelude = $next . $prelude;
                            $next->delete;
                        }
                        $prev->delete;
                    }
                    else {
                        next;
                    }
                }
                $prelude =~ s/^ //;
                my $code
                    = q[our $VERSION = '] . $version. q['; ]
                    . $prelude
                    . ($self->zilla->is_trial ? 'TRIAL ' : '')
                    . 'VERSION' . $remains;
                $comment->set_content($code);
                $file->content( $doc->serialize );
                $munged_version++;
            }
        }
    }

    if ( $munged_version ) {
        $self->log_debug([ 'adding $VERSION assignment to %s', $file->name ]);
    }
    else {
        $self->log([ 'Skipping: "%s" has no "# VERSION" comment', $file->name ]);
    }
    return;
}
__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Override existing VERSION in a module

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::OverridePkgVersion - Override existing VERSION in a module

=head1 VERSION

version 0.002

=head1 SYNOPSIS

in dist.ini

    [OverridePkgVersion]

in your modules

    # VERSION

=head1 DESCRIPTION

This module was created as an alternative to
L<Dist::Zilla::Plugin::OurPkgVersion> and uses some code from that
module.  In addition to inserting a version number, it will update
an existing version number.

=head2 EXAMPLES

in dist.ini

    version = 0.02;
    [OurPkgVersion]

in lib/My/Module.pm

    package My::Module;
    our $VERSION = '0.01'; # VERSION

output lib/My/Module.pm

    package My::Module;
    our $VERSION = '0.02'; # VERSION

=head1 AUTHOR

Graham Knop <haarg@haarg.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Knop.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
