package Exporter::Extensible::Compat;
use strict;
use warnings;
require MRO::Compat if "$]" < '5.009005';

=head1 DESCRIPTION

This module provides a compatibility layer for perl 5.10 and 5.8.
The module itself is not used at all; loading it applies monkey patches
to Exporter::Extensible.  Do not use this module, as it gets loaded
automatically by Exporter::Extensible if needed.

The main problem solved here is that perl earlier than 5.12 does not install
a sub into the package stash until after calling MODIFY_CODE_ATTRIBUTES, so
the :Export attributes can't resolve to a name until later.

There isn't any good spot in the API of Exporter::Extensible to put this
delayed processing, so about the only way to fix is to just perform it
before any public API method, and at the end of the scope.

=cut

my $process_attr= \&Exporter::Extensible::_exporter_process_attribute;
our @_pending_attr= ();
{
	no warnings 'redefine';
	*Exporter::Extensible::_exporter_process_attribute= *_exporter_process_attribute;
	# Other methods that might be called before end of scope
	for (qw(
		FETCH_CODE_ATTRIBUTES MODIFY_CODE_ATTRIBUTES import exporter_setup
		exporter_export exporter_register_tag_members exporter_register_generator
		exporter_register_option exporter_get_inherited exporter_also_import
		exporter_autoload_tag exporter_get_tag exporter_autoload_symbol
		exporter_register_symbol
	)) {
		my $method= Exporter::Extensible->can($_);
		eval 'sub Exporter::Extensible::'.$_.' {
				_process_pending_attrs()
					if @_pending_attr;
				goto $method;
			}
			1'
			or die $@;
	};
}

sub _queue_attr {
	my ($class, $coderef, $attr)= @_;
	if (!@_pending_attr) {
		require B::Hooks::EndOfScope;
		B::Hooks::EndOfScope::on_scope_end(\&_process_pending_attrs);
	}
	push @_pending_attr, [ @_ ];
}

sub _process_pending_attrs {
	while (my $call= shift @_pending_attr) {
		$process_attr->(@$call);
	}
}

sub _exporter_process_attribute {
	my $ret;
	if (eval { $ret= $process_attr->(@_); 1 }) {
		return $ret;
	}
	elsif ($@ =~ /determine export name/) {
		_queue_attr(@_);
		return 1;
	}
	else {
		die $@;
	}
}

1;
