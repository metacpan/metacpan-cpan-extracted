package Dist::Zilla::Plugin::DROLSKY::Precious;

use v5.10;

use strict;
use warnings;
use autodie;
use namespace::autoclean;

our $VERSION = '1.23';

use Path::Tiny qw( path );
use Path::Tiny::Rule;
use Sort::ByExample qw( sbe );

use Moose;

has stopwords_file => (
    is        => 'ro',
    isa       => 'Str',
    predicate => '_has_stopwords_file',
);

with qw(
    Dist::Zilla::Role::BeforeBuild
    Dist::Zilla::Role::TextTemplate
);

sub before_build {
    my $self = shift;

    path('precious.toml')->spew_utf8( $self->_precious_toml_content );

    return;
}

sub _precious_toml_content {
    my $self = shift;

    return $self->_new_precious_toml
        unless -e 'precious.toml';

    return $self->_munged_precious_toml;
}

sub _new_precious_toml {
    my $self = shift;

    my $perl_include = ['**/*.{pl,pm,t,psgi}'];
    my %precious     = (
        q{_}                  => { exclude => $self->_default_perl_exclude },
        'commands.perlcritic' => {
            type    => 'lint',
            include => $perl_include,
            cmd => [qw( perlcritic --profile=$PRECIOUS_ROOT/perlcriticrc )],
            ok_exit_codes           => 0,
            lint_failure_exit_codes => 2,
        },
        'commands.perltidy' => {
            type    => 'both',
            include => $perl_include,
            cmd     => [qw( perltidy --profile=$PRECIOUS_ROOT/perltidyrc )],
            lint_flags => [
                '--assert-tidy',
                '--no-standard-output',
                '--outfile=/dev/null'
            ],
            tidy_flags => [
                qw( --backup-and-modify-in-place --backup-file-extension=/ )],
            ok_exit_codes           => 0,
            lint_failure_exit_codes => 2,

            # I think this is really only true for linting mode, but perltidy
            # is so complicated it's hard for me to tell.
            ignore_stderr => 'Begin Error Output Stream',
        },
        'commands.omegasort-gitignore' => {
            type                    => 'both',
            include                 => '**/.gitignore',
            cmd                     => [qw( omegasort --sort=path )],
            lint_flags              => '--check',
            tidy_flags              => '--in-place',
            ok_exit_codes           => 0,
            lint_failure_exit_codes => 1,
        },
        'commands.podchecker' => {
            type          => 'lint',
            include       => ['**/*.{pl,pm,pod}'],
            cmd           => [ 'podchecker', '--warnings', '--warnings' ],
            ok_exit_codes => [ 0, 2 ],
            lint_failure_exit_codes => 1,

            # podchecker will print a warning to stderr if a file has no POD at all.
            ignore_stderr => [
                '.+ pod syntax OK',
                '.+ does not contain any pod commands',
            ]
        },
        'commands.podtidy' => {
            type    => 'tidy',
            include => ['**/*.{pl,pm,pod}'],
            cmd     =>
                [ 'podtidy', '--columns', '80', '--inplace', '--nobackup' ],
            ok_exit_codes           => 0,
            lint_failure_exit_codes => 1,
        },
    );

    if ( $self->_has_stopwords_file ) {
        $precious{'commands.omegasort-stopwords'} = {
            type          => 'both',
            include       => $self->stopwords_file,
            cmd           => [qw( omegasort --sort=text --case-insensitive )],
            lint_flags    => '--check',
            tidy_flags    => '--in-place',
            ok_exit_codes => 0,
            lint_failure_exit_codes => 1,
        };
    }

    return $self->_config_to_toml( \%precious );
}

sub _munged_precious_toml {
    my $self = shift;

    return path('precious.toml')->slurp_utf8;
}

sub _default_perl_exclude {
    my $self = shift;

    my @exclude = qw(
        .build/**/*
        blib/**/*
        t/00-*
        t/author-*
        t/release-*
        t/zzz-*
        xt/**/*
    );

    my $dist = $self->zilla->name;
    push @exclude, "$dist-*/**/*";

    if ( grep { $_->plugin_name =~ /\bConflicts/ }
        @{ $self->zilla->plugins } ) {

        my $conflicts_dir = $self->zilla->name =~ s{-}{/}gr;
        push @exclude, "lib/$conflicts_dir/Conflicts.pm";
    }

    return [ sort @exclude ];
}

my @key_order = qw(
    type
    include
    exclude
    cmd
    lint_flags
    tidy_flags
    ok_exit_codes
    lint_failure_exit_codes
);

my %unquoted_keys = map { $_ => 1 } qw(
    chdir
    lint_failure_exit_codes
    ok_exit_codes
);

sub _config_to_toml {
    my $self     = shift;
    my $precious = shift;

    my $sorter = sbe(
        \@key_order,
        {
            fallback => sub { $_[0] cmp $_[1] },
        },
    );

    my $toml = q{};
    for my $section ( q{_}, sort grep { $_ ne q{_} } keys %{$precious} ) {
        next unless keys %{ $precious->{$section} };

        if ( $section ne q{_} ) {
            $toml .= "[$section]\n";
        }

        for my $key ( $sorter->( keys %{ $precious->{$section} } ) ) {
            my $val   = $precious->{$section}{$key};
            my $quote = $unquoted_keys{$key} ? sub { $_[0] } : \&_quote;
            if ( ref $val ) {
                my @vals     = map { $quote->($_) } @{$val};
                my $one_line = join ', ', @vals;
                if ( length $one_line > 70 ) {
                    $toml .= "$key = [\n";
                    $toml .= "    $_,\n" for @vals;
                    $toml .= "]\n";
                }
                else {
                    $toml .= "$key = [ $one_line ]\n";
                }
            }
            else {
                $val = $quote->($val);
                $toml .= "$key = $val\n";
            }
        }

        $toml .= "\n";
    }

    chomp $toml;

    return $toml;
}

sub _quote {
    return qq{"$_[0]"};
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Creates a default precious.toml file if it doesn't yet exist

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::DROLSKY::Precious - Creates a default precious.toml file if it doesn't yet exist

=head1 VERSION

version 1.23

=for Pod::Coverage .*

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/autarch/Dist-Zilla-PluginBundle-DROLSKY/issues>.

=head1 SOURCE

The source code repository for Dist-Zilla-PluginBundle-DROLSKY can be found at L<https://github.com/autarch/Dist-Zilla-PluginBundle-DROLSKY>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 - 2025 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
