package Dist::Zilla::App::Command::cover;
use 5.008;
use strict;
use warnings;
# ABSTRACT: Code coverage metrics for your distribution
our $VERSION = '1.101001'; # VERSION

use Dist::Zilla::App -command;


sub abstract { "code coverage metrics for your distribution" }

sub execute {
    my $self = shift;
    require File::Temp;
    require Path::Class;
    require File::chdir;

    local $ENV{HARNESS_PERL_SWITCHES} = '-MDevel::Cover';
    my @cover_command = @ARGV;

    # adapted from the 'test' command
    my $zilla = $self->zilla;
    my $build_root = Path::Class::dir('.build');
    $build_root->mkpath unless -d $build_root;
    my $target = Path::Class::dir(File::Temp::tempdir(DIR => $build_root));
    $self->log("building test distribution under $target");

    # Don't run author and release tests during code coverage.
    # local $ENV{AUTHOR_TESTING}  = 1;
    # local $ENV{RELEASE_TESTING} = 1;

    $zilla->ensure_built_in($target);
    $self->zilla->run_tests_in($target);

    $self->log(join ' ' => @cover_command);
    local $File::chdir::CWD = $target;
    system @cover_command;
    $self->log("leaving $target intact");
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Dist::Zilla::App::Command::cover - Code coverage metrics for your distribution

=head1 VERSION

version 1.101001

=head1 SYNOPSIS

    # dzil cover -outputdir /my/dir

=head1 DESCRIPTION

This is a command plugin for L<Dist::Zilla>. It provides the C<cover> command,
which generates code coverage metrics for your distribution using
L<Devel::Cover>.

If there were any test errors, the C<cover> command won't be run. Author and
release tests are not run since they should not be counted against code
coverage. Any additional command-line arguments are passed to the C<cover>
command.

=for Pod::Coverage abstract execute

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::App::Command::cover/>.

=head1 SOURCE

The development version is on github at L<http://github.com/doherty/Dist-Zilla-App-Command-cover>
and may be cloned from L<git://github.com/doherty/Dist-Zilla-App-Command-cover.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/doherty/Dist-Zilla-App-Command-cover/issues>.

=head1 AUTHORS

=over 4

=item *

Marcel Grünauer <marcel@cpan.org>

=item *

Mike Doherty <doherty@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Marcel Grünauer <marcel@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

