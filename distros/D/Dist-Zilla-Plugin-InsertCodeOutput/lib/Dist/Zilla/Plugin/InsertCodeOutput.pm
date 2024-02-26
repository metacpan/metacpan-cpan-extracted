package Dist::Zilla::Plugin::InsertCodeOutput;

use 5.010001;
use strict;
use warnings;

use Capture::Tiny qw(capture_merged);
use String::CommonPrefix qw(common_prefix);

use Moose;
with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':InstallModules', ':ExecFiles'],
    },
);

has make_verbatim => (is => 'rw', default => sub{1});

use namespace::autoclean;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-11'; # DATE
our $DIST = 'Dist-Zilla-Plugin-InsertCodeOutput'; # DIST
our $VERSION = '0.046'; # VERSION

sub munge_files {
    my $self = shift;

    $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
    my ($self, $file) = @_;
    my $content_as_bytes = $file->encoded_content;
    if ($content_as_bytes =~ s{
                                  ^\#\s*CODE:\s*(.*)[ \t]*(?:\R|\z) |
                                  ^\#\s*BEGIN_CODE\s*\R((?:.|\R)*?)^\#\s*END_CODE[ \t]*(?:\R|\z)
                          }{
                              my $output = $self->_code_output($1 // $2);
                              $output .= "\n" unless $output =~ /\R\z/;
                              $output;
                          }egmx) {
        $self->log(["inserting output of code '%s' in %s", $1 // $2, $file->name]);
        $self->log_debug(["content of %s after code output insertion: '%s'", $file->name, $content_as_bytes]);
        $file->encoded_content($content_as_bytes);
    }
}

sub _code_output {
    my($self, $code) = @_;

    local @INC = @INC;
    unshift @INC, "lib";

  REMOVE_COMMENT: {
        my @lines = split /^/m, $code;
        my $common_prefix = common_prefix(@lines);
        if ($common_prefix =~ /\A\#+\s*\z/) {
            $code =~ s/^\Q$common_prefix\E//gm;
        }
    }

    my $eval_res;
    my ($merged, @result) = capture_merged { eval $code; $eval_res = $@ };## no critic: BuiltinFunctions::ProhibitStringyEval

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

This document describes version 0.046 of Dist::Zilla::Plugin::InsertCodeOutput (from Perl distribution Dist-Zilla-Plugin-InsertCodeOutput), released on 2023-12-11.

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

(you can prefix each line in multiline code with comment, to prevent this code
from being analyzed by other analyzers e.g. L<scan_prereqs>):

 # BEGIN_CODE
 #require MyLib;
 #MyLib::gen_stuff("some", "param");
 #...
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

=head1 SEE ALSO

L<Dist::Zilla::Plugin::InsertCodeResult> which is similar and uses the same C<#
CODE> directive, but instead of inserting output, will insert the result of the
code (which can be a reference, in which case will be dumped using
L<Data::Dump>).

L<Dist::Zilla::Plugin::InsertCommandOutput>

L<Dist::Zilla::Plugin::InsertExample>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023, 2021, 2020, 2019, 2018, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-InsertCodeOutput>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
