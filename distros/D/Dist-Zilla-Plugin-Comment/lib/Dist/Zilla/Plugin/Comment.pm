package Dist::Zilla::Plugin::Comment;

our $DATE = '2016-12-25'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

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

sub __comment_lines {
    local $_ = shift;
    s/^/## /gm;
    $_;
}

sub munge_file {
    my ($self, $file) = @_;
    my $content = $file->content;

    my $modified;

    $modified++ if
        $content =~ s/^(=for [ ] BEGIN_COMMENT$)
                      (\n[ \t]*)+
                      (.+?)
                      (\n[ \t]*)+
                      ^(=for [ ] END_COMMENT$)/$1 . $2 . __comment_lines($3) . $4 . $5/egmsx;

    $modified++ if
        $content =~ s/^(\# [ ] BEGIN_COMMENT$)
                      (.+?)
                      ^(\# [ ] END_COMMENT$)/$1 . __comment_lines($2) . $3/egmsx;

    $modified++ if
        $content =~ s/^(.+)(# COMMENT$)/__comment_lines($1) . $2/egm;

    if ($modified) {
        $self->log(["commented block(s)/line(s) in '%s'", $file->name]);
        $file->content($content);
    }
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Comment-out lines or blocks of lines

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Comment - Comment-out lines or blocks of lines

=head1 VERSION

This document describes version 0.02 of Dist::Zilla::Plugin::Comment (from Perl distribution Dist-Zilla-Plugin-Comment), released on 2016-12-25.

=head1 SYNOPSIS

In C<dist.ini>:

 [Comment]

In C<lib/Foo.pm>:

 ...

 do_something(); # COMMENT

 # BEGIN_COMMENT
 one();
 two();
 three();
 # END_COMMENT

 =pod

 =for BEGIN_COMMENT

 blah
 blah
 blah

 =for END_COMMENT

 ...

After build, C<lib/Foo.pm> will become:

 ...

 ## do_something(); # COMMENT

 # BEGIN_COMMENT
 ## one();
 ## two();
 ## three();
 # END_COMMENT

 =pod

 =for BEGIN_COMMENT

 ## blah
 ## blah
 ## blah

 =for END_COMMENT

 ...

=head1 DESCRIPTION

This plugin finds lines that end with C<# COMMENT>, or blocks of lines delimited
by C<# BEGIN COMMENT> ... C<# END_COMMENT> or C<=for BEGIN_COMMENT> ... C<=end
END_COMMENT> and comment them out.

This can be used, e.g. to do stuffs only when the source file is not the
dzil-built version, usually for testing.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-Comment>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-Comment>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Comment>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

You can use this plugin in conjunction with L<Dist::Zilla::Plugin::InsertBlock>.
DZP:InsertBlock can insert lines that will only be available in the dzil-built
version. While for the raw version, you can use DZP:Comment plugin to make lines
that will be commented-out in the dzil-built version.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
