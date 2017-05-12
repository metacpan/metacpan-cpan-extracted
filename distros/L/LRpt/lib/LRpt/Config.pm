###########################################################################
#
# $Id: Config.pm,v 1.7 2006/09/17 19:23:40 pkaluski Exp $
# $Name: Stable_0_16 $
#
# Module supporting handling of parameters needed by LReport tools to run.
# 
# $Log: Config.pm,v $
# Revision 1.7  2006/09/17 19:23:40  pkaluski
# Added new settings for chunk size, global keys file, diff report separator
#
# Revision 1.6  2006/02/10 22:32:16  pkaluski
# Major redesign in progress. Updated POD. Works.
#
# Revision 1.5  2006/01/07 22:56:17  pkaluski
# Redesigned simple reporting works. Diff reports still to be implemented.
#
# Revision 1.4  2006/01/01 13:13:49  pkaluski
# Initial revision. Works.
#
#
########################################################################### 
package LRpt::Config;
use strict;

#
# Reference to a hash in which all current values of parameters are stored.
#
our $settings = "";

#
# A hash storing information about each known parameter. These informations
# are:
# ENV - Name of environmental variable in which a parametr's value is
#       stored.
# default - default value of a parameter
#
our %defaults = 
           ( 'ext'  => { 'ENV'     => 'LRPT_CSV_FILE_EXT',
                         'default' => 'txt' },
             'path' => { 'ENV'     => 'LRPT_CSV_FILE_PATH',
                         'default' => '.' },
             'sep'  => { 'ENV'     => 'LRPT_CSV_FIELD_SEPARATOR',
                         'default' => "\t" },
             'conn_file' =>
                       { 'ENV'     => 'LRPT_CONNECTION_FILE',
                         'default' => 'conn_file.txt' },
             'chunk_size' => 
                       { 'ENV'     => 'LRPT_CHUNK_SIZE',
                         'default' => 1000 },  
             'global_keys_file' => 
                       { 'ENV'     => 'LRPT_GLOBAL_KEYS_FILE',
                         'default' => 'keys.txt' },  
             'dv_sep' => 
                       { 'ENV'     => 'LRPT_DIFF_VALUE_SEPARATOR',
                         'default' => '--#>' }  
           );

=head1 NAME

LRpt::Config - A module for managing B<LReport> defaults and runtime
parameters

=head1 DESCRIPTION

This class is a part of L<C<LRpt>|LRpt> library.
It provides a consistent interface to all run time parameters, which
are needed by B<LReport> tools

=head1 METHODS

In this sections you will find a more or less complete listing of all
methods provided by the package. Note that the package itself is not
public so none of those methods are guaranteed to be maintained in future 
(including the package itself).

=cut

##########################################################################

=head2 C<new>

  my $config = LRpt::Config->new( %params );

Constructor. If Config has been already initialised, does nothing.
Otherwise initilizes internal structures

=cut

##########################################################################
sub new
{
    my $proto  = shift;
    my @params = @_;

    my $class = ref( $proto ) || $proto;

    my $self = {};
    bless( $self, $class );
    if( !$settings ){
        $self->initialize( @_ );
    }
    return $self;
}

##########################################################################

=head2 C<initialize>

  $config->initialize( %params );

Decides what actual values for each parameter. Parameters values given
in function paramers have priority.

=cut

##########################################################################
sub initialize
{
    my $self   = shift;
    my %params = @_;

    my $settings = {};

    foreach my $key ( keys %defaults ){
        if( defined $params{ $key } and $params{ $key } ne "" ){
            $settings->{ $key } = $params{ $key };
        }elsif( exists $ENV{ 
                         $defaults{ $key }->{ 'ENV' }
                           } )
        {
            $settings->{ $key } = $ENV{ 
                                     $defaults{ $key }->{ 'ENV' }
                                      }; 
        }else{
            $settings->{ $key } = $defaults{ $key }->{ 'default' };
        }
    }

    foreach my $key ( keys %params ){
        if( not exists $defaults{ $key } ){
            die "Unknown parameter $key";
        }
    }

    $LRpt::Config::settings = $settings;
}

##########################################################################

=head2 C<get_value>

  my $value = $config->get_value( $name );

Returns an actual value of a given parameter

=cut

##########################################################################
sub get_value
{
    my $self = shift;
    my $name = shift;
    return $settings->{ $name };
}

=head1 SEE ALSO

The project is maintained on Source Forge L<http://lreport.sourceforge.net>. 
You can find there links to some helpful documentation like tutorial.

=head1 AUTHORS

Piotr Kaluski E<lt>pkaluski@piotrkaluski.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2004-2006 Piotr Kaluski. Poland. All rights reserved.

You may distribute under the terms of either the GNU General Public License 
or the Artistic License, as specified in the Perl README file. 

=cut

1;

