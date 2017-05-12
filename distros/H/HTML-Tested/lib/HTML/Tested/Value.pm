=head1 NAME

HTML::Tested::Value - Base class for most HTML::Tested widgets.

=head1 DESCRIPTION

This class provides the most basic HTML::Tested widget - simple value to be
output in the template.

=head1 METHODS

=cut

use strict;
use warnings FATAL => 'all';

package HTML::Tested::Value;
use HTML::Entities;
use HTML::Tested::Seal;
use Carp;
use Data::Dumper;

sub setup_datetime_option {
	my ($self, $dto, $opts) = @_;
	$opts ||= $self->options;
	eval "use DateTime::Format::Strptime";
	confess "Unable to use DateTime::Format::Strptime: $@" if $@;
	$dto = { pattern => $dto } unless ref($dto);
	$opts->{is_datetime} = DateTime::Format::Strptime->new($dto);
	$self->compile;
}

=head2 $class->new($parent, $name, %opts)

Creates new L<HTML::Tested::Value> named C<$name> at parent class C<$parent>.

C<%opts> is a hash containing various options changing behaviour of this widget.

See OPTIONS section for description of available options.

=cut
sub new {
	my ($class, $parent, $name, %opts) = @_;
	my $self = bless({ name => $name, _options => \%opts
			, constraints => [], validators => [] }, $class);
	my $cs = $opts{constraints} || [];
	$self->push_constraint($_) for @$cs;

	my $dto = $self->options->{is_datetime};
	$self->setup_datetime_option($dto) if $dto;
	return $self;
}

sub _get_option {
	my ($self, $caller, $wname, $opname) = @_;
	if ($caller && ref($caller)) {
		my $n = "__ht__$wname\_$opname";
		return $caller->{$n} if exists $caller->{$n};
	}
	return $self->options->{$opname};
}

=head2 $widget->name

Returns the name of the widget.

=cut
sub name { return shift()->{name}; }

=head2 $widget->options

Returns hash of options assigned to this widget. See OPTIONS section for
description of available options.

=cut
sub options { return shift()->{_options}; }

=head2 $widget->value_to_string($name, $val, $caller, $stash)

This function is called from C<render> to return final string which will be
rendered into stash. For HTML::Tested::Value it simply returns $val.

C<$caller> is the object calling this function. C<$stash> is read-only hash of
the values accummulated so far.

=cut
sub value_to_string {
	my ($self, $name, $val) = @_;
	return $val;
}

=head2 $widget->encode_value($val)

Uses HTML::Entities to encode $val.

=cut
sub encode_value {
	my ($self, $val) = @_;
	confess ref($self) . "->" . $self->name . ": Non scalar value $val\n"
		. Dumper($val) if ref($val);
	return encode_entities($val, '<>&"' . "'");
}

sub get_default_value {
	my ($self, $caller, $n) = @_;
	my $func = $caller->{"__$n\_defval"} || $self->{__defval};
	return $func->($self, $n, $caller);
}

=head2 $widget->get_value($caller, $id)

It is called from $widget->render to get the value to render. If the value
is C<undef> C<get_default_value> will be used to get default value for the
widget.

=cut
sub get_value {
	my ($self, $caller, $id, $n) = @_;
	return $caller->{$n} // $self->get_default_value($caller, $n);
}

=head2 $widget->seal_value($value, $caller)

If C<is_sealed> option is used, this function is called from $widget->render to
seal the value before putting it to stash.  See HTML::Tested::Seal for sealing
description.

This function maintains cache of sealed values in caller. Thus promising that
the same value will map to the same id during request.

=cut
sub seal_value {
	my ($self, $val, $caller) = @_;
	return HTML::Tested::Seal->instance->encrypt($val);
}

sub transform_value {
	my ($self, $caller, $val, $n) = @_;
	my $func = $caller->{"__$n\_transform"} || $self->{__transform};
	return $func->($self, $val, $caller, $n);
}

sub prepare_value {
	my ($self, $caller, $id, $n) = @_;
	my $val = $self->get_value($caller, $id, $n);
	return undef unless defined($val);
	return $self->transform_value($caller, $val, $n);
}

sub _render_i {
	my ($self, $caller, $stash, $id, $n) = @_;
	my $val = $self->prepare_value($caller, $id, $n);
	return unless defined($val);
	return $self->value_to_string($id, $val, $caller, $stash);
}

=head2 $widget->render($caller, $stash, $id, $name)

Renders widget into $stash. For HTML::Tested::Value it essentially means
assigning $stash->{ $name } with $widget->get_value.

=cut
sub render {
	my ($self, $caller, $stash, $id, $n) = @_;
	my $func = $caller->{"__$n\_render"} || $self->{__render};
	my $res = $func->($self, $caller, $stash, $id, $n);
	$stash->{$n} = $res if defined($res);
}

sub bless_from_tree { return $_[1]; }

=head2 $widget->push_constraint($constraint)

C<$constraint> should be ARRAY reference with the following format:

[ TYPE, OP, COOKIE ]

where C<TYPE> is type of the constraint, C<OP> is the operation to be done on
the constraint and cookie is optional method for the application to recognize
specific constraint.

Available types are:

=over

=item C<regexp>

With OP being regexp string (or C<qr//> value) (e.g. [ regexp => '\d+' ] or [
regexp => qr/\d+/ ]).

=item C<defined>

Ensures that the value is defined. C<OP> doesn't matter here
(e.g. [ defined => '' ]).

=item C<any user-defined string>

Any user defined constraint - second parameter should be function to call.
It gets the value and the caller as the arguments.

For example [ 'my_foo' => sub { my ($v, $caller) = @_; return is_ok? } ].

=back

=cut
sub push_constraint {
	my ($self, $c) = @_;
	my $func;
	push @{ $self->{constraints} }, $c;
	confess "Constraint should be of [ TYPE, OP ] format"
			unless ($c && ref($c) eq 'ARRAY');
	if ($c->[0] eq 'regexp') {
		my $rexp = $c->[1];
		$func = sub {
			my $v = shift;
			return defined($v) ? $v =~ /$rexp/ : undef;
		};
	} elsif ($c->[0] eq 'defined') {
		$func = sub { return defined($_[0]); };
	} elsif ($c->[1]) {
		$func = $c->[1];
	} else {
		confess "Unknown type " . $c->[0] . " found!\n";
	}
	push @{ $self->{validators} }, $func if $func;
}

=head2 $widget->validate($value, $caller)

Validate value returning list of failed constraints in the format specified
above.

I.e. the C<$value> is "constraint-clean" when C<validate> returns empty list.

Validate is disabled if C<no_validate> widget option is set.

=cut
sub validate {
	my ($self, $caller) = @_;
	my $n = $self->name;
	my $val = $caller->$n;
	return () if $caller->ht_get_widget_option($n, "no_validate");
	return ([ $n, 'integer' ]) if (defined($val)
			&& $caller->ht_get_widget_option($n, "is_integer")
			&& $val !~ /^\d+$/);
	my $vs = $self->{validators};
	my @res;
	for (my $i = 0; $i < @$vs; $i++) {
		next if $vs->[$i]->($val, $caller);
		push @res, [ $n, @{ $self->{constraints}->[$i] } ];
	}
	return @res;
}

sub unseal_value {
	my ($self, $val, $caller) = @_;
	return HTML::Tested::Seal->instance->decrypt($val);
}

sub merge_one_value { shift()->absorb_one_value(@_); }

=head2 $widget->absorb_one_value($parent, $val, @path)

Parses C<$val> and puts the result into C<$parent> object. C<@path> is used for
widgets aggregating other widgets (such as C<HTML::Tested::List>).

=cut
sub absorb_one_value {
	my ($self, $root, $val, @path) = @_;
	return if $self->options->{is_trusted};
	$val = $self->unseal_value($val, $root)
			if $self->options->{"is_sealed"};
	my $dtfs = $self->options->{"is_datetime"};
	$val = $dtfs->parse_datetime($val) if $dtfs;
	$root->{ $self->name } = (defined($val) && $val eq ""
			&& !$self->options->{keep_empty_string}) ? undef : $val;
}

sub _set_callback {
	my ($self, $caller, $n, $what, $func) = @_;
	my $obj = ($caller && ref($caller)) ? $caller : $self;
	my $key = ($caller && ref($caller)) ? "__$n\_$what" : "__$what";
	$obj->{$key} = $func;
}

sub _trans_datetime {
	my ($self, $dtfs, $val, $caller, $n) = @_;
	return $dtfs->format_datetime($val) if $val;
}

sub compile {
	my ($self, $caller) = @_;
	my $n = $self->name;
	my $trans = $self->can('encode_value');
	my $func = $self->can('_render_i');
	my $defval = sub { return '' };
	if ($self->_get_option($caller, $n, 'is_disabled')) {
		$func = $defval;
	} elsif (my $dtfs = $self->_get_option($caller, $n, "is_datetime")) {
		$trans = sub { return shift()->_trans_datetime($dtfs, @_); };
	} elsif ($self->_get_option($caller, $n, "is_sealed")) {
		$trans = sub {
			my $this = shift;
			my $val = shift;
			$val = $this->seal_value($val, @_);
			return $this->encode_value($val, @_);
		};
	} elsif ($self->_get_option($caller, $n, "is_trusted")) {
		$trans = sub { return $_[1]; };
	}

	my $dval = $self->_get_option($caller, $n, "default_value");
	if (defined($dval)) {
		$defval = ref($dval) eq 'CODE' ? $dval : sub { return $dval; };
	} elsif ($self->_get_option($caller, $n, "skip_undef")) {
		$defval = sub { return undef; };
	}

	$self->_set_callback($caller, $n, 'render', $func);
	$self->_set_callback($caller, $n, 'transform', $trans);
	$self->_set_callback($caller, $n, 'defval', $defval);
}

1;

=head1 OPTIONS

Options can be used to customize widget behaviour. Each widget is free to
define its own options. They can be set per class or per object using
C<ht_set_widget_option>. The options can be retrieved using
C<ht_get_widget_option>.

C<HTML::Tested::Value> defines the following options:

=over

=item is_sealed

The widget value is encrypted before rendering it. The value is decrypted from
the request parameters in transparent fashion.

=item is_disabled

The widget is disabled: it is rendered as blank value.

=item default_value

Default value for the widget. It is rendered if current widget value is
C<undef>.

=item skip_undef

Normally, if widget value is C<undef>, the widget is rendered as blank value.
When this option is set the widget will not appear in the stash at all.

=item constraints

Array reference containing widget value constraints. See C<push_constraint>
documentation for the individual entry format.

=item is_trusted

Do not perform the escaping of special characters on the value. Improperly
setting this option may result in XSS security breach.

=item is_integer

Ensures that the value is integer. 

=back

=head1 AUTHOR

Boris Sukholitko (boriss@gmail.com)
	
=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

HTML::Tested

=cut

