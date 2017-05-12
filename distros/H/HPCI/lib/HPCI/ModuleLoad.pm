package HPCI::ModuleLoad;

# safe Perl
use warnings;
use strict;
use Carp;
# use PerlBL;

use Moose::Role;

our @default_modules;

has 'modules_to_load' => (
	is        => 'ro',
	isa       => 'ArrayRef[Str]',
	predicate => '_has_modules_to_load'
);

sub _final_modules_to_load {
	my $self = shift;
	my @mtl  = (
		@default_modules,
		( $self->_has_modules_to_load ? @{ $self->modules_to_load } : () )
	);
	return [
		map {
			if (m{/}) {
				$_;
			}
			else {  # TODO: BoutrosLab specific code here - move it to local config
				my @versions =
					split( /\n/,
qx { /oicr/local/Modules/default/bin/modulecmd sh show $_ 2>&1 }
				);
				scalar(@versions) > 2 && $versions[1] =~ m{/([^/]*):$}
					? "$_/$1"
					: $_;
			}
		} @mtl
	];
}

before 'BUILD' => sub {
	my $self = shift;

	my $cmds = $self->_command_expansion_methods;
	push @$cmds, 'print_module_load';
};

sub print_module_load {
	my $self = shift;
	my $fh   = shift;
	my $mods = $self->_final_modules_to_load;
	for my $mod (@$mods) {
		print $fh "module load $mod\n";
	}
}

1;
