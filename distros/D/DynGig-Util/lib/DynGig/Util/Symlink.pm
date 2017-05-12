=head1 NAME

DynGig::Util::Symlink - manipulate symbolic links

=cut
package DynGig::Util::Symlink;

use warnings;
use strict;
use Carp;
use Cwd;

use constant ROLLBACK => 'rollback';

=head1 SYNOPSIS

 use DynGig::Util::Symlink;
 
 my $link = DynGig::Util::Symlink->new
 (
     link => 'foo.bar',
     root => '/foo/bar', ## optional
     path => 'foo.real', ## optional
     user => 'web:web',  ## optional 
 )

 my $check = $link->check();
 my $path1 = $link->make();
 my $path2 = $link->make( rollback => 1 );

=cut
sub new
{
    my ( $class, %config ) = @_;

    croak 'link not defined' unless defined $config{link};

    $config{root} = $config{oldcwd} unless defined $config{root};
    $config{oldcwd} = getcwd();
    $config{ROLLBACK} = join '.', $config{link}, ROLLBACK;

    bless \%config, ref $class || $class;
}

sub make
{
    my ( $this, %param ) = @_;
    my $cwd = $this->{oldcwd};
    my $user = $this->{user};
    my $link = $this->{link};
    my $rollback = $this->{ROLLBACK};
    my $current = $this->readlink();
    my $previous = readlink $rollback;

    if ( $param{rollback} )
    {
        if ( -l $rollback && defined $previous )
        {
            my $temp = ".$link.temp";

            croak "rename: $!" if -l $link && ! rename( $link, $temp )
                || ! rename( $rollback, $link ) || ! rename( $temp, $rollback );
        }

        $previous = readlink $link;
    }
    elsif ( defined ( my $path = $this->{path} ) )
    {
        unless ( defined $current && $path eq $current )
        {
            croak "rename: $!" if -l $link && ! rename $link, $rollback; 
            croak "symlink: $!" unless symlink $path, $link;
        }
    }

    system( "chown -h $user $link $rollback" ) unless $<;
    croak "chdir $cwd: $!" unless chdir $cwd;
    return $previous;
}

sub check
{
    my $this = shift @_;
    my $cwd = $this->{oldcwd};

    croak "chdir $cwd: $!" unless chdir $cwd;
    $this->readlink();
}

sub readlink
{
    my $this = shift @_;
    my $cwd = $this->{root};
    my $link = $this->{link};

    croak "chdir $cwd: $!" unless chdir $cwd;
    return undef unless -e $link;
    croak "not a symlink" unless -l $link;

    readlink $link;
}

sub DESTROY
{
    my $this = shift @_;
    my $cwd = $this->{oldcwd};

    map { delete $this->{$_} } keys %$this;
    croak "chdir $cwd: $!" unless chdir $cwd;
}

=head1 NOTE

See DynGig::Util

=cut

1;

__END__
