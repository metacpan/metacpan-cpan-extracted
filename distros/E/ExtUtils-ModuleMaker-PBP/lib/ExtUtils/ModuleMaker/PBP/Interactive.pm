package ExtUtils::ModuleMaker::PBP::Interactive;
# as of 04-05-2006
use strict;
local $^W = 1;
BEGIN {
    use base qw(
        ExtUtils::ModuleMaker::PBP
        ExtUtils::ModuleMaker::Interactive
        ExtUtils::ModuleMaker
    );
    use vars qw ( $VERSION );
    $VERSION = '0.09';
}
use Carp;
use Data::Dumper;


1;

################### DOCUMENTATION ###################

=head1 NAME

ExtUtils::ModuleMaker::PBP::Interactive - Hold methods used in F<mmkrpbp>

=head1 SYNOPSIS

    use ExtUtils::ModuleMaker::PBP::Interactive;

    ...  # ExtUtils::ModuleMaker::new() called here

    $MOD->run_interactive() if $MOD->{INTERACTIVE};

    ...  # ExtUtils::ModuleMaker::complete_build() called here

    $MOD->closing_message();

=head1 DESCRIPTION

This package exists solely to hold declarations of variables and
methods used in F<mmkrpbp>, the command-line utility which is
the easiest way of accessing the functionality of Perl extension
ExtUtils::ModuleMaker.

=head1 METHODS

=head2 C<run_interactive()>

This method drives the menus which make up F<mmkrpbp>'s interactive mode.
Once it has been run, F<mmkrpbp> calls
C<ExtUtils::ModuleMaker::complete_build()> to build the directories and files
requested.

=head2 C<closing_message()>

Prints a closing message after C<complete_build()> is run.  Can be commented
out without problem.  Could be subclassed, and -- in a future version --
probably will be with an optional printout of files created.

=head1 AUTHOR

James E Keenan.  CPANID:  JKEENAN.

=head1 COPYRIGHT

Copyright (c) 2005 James E. Keenan.  All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

F<ExtUtils::ModuleMaker::PBP>, F<mmkrpbp>, F<ExtUtils::ModuleMaker>,
F<modulemaker>.

=cut

