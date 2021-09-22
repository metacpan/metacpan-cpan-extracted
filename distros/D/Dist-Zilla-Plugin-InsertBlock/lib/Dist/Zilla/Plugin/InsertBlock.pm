package Dist::Zilla::Plugin::InsertBlock;

use 5.010001;
use strict;
use warnings;

use Moose;
with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':InstallModules', ':ExecFiles', ':TestFiles'],
    },
);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-09-16'; # DATE
our $DIST = 'Dist-Zilla-Plugin-InsertBlock'; # DIST
our $VERSION = '0.103'; # VERSION

use namespace::autoclean;
has _directive_re => (is=>'rw', default=>sub{qr/INSERT_BLOCK/});

sub munge_files {
    my $self = shift;

    $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
    my ($self, $file) = @_;
    my $content_as_bytes = $file->encoded_content;
    my $directive = $self->_directive_re;
    if ($content_as_bytes =~ s{^#\s*$directive:\s*(.*?)\s+(\w+)(?:\s+(\w+))?\s*$}
                              {$self->_insert_block($1, $2, $3, $file->name)}egm) {
        $file->encoded_content($content_as_bytes);
    }
}

sub _insert_block {
    my($self, $file, $name, $opts, $target) = @_;

    open my($fh), "<", $file or do {
        $self->log_fatal(["can't open %s: %s", $file, $!]);
    };
    my $content = do { local $/; scalar <$fh> };

    my $block;
    if ($content =~ /^=for [ \t]+ BEGIN_BLOCK: [ \t]+ \Q$name\E[ \t]* \R
                     (.*?)
                     ^=for [ \t]+ END_BLOCK: [ \t]+ \Q$name\E/msx) {
        $self->log(["inserting block from '%s' named %s into '%s' (=for syntax)", $file, $name, $target]);
        $block = $1;
    } elsif ($content =~ /^=over [ \t]+ 11 [ \t]* \R\R
                          ^=back [ \t]+ BEGIN_BLOCK: [ \t]+ \Q$name\E[ \t]* \R
                          (.*?)
                          ^=over [ \t]+ 11 [ \t]* \R\R
                          ^=back [ \t]+ END_BLOCK:   [ \t]+ \Q$name\E/msx) {
        $self->log(["inserting block from '%s' named %s into '%s' (=over 11 syntax)", $file, $name, $target]);
        $block = $1;
    } elsif ($content =~ /^\# [ \t]* BEGIN_BLOCK: [ \t]+ \Q$name\E[ \t]* \R
                     (.*?)
                     ^\# [ \t]* END_BLOCK: [ \t]+ \Q$name\E/msx) {
        $self->log(["inserting block from '%s' named %s into '%s' (# syntax)", $file, $name, $target]);
        $block = $1;
    } else {
        $self->log_fatal(["can't find block named %s in file '%s'", $name, $file]);
    }

    $opts //= "";
    if ($opts eq 'pod_verbatim') {
        $block =~ s/^/ /mg;
    }

    return $block;
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Insert a block of text from another file

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::InsertBlock - Insert a block of text from another file

=head1 VERSION

This document describes version 0.103 of Dist::Zilla::Plugin::InsertBlock (from Perl distribution Dist-Zilla-Plugin-InsertBlock), released on 2021-09-16.

=head1 SYNOPSIS

In dist.ini:

 [InsertBlock]

In lib/Baz.pm:

 ...

 # BEGIN_BLOCK: some_code

 ...

 # END_BLOCK

In lib/Foo/Base.pm:

 ...

 =head1 ATTRIBUTES

 =for BEGIN_BLOCK: base_attributes

 =head2 attr1

 =head2 attr2

 =for END_BLOCK: base_attributes

 ...

 =head1 METHODS

 =over 11

 =back BEGIN_BLOCK: base_methods

 =head2 meth1

 =head2 meth2

 =over 11

 =back END_BLOCK: base_methods

In lib/Foo/Bar.pm:

 ...

 # INSERT_BLOCK: lib/Baz.pm some_code

 ...

 =head1 ATTRIBUTES

 # INSERT_BLOCK: lib/Foo/Base.pm base_attributes

 =head2 attr3

 ...

 =head1 METHODS

 =INSERT_BLOCK: lib/Foo/Base.pm base_methods

 =head2 meth3

 ...

=head1 DESCRIPTION

This plugin finds C<< # INSERT_BLOCK: <file> <name> >> directives in your
POD/code. It then searches for a block of text named I<name> in file I<file>,
and inserts the content of the block to replace the directive.

A block is marked/defined using either this syntax:

 # BEGIN_BLOCK: Name
 ...
 # END_BLOCK: Name

or this (for block inside POD):

 =for BEGIN_BLOCK: Name

 ...

 =for END_BLOCK: Name

or this C<=over 11> workaround syntax (for blocks inside POD, in case tools like
L<Pod::Weaver> remove C<=for> directives):

 =over 11

 =back BEGIN_BLOCK: Name

 ...

 =over 11

 =back END_BLOCK: Name

Block name is case-sensitive.

This plugin can be useful to avoid repetition/manual copy-paste, e.g. when you
want to list POD attributes, methods, etc from a base class into a subclass.

=head2 Options

The C<# INSERT_BLOCK> directive accepts an optional third argument for options.
Known options:

=over

=item * pod_verbatim

This option pads each line of the block content with whitespace. Suitable for
when you are inserting a block into a POD and you want to make the content of
the block as POD verbatim.

=back

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-InsertBlock>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-InsertBlock>.

=head1 SEE ALSO

L<Dist::Zilla::Plugin::InsertBlock::FromModule>

L<Dist::Zilla::Plugin::InsertCodeResult>

L<Dist::Zilla::Plugin::InsertCodeOutput>

L<Dist::Zilla::Plugin::InsertCommandOutput>

L<Dist::Zilla::Plugin::InsertExample> - which basically insert whole files
instead of just a block of text from a file

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-InsertBlock>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
