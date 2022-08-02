package Dist::Zilla::Plugin::InsertCommandOutput;

use 5.010001;
use strict;
use warnings;

use Proc::ChildError qw(explain_child_error);

use Moose;
with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':InstallModules', ':ExecFiles'],
    },
);

has make_verbatim => (is => 'rw', default => sub{1}); # DEPRECATED

has indent => (is => 'rw', default => sub{1});

use namespace::autoclean;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-06-10'; # DATE
our $DIST = 'Dist-Zilla-Plugin-InsertCommandOutput'; # DIST
our $VERSION = '0.056'; # VERSION

sub munge_files {
    my $self = shift;

    $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
    my ($self, $file) = @_;
    my $content_as_bytes = $file->encoded_content;
    if ($content_as_bytes =~ s{^#\s*COMMAND:\s*(.*)[ \t]*(\R|\z)}{
        my $output = $self->_command_output($1);
        $output .= "\n" unless $output =~ /\R\z/;
        $output;
    }egm) {
        $self->log(["inserting output of command '%s' in %s", $1, $file->name]);
        $self->log_debug(["output of command: %s", $content_as_bytes]);
        $file->encoded_content($content_as_bytes);
    }
}

sub _command_output {
    my($self, $cmd) = @_;

    my $res = `$cmd`;

    if ($?) {
        die "Command '$cmd' failed: " . explain_child_error();
    }

    my $indent = " " x $self->indent;

    $res =~ s/^/$indent/gm if $self->make_verbatim;
    $res;
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Insert the output of command into your POD

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::InsertCommandOutput - Insert the output of command into your POD

=head1 VERSION

This document describes version 0.056 of Dist::Zilla::Plugin::InsertCommandOutput (from Perl distribution Dist-Zilla-Plugin-InsertCommandOutput), released on 2022-06-10.

=head1 SYNOPSIS

In dist.ini:

 [InsertCommandOutput]
 ;indent=4

In your POD:

 # COMMAND: netstat -anp

=head1 DESCRIPTION

This module finds C<# COMMAND: ...> directives in your POD, pass it to the
Perl's backtick operator, and insert the result into your POD as a verbatim
paragraph (unless if you set C<make_verbatim> to 0, in which case output will be
inserted as-is). If command fails (C<$?> is non-zero), build will be aborted.

=for Pod::Coverage .+

=head1 CONFIGURATION

=head2 indent

Uint. Default: 1. Number of spaces to indent each line of output with. Can be
set to 0 to not indent at all.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-InsertCommandOutput>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-InsertCommandOutput>.

=head1 SEE ALSO

L<Dist::Zilla::Plugin::InsertCodeResult>, which can also be used to accomplish
the same thing, e.g. with C<# CODE: my $res = `netstat -anp`; die if $?; $res>
except the DZP::InstallCommandResult plugin is shorter.

L<Dist::Zilla::Plugin::InsertCodeOutput>, which can also be used to accomplish
the same thing, e.g. with C<# CODE: system "netstat -anp"; die if $?>.

L<Dist::Zilla::Plugin::InsertExample>

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

This software is copyright (c) 2022, 2021, 2019, 2018, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-InsertCommandOutput>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
