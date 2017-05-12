#!perl
#
# Documentation, copyright and license is at the end of this file.
#
package  File::SubPM;

use 5.001;
use strict;
use warnings;
use warnings::register;

use File::Where;

use vars qw($VERSION $DATE);
$VERSION = '1.12';
$DATE = '2004/05/04';

#####
# Determine the output generator program modules
#
sub sub_modules
{
   my (undef,$base_file, @dirs) = @_;
   File::Where->program_modules($base_file,'file',@dirs);
}

#####
# Determine if a module is valid
#
sub is_module
{
   shift;
   File::Where->is_module(@_);
}

1

__END__

=head1 NAME

File::SubPM - Obsolete. Superceded by C<File::Where> 1.16.

=head1 SYNOPSIS

 use File::SubPM

 @sub_modules   = File::SubPM->sub_modules($base_file, @dirs);
 $module        = File::SubPM-->is_module($module, @modules);

=head1 DESCRIPTION

This module is obsolete and superceded by the C<File::Where> 1.16.

=head1 SUBROUTINES

=head2 is_module method

 $driver = File::SubPM->is_module($module, @repositories)

The C<is_module> subroutine determines if a I<$module> is present
in a list of modules C<@modules>. The detemination is case insensitive and
only the leading characters are needed.

=head2 sub_modules method

 @sub_modules = File::SubPM->sub_modules($base_file, @dirs)

Returns a list of modules in the directory defined by C<$base_file>, C<@dirs>.

=head1 REQUIREMENTS

The C<File::SubPM> subroutines shall be replaced by the
appropriate C<File::Where> subroutine whenever a 
C<File::PM2File> subroutine needs a revision as follows:

 File::SubPM->is_module()                    File::Where->is_module()
 File::SubPM->sub_modules($base_file, @dir)  File::Where->program_modules($base_file,'',@dirs)

=head1 DEMONSTRATION

 #########
 # perl SubPM.d
 ###

~~~~~~ Demonstration overview ~~~~~

The results from executing the Perl Code 
follow on the next lines as comments. For example,

 2 + 2
 # 4

~~~~~~ The demonstration follows ~~~~~

     use File::Spec;

     use File::Package;
     my $fp = 'File::Package';

     my $sm = 'File::SubPM';
     my $loaded = '';

 ##################
 # Load UUT
 # 

 my $errors = $fp->load_package( $sm )
 $errors

 # ''
 #

 ##################
 # sub_modules
 # 

 my @drivers = sort $sm->sub_modules( __FILE__, '_Drivers_' )
 join (', ', @drivers)

 # 'Driver, Generate, IO'
 #

 ##################
 # is_module
 # 

 $sm->is_module('dri', @drivers )

 # 'Driver'
 #

=cut

### end of file ###