package Enbld::Command::Available;

use strict;
use warnings;

use parent qw/Enbld::Command/;

use File::Spec;
use autodie;

use Module::Load;
use Module::Load::Conditional qw/can_load/;

require Enbld::Home;
require Enbld::Definition;

sub do {
    my $self = shift;

    my $target_name = shift @{ $self->{argv} };

    if ( $target_name ) {
        $self->validate_target_name( $target_name );

        show_target_available_version( $target_name );

        return $self;
    }

    Enbld::Home->initialize;

    my $module_path = $INC{'Enbld/Command/Available.pm'};
    $module_path =~ s{/Command/Available.pm$}{};

    my $path = File::Spec->catdir( $module_path, 'Definition' );

    opendir( my $dh, $path );
    my @list = grep { !/^\./ } readdir $dh;
    closedir $dh;

    foreach my $name ( sort @list ) {
        $name =~ s/\.pm$//;
        my $output = lc( $name );

        my $module = 'Enbld::Definition::' . $name;

        load $module;

        my $attributes = Enbld::Definition->new( $output )->parse;
        my $line = $output . ' ' x 15;
        print substr( $line, 0, 15 );
        print $attributes->WebSite . "\n";
   }

    return $self;
}

sub show_target_available_version {
    my $target_name = shift;

    my $module = 'Enbld::Definition::' . ucfirst( $target_name );

    load $module;

    my $attributes = Enbld::Definition->new( $target_name )->parse;

    for my $ver ( @{ $attributes->SortedVersionList } ) {
        print $ver . "\n";
    }
}

1;
