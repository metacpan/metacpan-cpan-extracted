# DbgrProperties.pm -- Move all the property-handling code
# into this module.
#
# Copyright (c) 1998-2006 ActiveState Software Inc.
# All rights reserved.
# 
# Xdebug compatibility, UNIX domain socket support and misc fixes
# by Mattia Barbon <mattia@barbon.org>
# 
# This software (the Perl-DBGP package) is covered by the Artistic License
# (http://www.opensource.org/licenses/artistic-license.php).

package DB::DbgrProperties;

use strict qw(vars subs);

our $VERSION = 0.10;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
	     doPropertySetInfo
	     emitEvalResultAsProperty
	     emitEvaluatedPropertyGetInfo
	     figureEncoding
	     getFullPropertyInfoByValue
	     makeFullPropertyName
	     );
our @EXPORT_OK = ();

use overload;

use DB::Data::Dump;
use DB::DbgrCommon;

# Internal sub declarations

sub adjustLongName($$$);
sub makeFullPropertyName($$);

# And recursively-called exported routines:

sub figureEncoding($);
sub getFullPropertyInfoByValue($$$$$$);

our $ldebug = 0;

# Exported subs

=head1 postconditions

This function does one of three things:

1. Throw an exception: let the caller deal with it, and formulate
an error message.

2. Assign a value to a local value if it's a non-top-level stack
Return undef

3. Return [$property_long_name, undef, 1]
and let the caller do an eval to carry out the assignment.

=cut

sub doPropertySetInfo($$$) {
    my ($cmd,
	$transactionID,
	$property_long_name) = @_;
    
    if (!defined $property_long_name) {
	return makeErrorResponse($cmd,
				 $transactionID,
				 DBP_E_InvalidOption,
				 "-n full-property-name missing");
    } else {
	# In Perl these can be modified.  Setting $_[x] to a value
	# changes the underlying object if it isn't constant.
	# Other changes will be ignored.
	return [$property_long_name, undef, 1];
    }
}

sub emitEvaluatedPropertyGetInfo($$$$$$$) {
    my ($cmd,
	$transactionID,
	$nameAndValue,
	$property_long_name, # For the response things.
	$propertyKey,
	$maxDataSize,
	$pageIndex) = @_;

    my $res = sprintf(qq(%s\n<response %s command="%s" 
			 transaction_id="%s" ),
		      xmlHeader(),
		      namespaceAttr(),
		      $cmd,
		      $transactionID);
    my $finalName = $nameAndValue->[NV_NAME];
    my $finalVal = $nameAndValue->[NV_VALUE];

    $res .= '>' if $cmd ne 'property_value';
    my $startTag = $cmd ne 'property_value' ? '<property' : '';
    my $endTag = $cmd ne 'property_value' ? '</property>' : '';
    $res .= _getFullPropertyInfoByValue($startTag, $endTag,
					$propertyKey || $finalName, # name
					$finalName,
					$finalVal,
					$maxDataSize,
					$pageIndex, # page
					0, # current depth
					);
    $res .= "\n</response>";
    printWithLength($res);
}

sub _truncateIfNecessary {
    my($res, $maxDataSize, $stripOuterBrackets) = @_;
    if ($stripOuterBrackets && $res =~ /^([\[\{\(\<]).*([\]\}\)\>])$/) {
	substr($res, 0, 1) = "";
	substr($res, -1, 1) = "";
    }
    # Truncate if exceeds size
    if ($maxDataSize > 0) {
	$maxDataSize -= 2 if $stripOuterBrackets;
	if (length($res) > $maxDataSize) {
	    dblog("_truncateIfNecessary: Have length(\$res) = ", length($res), " > $maxDataSize") if $ldebug;
	    if ($maxDataSize >= 3) {
		$res = substr($res, 0, ($maxDataSize - 3)) . "...";
	    } else {
		$res = substr($res, 0, $maxDataSize);
	    }
	    dblog("_truncateIfNecessary: After: length(\$res) = ", length($res)) if $ldebug;
	}
    }
    return $res;
}

sub emitEvalResultAsProperty($$$$$$) {
    my ($cmd,
	$transactionID,
	$property_long_name,
	$valRefs,
	$maxDataSize,
	$pageIndex) = @_;
    my $res = sprintf(qq(%s\n<response %s command="%s" 
			 transaction_id="%s" >),
		      xmlHeader(),
		      namespaceAttr(),
		      $cmd,
		      $transactionID);
    $res .= getFullPropertyInfoByValue($property_long_name, # name
				       $property_long_name,
				       $valRefs,
				       $maxDataSize,
				       $pageIndex,
				       0, # current depth
				       );
    $res .= "\n</response>";
    printWithLength($res);
}

sub propertyTagSpacer($) {
    my ($currentDepth) = @_;
    return ("\n" . ('  ' x $currentDepth));
}

sub containsWideChar {
    my ($str) = @_;
    require bytes;
    if (bytes::length($str) > length($str)
	|| $str =~ /[\x00-\x08\x0b\x0c\x0e-\x1f\x7f-\xff]/
	|| $str =~ /[^\0-\xff]/) {
	return 1;
    }
    return 0;
}
    
sub figureEncoding($) {
    my ($val) = @_;
    my ($encVal);
    my $encoding = $settings{data_encoding}->[0];
    my $hasWide = containsWideChar($val);
    if ($encoding eq 'none' || $encoding eq 'binary') {
	if ($val =~ m/[\x00-\x08\x0b\x0c\x0e-\x1f]/) {
	    # Override
	    $encoding = 'base64';
	}
    }
    if ($hasWide && $encoding eq 'base64') {
	$val = nonXmlChar_Encode($val);
    }
    $encVal = encodeData($val, $encoding);
    if ($encoding eq 'none' || $encoding eq 'binary') {
	$encVal = xmlEncode($encVal);
    }
    return ($encoding, $encVal);
}

sub _attr_needs_base64_encoding {
    my ($val) = @_;
    return ($val =~ /[^\x20-\x7f]/);
}

sub getFullPropertyInfoByValue($$$$$$) {
    _getFullPropertyInfoByValue('<property', '</property>', @_);
}

sub _getFullPropertyInfoByValue {
    my ($startTag,
	$endTag,
	$name,
	$fullname,
	$val,
	$maxDataSize,
	$pageIndex,
	$currentDepth,
	) = @_;
    require Scalar::Util;

    # dblog("getFullPropertyInfoByValue: (@_)\n");
    my $encoding;
    my $res = $startTag;
    if ($currentDepth > 0) {
	$res .= propertyTagSpacer($currentDepth);
    }
    my %b_attr = (name => $name, fullname => $fullname);
    my %b_needs_attr;
    $b_needs_attr{name} = _attr_needs_base64_encoding($name);
    $b_needs_attr{fullname} = _attr_needs_base64_encoding($fullname);
    while (my($k, $v) = each %b_needs_attr) {
	if (!$v) {
	    $res .= sprintf(qq( $k="%s"), xmlAttrEncode($b_attr{$k}));
	    delete $b_attr{$k};
	}
    }
    my $typeString;
    my $hasChildren = 0;
    my $numChildren;
    my $className;
    my $encVal = undef;
    my $encValLength = undef;
    my $address;
    my $hasValue = 1;
    my $variableGroup = -1;
    use constant VARIABLE_GROUP_ARRAY => 1;
    use constant VARIABLE_GROUP_HASH => 2;
    if (!defined $val) {
	$typeString = 'undef';
    } else {
	# Unlike getPropertyInfo, this is where we find
	# arrays and hashes
	if (my $reftype = Scalar::Util::reftype($val)) {
	    my $refstr = ref $val;
	    $className = Scalar::Util::blessed($val);
	    $address = Scalar::Util::refaddr($val);
	    $typeString = defined $className ? $className : $reftype;
	    $hasValue = 0;
	    if ($reftype eq 'HASH') {
		$variableGroup = VARIABLE_GROUP_HASH;
		$numChildren = keys %$val;
	    } elsif ($reftype eq 'ARRAY') {
		$variableGroup = VARIABLE_GROUP_ARRAY;
		$numChildren = @$val;
	    } elsif (defined $className || $reftype eq 'SCALAR' || $reftype eq 'REF') {
		# object but not array/hash: it's a scalar
		$numChildren = 1;
	    }
	    if ($reftype eq 'REGEXP' || (
		    $] < 5.012 &&
		    $reftype eq 'SCALAR' &&
		    $className eq 'Regexp' &&
		    _hasQrMagic($val))) {
		# Special-case -- only one in Perl?
		$val = substr("$val", 0, $maxDataSize);
		($encoding, $encVal) = figureEncoding($val);
		$res .= sprintf(qq( encoding="%s"), $encoding);
		$encValLength = length($encVal);
		$numChildren = 0;
		$hasValue = 1;
	    }
	} else {
	    # It's a scalar -- get the underlying value and classify.
	    # First convert wide chars to utf-8
	    my $val2 = nonXmlChar_Encode($val);
	    my $val3 = _truncateIfNecessary($val2, $maxDataSize, 0);
	    ($encoding, $encVal) = figureEncoding($val3);
	    $res .= sprintf(qq( encoding="%s"), $encoding);
	    $encValLength = length($encVal);
	    $typeString = getCommonType($val2);
	}
	$hasChildren = !!$numChildren;
    }
    $res .= sprintf(qq( type="%s"), xmlAttrEncode($typeString));
    $res .= qq( constant="0");
    if ($hasChildren) {
	$res .= qq( children="1" numchildren="$numChildren");
	if (defined $address) {
	    $res .= qq( address="$address");
	}
    } else {
	$res .= qq( children="0");
    }

    if ($hasChildren) {
	$res .= qq( size="0");
	$res .= qq( page="$pageIndex");
	$res .= sprintf(qq( pagesize="%d"), $settings{max_children}[0]);
	# Get each child property
	if ($currentDepth < $settings{max_depth}[0]) {
	    my $childrenPerPage = $settings{max_children}[0];
	    my $startIndex = $pageIndex * $childrenPerPage;
	    my $endIndex = $startIndex + $childrenPerPage - 1;
	    if ($variableGroup == VARIABLE_GROUP_ARRAY) {
		my $arraySize = scalar @$val;
		#### ???? $res .= sprintf(qq( numchildren="%d"), $arraySize);
		$res .= qq(>);
		$res .= _getFullPropertyInfoByValue_emitNames($maxDataSize, %b_attr);
		if ($startIndex < $arraySize) {
		    if ($endIndex >= $arraySize) {
			$endIndex = $arraySize - 1;
		    }
		    for (my $i = $startIndex; $i <= $endIndex; $i++) {
			my ($newInnerName, $newFullName) =
			    adjustLongName($fullname, $i, 1);
			my $innerProp =
			    getFullPropertyInfoByValue($newInnerName,
						       $newFullName,
						       $val->[$i],
						       $maxDataSize,
						       # For inner children,
						       # show first page
						       0,
						       $currentDepth + 1);
			$res .= "$innerProp";
		    }
		}
	    } elsif ($variableGroup == VARIABLE_GROUP_HASH) {
		my @keys = sort keys %$val;
		my $arraySize = scalar @keys;
		#### ???? $res .= sprintf(qq( numchildren="%d"), $arraySize);
		$res .= qq(>);
		$res .= _getFullPropertyInfoByValue_emitNames($maxDataSize, %b_attr);
		if ($startIndex < $arraySize) {
		    if ($endIndex >= $arraySize) {
			$endIndex = $arraySize - 1;
		    }
		    for (my $i = $startIndex; $i <= $endIndex; $i++) {
			my $k = $keys[$i];
			my ($newInnerName, $newFullName) =
			    adjustLongName($fullname, $k, 0);
			my $innerProp =
			    getFullPropertyInfoByValue($newInnerName,
						       $newFullName,
						       $val->{$k},
						       $maxDataSize,
						       # For inner children,
						       # show first page
						       0,
						       $currentDepth + 1);
			$res .= "$innerProp";
		    }
		}
	    } else {
		# Objects just have one child
		#### $res .= qq( numchildren="1");
		$res .= qq(>);
		$res .= _getFullPropertyInfoByValue_emitNames($maxDataSize, %b_attr);
		my $innerProp =
		    getFullPropertyInfoByValue("->",
					       "\${$fullname}",
					       $$val,
					       $maxDataSize,
					       # For inner children,
					       # show first page
					       0,
					       $currentDepth + 1);
		$res .= "$innerProp";
	    }
	} else {
	    # End the start-tag.
	    $res .= qq( >);
	    $res .= _getFullPropertyInfoByValue_emitNames($maxDataSize, %b_attr);
	}
	$res .= $endTag . qq(\n);
    } else {
	$res .= qq( size="$encValLength") if defined $encValLength;
	$res .= qq( >);
	$res .= _getFullPropertyInfoByValue_emitNames($maxDataSize, %b_attr);
	if (!$hasValue || !defined($encVal)) {
	    # Do nothing
	} elsif ($DB::xdebug_no_value_tag) {
	    $res .= $encVal;
	} else {
	    $res .= sprintf(qq(<value%s><![CDATA[%s]]></value>\n),
			    $encoding ? qq( encoding="$encoding") : "",
			    $encVal);
	}
	$res .= $endTag;
	$res .= "\n" if $currentDepth == 0;
    }
    # dblog("getFullPropertyInfoByValue: \{$res}\n");
    return $res;
}

sub _hasQrMagic {
    my ($val) = @_;

    require B;

    my $b = B::svref_2object($val);

    return unless $b->isa('B::PVMG');
    for (my $m = $b->MAGIC; $m; $m = $m->MOREMAGIC) {
        return 1 if $m->TYPE eq 'r';
    }

    return 0;
}

sub _getFullPropertyInfoByValue_emitNames {
    my ($maxDataSize, %b_attr) = @_;
    my $ret = "";
    while (my ($k, $v) = each %b_attr) {
	my $val2 = nonXmlChar_Encode($v);
	my $val3 = _truncateIfNecessary($val2, $maxDataSize, 0);
	$ret .= (qq(<$k encoding="base64">)
		 . xmlAttrEncode(encodeData($val3, 'base64'))
		 . "</$k>\n");
    }
    return $ret;
}

#############################################################################

# Internal subs

sub adjustLongName($$$) {
    my ($fullname, $key, $isArray) = @_;
    if ($isArray) {
	if ($fullname =~ m/^(\@)(.*)/) {
	    return ("[$key]", sprintf('$%s[%d]', $2, $key));
	} else {
	    return ("->[$key]", "${fullname}->[$key]");
	}
    } else {
        # Don't use Data::Dump for hash keys, as it's doing too
        # much processing on hash keys.
        # Data::Dump was used to fix bugs 79892, 79894, and 79895 in r22847.
        # However Data::Dump \x-encodes high-bit characters,
        # which makes them hard to read in the UI, so we need to do
        # our own encoding.
        # This change fixes bug 83959
	if ($key =~ /^-?[a-zA-Z_]\w*$/) {
	    # Don't quote barewords
	} elsif ($key =~ /^-?[1-9]\d{0,8}$/ || $key eq "0") {
            # Don't quote integers
        } else {
            # Convert low-byte values, leave high-byte values alone,
            # and backslash-escape the usual suspects.
            $key =~ s{([\\\"\$\@\*\%])}
                     {\\$1}g;
            $key =~ s{([\x00-\x08\x0b\x0c\x0e-\x1f])}
                     {sprintf('\\x%02x', hex(ord($1)))}egx;
            $key =~ s{\t}{\\t}gx;
            $key =~ s{\r}{\\r}gx;
            $key =~ s{\n}{\\n}gx;
            $key = '"' . $key . '"';
	}
	if ($fullname =~ m/^(\%)(.*)/) {
	    # Verify that single-quotes won't nest.
	    return ("{$key}", sprintf(q($%s{%s}), $2, $key));
	} else {
	    return ("->{$key}", "${fullname}->{$key}");
	}
    }
}

sub makeFullPropertyName($$) {
    my ($property_long_name, $propertyKey) = @_;
    if (!$propertyKey) {
	return ($property_long_name, undef);
    } elsif ($property_long_name =~ /^[\@\%](.*)/) {
	return (sprintf(q($%s%s), $1, $propertyKey), $propertyKey);
    } elsif ($propertyKey =~ /^->/) {
	return (sprintf(q(%s%s), $property_long_name, $propertyKey), $propertyKey);
    } else {
	return (sprintf(q(%s->%s), $property_long_name, $propertyKey), "->$propertyKey");
    }
}

1;
