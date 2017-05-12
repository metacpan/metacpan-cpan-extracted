package HTML::DBTable;

use 5.006;
use strict;
use warnings;

use Params::Validate qw(:all);
use DBIx::DBSchema;
use HTML::Template;

our $VERSION = '0.05';

my $init_params = 
	{
		strip_tablename			=> { type 	=> BOOLEAN,default 	=> 1},
		begin_form				=> { type 	=> BOOLEAN,default 	=> 1},
		end_form				=> { type 	=> BOOLEAN,default 	=> 1},
	};

sub new {
	my $proto 					= shift;
	my $class 					= ref($proto) || $proto;
	my %opts  					= validate(@_ , $init_params);
	my $self  					= {%opts};
	bless $self,$class;
	return $self;
}

sub html {
	my $self	= shift;
	my %opt		= validate(@_, {	dbh	=> {isa => 'DBI::db',optional=>1 },
									tablename 	=> {type => SCALAR,
													optional=>1 },
									values		=> {type => HASHREF, 
													optional => 1 },
									tmpl_path 	=> {type => SCALAR , 
													optional => 1 },
								} );
	$self->tmpl_path($opt{tmpl_path}) if (exists $opt{tmpl_path});
	$self->dbh($opt{dbh}) if (exists $opt{dbh});
	$self->tablename($opt{tablename}) if (exists $opt{tablename});
	$self->values($opt{values}) if (exists $opt{values});
	#my $tbl_schema = new_native DBIx::DBSchema::Table 
	#										$self->dbh,$self->tablename;
	my $tbl_schema	= $self-> _new_table_schema;
	my @columns     = $tbl_schema->columns;
	my @fields      = ();
	my @hidden_fields = ();
	my $column_pos = 0;
	my $values		= $self->values;
	foreach (@columns) {
    	my $col_schema = $tbl_schema->column($_);
		my $name	= ($self->strip_tablename) ? '' : $self->tablename . '.';
		$name		.= $col_schema->name;
    	my $length  = $col_schema->length;
    	$length = $length == 0 	? 10 	
								: ($length > 50 ? 50 : $length) if ($length);
    	my $field       = {     name 	=> $name,
								label	=> $col_schema->name,
								pos		=> $column_pos,
                            	value => $values->{$col_schema->name}  
											|| $col_schema->default,
                            	length => $length,
								can_be_null => ($col_schema->null eq 'NULL'),
								is_null => defined 
											$values->{$col_schema->name}
											? 0 : 1,
								'row.pre' => defined $self->{cb_row_pre} 
											? $self->{cb_row_pre}->call($col_schema->name) : '',
								'row.post' => defined $self->{cb_row_post} 
											? $self->{cb_row_post}->call($col_schema->name) : '',
                          };
		# reimposto la label
		if ($self->labels) {
			if (ref($self->labels) eq 'HASH') {
				$field->{label} = $self->labels->{$field->{name}}
					if (exists $self->labels->{$field->{name}});
			} else {
				$field->{label} = $self->labels->[$column_pos]
					if ($column_pos < scalar(@{$self->labels}) );
			}
		}
		$self->_set_field_appearance(field => $field,schema => $col_schema);
		$self->_set_field_enums(field => $field,schema => $col_schema);
		if ($field->{use_hidden}) {
			push @hidden_fields,$field;
		} else {
    		push @fields,$field;
		}
		$column_pos++;
	}
	my $htmpl = $self->_new_html_template();
	$htmpl->param(fields => \@fields);
	$htmpl->param('fields.hidden' => \@hidden_fields);
	$htmpl->param('form.begin' => $self->begin_form);
	$htmpl->param('form.end' => $self->end_form);
	$htmpl->param('rows.pre' => defined $self->{cb_rows_pre} 
								? $self->{cb_rows_pre}->call() : '');
	$htmpl->param('rows.post' => defined $self->{cb_rows_post} 
								? $self->{cb_rows_pre}->call() : '');
	return $htmpl->output;
}

sub _new_html_template() {
	my $self 	= shift;
	my $htmpl;
	if ($self->tmpl_path) {
		$htmpl = new HTML::Template( 	filename 	=> $self->tmpl_path,
                               			vanguard_compatibility_mode=>1,
										global_vars => 1);
	} else {
		$htmpl = new HTML::Template(	scalarref => \$self->template,
										vanguard_compatibility_mode=>1,
										global_vars=>1);
	}
	return $htmpl;
	
}

sub _new_table_schema() {
	my $self	= shift;
	if ($self->tblschema) {
		return $self->tblschema;
	} else {
		die "You must set a DB handle connection setting dbh parameter"
			unless ($self->dbh);	
		return new_native DBIx::DBSchema::Table 
											$self->dbh,$self->tablename;
	}
}

sub _set_field_appearance {
	my $self 	= shift;
	my %opt		= validate(@_ ,{
								field => HASHREF,
								schema => {isa => 'DBIx::DBSchema::Column'}
								} );
	my $appearance = 'text';
	if ($self->appearances) {
		if (ref $self->appearances eq 'HASH') {
			$appearance = $self->appearances->{$opt{field}->{name}} 
				if (exists $self->appearances->{$opt{field}->{name}});
		} else {
			$appearance = $self->appearances->[$opt{field}->{pos}]
                    if ($opt{field}->{pos} < scalar(@{$self->appearances}) );
		}
	}
	if ($opt{schema}->type eq 'enum' || $appearance eq 'enum') {
		my @items_value = @{$opt{schema}->enum};
		$appearance =  (scalar(@items_value) < 5) ? 'radio' : 'combo';
	}
	$opt{field}->{'use_' . $appearance} = 1;
}

sub _set_field_enums() {
	my $self 	= shift;
	my %opt		= validate(@_ ,{
								field => HASHREF,
								schema => {isa => 'DBIx::DBSchema::Column'}
								} );
	my $field = $opt{field};
	my $col_schema = $opt{schema};
    if ($field->{use_combo} || $field->{use_radio} ) {
		my %enums = ();
		if ($self->enums) {
			my $enums;
			if (ref $self->enums eq 'HASH') {
				$enums = $self->enums->{$field->{name}} 
					if (exists $self->enums->{$field->{name}});
			} else {
				$enums = $self->enums->[$field->{pos}]
					if ($field->{pos}<=scalar(@{$self->enums}));
			}
			if ($enums) {
				if (ref $enums eq 'HASH') {
					%enums = %{$enums}
				} else {
					%enums = map {$_ => $_ } 
									@{$enums};
				}
			}
		} else { 
			%enums = map {$_ => $_} @{$col_schema->enum} if ($col_schema->enum);
		}
       	$field->{enums}  = [];
       	foreach (keys %enums) {
			my $item = {enum_key => $_,enum_value =>$enums{$_}};
			if ( $field->{value} ) {
				$item->{selected} = $_ eq $field->{value} 
										? ($field->{use_combo} 
												? 'selected'  
												: 'checked'
											) 
										: '';
			}
			push @{$field->{enums}}, $item;
		}
   	}
}

sub tmpl_path {
	my $self 	= shift;
	my @opt		= validate_pos(@_, {type => SCALAR | UNDEF, default => undef} );
	return defined $opt[0] ?  $self->{tmpl_path} = $opt[0] : $self->{tmpl_path};
}


sub dbh {
	my $self 	= shift;
	my @opt		= validate_pos(@_, {isa => 'DBI::db' , default => undef} );
	return defined $opt[0] ?  $self->{dbh} = $opt[0] : $self->{dbh};
}

sub tablename {
	my $self 	= shift;
	if (defined $self->tblschema && !defined $self->dbh) {
		# prendo il nome direttamente dal tblschema
		return $self->tblschema->name;
	}
	my @opt		= validate_pos(@_, {type => SCALAR, default => undef} );
	return defined $opt[0] ?  $self->{tablename} = $opt[0] : $self->{tablename};
}

sub strip_tablename {
	my $self 	= shift;
	my @opt		= validate_pos(@_, {type => BOOLEAN, default => undef} );
	return defined $opt[0] ?  $self->{strip_tablename} = $opt[0] : $self->{strip_tablename};
}

sub values {
	my $self 	= shift;
	my @opt		= validate_pos(@_, {type => HASHREF, default => undef} );
	return defined $opt[0] ?  $self->{values} = $opt[0] : $self->{values};
}

sub tblschema {
	my $self 	= shift;
	my @opt		= validate_pos(@_, {isa => 'DBIx::DBSchema::Table', 
									default => undef} );
	return defined $opt[0] ?  $self->{tblschema} = $opt[0] : $self->{tblschema};
}

sub labels {
	my $self 	= shift;
	my @opt		= validate_pos(@_,  {type => ARRAYREF | HASHREF,
									default => undef} );
	return defined $opt[0] ?  $self->{labels} = $opt[0] : $self->{labels};
	
}

sub appearances {
	my $self 	= shift;
	my @opt		= validate_pos(@_,  {type => ARRAYREF | HASHREF,
									default => undef} );
	return defined $opt[0] ?  $self->{appearances} = $opt[0] : $self->{appearances};
	
}

sub enums {
	my $self 	= shift;
	my @opt		= validate_pos(@_,  {type => ARRAYREF | HASHREF,
									default => undef} );
	return defined $opt[0] ?  $self->{enums} = $opt[0] : $self->{enums};
	
}

sub begin_form {
	my $self 	= shift;
	my @opt		= validate_pos(@_, {type => BOOLEAN, default => undef} );
	return defined $opt[0] ?  $self->{begin_form} = $opt[0] : $self->{begin_form};
}

sub end_form {
	my $self 	= shift;
	my @opt		= validate_pos(@_, {type => BOOLEAN, default => undef} );
	return defined $opt[0] ?  $self->{end_form} = $opt[0] : $self->{end_form};
}
sub cb_row_pre {
	my $self	= shift;
	my @opt		= validate_pos(@_,  {isa => 'Callback',
									default => undef} );
	return defined $opt[0] ?  $self->{cb_row_pre} = $opt[0] : $self->{cb_row_pre};
	
}
sub cb_row_post {
	my $self	= shift;
	my @opt		= validate_pos(@_,  {isa => 'Callback',
									default => undef} );
	return defined $opt[0] ?  $self->{cb_row_post} = $opt[0] : $self->{cb_row_post};
	
}
sub cb_rows_pre {
	my $self	= shift;
	my @opt		= validate_pos(@_,  {isa => 'Callback',
									default => undef} );
	return defined $opt[0] ?  $self->{cb_rows_pre} = $opt[0] : $self->{cb_rows_pre};
	
}
sub cb_rows_post {
	my $self	= shift;
	my @opt		= validate_pos(@_,  {isa => 'Callback',
									default => undef} );
	return defined $opt[0] ?  $self->{cb_rows_post} = $opt[0] : $self->{cb_rows_post};
	
}

sub template() {
	my $self	= shift;
	my @opt		= validate_pos(@_,  {type => SCALAR,
									default => undef} );
	$self->{template} = $opt[0] if ($opt[0]);
	return $self->{template} || <<EOF;
<TMPL_IF form.begin>
<FORM ACTION="" METHOD="POST">
</TMPL_IF>
%rows.pre%
<TMPL_LOOP name="fields.hidden">
	<input type="HIDDEN" name="%name%" value="%value%">
</TMPL_LOOP>
<table>
<TMPL_LOOP name="fields">
<tr>
<td>%row.pre%<b>%label%:</b></td>
<td>
<TMPL_UNLESS name="use_label">
<TMPL_IF name="can_be_null">
	<input type="checkbox" name="%name%_null" 
	onclick="if (this.checked) {nullify(this.form,'%name%'); 
	this.checked = true}; return true"
	<TMPL_IF name="is_null">checked</TMPL_IF>>
</TMPL_IF>
</TMPL_UNLESS>
</td>
<td>
<TMPL_IF name="use_combo">
	<select name="%name%">
		<TMPL_LOOP name="enums">
			<option value="%enum_key%" %selected%>%enum_value%
		</TMPL_LOOP>
	</select>
</TMPL_IF>
<TMPL_IF name="use_radio">
	<TMPL_LOOP name="enums">
		<input type="radio" name="%name%" value="%enum_key%" %selected%>%enum_value%
	</TMPL_LOOP>
</TMPL_IF>
<TMPL_IF name="use_text">
	<input type="TEXT" name="%name%" value="%value%" size="%length%"
	<TMPL_IF NAME="can_be_null">onchange="return unnullify(this.form,this)"</TMPL_IF> >
</TMPL_IF>
<TMPL_IF name="use_unmodificable">
	%value%
</TMPL_IF>
%row.post%
</td>
</tr>
</TMPL_LOOP>
<TMPL_VAR name="rows.post">
</table>
<TMPL_IF form.end>
<INPUT TYPE="submit" NAME="submit_form" VALUE="Invia">
</FORM>
</TMPL_IF>

<script type="text/javascript">
<!--
function unnullify(form,field)
{
    if (typeof(form.elements[field.name + '_null']) != 'undefined') {
       form.elements[field.name + '_null'].checked = false
    } // end if
    return true;
}

function nullify(form,fieldname)
{
    if (typeof(form.elements[fieldname]) != 'undefined') {
       form.elements[fieldname].value = '';
    } // end if
    return true;
}

//-->
</script>

EOF
}


1;
