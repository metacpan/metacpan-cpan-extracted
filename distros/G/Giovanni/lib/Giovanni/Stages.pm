package Giovanni::Stages;

use Mouse;
use Expect;
use Data::Dumper;

# Stages are defined here and expected to be overridden with plugins.
# the idea is to have different plugins that can extend the existing
# stages real easy. If this stages approach turns out to be too limited
# (ie 1000s of stages in one file, not a good look) we may need to
# rethink this approach.

sub update_cache {
    my ($self, $ssh) = @_;
    $self->log($ssh, "running update_cache task ...");
    return;
}

sub rollout {
    my ($self, $ssh) = @_;

    $self->log($ssh, "running rollout task ...");
    $self->config->{deploy_dir} = $self->config->{root};
    my $log = $ssh->capture("mkdir -p " . $self->config->{deploy_dir});
    $self->log($ssh, $log);
    $self->checkout($ssh);
    $self->post_rollout($ssh);

    return;
}

sub rollout_timestamped {
    my ($self, $ssh) = @_;

    $self->log($ssh, "running rollout_timestamped task ...");
    my $deploy_dir = join('/', $self->config->{root}, 'releases', time);
    my $current = join('/', $self->config->{root}, 'current');
    my $log = $ssh->capture("mkdir -p " . $deploy_dir);
    $self->config->{deploy_dir} = $deploy_dir;
    $self->checkout($ssh);
    $log .= $ssh->capture(
        "unlink " . $current . "; ln -s " . $deploy_dir . " " . $current);
    $self->log($ssh, $log);
    $self->post_rollout($ssh);

    return;
}

sub rollback_timestamped {
    my ($self, $ssh, $offset) = @_;

    $self->log($ssh, "running rollback task ...");
    my $deploy_dir = join('/', $self->config->{root}, 'releases');
    my $current    = join('/', $self->config->{root}, 'current');
    my @rels = $ssh->capture("ls -1 " . $deploy_dir);
    @rels = sort(@rels);
    my $link = $ssh->capture("ls -l " . $current . " | sed 's/^.*->\\s*//'");
    my @path = split(/\//, $link);
    my $current_rel = pop(@path);
    my (@past, @future);

    foreach my $rel (@rels) {
        chomp($rel);
        next unless $rel =~ m{^\w};
        if ($rel == $current_rel) {
            push(@future, $rel);
            next;
        }
        if (@future) {
            push(@future, $rel);
        }
        else {
            push(@past, $rel);
        }
    }
    $deploy_dir = join('/', $self->config->{root}, 'releases', pop(@past));
    my $log = $ssh->capture(
        "unlink " . $current . "; ln -s " . $deploy_dir . " " . $current);
    $self->log($ssh, $log);
    return;
}

sub rollback_scm {
    my ($self, $ssh, $offset) = @_;

    # load SCM plugin
    $self->load_plugin($self->scm);
    my $tag = $self->get_last_tag($offset);
    $self->log($ssh, "Rolling back to tag: $tag") if $self->is_debug;

    # TODO change checkout to accept an optional tag so we can reuse it
    # here to check out an old version.

    return;
}

sub restart {
    my ($self, $ssh) = @_;

    $self->log("running restart task ...");
    my $log = $ssh->capture($self->config->{init});
    $self->log($ssh, $log);
    return;
}

sub checkout {
    my ($self, $ssh) = @_;
    $self->log($ssh, "running checkout task ...");
    return;
}

sub cleanup_timestamped {
    my ($self, $ssh, $offset) = @_;

    $self->log($ssh, "running cleanup task ...");

    if ($self->config->{root} =~ m{^.*/\d+$}) {
        my @path = split(/\//, $self->config->{root});
        pop(@path);
        pop(@path);
        $self->config->{root} = join('/', @path);
    }

    my $deploy_dir = join('/', $self->config->{root}, 'releases');
    my $current    = join('/', $self->config->{root}, 'current');
    my @rels = $ssh->capture("ls -1 " . $deploy_dir);
    @rels = sort(@rels);
    my $link = $ssh->capture("ls -l " . $current . " | sed 's/^.*->\\s*//'");
    my @path = split(/\//, $link);
    my $current_rel = pop(@path);
    my (@past, @future);

    foreach my $rel (@rels) {
        chomp($rel);
        next unless $rel =~ m{^\w};
        if ($rel == $current_rel) {
            push(@future, $rel);
            next;
        }
        if (@future) {
            push(@future, $rel);
        }
        else {
            push(@past, $rel);
        }
    }
    $deploy_dir = join('/', $self->config->{root}, pop(@past));
    my $num = $self->config->{keep_versions} || 5;
    my $log;
    while ($#past > ($num)) {
        my $to_del = join('/', $self->config->{root}, 'releases', shift(@past));
        $self->log($ssh, "deleting $to_del");
        $log = $ssh->capture("rm -rf " . $to_del);
    }
    $self->log($ssh, $log);

    return;
}

sub restart_phased {
    my ($self, $ssh) = @_;

    $self->log($ssh, "running restart_phased task ...");
    unless ($ssh->test($self->_init_command('restart'))) {
        $self->log(
            'restart failed: ' . $ssh->error . ' trying stop -> start instead');
        $ssh->test($self->_init_command('stop'));

        # give time to exit
        sleep 2;
        $ssh->test($self->_init_command('start'))
            or $self->error('restart failed: ' . $ssh->error);
        return;
    }

    # my $exp = Expect->init($pty);
    # $exp->interact();
    $self->log(
        $ssh,
        'restarted '
            . (
              $self->config->{systemd}
            ? $self->config->{systemd}
            : $self->config->{init}));

    return;
}

sub reload_phased {
    my ($self, $ssh) = @_;

    $self->log($ssh, "running reload_phased task ...");
    unless ($ssh->test($self->_init_command('restart'))) {
        $self->log(
            'reload failed: ' . $ssh->error . ' trying stop -> start instead');
        $ssh->test($self->_init_command("stop"));

        # give time to exit
        sleep 2;
        $ssh->test($self->_init_command("start"))
            or $self->error('restart failed: ' . $ssh->error);
        return;
    }

    # my $exp = Expect->init($pty);
    # $exp->interact();
    $self->log(
        $ssh,
        'restarted '
            . (
              $self->config->{systemd}
            ? $self->config->{systemd}
            : $self->config->{init}));

    return;
}

sub send_notify {
    my ($self, $ssh) = @_;
    $self->log($ssh, "running send_notify task ...");
    return;
}

sub post_rollout {
    my ($self, $ssh) = @_;

    return
        unless (exists $self->config->{post_rollout}
        and defined $self->config->{post_rollout});

    $self->log($ssh,
              'running post_rollout script "'
            . $self->config->{post_rollout}
            . '" ...');
    unless (
        $ssh->test(
                  'cd '
                . $self->config->{deploy_dir} . ' && '
                . $self->config->{post_rollout}))
    {
        $self->error("post_rollout script failed: " . $ssh->error);
    }
    return;
}

sub _init_command {
    my ($self, $command) = @_;

    if (defined $self->config->{systemd}) {
        return "sudo systemctl $command " . $self->config->{systemd} . ".service";
    }
    else {
        return "sudo " . $self->config->{init} . " $command";
    }
    return;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Giovanni::Stages

=head1 VERSION

version 1.12

=head1 AUTHOR

Lenz Gschwendtner <mail@norbu09.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by ideegeo Group Limited.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
