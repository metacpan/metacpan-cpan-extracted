package Giovanni::Plugins::Git;

use Mouse::Role;
use Git::Repository;

has 'git' => (
    is      => 'rw',
    isa     => 'Git::Repository',
    lazy    => 1,
    default => sub { Git::Repository->new(work_tree => $_[0]->repo) },
);

sub tag {
    my $self = shift;

    my $tag = 'v' . time;
    my $log =
        $self->git->run(tag => '-a', $tag, '-m', "tagging to $tag for rollout");
    $self->log('git', "Tag: [$tag] " . $log) if $self->is_debug;
    $log = $self->git->run('pull') unless $self->is_debug;
    $self->log('git', "Pull: " . $log) if $self->is_debug;
    $log = $self->git->run(push => 'origin', '--tags') unless $self->is_debug;
    $self->log('git', "Push: " . $log) if $self->is_debug;
    $self->version($tag);
    $self->log('git', $log);

    return $tag;
}

sub get_last_tag {
    my ($self, $n) = @_;

    $n = 1 unless $n;
    my @tags = $self->git->run('tag');
    $self->log('git', "Tags: " . join(', ', @tags) . $/) if $self->is_debug;

    return splice(@tags, $n - 1, $n);
}

around 'update_cache' => sub {
    my ($orig, $self, $ssh, $conf) = @_;

    my $log;
    my $cache_dir = $self->_get_cache_dir($conf);

    if ($cache_dir) {
        if ($ssh->test("[ -d " . $cache_dir . "/.git ]")) {
            $log .= $ssh->capture("cd $cache_dir && git pull");
            $self->log("running git pull ...");
        }
        else {
            $log = $ssh->capture("mkdir -p " . $cache_dir)
                unless $ssh->test("[ -d " . $cache_dir . " ]");
            $log .= $ssh->capture("cd ". $cache_dir
                . "&& git clone " . $self->config->{repo} . " .");
            $self->log("running git clone ...");
        }
    }
    $self->log($ssh, $log);

    return;
};

around 'checkout' => sub {
    my ($orig, $self, $ssh, $conf) = @_;

    my $log;
    my $cache_dir = $self->_get_cache_dir($conf);
    if ($self->config->{deploy_dir}) {
        $log .=
            $ssh->capture("cd "
                . $self->config->{deploy_dir}
                . " && git clone --depth 1 --no-hardlinks file://"
                . $cache_dir
                . " .");
    }
    $self->log($ssh, $log);
};

sub _get_cache_dir {
    my ($self, $conf) = @_;
    if($self->config->{cache}){
        my @parts = split(/\//, $self->config->{repo});
        my $git_dir = pop(@parts);
        return join('/', $self->config->{cache}, $git_dir);
    } else {
        return $self->config->{root};
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Giovanni::Plugins::Git

=head1 VERSION

version 1.12

=head1 AUTHOR

Lenz Gschwendtner <mail@norbu09.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by ideegeo Group Limited.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
