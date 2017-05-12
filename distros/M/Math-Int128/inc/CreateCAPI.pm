package inc::CreateCAPI;

use strict;
use warnings;
use autodie;

use Dist::Zilla::File::InMemory;

use Moose;

with 'Dist::Zilla::Role::FileGatherer',
    'Dist::Zilla::Role::FileInjector';

sub gather_files {
    my $self = shift;

    my @cmd = (
        'make_perl_module_c_api',
        'module_name=' . ( $self->zilla->name =~ s/-/::/gr ),
        'module_version=' . $self->zilla->version,
        q{author="} . ( join ', ', @{ $self->zilla->authors } ) . q{"},
    );

    $self->log( ["Running @cmd"] );

    system(@cmd) and die "Could not run @cmd";

    $self->_add_and_clean_file($_) for qw(
        c_api.h
        c_api_client/perl_math_int128.c
        c_api_client/perl_math_int128.h
        c_api_client/sample.xs
    );

    return;
}

sub _add_and_clean_file {
    my $self = shift;
    my $file = shift;

    open my $fh, '<', $file;
    my $content = do { local $/; <$fh> };
    close $fh;

    $self->add_file(
        Dist::Zilla::File::InMemory->new(
            name     => $file,
            content  => $content,
            added_by => [__PACKAGE__],
        )
    );

    unlink $file;

    return;
}

1;
