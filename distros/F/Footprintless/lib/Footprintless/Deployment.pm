use strict;
use warnings;

package Footprintless::Deployment;
$Footprintless::Deployment::VERSION = '1.29';
# ABSTRACT: A deployment manager
# PODNAME: Footprintless::Deployment

use parent qw(Footprintless::MixableBase);

use Carp;
use File::Path qw(
    make_path
);
use Footprintless::Mixins qw (
    _clean
    _download
    _entity
    _extract_resource
    _resource
    _sub_entity
);
use Footprintless::Util qw(
    agent
    rebase
    temp_dir
);
use Log::Any;

my $logger = Log::Any->get_logger();

sub clean {
    my ( $self, @options ) = @_;
    $self->_clean(@options);
}

sub deploy {
    my ( $self, %options ) = @_;

    if ( $options{to_dir} ) {
        $self->_ensure_clean_dirs( $options{to_dir} );
        $self->_deploy_resources( $options{to_dir},
            ( $options{names} ? ( names => $options{names} ) : () ) );
        &{ $options{extra} }( $options{to_dir} ) if ( $options{extra} );
    }
    else {
        $self->_local_template(
            sub {
                my ( $to_dir, $resource_dir ) = @_;
                $self->_ensure_clean_dirs($to_dir);
                $self->_deploy_resources( $resource_dir,
                    ( $options{names} ? ( names => $options{names} ) : () ) );
                &{ $options{extra} }($to_dir) if ( $options{extra} );
            },
            rebase => $options{rebase}
        );
    }

    $logger->debug("deploy complete");
}

sub _deploy_resources {
    my ( $self, $to_dir, %options ) = @_;
    my $resources = $self->_sub_entity( 'resources', 1 );

    my @names =
        $options{names}
        ? @{ $options{names} }
        : keys(%$resources);

    $logger->debugf( "deploy %s to %s", \@names, $to_dir );
    foreach my $resource_name (@names) {
        my $resource = $resources->{$resource_name};
        if ( ref($resource) eq 'HASH' && $resource->{extract_to} ) {
            my $extract_dir = File::Spec->catdir( $to_dir, $resource->{extract_to} );
            $logger->tracef( 'extract [%s] to [%s]', $resource, $to_dir );
            $self->_extract_resource( $resource, $extract_dir );
        }
        else {
            $logger->tracef( 'download [%s] to [%s]', $resource, $to_dir );
            $self->_download( $resource, $to_dir );
        }
    }
}

sub _ensure_clean_dirs {
    my ( $self, $base_dir ) = @_;
    foreach my $dir ( $self->_relative_clean_dirs ) {
        make_path( File::Spec->catdir( $base_dir, $dir ) );
    }
}

sub _local_template {
    my ( $self, $local_work, @options ) = @_;
    $self->Footprintless::Mixins::_local_template(
        sub {
            my ($to_dir) = @_;

            my $resource_dir = $self->_sub_entity('resource_dir');
            $resource_dir =
                $resource_dir
                ? File::Spec->catdir( $to_dir, $resource_dir )
                : $to_dir;
            make_path($resource_dir);

            &$local_work( $to_dir, $resource_dir );
        },
        @options
    );
}

sub _relative_clean_dirs {
    my ($self) = @_;
    my $base = $self->_entity("$self->{coordinate}.to_dir");
    return
        map { m'/$' ? ( File::Spec->abs2rel( $_, $base ) ) : () }
        @{ $self->_entity("$self->{coordinate}.clean") };
}

1;

__END__

=pod

=head1 NAME

Footprintless::Deployment - A deployment manager

=head1 VERSION

version 1.29

=head1 SYNOPSIS

    # Standard way of getting a deployment
    use Footprintless;
    my $deployment = Footprintless->new()->deployment('deployment');

    # Standard deploy procedure
    $deployment->clean();
    $deployment->deploy();

    # Deploy to temp instead of the entity configured location
    my $rebase = {
        from => '/opt/tomcat', 
        to => '/tmp/tomcat'
    };
    $deployment->clean(rebase => $rebase);
    $deployment->deploy(rebase => $rebase);

    # Only deploy selected resources
    $deployment->deploy(names => ['bar']);

=head1 DESCRIPTION

Manages deployments.  A deployment is a set of files and directories that
are all associated with a single component.  For example, if you are using
tomcat, a deployment might refer to all of the webapps deployed to the 
container, and the folders and files that are I<NOT> part of the tomcat
container itself.  

=head1 ENTITIES

A simple deployment:

    deployment => {
        clean => ['/opt/app/'],
        resources => {
            foo => 'http://download.com/foo.exe',
            bar => 'http://download.com/bar.exe'
        },
        to_dir => '/opt/app'
    }

A more complex situation, perhaps a tomcat instance:

    deployment => {
        'Config::Entities::inherit' => ['hostname', 'sudo_username'],
        clean => [
            '/opt/tomcat/conf/Catalina/localhost/',
            '/opt/tomcat/temp/',
            '/opt/tomcat/webapps/',
            '/opt/tomcat/work/'
        ],
        resources => {
            bar => '/home/me/.m2/repository/com/pastdev/bar/1.2/bar-1.2.war',
            baz => {
                coordinate => 'com.pastdev:baz:war:1.0',
                'as' => 'foo.war',
                type => 'maven'
            },
            foo => {
                url => 'http://pastdev.com/resources/foo.war',
                extract_to => 'ROOT'
            }
        },
        to_dir => '/opt/tomcat/webapps'
    }

=head1 CONSTRUCTORS

=head2 new($entity, $coordinate)

Constructs a new deployment configured by C<$entities> at C<$coordinate>.  

=head1 METHODS

=head2 clean(%options)

Cleans the deployment.  Each path in the C<configuration.clean> entity, 
will be removed from the destination.  If the path ends in a C</>, then 
after being removed, the directory will be recreated.  The supported 
options are:

=over 4

=item rebase

A hash containing C<from> and C<to> where the paths for each item in the
clean entity will have the C<from> portion of their path substituted by 
C<to>.  For example, if the path is C</foo/bar> and rebase is
C<{from => '/foo', to => '/baz'}>, then the resulting path would be 
C</baz/bar>.

=back

=head2 deploy(%options)

Deploys all the resources listed in the C<resource> entity to the location
specified in the C<configuration.to_dir> entity. The supported options 
are:

=over 4

=item extra 

A subroutine that is called during deployment allowing you to add to
what is deployed before it is pushed to its destination.  This subroutine
will be called with a single argument containing the (possibly temporary)
directory that you can write additional files to.

=item names

A list of names of resources that should be deployed.  If this option is
provided, any names not in this list will be ignored.

=item rebase

A hash containing C<from> and C<to> where the paths for each item in the
clean entity will have the C<from> portion of their path substituted by 
C<to>.  For example, if the path is C</foo/bar> and rebase is
C<{from => '/foo', to => '/baz'}>, then the resulting path would be 
C</baz/bar>.

=back

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Footprintless|Footprintless>

=item *

L<Config::Entities|Config::Entities>

=item *

L<Footprintless|Footprintless>

=item *

L<Footprintless::Mixins|Footprintless::Mixins>

=back

=cut
