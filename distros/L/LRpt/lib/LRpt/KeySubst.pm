###########################################################################
#
# $Id: KeySubst.pm,v 1.4 2006/09/17 19:22:37 pkaluski Exp $
# $Name: Stable_0_16 $
#
# Module, which encapsulates logic of substituting where key entries
# with the actual values. 
# 
# $Log: KeySubst.pm,v $
# Revision 1.4  2006/09/17 19:22:37  pkaluski
# Cosmetic changes in help screen
#
# Revision 1.3  2006/09/10 18:31:53  pkaluski
# Selects are taken from files or STDIN (like with diamond operator).
#
# Revision 1.2  2006/04/09 15:42:19  pkaluski
# Small code clean-up. Each module has comprehensive POD
#
# Revision 1.1  2006/01/01 13:13:48  pkaluski
# Initial revision. Works.
#
#
########################################################################### 
package LRpt::KeySubst;
use strict;
use Getopt::Long;
use LRpt::JarReader;
require Exporter;

=head1 NAME

LRpt::KeySubst - A module for substituting where keys placeholders in
select templates

=head1 SYNOPSIS

  lks.pl --keys=keys.txt selects.txt 

=head1 DESCRIPTION

This module is a part of L<C<LRpt>|LRpt> (B<LReport>) library.
It is used for replacing I<where keys> placeholders with the actual value
in selects templates.
You should not use C<LRpt::KeySubst> module directly in your code.
Instead you should use B<lks.pl> tool, which is a simple wrapper
around the module. B<lks.pl> looks like this:

  use strict;
  use LRpt::KeySubst;
  
  wkey_subst( @ARGV );
  

=head1 COMMAND LINE OPTIONS

=over 4

=item --keys=name

Name of a file containing actual values for where keys to be put in 
select templates.

=item --help

Prints help screen.

=back

=cut


use vars qw( @EXPORT @ISA );
@ISA = qw(Exporter);
@EXPORT = qw(wkey_subst);


#
# For JarReader
#
our @keys_rules = ( { 'name' => 'name' },
                   { 'name' => 'key' } );

our @sel_rules = ( { 'name' => 'name' },
                  { 'name' => 'select' } );

=head1 METHODS

In this sections you will find a more or less complete listing of all
methods provided by the package. Note that the package itself is not
public so none of those methods are guaranteed to be maintained in future 
(including the package itself).

=cut

############################################################################

=head2 C<wkey_subst>

  wkey_subst( @ARGV );

Main function. @ARGV is processes by standard Getopt::Long module. Meaning 
of each switch is given in L<SYNOPSIS|"SYNOPSIS">.

=cut

############################################################################
sub wkey_subst
{
    local( @ARGV ) = @_;
    my $keys_file    = "";
    my $help         = "";

    GetOptions( "keys=s"    => \$keys_file,
                "help"      => \$help ); 
    if( !$keys_file or $help ){
        print_usage();
        exit( 1 );
    }

    my $key_jr = LRpt::JarReader->new( 'rules'    => \@keys_rules,
                                       'filename' => $keys_file );
    
    $key_jr->read_all();                               
    unshift( @ARGV, "-" ) unless @ARGV;
    while( my $file = shift( @ARGV ) ){
        open( SEL_FILE, "< $file" ) or die "Cannot open $file for reading: $!";
        my $select_jr = LRpt::JarReader->new( 'rules'    => \@sel_rules,
                                              'filehandle' => *SEL_FILE );
    
        $select_jr->read_all(); 

        my @sel_names = $select_jr->get_all_values_of( 'name' );
        foreach my $sel ( @sel_names ){
            my $section = $select_jr->get_section_with( 'name' => $sel );
            my $select = $section->{ 'select' };
            print "name: $sel\n";
            while( $select =~ /--(\w+)--/ ){
                my $key_name = $1;
                my $sect = $key_jr->get_section_with( 'name' => $key_name );
                if( !$sect ){
                     die "Key $key_name not defined or empty value given";
                }else{
                    my $value = $sect->{ 'key' };
                    $select =~ s/--$key_name--/$value/g;
                }
            }
            print "select: $select\n";
            print "%%\n";
        }
        close( SEL_FILE ) or die "Cannot close $file : $!"; 
    }
}

###########################################################################

=head2 C<print_usage>

  print_usage();

Prints usage text

=cut

###########################################################################
sub print_usage
{
    print "Usage:  $0 --help --keys=<name> filenames\n"; 
    print "\n";
    print "  --help          - prints this help screen\n";
    print "  --keys          - name of a file containing where key";
    print " definitions\n";
    print "  filenames       - names of files containing selects to be\n";
    print "                    parsed\n";
    exit( 0 );
}
1;


=head1 SEE ALSO

The project is maintained on Source Forge L<http://lreport.sourceforge.net>. 
You can find there links to some helpfull documentation like tutorial.

=head1 AUTHORS

Piotr Kaluski E<lt>pkaluski@piotrkaluski.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2004-2006 Piotr Kaluski. Poland. All rights reserved.

You may distribute under the terms of either the GNU General Public License 
or the Artistic License, as specified in the Perl README file. 

=cut

