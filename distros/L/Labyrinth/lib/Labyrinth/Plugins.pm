package Labyrinth::Plugins;

use warnings;
use strict;

=head1 NAME

Labyrinth::Plugins - Plugin Manager for Labyrinth

=head1 SYNOPSIS

  load_plugins(@plugins);
  my $plugin  = get_plugin($class);
  my @plugins = get_plugins();

=head1 DESCRIPTION

Although loaded via the main Labyrinth module, this module is used by others
to quickly reference all the available plugins.

=cut

use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT @EXPORT_OK);
$VERSION = '5.32';

# -------------------------------------
# Export Details

require Exporter;
@ISA = qw(Exporter);

%EXPORT_TAGS = (
    'all' => [ qw(load_plugins get_plugin get_plugins) ],
);

@EXPORT_OK  = ( @{$EXPORT_TAGS{'all'}} );
@EXPORT     = ( @{$EXPORT_TAGS{'all'}} );

# -------------------------------------
# Library Modules

use Labyrinth::Audit;
use Labyrinth::Variables;

# -------------------------------------
# Variables

my (%plugins,%classes);

# -------------------------------------
# The Program

=head1 FUNCTIONS

=over

=item load_plugins()

Loads plugins found under the plugins directory.

=item get_plugin($class)

Returns the appropriate plugin for the given class.

=item get_plugins()

Returns all available plugins.

=back

=cut

sub load_plugins {
    $classes{$_} = 1    for(@_);
}

sub get_plugin {
    my $class = shift;
    my $method = 'new';
    
    return $plugins{$class} if($plugins{$class});
    return                  unless($classes{$class});

    eval { 
        eval "CORE::require $class";
        $plugins{$class} = $class->$method(@_);
    };

    if($@) {
        $tvars{errcode} = 'ERROR';
        LogError("action: class=$class, method=new, FAULT: $@");
    }

    return $plugins{$class} || undef;
}

sub get_plugins {
    return values %plugins;
}

1;

__END__

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
