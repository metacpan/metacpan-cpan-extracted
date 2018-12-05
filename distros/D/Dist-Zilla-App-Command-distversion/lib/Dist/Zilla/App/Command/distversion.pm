package Dist::Zilla::App::Command::distversion;
use Capture::Tiny qw/capture capture_stdout/;
use Sort::Naturally qw/nsort/;

use strict;
use warnings;

our $VERSION = '0.03';

use Dist::Zilla::App -command;

sub abstract    { "Prints your dist version on the command line" }
sub description { "Asks dzil what version the dist is on, then prints that" }
sub usage_desc  { "%c" }
sub opt_spec    { (
    [ rc => "Produce a release candidate version" ]
) }
sub execute {
    my $self = shift;
    my $opt = shift;

    # Something might output.
    capture {
        # https://metacpan.org/source/RJBS/Dist-Zilla-6.010/lib/Dist/Zilla/Dist/Builder.pm#L344,348-352
        $_->before_build       for @{ $self->zilla->plugins_with(-BeforeBuild) };
        $_->gather_files       for @{ $self->zilla->plugins_with(-FileGatherer) };
        $_->set_file_encodings for @{ $self->zilla->plugins_with(-EncodingProvider) };
        $_->prune_files        for @{ $self->zilla->plugins_with(-FilePruner) };

        $self->zilla->version;
    };

    my $distver = $self->zilla->version;
    if ($opt->{rc}) {
        # TODO: configure this
        my @tags = split /\n/, capture_stdout { system qw/git tag/ };
        my @relevant = grep /^v$distver/, @tags;

        if (grep /^v$distver$/, @relevant) {
            warn "$distver appears to already have a release tag\n";
        }

        my $currc = 1;
        if (my $latest = (nsort @relevant)[-1]) {
            ($currc) = $latest =~ /-rc(\d+)$/;
            $currc++;
        }
        print "$distver-rc$currc\n";
    }
    else {
        print $distver, "\n";
    }
}

1;

=head1 NAME

Dist::Zilla::App::Command::distversion - report your dist version

=head1 DESCRIPTION

Tries to output the current version of your distribution onto stdout

=head1 SYNOPSIS

    $ dzil distversion
    0.01

    $ dzil distversion --rc
    0.01-rc1

=head1 OPTIONS

=head2 rc

Produce a release candidate version. This is defined as your dist version with
the suffix C<-rcN>, where N is either 1, or 1 more than the previous RC version.

Since dzil doesn't care about the output of this module, nor tracks RC versions
for you, the module currently looks for git tags matching your dist version.
Later, this will be configurable. Any tag matching /^v$distversion-rc(\d+)/ is
considered a release candidate tag, and if none is found, we use 1.

Any tag matching /^v$distversion/ is considered a problem and we emit a warning.
