package Kwiki::Kwiki::Command::Lib;
use strict;
use base 'Kwiki::Kwiki::Command';
use Cwd qw(cwd);
use File::Copy;
use File::Path qw(mkpath);
use File::Copy::Recursive qw(dircopy rcopy);
use File::Spec::Functions qw(splitdir catfile catdir);
use IO::All;
use CPAN;
use CPAN::Config;

sub process {
    my $self = shift;
        my $class = shift;
    my $list = $self->read_list();
    my $svn_list = $list->{svn}{list};

    my $top = cwd();
    chdir($self->{ROOT}) or die "Could not chdir to the '$self->{ROOT}' directory";

    my @sources;
    for my $url (@$svn_list) {
        $url =~ s/\/$//;
        my ($dir) = ($url =~ /^.*\/(.*)/);
        my $path = catfile("src","svn",$dir);
        push @sources, $path;
    }
    push @sources, catdir("src","local");
    push @sources, catdir("src","inc");

    my %path_map;

    my $home = cwd();
    for my $dir (@sources) {
        next unless -d $dir and -r $dir;
        chdir $dir or die "Couldn't chdir to $dir";

        for my $path (
            #            `find lib -type f | grep '\\.pm\$'`
            sub {
                my @files;
                File::Find::find({
                    wanted => sub {
                        my ($dev,$ino,$mode,$nlink,$uid,$gid);
                        (($dev,$ino,$mode,$nlink,$uid,$gid) = lstat($_))
                          && -f _
                          && $File::Find::name =~ m/.pm$/
                          && push @files, $File::Find::name;
                    }}, 'lib');
                return @files
            }->()
        ) {
            chomp $path;
            $path_map{$path} =
              join('/', ('..') x ((split '/', $path) - 1)) . "/$dir/$path";
        }
        chdir $home or die "Couldn't chdir back to $home";
    }

    for my $src_path (keys %path_map) {
        my $target_path = $path_map{$src_path};
        my ($rel_dir) = ($src_path =~ /(.*)\/\w+\.pm$/)
            or die "Can't find directory component for $src_path";
        mkpath($rel_dir) unless -e $rel_dir;
        unlink $src_path;       # if -l $src_path;
        symlink($target_path, $src_path)
            or die "Can't create symlink from $src_path to $target_path\n";
    }
    chdir $top or die "Couldn't chdir back to $top";
    $File::Copy::Recursive::CopyLink = 0;
    rcopy("$self->{ROOT}/lib", "lib");
    $self->process_cpan;
}

sub process_cpan {
    my $self = shift;
    my $path = cwd();

    my $list = $self->read_list();
    my $cpan_list = $list->{cpan}{list} || [];

    # plugins
    my $plugins = io('plugins');
    die("This does not seem to a kwiki directory\n") unless $plugins->exists;

    mkdir "$path/.cpan";
    mkdir "$path/.cpan/build";
    my @modules =
        ( @{$cpan_list},
          grep { !/^ #/ && !/^\s*$/ }
          $plugins->chomp->getlines);
    print join"\n",@modules,"\n";

    $CPAN::Config->{build_dir} = "$path/.cpan/build";
    $CPAN::Config->{cpan_home} = "$path/.cpan/build";
    $CPAN::Config->{histfile} = "$path/.cpan/histfile;";
    $CPAN::Config->{keep_source_where} = "$path/.cpan/sources";
    $CPAN::Config->{prerequisites_policy} = "follow";

    my @objs = map { CPAN::Shell->expand('Module',$_) } @modules;
    for my $i (0..$#objs) {
        delete $objs[$i] if grep { $_->{RO}->{CPAN_FILE} eq $objs[$i]->{RO}->{CPAN_FILE} } @objs[$i+1..$#objs];
    }

    # Install to local
    $CPAN::Config->{makepl_arg} = "PREFIX=$path PERL5LIB=$path/lib LIB=$path/lib INSTALLMAN1DIR=$path/man/man1 INSTALLMAN3DIR=$path/man/man3 INSTALLBIN=$path/bin INSTALLSCRIPT=$path/bin";
    $CPAN::Config->{make_install_arg} =~ s/UNINST=1//;
    for (grep { defined $_ } @objs) {
        $_->{force_update} = 1;
        $_->install;
    }
    # CPAN chdir into module dir.
    chdir($path);
}

1;

__END__

=head1 NAME

Kwiki::Kwiki::Command::Lib - Methods that builds lib tree.

=head1 DESCRIPTION

See L<Kwiki::Kwiki> for all documentation.

=head1 COPYRIGHT

Copyright 2006 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>
