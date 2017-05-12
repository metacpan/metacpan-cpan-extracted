package HTML::FormStructure::Query;

use strict;
use base qw(Class::Accessor);

__PACKAGE__->mk_accessors(&_my_accessors);

sub _init {
    my $opt = shift;
    $opt->{query_accessors} = defined $opt->{query_accessors} ?
	$opt->{query_accessors} : [];
    __PACKAGE__->mk_accessors(
	&_my_accessors,@{$opt->{query_accessors}}
    );
}

sub _my_accessors {
    return qw(name type value checked selected
	      more less be consist consistf store storef
	      column error
	      tag_label tag_attr tag_desc
	      tag_val_label tag_left_in tag_right_in
	      scratch);
}

sub new {
    my $class = shift;
    my $query = shift;
    my $opt   = shift;
    _init($opt);
    my $self =  bless { _query => $query }, $class;
    $self->$_($query->{$_}) for (keys %{$query});
    return $self;
}

sub array_of {
    my $self = shift;
    my $meth = shift;
    return unless defined $self->$meth();
    my $array = defined $self->$meth() ? $self->$meth() : [];
    return @{$array};
}

sub _compare_value_with_arg {
    my $self  = shift;
    my $meth  = shift;
    my $arg = shift;
    return unless defined $self->$meth();
    my $ret = '';
    if (ref $self->$meth() eq 'ARRAY') {
	for (@{$self->$meth()}) {
	    $ret = $meth if $arg eq $_;
	}
    }
    else {
	$ret = $meth if $arg eq $self->$meth();
    }
    return $ret;
}

sub is_checked {
    my $self = shift;
    my $arg  = shift;
    $self->_compare_value_with_arg('checked',$arg);
}

sub is_selected {
    my $self = shift;
    my $arg  = shift;
    $self->_compare_value_with_arg('selected',$arg);
}

sub column_name {
    my $self = shift;
    if ($self->column == 1) {
	return $self->name;
    }
    else {
	return $self->column;
    }
}

sub store_error {
    my $self = shift;
    my $error = $self->error || [];
    push @{$error}, shift;
    $self->error($error);
}

sub add { shift->add_right(@_) }

sub add_left {
    my $self = shift;
    my ($key,$val) = @_;
    $self->_do_add($key,$val,1);
}

sub add_right {
    my $self = shift;
    my ($key,$val) = @_;
    $self->_do_add($key,$val);
}

sub _do_add {
    my $self = shift;
    my ($key,$val,$left) = @_;
    my $stored = defined $self->$key() ? $self->$key() : '';
    if ($left) {
	if (ref $stored) {
	    push @{$self->$key()}, $val if ref $stored eq 'ARRAY';
	}
	else {
	    $self->$key($stored . $self->$key());
	}
    }
    else {
	if (ref $stored) {
	    unshift @{$self->$key()}, $val if ref $stored eq 'ARRAY';
	}
	else {
	    $self->$key($stored . $val);
	}
    }
}


# ----------------------------------------------------------------------

sub tag {
    my $self = shift;
    my $tag  = shift || '';
    if ($self->type =~ /^(?:text|password|file|hidden)$/i) {
	$tag = $self->_Input;
    }
    elsif ($self->type =~ /radio|checkbox/i) {
	$tag = $self->_RadioCheckbox;
    }
    elsif ($self->type =~ /select/i) {
	$tag = $self->_Select;
    }
    elsif ($self->type =~ /textarea/i) {
	$tag = $self->_Textarea;
    }
}

sub _Input {
    my $self = shift;
    return sprintf qq|%s<input name="%s" type="%s" value="%s" %s>%s|,(
	$self->tag_left_in,
	$self->name,$self->type,$self->value,$self->tag_attr,
	$self->tag_right_in,
    );
}

sub _Select {
    my $self = shift;
    my $start = sprintf qq|%s<select name="%s" %s>|,
	$self->tag_left_in,$self->name,$self->tag_attr;
    my $end   = sprintf qq|</select>%s|,$self->tag_right_in;
    my $option;
    return unless ref $self->value eq 'ARRAY';
    for my $val (@{$self->value}) {
	my $selected = $self->is_selected($val) ? 'selected': '';
	$option .= sprintf qq|<option value="%s" %s %s>%s</option>|,
	    $val,$self->tag_attr,$selected,$self->gen_tag_val_label($val);
    }
    return join "\n",($start,$option,$end,);
}

sub _RadioCheckbox {
    my $self = shift;
    my $tag;
    return unless ref $self->value eq 'ARRAY';
    for my $val (@{$self->value}) {
	my $checked = $self->is_checked($val) ? 'checked': '';
	$tag .= sprintf
	    qq|%s<input name="%s" type="%s" value="%s" %s %s>%s%s|,(
		$self->tag_left_in,
		$self->name,$self->type,$val,$self->tag_attr,
		$checked,$self->gen_tag_val_label($val),
		$self->tag_right_in,
	    );
    }
    return $tag;
}

sub _Textarea {
    my $self = shift;
    return sprintf qq|%s<textarea name="%s" %s>%s</textarea>%s|,(
	$self->tag_left_in,
	$self->name,$self->tag_attr,$self->value,
	$self->tag_right_in,
    );
}

sub gen_tag_val_label {
    my $self = shift;
    my $key  = shift;
    my $label = $self->tag_val_label ne '' ? $self->tag_val_label : {};
    return defined $label->{$key} ? $label->{$key} : $key;
}


1;

__END__

