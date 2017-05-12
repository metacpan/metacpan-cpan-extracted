#-----------------------------------------------------------------
# MOSES::MOBY::Utils
# Author: Martin Senger <martin.senger@gmail.com>,
#         Edward Kawas <edward.kawas@gmail.com>
# For copyright and disclaimer see below.
#
# $Id: Utils.pm,v 1.7 2009/10/13 16:46:21 kawas Exp $
#-----------------------------------------------------------------

package MOSES::MOBY::Generators::Utils;
use File::Spec;
use strict;

# add versioning to this module
use vars qw /$VERSION/;
$VERSION = sprintf "%d.%02d", q$Revision: 1.7 $ =~ /: (\d+)\.(\d+)/;

=head1 NAME

MOSES::MOBY::Utils - what does not fit elsewhere

=head1 SYNOPSIS

 # find a file located somewhere in @INC
 use MOSES::MOBY::Generators::Utils;
 my $file = MOSES::MOBY::Generators::Utils->find_file ('resource.file');

=head1 DESCRIPTION

General purpose utilities.

=head1 AUTHORS

 Martin Senger (martin.senger [at] gmail [dot] com)
 Edward Kawas (edward.kawas [at] gmail [dot] com)

=head1 SUBROUTINES

=head2 find_file

Try to locate a file whose name is created from the C<$default_start>
and all elements of C<@names>. If it does not exist, try to replace
the C<$default_start> by elements of @INC (one by one). If neither of
them points to an existing file, go back and return the
C<$default_start> and all elements of C<@names> (even - as we know now
- such file does not exist).

There are two or more arguments: C<$default_start> and C<@names>.

=cut

my %full_path_of = ();

#-----------------------------------------------------------------
# find_file
#-----------------------------------------------------------------
sub find_file {
    my ($self, $default_start, @names) = @_;
    my $fixed_part = File::Spec->catfile (@names);
    return $full_path_of{ $fixed_part } if exists $full_path_of{ $fixed_part };

    my $result = File::Spec->catfile ($default_start, $fixed_part);
    if (-e $result) {
        $full_path_of{ $fixed_part } = $result;
        return $result;
    }

    foreach my $idx (0 .. $#INC) {
        $result = File::Spec->catfile ($INC[$idx], $fixed_part);
        if (-e $result) {
            $full_path_of{ $fixed_part } = $result;
            return $result;
        }
    }
    $result = File::Spec->catfile ($default_start, $fixed_part);
    $full_path_of{ $fixed_part } = $result;
    return $result;
}

1;

__END__
