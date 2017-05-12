use strict;
use warnings FATAL => 'all';

package HTML::Tested::ClassDBI::Field::Column;
use Carp;

sub verify_arg {
	my ($class, $root, $w, $arg) = @_;
	my $gr = $w->options->{cdbi_group};
	confess($w->name . ": $arg - unknown column. Wrong cdbi_bind usage")
		unless $root->_CDBI_Class->{$gr}->find_column($arg);
	$root->_PrimaryFields->{$gr}->{ $w->name } = [ $arg ]
		if $w->options->{cdbi_primary};
}

sub bless_arg {
	my ($class, $root, $w, $arg) = @_;
	$class->verify_arg($root, $w, $arg);
	return bless([ $arg ], $class);
}

sub get_column_value {
	my ($self, $cdbi) = @_;
	my $c = $self->column_name;
	return exists $cdbi->{$c} ? $cdbi->{$c} : $cdbi->$c;
}

sub column_name { return shift()->[0]; }

sub update_column {
	my ($self, $setter, $root, $name) = @_;
	$setter->($self->[0], $root->$name) unless $root->ht_get_widget_option(
		$name, "cdbi_readonly");
}

my %_dt_fmts = (date => '%x', 'time' => '%X', timestamp => '%c');

sub setup_datetime_from_info {
	my ($self, $w, $info) = @_;
	return unless $info->{type};
	my ($t) = ($info->{type} =~ /^(\w+)/);
	$w->setup_datetime_option($_dt_fmts{$t}) if ($_dt_fmts{$t});
}

sub setup_type_info {
	my ($self, $root, $w, $info) = @_;
	($info ||= $root->pg_column_info($self->[0])) or return;
	$w->options->{cdbi_column_info} = $info;
	$w->options->{is_integer} = 1 if ($info->{type} eq 'integer'
			|| $info->{type} eq 'smallint');
	$w->push_constraint([ 'defined', '' ]) unless 
		($w->options->{cdbi_readonly} || $info->{is_nullable});
	$self->setup_datetime_from_info($w, $info);
}

package HTML::Tested::ClassDBI::Field::Primary;
use base 'HTML::Tested::ClassDBI::Field::Column';

sub verify_arg {
	my ($class, $root, $w, $arg) = @_;
	my @pc = map { $_->name } $root->_CDBI_Class->{
			$w->options->{cdbi_group} }->primary_columns;
	$root->_PrimaryFields->{ $w->options->{cdbi_group} }
		->{ $w->name } = \@pc;
	$root->ht_set_widget_option($w->name, "is_sealed", 1)
		unless exists $w->options->{is_sealed};
	$root->ht_set_widget_option($w->name, "cdbi_readonly", 1)
		unless exists $w->options->{cdbi_readonly};
}

sub get_column_value {
	my ($self, $cdbi) = @_;
	my @pvals = map { $cdbi->$_ } $cdbi->primary_columns;
	return join('_', @pvals);
}

sub update_column {}

sub setup_type_info {
	my ($self, $root, $w) = @_;
	my @pc = $root->primary_columns;
	return if @pc > 1; 
	$self->SUPER::setup_type_info($root, $w, $root->pg_column_info($pc[0]));
}

package HTML::Tested::ClassDBI::Field::Array;

sub bless_arg {
	my ($class, $root, $w, $arg) = @_;
	return bless([ map { HTML::Tested::ClassDBI::Field->do_bless_arg(
				$root, $w, $_) } @$arg ]);
}

sub get_column_value {
	my ($self, $cdbi) = @_;
	return [ map { $_->get_column_value($cdbi) } @$self ];
}

sub update_column {}

sub setup_type_info {
	my ($self, $root, $w) = @_;
	for (my $i = 0; $i < @$self; $i++) {
		my $iopts = $w->options->{$i} || {};
		$self->[$i]->setup_datetime_from_info($w, $iopts);
		$w->options->{$i} = $iopts if %$iopts;
	}
}

package HTML::Tested::ClassDBI::Field;
use HTML::Tested::ClassDBI::Upload;

sub do_bless_arg {
	my ($class, $root, $w, $arg) = @_;
	if (ref($arg) eq 'ARRAY') {
		$class .= "::Array";
	} elsif ($arg eq 'Primary') {
		$class .= "::Primary";
	} else {
		$class .= "::Column";
	}
	return $class->bless_arg($root, $w, $arg);
}

sub new {
	my ($class, $root, $w) = @_;
	return HTML::Tested::ClassDBI::Upload->new($root
			, $w->options->{cdbi_upload} || $w->name)
		if (exists $w->options->{cdbi_upload});
	return HTML::Tested::ClassDBI::Upload->new($root
			, $w->options->{cdbi_upload_with_mime} || $w->name, 1)
		if (exists $w->options->{cdbi_upload_with_mime});
	return unless exists $w->options->{cdbi_bind};

	my $arg = $w->options->{cdbi_bind} || $w->name;
	return $class->do_bless_arg($root, $w, $arg);
}

1;
