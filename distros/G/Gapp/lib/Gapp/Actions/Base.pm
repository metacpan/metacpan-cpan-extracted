package Gapp::Actions::Base;
{
  $Gapp::Actions::Base::VERSION = '0.60';
}
use Moose;

use Carp::Clan                      qw( ^Gapp::Actions );
use Gapp::Actions::Util;
use Gapp::Action::Undefined;
use Gapp::Action::Registry;
use Sub::Exporter                   qw( build_exporter );
use Moose::Util::TypeConstraints;

use namespace::clean -except => [qw( meta )];

my $UndefMsg = q{Unable to find action '%s' in library '%s'};

sub import {
    my ($class, @args) = @_;

    # filter or create options hash for S:E
    my $options = (@args and (ref($args[0]) eq 'HASH')) ? $args[0] : undef;
    unless ($options) {
        $options = {foo => 23};
        unshift @args, $options;
    }

    # all actions known to us
    my @actions = $class->action_names;

    # determine the wrapper, -into is supported for compatibility reasons
    my $wrapper = $options->{ -wrapper } || 'Gapp::Actions';
    $args[0]->{into} = $options->{ -into } 
        if exists $options->{ -into };

    my (%ex_spec, %ex_util);
    
    # create the functions for export
    for my $action_short (@actions) {
        # the action itself
        push @{ $ex_spec{exports} }, 
            $action_short,
            sub { 
                bless $wrapper->action_export_generator($class, $action_short),
                    'Gapp::Actions::EXPORTED_ACTION';
            };
            
        push @{ $ex_spec{exports} }, 
            'do_' . $action_short,
            sub { 
                $wrapper->perform_export_generator($class, $action_short)
            };
    }

    # create S:E exporter and increase export level unless specified explicitly
    my $exporter = build_exporter \%ex_spec;
    $options->{into_level}++ 
        unless $options->{into};
        

    # and on to the real exporter
    my @new_args = ( @args, map { 'do_' . $_ } @actions ); #, keys %add);
    return $class->$exporter(@new_args);
}

sub action_names {
    my ( $class ) = @_;
    return ACTION_REGISTRY( $class )->action_list
}

sub get_action {
    my ($class, $name) = @_;
    
    croak "Unknown action '$name' in library '$class'"   unless
        $class->has_action( $name );

    # return real name of the action
    return ACTION_REGISTRY( $class )->action( $name );
}

sub declare_action {
    my ( $class, $name ) = @_;
    return if ACTION_REGISTRY( $class )->has_action( $name );

    my $action = Gapp::Action::Undefined->new( name => $name );
    ACTION_REGISTRY( $class )->add_action( $action );
}

sub has_action {
    my ( $class, $name ) = @_;
    return ACTION_REGISTRY( $class )->has_action( $name );
}





1;
