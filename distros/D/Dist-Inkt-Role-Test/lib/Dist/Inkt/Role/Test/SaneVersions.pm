use 5.010001;
use strict;
use warnings;

package Dist::Inkt::Role::Test::SaneVersions;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Moose::Role;
use Types::Standard -types;
use version 0.86 qw(is_strict);
use namespace::autoclean;

with qw(Dist::Inkt::Role::Test);

after BUILD => sub {
	my $self = shift;
	
	$self->setup_prebuild_test(sub {
		require Path::Iterator::Rule;
		require Module::Metadata;
		
		my $project_version = $self->version;
		my $iter = Path::Iterator::Rule::->new->perl_module->iter(
			$self->rootdir->child("lib"),
		);
		my $die = 0;
		while (my $filename = $iter->())
		{
			my $info = Module::Metadata::->new_from_file($filename);
			my $module_version = $info->version;
			
			next if $module_version eq $project_version;
			
			++$die;
			!is_strict($module_version)
				? $self->log("Invalid version number: $filename ($module_version)")
				: $self->log("Different version number: $filename ($module_version)")
		}
		die "Versions not sane!" if $die;
	});
};

1;

