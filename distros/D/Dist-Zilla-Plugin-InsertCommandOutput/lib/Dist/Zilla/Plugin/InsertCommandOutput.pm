package Dist::Zilla::Plugin::InsertCommandOutput;

use 5.010001;
use strict;
use warnings;

use IPC::System::Options;
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

has include_command => (is => 'rw', default => sub{0});

has substitute_template => (is => 'rw', default => sub{0});

has capture_stdout => (is => 'rw', default => sub{1});
has capture_stderr => (is => 'rw', default => sub{0});

use namespace::autoclean;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-10-28'; # DATE
our $DIST = 'Dist-Zilla-Plugin-InsertCommandOutput'; # DIST
our $VERSION = '0.057'; # VERSION

sub munge_files {
    my $self = shift;

    $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
    my ($self, $file) = @_;
    my $content_as_bytes = $file->encoded_content;
    if ($content_as_bytes =~ s{^#\s*COMMAND:\s*(.*)[ \t]*(\R|\z)}{
        my $output = $self->_command_output($file, $1);
        $output .= "\n" unless $output =~ /\R\z/;
        $output;
    }egm) {
        $self->log(["inserting output of command '%s' in %s", $1, $file->name]);
        $self->log_debug(["output of command: %s", $content_as_bytes]);
        $file->encoded_content($content_as_bytes);
    }
}

sub _command_output {
    my($self, $file, $cmd) = @_;

    my $cmd_for_display = $cmd;

    if ($self->substitute_template) {
        my %vars;
        my %vars_for_display;

      VAR_PROG: {
            require String::ShellQuote;
            (my $prog = $file->name) =~ s!.*/!!;
            $vars{prog} = String::ShellQuote::shell_quote($^X) . " " . String::ShellQuote::shell_quote($file->name);
            $vars_for_display{prog} = $prog;
        }

      VAR_MODULE: {
            require String::ShellQuote;
            my $module = $file->name;
            if ($module =~ m!^(?:lib/)?(.+)\.pm$!) {
                $module = $1;
                $module =~ s!/!::!g;
            } else {
                $module = "";
            }

            $vars{module} = $module;
            $vars_for_display{module} = $module;
        }

        $cmd             =~ s/\[\[(\w+)\]\]/exists $vars            {$1} ? $vars            {$1} : do {$self->log("Undefined template variable $1"); ""}/eg;
        $cmd_for_display =~ s/\[\[(\w+)\]\]/exists $vars_for_display{$1} ? $vars_for_display{$1} : do {$self->log("Undefined template variable (for display) $1"); ""}/eg;
    }

    my $res;
    my $capture_key =
        $self->capture_stdout  && $self->capture_stderr ? "capture_merged" :
        !$self->capture_stdout && $self->capture_stderr ? "capture_stderr" :
        "capture_stdout";

    IPC::System::Options::system({shell=>1, log=>1, $capture_key=>\$res}, $cmd);

    if ($?) {
        die "Command '$cmd' failed: " . explain_child_error();
    }

    if ($self->include_command) {
        $res = "% $cmd_for_display\n$res";
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

This document describes version 0.057 of Dist::Zilla::Plugin::InsertCommandOutput (from Perl distribution Dist-Zilla-Plugin-InsertCommandOutput), released on 2022-10-28.

=head1 SYNOPSIS

In F<dist.ini>:

 [InsertCommandOutput]
 ;indent=4
 ;include_command=0
 ;substitute_template=0

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

=head2 include_command

Bool, default false. If set to true, will also show the command in the output.

=head2 capture_stdout

Bool, default true.

=head2 capture_stderr

Bool, default false.

=head2 substitute_template

Bool, default false. If set to true, will substitute some template variables in
the command with their actual values:

=over

=item * [[prog]]

The name of the program (guessed from the current filename, and in the actual
command to execute will be quoted($^X) + " " + quoted(filename)). Empty if
current filename is not a script.

=item * [[module]]

The name of the module (guessed from the current filename). Empty if current
filename is not a module.

=back

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

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
