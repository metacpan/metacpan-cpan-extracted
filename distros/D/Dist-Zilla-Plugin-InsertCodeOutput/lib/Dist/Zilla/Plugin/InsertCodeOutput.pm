package Dist::Zilla::Plugin::InsertCodeOutput;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-21'; # DATE
our $DIST = 'Dist-Zilla-Plugin-InsertCodeOutput'; # DIST
our $VERSION = '0.042'; # VERSION

use 5.010001;
use strict;
use warnings;

use Capture::Tiny qw(capture_merged);

use Moose;
with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':InstallModules', ':ExecFiles'],
    },
);

has make_verbatim => (is => 'rw', default => sub{1});

use namespace::autoclean;

sub munge_files {
    my $self = shift;

    $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
    my ($self, $file) = @_;
    my $content = $file->content;
    if ($content =~ s{
                         ^\#\s*CODE:\s*(.*)\s*$ |
                         ^\#\s*BEGIN_CODE\s*\R((?:.|\R)*?)^\#\s*END_CODE\s*(?:\R|\z)
                 }{
                     $self->_code_output($1 // $2)."\n"
                 }egmx) {
        $self->log(["inserting output of code '%s' in %s", $1 // $2, $file->name]);
        $self->log_debug(["content of %s after code output insertion: '%s'", $file->name, $content]);
        $file->content($content);
    }
}

sub _code_output {
    my($self, $code) = @_;

    local @INC = @INC;
    unshift @INC, "lib";

    my $eval_res;
    my ($merged, @result) = capture_merged { eval $code; $eval_res = $@ };

    if ($eval_res) {
        die "eval '$code' failed: $@";
    }

    $merged =~ s/^/ /gm if $self->make_verbatim;
    $merged;
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Insert the output of Perl code into your POD

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::InsertCodeOutput - Insert the output of Perl code into your POD

=head1 VERSION

This document describes version 0.042 of Dist::Zilla::Plugin::InsertCodeOutput (from Perl distribution Dist-Zilla-Plugin-InsertCodeOutput), released on 2020-02-21.

=head1 SYNOPSIS

In dist.ini:

 [InsertCodeOutput]
 ;make_verbatim=1

In your POD:

 # CODE: require MyLib; MyLib::gen_stuff("some", "param");

or for multiline code:

 # BEGIN_CODE
 require MyLib;
 MyLib::gen_stuff("some", "param");
 ...
 # END_CODE

=head1 DESCRIPTION

This module finds C<# CODE: ...> or C<# BEGIN_CODE> and C<# END CODE> directives
in your POD, evals the specified Perl code while capturing the output using
L<Capture::Tiny>'s C<capture_merged> (which means STDOUT and STDERR output are
both captured), and insert the output to your POD as verbatim paragraph
(indented with a whitespace), unless when C<make_verbatim> is set to 0 then it
is inserted as-is. If eval fails (C<$@> is true), build will be aborted.

The directives must be at the first column of the line.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-InsertCodeOutput>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-InsertCodeOutput>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-InsertCodeOutput>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Dist::Zilla::Plugin::InsertCodeResult> which is similar and uses the same C<#
CODE> directive, but instead of inserting output, will insert the result of the
code (which can be a reference, in which case will be dumped using
L<Data::Dump>).

L<Dist::Zilla::Plugin::InsertCommandOutput>

L<Dist::Zilla::Plugin::InsertExample>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
