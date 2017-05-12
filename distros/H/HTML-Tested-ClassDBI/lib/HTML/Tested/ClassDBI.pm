=head1 NAME

HTML::Tested::ClassDBI - Enhances HTML::Tested to work with Class::DBI

=head1 SYNOPSIS

  package MyClass;
  use base 'HTML::Tested::ClassDBI';
  
  __PACKAGE__->ht_add_widget('HTML::Tested::Value'
		  , id => cdbi_bind => "Primary");
  __PACKAGE__->ht_add_widget('HTML::Tested::Value'
		  , x => cdbi_bind => "");
  __PACKAGE__->ht_add_widget('HTML::Tested::Value::Upload'
  	, x => cdbi_upload => "largeobjectoid");
  __PACKAGE__->bind_to_class_dbi('MyClassDBI');

  # And later somewhere ...
  # Query and load underlying Class::DBI:
  my $list = MyClass->query_class_dbi(search => x => 15);

  # or sync it to the database:
  $obj->cdbi_create_or_update;
	
=head1 DESCRIPTION

This class provides mapping between Class::DBI and HTML::Tested objects.

It inherits from HTML::Tested. Widgets created with C<ht_add_widget> can have
additional C<cdbi_bind> property.

After calling C<bind_to_class_dbi> you would be able to automatically
synchronize between HTML::Tested::ClassDBI instance and underlying Class::DBI.

=cut

use strict;
use warnings FATAL => 'all';

package HTML::Tested::ClassDBI;
use base 'HTML::Tested';
use Carp;
use HTML::Tested::ClassDBI::Field;
use Data::Dumper;

my @_cdata = qw(_CDBI_Class _PrimaryFields _Field_Handlers _PrimaryKey);
__PACKAGE__->mk_classdata($_) for @_cdata;

our $VERSION = '0.23';

sub class_dbi_object { shift()->class_dbi_object_gr('_CDBIM_', @_); }

sub class_dbi_object_gr {
	my ($self, $gr, $val) = @_;
	return $self->{_class_dbi_objects}->{$gr} if @_ == 2;
	$self->{_class_dbi_objects}->{$gr} = $val;
}

sub cdbi_bind_from_fields {
	my ($class, $gr) = @_;
	for my $v (@{ $class->Widgets_List }) {
		my $wgr = $v->options->{cdbi_group} || '_CDBIM_';
		$v->options->{cdbi_group} = $wgr;
		next unless $wgr eq $gr;
		my $f = HTML::Tested::ClassDBI::Field->new($class, $v, $gr)
				or next;
		$class->_Field_Handlers->{ $v->options->{cdbi_group} }
			->{$v->name} = $f;
	}
}

sub CDBI_Class { return shift()->_CDBI_Class->{_CDBIM_} }
sub PrimaryFields { return shift()->_PrimaryFields->{_CDBIM_} }
sub Field_Handlers { return shift()->_Field_Handlers->{_CDBIM_} }
sub PrimaryKey { return shift()->_PrimaryKey->{_CDBIM_} }

=head1 METHODS

=head2 $class->bind_to_class_dbi($cdbi_class)

Binds $class to $cdbi_class, by going over all fields declared with C<cdbi_bind>
or C<cdbi_upload> option.

C<cdbi_bind> option value could be one of the following:
name of the column, empty string for the column named the same as field or for
array of columns.

C<cdbi_upload> can be used to upload file into the database. Uploaded file is
stored as PostgreSQL's large object. Its OID is assigned to the bound column.

C<cdbi_upload_with_mime> uploads the file and prepends its mime type as a
header. Use HTML::Tested::ClassDBI::Upload->strip_mime_header to pull it from
the data.

C<cdbi_readonly> boolean option can be used to make its widget readonly thus
skipping its value during update. Read only widgets will not be validated.

C<cdbi_primary> boolean option is used to make an unique column behave as
primary key. C<cdbi_load> will use this field while retrieving the object from
the database.

=cut
sub bind_to_class_dbi { shift()->bind_to_class_dbi_gr('_CDBIM_', @_); }

=head2 $class->bind_to_class_dbi_gr($group, $cdbi_class)

Binds $class to $cdbi class in group $group. Special group _CDBIM_ is used
as the default group.

=cut
sub bind_to_class_dbi_gr {
	my ($class, $gr, $dbi_class, $opts) = @_;
	$class->$_({}) for grep { !$class->$_ } @_cdata;
	$class->_CDBI_Class->{$gr} = $dbi_class;
	$class->_Field_Handlers->{$gr} = {};
	$class->_PrimaryFields->{$gr} = {};
	$class->cdbi_bind_from_fields($gr);
	$class->_load_db_info($gr);

	my $pk = $opts ? $opts->{PrimaryKey} : undef;
	$class->_PrimaryKey->{$gr} = $pk if $pk;
	confess "# No Primary fields given\n"
		unless ($pk || %{ $class->_PrimaryFields->{$gr} });
}

sub _get_cdbi_pk_for_retrieve {
	my ($self, $gr) = @_;
	my $pk = $self->_PrimaryKey->{$gr} or goto PFIELDS;

	my %pkh;
	for my $f (@$pk) {
		my $v = $self->$f;
		goto PFIELDS unless defined($v);

		my $h = $self->_Field_Handlers->{$gr}->{$f};
		$pkh{ $h ? $h->column_name : $f } = $v;
	}
	return \%pkh if %pkh;

PFIELDS:
	my $res = {};
	my %pf = %{ $self->_PrimaryFields->{$gr} };
	my ($pv, $pc);
	while (my ($k, $v) = each %pf) {
		$pv = $self->$k;
		next unless defined $pv;
		$pc = $v;
		last;
	}
	return undef unless defined($pv);
	my @vals = split('_', $pv);
	for (my $i = 0; $i < @$pc; $i++) {
		$res->{ $pc->[$i] } = $vals[$i];
	}
	return $res;
}

sub _fill_in_from_class_dbi {
	my ($self, $gr, $is_update) = @_;
	my $fhs = $self->_Field_Handlers->{$gr};
	my $cdbi = $self->class_dbi_object_gr($gr);
	while (my ($f, $h) = each %$fhs) {
		next if ($is_update && defined $self->{$f});
		$self->$f($h->get_column_value($cdbi));
	}
}

sub cdbi_retrieve { shift()->_call_for_all('cdbi_retrieve_gr', @_); }

sub cdbi_retrieve_gr {
	my ($self, $gr) = @_;
	my $pk = $self->_get_cdbi_pk_for_retrieve($gr);
	return unless defined($pk);
	my $cdbi = $self->_CDBI_Class->{$gr}->retrieve(ref($pk) ? %$pk : $pk);
	$self->class_dbi_object_gr($gr, $cdbi);
	return $cdbi;
}

=head2 $obj->cdbi_load

Loads Class::DBI object using primary key field - the widget with special
C<cdbi_bind> => 'Primary'.

This method populates the rest of the bound fields with values of the loaded
Class::DBI object.

Returns retrieved Class::DBI object or undef.

=cut
sub cdbi_load { return shift()->_call_for_all('cdbi_load_gr', @_); }

sub _get_cdbi_object {
	my ($self, $gr) = @_;
	return $self->class_dbi_object_gr($gr) || $self->cdbi_retrieve_gr($gr);
}

sub cdbi_load_gr {
	my ($self, $gr) = @_;
	my $cdbi = $self->_get_cdbi_object($gr) or return;
	$self->_fill_in_from_class_dbi($gr);
	return $cdbi;
}

=head2 $class->query_class_dbi($func, @params)

This function loads underlying Class::DBI objects using query function $func
(e.g C<search>) with parameters contained in C<@params>.

For each of those objects new HTML::Tested::ClassDBI instance is created.

=cut
sub query_class_dbi {
	my ($class, $func, @params) = @_;
	my @cdbis = $class->CDBI_Class->$func(@params);
	return [ map { 
		my $c = $class->new;
		$c->class_dbi_object($_);
		$c->_fill_in_from_class_dbi('_CDBIM_'); 
		$c;
	} @cdbis ];
}

sub _call_for_all {
	my ($self, $func, @args) = @_;
	$self->$func($_, @args) for keys %{ $self->_CDBI_Class };
	return $self->class_dbi_object;
}

=head2 $obj->cdbi_create($args)

Creates new database record using $obj fields.

Additional (optional) arguments are given by $args hash refernce.

=cut
sub cdbi_create { return shift()->_call_for_all('cdbi_create_gr', @_); }

=head2 $class->cdbi_create_gr($group, $args)

Creates new database record using $obj fields in group $group.

=cut
sub cdbi_create_gr {
	my ($self, $gr, $args) = @_;
	my $cargs = $self->_get_cdbi_pk_for_retrieve($gr) || {};
	$self->_update_fields($gr, sub { $cargs->{ $_[0] } = $_[1]; }, $args);
	my $res;
	eval { $res = $self->_CDBI_Class->{$gr}->create($cargs); };
	confess "SQL error: $@\n" . Dumper($self) if $@;
	$self->class_dbi_object_gr($gr, $res);
	$self->_fill_in_from_class_dbi($gr, 1);
	return $res;
}

sub _update_fields {
	my ($self, $gr, $setter, $args) = @_;
	while (my ($field, $h) = each %{ $self->_Field_Handlers->{$gr} }) {
		$h->update_column($setter, $self, $field)
			if exists $self->{$field};
	}
	my $cdbi = $self->_CDBI_Class->{$gr};
	while (my ($n, $v) = each %{ $args || {} }) {
		$setter->($n, $v) if $cdbi->can($n);
	}
}

=head2 $obj->cdbi_update($args)

Updates database records using $obj fields.

Additional (optional) arguments are given by $args hash refernce.

=cut
sub cdbi_update { return shift()->_call_for_all('cdbi_update_gr', @_); }

sub cdbi_update_gr {
	my ($self, $gr, $args) = @_;
	my $cdbi = $self->_get_cdbi_object($gr)
			or confess("# Nothing found to update");
	$self->_update_fields($gr, sub {
		my ($c, $val) = @_;
		no warnings 'uninitialized';
		$cdbi->$c($val) if $cdbi->$c ne $val;
	}, $args);
	eval { $cdbi->update; };
	confess "SQL error: $@\n" . Dumper($self) if $@;
	$self->_fill_in_from_class_dbi($gr, 1);
	return $cdbi;
}

=head2 $obj->cdbi_create_or_update($args)

Calls C<cdbi_create> or C<cdbi_update> based on whether the database record
exists already.

Additional (optional) arguments are given by $args hash refernce.

=cut
sub cdbi_create_or_update {
	return shift()->_call_for_all('cdbi_create_or_update_gr', @_);
}

sub cdbi_create_or_update_gr {
	my ($self, $gr, $args) = @_;
	return $self->_get_cdbi_object($gr) ? $self->cdbi_update_gr($gr, $args)
					: $self->cdbi_create_gr($gr, $args);
}

=head2 $obj->cdbi_construct

Constructs underlying Class::DBI object using $obj fields.

=cut
sub cdbi_construct { return shift()->cdbi_construct_gr('_CDBIM_'); }

sub cdbi_construct_gr {
	my ($self, $gr) = @_;
	my $pk = $self->_get_cdbi_pk_for_retrieve($gr)
			or confess "No primary key for $gr";
	return $self->_CDBI_Class->{$gr}->construct($pk);
}

=head2 $obj->cdbi_delete

Deletes database record using $obj fields.

=cut
sub cdbi_delete { shift()->cdbi_delete_gr('_CDBIM_', @_); }

sub cdbi_delete_gr {
	my $c = shift()->cdbi_construct_gr(shift());
	$c->delete;
}

sub _load_db_info {
	my ($class, $gr) = @_;
	while (my ($n, $h) = each %{ $class->_Field_Handlers->{$gr} }) {
		my $w = $class->ht_find_widget($n);
		$h->setup_type_info($class->_CDBI_Class->{$gr}, $w);
	}
}

=head2 $class->cdbi_set_many($class_objs, $cdbi_objs)

Initializes C<class_dbi_object> field of C<$class_objs> arrayref from the
Class::DBI objects given in C<$cdbi_objs>.

Useful to avoid overhead of retrieving Class::DBI objects one by one.

=cut
sub cdbi_set_many {
	my ($class, $h_objs, $c_objs) = @_;
	my @pcs = $class->CDBI_Class->primary_columns;
	my %c_objs;
	for my $co (@$c_objs) {
		$c_objs{ join('_', map { $co->$_ } @pcs) } = $co;
	}
	for my $ho (@$h_objs) {
		my $pk = $ho->_get_cdbi_pk_for_retrieve('_CDBIM_');
		my $co = $c_objs{ join('_', grep { defined($_) }
					map { $pk->{$_} } @pcs) };
		$ho->class_dbi_object($co);
	}
}

1;

=head1 AUTHOR

	Boris Sukholitko
	CPAN ID: BOSU
	
	boriss@gmail.com
	

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

HTML::Tested, Class::DBI

=cut

