package Enbugger::trepan;
$Enbugger::trepan::VERSION = '2.016';
# COPYRIGHT AND LICENCE
#
# Copyright (C) 2007,2008 WhitePages.com, Inc. with primary
# development by Joshua ben Jore.
#
# This program is distributed WITHOUT ANY WARRANTY, including but not
# limited to the implied warranties of merchantability or fitness for
# a particular purpose.
#
# The program is free software.  You may distribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation (either version 2 or any later version)
# and the Perl Artistic License as published by O’Reilly Media, Inc.
# Please open the files named gpl-2.0.txt and Artistic for a copy of
# these licenses.


=head1 NAME

Enbugger::trepan - subclass for the extraordinary trepanning debugger
=cut


use strict;
use vars qw( @ISA @Symbols );
BEGIN { @ISA = 'Enbugger' }


=head1 OVERRIDEN METHODS

=over

=item CLASS-E<gt>_load_debugger

=cut

sub _load_debugger {
    my ( $class ) = @_;

    $class->_compile_with_nextstate();
    require Devel::Trepan::Core;
    $^P |= 0x73f;
    $class->_compile_with_dbstate();

    $class->init_debugger;

    return;
}





=item CLASS-E<gt>_stop ( [OPTION_HASH_REF] )

Set to stop at the next stopping point. OPTIONS_HASH_REF is an
optional hash reference which can be used to things in the debugger.

=cut

1 if $DB::signal;
sub _stop {

    my ($self, $opts) = @_;
    $Devel::Trepan::Core::dbgr->awaken($opts);

    # trepan looks for these to stop.
    $DB::in_debugger = 1;
    $DB::signal = 2;
    # Use at least the default debug flags and 
    # eval string saving.
    $^P |= 0x73f;
    $DB::event = 'debugger-call';
    my ($pkg, $filename, $line) = caller;
    if ($filename =~ /^\(eval \d+\)/) {
	@DB::dbline = map "$_\n", split(/\n/, $DB::eval_string);
    }
    $DB::in_debugger = 0;
    return;
}





=item CLASS-E<gt>_write( TEXT )

=cut

1 if $DB::OUT;
sub _write {

    for my $c (@DB::clients) {
	$c->output(@_);
    }
    return;
}





=back

=cut




# Load up a list of symbols known to be associated with this
# debugger. Enbugger, the base class will use this to guess at which
# debugger has been loaded if it was loaded prior to Enbugger being
# around.
1 if %Enbugger::RegisteredDebuggers;
$Enbugger::RegisteredDebuggers{trepan}{symbols} = [qw[
    DB
    subs
    eval_with_return
    save
]];

## Local Variables:
## mode: cperl
## mode: auto-fill
## cperl-indent-level: 4
## End:
