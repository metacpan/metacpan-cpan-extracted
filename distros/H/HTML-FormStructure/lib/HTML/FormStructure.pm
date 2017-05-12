package HTML::FormStructure;

use strict;
use vars qw($VERSION);
$VERSION = '0.04';

use HTML::FormStructure::Query;
use HTML::FormStructure::Validation;

use base qw(Class::Accessor);

sub _my_accessors {
    qw(action method enctype r validator);
}

sub _init {
    my $opt = shift;
    $opt->{form_accessors} = defined $opt->{form_accessors} ?
	$opt->{form_accessors} : [];
    __PACKAGE__->mk_accessors(
	&_my_accessors,@{$opt->{form_accessors}}
    );
}

sub new {
    my($class, $form, $r, $opt) = @_;
    _init($opt);
    my @query;
    for my $query (@{$form}) {
	if (ref $query->{consist} eq 'ARRAY') {
	    my @tmp_query;
	    for my $q (@{$query->{consist}}) {
		my $tmp_q = HTML::FormStructure::Query->new($q,$opt);
		push @tmp_query, $tmp_q;
	    }
	    $query->{consist} = \@tmp_query;
	    push @query, HTML::FormStructure::Query->new($query,$opt);
	}
	else {
	    push @query, HTML::FormStructure::Query->new($query,$opt);
	}
    }
    my $self = bless { _form_data => \@query }, $class;
    $self->r($r) if defined $r;
    return $self;
}

sub list_as_array {
    return @{shift->{_form_data}};
}

sub list_as_arrayref {
    return shift->{_form_data};
}

sub have {
    my $self = shift;
    my $meth = shift;
    my @wanted;
    for my $query ($self->list_as_array) {
	if ($query->$meth()) {
	    push @wanted, $query if defined $query->$meth();
	}
	next unless ($query->consist);
	for my $q ($query->array_of('consist')) {
	    next unless $q->$meth();
	    push @wanted, $q if defined $q->$meth();
	}
    }
    return @wanted;
}

sub _do_search {
    my $self = shift;
    my $key  = shift;
    my $val  = shift;
    my $type = shift;
    my @ret;
    for my $query ($self->list_as_array) {
	if (defined $type && $type eq 'like') {
	    push @ret,$query if $query->$key() =~ /$val/;
	}
	else {
	    push @ret,$query if $query->$key() eq $val;
	}
	for my $q ($query->array_of('consist')) {
	    push @ret, $q if $q->$key() eq $val;
	}
    }
    return @ret;
}

sub search { shift->_do_search(@_)}

sub search_like { shift->_do_search(@_,'like')}

sub fetch {
    my $self = shift;
    my $target = ($self->search('name',shift))[0];
    return $target ? $target : '';
}

sub group {
    my $self = shift;
    my $key = shift;
    my $ret = {};
    for my $query ($self->have($key)) {
	push @{$ret->{$query->$key()}}, $query;
    }
    return map { $ret->{$_}} keys %{$ret};
}

sub param {
    my $self = shift;
    my $target = ($self->search('name',shift))[0];
    return $target ? $target->store : '';
}

sub store_request {
    my $self = shift;
    for my $query ($self->list_as_array) {
	if (defined $query->storef) {
	    $query->store(
		sprintf $query->storef,
		$self->r->param($query->name)
	    );
	}
	else {
	    $query->store($self->r->param($query->name));
	}
	for my $q ($query->array_of('consist')) {
	    $q->store($self->r->param($q->name));
	}
    }
}

sub hashref {
    my $self = shift;
    my ($key,$val,$situation) = @_;
    my $hashref = {};
    for ($self->have($key)) {
	if ($situation) {
	    next unless defined $_->$situation();
	}
	$hashref->{$_->name} = $_->$val() if defined $_->$val();
    }
    return $hashref;
}

sub query_combine { shift->consist_query }

sub consist_query {
    my $self = shift;
    for my $query ($self->have('consist')) {
	my $value;
	if (defined $query->consistf) {
	    $value = sprintf $query->consistf,
		map $self->r->param($_->name),$query->array_of('consist');
	}
	else {
	    for my $q ($query->array_of('consist')) {
		$value .= defined $self->r->param($q->name) ?
		    $self->r->param($q->name) : '';
	    }
	}
	$self->r->param($query->name => $value) if defined $value;
    }
}

1;

__END__


=head1 NAME

HTML::FormStructure - Accessor for HTML FORM definition

=head1 SYNOPSIS

  use HTML::FormStructure;
  use CGI;
  $cgi    = CGI->new;
  $option = { form_accessors  => [qw(foo bar baz)], 
  	      query_accessors => [qw(foo bar baz)], };

  $form = HTML::FormStructure->new(
      &arrayref_of_queries,
      $cgi_object,
      $option
  );

  sub arrayref_of_queries {
      return [{
  	name   => 'user_name',
  	type   => 'text',
  	more   => 6,
  	less   => 255,
  	column => 1,
      },{
  	name   => 'email',
  	type   => 'text',
  	more   => 1,
  	less   => 255,
  	be     => [qw(valid_email)],
  	column => 1,
      },{
  	name    => 'sex',
  	type    => 'radio',
  	value   => [1,2],
  	checked => 1,
  	column  => 1,
      },{
  	name    => 'birthday',
  	type    => 'text',
  	be      => [qw(valid_date)],
  	more    => 1,
  	less    => 255,
  	column  => 1,
  	consist => [{
  	    name => 'year',
  	    type => 'text',
  	    more => 1,
  	    less => 4,
  	    be   => [qw(is_only_number)],
  	},{
  	    name => 'month',
  	    type => 'text',
  	    more => 1,
  	    less => 2,
  	    be   => [qw(is_only_number)],
  	},{
  	    name => 'day',
  	    type => 'text',
  	    more => 1,
  	    less => 2,
  	    be   => [qw(is_only_number)],
  	}];
      }];
  }

=head1 DESCRIPTION

  HTML::FormStructure hold definition of FORM in your script.
  It have the part of generating FORM tags, validating via itself,
  and storeing cgi(apache request)'s parameters.
  You can access this object in the perl souce code or templates.

=head1 Form Accessor

=head2 action

  $form->action('foo.cgi');
  $form->action; # foo.cgi

=head2 method

  $form->method('POST');
  $form->method; # POST

=head2 enctype

  $form->enctype('multipart/form-data')
  $form->enctype; # multipart/form-data

=head2 r

  # cgi/apache-req alias.
  $form->r->param('query_name');
  $form->r->param('query_name' => $value);

=head2 validator

  # validator object
  $form->validator->method($form->r->param('foo'));
  $form->validator(YourValidate::Clsss->new);

=head1 Form Method

=head2 list_as_array

  # return the query objects as array.
  @queries = $form->list_as_array;

=head2 list_as_arrayref

  # return the query objects as arrayref.
  $queries = $form->list_as_array;

=head2 have

  # return the query objects that's defined.
  @queries       = $form->have('column');
  @error_queries = $form->have('error');

=head2 search

  # return the query objects that's equal
  @queries = $form->search(type => 'checkbox');

=head2 search_like

  # return the query objects that's matched.
  @queries = $form->search(stored => 'foo');

=head2 group

  # return that queries objects that's grouped by value.
  @queries = $form->group('scratch');

=head2 fetch

  # get the query object via query name.
  $query = $form->fetch('user_name'); # name => 'user_name'

=head2 param

  # get the query stored value via query name.
  # it does not return nothing before $form->store_request called.
  $store = $form->param('user_name');

=head2 store_request

  # store the value of cgi/apache-req's param as the 'store'.
  $form->store_request;
  $user_name = $form->param('user_name');

=head2 consist_query

  # combine all of consist query
  # each value is stored in r->param.
  $form->consist_query

=head2 hashref

  # return the key , value of form object.
  $hashref = $form->hashref(name => 'store');

=head2 validate

  # validating each query via "more|less|be"
  $form->validate;

=head2 error_messages

  # return error message.
  @error = $form->error_messages;

=head1 Query Accessor

=head2 name

  # query name
  $query->name;
  $query->name('val');

=head2 type

  # query type(text|password|file|hidden|radio|checkbox|select|textarea)
  $query->type;
  $query->type('val');

=head2 value

  # query value
  $query->value;
  $query->value('val');
  $query->value([1,2,3]);

=head2 checked

  # query checked
  $query->type('radio')
  $query->value('val');
  $query->checked('val');
  $query->tag; # <input type="radio" value="val" checked>

=head2 selected

  # query selected
  $query->type('selected')
  $query->value(['foo','bar','val']);
  $query->selected('val');
  $query->tag; # <option value="val" selected>

=head2 more

  # query min size
  $query->more('100'); # length 100 checked when validation

=head2 less

  # query max size
  $query->less('100'); # length 100 checked when validation

=head2 be

  # query validate method name or sub
  # called when $form->validate
  $query->be([qw(foo bar baz)]); # function or method named
                                 # foo,bar,and baz needed in the
                                 # current package.
  $query->be([sub { $_ eq 'foo' }]);

=head2 consist

  # define structure of consisted when form's query_combine called.
  $query->consist([{
    name => 'zip1',
    type => 'text',
  },{
    name => 'zip2',
    type => 'text',
  }]);
  # When query_combine called
  # default
	    for my $q ($query->array_of('consist')) {
		$value .= $self->r->param($q->name);
	    }

=head2 consistf

  # format of cosisted
  # consist_* have more priority than this accessor
  $query->consistf("%s-%s-%s");

=head2 store

  # query store cgi/apache-req's param
  $query->store;
  $query->store($cgi->param($query->name));

=head2 storef

  # query stored format
  $query->storef("%D");

=head2 column

  # query have column
  $query->column;
  $query->column(1);
  $query->column('column_name');

=head2 error

  # return query error(when validate)
  $query->error; # error message
  $query->store_error([qw(err1,err2)]);

=head2 tag_label

  # tag label
  $query->tag_label('user name');
  # in the template
  [% query.tag_label %] : [% query.tag %]
  # user name : <input type="text" name="foo">

=head2 tag_attr

  # tag attribute
  $query->tag_attrl('size = "10"');
  # in the template
  [% query.tag %]
  # <input type="text" name="foo" size="10">

=head2 tag_desc

  # tag description
  $query->tag_desc('only number');
  # in the template
  [% query.tag_label %] : [% query.tag %] *[% query.tag_desc %]
  # user name : <input type="text" name="foo"> * only number

=head2 tag_val_label

  # tag label having key
  $query->tag_val_label({ 1 => 'female', 2 => 'male' });
  # in the template
  [% query.tag %]
  # <input type="radio" name="sex" value="1"> female
  # <input type="radio" name="sex" value="2"> male

=head2 tag_left_in / tag_right_in

  $query->tag_val_label({ 1 => 'female', 2 => 'male' });
  $query->tag_left_in('<br>');
  $query->tag_right_in('<br>');
  # in the template
  [% query.tag %]
  # <input type="radio" name="sex" value="1"> female<br>
  # <input type="radio" name="sex" value="2"> male<br>

=head2 scratch

  # query scratch pad (free space)
  $query->scratch;
  $query->scratch('foo/bar');

=head1 Query Method

=head2 tag

  # generate query tag
  $query->tag;
  [% query.tag %]

=head2 is_checked

  # check query is check(it's type is 'radio/checkbox').
  $query->is_checked;

=head2 is_selected

  # check query is selected(it's type is 'select').
  $query->is_selected;

=head2 add (alias of add_right)

  # right concat. push if it's arrayref.
  $query->add(tag_attr => 'size ="10" '); # right

=head2 add_right

  # right concat. push if it's arrayref.
  $query->add(tag_attr => 'size ="10" ');

=head2 add_left

  # left concat. unshift if it's arrayref.
  $query->add(tag_attr => 'size ="10" ');

=head1 OPTION

=head2 form_accessors

  # additional accessor in the Form Class.

=head2 query_accessors

  # additional accessor in the Query Class.

=head1 AUTHOR

Naoto Ishikawa E<lt>toona@edge.jpE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
