use strict;
use warnings;

package Maven::SettingsLoader;
$Maven::SettingsLoader::VERSION = '1.14';
# ABSTRACT: The loader for settings files
# PODNAME: Maven::SettingsLoader

use Exporter qw(import);
use File::ShareDir;
use Log::Any;
use Maven::Xml::Settings;

our @EXPORT_OK = qw(load_settings);
my $logger = Log::Any->get_logger();

sub load_settings {
    my ( $settings_files, $properties ) = @_;

    my $settings =
        Maven::Xml::Settings->new(
        file => File::ShareDir::module_file( 'Maven::Xml::Settings', 'settings.xml' ) );
    foreach my $file (@$settings_files) {
        if ( $file && -f $file ) {
            $settings = _merge( Maven::Xml::Settings->new( file => $file ), $settings );
        }
    }

    _interpolate( $settings, $properties );

    return $settings;
}

sub _interpolate {
    my ( $value, $properties ) = @_;

    my $ref = ref($value);
    if ($ref) {
        if ( $ref eq 'ARRAY' ) {
            for ( my $i = 0; $i < scalar(@$value); $i++ ) {
                $value->[$i] = _interpolate( $value->[$i], $properties );
            }
        }
        else {
            foreach my $key ( keys(%$value) ) {
                $value->{$key} = _interpolate( $value->{$key}, $properties );
            }
        }
    }
    elsif ($value) {
        $logger->tracef( 'interpolating \'%s\'', $value );
        $value =~ s/\$\{(.*?)\}/$properties->{$1}/g;
    }

    return $value;
}

sub _merge {
    my ( $dominant, $recessive ) = @_;

    if ( !$dominant->get_localRepository() ) {
        $dominant->set_localRepository( $recessive->get_localRepository() );
    }
    if ( !$dominant->get_interactiveMode() ) {
        $dominant->set_interactiveMode( $recessive->get_interactiveMode() );
    }
    if ( !$dominant->get_usePluginRegistry() ) {
        $dominant->set_usePluginRegistry( $recessive->get_usePluginRegistry() );
    }
    if ( !$dominant->get_offline() ) {
        $dominant->set_offline( $recessive->get_offline() );
    }

    if ( $dominant->get_mirrors() ) {
        _shallow_merge_by_ids( $dominant->get_mirrors(), $recessive->get_mirrors() );
    }
    else {
        $dominant->set_mirrors( $recessive->get_mirrors() );
    }

    if ( $dominant->get_servers() ) {
        _shallow_merge_by_ids( $dominant->get_servers(), $recessive->get_servers() );
    }
    else {
        $dominant->set_servers( $recessive->get_servers() );
    }

    if ( $dominant->get_proxies() ) {
        _shallow_merge_by_ids( $dominant->get_proxies(), $recessive->get_proxies() );
    }
    else {
        $dominant->set_proxies( $recessive->get_proxies() );
    }

    if ( $dominant->get_profiles() ) {
        _shallow_merge_by_ids( $dominant->get_profiles(), $recessive->get_profiles() );
    }
    else {
        $dominant->set_profiles( $recessive->get_profiles() );
    }

    if ( $recessive->get_activeProfiles() ) {
        my $dominant_active_profiles = $dominant->get_activeProfiles();
        if ( $dominant_active_profiles && scalar(@$dominant_active_profiles) ) {
            my %dominant = map { $_ => 1 } @$dominant_active_profiles;
            foreach my $recessive_active_profile ( @{ $recessive->get_activeProfiles() } ) {
                push( @$dominant_active_profiles, $recessive_active_profile );
            }
        }
        else {
            $dominant->set_activeProfiles( $recessive->get_activeProfiles() );
        }
    }

    if ( $recessive->get_pluginGroups() ) {
        my $dominant_plugin_groups = $dominant->get_pluginGroups();
        if ( $dominant_plugin_groups && scalar(@$dominant_plugin_groups) ) {
            my %dominant = map { $_ => 1 } @$dominant_plugin_groups;
            foreach my $recessive_plugin_groups ( @{ $recessive->get_pluginGroups() } ) {
                push( @$dominant_plugin_groups, $recessive_plugin_groups );
            }
        }
        else {
            $dominant->set_pluginGroups( $recessive->get_pluginGroups() );
        }
    }

    return $dominant;
}

sub _shallow_merge_by_ids {
    my ( $dominant, $recessive ) = @_;
    return if ( !$recessive || !scalar(@$recessive) );

    my %dominant_by_id = map { $_->get_id() => $_ } @$dominant;
    foreach my $recessive_entry (@$recessive) {
        next unless $recessive_entry;
        if ( !$dominant_by_id{ $recessive_entry->get_id() } ) {
            push( @$dominant, $recessive_entry );
        }
    }
}

1;

__END__

=pod

=head1 NAME

Maven::SettingsLoader - The loader for settings files

=head1 VERSION

version 1.14

=head1 SYNOPSIS

    use Maven::SettingsLoader qw(load_settings);
    my $settings = load_settings(
        [
            '/path/to/global/settings.xml',
            '/path/to/user/settings.xml',
        ],
        {
            'env.M2_HOME' => $ENV{M2_HOME},
            'user.home' => $ENV{HOME}
        });

=head1 DESCRIPTION

Used by L<Maven::Maven> to load settings files.

=head1 EXPORT_OK

=head2 load_settings(\@settings_files, \%properties)

Will load C<\@settings_files> in order, interpolating 
placeholders using the values from C<$properties>.

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

L<Maven::Maven|Maven::Maven>

=back

=cut
