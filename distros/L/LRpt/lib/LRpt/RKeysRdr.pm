###################################################################
#
# $Id: RKeysRdr.pm,v 1.4 2006/09/17 19:20:40 pkaluski Exp $
# $Name: Stable_0_16 $
#
# This module reads definitions of row keys
#
# $Log: RKeysRdr.pm,v $
# Revision 1.4  2006/09/17 19:20:40  pkaluski
# Added handling of several ways of specifying keys
#
# Revision 1.3  2006/04/09 15:42:19  pkaluski
# Small code clean-up. Each module has comprehensive POD
#
# Revision 1.2  2006/01/14 12:52:33  pkaluski
# New tool design in progress
#
# Revision 1.1  2006/01/07 22:15:03  pkaluski
# Initial revision. Works.
#
#
#
###################################################################
package LRpt::RKeysRdr;

use LRpt::JarReader;
use strict;

=head1 NAME

LRpt::RKeysRdr - a module for reading definitions of row keys

=head1 DESCRIPTION

This class is a part of L<C<LRpt>|LRpt> library.
Object of this class provides an easy interface row keys definition
files.

=cut

our @rkeys_rules = ( { 'name' => 'select_name' },
                    { 'name' => 'key_columns' } );

our $rkeys_data = "";
                

=head1 METHODS

In this sections you will find a more or less complete listing of all
methods provided by the package. Note that the package itself is not
public so none of those methods are guaranteed to be maintained in future 
(including the package itself).

=cut

############################################################################

=head2 C<new>

  my $rkr = LRpt::RKeysRdr->new( fname    => $fname,
                                 string   => $string );

Constructor. Meaning of parameters:

=over 4

=item fname

Name of a file containing definitions of row keys

=item string

Definition of a row keys given as one string. This feature is experimantal
and you better don't use it.

=back

=cut

#############################################################################
sub new
{
    my $proto         = shift;
    my %params        = @_;
    
    my $class = ref( $proto ) || $proto;
    my $self = {};
    bless( $self, $class ); 
    if( !$rkeys_data ){
        $self->initialize_keys( $params{ 'fname' }, 
                                $params{ 'key' },
                                $params{ 'key_cols' },
                                $params{ 'global_keys' } );
    }
    return $self;
}


############################################################################

=head2 C<initialize_keys>

  $rkr->initialize_keys( $fname, $string );

Called by the contructor to perform initialization. Meaning of parameters:

=over 4

=item $fname

Name of a file containing definitions of row keys

=item $string

Definition of a row keys given as one string. This feature is experimantal
and you better don't use it.

=back

=cut

#############################################################################
sub initialize_keys
{
    my $self        = shift;
    my $rk_fname    = shift;
    my $key_strings   = shift;
    my $key_col_strings   = shift;
    my $global_keys = shift;
    
    $rkeys_data = {};
    $self->{ 'default' }->{ 'columns' } = [ 0 ];
    $self->{ 'default' }->{ 'name' } = 'key1';
    if( @$key_strings ){
        $self->scan_key_from_cmd( $key_strings );
    }
    if( @$key_col_strings ){
        $self->scan_key_cols_from_cmd( $key_col_strings );
    }

    if( $global_keys ){
        my $config = LRpt::Config->new();
        my $fname = $config->get_value( 'global_keys_file' );
        if( -e $fname ){
            $self->load_keys( $fname );
        }
    }
    if( $rk_fname ){
        $self->load_keys( $rk_fname );
    }

}

######################################################################

=head2 C<scan_keys_from_cmd>

  $rkr->scan_keys_from_cmd( $string );

Scans row key definition given in the command line. If nothing is given,
a default row key is assumed. Key parts are separated by commas.
The key will be used in all collections, for which a key in a file was
not defined.

=cut

######################################################################
sub scan_key_from_cmd
{
    my $self        = shift;
    my $key_strings = shift;
    
    my $fmt_str = "";
    my @col_idxs    = ();
    my @col_type    = ();
    foreach my $string ( @$key_strings ){
        my( $start, $end ) = split( /,/, $string ); 
        my $start_idx;
        my $start_field_length;
        my $end_idx;
        my $end_field_length;

        if( $start =~ /^\d+$/ ) # Text field
        {
            $start_idx = $start;
        }elsif( $start =~ /^\d+n\d+$/ ){
            ( $start_idx, $start_field_length ) = ( $start =~ /^(\d+)n(\d+)$/ )[ 0, 1 ];
        }else{
            die "$string is not a right format of a key specification";
        } 
        
        if( $end ){
            if( $end =~ /^\d+$/ ) # Text field
            {
                $end_idx = $end;
            }elsif( $end =~ /^\d+n\d+$/ ){
                ( $end_idx, $end_field_length ) = ( $end =~ /^(\d+)n(\d+)$/ )[ 0, 1 ];
            }else{
                die "$string is not a right format of a key specification";
            } 
        }else{
            $end_idx = $start_idx;
        }
       
        my $cur_idx = @col_idxs;
        if( $start_idx <= $end_idx ){
            for( my $i = $start_idx - 1; $i < $end_idx; $i++ ){ 
                push( @col_idxs, $i ); 
                push( @col_type, "s" ); 
            }
        }else{
            for( my $i = $start_idx - 1; $i >= ( $end_idx - 1 ); $i-- ){ 
                push( @col_idxs, $i ); 
                push( @col_type, "s" ); 
            }
        }    
        $col_type[ $cur_idx ] = $start_field_length if $start_field_length; 
        $col_type[ $#col_type ]   = $end_field_length if $end_field_length; 
    }
            
    for( my $i = 0; $i < @col_idxs; $i++ ){
        if( $col_type[ $i ] eq "s" ){
            $fmt_str = $fmt_str . "\%s#";
        }else{
            $fmt_str = $fmt_str . "%0" . $col_type[ $i ] . "d#";
        }    
    }
    $fmt_str =~ s/#$//;
    $self->{ 'default' }->{ 'columns' } = \@col_idxs;
    $self->{ 'default' }->{ 'function' } = $fmt_str; 
}

sub scan_key_cols_from_cmd
{
    my $self        = shift;
    my $key_strings = shift;
    
    my @cols    = ();
    my $fmt_str = "";
    foreach my $string ( @$key_strings ){
        my @keys_parts = split( /,/, $string );
        foreach my $key ( @keys_parts ){
            my @parts = split( /:/, $key );
            push( @cols, $parts[ 0 ] ); 
            if( $parts[ 1 ] ){
                $fmt_str = $fmt_str . "%0$parts[ 1 ]" . "d#";
            }else{
                $fmt_str = $fmt_str . "%s#";
            }
        }
    }
    $fmt_str =~ s/#$//;
    $self->{ 'default' }->{ 'columns' } = \@cols;
    $self->{ 'default' }->{ 'function' } = $fmt_str; 
}

######################################################################

=head2 C<load_keys>

  $rkr->load_keys( $rk_fname );

Loads row keys definitions from jar-record file.

=cut

######################################################################
sub load_keys
{
    my $self  = shift;
    my $fname = shift;
    open( KEYS, "<$fname" ) or die "Cannot open '$fname' : $!"; 
    my $jr = LRpt::JarReader->new( 
                      'rules' => \@rkeys_rules, 'filehandle' => *KEYS ); 
    $jr->read_all();
    my @selects = $jr->get_all_values_of( 'select_name' );

    foreach my $select ( @selects ){
        my $sect = $jr->get_section_with( 'select_name' => $select );
        my @selects_in_entry = split( /\s*,\s*/, $select );
        foreach my $s ( @selects_in_entry ){
            $self->{ 'definitions' }->{ $s } = 
                       $self->parse_rkey_str( $sect->{ 'key_columns' } );
        }
    }
    close( KEYS ) or die "Cannot close $fname";
    
}

######################################################################

=head2 C<parse_rkey_str>

  $rkr->parse_rkey_str( $keys_str );

Parse a definition of one row key given in C<$keys_str>.

=cut

######################################################################
sub parse_rkey_str
{
    my $self = shift;
    my $keys_str = shift;

    my %rkey = ();
    $rkey{ 'name' } = 'key1';
    my $fmt_str = "";
    my @cols = ();

    my @keys_parts = split( /\s*,\s*/, $keys_str );
    foreach my $key ( @keys_parts ){
        my @parts = split( /:/, $key );
        push( @cols, $parts[ 0 ] ); 
        if( $parts[ 1 ] ){
            $fmt_str = $fmt_str . "%0$parts[ 1 ]" . "d#";
        }else{
            $fmt_str = $fmt_str . "%s#";
        }
    }
    $fmt_str =~ s/#$//;
    $rkey{ 'columns' } = \@cols;
    $rkey{ 'function' } = $fmt_str; 
    return \%rkey;
}

######################################################################

=head2 find_key

  $key = $rkr->find_key( $name );

Find a row key to be applied to a given file.

=cut

######################################################################
sub find_key
{
    my $self = shift;
    my $name = shift;
    if( not exists $self->{ 'definitions' }->{ $name } ){
        return $self->{ 'default' };
    }else{
        return $self->{ 'definitions' }->{ $name };
    }
} 

1;

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

