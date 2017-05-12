use strict;
use warnings;

package Maven::Maven;
$Maven::Maven::VERSION = '1.14';
# ABSTRACT: The main interface to maven
# PODNAME: Maven::Maven

use Carp;
use Data::Dumper;
use File::ShareDir;
use Log::Any;
use Maven::Repositories;
use Maven::SettingsLoader qw(load_settings);
use Maven::Xml::Pom;

my $logger = Log::Any->get_logger();

sub new {
    return bless( {}, shift )->_init(@_);
}

sub dot_m2 {
    return shift->user_home( '.m2', @_ );
}

sub _default_agent {
    my ( $self, @options ) = @_;
    require LWP::UserAgent;
    my $agent = LWP::UserAgent->new(@options);
    $agent->env_proxy();    # because why not?
    return $agent;
}

sub _default_m2_home {
    return unless ( $ENV{M2_HOME} );
    if ( $^O eq 'cygwin' ) {
        return Cygwin::win_to_posix_path( $ENV{M2_HOME} );
    }
    else {
        return $ENV{M2_HOME};
    }
}

sub _default_user_home {
    if ( $^O eq 'cygwin' ) {
        return Cygwin::win_to_posix_path( $ENV{USERPROFILE} );
    }
    elsif ( $^O eq 'MSWin32' ) {
        return $ENV{USERPROFILE};
    }
    else {
        return $ENV{HOME};
    }
}

sub _init {
    my ( $self, %options ) = @_;

    my $m2_home = $options{M2_HOME} || _default_m2_home();
    $self->{properties} = {
        ( $m2_home ? ( 'env.M2_HOME' => $m2_home ) : () ),
        'user.home' => $options{'user.home'} || _default_user_home()
    };

    my $global_settings = $self->m2_home( 'conf', 'settings.xml' );
    my $user_settings = $self->dot_m2('settings.xml');
    $self->{settings} =
        load_settings( [ $global_settings, $user_settings ], $self->{properties} );

    # some day we should load pom...

    $self->_load_active_profiles();

    my $agent = $options{agent} || $self->_default_agent();

    $self->{repositories} =
        Maven::Repositories->new()->add_local( $self->{settings}->get_localRepository() );
    foreach my $profile ( @{ $self->{active_profiles} } ) {
        my $repositories = $profile->get_repositories();
        if ( $repositories && scalar(@$repositories) ) {
            foreach my $repository (@$repositories) {
                $self->{repositories}->add_repository( $repository->get_url(), agent => $agent );
            }
        }
    }

    return $self;
}

sub get_property {
    my ( $self, $key ) = @_;
    $logger->tracef( 'get_property(\'%s\')', $key );
    return $self->{properties}{$key} || $key;
}

sub get_repositories {
    return $_[0]->{repositories};
}

sub get_settings {
    return $_[0]->{settings};
}

sub _is_active_profile {
    my ( $self, $profile ) = @_;
}

sub _load_active_profiles {
    my ($self) = @_;

    my @active_profiles = ();

    my %settings_active_profiles =
        $self->{settings}->get_activeProfiles()
        ? map { $_ => 1 } @{ $self->{settings}->get_activeProfiles() }
        : ();
    foreach my $profile ( @{ $self->{settings}->{profiles} } ) {
        if ( $settings_active_profiles{ $profile->get_id() } ) {
            push( @active_profiles, $profile );
            next;
        }

        # add support for other ways of being active...
        my $activation = $profile->get_activation();
        if ($activation) {
            my $activeByDefault = $activation->get_activeByDefault();
            if ( $activeByDefault && $activeByDefault =~ /^true$/i ) {
                push( @active_profiles, $profile );
                next;
            }

            # not using jdk, so lets ignore it
            # OS is complicated by cygwin, so we bow out for now...
            my $property = $activation->get_property();
            if (   $property
                && $property->get_name()
                && $property->get_value()
                && $self->{properties}{ $property->get_name() }
                && $self->{properties}{ $property->get_name() } eq $property->get_value() )
            {
                push( @active_profiles, $profile );
                next;
            }
            my $file = $activation->get_file();
            if ($file) {
                my $missing = $file->get_missing();
                if ( $missing && !-f $missing ) {
                    push( @active_profiles, $profile );
                    next;
                }
                my $exists = $file->get_exists();
                if ( $exists && -f $exists ) {
                    push( @active_profiles, $profile );
                    next;
                }
            }
        }
    }

    if (@active_profiles) {
        if ( $self->{active_profiles} ) {
            push( @{ $self->{active_profiles} }, @active_profiles );
        }
        else {
            $self->{active_profiles} = \@active_profiles;
        }
    }
}

sub m2_home {
    my ( $self, @parts ) = @_;
    return unless ( $self->{properties}{'env.M2_HOME'} );
    return File::Spec->catdir( $self->{properties}{'env.M2_HOME'}, @parts );
}

sub user_home {
    my ( $self, @parts ) = @_;
    return File::Spec->catdir( $self->{properties}{'user.home'}, @parts );
}

1;

__END__

=pod

=head1 NAME

Maven::Maven - The main interface to maven

=head1 VERSION

version 1.14

=head1 SYNOPSIS

    use Maven::Maven;

    my $maven = Maven::Maven->new();
    my $artifact = $maven->repositories()->resolve(
        'javax.servlet:servlet-api:2.5');

Or more likely

    use Maven::Agent;

    my $agent = Maven::Agent->new();
    my $maven = $agent->maven();

    my $global_settings_file = $maven->m2_home('conf', 'settings.xml');
    my $user_settings_file = $maven->dot_m2('settings.xml');

    my $artifact = $agent->resolve('javax.servlet:servlet-api:2.5');

=head1 DESCRIPTION

This class is a container for maven configuration data.  When constructed
it parses the settings files (both user and global), and generates 
L<Maven::Repositories> that can be used to resolve L<Maven::Artifact>'s.

=head1 CONSTRUCTORS

=head2 new([%options])

Constructs a new instance.  It is uncommon to construct L<Maven::Maven> 
directly, instead you should use one of the agents (L<Maven::Agent>, 
L<Maven::MvnAgent>) and then obtain access through their 
L<get_maven|Maven::Agent/get_maven()> method. The currently supported options
are:

=over 4

=item agent

An instance of L<LWP::UserAgent> that will be used to connect to the remote
repositories.

=item M2_HOME

The path to the maven install directory.  Defaults to C<$ENV{HOME}>.

=item user.home

The path to the users home directory.  Defaults to 
C<$ENV{HOME} || $ENV{USERPROFILE}>.

=back

=head1 METHODS

=head2 dot_m2([@parts])

Returns a path indicated by joining all of C<@parts> to the user maven dot
directory.

=head2 get_property($key)

Returns the value of the effective settings property indicated by C<$key>.

=head2 get_repositories()

Returns the repositories configured in the effective settings.

=head2 get_settings()

Returns the resolved maven settings (combines global and user settings).

=head2 m2_home([@parts])

Returns a path indicated by joining all of C<@parts> to the maven install
directory.

=head2 user_home([@parts])

Returns a path indicated by joining all of C<@parts> to the user home 
directory.

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Maven::Agent|Maven::Agent>

=item *

L<Maven::MvnAgent|Maven::MvnAgent>

=item *

L<Maven::Artifact|Maven::Artifact>

=back

=cut
