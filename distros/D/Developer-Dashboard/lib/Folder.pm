package Folder;
$Folder::VERSION = '0.72';
use strict;
use warnings;

use Cwd qw(cwd);
use File::Basename qw(dirname);
use File::Find ();
use File::Path qw(make_path);
use File::Spec;

our $PATHS = {};
our %ALIASES;
our $AUTOLOAD;

# configure(%args)
# Configures the compatibility folder registry from runtime paths and aliases.
# Input: optional paths object and aliases hash.
# Output: true value.
sub configure {
    my ( $class, %args ) = @_;
    $PATHS = $args{paths} if $args{paths};
    %ALIASES = %{ $args{aliases} || {} };
    return 1;
}

# home()
# Returns the current home directory path.
# Input: none.
# Output: directory path string.
sub home {
    return $ENV{HOME} || '';
}

# tmp()
# Returns the temporary directory path.
# Input: none.
# Output: directory path string.
sub tmp {
    return File::Spec->tmpdir;
}

# dd()
# Returns the dashboard runtime root directory.
# Input: none.
# Output: directory path string.
sub dd {
    return $PATHS && $PATHS->can('runtime_root') ? $PATHS->runtime_root : '';
}

# bookmarks()
# Returns the dashboard bookmark directory.
# Input: none.
# Output: directory path string.
sub bookmarks {
    return $PATHS && $PATHS->can('dashboards_root') ? $PATHS->dashboards_root : '';
}

# configs()
# Returns the dashboard config directory.
# Input: none.
# Output: directory path string.
sub configs {
    return $PATHS && $PATHS->can('config_root') ? $PATHS->config_root : '';
}

# postman()
# Returns the neutral default postman collection directory.
# Input: none.
# Output: directory path string.
sub postman {
    my $dir = File::Spec->catdir( configs(), 'postman' );
    make_path($dir) if $dir ne '' && !-d $dir;
    return $dir;
}

# startup()
# Returns the dashboard startup directory.
# Input: none.
# Output: directory path string.
sub startup {
    return $PATHS && $PATHS->can('startup_root') ? $PATHS->startup_root : '';
}

# cd($where, $code)
# Temporarily changes directory and invokes a callback.
# Input: named path or literal directory path plus callback.
# Output: callback return value or undef.
sub cd {
    my ( $class, $where, $code ) = @_;
    return if ref($code) ne 'CODE';
    my $pwd = cwd();
    my $dir = $class->_resolve_path($where);
    return if !$dir || !-d $dir;
    chdir $dir or return;
    my $parent = dirname($dir);
    my $result = $code->(
        {
            caller => $pwd,
            parent => $parent,
            dir    => $dir,
            stay   => sub { $pwd = $_[0] if defined $_[0] && $_[0] ne '' },
        }
    );
    chdir $pwd if $pwd;
    return $result;
}

# ls($where)
# Lists files and folders in a directory.
# Input: named path or literal directory path.
# Output: list of detail hashes.
sub ls {
    my ( $class, $where ) = @_;
    my $dir = $class->_resolve_path($where);
    return () if !$dir || !-d $dir;
    opendir my $dh, $dir or return ();
    my @items;
    while ( my $entry = readdir $dh ) {
        next if $entry eq '.' || $entry eq '..';
        my $path = File::Spec->catfile( $dir, $entry );
        push @items, {
            NAME => $entry,
            path => $path,
            type => -d $path ? 'folder' : 'file',
            size => -s $path || 0,
        };
    }
    closedir $dh;
    return sort { $b->{type} cmp $a->{type} || $a->{NAME} cmp $b->{NAME} } @items;
}

# locate(@parts)
# Locates matching directories below configured workspace roots.
# Input: name fragments.
# Output: matching absolute directory paths.
sub locate {
    my ( $class, @parts ) = @_;
    @parts = grep { defined && $_ ne '' } @parts;
    return () if !@parts || !$PATHS || !$PATHS->can('workspace_roots');
    my @found;
    for my $root ( $PATHS->workspace_roots ) {
        next if !-d $root;
        File::Find::find(
            {
                no_chdir => 1,
                wanted   => sub {
                    return if !-d $_;
                    my $path = $File::Find::name;
                    my $name = $_;
                    for my $part (@parts) {
                        return if $name !~ /\Q$part\E/i && $path !~ /\Q$part\E/i;
                    }
                    push @found, $path;
                },
            },
            $root,
        );
    }
    my %seen;
    return grep { !$seen{$_}++ } sort @found;
}

# _resolve_path($where)
# Resolves a named folder alias or literal path.
# Input: alias or path string.
# Output: directory path string or undef.
sub _resolve_path {
    my ( $class, $where ) = @_;
    return if !defined $where || $where eq '';
    return $where if File::Spec->file_name_is_absolute($where) || -d $where;
    return $class->$where() if $class->can($where);
    return $ALIASES{$where} if defined $ALIASES{$where};
    my $env = 'DEVELOPER_DASHBOARD_PATH_' . uc($where);
    return $ENV{$env} if defined $ENV{$env} && $ENV{$env} ne '';
    return;
}

# AUTOLOAD()
# Resolves unknown folder names from configured aliases or env overrides.
# Input: none.
# Output: directory path string or dies on unknown alias.
sub AUTOLOAD {
    my ($class) = @_;
    my ($name) = $AUTOLOAD =~ /::([^:]+)$/;
    return if $name eq 'DESTROY';
    my $path = $class->_resolve_path($name);
    die "Unknown folder '$name'" if !defined $path || $path eq '';
    make_path($path) if $path =~ m{^/} && !-e $path;
    return $path;
}

1;

__END__

=head1 NAME

Folder - legacy folder compatibility wrapper

=head1 SYNOPSIS

  Folder->configure(paths => $paths, aliases => { postman => '/tmp/postman' });
  my $dir = Folder->postman;

=head1 DESCRIPTION

This module exposes a project-neutral compatibility layer for older bookmark
code that expects a C<Folder> package.

=head1 METHODS

=head2 configure, home, tmp, dd, bookmarks, configs, startup, cd, ls, locate

Configure and resolve compatibility folders.

=cut
