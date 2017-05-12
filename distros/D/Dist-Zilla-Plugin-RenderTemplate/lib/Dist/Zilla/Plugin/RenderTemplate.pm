package Dist::Zilla::Plugin::RenderTemplate;

our $DATE = '2015-03-22'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;

use DTL::Fast;

use Moose;
with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':InstallModules', ':ExecFiles'],
    },
);

use namespace::autoclean;

sub munge_files {
    my $self = shift;
    $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
    my ($self, $file) = @_;

    my $content = $file->content;
    if ($content =~ s{^#\s*RENDER_TEMPLATE:\s*(\S.*)$}
                     {$self->_render_template($file->name, $1)."\n"}egm) {
        $self->log(["Rendered template in %s", $file->name]);
        $file->content($content);
    }
}

sub _render_template {
    my($self, $filename, $raw_args) = @_;

    my $errp = "Can't render template in $filename";

    my %args;
    eval "\%args = ($raw_args);";
    $self->log_fatal(["$errp: invalid args: %s", $@]) if $@;

    my $srcfile;
    if ($args{dist} && $args{dist_file}) {
        require File::ShareDir;
        eval { $srcfile = File::ShareDir::dist_file(
            $args{dist}, $args{dist_file}) };
        $self->log_fatal(["$errp: unknown dist file (%s, %s): %s",
                          $args{dist}, $args{dist_file}, $@])
            if $@;
    } elsif ($args{file}) {
        $srcfile = $args{file};
    } else {
        $self->log_fatal(["$errp: either specify file, or dist + dist_file"]);
    }

    open my($fh), "<", $srcfile or do {
        $self->log_fatal(["$errp: can't open %s: %s", $srcfile, $!]);
    };
    my $srctext = do { local $/; ~~<$fh> };

    my $tpl = DTL::Fast::Template->new($srctext);
    $tpl->render($args{context} // {});

}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Render template into your scripts/modules during build

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::RenderTemplate - Render template into your scripts/modules during build

=head1 VERSION

This document describes version 0.01 of Dist::Zilla::Plugin::RenderTemplate (from Perl distribution Dist-Zilla-Plugin-RenderTemplate), released on 2015-03-22.

=head1 SYNOPSIS

In C<dist.ini>:

 [RenderTemplate]

In C</some/path/template.txt>:

 Hello, {{ username }}!

In lib/Foo.pm:

 ...

 # RENDER_TEMPLATE: file=>"/some/path/template.txt", context=>{username=>"ujang"}

 ...

After build, lib/Foo.pm will become:

 ...

 Hello, ujang!

 ...

=head1 DESCRIPTION

This plugin finds C<#RENDER_TEMPLATE: ...> directive in your scripts/modules,
renders the specified template (currently using L<DTL::Fast>), and replaces the
directive with the rendered result.

The C<...> part is parsed as Perl using C<eval> and should produce a hash of
arguments. Known arguments:

=over

=item * file => str

Specify the path to template file. Either specify this, or C<dist> and
C<dist_file>.

=item * dist => str

Specify that template file is to be retrieved from per-dist shared dir (see
L<File::ShareDir>). This argument specify the dist name. You also have to
specify C<dist_file>. The path to template will be retrieved using
C<dist_file($dist, $dist_file)>.

=item * dist_file => str

See C<dist> argument.

=item * context => hashref

Specify context (variables).

=back

=for Pod::Coverage .+

=head1 SEE ALSO

L<DTL::Fast>

L<Dist::Zilla::Plugin::InsertBlock>

L<Dist::Zilla::Plugin::InsertExample> - which basically insert whole files
instead of just a block of text from a file

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-RenderTemplate>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-RenderTemplate>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-RenderTemplate>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
