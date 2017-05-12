package Kephra::API;
our $VERSION = '0.02';

use strict;
use warnings;

# passive part, just getter
sub settings     { Kephra::Config::Global::settings()      }
sub localisation { Kephra::Config::Localisation::strings() }
sub commands     { Kephra::CommandList::data()  }
sub events       { Kephra::EventTable::_table() }
sub menu         { Kephra::Menu::_all()    }
sub toolbar      { Kephra::ToolBar::_all() }

# active part
sub run_cmd      { 
	my @cmd;
	push @cmd, split /\s*,\s*/, $_ for @_;
	Kephra::CommandList::run_cmd_by_id($_) for @cmd;
}

1;

=head1 NAME

Kephra::API - Interface between Modules and Plugins

=head1 DESCRIPTION

=cut
