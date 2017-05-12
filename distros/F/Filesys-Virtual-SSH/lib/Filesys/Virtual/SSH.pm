package Filesys::Virtual::SSH;
use strict;
use warnings;
use File::Basename qw( basename );
use Filesys::Virtual::Plain ();
use String::ShellQuote;
use IO::File;
use base qw( Filesys::Virtual Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( cwd root_path home_path host ));
our $VERSION = '0.03';

=head1 NAME

Filesys::Virtual::SSH - remote execution Virtual Filesystem

=head1 SYNOPSIS

 use Filesys::Virtual::SSH;
 my $fs = Filesys::Virtual::SSH->new({
     host      => 'localhost',
     cwd       => '/',
     root_path => '/',
     home_path => '/home',
 });
 my @files = $fs->list("/");

 # a deeply inneffecient equivalent to
 # my @files = `ls -a /`;
 # chomp @files;


=head1 DESCRIPTION

Filesys::Virtual::SSH invokes the ssh command line utility in order to
make a remote filesystem have the same api as any other.  It's
primarily useful for POE::Component::Server::FTP.

=cut

# HACKY - mixin these from the ::Plain class, they only deal with the
# mapping of root_path, cwd, and home_path, so they should be safe
*_path_from_root = \&Filesys::Virtual::Plain::_path_from_root;
*_resolve_path   = \&Filesys::Virtual::Plain::_resolve_path;


sub _remote_command {
    my $self = shift;
    return "ssh ". $self->host . " ";
}

sub _remotely {
    my $self = shift;
    my $what = shift;
    my $cmd = $self->_remote_command . shell_quote $what;
    #warn $cmd;
    `$cmd`;
}

sub list {
    my $self = shift;
    my $path = $self->_path_from_root( shift );

    my @files = $self->_remotely( qq{ls -a $path 2> /dev/null} );
    chomp (@files);
    return map { basename $_ } @files;
}

sub list_details {
    my $self = shift;
    my $path = $self->_path_from_root( shift );

    my @lines = $self->_remotely( qq{ls -al $path 2> /dev/null});
    shift @lines; # I don't care about 'total 42'
    chomp @lines;
    return @lines;
}

sub chdir {
    my $self = shift;
    my $to   = shift;

    my $new_cwd   = $self->_resolve_path( $to );
    my $full_path = $self->_path_from_root( $to );
    # XXX check that full_path is a directory
    return $self->cwd( $new_cwd );
}

# well if ::Plain can't be bothered, we can't be bothered either
sub modtime { return (0, "") }

sub stat {
    my $self = shift;
    my $file = $self->_path_from_root( shift );

    my $stat = $self->_remotely(qq{perl -e'print join ",", stat "$file"'});
    return split /,/, $stat;
}

sub size {
    my $self = shift;
    return ( $self->stat( shift ))[7];
}

sub test {
    my $self = shift;
    my $test = shift;
    my $file = $self->_path_from_root( shift );
    my $stat = $self->_remotely( qq{perl -e'print -$test "$file"'});
    return $stat;
}

sub chmod {
    my $self = shift;
    my $mode = shift;
    my $file = $self->_path_from_root( shift );
    my $ret = $self->_remotely( qq{perl -e'print chmod( $mode, "$file") ? 1 : 0'});
    return $ret;
}

sub mkdir {
    my $self = shift;
    my $path = $self->_path_from_root( shift );
    my $ret = $self->_remotely( qq{perl -e'print -d "$path" ? 2 : mkdir( "$path", 0755 ) ? 1 : 0'});
    return $ret;
}

sub delete {
    my $self = shift;
    my $file = $self->_path_from_root( shift );
    my $ret = $self->_remotely( qq{perl -e'print unlink("$file") ? 1 : 0'});
    return $ret;
}

sub rmdir {
    my $self = shift;
    my $path = $self->_path_from_root( shift );
    my $ret = $self->_remotely( qq{perl -e'print -d "$path" ? rmdir "$path" ? 1 : 0 : unlink "$path" ? 1 : 0'} );
    return $ret;

}

# Yeah Yeah, Whatever
sub login { 1 }

sub open_read {
    my $self = shift;
    my $file = $self->_path_from_root( shift );
    return IO::File->new($self->_remote_command."cat $file |");
}

sub close_read {
    my $self = shift;
    my $fh = shift;
    close $fh;
    return 1;
}

sub open_write {
    my $self = shift;
    my $file = $self->_path_from_root( shift );
    return IO::File->new("|".$self->_remote_command."'cat >> $file'") if @_;
    return IO::File->new("|".$self->_remote_command."'cat > $file'");
}

*close_write = \&close_read;

1;

__END__

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright 2004, 2005 Richard Clamp.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

Filesys::Virtual, POE::Component::Server::FTP

=cut
