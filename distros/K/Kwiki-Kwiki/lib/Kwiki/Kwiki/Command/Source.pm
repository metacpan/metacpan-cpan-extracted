package Kwiki::Kwiki::Command::Source;
use strict;
use base 'Kwiki::Kwiki::Command';
use File::Path qw(rmtree);
use File::Spec::Functions qw(catfile catdir);
use File::Find;

sub process {
    my $self = shift;
    my $list = $self->read_list;
    $self->process_svn($list->{svn}{list});
    $self->process_local($list->{local}{list});
    $self->process_inc($list->{inc}{list});
}

sub process_svn {
    my $self = shift;
    my $svn_list = shift || return;
    for my $url (@$svn_list) {
        $url =~ s/\/$//;
        my ($dir) = ($url =~ /^.*\/(.*)/);
        my $path = catfile($self->{ROOT}, qw(src svn), $dir);
        if (-e $path) {
            if (not(-e catfile($path, ".svn") and
                        `svn info $path` =~ /^URL: \Q$url\E$/m)) {
                warn "Deleting out of date path: $path\n";
                rmtree $path;
            }
        }
        if (-e $path) {
            $self->system_command("svn up $path");
        } else {
            $self->system_command("svn co $url $path");
        }
    }
}

sub process_local {
    my $self = shift;
    my $local_list = shift || return;

    my @files;
    my $wanted = sub {
        my ($dev,$ino,$mode,$nlink,$uid,$gid);
        ($dev,$ino,$mode,$nlink,$uid,$gid) = lstat($_)
            && -f _ && /^.*\.pm\z/s
            && push @files, $File::Find::name;
    };

    for my $dir (map { catdir($_, "lib") } @$local_list) {
        next unless -d $dir;
        find({wanted => $wanted}, $dir);
        for (@files) {
            my $new_path = $_;
            $new_path =~ s/^$dir/catfile($self->{ROOT},qw(src local lib))/e;
            $self->assert_copy($_, $new_path);
        }
    }
}

sub process_inc {
    my $self = shift;
    my $pm_list = shift || return;
    my %pm_files;

    for my $pm (@$pm_list) {
        for my $inc (@INC) {
            my $pm_file = catfile($inc, $pm);
            if (-f $pm_file) {
                $pm_files{$pm} = $pm_file;
                last;
            }
        }
    }

    for (keys %pm_files) {
        my $new_path = catfile($self->{ROOT},qw(src inc lib), $_);
        $self->assert_copy($pm_files{$_}, $new_path);
    }

}

1;

__END__

=head1 NAME

Kwiki::Kwiki::Command::Source - Methods that pulling sources down.

=head1 DESCRIPTION

See L<Kwiki::Kwiki> for all documentation.

=head1 COPYRIGHT

Copyright 2006 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>
