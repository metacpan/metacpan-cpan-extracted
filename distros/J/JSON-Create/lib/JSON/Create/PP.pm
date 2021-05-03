=head1 NAME

JSON::Create::PP - Pure-Perl version of JSON::Create

=head1 DESCRIPTION

This is a backup module for JSON::Create. JSON::Create is written
using Perl XS, but JSON::Create::PP offers the same functionality
without the XS.

=head1 DEPENDENCIES

=over

=item L<B>

=item L<Carp>

This uses Carp to report errors.

=item L<Scalar::Util>

Scalar::Util is used to distinguish strings from numbers, detect
objects, and break encapsulation.

=item L<Unicode::UTF8>

This is used to handle conversion to and from character strings.

=back

=head1 BUGS

Printing of floating point numbers cannot be made to work exactly like
the XS version.

=cut

package JSON::Create::PP;
use parent Exporter;
our @EXPORT_OK = qw/create_json create_json_strict json_escape/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);
use warnings;
use strict;
use utf8;
use Carp qw/croak carp confess cluck/;
use Scalar::Util qw/looks_like_number blessed reftype/;
use Unicode::UTF8 qw/decode_utf8 valid_utf8 encode_utf8/;
use B;

our $VERSION = '0.34';

sub create_json
{
    my ($input, %options) = @_;
    my $jc = bless {
	output => '',
    };
    $jc->{_strict} = !! $options{strict};
    $jc->{_indent} = !! $options{indent};
    $jc->{_sort} = !! $options{sort};
    if ($jc->{_indent}) {
	$jc->{depth} = 0;
    }
    my $error = create_json_recursively ($jc, $input);
    if ($error) {
	$jc->user_error ($error);
	delete $jc->{output};
	return undef;
    }
    return $jc->{output};
}

sub create_json_strict
{
    my ($input, %options) = @_;
    $options{strict} = 1;
    return create_json ($input, %options);
}

# http://stackoverflow.com/questions/1185822/how-do-i-create-or-test-for-nan-or-infinity-in-perl#1185828

sub isinf {
    $_[0]==9**9**9;
}

sub isneginf {
    $_[0]==-9**9**9;
}

sub isnan {
    return ! defined( $_[0] <=> 9**9**9 ); 
}

sub isfloat
{
    my ($num) = @_;

    if ($num != int ($num)) {
	# It's clearly a floating point number
	return 1;
    }

    # To get the same result as the XS version we have to poke around
    # with the following. I cannot actually see what to do in the XS
    # so that I get the same printed numbers as Perl, it seems like
    # Perl is really monkeying around with NVs so as to print them
    # like integers when it can do so sensibly, and it doesn't make
    # the "I'm gonna monkey with this NV" information available to the
    # Perl programmer.

    my $r = B::svref_2object (\$num);
    my $isfloat = $r->isa("B::NV") || $r->isa("B::PVNV");
    return $isfloat;
}

# Built in booleans. The nasty PL_sv_(yes|no) stuff comes from
# JSON::Parse. The JSON::Create::Bool is from our own nice module.

sub isbool
{
    my ($input, $ref) = @_;
    my $poo = B::svref_2object ($ref);
    if (ref $poo eq 'B::SPECIAL') {
	# Leave the following commented-out code as reference for what
	# the magic numbers mean.

	# if ($B::specialsv_name[$$poo] eq '&PL_sv_yes') {
	if ($$poo == 2) {
	    return 'true';
	}
	# elsif ($B::specialsv_name[$$poo] eq '&PL_sv_no') {
	elsif ($$poo == 3) {
	    return 'false';
	}
    }
    return undef;
}

sub json_escape
{
    my ($input) = @_;
    $input =~ s/("|\\)/\\$1/g;
    $input =~ s/\x08/\\b/g;
    $input =~ s/\f/\\f/g;
    $input =~ s/\n/\\n/g;
    $input =~ s/\r/\\r/g;
    $input =~ s/\t/\\t/g;
    $input =~ s/([\x00-\x1f])/sprintf ("\\u%04x", ord ($1))/ge;
    return $input;
}

sub escape_all_unicode
{
    my ($jc, $input) = @_;
    my $format = "\\u%04x";
    if ($jc->{_unicode_upper}) {
	$format = "\\u%04X";
    }
    $input =~ s/([\x{007f}-\x{ffff}])/sprintf ($format, ord ($1))/ge;
    # Convert U+10000 to U+10FFFF into surrogate pairs
    $input =~ s/([\x{10000}-\x{10ffff}])/
	sprintf ($format, 0xD800 | (((ord ($1)-0x10000) >>10) & 0x3ff)) .
	sprintf ($format, 0xDC00 |  ((ord ($1)) & 0x3ff))
    /gex;
    return $input;
}

sub stringify
{
    my ($jc, $input) = @_;
    if (! utf8::is_utf8 ($input)) {
	if ($input =~ /[\x{80}-\x{FF}]/ && $jc->{_strict}) {
	    return "Non-ASCII byte in non-utf8 string";
	}
	if (! valid_utf8 ($input)) {
	    if ($jc->{_replace_bad_utf8}) {
		# Discard the warnings from Unicode::UTF8.
		local $SIG{__WARN__} = sub {};
		$input = decode_utf8 ($input);
	    }
	    else {
		return 'Invalid UTF-8';
	    }
	}
    }
    $input = json_escape ($input);
    if ($jc->{_escape_slash}) {
	$input =~ s!/!\\/!g;
    }
    if (! $jc->{_no_javascript_safe}) {
	$input =~ s/\x{2028}/\\u2028/g;
	$input =~ s/\x{2029}/\\u2029/g;
    }
    if ($jc->{_unicode_escape_all}) {
	$input = $jc->escape_all_unicode ($input);
    }
    $jc->{output} .= "\"$input\"";
    return undef;
}

sub validate_user_json
{
    my ($jc, $json) = @_;
    eval {
	JSON::Parse::assert_valid_json ($json);
    };
    if ($@) {
	return "JSON::Parse::assert_valid_json failed for '$json': $@";
    }
    return undef;
}

sub call_to_json
{
    my ($jc, $cv, $r) = @_;
    if (ref $cv ne 'CODE') {
	confess "Not code";
    }
    my $json = &{$cv} ($r);
    if (! defined $json) {
	return 'undefined value from user routine';
    }
    if ($jc->{_validate}) {
	my $error = $jc->validate_user_json ($json);
	if ($error) {
	    return $error;
	}
    }
    $jc->{output} .= $json;
    return undef;
}

# This handles a non-finite floating point number, which is either
# nan, inf, or -inf. The return value is undefined if successful, or
# the error value if an error occurred.

sub handle_non_finite
{
    my ($jc, $input, $type) = @_;
    my $handler = $jc->{_non_finite_handler};
    if ($handler) {
	my $output = &{$handler} ($type);
	if (! $output) {
	    return "Empty output from non-finite handler";
	}
	$jc->{output} .= $output;
	return undef;
    }
    if ($jc->{_strict}) {
	return "non-finite number";
    }
    $jc->{output} .= "\"$type\"";
    return undef;
}

sub handle_number
{
    my ($jc, $input) = @_;
    # Perl thinks that nan, inf, etc. look like numbers.
    if (isnan ($input)) {
	return $jc->handle_non_finite ($input, 'nan');
    }
    elsif (isinf ($input)) {
	return $jc->handle_non_finite ($input, 'inf');
    }
    elsif (isneginf ($input)) {
	return $jc->handle_non_finite ($input, '-inf');
    }
    elsif (isfloat ($input)) {
	# Default format
	if ($jc->{_fformat}) {
	    # Override. Validation is in
	    # JSON::Create::set_fformat.
	    $jc->{output} .= sprintf ($jc->{_fformat}, $input);
	}
	else {
	    $jc->{output} .= sprintf ("%.*g", 10, $input);
	}
    }
    else {
	# integer or looks like integer.
	$jc->{output} .= $input;
    }
    return undef;
}

sub newline_indent
{
    my ($jc) = @_;
    $jc->{output} .= "\n" . "\t" x $jc->{depth};
}

sub openB
{
    my ($jc, $b) = @_;
    $jc->{output} .= $b;
    if ($jc->{_indent}) {
	$jc->{depth}++;
	$jc->newline_indent ();
    }
}

sub closeB
{
    my ($jc, $b) = @_;
    if ($jc->{_indent}) {
	$jc->{depth}--;
	$jc->newline_indent ();
    }
    $jc->{output} .= $b;
    if ($jc->{_indent}) {
	if ($jc->{depth} == 0) {
	    $jc->{output} .= "\n";
	}
    }
}

sub comma
{
    my ($jc) = @_;
    $jc->{output} .= ',';
    if ($jc->{_indent}) {
	$jc->newline_indent ();
    }
}

sub array
{
    my ($jc, $input) = @_;
    $jc->openB ('[');
    my $i = 0;
    for my $k (@$input) {
	if ($i != 0) {
	    $jc->comma ();
	}
	$i++;
	my $error = create_json_recursively ($jc, $k, \$k);
	if ($error) {
	    return $error;
	}
    }
    $jc->closeB (']');
    return undef;
}

sub object
{
    my ($jc, $input) = @_;
    $jc->openB ('{');
    my @keys = keys %$input;
    if ($jc->{_sort}) {
	if ($jc->{cmp}) {
	    @keys = sort {&{$jc->{cmp}} ($a, $b)} @keys;
	}
	else {
	    @keys = sort @keys;
	}
    }
    my $i = 0;
    for my $k (@keys) {
	if ($i != 0) {
	    $jc->comma ();
	}
	$i++;
	my $error;
	$error = stringify ($jc, $k);
	if ($error) {
	    return $error;
	}
	$jc->{output} .= ':';
	$error = create_json_recursively ($jc, $input->{$k}, \$input->{$k});
	if ($error) {
	    return $error;
	}
    }
    $jc->closeB ('}');
    return undef;
}
sub newline_for_top
{
    my ($jc) = @_;
    if ($jc->{_indent} && $jc->{depth} == 0) {
	$jc->{output} .= "\n";
    }
}

sub create_json_recursively
{
    my ($jc, $input, $input_ref) = @_;
    if ($input_ref) {
	my $bool = isbool ($input, $input_ref);
	if ($bool) {
	    $jc->{output} .= $bool;
	    $jc->newline_for_top ();
	    return undef;
	}
    }
    if (! defined $input) {
	$jc->{output} .= 'null';
	$jc->newline_for_top ();
	return undef;
    }
    my $ref = ref ($input);
    if ($ref eq 'JSON::Create::Bool') {
	if ($$input) {
	    $jc->{output} .=  'true';
	}
	else {
	     $jc->{output} .= 'false';
	}
	$jc->newline_for_top ();
	return undef;
    }
    if (! keys %{$jc->{_handlers}} && ! $jc->{_obj_handler}) {
	my $origref = $ref;
	# Break encapsulation if the user has not supplied handlers.
	$ref = reftype ($input);
	if ($ref && $jc->{_strict}) {
	    if ($ref ne $origref) {
		return "Object cannot be serialized to JSON: $origref";
	    }
	}
    }
    if ($ref) {
	if ($ref eq 'HASH') {
	    my $error = $jc->object ($input);
	    if ($error) {
		return $error;
	    }
	}
	elsif ($ref eq 'ARRAY') {
	    my $error = $jc->array ($input);
	    if ($error) {
		return $error;
	    }
	}
	elsif ($ref eq 'SCALAR') {
	    if ($jc->{_strict}) {
		return "Input's type cannot be serialized to JSON";
	    }
	    my $error = $jc->create_json_recursively ($$input);
	    if ($error) {
		return $error;
	    }
	}
	else {
	    if (blessed ($input)) {
		if ($jc->{_obj_handler}) {
		    my $error = call_to_json ($jc, $jc->{_obj_handler}, $input);
		    if ($error) {
			return $error;
		    }
		}
		else {
		    my $handler = $jc->{_handlers}{$ref};
		    if ($handler) {
			if ($handler eq 'bool') {
			    if ($$input) {
				$jc->{output} .= 'true';
			    }
			    else {
				$jc->{output} .= 'false';
			    }
			}
			elsif (ref ($handler) eq 'CODE') {
			    my $error = $jc->call_to_json ($handler, $input);
			    if ($error) {
				return $error;
			    }
			}
			else {
			    confess "Unknown handler type " . ref ($handler);
			}
		    }
		    else {
			return "$ref cannot be serialized.\n";
		    }
		}
	    }
	    else {
		if ($jc->{_type_handler}) {
		    my $error = call_to_json ($jc, $jc->{_type_handler}, $input);
		    if ($error) {
			return $error;
		    }
		}
		else {
		    return "$ref cannot be serialized.\n";
		}
	    }	    
	}	
    }
    else {
	my $error;
	if (looks_like_number ($input) && $input !~ /^0[^.]/) {
	    $error = $jc->handle_number ($input);
	}
	else {
	    $error = stringify ($jc, $input);
	}
	if ($error) {
	    return $error;
	}
	$jc->newline_for_top ();
    }
    return undef;
}

sub user_error
{
    my ($jc, $error) = @_;
    if ($jc->{_fatal_errors}) {
	die $error;
    }
    else {
	warn $error;
    }
}

sub new
{
    return bless {
	_handlers => {},
    };
}

sub strict
{
    my ($jc, $onoff) = @_;
    $jc->{_strict} = !! $onoff;
}

sub get_handlers
{
    my ($jc) = @_;
    return $jc->{_handlers};
}

sub non_finite_handler
{
    my ($jc, $handler) = @_;
    $jc->{_non_finite_handler} = $handler;
    return undef;
}

sub bool
{
    my ($jc, @list) = @_;
    my $handlers = $jc->get_handlers ();
    for my $k (@list) {
	$handlers->{$k} = 'bool';
    }
}

sub cmp
{
    my ($jc, $cmp) = @_;
    $jc->{cmp} = $cmp;
}

sub escape_slash
{
    my ($jc, $onoff) = @_;
    $jc->{_escape_slash} = !! $onoff;
}

sub fatal_errors
{
    my ($jc, $onoff) = @_;
    $jc->{_fatal_errors} = !! $onoff;
}

sub indent
{
    my ($jc, $onoff) = @_;
    $jc->{_indent} = !! $onoff;
}

sub no_javascript_safe
{
    my ($jc, $onoff) = @_;
    $jc->{_no_javascript_safe} = !! $onoff;
}

sub obj
{
    my ($jc, %things) = @_;
    my $handlers = $jc->get_handlers ();
    for my $k (keys %things) {
	$handlers->{$k} = $things{$k};
    }
}

sub obj_handler
{
    my ($jc, $handler) = @_;
    $jc->{_obj_handler} = $handler;
}

sub replace_bad_utf8
{
    my ($jc, $onoff) = @_;
    $jc->{_replace_bad_utf8} = !! $onoff;
}

sub run
{
    goto &create;
}

sub create
{
    my ($jc, $input) = @_;
    $jc->{output} = '';
    my $error = create_json_recursively ($jc, $input);
    if ($error) {
	$jc->user_error ($error);
	delete $jc->{output};
	return undef;
    }
    if ($jc->{_downgrade_utf8}) {
	$jc->{output} = encode_utf8 ($jc->{output});
    }
    return $jc->{output};
}

sub set_fformat
{
    my ($jc, $fformat) = @_;
    JSON::Create::set_fformat ($jc, $fformat);
}

sub set_fformat_unsafe
{
    my ($jc, $fformat) = @_;
    if ($fformat) {
	$jc->{_fformat} = $fformat;
    }
    else {
	delete $jc->{_fformat};
    }
}

sub set_validate
{
    my ($jc, $onoff) = @_;
    $jc->{_validate} = !! $onoff;
}

sub JSON::Create::PP::sort
{
    my ($jc, $onoff) = @_;
    $jc->{_sort} = !! $onoff;
}

sub downgrade_utf8
{
    my ($jc, $onoff) = @_;
    $jc->{_downgrade_utf8} = !! $onoff;
}

sub set
{
    my ($jc, %args) = @_;
    for my $k (keys %args) {
	my $value = $args{$k};

	# Options are in alphabetical order

	if ($k eq 'bool') {
	    $jc->bool (@$value);
	    next;
	}
	if ($k eq 'cmp') {
	    $jc->cmp ($value);
	    next;
	}
	if ($k eq 'downgrade_utf8') {
	    $jc->downgrade_utf8 ($value);
	    next;
	}
	if ($k eq 'escape_slash') {
	    $jc->escape_slash ($value);
	    next;
	}
	if ($k eq 'fatal_errors') {
	    $jc->fatal_errors ($value);
	    next;
	}
	if ($k eq 'indent') {
	    $jc->indent ($value);
	    next;
	}
	if ($k eq 'no_javascript_safe') {
	    $jc->no_javascript_safe ($value);
	    next;
	}
	if ($k eq 'non_finite_handler') {
	    $jc->non_finite_handler ($value);
	    next;
	}
	if ($k eq 'obj_handler') {
	    $jc->obj_handler ($value);
	    next;
	}
	if ($k eq 'replace_bad_utf8') {
	    $jc->replace_bad_utf8 ($value);
	    next;
	}
	if ($k eq 'sort') {
	    $jc->sort ($value);
	    next;
	}
	if ($k eq 'strict') {
	    $jc->strict ($value);
	    next;
	}
	if ($k eq 'unicode_upper') {
	    $jc->unicode_upper ($value);
	    next;
	}
	if ($k eq 'validate') {
	    $jc->validate ($value);
	    next;
	}
	warn "Unknown option '$k'";
    }
}

sub type_handler
{
    my ($jc, $handler) = @_;
    $jc->{_type_handler} = $handler;
}

sub unicode_escape_all
{
    my ($jc, $onoff) = @_;
    $jc->{_unicode_escape_all} = !! $onoff;
}

sub unicode_upper
{
    my ($jc, $onoff) = @_;
    $jc->{_unicode_upper} = !! $onoff;
}

sub validate
{
    return JSON::Create::validate (@_);
}

sub write_json
{
    # Parent module function is pure perl.
    JSON::Create::write_json (@_);
}

1;
