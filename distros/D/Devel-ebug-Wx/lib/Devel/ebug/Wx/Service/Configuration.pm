package Devel::ebug::Wx::Service::Configuration;

use strict;
use base qw(Devel::ebug::Wx::Service::Base);
use Devel::ebug::Wx::Plugin qw(:plugin);

=head1 NAME

Devel::ebug::Wx::Service::Configuration - manage ebugger configuration

=head1 SYNOPSIS

  my $cm = ...->get_service( 'configuration' );
  my $cfg = $cm->get_config( 'service_name' );

  my $value_or_default = $cfg->get_value( 'value_name', $value_default );
  $cfg->set_value( 'value_name', $value );
  $cfg->delete_value( 'value_name' );

=head1 DESCRIPTION

The C<configuration> service manages the global configuration for all
services.

=head1 METHODS

=cut

__PACKAGE__->mk_ro_accessors( qw(inifiles default_file) );

use File::UserConfig;
use Config::IniFiles;
use File::Spec;

sub service_name : Service { 'configuration' }
sub initialized  { 1 }
sub finalized    { 0 }

sub file_name {
    my( $class ) = @_;
    my $dir = File::UserConfig->new( dist     => 'ebug_wx',
                                     sharedir => '.',
                                     )->configdir;

    return File::Spec->catfile( $dir, 'ebug_wx.ini' );
}

sub new {
    my( $class ) = @_;
    my $self = $class->SUPER::new( { inifiles => {} } );

    $self->{default_file} = $class->file_name;
    _load_inifile( $self, $self->default_file );

    return $self;
}

sub _read_or_create {
    my( $file ) = @_;

    if( -f $file ) {
        return Config::IniFiles->new( -file => $file );
    } else {
        my $inifile = Config::IniFiles->new;
        $inifile->SetFileName( $file );

        return $inifile;
    }
}

sub _load_inifile {
    my( $self, $file_name ) = @_;

    $self->inifiles->{$file_name} ||= _read_or_create( $file_name );
}

=head2 get_config

  my $cfg = $cm->get_config( 'service_name' );
  my $cfg2 = $cm->get_config( 'service_name', 'myfile.ini' );

  my $value_or_default = $cfg->get_value( 'value_name', $value_default );
  $cfg->set_value( 'value_name', $value );
  $cfg->delete_value( 'value_name' );
  $cfg->get_serialized_value( 'value_name', $default );
  $cfg->set_serialized_value( 'value_name', $value );

  # force file rewrite
  $cm->flush( 'myfile.ini' );

Returns an object that can be used to read/change/delete the value of
the configuration keys for a given service.

=cut

sub get_config {
    my( $self, $section, $filename ) = @_;

    return Devel::ebug::Wx::Service::Configuration::My->new
      ( _load_inifile( $self, $filename || $self->default_file ), $section );
}

sub finalize {
    my( $self ) = @_;

    $_->RewriteConfig foreach values %{$self->inifiles};
}

sub flush {
    my( $self, $file ) = @_;

    $self->inifiles->{$file}->RewriteConfig if $self->inifiles->{$file};
}

package Devel::ebug::Wx::Service::Configuration::My;

use strict;
use base qw(Class::Accessor::Fast);
use YAML qw();

__PACKAGE__->mk_ro_accessors( qw(inifile section) );

sub new {
    my( $class, $inifile, $section ) = @_;
    my $self = $class->SUPER::new
      ( { inifile   => $inifile,
          section   => $section,
          } );

    return $self;
}

sub get_value {
    my( $self, $name, $default ) = @_;

    return $self->inifile->val( $self->section, $name, $default );
}

sub set_value {
    my( $self, $name, @values ) = @_;

    unless( $self->inifile->setval( $self->section, $name, @values ) ) {
        $self->inifile->newval( $self->section, $name, @values );
    }

    return;
}

sub set_serialized_value {
    my( $self, $name, $value ) = @_;

    $self->set_value( $name, YAML::Dump( $value ) );
}

sub get_serialized_value {
    my( $self, $name, $default ) = @_;

    my @values = $self->get_value( $name, undef );
    return $default unless @values;
    my $undumped = eval {
        YAML::Load( join "\n", @values, '' );
    };

    return $@ ? $default : $undumped;
}

sub delete_value {
    my( $self, $name ) = @_;

    $self->inifile->delval( $self->section, $name );
}

1;
