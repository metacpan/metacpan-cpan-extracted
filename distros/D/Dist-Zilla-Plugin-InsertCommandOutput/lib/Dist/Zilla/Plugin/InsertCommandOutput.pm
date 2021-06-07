package Dist::Zilla::Plugin::InsertCommandOutput;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-21'; # DATE
our $DIST = 'Dist-Zilla-Plugin-InsertCommandOutput'; # DIST
our $VERSION = '0.054'; # VERSION

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

has make_verbatim => (is => 'rw', default => sub{1});

use namespace::autoclean;

sub munge_files {
    my $self = shift;

    $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
    my ($self, $file) = @_;
    my $content_as_bytes = $file->encoded_content;
    if ($content_as_bytes =~ s{^#\s*COMMAND:\s*(.*)\s*(\R|\z)}{
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

    $res =~ s/^/ /gm if $self->make_verbatim;
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

This document describes version 0.054 of Dist::Zilla::Plugin::InsertCommandOutput (from Perl distribution Dist-Zilla-Plugin-InsertCommandOutput), released on 2021-05-21.

=head1 SYNOPSIS

In dist.ini:

 [InsertCommandOutput]
 ;make_verbatim=1

In your POD:

 # COMMAND: netstat -anp

=head1 DESCRIPTION

This module finds C<# COMMAND: ...> directives in your POD, pass it to the
Perl's backtick operator, and insert the result into your POD as a verbatim
paragraph (unless if you set C<make_verbatim> to 0, in which case output will be
inserted as-is). If command fails (C<$?> is non-zero), build will be aborted.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-InsertCommandOutput>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-InsertCommandOutput>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-InsertCommandOutput/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Dist::Zilla::Plugin::InsertCodeResult>, which can also be used to accomplish
the same thing, e.g. with C<# CODE: my $res = `netstat -anp`; die if $?; $res>
except the DZP::InstallCommandResult plugin is shorter.

L<Dist::Zilla::Plugin::InsertCodeOutput>, which can also be used to accomplish
the same thing, e.g. with C<# CODE: system "netstat -anp"; die if $?>.

L<Dist::Zilla::Plugin::InsertExample>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2019, 2018, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
