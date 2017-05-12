#
# $Id: typemap.PL,v 38.2 2012/09/26 16:10:09 jettisu Exp $
#
# (c) 1999-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#
# Script to generate a typemap from the MQSeries header files
#
# Whenever it encounters a new type, it starts building up two hashes,
# %input, and %output.  $input{TYPE} is the input section of the
# typemap for the TYPE, and $output{TYPE} is the output section of the
# typemap.
#
# The actual code used to convert a field can be found in:
#
#       &long_output, &long_input               for MQLONG types
#       &string_output, &string_input           for MQCHARn types
#       &byte_output, &byte_input               for MQBYTE types
#       &charv_output, &charv_input             for MQCHARV types
#
# Other types are not yet supported, and those that are not relevant
# are skipped intentionally.  Warnings should be due to new
# structures, and should be reviewed.
#

$input{'MQCHAR48'} = join('',
                          '/*' . '=' x 75 . "*/\n",
                          "T_MQCHAR48\n",
                          "    strncpy(\$var, (char*)SvPV(\$arg, PL_na), 48)\n",
                          );

require "../util/parse_config";
require "../util/parse_headers";

@ARGV = @headers;

my $debug = $ENV{DEBUG_TYPEMAP_PL};

open(STDOUT, '>', "typemap") || die "$0: error writing typemap: $!\n";

my $skipping = 0;
while ( <> ) {

    if (/typedef\s+struct\s+tag(\w+)/) {
        # entry into a new type
        $type = $1;

	#
	# We skip some types not used for MQI calls, or ahndled
	# manually instead of typemaps
	#
	if (grep { $type eq $_ } 
	    qw(MQCFIN MQCFIN64 MQIMPO MQWDR MQWDR2 MQXEPO)) {
	    $skipping = 1;
	    next;
	}
	$skipping = 0;

        print "#we're starting a $type\n" if $debug;
        $input{$type} = &input_header($type);
        $output{$type} = &output_header($type);
	next;
    } 
    next if ($skipping);

    if (/\}\s+(MQ\w+);/) {
        # exit of a type.  Probably should assert that $type2 eq $type
        $type2 = $1;
        print "#we're ending a $type ($type2)\n" if $debug;
        $input{$type} .= &input_footer($type);
        undef $type;
    } elsif ($type && /^\s*\}\s*;\s*$/) {
        # exit of a type in 5.3 headers
        print "#we're ending a $type\n" if $debug;
        $input{$type} .= &input_footer($type);
        undef $type;
    } elsif ($type && ($_ =~ /\s+(MQ\w+)\s+(\w+);/)) {
        # found a new field of type $fieldt and name $field:
        $fieldt = $1;
        $field = $2;

        next if $field eq "StrucId";
        print "#Found a $field of type $fieldt\n" if $debug;

        #
        # A list of known types we don't support.  Ignore them.
        #
        next if (grep { $fieldt eq $_ }
                 qw(MQPTR MQMD1 MQHCONN MQPOINTER MQPID MQTID MQHCONFIG
		    MQAXP MQCFH MQXEPO));

        if ($fieldt eq 'MQLONG' ||
            $fieldt eq 'MQHOBJ' ||
            $fieldt eq 'MQBOOL') {
            $strlen = length($field);

            $input{$type} .= &long_input($field);
            $output{$type} .= &long_output($field);

        } elsif ($fieldt eq 'MQHMSG' || $fieldt eq 'MQINT64') {
            # MQHMSG is a MQINT64, not a MQLONG (or MQULONG)
            $input{$type} .= &int64_input($field);
            $output{$type} .= &int64_output($field);

        } elsif ($fieldt =~ /^MQCHAR(\d*)$/) {
            $size = $1;

            if ($size == 0) {
                $size = 1;
            }
            $output{$type} .= &string_output($field, $size);
            $input{$type} .= &string_input($field, $size);
        } elsif ($fieldt =~ /^MQBYTE(\d*)$/) {
            $size = $1;

            if ($size == 0) {
                $size = 1;
            }
            $output{$type} .= &byte_output($field, $size);
            $input{$type} .= &byte_input($field, $size);
	} elsif ($fieldt eq 'MQCHARV') {
            $input{$type} .= &charv_input($field);
            $output{$type} .= &charv_output($field);
        } else {
            warn "$0: warning: type $type.$field ($fieldt) not supported\n";
        }

    }

}


print <<"EOF";
MQBYTE          T_U_CHAR
PMQBYTE         T_PV
MQBYTE16        T_PV
PMQBYTE16       T_PV
MQBYTE24        T_PV
PMQBYTE24       T_PV
MQBYTE32        T_PV
PMQBYTE32       T_PV
# Character Datatypes
MQCHAR          T_CHAR
PMQCHAR         T_PV
MQCHAR4         T_PV
PMQCHAR4        T_PV
MQCHAR8         T_PV
PMQCHAR8        T_PV
MQCHAR12        T_PV
PMQCHAR12       T_PV
MQCHAR28        T_PV
PMQCHAR28       T_PV
MQCHAR32        T_PV
PMQCHAR32       T_PV
MQCHAR48        T_MQCHAR48
PMQCHAR48       T_PV
MQCHAR64        T_PV
PMQCHAR64       T_PV
MQCHAR128       T_PV
PMQCHAR128      T_PV
MQCHAR256       T_PV
PMQCHAR256      T_PV
# Other Datatypes
MQLONG          T_IV
PMQLONG         T_OPAQUEPTR
MQULONG         T_UV
MQHCONN         T_IV
PMQHCONN        T_OPAQUEPTR
MQHOBJ          T_IV
PMQHOBJ         T_OPAQUEPTR
MQHMSG          T_IV
PMQHMSG         T_OPAQUEPTR
MQPTR           T_PV
PMQPTR          T_PV
PMQVOID         T_PV
PPMQVOID        T_PV

# Structures
MQAIR           T_MQAIR
MQBMHO          T_MQBMHO
MQBO            T_MQBO
MQCHARV         T_MQCHARV
MQCMHO          T_MQCMHO
MQCNO           T_MQCNO
MQDH            T_MQDH
MQDLH           T_MQDLH
MQDMHO          T_MQDMHO
MQDMPO          T_MQDMPO
MQGMO           T_MQGMO
MQIIH           T_MQIIH
MQMD            T_MQMD
MQMDE           T_MQMDE
MQMD1           T_MQMD1
MQMHBO          T_MQMHBO
MQOD            T_MQOD
MQOR            T_MQOR
MQPD            T_MQPD
MQPMO           T_MQPMO
MQRFH           T_MQRFH
MQRMH           T_MQRMH
MQRR            T_MQRR
MQSCO           T_MQSCO
MQSMPO          T_MQSMPO
MQSTS           T_MQSTS
MQTM            T_MQTM
MQTMC2          T_MQTMC2
MQXQH           T_MQXQH

MQCFH           T_MQCFH
MQCFIL          T_MQCFIL
MQCFIN          T_MQCFIN
MQCFSL          T_MQCFSL
MQCFST          T_MQCFST

# Input of the above types:
INPUT
EOF

foreach $type (sort keys %input) {
    print $input{$type}, "\n";
}

print "# Output of the above types:\nOUTPUT\n";
foreach $type (sort keys %output) {
    print $output{$type}, "\n";
}


#==============================================================================
sub long_input {
    my($field) = @_;
    my($strlen) = length($field);

    return <<"EOF";
        if (hv_exists((HV*)SvRV(\$arg),\\"$field\\",$strlen))
          \$var.$field = SvIV(*(hv_fetch((HV*)SvRV(\$arg),
                \\"$field\\",$strlen,0)));
EOF
}
#==============================================================================
sub long_output {
    my($field, $hash) = @_;
    my($strlen) = length($field);

    $hash = 0 unless $hash;
    return <<"EOF";
        hv_store((HV*)SvRV(\$arg),\\"$field\\",$strlen,
                 (newSViv(\$var.$field)),$hash);
EOF
}
#==============================================================================
sub int64_input {
    my($field) = @_;
    my($strlen) = length($field);

    return <<"EOF";
        if (hv_exists((HV*)SvRV(\$arg),\\"$field\\",$strlen)) {
          SV *Value = *(hv_fetch((HV*)SvRV(\$arg),\\"$field\\",$strlen,0));
          if (sizeof(IV) >= 8 || SvIOKp(Value)) {
            \$var.$field = (MQINT64)SvIV(Value);
          } else {
            char   *val;
            STRLEN  len;
            val = SvPV(Value, len);
            if (!sscanf(val, \\"%\\" SCNdLEAST64, &\$var.$field)) {
              croak(\\"Cannot turn string '%s' into a 64-bit number\\", val);
            }
          }
        }
EOF
}
#==============================================================================
sub int64_output {
    my($field, $hash) = @_;
    my($strlen) = length($field);

    $hash = 0 unless $hash;
    return <<"EOF";
        if (sizeof(IV) >= 8) {
          hv_store((HV*)SvRV(\$arg),\\"$field\\",$strlen,
                   (newSViv((IV)\$var.$field)),$hash);
        } else {
          char   printed_number[32];
          STRLEN len;
          sprintf(printed_number, \\"%\\" PRIdLEAST64, \$var.$field);
          len = strlen((const char *)printed_number);
          hv_store((HV*)SvRV(\$arg),\\"$field\\",$strlen,
                   (newSVpvn(printed_number,len)),$hash);
        }
EOF
}
#==============================================================================
sub string_output {
    my ($field, $fieldsize, $hash) = @_;
    my $fieldnamelen = length($field);
    my $isptr = '';

    $hash = 0 unless $hash;
    if ($fieldsize == 1) {
        $isptr = "&";
	return <<"EOF";
        hv_store((HV*)SvRV(\$arg),\\"$field\\",$fieldnamelen,
                 (newSVpv($isptr\$var.$field, $fieldsize)),$hash);
EOF
	;
    }

    #
    # Strings over 1 character: trim zeroes (i.e. only return actual
    # size used, which could be the empty string)
    #
    return <<"EOF";
        {
            STRLEN len = mqstrnlen($isptr\$var.$field, $fieldsize);
            hv_store((HV*)SvRV(\$arg),\\"$field\\",$fieldnamelen,
                     (newSVpv($isptr\$var.$field, len)),$hash);
        }
EOF
    ;
}
#==============================================================================
sub string_input {
    my($field, $fieldsize) = @_;
    my($fieldnamelen) = length($field);
    my($isptr);

    if ($fieldsize == 1) {
        $isptr = "&";
    }

    return <<"EOF";
        if (hv_exists((HV*)SvRV(\$arg), \\"$field\\", $fieldnamelen)) {
            SV        **scalar;
            STRLEN      StringLength;
            const char *StringData;

            /* Need to deal with undersized data.  Only copy supplied bytes. */
            scalar = hv_fetch((HV *)SvRV(\$arg), \\"$field\\", $fieldnamelen, 0);
            if (SvOK(*scalar)) { /* Defined */
                StringData = SvPV(*scalar, StringLength);
                strncpy($isptr\$var.$field,
                        StringData,
                        StringLength > $fieldsize ? $fieldsize : StringLength);
            }
        }


EOF
}
#==============================================================================
sub input_header {
    my($type) = @_;

    return <<"EOF";
/*===========================================================================*/
T_$type
    {
        /* input a $type */
        $type default_$type = { ${type}_DEFAULT };

        if (!SvROK(\$arg))
            croak(\\"Reference expected for parameter \$var\\");
        /* copy in the default value of structure... */
        memcpy((char *)&\$var, &default_$type, sizeof($type));

EOF
}
#==============================================================================
sub input_footer { "    }\n"; }
#==============================================================================
sub output_header {
    my($type) = @_;

    return <<"EOF";
/*===========================================================================*/
T_$type
    /* output a $type: */


EOF
}
#==============================================================================
sub byte_output {
    my($field, $fieldsize, $hash) = @_;
    my($fieldnamelen) = length($field);

    $hash = 0 unless $hash;
    return <<"EOF";
        hv_store((HV*)SvRV(\$arg),\\"$field\\",$fieldnamelen,
                 (newSVpv((char *)\$var.$field,$fieldsize)),$hash);
EOF
}
#==============================================================================
sub byte_input {
    my($field, $fieldsize) = @_;
    my($fieldnamelen) = length($field);

    return <<"EOF";
        if (hv_exists((HV*)SvRV(\$arg), \\"$field\\", $fieldnamelen)) {
            SV        **scalar;
            STRLEN      ByteLength;
            const char *ByteData;

            /* Need to deal with undersized data.  Only copy supplied bytes. */
            scalar = hv_fetch((HV *)SvRV(\$arg), \\"$field\\", $fieldnamelen, 0);
            ByteData = SvPV(*scalar, ByteLength);
            memcpy(\$var.$field,
                   ByteData,
                   ByteLength > $fieldsize ? $fieldsize : ByteLength);
        }
EOF
}
#==============================================================================
sub charv_output {
    my ($field) = @_;
    my $fieldnamelen = length($field);

    #
    # NOTE: this function assumes that the return value uses a buffer
    #       on the stack (or a static) in the XS code, not a
    #       dynamically allocated value.  See the MQINQMP XS code for
    #       an example.
    #
    return <<"EOF";
        {
            char    *ptr;
            STRLEN  len;

            if (\$var.$field.VSPtr) {
                ptr = \$var.$field.VSPtr;
            } else {
                ptr = (char *)&\$var.$field;
                ptr += \$var.$field.VSOffset;
            }
            if (\$var.$field.VSLength == MQVS_NULL_TERMINATED) {
                len = strlen(ptr);
            } else {
                len = \$var.$field.VSLength;
            }
            hv_store((HV*)SvRV(\$arg),\\"$field\\",$fieldnamelen,
                     (newSVpv(ptr,len)),0);
        }
EOF
}
#==============================================================================
sub charv_input {
    my ($field) = @_;
    my $fieldnamelen = length($field);

    return <<"EOF";
        if (hv_exists((HV*)SvRV(\$arg), \\"$field\\", $fieldnamelen)) {
            SV     **scalar;
	    char    *val;
            STRLEN   len;

            scalar = hv_fetch((HV *)SvRV(\$arg), \\"$field\\", $fieldnamelen, 0);
	    val = SvPV(*scalar, len);
	    if (len) {
	        \$var.$field.VSPtr = val;
		\$var.$field.VSLength = len;
		\$var.$field.VSOffset = 0;
		\$var.$field.VSBufSize  = 0;
		\$var.$field.VSCCSID = MQCCSI_APPL; /* Maybe UTF-8 */
	    }
        }
EOF
}
