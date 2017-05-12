package Dist::Zilla::Plugin::TidyAll;

use Moose;

our $VERSION = '0.04';

use Cwd qw(realpath);
use Code::TidyAll;
with qw(
  Dist::Zilla::Role::FileMunger
  Dist::Zilla::Role::PrereqSource
);

has 'mode'        => ( is => 'ro', default    => 'dzil' );
has 'tidyall'     => ( is => 'ro', init_arg   => undef, lazy_build => 1 );
has 'tidyall_ini' => ( is => 'ro', lazy_build => 1 );

sub _build_tidyall_ini {
    my ($self) = @_;

    my $root_dir = realpath( $self->zilla->root->stringify );
    return "$root_dir/tidyall.ini";
}

sub _build_tidyall {
    my ($self) = @_;

    return Code::TidyAll->new_from_conf_file(
        $self->tidyall_ini,
        mode       => $self->mode,
        no_cache   => 1,
        no_backups => 1
    );
}

sub register_prereqs {
    my ($self) = @_;

    $self->zilla->register_prereqs(
        {
            type  => 'requires',
            phase => 'develop',
        },
        'Code::TidyAll' => '0',
    );

    return;
}

sub munge_file {
    my ( $self, $file ) = @_;

    return if ref($file) eq 'Dist::Zilla::File::FromCode';

    my $source = $file->content;
    my $path   = $file->name;
    my $result = $self->tidyall->process_source( $source, $path );
    if ( $result->error ) {
        die $result->error . "\n";
    }
    elsif ( $result->state eq 'tidied' ) {
        my $destination = $result->new_contents;
        $file->content($destination);
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__


=pod

=head1 NAME

Dist::Zilla::Plugin::TidyAll - Apply tidyall to files in Dist::Zilla

=head1 SYNOPSIS

    # dist.ini
    [TidyAll]

    # or
    [TidyAll]
    tidyall_ini = /path/to/tidyall.ini

=head1 DESCRIPTION

Processes each file with L<tidyall|tidyall>, via the
L<Dist::Zilla::Role::FileMunger|Dist::Zilla::Role::FileMunger> role.

You may specify the path to the tidyall.ini; otherwise it is expected to be in
the dzil root (same as dist.ini).

=head1 SEE ALSO

L<tidyall|tidyall>

