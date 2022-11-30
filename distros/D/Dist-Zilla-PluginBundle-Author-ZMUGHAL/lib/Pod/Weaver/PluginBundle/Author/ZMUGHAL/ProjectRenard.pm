use strict;
use warnings;
package Pod::Weaver::PluginBundle::Author::ZMUGHAL::ProjectRenard;
# ABSTRACT: A plugin bundle for pod woven for Project Renard
$Pod::Weaver::PluginBundle::Author::ZMUGHAL::ProjectRenard::VERSION = '0.006';
use Pod::Weaver::Config::Assembler;

our $PB_NAME = '@Author::ZMUGHAL::ProjectRenard';

sub _exp { Pod::Weaver::Config::Assembler->expand_package($_[0]) }

sub mvp_bundle_config {
	return (
		# [@CorePrep]
		[ "$PB_NAME/CorePrep"       , _exp('@CorePrep')       , {} ],
		# [-Transformer]
		# transformer = List
		[ "$PB_NAME/TransList"      , _exp('-Transformer')    , { transformer => 'List' }    ],
		# [-SingleEncoding]
		[ "$PB_NAME/SingleEncoding" , _exp('-SingleEncoding') , {} ],

		# [Region  / header]
		_region('Header'),
		# [Name]
		[ "$PB_NAME/Name"           , _exp('Name')     , {} ],
		# [Version]
		[ "$PB_NAME/Version"        , _exp('Version')  , {} ],

		### Prelude
		# [Region  / prelude]
		_region('Prelude'),
		# [Generic / SYNOPSIS]
		_generic("Synopsis"),
		# [Generic / DESCRIPTION]
		_generic("Description"),
		# [Generic / OVERVIEW]
		_generic("Overview"),

		### Object hierarchy
		# [Extends]
		[ "$PB_NAME/Extends"        , _exp('Extends')  , {} ],
		# [Consumes]
		[ "$PB_NAME/Consumes"       , _exp('Consumes') , {} ],

		### Package members

		# [Collect / FUNCTIONS]
		# command = func
		_collect("Functions", 'func', 'FUNCTIONS'),

		# [Collect / TYPES]
		# command = type
		_collect("Types", 'type', 'TYPES'),

		# [Collect / METHODS REQUIRED BY THIS ROLE]
		# command = requires
		_collect("RoleRequires", 'requires', 'METHODS REQUIRED BY THIS ROLE'),

		# [Collect / ATTRIBUTES]
		# command = attr
		_collect("Attributes", 'attr', 'ATTRIBUTES'),

		# [Collect / CLASS METHODS]
		# command = classmethod
		_collect("ClassMethods", 'classmethod', 'CLASS METHODS'),

		# [Collect / METHODS]
		# command = method
		_collect("Methods", 'method', 'METHODS'),

		# [Collect / CALLBACKS]
		# command = callback
		_collect("Callbacks", 'callback', 'CALLBACKS'),

		# [Collect / SIGNALS]
		# command = signal
		_collect('Signals', 'signal', 'SIGNALS'),

		### Rest
		# [Leftovers]


		[ "$PB_NAME/Leftovers"       , _exp('Leftovers') , {} ],

		# [Region  / postlude]
		_region('Postlude'),
		# [Authors]
		[ "$PB_NAME/Authors"       , _exp('Authors') , {} ],
		# [Legal]
		[ "$PB_NAME/Legal"       , _exp('Legal') , {} ],
	);
}

sub _region {
	my ($name) = @_;

	return [
		"$PB_NAME/@{[ ucfirst $name ]}",
		_exp('Region'),
		{ region_name => lc $name }
	];
}

sub _generic {
	my ($name) = @_;

	return [
		"$PB_NAME/$name",
		_exp('Generic'),
		{
			header => uc $name
		}
	];
}
sub _collect {
	my ($name, $command, $header) = @_;

	return [
		"$PB_NAME/$name",
		_exp('Collect'),
		{
			command => $command,
			header => $header
		}
	];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::PluginBundle::Author::ZMUGHAL::ProjectRenard - A plugin bundle for pod woven for Project Renard

=head1 VERSION

version 0.006

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
