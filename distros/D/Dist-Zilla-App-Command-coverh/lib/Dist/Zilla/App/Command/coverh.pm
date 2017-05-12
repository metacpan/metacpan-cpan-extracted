use 5.10.1;
use strict;
use warnings;

package Dist::Zilla::App::Command::coverh;

our $VERSION = '0.0100'; # VERSION
# ABSTRACT: Code coverage metrics, with history

use Dist::Zilla::App -command;

sub abstract { 'code coverage metrics, with history' }

sub opt_spec {
    ['history' => 'Show history'],
}

sub execute {
    my $self = shift;
    my $opt = shift;
    my $args = shift;

    require File::chdir;
    require Path::Tiny;
    import Path::Tiny;
    require File::Temp;
    require DateTime;
    require JSON::MaybeXS;

    if($opt->{'history'}) {
        $self->show_history;
    }
    else {
        $self->cover;
    }
}

sub show_history {
    my $self = shift;
    my $json = JSON::MaybeXS->new(pretty => 1);

    my $history_file = path('.coverhistory.json');
    exit if !$history_file->exists;

    my $history = $json->decode($history_file->slurp);
    exit if !scalar @$history;

    printf "%20.20s %-10s %6.6s %6.6s %6.6s %6.6s %6.6s %6.6s\n" =>
          'version',
          'date......',
          '...tot',
          '..stmt',
          '..bran',
          '..cond',
          '...sub',
          '...pod';

    for my $hist (@$history) {
        printf "%20s %10s %5.1f%% %5.1f%% %5.1f%% %5.1f%% %5.1f%% %5.1f%%\n" =>
               $hist->{'version'},
               substr($hist->{'created_at'}, 0, 10),
               $hist->{'total'},
               $hist->{'statement'},
               $hist->{'branch'},
               $hist->{'condition'},
               $hist->{'subroutine'},
               $hist->{'pod'};
    }

}

sub cover {
    my $self = shift;

    my $json = JSON::MaybeXS->new(pretty => 1);
    local $ENV{'HARNESS_PERL_SWITCHES'} = '-MDevel::Cover';

    my @cover_command = qw/cover -report json/;
    my $zilla = $self->zilla;
    my $dist_dir = path('.');
    my $build_dir = $dist_dir->child('.build');
    $build_dir->mkpath if !$build_dir->is_dir;

    my $cover_dir = path(File::Temp::tempdir(DIR => $build_dir));
    $self->log("building distribution for coverage testing in @{[ $cover_dir->stringify ]}");

    $zilla->ensure_built_in($cover_dir);
    $self->zilla->run_tests_in($cover_dir);
    $self->log(join ' ' => @cover_command);

    {
        local $File::chdir::CWD = $cover_dir;
        system @cover_command;
    }
    $self->log("leaving $cover_dir intact");

    my $full_summary = $json->decode($cover_dir->child(qw/cover_db cover.json/)->slurp)->{'summary'}{'Total'};
    my $summary = { map { ($_ => $full_summary->{ $_ }{'percentage'}) } keys %$full_summary };
    $summary->{'created_at'} = DateTime->now->strftime('%Y-%m-%dT%H:%M:%SZ');
    $summary->{'version'} = $zilla->distmeta->{'version'};

    my $log_file = $dist_dir->child('.coverhistory.json');
    if(!$log_file->exists) {
        $log_file->spew($json->encode([]));
    }

    my $log = $json->decode($log_file->slurp);
    if(scalar @$log && $log->[-1]{'version'} eq $summary->{'version'}) {
        $log->[-1] = $summary;
    }
    else {
        push @$log => $summary;
    }
    $log_file->spew($json->encode($log));

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::coverh - Code coverage metrics, with history



=begin HTML

<p><img src="https://img.shields.io/badge/perl-5.10.1+-brightgreen.svg" alt="Requires Perl 5.10.1+" /> <a href="https://travis-ci.org/Csson/p5-Dist-Zilla-App-Command-coverh"><img src="https://api.travis-ci.org/Csson/p5-Dist-Zilla-App-Command-coverh.svg?branch=master" alt="Travis status" /></a> <img src="https://img.shields.io/badge/coverage-19.1%-red.svg" alt="coverage 19.1%" /></p>

=end HTML


=begin markdown

![Requires Perl 5.10.1+](https://img.shields.io/badge/perl-5.10.1+-brightgreen.svg) [![Travis status](https://api.travis-ci.org/Csson/p5-Dist-Zilla-App-Command-coverh.svg?branch=master)](https://travis-ci.org/Csson/p5-Dist-Zilla-App-Command-coverh) ![coverage 19.1%](https://img.shields.io/badge/coverage-19.1%-red.svg)

=end markdown

=head1 VERSION

Version 0.0100, released 2016-01-17.

=head1 SYNOPSIS

    $ dzil coverh
    $ dzil coverh --history

=head1 DESCRIPTION

Dist::Zilla::App::Command::coverh is a command extension for L<Dist::Zilla>. It provides the C<coverh> command, which generates code coverage metrics (in json format)
for the current distribution using L<Devel::Cover>. It appends the summary to a C<.coverhistory.json> file in the distribution root.

Tests must pass for this to work. Author and release tests are not run. No command-line arguments are passed on to
the C<cover> command from L<Devel::Cover>.

=head2 Options

=head3 --history

Prints the contents of the log file:

    version date...... ...tot ..stmt ..bran ..cond ...sub ...pod
     0.0001 2016-01-16  25.8%  22.4%   0.0%   0.0%  66.7% 100.0%
     0.0002 2016-01-17  68.0%  79.8%  23.4%  19.4%  83.0% 100.0%

=head1 NOTE

Depending on which VersionProvider is in use, the version number logged in the log file may or may not correspond to the version number
on cpan (for the same I<version> of the distribution).

Only the latest run of C<coverh> for a certain version number is kept in the log file.

=head1 SEE ALSO

=over 4

=item *

L<Dist::Zilla::App::Command::cover>

=item *

L<Devel::Cover>

=back

=head1 ACKNOWLEDGEMENTS

Some parts where borrowed from L<Dist::Zilla::App::Command::cover>.

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Zilla-App-Command-coverh>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Zilla-App-Command-coverh>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
