# $Id: IO.pm,v 1.7 2002/03/08 10:55:15 joern Exp $

package JaM::Filter::IO;

my $DEBUG = 0;

use strict;
use Carp;
use Storable qw ( freeze thaw );
use JaM::Folder;

my %actions = (
        "drop" 	             =>    "Drop To Folder",
        "delete"             =>    "Delete",
);

my %operations = (
        "and" 	  	     =>    "Match All",
        "or"                 =>    "Match Any",
);

sub dbh 		{ shift->{dbh}				}

sub id			{ my $s = shift; $s->{id}
		          = shift if @_; $s->{id}		}
sub filter_id		{ my $s = shift; $s->{id}
		          = shift if @_; $s->{id}		}
sub name		{ my $s = shift; $s->{name}
		          = shift if @_; $s->{name}		}
sub folder_id		{ my $s = shift; $s->{folder_id}
		          = shift if @_; $s->{folder_id}	}
sub type		{ my $s = shift; $s->{type}
		          = shift if @_; $s->{type}		}
sub rules		{ my $s = shift; $s->{rules}
		          = shift if @_; $s->{rules}		}
sub last_changed	{ my $s = shift; $s->{last_changed}
		          = shift if @_; $s->{last_changed}	}
sub code		{ my $s = shift; $s->{code}
		          = shift if @_; $s->{code}		}

sub possible_actions {
	return \%actions;
}

sub possible_operations {
	return \%operations;
}

sub create {
	my $class = shift;
	my %par = @_;
	my ( $dbh, $name, $folder_id, $folder_path) =
	@par{'dbh','name','folder_id','folder_path'};
	my ( $operation, $action, $type) =
	@par{'operation','action','type'};

	$folder_id ||= 2 if not $folder_path;
	$operation ||= 'and';
	$action    ||= 'drop';
	$type      ||= 'input';
	
	my ($sortkrit) = $dbh->selectrow_array (
		"select max(sortkrit)
		 from   IO_Filter"
	);
	
	$dbh->do (
		"insert into IO_Filter (name, sortkrit)
		 values (?, ?)", {},
		$name, $sortkrit + 1
	);
	
	my $self = {
		dbh => $dbh,
		id  => $dbh->{mysql_insertid},
		name => $name,
		rules => [],
	};
	
	$self = bless $self, $class;
	
	if ( $folder_path ) {
		my $href = JaM::Folder->query (
			dbh    => $dbh,
			where  => "path=?",
			params => [ $folder_path ],
		);
		confess "Folder with path '$folder_path' not found"
			if not keys %{$href};
		($folder_id) = keys %{$href};
	}
	
	$self->operation($operation||'and');
	$self->folder_id($folder_id);
	$self->action($action);
	$self->type($type);

	$self->save;
	
	return $self;
}

sub load {
	my $type = shift;
	my %par = @_;
	my ($dbh, $filter_id) = @par{'dbh','filter_id'};

	my ($id, $object) =
	    	$dbh->selectrow_array (
		"select id, object
		 from   IO_Filter
		 where  id=?", {}, $filter_id
	);

	if ( not $id ) {
		confess ("input filter id $filter_id not found");
	}
	
	my $self = thaw $object;
	$self->{dbh} = $dbh;

	return bless $self, $type;
}

sub save {
	my $self = shift;

	# first recalculate filter perl code
	$self->calculate_code;

	# first touch objects last_changed field
	my $last_changed = time;
	$self->last_changed($last_changed);

	# copy $self to a hash, which will be serialized and stored
	my %object = %{$self};
	
	# no $dbh in the serialized object
	my $dbh = delete $object{dbh};
	
	# output filter?
	my $output = $self->type eq 'output' ? 1 : 0;
	
	# folder_id defaults to 0
	my $folder_id = $self->folder_id || 0;

	# and store the serialized object
	$dbh->do (
		"update IO_Filter set
			name = ?, object = ?, last_changed = ?,
			output = ?, folder_id = ?
		 where id = ?", {},
		$self->name, freeze(\%object), $last_changed,
		$output, $folder_id, $self->id
	);

	return $self;
}

sub list {
	my $class = shift;
	my %par = @_;
	my ($dbh, $type) = @par{'dbh','type'};
	
	my $output = $type eq 'output' ? 1 : 0;
	
	my $sth = $dbh->prepare (
		"select id, name, last_changed
		 from	IO_Filter
		 where  output = ?
		 order by sortkrit"
	);
	$sth->execute ( $output );

	my $ar;
	my @filters;
	while  ( $ar = $sth->fetchrow_arrayref ) {
		push @filters, {
			id      => $ar->[0],
			name    => $ar->[1],
			changed => $ar->[2]
		};
	}
	
	return \@filters;
}

sub action {
	my $self = shift;
	my ($value) = @_;
	if ( $value ) {
		confess "unknown action '$value'"
			if not defined $actions{$value};
		$self->{action} = $value;
	}
	return $self->{action};
}

sub operation {
	my $self = shift;
	my ($value) = @_;
	if ( $value ) {
		confess "unknown operation '$value'"
			if not defined $operations{$value};
		$self->{operation} = $value;
	}
	return $self->{operation};
}

sub append_rule {
	my $self = shift;
	my %par = @_;
	my ($rule) = @par{'rule'};
	push @{$self->rules}, $rule;
	return $self;
}

sub prepend_rule {
	my $self = shift;
	my %par = @_;
	my ($rule) = @par{'rule'};
	unshift @{$self->rules}, $rule;
	return $self;
}

sub insert_rule {
	my $self = shift;
	my %par = @_;
	my ($rule, $index) = @par{'rule','index'};
	splice @{$self->rules}, $index, 0, $rule;
	return $self;
}

sub remove_rule {
	my $self = shift;
	my %par = @_;
	my ($rule) = @par{'rule'};
	
	my $i;
	my $rules = $self->rules;
	for ($i=0; $i < @{$rules}; ++$i) {
		last if $rule eq $rules->[$i];
	}

	splice @{$self->rules}, $i, 1;
	
	return $self;
}

sub calculate_code {
	my $self = shift;
	
	my $code      = "";
	my $op        = $self->operation;
	my $action    = $self->action;
	my $folder_id = $self->folder_id || 'undef';

	if ( $DEBUG ) {	
		$code .= qq{print STDERR "apply filter: }.quotemeta($self->name).qq{\\n";\n};
	}

	$code .= "return ('$action', $folder_id) if ";

	my $condition;
	foreach my $rule ( @{$self->rules} ) {
		$rule->calculate_code;
		$condition .= $rule->code." $op ";
	}
	
	$condition =~ s/ $op $//;

	if ( $DEBUG ) {
		$code .= qq{print STDERR "apply filter: }.quotemeta($self->name).qq{ ($condition)\\n" and $condition;};
		$code .= qq{print STDERR "didn't match\\n";\n};
	} else {
		$code .= $condition.";\n";
	}

	print STDERR $code if $DEBUG;

	return $self->code ($code);
}

sub reorder {
	my $type = shift;
	my %par = @_;
	my ($filter_ids, $dbh) = @par{'filter_ids','dbh'};
	
	my $sortkrit = 1;
	my $sth = $dbh->prepare (
		"update IO_Filter set sortkrit=? where id=?"
	);
	
	foreach my $id ( @{$filter_ids} ) {
		$sth->execute ($sortkrit, $id);
		++$sortkrit;
	}
	
	$sth->finish;
	
	1;
}

sub delete {
	my $self = shift;
	
	$self->dbh->do (
		"delete from IO_Filter where id=?",{}, $self->id
	);

	JaM::Filter::IO::Apply->clear_cache;

	1;
}

package JaM::Filter::IO::Rule;

use Carp;

my %fields = (
        "to" 	             =>    "To",
        "tocc"               =>    "To or CC",
        "tofromcc"           =>    "To or CC or From",
        "from"               =>    "From",
        "cc" 	             =>    "CC",
        "body"               =>    "Body",
        "subject"            =>    "Subject",
#        "date"               =>    "Date",
);

my %operations = (
	"contains"  	     =>    "Contains",
	"contains!" 	     =>    "Does'n contain",
	"begins"    	     =>    "Begins with",
	"ends"      	     =>    "Ends with",
	"regex_case"	     =>	   "Matches This RegEx, Case Relevant",
	"regex"	   	     =>	   "Matches This RegEx, Case Ignore",
);

sub code	{ my $s = shift; $s->{code}
	          = shift if @_; $s->{code}	}

sub calculate_code {
	my $self = shift;
	
	my $field     = $self->field;
	my $operation = $self->operation;
	my $value     = $self->value;

	$value = quotemeta($value) if $operation !~ /^regex/;

	my $code;
	
	if ( $field eq 'body' ) {
		$code .= "( \$h->{entity}->bodyhandle ? \$h->{entity}->bodyhandle->as_string : '' ) ";
	} else {
		$code .= "\$h->{$field} ";
	}

	if ( $operation eq 'contains' or $operation eq 'regex' ) {
		$code .= "=~ m!$value!i";

	} elsif ( $operation eq 'regex_case' ) {
		$code .= "=~ m!$value!";
	
	} elsif ( $operation eq 'contains!' ) {
		$code .= "!~ m!$value!i";

	} elsif ( $operation eq 'begins' ) {
		$code .= "=~ m!^$value!i";

	} elsif ( $operation eq 'ends' ) {
		$code .= "=~ m!$value\$!i";
	}
	
	return $self->code($code);	
}

sub create {
	my $type = shift;
	my %par = @_;
	my  ($field, $operation, $value) =
	@par{'field','operation','value'};
	
	my $self = bless {}, $type;

	$self->field($field)         if $field;
	$self->operation($operation) if $operation;
	$self->value($value)         if $value;
	
	return $self;
}

sub possible_fields {
	return \%fields;
}

sub possible_operations {
	return \%operations;
}

sub field {
	my $self = shift;
	my ($name) = @_;
	if ( $name ) {
		confess "unknown header field '$name'"
			if not defined $fields{$name};
		$self->{field} = $name;
		$self->calculate_code;
	}

	return $self->{field};
}

sub operation {
	my $self = shift;
	my ($name) = @_;
	if ( $name ) {
		confess "unknown operation '$name'"
			if not defined $operations{$name};
		$self->{operation} = $name;
		$self->calculate_code;
	}

	return $self->{operation};
}

sub value {
	my $self = shift;
	my ($value) = @_;

	if ( @_ ) {
		$self->{value} = $value;
		$self->calculate_code;
	}

	return $self->{value};
}

package JaM::Filter::IO::Apply;

use strict;
use Carp;

my %FILTER_OBJECTS;		# Hash of IO::Filter objects
my %FILTER_CHANGED;		# Hash of change timestamps of IO::Filter objects
my %FILTER_EACH_CODE;		# code of each IO::Filter object
my %FILTER_COMBINED_CODE;	# combined code for keys 'input' and 'output'

sub clear_cache {
	%FILTER_OBJECTS       = ();
	%FILTER_CHANGED       = ();
	%FILTER_EACH_CODE     = ();
	%FILTER_COMBINED_CODE = ();
}

sub init {
	my $class = shift;
	my %par = @_;
	my ($dbh, $type) = @par{'dbh','type'};
	
	$type ||= 'input';
	
	my $filters = JaM::Filter::IO->list (
		dbh  => $dbh,
		type => $type,
	);
	
	my $code = "sub {\nmy \$h=shift;\n";

	if ( $DEBUG ) {
		$code .= "my \%hd = \%\{\$h\}; delete \$hd{entity}; use Data::Dumper; print STDERR Dumper(\\\%hd);\n";
	}

	my $loaded_filter;
	my $changed = 0;
	foreach my $filter ( @{$filters} ) {
		if ( $FILTER_CHANGED{$type.$filter->{id}} < $filter->{changed} ) {
			$changed = 1;

			$loaded_filter = $FILTER_OBJECTS{$type.$filter->{id}} =
				JaM::Filter::IO->load (
					dbh       => $dbh,
					filter_id => $filter->{id}
			);

			$FILTER_CHANGED{$type.$filter->{id}} =
				$loaded_filter->last_changed;

			$FILTER_EACH_CODE{$type.$filter->{id}} =
				$loaded_filter->code;
		}
		$code .= $FILTER_EACH_CODE{$type.$filter->{id}}."\n";
	}
	
	$code .= "}\n";

	my $error;
	my $sub = $FILTER_COMBINED_CODE{$type};
	if ( not $sub or $changed ) {
		$sub = eval $code;
		$error = $@;
	}

	if ( $DEBUG ) {	
		print STDERR "code=\n$code\n\nerror=\n$error\n";
	}
	
	$FILTER_COMBINED_CODE{$type} = $sub;

	my $self = {
		code  => $code,
		sub   => $sub,
		error => $error,
	};
	
	return bless $self, $class;
}

sub dbh   { shift->{dbh}		}
sub error { shift->{error}		}
sub sub	  { shift->{sub}		}
sub code  { shift->{code}		}

1;
