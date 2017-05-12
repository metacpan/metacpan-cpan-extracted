#!/usr/bin/perl

package Goo::Thing::pm::TypeChecker;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     TypeChecker.pm
# Description:  What type of pm file is this? Perl6? Perl5?
#
# Date          Change
# ----------------------------------------------------------------------------
# 01/08/2005    Factored out of ProgramEditor as part of the new Goo
#
##############################################################################


###############################################################################
#
# is_perl6 - check if this Thing is Perl6?
#
###############################################################################

sub is_perl6 {

    my ($thing) = @_;

	# Goo::Prompter::trace(caller() . " " . $thing->to_string());

	# check the #!/shebang/line?
    return 1 if ($thing->get_file() =~ /\#.*\/pugs/);

	# if it's a class assume Perl6
    return 1 if ($thing->get_file() =~ /^class/);

	# use v6
    return 1 if ($thing->get_file() =~ /use\s+v6/);

	# what about the location?
    return 1 if ($thing->get_full_path() =~ /perl6/);

	return 0;

}


1;


__END__

=head1 NAME

Goo::Thing::pm::TypeChecker - What type of pm file is this? Perl6? Perl5?

=head1 SYNOPSIS

use Goo::Thing::pm::TypeChecker;

=head1 DESCRIPTION

=head1 METHODS

=over

=item is_perl6

check if this Thing is Perl6 by inspecting the #/shebang/line and whether or not
is uses: use v6;

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

