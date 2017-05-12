package FreePAN::SVKMirror;
use FreePAN::Plugin -Base;
our $VERSION = '0.01';
use URI;
use SVK 0.30;
use SVK::XD;

field svk => -init => q{$self->svk_init};

sub svk_init {
    $self->create_repos unless (-d $self->plugin_directory);
    my $xd = SVK::XD->new(depotmap => {'' => $self->plugin_directory});
    return SVK->new(xd=>$xd);
}

sub register {
    my $reg = shift;
    $reg->add(command => 'mirror',
              description => 'Mirror other svn repository to freepan repository');
}

sub create_repos {
    system("svnadmin create --fs-type fsfs ". $self->plugin_directory);
}

sub resolve_remote {
    my @dir = split('/',URI->new(shift||return)->path);
    ($dir[-1]=~/trunk|tag|branch/i)?$dir[-2]:$dir[-1];
}

sub mirror_freepan_repos {
    my ($reponame) = @_;
    my $remote = $self->hub->config->svn_domain_name . "/$reponame";
    $self->svk->mirror("//freepan/$reponame",$remote);
    $self->svk->sync("//freepan/$reponame");
}

sub mirror_remote_repos {
    my ($reponame,$remote) = @_;
    $self->svk->mirror("//mirror/$reponame",$remote);
    $self->svk->sync("//mirror/$reponame");
}

sub handle_mirror {
    my ($repo,$remote,$rename) = @_;
    my $module = $self->resolve_remote($remote);
    $self->mirror_freepan_repos($repo);
    $self->mirror_remote_repos($module,$remote);
    $self->svk->mkdir("//freepan/$repo/$module",
                      -p => -m => "make $module directory");
    $self->svk->smerge(-BI => '--verbatim' => "//mirror/$module","//freepan/$repo/$module");
}

__DATA__

=head1 NAME

FreePAN::SVKMirror - Use SVK to Mirror other repositories

=head1 COPYRIGHT

Copyright 2005 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
