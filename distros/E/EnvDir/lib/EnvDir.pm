package EnvDir;
use 5.008005;
use strict;
use warnings;
use Carp ();
use File::Spec;
use Storable ();

our $VERSION = "0.08";
our $DEFAULT_ENVDIR = File::Spec->catdir( File::Spec->curdir, 'env' );

use constant MARK_DELETE => '__MARK_DELETE__';

sub new {
    my $class = shift;
    my %args  = @_;
    bless {
        clean => 0,
        depth => 0,
        cache => [],
        stack => [],
        map { $_ => $args{$_} } qw(clean)
    }, $class;
}

my $GLOBAL_INSTANCE;
my @GLOBAL_GUARD;
sub _instance {
    my $class = shift;
    $GLOBAL_INSTANCE ||= $class->new;
    $GLOBAL_INSTANCE;
}

sub import {
    my $class = shift;
    my @args  = @_;

    my $autoload = 0;
    my $dir      = 0;
    my $clean    = 0;
    my $self;

    while ( defined( my $arg = shift @args ) ) {
        if ( $arg eq '-autoload' ) {
            $self = $class->_instance;
            $autoload = 1;

            $dir = shift @args;
            if ( $dir and $dir eq '-clean' ) {
                push @_, $dir;
                $dir = $DEFAULT_ENVDIR;
            }
        }
        elsif ( $arg eq 'envdir' ) {
            my $package = (caller)[0];
            no strict 'refs';
            *{"$package\::envdir"} = \&envdir;
        }
        elsif ( $arg eq '-clean' ) {
            $self = $class->_instance;
            $self->{clean} = 1;
        }
    }

    if ($autoload) {
        push @GLOBAL_GUARD, $self->envdir($dir);
    }
}

sub envdir {
    my ( $self, $envdir ) = @_;

    unless ( ref $self and ref $self eq 'EnvDir' ) {
        $envdir = $self;
        $self = EnvDir->_instance;
    }

    $self->{depth} = scalar @{ $self->{stack} };
    $envdir ||= $DEFAULT_ENVDIR;

    my $depth = $self->{depth};

    # from cache
    my @keys = keys %{ $self->{cache}->[$depth] };
    if ( scalar @keys ) {
        $self->_push_stack;
        $self->_clean_env if $self->{clean};
        $self->_update_env;

        return EnvDir::Guard->new( sub { $self->_revert if $self } );
    }

    # from dir
    opendir my $dh, $envdir or Carp::croak "Cannot open $envdir: $!";

    for my $key ( grep !/^\./, readdir($dh) ) {
        my $path = File::Spec->catfile( $envdir, $key );
        next if -d $path;
        if ( -s $path == 0 ) {
            $self->{cache}->[$depth]->{ uc $key } = MARK_DELETE;
        }
        else {
            my $value = $self->_slurp($path);
            $self->{cache}->[$depth]->{ uc $key } = $value;
        }
    }

    $self->_push_stack;
    $self->_clean_env if $self->{clean};
    $self->_update_env;

    closedir $dh or Carp::carp "Cannot close $envdir: $!";

    return EnvDir::Guard->new( sub { $self->_revert if $self } );
}

sub _push_stack {
    my $self = shift;
    push @{ $self->{stack} }, Storable::freeze( \%ENV );
}

sub _pop_stack {
    my $self = shift;
    my $ENV = pop @{ $self->{stack} };
    %{ Storable::thaw($ENV) };
}

sub _revert {
    my $self = shift;
    %ENV = $self->_pop_stack;
}

sub _clean_env {
    my $self = shift;
    %ENV = ();
    $ENV{PATH} = '/bin:/usr/bin'; # the same as envdir(8)
}

sub _update_env {
    my $self    = shift;
    my $new_env = $self->{cache}->[ $self->{depth} ];
    for ( keys %$new_env ) {
        my $value = $new_env->{$_};
        if ( $value and $value eq MARK_DELETE ) {
            delete $ENV{$_};
        }
        else {
            $ENV{$_} = $value;
        }
    }
}

sub _slurp {
    my $self = shift;
    my $path = shift;
    if ( open my $fh, '<', $path ) {
        my $value = <$fh>;    # read first line only.
        chomp $value if defined $value;
        close $fh or Carp::carp "Cannot close $path: $!";
        return $value;
    }
    else {
        Carp::carp "Cannot open $path: $!";
        return;
    }
}

package EnvDir::Guard;

sub new {
    my ( $class, $handler ) = @_;
    bless $handler, $class;
}

sub DESTROY {
    my $self = shift;
    $self->();
}

1;
__END__

=encoding utf-8

=head1 NAME

EnvDir - Modify environment variables according to files in a specified directory

=head1 SYNOPSIS

    # Load environment variables from ./env
    use EnvDir -autoload;

    # You can specify a directory.
    use EnvDir -autoload => '/path/to/dir';

    # envdir function returns a guard object.
    use EnvDir 'envdir';

    $ENV{PATH} = '/bin';
    {
        my $guard = envdir('/path/to/dir');
    }
    # PATH is /bin from here

    # you can nest envdir by OOP syntax.
    use EnvDir;

    my $envdir = EnvDir->new;
    {
        my $guard = $envdir->envdir('/env1');
        ...

        {
            my $guard = $envdir->envdir('/env2');
            ...
        }
    }

    # If you set the clean option,
    # removes all current %ENV and set PATH=/bin:/usr/bin.
    # This behavior is the same as envdir(8).
    use EnvDir -autoload, -clean;

    # in function style
    use EnvDir 'envdir', -clean;

    # OO style
    use EnvDir;
    my $envdir = EnvDir->new( clean => 1 );

=head1 DESCRIPTION

EnvDir is a module like envdir(8). But this module does not reset all
environments by default, updates only the value that file exists. If you want to reset all environment variables, you can use the C<-clean> option.

=head1 SCRIPT

This distribution contains envdir.pl. See L<envdir.pl> for more details.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 Yoshihiro Sasaki E<lt>ysasaki at cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yoshihiro Sasaki E<lt>ysasaki at cpan.orgE<gt>

=cut

