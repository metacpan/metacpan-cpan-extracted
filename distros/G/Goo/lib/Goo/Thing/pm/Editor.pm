package Goo::Thing::pm::Editor;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Goo::Thing::pm::Editor.pm
# Description:  Edit a program interactively as fast as possible
#
# Date          Change
# -----------------------------------------------------------------------------
# 15/02/2005    Auto generated file
# 15/02/2005    Wanted to boost my code-cutting productivity and accuracy
#               Other things to add - renaming methods automatically changes
#               tests and 'link backs' from other modules
# 16/02/2005    Added deleteMethod method - this is a bit of a mind bend!
# 05/05/2005    Added a TypeLessTranslator to make typing quicker - think
#               phone txt 4 code! The idea is write shrt read looonger.
# 01/07/2005    Integrated new model of "Things"
# 01/08/2005    New command-based system caused massive refactoring of this
#               module. It used a whopping 16 other modules - crazy!
# 07/08/2005    Want to add ThereDocs back into the mix
# 17/08/2005    Added method: doTypeLessTranslation
# 17/08/2005    Added method: doThereDoc
# 02/11/2005    Now returns to the location of the original ThereDoc
#               Handles all actions a Thing can do: e > >  p > >  l > >
# 03/11/2005    Preparing for CPAN alpha release
#
###############################################################################

use strict;

use Goo::Object;
use Goo::Editor;
use Goo::Thing::pm::TypeChecker;
use Goo::Thing::pm::Perl5Editor;
#use Goo::Thing::pm::Perl6Editor;

use base qw(Goo::Object);


###############################################################################
#
# run - edit a program
#
###############################################################################

sub run {

    my ($this, $thing, $line_number) = @_;

    if (Goo::Thing::pm::TypeChecker::is_perl6($thing)) {
		# really simple editor
        Goo::Editor->new()->run($thing, $line_number);
    } else {
        Goo::Thing::pm::Perl5Editor->new()->run($thing, $line_number);		
    }

}

1;


__END__

=head1 NAME

Goo::Thing::pm::Editor - Edit a program interactively as fast as possible

=head1 SYNOPSIS

use Goo::Thing::pm::Editor;

=head1 DESCRIPTION



=head1 METHODS

=over

=item run

Delegate editing a Perl program to either a Goo::Editor or a Goo::Thing::pm::Perl5Editor.

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

