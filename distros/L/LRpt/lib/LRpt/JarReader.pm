###########################################################################
#
# $Id: JarReader.pm,v 1.2 2006/04/09 15:42:19 pkaluski Exp $
# $Name: Stable_0_16 $
#
# A module for parsing jar record format file.
#
# $Log: JarReader.pm,v $
# Revision 1.2  2006/04/09 15:42:19  pkaluski
# Small code clean-up. Each module has comprehensive POD
#
# Revision 1.1  2006/01/01 13:13:50  pkaluski
# Initial revision. Works.
#
#
############################################################################ 

package LRpt::JarReader;
use strict;

=head1 NAME

LRpt::JarReader - A module for reading jar record format files.

=head1 DESCRIPTION

This class is a part of L<C<LRpt>|LRpt> library.
Object of this class provides an easy interface to jar record format file.

=head1 METHODS

In this sections you will find a more or less complete listing of all
methods provided by the package. Note that the package itself is not
public so none of those methods are guaranteed to be maintained in future 
(including the package itself).

=cut

############################################################################

=head2 C<new>

  my $jr = LRpt::JarReader->new( rules      => $rules,
                                 filename   => $filename,
                                 filehandle => $filehandle );

Constructor. 
Three parameters are allowed:

=over 4

=item rules 

A reference to a list defining the expected layout of the 
input file. Each entry of the list is a reference to a hash
describing rules for one entry. Each hash may have the
following keys:

B<name> => Name of en entry in a section. This parameter is mandatory 

B<mandatory> => Specifies if an entry is mandatory. The default is '1' 
which means 'mandatory'. If an entry is mandatory, it is an error not 
to specify it.

B<trim> => Specifies if traling spaces of an entry value should be 
trimmed. Default is 1, i.e. trim

=item filename

Name of a file, which should be read as input

=item filehandle

Filehandle to a file, which should be read as input

=back

=cut

############################################################################
sub new
{
    my $proto  = shift;
    my %params = @_; 

    my $class = ref( $proto ) || $proto;

    my $self = {};
    bless( $self, $class );
    $self->{ 'rules' }      = $params{ 'rules' };
    if( $params{ 'filename' } ){
        die "filehandle must not be given when a file name is given" 
            if $params{ 'filehandle' };
        open( FH, "< $params{ 'filename' } " ) or 
            die "Cannot open $params{ 'filename' }";
        $self->{ 'filename' } = $params{ 'filename' };
        $self->{ 'filehandle' } = *FH;
    }else{
        $self->{ 'filehandle' } = $params{ 'filehandle' };
    }
    foreach my $rule ( @{ $self->{ 'rules' } } ){
        if( not exists $rule->{ 'mandatory' } ){
            $rule->{ 'mandatory' } = 1;
        }
        if( not exists $rule->{ 'trim' } ){
            $rule->{ 'trim' } = 1;
        }
    }
    return $self;
}


############################################################################

=head2 C<read_all>

  $jr->read_all();

Parses the input file. Creates a list containing values for all sections.
Each item from the list is a reference to a section. Each section is
a hash, where key is an entry name and value is an entry value.

=cut

############################################################################
sub read_all
{
    my $self = shift;
    my $curr_entry = "";
    my $is_first = 1;
    my $curr_section = {};
    my $key = "";
    my @sections = ();
    my $fh = $self->{ 'filehandle' };
    while( 1 ){
        $_ = <$fh>;
        if( ! defined $_ ){
            if( $is_first ){
                last;
            }
            $curr_section->{ $key } = $curr_entry;
            $self->check_mandatory( $curr_section );
            push( @sections, $curr_section );
            $curr_section = {};
            $is_first = 1;
            last;
        }
        if( /^#/ or /^\s+$/ ){
            next;
        }
        if( /^%%\s*$/ ){
            $curr_section->{ $key } = $curr_entry;
            $self->check_mandatory( $curr_section );
            push( @sections, $curr_section );
            $curr_section = {};
            $is_first = 1;
            next;
        } 
        if( /^\w+:/ ){
            if( $is_first ){ # The first entry in a section
                $is_first = 0;
            }else{ 
                $curr_section->{ $key } = $curr_entry;
            }
            ( $key, $curr_entry ) = ( /^(\w+):\s+(.*)/ );
        }else{
            $curr_entry = $curr_entry . $_;    
        }
    }
    $self->{ 'sections' } = \@sections;
}
                
############################################################################

=head2 C<check_mandatory>

  $jr->check_mandatory( $section );

Checks if the current section contains all mandatory entries (and
does necessary trimming).

=cut

############################################################################
sub check_mandatory
{
    my $self    = shift;
    my $section = shift;

    my @read_entries = keys %{ $section };
    my %def_names = ();
    foreach my $def ( @{ $self->{ 'rules' } } ){
        $def_names{ $def->{ 'name' } } = 1;
        if( ! exists $section->{ $def->{ 'name' } } ){
            if( $def->{ 'mandatory' } ){
                die "Mandatory entry '$def->{ 'name' }' not given";
            }
        }
        if( $def->{ 'trim' } ){
            $section->{ $def->{ 'name' } } =~ s/\s*$//;
        }
    }
    foreach my $re ( @read_entries ){
        if( not exists $def_names{ $re } ){
            die "Unexpected entry $re";
        }
    }
}

############################################################################

=head2 C<get_section_with>

  $jr->get_section_with( %entry );

Returns a reference to a section containing an entry of a given name, having
a given value.

=cut

############################################################################
sub get_section_with
{
    my $self  =  shift;
    my %entry =  @_;

    my $name  = ( keys %entry )[ 0 ]; 
    my $value = $entry{ $name };
    
    foreach my $sect ( @{ $self->{ 'sections' } } ){
        if( exists $sect->{ $name } ){
            if( $sect->{ $name } eq $value ){
                return $sect;
            }
        }
    } 
    return undef;
}
    
############################################################################

=head2 C<get_all_values_of>

  $jr->get_all_values_of( $name )

Returnes a list of all values of a given entry in all sections.

=cut

############################################################################
sub get_all_values_of
{
    my $self   = shift;
    my $name   = shift;
    my @values = ();
    foreach my $sect ( @{ $self->{ 'sections' } } ){
        push( @values, $sect->{ $name } );
    }
    return @values;
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

