package Dist::Dzpl::Plugin::Prune;

use Moose;
with qw/ Dist::Zilla::Role::FilePruner /;

has pruner => qw/ is ro lazy_build 1 isa CodeRef /;
sub _build_pruner { die "Missing pruner" }

sub prune_files {
    my $self = shift;

    my $prune = $self->pruner;
    my $files = $self->zilla->files;
    @$files = grep {
        my $file = $_;
        local $_ = $file->name;
        if ( $prune->( $file ) ) {
            $self->log_debug([ 'pruning %s', $file->name ]);
            0;
        }
        else {
            1;
        }
    } @$files;

    return;

}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
