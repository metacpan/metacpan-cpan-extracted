package Drogo::LoadModules;

use strict;
use warnings;

use File::Find;
use Cwd;

=head1 NAME

Drogo::LoadModules - Lightweight module loader

=head1 SYNOPSIS

use Drogo::LoadModules(
    path => [ '/var/foo/weasel', './lib', '../dragons/time/lib' ],
    skip => [ 'BadVoodoo.pm' ],
);

=cut

sub import
{
    my ($self, %params) = @_;

    my @paths = @{ $params{path} || [] };
    my @skips = @{ $params{skip} || [] };

    for my $path (@paths)
    {
        my $caller_dir = '';
        if ($path =~ /^\//)
        {
            $caller_dir = $path;
        }
        else
        {
            my @caller_dir  = split('/', (caller)[1]);
            pop @caller_dir; # trash file name

            $caller_dir = join('/', @caller_dir) . '/' . $path;
        }

        $caller_dir = Cwd::abs_path($caller_dir);

        die "$caller_dir does not exist" unless -d $caller_dir;

        my @files;
        File::Find::find({
            wanted   => sub { push @files, $_ }, 
            no_chdir => 1,
        }, $caller_dir);

        FILE: for my $rel_file (@files)
        {
            # do nothing with directories
            next if -d $rel_file;

            my $file = Cwd::abs_path($rel_file);

            # only include perl files
            next unless $file =~ /\.pm$/;
            next unless -e $file;

            my @path = split('/', $file);
            my $filename = $path[-1];
        
            # skip hidden files
            next if $filename =~ /^\./;
            next if $filename =~ /^\#/;

            # should the file be slipped
            for my $skip (@skips)
            {
                next FILE if $file =~ /$skip/;
            }

            (my $local_file = $file) =~ s/$caller_dir\///;
            my (undef, @rest_path) = split('/', $local_file);
            my $soft_path = join('/', @rest_path);

            # don't reload this if the file is already in %INC
            next if $INC{$local_file};
            next if $INC{$soft_path};
            next if $INC{$file};
            next if $INC{$rel_file};

            # actually require it
            require $file;

            # build local paths to avoid reloading files
            $INC{$soft_path}  = $file;
            $INC{$local_file} = $file;
        }
    }
}

=head1 AUTHORS

Bizowie <http://bizowie.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 Bizowie

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
