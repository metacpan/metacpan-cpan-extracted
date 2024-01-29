package Ixchel::Actions::list_actions;

use 5.006;
use strict;
use warnings;
use Module::List qw(list_modules);
use base 'Ixchel::Actions::base';

=head1 NAME

Ixchel::Actions::list_actions - Lists the various actions with a short description.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 CLI SYNOPSIS

ixchel -a list_actions

=head1 CODE SYNOPSIS

    my $results $ixchel->action(action=>'list_actions', opts=>{np=>1}

    if ($results->{ok}) {
        print $results->{status_text};
    }else{
        die('Action errored... '.joined("\n", @{$results->{errors}}));
    }

=head1 FLAGS

=head2 --np

Don't print the the filled in template.

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and the results.
    .ok :: Set to zero if any of the above errored.

=cut

sub new_extra { }

sub action_extra {
	my $self = $_[0];

	my $actions = list_modules( "Ixchel::Actions::", { list_modules => 1 } );

	foreach my $action ( sort( keys( %{$actions} ) ) ) {
		if ( $action ne 'Ixchel::Actions::base' ) {
			my $action_name = $action;
			$action_name =~ s/^Ixchel\:\:Actions\:\://;

			my $short;
			my $to_eval = 'use ' . $action . '; $short=' . $action . '->short;';
			eval($to_eval);
			if ( !defined($short) ) {
				$short = '';
			}
			my $new_line = $action_name . ' : ' . $short . "\n";
			$self->{results}{status_text} = $self->{results}{status_text} . $new_line;
			if ( !$self->{opts}{np} ) {
				print $new_line;
			}
		} ## end if ( $action ne 'Ixchel::Actions::base' )
	} ## end foreach my $action ( sort( keys( %{$actions} ) ...))
} ## end sub action_extra

sub short {
	return 'Lists the available actions.';
}

sub opts_data {
	return 'np
'
		;
}

1;
