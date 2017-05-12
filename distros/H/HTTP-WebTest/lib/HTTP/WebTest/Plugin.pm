# $Id: Plugin.pm,v 1.14 2003/03/02 11:52:10 m_ilya Exp $

package HTTP::WebTest::Plugin;

=head1 NAME

HTTP::WebTest::Plugin - Base class for HTTP::WebTest plugins.

=head1 SYNOPSIS

Not applicable.

=head1 DESCRIPTION

L<HTTP::WebTest|HTTP::WebTest> plugin classes can inherit from this class.
It provides some useful helper methods.

=head1 METHODS

=cut

use strict;

use HTTP::WebTest::TestResult;
use HTTP::WebTest::Utils qw(make_access_method);

=head2 new ($webtest)

Constructor.

=head3 Returns

A new plugin object that will be used by
L<HTTP::WebTest|HTTP::WebTest> object C<$webtest>.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = bless {}, $class;

    my $webtest = shift;

    $self->webtest($webtest);

    return $self;
};

=head2 webtest ()

=head3 Returns

An L<HTTP::WebTest|HTTP::WebTest> object that uses this plugin.

=cut

*webtest = make_access_method('WEBTEST');

=head2 global_test_param ($param, $optional_default)

=head3 Returns

If global test parameter C<$param> is not defined, returns
C<$optional_default> or C<undef> if there is no default.

If the global test parameter C<$param> is defined, returns it's value.

=cut

sub global_test_param {
    my $self = shift;
    my $param = shift;
    my $default = shift;

    my $value = $self->webtest->global_test_param($param);

    my $ret = defined $value ? $value : $default;

    return $self->_canonic_value($ret);
}

=head2 test_param ($param, $optional_default)

=head3 Returns

If latest test parameter C<$param> is not defined, returns
C<$optional_default> or C<undef> if there is no default.

If latest test parameter C<$param> is defined returns it's value.

=cut

sub test_param {
    my $self = shift;
    my $param = shift;
    my $default = shift;

    my $global_value = $self->webtest->global_test_param($param);

    my $value;
    if(defined $self->webtest->current_test) {
	$value = $self->webtest->current_test->param($param);
	$value = defined $value ? $value : $global_value;
    } else {
	$value = $global_value;
    }

    my $ret = defined $value ? $value : $default;

    return $self->_canonic_value($ret);
}

=head2 global_yesno_test_param ($param, $optional_default)

=head3 Returns

If the global test parameter C<$param> is not defined, returns
C<$optional_default> or false if no default exists.

If the global test parameter C<$param> is defined, returns true if latest
test parameter C<$param> is C<yes>, false otherwise.

=cut

sub global_yesno_test_param {
    my $self = shift;
    my $param = shift;
    my $default = shift || 0;

    my $value = $self->global_test_param($param);

    return $default unless defined $value;
    return $value =~ /^yes$/i;
}

=head2 yesno_test_param ($param, $optional_default)

=head3 Returns

If latest test parameter C<$param> is not defined returns
C<$optional_default> or false if it is not defined also.

If latest test parameter C<$param> is defined returns true if latest
test parameter C<$param> is C<yes>.  False otherwise.

=cut

sub yesno_test_param {
    my $self = shift;
    my $param = shift;
    my $default = shift || 0;

    my $value = $self->test_param($param);

    return $default unless defined $value;
    return $value =~ /^yes$/i;
}

# reference on hash that caches return value of subroutine calls
*_sub_cache = make_access_method('_SUB_CACHE', sub { {} });

# searches passed data structure for code references and replaces them
# with value returned by referenced subs
sub _canonic_value {
    my $self = shift;
    my $value = shift;

    if(ref($value) eq 'CODE') {
	# check if value is in cache; value returned from subroutine
	# is cached so we don't evaluate test parameter value more
	# than one time
	unless(${$self->_sub_cache}{$value}) {
	    ${$self->_sub_cache}{$value} = $value->($self->webtest);
	}

	$value = ${$self->_sub_cache}{$value};
    }

    if(ref($value) eq 'ARRAY') {
	$value = [ map $self->_canonic_value($_), @$value ];
    } elsif(ref($value) eq 'HASH') {
	for my $key (keys %$value) {
	    $value->{$key} = $self->_canonic_value($value->{$key});
	}
    }

    return $value;
}

=head2 test_result ($ok, $comment)

Factory method that creates test result object.

=head3 Returns

A L<HTTP::WebTest::TestResult|HTTP::WebTest::TestResult> object.

=cut

sub test_result {
    my $self = shift;
    my $ok = shift;
    my $comment = shift;

    my $result = HTTP::WebTest::TestResult->new;
    $result->ok($ok);
    $result->comment($comment);

    return $result;
}

# helper method used by validate_params and by global_validate_params
# to validate values of test parameters
sub _validate_params {
    my $self = shift;
    my %params = @_;

    my %param_types = grep $_ =~ /\S/, split /\s+/, $self->param_types;

    while(my($param, $value) = each %params) {
	next unless defined $value;

	my $type = $param_types{$param};
	die "HTTP::WebTest: unknown test parameter '$param'"
	    unless defined $type;

	$self->validate_value($param, $value, $type);
    }
}

=head2 validate_params (@params)

Checks test parameters in C<@params>.  Throws exception if any
of them are invalid.

=cut

sub validate_params {
    my $self = shift;
    my @params = @_;

    my %params = ();
    for my $param (@params) {
	$params{$param} = $self->test_param($param);
    }

    $self->_validate_params(%params);
}

=head2 global_validate_params (@params)

Checks global test parameters in C<@params>.  Throws exception
if any of them are invalid.

=cut

sub global_validate_params {
    my $self = shift;
    my @params = @_;

    my %params = ();
    for my $param (@params) {
	$params{$param} = $self->global_test_param($param);
    }

    $self->_validate_params(%params);
}

=head2 validate_value($param, $value, $type)

Checks if C<$value> of test parameter C<$param> has type <$type>.

=head3 Exceptions

Dies if check is not successful.

=cut

sub validate_value {
    my $self = shift;
    my $param = shift;
    my $value = shift;
    my $type = shift;

    # parse param type specification
    my($method, $args) = $type =~ /^ (\w+) (?: \( (.*?) \) )? $/x;
    die "HTTP::WebTest: bad type specification '$type'"
	unless defined $method;
    $method = 'check_' . $method;

    # get additional arguments for type validation sub
    $args = '' unless defined $args;
    my @args = eval " ( $args ) ";
    die "HTTP::WebTest: can't eval args '$args': $@"
	if $@;

    $self->$method($param, $self->_canonic_value($value), @args);
}

=head2 param_types ()

This method should be redefined in the subclasses.  Returns information
about test parameters that are supported by plugin.  Used to validate
tests.

=head3 Returns

A string that looks like:

    'param1 type1
     param2 type2
     param3 type3(optional,args)
     param4 type4'

=cut

sub param_types { '' }

=head2 check_anything ($value)

Method that checks whether test parameter value is of C<anything>
type.

This is NOOP operation.  It always succeed.

=cut

sub check_anything { 1 }

=head2 check_list ($param, $value, @optional_spec)

Method that checks whether test parameter value is of C<list>
type.  That is it is a reference on an array.

Optional list C<@optional_spec> can define specification on allowed
elements of list.  It can be either

    ('TYPE_1', 'TYPE_2', ..., 'TYPE_N')

or

    ('TYPE_1', 'TYPE_2', ..., 'TYPE_M', '...')

First specification requires list value of test parameter to contain
C<N> elements.  First element of list should be of should C<TYPE_1>
type, second element of list should of C<TYPE_2> type, ..., N-th
element of list should be of C<TYPE_N> type.

Second specification requires list value of test parameter to contain
at least C<N> elements.  First element of list should be of should
C<TYPE_1> type, second element of list should of C<TYPE_2> type, ...,
M-th element of list should be of C<TYPE_M> type, all following
elements should be of C<TYPE_M> type.

=head3 Exceptions

Dies if checks is not successful.

=cut

sub check_list {
    my $self = shift;
    my $param = shift;
    my $value = shift;
    my @spec = @_;

    die "HTTP::WebTest: parameter '$param' is not a list"
	unless ref($value) eq 'ARRAY';

    return unless @spec;

    my @list = @$value;
    my $prev_type = undef;
    for my $i (0 .. @list - 1) {
	my $type = shift @spec;

	die "HTTP::WebTest: too many elements in list parameter '$param'"
	    unless defined $type;

	if($type eq '...') {
	    $type = $prev_type;
	    push @spec, '...';
	}

	my $elem = $list[$i];

	$self->validate_value("$param\[$i]", $elem, $type);

	$prev_type = $type;
    }

    shift @spec if defined $spec[0] and $spec[0] eq '...';

    die "HTTP::WebTest: too few elements in list parameter '$param'"
	if @spec;
}

=head2 check_scalar ($param, $value, $optional_regexp)

Method that checks whether test parameter value is of C<scalar>
type (that is it is usual Perl scalar and is not a reference).

If C<$optional_regexp> is specified also checks value of parameter
using this regual expression.

=head3 Exceptions

Dies if check is not successful.

=cut

sub check_scalar {
    my $self = shift;
    my $param = shift;
    my $value = shift;
    my $optional_regexp = shift;

    die "HTTP::WebTest: parameter '$param' is not a scalar"
	unless not ref($value);

    return unless defined $optional_regexp;

    die "HTTP::WebTest: parameter '$param' doesn't match regexp '$optional_regexp'"
	unless $value =~ /$optional_regexp/i;
}

=head2 check_stringref ($param, $value)

Method that checks whether test parameter value is of C<stringref>
type (that is it is a reference on scalar).

=head3 Exceptions

Dies if check is not successful.

=cut

sub check_stringref {
    my $self = shift;
    my $param = shift;
    my $value = shift;

    die "HTTP::WebTest: parameter '$param' is not a scalar reference"
	unless ref($value) eq 'SCALAR';
}

=head2 check_uri ($param, $value)

Method that checks whether test parameter value is of C<uri>
type (that is it either scalar or L<URI|URI> object).

=head3 Exceptions

Dies if check is not successful.

=cut

sub check_uri {
    my $self = shift;
    my $param = shift;
    my $value = shift;

    my $ok = 1;
    eval { $self->check_scalar($param, $value) };
    if($@) {
	$ok = 0
	    unless defined ref($value) and UNIVERSAL::isa($value, 'URI');
    }

    die "HTTP::WebTest: parameter '$param' is not a URI"
	unless $ok;
}

=head2 check_hashlist ($param, $value)

Method that checks whether test parameter value is of C<hashlist>
type (that is it is either a hash reference or an array reference
that points to array containing even number of elements).

=head3 Exceptions

Dies if check is not successful.

=cut

sub check_hashlist {
    my $self = shift;
    my $param = shift;
    my $value = shift;

    my $ok = 1;
    eval { $self->check_list($param, $value) };
    if($@) {
	$ok = 0
	    unless ref($value) eq 'HASH';
    } else {
	$ok = 0
	    unless (@$value % 2) == 0;
    }

    die "HTTP::WebTest: parameter '$param' is neither a hash nor a list with even number of elements"
	unless $ok;
}

=head2 check_yesno ($param, $value)

Same as

    check_scalar($param, $value, '^(?:yes|no)$');

=cut

sub check_yesno {
    my $self = shift;
    my $param = shift;
    my $value = shift;

    check_scalar($param, $value, '^(?:yes|no)$');
}

=head1 COPYRIGHT

Copyright (c) 2001-2003 Ilya Martynov.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::API|HTTP::WebTest::API>

L<HTTP::WebTest::Plugins|HTTP::WebTest::Plugins>

L<HTTP::WebTest::ReportPlugin|HTTP::WebTest::ReportPlugin>

=cut

1;
