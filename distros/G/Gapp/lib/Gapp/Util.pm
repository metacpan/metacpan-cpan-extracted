package Gapp::Util;
{
  $Gapp::Util::VERSION = '0.60';
}

use Moose;
use MooseX::Types::Moose qw( ArrayRef HashRef );
use Sub::Exporter;



Sub::Exporter::setup_exporter({
    exports => [qw( resolve_gapp_trait_alias replace_entities add_handles)],
    groups  => { all => [qw( resolve_gapp_trait_alias replace_entities add_handles )] }
});

# resolve custom widget trait names
sub _build_alias_package_name {
    my ( $type, $name, $trait ) = @_;
    return 'Gapp::Meta::'
         . $type
         . '::Custom::'
         . ( $trait ? 'Trait::' : '' )
         . $name;
}

{
    my %cache;

    sub resolve_gapp_class_alias {
        my ( $type, $widget_class_name, %options ) = @_;

        my $cache_key = $type . q{ } . ( $options{trait} ? '-Trait' : '' );
        return $cache{$cache_key}{$widget_class_name}
            if $cache{$cache_key}{$widget_class_name};

        my $possible_full_name = _build_alias_package_name(
            $type, $widget_class_name, $options{trait}
        );

        my $loaded_class = Class::MOP::load_first_existing_class(
            $possible_full_name,
            $widget_class_name
        );

        return $cache{$cache_key}{$widget_class_name}
            = $loaded_class->can('register_implementation')
            ? $loaded_class->register_implementation
            : $loaded_class;
    }
}


sub resolve_gapp_trait_alias {
    return resolve_gapp_class_alias( @_, trait => 1 );
}

# convert entities for passing to markup properties
sub replace_entities {
    my ( $str ) = @_;
    
    $str =~ s/&/&amp;/g;
    return $str;
}

# add handles
sub add_handles {
    my ($orig, $handles ) = @_;
    
    # if the current handles value is an array-ref
    if ( is_ArrayRef $orig ) {
        
        # and the new values are an array ref
        if ( is_ArrayRef $handles ) {
            
            # then merge the array refs
            push @{ $orig }, @$handles;
        }
        
        # and the new values are a hash-ref
        elsif ( is_HashRef $handles ) {
            
            # create new hash-ref containing all handles
            my %newvalue = %$handles;
            map { $newvalue{$_} = $_ } @$orig;
            $orig = \%newvalue;
        }
    }
    
    # if the current handle value is a hash-ref
    elsif ( is_HashRef $orig ) {
        
        # and the new values are an array ref
        if ( is_ArrayRef $handles ) {
            
            # save new values in the hash-ref
            map { $orig->{$_} = $_ } @{$handles};
        }
        
        # and the new values are a hash-ref
        elsif ( is_HashRef $handles ) {
            
            # merge the hash-refs
            $orig = { %$orig, %$handles };
        }
    }
    else {
        $orig = $handles;
    }
    
    return $orig;
}

1;

__END__

=pod

=head1 NAME

Gapp::Util - Utility functions for Gapp

=head1 DESCRIPTION

Provides utility functions for the Gapp framework

=head1 EXPORTED FUNCTIONS

=over 4

=item B<add_handles $opts, $handles >

Use when altering the handles property of an attribue during the

=item B<resolve_gapp_trait_alias $trait_class, $trait_name>

Returns the full package name of a given trait.

=back

=head1 ACKNOWLEDGEMENTS

Thanks to everyone at Gtk2-Perl and Moose and all those who came before me for
making this module possible.

Special thanks to Jörn Reder, author of L<Gtk2::Ex::FormFactory>, which inspired
me to write Gapp. L<Gapp::TableMap> uses modified code directly from
L<Gtk2::Ex::FormFactory::Table> (see L<Gapp::TableMap> for more details.)

Special thanks to the authors and contributors of L<MooseX::Types>, which formed
the basis for L<Gapp::Actions> (see L<Gapp::Actions> for more details.)

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

Individual packages in this module may have have multiple authors/and or
contributors. Please refer to the documentation of indivdual packages for
more information. (see L<Gapp::Actions>, L<Gapp::TableMap>)

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.
    
    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.
    
    Individual packages in this module may have have multiple copyrights and
    licenses. Please refer to the documentation of indivdual packages for more
    information. (see L<Gapp::Actions>, L<Gapp::TableMap>)

=cut

















1;