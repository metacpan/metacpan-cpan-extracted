package Devel::ebug::Wx::View::Configuration::Simple;

use strict;
use base qw(Wx::Panel Class::Accessor::Fast);
use Devel::ebug::Wx::Plugin qw(:plugin);

__PACKAGE__->mk_ro_accessors( qw(attributes _controls) );

use Wx qw(:sizer wxNullFont wxFNTP_DEFAULT_STYLE);

sub tag { 'configuration_simple' }

sub new : Configuration {
    my( $class, $parent, $attributes ) = @_;
    my $self = $class->SUPER::new( $parent );
    $self->{attributes} = $attributes;
    $self->{_controls} = {};

    $self->create_fields;
    $self->set_data;
    $self->SetMinSize( [250, 200] );

    return $self;
}

# FIXME switch-like type handling sucks
sub create_fields {
    my( $self ) = @_;

    my $sz = Wx::FlexGridSizer->new( 0, 2, 3, 3 );
    $sz->AddGrowableCol( $_ ) foreach 0 .. 2 - 1;
    foreach my $key ( @{$self->attributes->{keys}} ) {
        my $label = Wx::StaticText->new( $self, -1, $key->{label} );
        my $control;
        if( $key->{type} eq 'font' ) {
            $control = Wx::FontPickerCtrl->new
              ( $self, -1, wxNullFont, [-1, -1], [-1, -1],
                wxFNTP_DEFAULT_STYLE );
        } elsif( $key->{type} eq 'string' ) {
            $control = Wx::TextCtrl->new( $self, -1, '' );
        }
        $self->_controls->{$key} = $control;
        $sz->Add( $label, 0 );
        $sz->Add( $control, 0, wxGROW );
    }
    $self->SetSizer( $sz );
}

sub set_data {
    my( $self ) = @_;

    foreach my $key ( @{$self->attributes->{keys}} ) {
        my $control = $self->_controls->{$key};
        next unless defined $key->{value};
        if( $key->{type} eq 'font' ) {
            my $font = Wx::Font->new( $key->{value} );
            $control->SetSelectedFont( $font );
        } elsif( $key->{type} eq 'string' ) {
            $control->SetValue( $key->{value} );
        }
    }
}

sub retrieve_data {
    my( $self ) = @_;

    foreach my $key ( @{$self->attributes->{keys}} ) {
        my $control = $self->_controls->{$key};
        if( $key->{type} eq 'font' ) {
            $key->{value} = $control->GetSelectedFont->GetNativeFontInfoDesc;
        } elsif( $key->{type} eq 'string' ) {
            $key->{value} = $control->GetValue;
        }
    }
}

1;
