## no critic (RequireUseStrict)
package Dist::Zilla::Plugin::Test::LocalBrew;
$Dist::Zilla::Plugin::Test::LocalBrew::VERSION = '0.08';
use File::Spec;
use File::Temp qw(tempdir);

use namespace::clean;

## use critic (RequireUseStrict)
use Moose;
with 'Dist::Zilla::Role::FileGatherer', 'Dist::Zilla::Role::TextTemplate';

has brews => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

has notest_deps => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has nobrew => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

sub should_test_deps {
    my ( $self ) = @_;

    return !$self->notest_deps;
}

sub mvp_multivalue_args {
    qw/brews/
}

my $template = <<'TEMPLATE';
#!perl

use strict;
use warnings;

use FindBin;
use File::Copy qw(copy);
use File::Spec;
use File::Temp;
use Test::More;

sub copy_log_file {
    my ( $home ) = @_;
    my $log_file = File::Spec->catfile($home, '.cpanm', 'build.log');
    my $tempfile = File::Temp->new(
        SUFFIX => '.log',
        UNLINK => 0,
    );
    copy($log_file, $tempfile->filename);
    diag("For details, please consult $tempfile")
}

sub is_dist_root {
    my ( @path ) = @_;

    return -e File::Spec->catfile(@path, 'Makefile.PL') ||
           -e File::Spec->catfile(@path, 'Build.PL');
}

delete @ENV{qw/AUTHOR_TESTING RELEASE_TESTING PERL5LIB/};

unless($ENV{'PERLBREW_ROOT'}) {
    plan skip_all => "Environment variable 'PERLBREW_ROOT' not found";
    exit;
}

my $brew = q[{{$brew || ''}}];

my $cpanm_path = qx(which cpanm 2>/dev/null);
unless($cpanm_path) {
    plan skip_all => "The 'cpanm' program is required to run this test";
    exit;
}
chomp $cpanm_path;

my $perlbrew_bin = File::Spec->catdir($ENV{'PERLBREW_ROOT'}, 'perls',
    $brew, 'bin');

my $perlbrew_path = $ENV{'PATH'};
if(my $local_lib_root = $ENV{'PERL_LOCAL_LIB_ROOT'}) {
    my @path = File::Spec->path;

    while(@path && $path[0] =~ /^$local_lib_root/) {
        shift @path;
    }

    if($^O eq 'MSWin32') {
        $perlbrew_path = join(';', @path);
    } else {
        $perlbrew_path = join(':', @path);
    }
}

my ( $env, $status ) = do {
    local $ENV{'PATH'} = $perlbrew_path;
    local $ENV{'SHELL'} = '/bin/bash'; # fool perlbrew
    ( scalar(qx(perlbrew env $brew)), $? )
};

unless($status == 0) {
    plan skip_all => "No such perlbrew environment '$brew'";
    exit;
}

my @lines = split /\n/, $env;

foreach my $line (@lines) {
    if($line =~ /^\s*export\s+([0-9a-zA-Z_]+)=(.*)$/) {
        my ( $k, $v ) = ( $1, $2 );
        if($v =~ /^("|')(.*)\1$/) {
            $v = $2;
            $v =~ s!\\(.)!$1!ge;
        }
        $ENV{$k} = $v;
    } elsif($line =~ /^unset\s+([0-9a-zA-Z_]+)/) {
        delete $ENV{$1};
    }
}

my $pristine_path = do {
    local $ENV{'PATH'} = $perlbrew_path;
    qx(perlbrew display-pristine-path);
};
chomp $pristine_path;
$ENV{'PATH'} = join(':', $ENV{'PERLBREW_PATH'}, $pristine_path);

plan tests => 1;

my $tmpdir  = File::Temp->newdir;
my $tmphome = File::Temp->newdir;

my $pid = fork;
if(!defined $pid) {
    fail "Forking failed!";
    exit 1;
} elsif($pid) {
    waitpid $pid, 0;
    ok !$?, "cpanm should successfully install your dist with no issues" or copy_log_file($tmphome->dirname);
} else {
    open STDIN, '<', File::Spec->devnull;
    open STDOUT, '>', File::Spec->devnull;
    open STDERR, '>', File::Spec->devnull;

    my @path = File::Spec->splitdir($FindBin::Bin);

    while(@path && !is_dist_root(@path)) {
        pop @path;
    }
    unless(@path) {
        die "Unable to find dist root\n";
    }
    chdir File::Spec->catdir(@path); # exit test directory

    # override where cpanm puts its log file
    $ENV{'HOME'} = $tmphome->dirname;

{{
        unless($should_test_deps) {
            return <<'END_PERL';
    system 'perl', $cpanm_path, '--notest', '--installdeps', '-L', $tmpdir->dirname, '.';
    if($?) {
        exit($? >> 8);
    }
END_PERL
        }
        return '';
}}

    # We use system here instead of exec so that $tmpdir gets cleaned up
    # after cpanm finishes
    system 'perl', $cpanm_path, '-L', $tmpdir->dirname, '.';
    exit($? >> 8);
}
TEMPLATE

sub gather_files {
    my ( $self ) = @_;

    my $brews = $self->brews;

    unless(@$brews) {
        $self->log_fatal('No perlbrew environments specified in your dist.ini');
    }

    foreach my $brew (@$brews) {
        $self->add_file(Dist::Zilla::File::InMemory->new(
            name    => "xt/release/localbrew-$brew.t",
            content => $self->fill_in_string($template, {
                brew             => $brew,
                should_test_deps => $self->should_test_deps,
            }),
        ));
    }

    if($self->nobrew) {
        $self->add_file(Dist::Zilla::File::InMemory->new(
            name    => "xt/release/system-localbrew.t",
            content => $self->fill_in_string($template, {
                brew             => undef,
                should_test_deps => $self->should_test_deps,
            }),
        ));
    }
}

no Moose;
1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Test::LocalBrew - Verify that your distribution tests well in a fresh perlbrew

=head1 VERSION

version 0.08

=head1 SYNOPSIS

  # in your dist.ini
  [Test::LocalBrew]
  brews = first-perlbrew
  brews = second-perlbrew

=head1 DESCRIPTION

This plugin adds a release test for your module that tests it against a set
of given perlbrew environments.  Any dependencies are installed via cpanminus
into a temporary local lib, so your perlbrew environments aren't altered.
This comes in handy when you want to build against a set of "fresh" Perl
installations (ie. those with only core modules) to make sure all of your
prerequisites are included correctly.

=head1 ATTRIBUTES

=head2 brews

A list of perlbrew environments to build and test in.

=head2 notest_deps

If this flag is set, don't test dependency modules.

=head2 nobrew

If this flag is set, test against the system perl as well.

=head1 ISSUES

=over

=item Relies on the 'which' program to detect cpanm.

=back

=head1 SEE ALSO

L<Dist::Zilla>, L<App::perlbrew>, L<App::cpanminus>, L<local::lib>

=begin comment

=over

=item mvp_multivalue_args

=item gather_files

=item should_test_deps

=back

=end comment

=head1 AUTHOR

Rob Hoelz <rob@hoelz.ro>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Rob Hoelz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/hoelzro/dist-zilla-plugin-test-localbrew/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__END__

# ABSTRACT: Verify that your distribution tests well in a fresh perlbrew

