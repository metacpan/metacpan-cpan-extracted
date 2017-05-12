=head1 NAME

JSON::Create::PP - Pure-Perl version of JSON::Create

=head1 DESCRIPTION

This is a reference and backup module for JSON::Create. It is meant to
do exactly the same things as JSON::Create, but there are a few
discrepancies, which should be treated as bugs.

=head1 DEPENDENCIES

=over

=item L<B>

=item L<Carp>

This uses Carp to report errors.

=item L<Scalar::Util>

Scalar::Util is used to distinguish strings from numbers, detect
objects, and break encapsulation.

=item L<Unicode::UTF8>

This is used to do the validation of UTF-8.

=back

=head1 BUGS

Floating point printing cannot be made to work like the XS version.

The XS version tests for NV or IV directly, but it is next to
impossible to get this information from Perl without XS.

=cut

package JSON::Create::PP;
use parent Exporter;
our @EXPORT_OK = qw/create_json/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);
use warnings;
use strict;
use utf8;
use Carp qw/croak carp confess cluck/;
use Scalar::Util qw/looks_like_number blessed reftype/;
use Unicode::UTF8 qw/decode_utf8 valid_utf8/;
use B;

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
#  print "Looking at $num...";
    if ($num != int ($num)) {
#	print "it's obviously a float.\n";
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
#    print "$r\n";
    my $isfloat = $r->isa("B::NV") || $r->isa("B::PVNV");# && ! $r->isa ('B::IV');
    # if ($isfloat) {
    # 	print "it's a float";
    # }
    # else {
    # 	print "it's not a float";
    # }
    # print "\n";

    return $isfloat;
}

# This is for compatibility with JSON::Parse.

sub isbool
{
    my ($ref) = @_;
    my $poo = B::svref_2object ($ref);
    if (ref $poo eq 'B::SPECIAL') {
#	if ($B::specialsv_name[$$poo] eq '&PL_sv_yes') {
	if ($$poo == 2) {
	    return 'true';
	}
#	elsif ($B::specialsv_name[$$poo] eq '&PL_sv_no') {
	elsif ($$poo == 3) {
	    return 'false';
	}
    }
    return undef;
}

sub escape_all_unicode
{
    my ($jc, $input) = @_;
    my $format = "\\u%04x";
    if ($jc->{_unicode_upper}) {
	$format = "\\u%04X";
    }
    $input =~ s/([\x{007f}-\x{ffff}])/sprintf ($format, ord ($1))/ge;
    $input =~ s/([\x{10000}-\x{10ffff}])/
    sprintf ($format, 0xD800 | (((ord ($1)-0x10000) >>10) & 0x3ff)) .
    sprintf ($format, 0xDC00 |  ((ord ($1)) & 0x3ff))
    /gex;
    return $input;
}

sub stringify
{
    my ($jc, $input) = @_;
    my $abstraction_leaked;
    if (! utf8::is_utf8 ($input)) {
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
    $input =~ s/("|\\)/\\$1/g;
    $input =~ s/\x08/\\b/g;
    $input =~ s/\f/\\f/g;
    $input =~ s/\n/\\n/g;
    $input =~ s/\r/\\r/g;
    $input =~ s/\t/\\t/g;
    $input =~ s/([\x00-\x1f])/sprintf ("\\u%04x", ord ($1))/ge;
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
#	print "Validating...\n";
	my $error = $jc->validate_user_json ($json);
	if ($error) {
#	    cluck "Validating failed";
	    return $error;
	}
    }
    $jc->{output} .= $json;
    return undef;
}

sub handle_number
{
    my ($jc, $input) = @_;
    # Perl thinks that nan, inf, etc. look like numbers,
    # apparently.
    if (isnan ($input)) {
	$jc->{output} .= '"nan"';
    }
    elsif (isinf ($input)) {
	$jc->{output} .= '"inf"';
    }
    elsif (isneginf ($input)) {
	$jc->{output} .= '"-inf"';
    }
    elsif (isfloat ($input)) {
#	print "Priting floats.\n";
	# Default format
	if ($jc->{_fformat}) {
#	    print "Overriing floats with $jc->{_fformat} for $input.\n";
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
	# if ($jc->{_fformat}) {
	#     print "Overriing integer with $jc->{_fformat} for $input.\n";
	#     $jc->{output} .= sprintf ($jc->{_fformat}, $input);
	# }
	# else {
#	    print "INT $input\n";
	    # integer
	    $jc->{output} .= $input;
#	}
    }
    return undef;
}

sub create_json_recursively
{
    my ($jc, $input) = @_;
    if (! defined $input) {
	$jc->{output} .= 'null';
	return undef;
    }
    my $ref;
    my $error;
    if (keys %{$jc->{_handlers}} || $jc->{_obj_handler}) {
	$ref = ref ($input);
    }
    else {
	# Break encapsulation if the user has not supplied handlers.
	$ref = reftype ($input);
    }
    if ($ref) {
	if ($ref eq 'HASH') {
	    $jc->{output} .= '{';
	    for my $k (keys %$input) {
		my $error = stringify ($jc, $k);
		if ($error) {
		    return $error;
		}
		$jc->{output} .= ':';
		my $bool = isbool (\$input->{$k});
		if ($bool) {
		    $jc->{output} .= $bool;
		}
		else {
		    $error = create_json_recursively ($jc, $input->{$k});
		    if ($error) {
			return $error;
		    }
		}
		$jc->{output} .= ',';
	    }
	    $jc->{output} =~ s/,$/}/;
	}
	elsif ($ref eq 'ARRAY') {
	    $jc->{output} .= '[';
	    for my $k (@$input) {
		my $bool = isbool (\$k);
		if ($bool) {
		    $jc->{output} .= $bool;
		}
		else {
		    $error = create_json_recursively ($jc, $k);
		    if ($error) {
			return $error;
		    }
		}
		$jc->{output} .= ',';
	    }
	    $jc->{output} =~ s/,$/]/;
	}
	elsif ($ref eq 'SCALAR') {
	    $error = stringify ($jc, $$input);
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
#		    printf ("%s:%d: %s\n", __FILE__, __LINE__, $handler);
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
			    $error = $jc->call_to_json ($handler, $input);
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
	if (looks_like_number ($input) && $input !~ /^0/) {
	    $error = $jc->handle_number ($input);
	}
	else {
	    $error = stringify ($jc, $input);
	}
	if ($error) {
	    return $error;
	}
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

sub create_json
{
    my ($input, %options) = @_;
    my $output;
    my $jc = bless {
	output => '',
    };
    my $error = create_json_recursively ($jc, $input);
    if ($error) {
	$jc->user_error ($error);
	delete $jc->{output};
	return undef;
    }
    return $jc->{output};
}

sub new
{
    return bless {
	_handlers => {},
    };
}

sub get_handlers
{
    my ($jc) = @_;
    return $jc->{_handlers};
}

sub obj
{
    my ($jc, %things) = @_;
    my $handlers = $jc->get_handlers ();
    for my $k (keys %things) {
#	printf "%s:%d: Adding key %s for %s.\n", __FILE__, __LINE__, $things{$k}, $k;
	$handlers->{$k} = $things{$k};
    }
}

sub bool
{
    my ($jc, @list) = @_;
    my $handlers = $jc->get_handlers ();
    for my $k (@list) {
	$handlers->{$k} = 'bool';
    }
}

sub escape_slash
{
    my ($jc, $onoff) = @_;
    $jc->{_escape_slash} = !! $onoff;
}

sub set_fformat_unsafe
{
#    printf ("%s:%d: ", __FILE__, __LINE__);
#    print ("@_ OK\n");
    my ($jc, $fformat) = @_;
    if ($fformat) {
	$jc->{_fformat} = $fformat;
    }
    else {
	delete $jc->{_fformat};
    }
}

sub set_fformat
{
    my ($jc, $fformat) = @_;
    JSON::Create::set_fformat ($jc, $fformat);
}

sub run
{
    my ($jc, $input) = @_;
    $jc->{output} = '';
    my $error = create_json_recursively ($jc, $input);
    if ($error) {
	$jc->user_error ($error);
	delete $jc->{output};
	return undef;
    }
    return $jc->{output};
}

sub type_handler
{
    my ($jc, $handler) = @_;
    $jc->{_type_handler} = $handler;
}

sub obj_handler
{
    my ($jc, $handler) = @_;
#    print "Handler for object set.\n";
    $jc->{_obj_handler} = $handler;
}

sub no_javascript_safe
{
    my ($jc, $onoff) = @_;
    $jc->{_no_javascript_safe} = !! $onoff;
}

sub set_validate
{
    my ($jc, $onoff) = @_;
    $jc->{_validate} = !! $onoff;
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

sub fatal_errors
{
    my ($jc, $onoff) = @_;
    $jc->{_fatal_errors} = !! $onoff;
}

sub replace_bad_utf8
{
    my ($jc, $onoff) = @_;
    $jc->{_replace_bad_utf8} = !! $onoff;
}

sub validate
{
    return JSON::Create::validate (@_);
}

1;
