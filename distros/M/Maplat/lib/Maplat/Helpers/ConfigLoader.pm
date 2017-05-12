# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Helpers::ConfigLoader;
use strict;
use warnings;

use 5.008000;

use base qw(Exporter);
our @EXPORT= qw(LoadConfig); ## no critic (Modules::ProhibitAutomaticExportation)
use XML::Simple;

our $VERSION = 0.995;

sub LoadConfig {
    my($fname, %options) = @_;

    croak("$fname not found") unless(-f $fname);
    my $config = XMLin($fname, %options);

    my $newconfig;

    # Copy everything EXCEPT the modules list
    foreach my $key (keys %{$config}) {
        next if($key eq "module");
        $newconfig->{$key} = $config->{$key};
    }

    if(defined($config->{module})) {
        my @modules = @{$config->{module}};
        my @newmodules;
        foreach my $module (@modules) {
            if($module->{modname} ne "include") {
                push @newmodules, $module;
            } else {
                # Lets do some recursion
                my $extraconf = LoadConfig($module->{file}, %options);
                
                ## Add all "normal" keys to the config hash, replacing existing ones
                foreach my $ekey (keys %{$extraconf}) {
                    next if($ekey eq "module");
                    $newconfig->{$ekey} = $extraconf->{$ekey};
                }

                # now, add the modules to the current list (add in sequence)
                if(defined($extraconf->{module})) {
                    my @emodules = @{$extraconf->{module}};

                    # No need to iterate over it, should be clean already
                    push @newmodules, @emodules;
                }
            }
        }
        $newconfig->{module} = \@newmodules;
    }
    return $newconfig;
}

1;

=head1 NAME

Maplat::Helpers::ConfigLoader - Load XML config file

=head1 SYNOPSIS

  use Maplat::Helpers::ConfigLoader;
  
  my $config = LoadConfig($file [, XML::Simple options]);

=head1 DESCRIPTION

This Module is a wrapper for XML::Simple. It adds some enhanced, MAPLAT-specific functions.

=head2 LoadConfig

Loads an XML file through XML::Simple and adds some extra functionality like including
external files.

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
