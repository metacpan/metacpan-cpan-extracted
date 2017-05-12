package Goo::Thing::pm::Profiler;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2004
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     Profiler.pm
# Description:  Create a synopsis of a program / module / script
#
# Date          Change
# -----------------------------------------------------------------------------
# 01/11/2004    Auto generated file
# 01/11/2004    Needed to work with the Goo
# 16/02/2005    Need to find out a range of lines for things
# 12/08/2005    Added method: getOption
# 12/08/2005    Added method: testingNow
# 24/08/2005    Added method: showHeader
#
###############################################################################

use strict;

use Goo::Thing::pm::TypeChecker;
use Goo::Thing::pm::Perl5Profiler;
use Goo::Thing::pm::Perl6Profiler;

use base qw(Goo::Object);


###############################################################################
#
# run - generate a profile of a program
#
###############################################################################

sub run {

    my ($this, $thing) = @_;

	if (Goo::Thing::pm::TypeChecker::is_perl6($thing)) {
        Goo::Thing::pm::Perl6Profiler->new()->run($thing);
    } else {
        Goo::Thing::pm::Perl5Profiler->new()->run($thing);

    }

}


1;


__END__

=head1 NAME

Goo::Thing::pm::Profiler - Show a profile of a Perl program

=head1 SYNOPSIS

use Goo::Thing::pm::Profiler;

=head1 DESCRIPTION



=head1 METHODS

=over

=item run

Delegate to Goo::Thing::pm::Perl6Profiler or Goo::Thing::pm::Perl5Profiler.

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

