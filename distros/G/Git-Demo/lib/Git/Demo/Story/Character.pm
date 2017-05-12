package Git::Demo::Story::Character;
use strict;
use warnings;
use Git::Demo::Story::Event;
use File::Util;
use File::Spec::Functions;

sub new{
    my $class = shift;
    my $args = shift;

    my $self = {};
    foreach( qw/name story/ ){
        if( ! $args->{$_} ){
            die( "Required agr $_ not defined" );
        }
        $self->{$_} = $args->{$_};
    }

    my $logger = Log::Log4perl->get_logger( __PACKAGE__ );
    $self->{logger} = $logger;


    $self->{dir} = $args->{dir} || catfile( $args->{story}->dir(), $args->{name} );

    ##FIXME
    # Add all git variables which could be useful
    # Replace zipmail domain with something configurable!
    my $options = {
        env => {
            GIT_COMMITTER_EMAIL => $args->{name} . '@zipmail.com',
            GIT_COMMITTER_NAME  => $args->{name},
            GIT_AUTHOR_EMAIL    => $args->{name} . '@zipmail.com',
            GIT_AUTHOR_NAME     => $args->{name},
        },
    };

    if( ! -d $self->{dir} ){
        my $f = File::Util->new();
        $logger->debug( "Creating repository directory for character: $args->{name}" );
        if( ! $f->make_dir( $self->{dir} ) ){
            die( "Could not create user dir $self->{dir}\n$!\n" );
        }
    }

    ##FIXME
    # There should be options to use existing, or even remote (ssh?) repositories
    # For now default is always initialise
    ##FIXME
    # This should be moved to the Actions/Git section
    $logger->debug( "Initialising repository character: $args->{name}" );

    my @git_args = ( 'init' );
    if( $args->{git_args} ){
        push( @git_args, @{ $args->{git_args} } );
    }
    push( @git_args, $self->{dir} );
    push( @git_args, $options );
    $self->{git} = Git::Repository->create( @git_args );

    bless $self, $class;

    return $self;
}

sub dir{
    my $self = shift;
    return $self->{dir};
}

sub git{
    my $self = shift;
    return $self->{git};
}

sub name{
    my $self = shift;
    return $self->{name};
}
1;
