package Dzpl;

use strict;
use warnings;

BEGIN {
    use vars qw/ @ISA @EXPORT /;
    @ISA = qw/ Exporter /;
    @EXPORT = qw/ plugin run prune /;
}

use Dist::Dzpl;

our %DZPL;

sub import {
    my $package = caller;
    my @arguments = splice @_, 1;

    strict->import;
    warnings->import;

    if ( $DZPL{$package} ) {
        warn "Dzpl: Already initialized Dist::Dzpl for package ($package)!\n";
        return;
    }

    $DZPL{$package} = Dist::Dzpl->from_arguments( @arguments );
    
    @_ = ( $_[0] );
    goto &Exporter::import;
}

sub dzpl_from_package {
    my ( $self, $package ) = @_;
    
    die "Missing package" unless $package;
    die "Dist::Dzpl not initialized for package ($package)" unless my $dzpl = $DZPL{$package};
    return $dzpl;
}

sub _dzpl_from_package ($) {
    __PACKAGE__->dzpl_from_package( @_ );
}

sub plugin {
    my $package = caller;
    _dzpl_from_package( $package )->plugin( @_ );
}

sub prune (&) {
    my $package = caller;
    _dzpl_from_package( $package )->prune( @_ );
}

sub run (;&) {

    return; # Do nothing until we clean up this interface

#    $dzpl->zilla->_setup_default_plugins;

#    my $default = sub {
#        my @arguments = @_;
#        return unless @arguments;
#        my $command = shift @arguments;
#        if ( $command eq 'dzil' ) {
#            require Dist::Zilla::App;
#            my $app = Dist::Zilla::App->new;
#            $app->{__chrome__} = $dzpl->zilla->chrome;
#            $app->{__PACKAGE__}{zilla} = $dzpl->zilla; # Cover case 1...
#            $app->{'Dist::Zilla::App'}{zilla} = $dzpl->zilla; # ...and case 2
#            local @ARGV = @arguments;
#            $app->run;
#        }
#        else {
#            $dzpl->zilla->$command;
#        }
#    };

#    if ( my $run = shift ) {
#        $run->( $default, $dzpl );
#    }
#    else {
#        $default->( @ARGV );
#    }
}

END {
    if ( my $dzpl = $DZPL{main} ) {
        # This *might* be sketchy...
        require Dist::Dzpl::App;
        Dist::Dzpl::App->run( $dzpl, @ARGV );
    }
}

1;
