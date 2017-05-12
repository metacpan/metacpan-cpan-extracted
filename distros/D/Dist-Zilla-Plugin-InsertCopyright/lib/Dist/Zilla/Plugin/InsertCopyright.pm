use 5.008001;
use strict;
use warnings;
use utf8;

package Dist::Zilla::Plugin::InsertCopyright;
# ABSTRACT: Insert copyright statement into source code files
our $VERSION = '0.005'; # VERSION

use PPI::Document;
use Moose;
use Carp qw/croak/;

#<<< No perltidy
with(
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::PPI',
);
#>>>

has copyright_lines => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

sub _build_copyright_lines {
    my ($self) = @_;
    my @copyright = (
        '', "This file is part of " . $self->zilla->name,
        '', split( /\n/, $self->zilla->license->notice ), '',
    );

    my @copyright_comment = map { length($_) ? "# $_" : '#' } @copyright;

    return \@copyright_comment;
}

# -- public methods

sub munge_file {
    my ( $self, $file ) = @_;

    if (   $file->name =~ /\.(?:pm|pl|t)$/i
        || $file->content =~ /^#!(?:.*)perl(?:$|\s)/ )
    {
        $self->_munge_perl($file);
    }

    return;
}

# -- private methods

#
# $self->_munge_perl($file, $lines);
#
# munge content of perl $file: add stuff at a #COPYRIGHT comment
#

sub _munge_perl {
    my ( $self, $file ) = @_;

    my $doc = $self->ppi_document_for_file($file);

    my $comments = $doc->find('PPI::Token::Comment');

    my $lines = $self->copyright_lines;

    if ( ref($comments) eq 'ARRAY' ) {
        foreach my $c ( @{$comments} ) {
            if ( $c =~ /^(\s*)(\#\s+COPYRIGHT\b)$/xms ) {
                my ( $ws, $comment ) = ( $1, $2 );
                my $code = join( "\n", map { "$ws$_" } @$lines );
                $c->set_content("$code\n");
                $self->log_debug( "Added copyright to " . $file->name );
                last;
            }
        }
        $self->save_ppi_document_to_file( $doc, $file );
    }

    return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

# COPYRIGHT

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::InsertCopyright - Insert copyright statement into source code files

=head1 VERSION

version 0.005

=head1 SYNOPSIS

In your F<dist.ini>:

    [InsertCopyright]

In your source files (before C<__END__>):

  # COPYRIGHT

=head1 DESCRIPTION

This module replaces a special C<# COPYRIGHT> comment in your Perl source
files with a short notice appropriate to your declared copyright.  The
special comment B<must> be placed before C<__END__>.  Only the first such
comment will be replaced.

It is inspired by excellent L<Dist::Zilla::Plugin::Prepender> but gives control
of the copyright notice placement instead of always adding it at the start of a
file.

I wrote this to let me put copyright statements at the end of my code to keep
line numbers of code consistent between the generated distribution and the
repository source.  See L<Dist::Zilla::Plugin::OurPkgVersion> for another
useful plugin that preserves line numbering.

=for Pod::Coverage munge_file

=head1 ACKNOWLEDGMENTS

Code in this module is based heavily on Dist::Zilla::Plugin::OurPkgVersion
by Caleb Cushing and Dist::Zilla::Plugin::Prepender by Jérôme Quelin.  Thank
you to both of them for their work and for releasing it as open source for
reuse.

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla> and L<dzil.org|http://dzil.org/>

=item *

L<Dist::Zilla::Plugin::OurPkgVersion>

=item *

L<Dist::Zilla::Plugin::Prepender>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/Dist-Zilla-Plugin-InsertCopyright/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/Dist-Zilla-Plugin-InsertCopyright>

  git clone https://github.com/dagolden/Dist-Zilla-Plugin-InsertCopyright.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 CONTRIBUTORS

=over 4

=item *

Jean-Damien Durand <jeandamiendurand@free.fr>

=item *

Keedi Kim <keedi.k@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
