package Dist::Zilla::Plugin::Git::RequireUnixEOL;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.001';

use Moose;
with 'Dist::Zilla::Role::BeforeBuild';

use Carp;
use Git::Background 0.003;
use Path::Tiny;

use namespace::autoclean;

sub mvp_multivalue_args { return (qw( ignore )) }

has _git => (
    is      => 'ro',
    isa     => 'Git::Background',
    lazy    => 1,
    default => sub { Git::Background->new( path( shift->zilla->root )->absolute ) },
);

has ignore => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef]',
    default => sub { [] },
);

sub before_build {
    my ($self) = @_;

    my %ignored_file = map  { $_ => 1 } @{ $self->ignore };
    my @files        = grep { !exists $ignored_file{$_} } $self->_git_ls_files();
    return if !@files;

    my @errors;
  FILE:
    for my $file (@files) {
        open my $fh, '<', $file or croak "Could not open $file: $!";

        # On Windows default is :crlf, which hides \r\n
        binmode $fh, ':raw' or croak "binmode failed: $!";

        my $windows_line_ending_found = 0;
        my $line_no                   = 0;
      LINE:
        while ( my $line = <$fh> ) {
            $line_no++;

            if ( ( $windows_line_ending_found == 0 ) and ( $line =~ m{\r$}xsm ) ) {
                $windows_line_ending_found = 1;
                push @errors, "File $file uses Windows EOL (found on line $line_no)";
            }

            if ( $line =~ m{[ \t]+\r?\n$}xsm ) {
                push @errors, "File $file has trailing whitespace on line $line_no";
            }
        }

        close $fh or croak "Could not read $file: $!";
    }

    if (@errors) {
        $self->log_fatal( join "\n", q{-} x 60, @errors );
    }

    return;
}

sub _git_ls_files {
    my ($self) = @_;

    my $git = $self->_git;

    my $files_f = $git->run('ls-files')->await;

    $self->log_fatal( scalar $files_f->failure ) if $files_f->is_failed;

    my @files = $files_f->stdout;
    return @files;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Git::RequireUnixEOL - enforce the correct line endings in your Git repository with Dist::Zilla

=head1 VERSION

Version 1.001

=head1 SYNOPSIS

  # in dist.ini:
  [Git::RequireUnixEOL]

=head1 DESCRIPTION

This plugin checks that all the files in the Git repository where your
project is saved use Unix line endings and have no whitespace at the end of
a line. Files not in the Git index are ignored. You can ignore additional
files with the C<ignore> option in F<dist.ini>.

The plugin runs in the before build phase and aborts the build if a violation
is found.

The plugin should ensure that you always commit your files with the correct
line endings and without superfluous whitespace.

This plugin checks the files in your repository. To check your build you can
use a test based on L<Test::EOL|Test::EOL>.

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/Dist-Zilla-Plugin-Git-RequireUnixEOL/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/Dist-Zilla-Plugin-Git-RequireUnixEOL>

  git clone https://github.com/skirmess/Dist-Zilla-Plugin-Git-RequireUnixEOL.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2022 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=head1 SEE ALSO

L<Dist::Zilla::Plugin::Git::FilePermissions|Dist::Zilla::Plugin::Git::FilePermissions>,
L<Test::EOL|Test::EOL>

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
