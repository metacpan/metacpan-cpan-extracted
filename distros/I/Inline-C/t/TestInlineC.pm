use strict; use warnings;
package TestInlineC;

BEGIN {
    $ENV{PERL_PEGEX_AUTO_COMPILE} = 'Inline::C::Parser::Pegex::Grammar';
}

use Test::More();
use YAML::XS;

use Parse::RecDescent;
use Inline::C::Parser::RecDescent;

use Pegex::Parser;
use Inline::C::Parser::Pegex::Grammar;
use Inline::C::Parser::Pegex::AST;

use base 'Exporter';
our @EXPORT = qw(test);

sub test {
    my ($input, $label) = @_;
    my $prd_data = prd_parse($input);
    my $parser = Pegex::Parser->new(
        grammar => Inline::C::Parser::Pegex::Grammar->new,
        receiver => Inline::C::Parser::Pegex::AST->new,
        debug => $ENV{DEBUG} # || 1,
    );
    my $pegex_data = $parser->parse($input)->{function};
    my $prd_dump = Dump $prd_data;
    my $pegex_dump = Dump $pegex_data;

    $label = "Pegex matches PRD: $label";

    # Carry over TODO from caller.
    local $TestInlineC::TODO = do {
      no strict 'refs';
      ${ caller . '::TODO' };
    };

    Test::More::cmp_ok($pegex_dump, 'eq', $prd_dump, $label);

    ($prd_data, $pegex_data);
}

require Inline::C;
sub prd_parse {
    my ($input) = @_;
    $main::RD_HINT++;
    my $grammar = Inline::C::Parser::RecDescent::grammar();
    my $parser = Parse::RecDescent->new( $grammar );
    $parser->{data}{typeconv} = TYPECONV();
    $parser->code($input);

    my $data = $parser->{data};
    my $functions = $data->{function};
    for my $name (keys %$functions) {
        if ($functions->{$name}{args}) {
            for my $arg (@{$functions->{$name}{args}}) {
                delete $arg->{offset};
            }
        }
    }
    $parser->{data}{function};
}

use constant TYPECONV => {
  'valid_rtypes' => {
    'wchar_t' => 1,
    'int' => 1,
    'caddr_t' => 1,
    'Boolean' => 1,
    'bool' => 1,
    'FileHandle' => 1,
    'wchar_t *' => 1,
    'void *' => 1,
    'unsigned char *' => 1,
    'AV *' => 1,
    'SysRetLong' => 1,
    'Result' => 1,
    'unsigned int' => 1,
    'time_t' => 1,
    'CV *' => 1,
    'SysRet' => 1,
    'ssize_t' => 1,
    'unsigned short' => 1,
    'double' => 1,
    'SV *' => 1,
    'PerlIO *' => 1,
    'OutputStream' => 1,
    'I32' => 1,
    'InOutStream' => 1,
    'UV' => 1,
    'U16' => 1,
    'IV' => 1,
    'char *' => 1,
    'unsigned char' => 1,
    'FILE *' => 1,
    'bool_t' => 1,
    'unsigned long' => 1,
    'char **' => 1,
    'size_t' => 1,
    'unsigned' => 1,
    'I16' => 1,
    'float' => 1,
    'I8' => 1,
    'STRLEN' => 1,
    'U8' => 1,
    'SVREF' => 1,
    'U32' => 1,
    'const char *' => 1,
    'char' => 1,
    'HV *' => 1,
    'void' => 1,
    'long' => 1,
    'NV' => 1,
    'unsigned long *' => 1,
    'InputStream' => 1,
    'Time_t *' => 1,
    'short' => 1
  },
  'output_expr' => {
    'T_PACKED' => '	XS_pack_$ntype($arg, $var);
',
    'T_UV' => '	sv_setuv($arg, (UV)$var);
',
    'T_IV' => '	sv_setiv($arg, (IV)$var);
',
    'T_REF_IV_REF' => '	sv_setref_pv($arg, \\"${ntype}\\", (void*)new $ntype($var));
',
    'T_U_LONG' => '	sv_setuv($arg, (UV)$var);
',
    'T_STDIO' => '	{
	    GV *gv = newGVgen("$Package");
	    PerlIO *fp = PerlIO_importFILE($var,0);
	    if ( fp && do_open(gv, "+<&", 3, FALSE, 0, 0, fp) )
		sv_setsv($arg, sv_bless(newRV((SV*)gv), gv_stashpv("$Package",1)));
	    else
		$arg = &PL_sv_undef;
	}
',
    'T_PTR' => '	sv_setiv($arg, PTR2IV($var));
',
    'T_NV' => '	sv_setnv($arg, (NV)$var);
',
    'T_FLOAT' => '	sv_setnv($arg, (double)$var);
',
    'T_DOUBLE' => '	sv_setnv($arg, (double)$var);
',
    'T_OPAQUE' => '	sv_setpvn($arg, (char *)&$var, sizeof($var));
',
    'T_LONG' => '	sv_setiv($arg, (IV)$var);
',
    'T_U_INT' => '	sv_setuv($arg, (UV)$var);
',
    'T_ARRAY' => '        {
	    U32 ix_$var;
	    EXTEND(SP,size_$var);
	    for (ix_$var = 0; ix_$var < size_$var; ix_$var++) {
		ST(ix_$var) = sv_newmortal();
	DO_ARRAY_ELEM
	    }
        }
',
    'T_PTRDESC' => '	sv_setref_pv($arg, \\"${ntype}\\", (void*)new\\U${type}_DESC\\E($var));
',
    'T_OPAQUEPTR' => '	sv_setpvn($arg, (char *)$var, sizeof(*$var));
',
    'T_ENUM' => '	sv_setiv($arg, (IV)$var);
',
    'T_INOUT' => '	{
	    GV *gv = newGVgen("$Package");
	    if ( do_open(gv, "+<&", 3, FALSE, 0, 0, $var) )
		sv_setsv($arg, sv_bless(newRV((SV*)gv), gv_stashpv("$Package",1)));
	    else
		$arg = &PL_sv_undef;
	}
',
    'T_AVREF' => '	$arg = newRV((SV*)$var);
',
    'T_SVREF' => '	$arg = newRV((SV*)$var);
',
    'T_HVREF_REFCOUNT_FIXED' => '	$arg = newRV_noinc((SV*)$var);
',
    'T_U_CHAR' => '	sv_setuv($arg, (UV)$var);
',
    'T_SV' => '	$arg = $var;
',
    'T_REFREF' => '	NOT_IMPLEMENTED
',
    'T_IN' => '	{
	    GV *gv = newGVgen("$Package");
	    if ( do_open(gv, "<&", 2, FALSE, 0, 0, $var) )
		sv_setsv($arg, sv_bless(newRV((SV*)gv), gv_stashpv("$Package",1)));
	    else
		$arg = &PL_sv_undef;
	}
',
    'T_INT' => '	sv_setiv($arg, (IV)$var);
',
    'T_OUT' => '	{
	    GV *gv = newGVgen("$Package");
	    if ( do_open(gv, "+>&", 3, FALSE, 0, 0, $var) )
		sv_setsv($arg, sv_bless(newRV((SV*)gv), gv_stashpv("$Package",1)));
	    else
		$arg = &PL_sv_undef;
	}
',
    'T_U_SHORT' => '	sv_setuv($arg, (UV)$var);
',
    'T_PV' => '	sv_setpv((SV*)$arg, $var);
',
    'T_CVREF' => '	$arg = newRV((SV*)$var);
',
    'T_CHAR' => '	sv_setpvn($arg, (char *)&$var, 1);
',
    'T_PACKEDARRAY' => '	XS_pack_$ntype($arg, $var, count_$ntype);
',
    'T_BOOL' => '	${"$var" eq "RETVAL" ? \\"$arg = boolSV($var);" : \\"sv_setsv($arg, boolSV($var));"}
',
    'T_AVREF_REFCOUNT_FIXED' => '	$arg = newRV_noinc((SV*)$var);
',
    'T_HVREF' => '	$arg = newRV((SV*)$var);
',
    'T_PTRREF' => '	sv_setref_pv($arg, Nullch, (void*)$var);
',
    'T_REFOBJ' => '	NOT IMPLEMENTED
',
    'T_REF_IV_PTR' => '	sv_setref_pv($arg, \\"${ntype}\\", (void*)$var);
',
    'T_SHORT' => '	sv_setiv($arg, (IV)$var);
',
    'T_CVREF_REFCOUNT_FIXED' => '	$arg = newRV_noinc((SV*)$var);
',
    'T_SYSRET' => '	if ($var != -1) {
	    if ($var == 0)
		sv_setpvn($arg, "0 but true", 10);
	    else
		sv_setiv($arg, (IV)$var);
	}
',
    'T_PTROBJ' => '	sv_setref_pv($arg, \\"${ntype}\\", (void*)$var);
',
    'T_SVREF_REFCOUNT_FIXED' => '	$arg = newRV_noinc((SV*)$var);
'
  },
  'input_expr' => {
    'T_PTR' => '	$var = INT2PTR($type,SvIV($arg))
',
    'T_NV' => '	$var = ($type)SvNV($arg)
',
    'T_DOUBLE' => '	$var = (double)SvNV($arg)
',
    'T_FLOAT' => '	$var = (float)SvNV($arg)
',
    'T_PACKED' => '	$var = XS_unpack_$ntype($arg)
',
    'T_IV' => '	$var = ($type)SvIV($arg)
',
    'T_UV' => '	$var = ($type)SvUV($arg)
',
    'T_REF_IV_REF' => '	if (sv_isa($arg, \\"${ntype}\\")) {
	    IV tmp = SvIV((SV*)SvRV($arg));
	    $var = *INT2PTR($type *, tmp);
	}
	else
	    Perl_croak(aTHX_ \\"%s: %s is not of type %s\\",
			${$ALIAS?\\q[GvNAME(CvGV(cv))]:\\qq[\\"$pname\\"]},
			\\"$var\\", \\"$ntype\\")
',
    'T_STDIO' => '	$var = PerlIO_findFILE(IoIFP(sv_2io($arg)))
',
    'T_U_LONG' => '	$var = (unsigned long)SvUV($arg)
',
    'T_HVREF_REFCOUNT_FIXED' => '	STMT_START {
		SV* const xsub_tmp_sv = $arg;
		SvGETMAGIC(xsub_tmp_sv);
		if (SvROK(xsub_tmp_sv) && SvTYPE(SvRV(xsub_tmp_sv)) == SVt_PVHV){
		    $var = (HV*)SvRV(xsub_tmp_sv);
		}
		else{
		    Perl_croak(aTHX_ \\"%s: %s is not a HASH reference\\",
				${$ALIAS?\\q[GvNAME(CvGV(cv))]:\\qq[\\"$pname\\"]},
				\\"$var\\");
		}
	} STMT_END
',
    'T_U_CHAR' => '	$var = (unsigned char)SvUV($arg)
',
    'T_ARRAY' => '	U32 ix_$var = $argoff;
	$var = $ntype(items -= $argoff);
	while (items--) {
	    DO_ARRAY_ELEM;
	    ix_$var++;
	}
        /* this is the number of elements in the array */
        ix_$var -= $argoff
',
    'T_PTRDESC' => '	if (sv_isa($arg, \\"${ntype}\\")) {
	    IV tmp = SvIV((SV*)SvRV($arg));
	    ${type}_desc = (\\U${type}_DESC\\E*) tmp;
	    $var = ${type}_desc->ptr;
	}
	else
	    Perl_croak(aTHX_ \\"%s: %s is not of type %s\\",
			${$ALIAS?\\q[GvNAME(CvGV(cv))]:\\qq[\\"$pname\\"]},
			\\"$var\\", \\"$ntype\\")
',
    'T_OPAQUEPTR' => '	$var = ($type)SvPV_nolen($arg)
',
    'T_INOUT' => '	$var = IoIFP(sv_2io($arg))
',
    'T_ENUM' => '	$var = ($type)SvIV($arg)
',
    'T_AVREF' => '	STMT_START {
		SV* const xsub_tmp_sv = $arg;
		SvGETMAGIC(xsub_tmp_sv);
		if (SvROK(xsub_tmp_sv) && SvTYPE(SvRV(xsub_tmp_sv)) == SVt_PVAV){
		    $var = (AV*)SvRV(xsub_tmp_sv);
		}
		else{
		    Perl_croak(aTHX_ \\"%s: %s is not an ARRAY reference\\",
				${$ALIAS?\\q[GvNAME(CvGV(cv))]:\\qq[\\"$pname\\"]},
				\\"$var\\");
		}
	} STMT_END
',
    'T_SVREF' => '	STMT_START {
		SV* const xsub_tmp_sv = $arg;
		SvGETMAGIC(xsub_tmp_sv);
		if (SvROK(xsub_tmp_sv)){
		    $var = SvRV(xsub_tmp_sv);
		}
		else{
		    Perl_croak(aTHX_ \\"%s: %s is not a reference\\",
				${$ALIAS?\\q[GvNAME(CvGV(cv))]:\\qq[\\"$pname\\"]},
				\\"$var\\");
		}
	} STMT_END
',
    'T_U_INT' => '	$var = (unsigned int)SvUV($arg)
',
    'T_OPAQUE' => '	$var = *($type *)SvPV_nolen($arg)
',
    'T_LONG' => '	$var = (long)SvIV($arg)
',
    'T_CVREF' => '	STMT_START {
                HV *st;
                GV *gvp;
		SV * const xsub_tmp_sv = $arg;
		SvGETMAGIC(xsub_tmp_sv);
                $var = sv_2cv(xsub_tmp_sv, &st, &gvp, 0);
		if (!$var) {
		    Perl_croak(aTHX_ \\"%s: %s is not a CODE reference\\",
				${$ALIAS?\\q[GvNAME(CvGV(cv))]:\\qq[\\"$pname\\"]},
				\\"$var\\");
		}
	} STMT_END
',
    'T_CHAR' => '	$var = (char)*SvPV_nolen($arg)
',
    'T_PACKEDARRAY' => '	$var = XS_unpack_$ntype($arg)
',
    'T_INT' => '	$var = (int)SvIV($arg)
',
    'T_OUT' => '	$var = IoOFP(sv_2io($arg))
',
    'T_U_SHORT' => '	$var = (unsigned short)SvUV($arg)
',
    'T_PV' => '	$var = ($type)SvPV_nolen($arg)
',
    'T_IN' => '	$var = IoIFP(sv_2io($arg))
',
    'T_REFREF' => '	if (SvROK($arg)) {
	    IV tmp = SvIV((SV*)SvRV($arg));
	    $var = *INT2PTR($type,tmp);
	}
	else
	    Perl_croak(aTHX_ \\"%s: %s is not a reference\\",
			${$ALIAS?\\q[GvNAME(CvGV(cv))]:\\qq[\\"$pname\\"]},
			\\"$var\\")
',
    'T_SV' => '	$var = $arg
',
    'T_SYSRET' => '	$var NOT IMPLEMENTED
',
    'T_PTROBJ' => '	if (SvROK($arg) && sv_derived_from($arg, \\"${ntype}\\")) {
	    IV tmp = SvIV((SV*)SvRV($arg));
	    $var = INT2PTR($type,tmp);
	}
	else
	    Perl_croak(aTHX_ \\"%s: %s is not of type %s\\",
			${$ALIAS?\\q[GvNAME(CvGV(cv))]:\\qq[\\"$pname\\"]},
			\\"$var\\", \\"$ntype\\")
',
    'T_SVREF_REFCOUNT_FIXED' => '	STMT_START {
		SV* const xsub_tmp_sv = $arg;
		SvGETMAGIC(xsub_tmp_sv);
		if (SvROK(xsub_tmp_sv)){
		    $var = SvRV(xsub_tmp_sv);
		}
		else{
		    Perl_croak(aTHX_ \\"%s: %s is not a reference\\",
				${$ALIAS?\\q[GvNAME(CvGV(cv))]:\\qq[\\"$pname\\"]},
				\\"$var\\");
		}
	} STMT_END
',
    'T_REF_IV_PTR' => '	if (sv_isa($arg, \\"${ntype}\\")) {
	    IV tmp = SvIV((SV*)SvRV($arg));
	    $var = INT2PTR($type, tmp);
	}
	else
	    Perl_croak(aTHX_ \\"%s: %s is not of type %s\\",
			${$ALIAS?\\q[GvNAME(CvGV(cv))]:\\qq[\\"$pname\\"]},
			\\"$var\\", \\"$ntype\\")
',
    'T_SHORT' => '	$var = (short)SvIV($arg)
',
    'T_CVREF_REFCOUNT_FIXED' => '	STMT_START {
                HV *st;
                GV *gvp;
		SV * const xsub_tmp_sv = $arg;
		SvGETMAGIC(xsub_tmp_sv);
                $var = sv_2cv(xsub_tmp_sv, &st, &gvp, 0);
		if (!$var) {
		    Perl_croak(aTHX_ \\"%s: %s is not a CODE reference\\",
				${$ALIAS?\\q[GvNAME(CvGV(cv))]:\\qq[\\"$pname\\"]},
				\\"$var\\");
		}
	} STMT_END
',
    'T_REFOBJ' => '	if (sv_isa($arg, \\"${ntype}\\")) {
	    IV tmp = SvIV((SV*)SvRV($arg));
	    $var = *INT2PTR($type,tmp);
	}
	else
	    Perl_croak(aTHX_ \\"%s: %s is not of type %s\\",
			${$ALIAS?\\q[GvNAME(CvGV(cv))]:\\qq[\\"$pname\\"]},
			\\"$var\\", \\"$ntype\\")
',
    'T_BOOL' => '	$var = (bool)SvTRUE($arg)
',
    'T_AVREF_REFCOUNT_FIXED' => '	STMT_START {
		SV* const xsub_tmp_sv = $arg;
		SvGETMAGIC(xsub_tmp_sv);
		if (SvROK(xsub_tmp_sv) && SvTYPE(SvRV(xsub_tmp_sv)) == SVt_PVAV){
		    $var = (AV*)SvRV(xsub_tmp_sv);
		}
		else{
		    Perl_croak(aTHX_ \\"%s: %s is not an ARRAY reference\\",
				${$ALIAS?\\q[GvNAME(CvGV(cv))]:\\qq[\\"$pname\\"]},
				\\"$var\\");
		}
	} STMT_END
',
    'T_HVREF' => '	STMT_START {
		SV* const xsub_tmp_sv = $arg;
		SvGETMAGIC(xsub_tmp_sv);
		if (SvROK(xsub_tmp_sv) && SvTYPE(SvRV(xsub_tmp_sv)) == SVt_PVHV){
		    $var = (HV*)SvRV(xsub_tmp_sv);
		}
		else{
		    Perl_croak(aTHX_ \\"%s: %s is not a HASH reference\\",
				${$ALIAS?\\q[GvNAME(CvGV(cv))]:\\qq[\\"$pname\\"]},
				\\"$var\\");
		}
	} STMT_END
',
    'T_PTRREF' => '	if (SvROK($arg)) {
	    IV tmp = SvIV((SV*)SvRV($arg));
	    $var = INT2PTR($type,tmp);
	}
	else
	    Perl_croak(aTHX_ \\"%s: %s is not a reference\\",
			${$ALIAS?\\q[GvNAME(CvGV(cv))]:\\qq[\\"$pname\\"]},
			\\"$var\\")
'
  },
  'valid_types' => {
    'unsigned int' => 1,
    'SysRet' => 1,
    'CV *' => 1,
    'time_t' => 1,
    'ssize_t' => 1,
    'unsigned short' => 1,
    'double' => 1,
    'SV *' => 1,
    'PerlIO *' => 1,
    'I32' => 1,
    'InOutStream' => 1,
    'OutputStream' => 1,
    'UV' => 1,
    'U16' => 1,
    'char *' => 1,
    'IV' => 1,
    'wchar_t' => 1,
    'int' => 1,
    'bool' => 1,
    'Boolean' => 1,
    'caddr_t' => 1,
    'void *' => 1,
    'wchar_t *' => 1,
    'FileHandle' => 1,
    'AV *' => 1,
    'unsigned char *' => 1,
    'SysRetLong' => 1,
    'Result' => 1,
    'const char *' => 1,
    'HV *' => 1,
    'char' => 1,
    'unsigned long *' => 1,
    'InputStream' => 1,
    'long' => 1,
    'NV' => 1,
    'Time_t *' => 1,
    'short' => 1,
    'unsigned char' => 1,
    'bool_t' => 1,
    'FILE *' => 1,
    'char **' => 1,
    'unsigned long' => 1,
    'size_t' => 1,
    'unsigned' => 1,
    'I16' => 1,
    'float' => 1,
    'U8' => 1,
    'I8' => 1,
    'STRLEN' => 1,
    'U32' => 1,
    'SVREF' => 1
  },
  'type_kind' => {
    'U32' => 'T_U_LONG',
    'SVREF' => 'T_SVREF',
    'STRLEN' => 'T_UV',
    'I8' => 'T_IV',
    'U8' => 'T_UV',
    'I16' => 'T_IV',
    'float' => 'T_FLOAT',
    'size_t' => 'T_UV',
    'unsigned' => 'T_UV',
    'unsigned long' => 'T_UV',
    'char **' => 'T_PACKEDARRAY',
    'FILE *' => 'T_STDIO',
    'bool_t' => 'T_IV',
    'unsigned char' => 'T_U_CHAR',
    'short' => 'T_IV',
    'Time_t *' => 'T_PV',
    'NV' => 'T_NV',
    'long' => 'T_IV',
    'InputStream' => 'T_IN',
    'unsigned long *' => 'T_OPAQUEPTR',
    'char' => 'T_CHAR',
    'HV *' => 'T_HVREF',
    'const char *' => 'T_PV',
    'Result' => 'T_U_CHAR',
    'SysRetLong' => 'T_SYSRET',
    'unsigned char *' => 'T_PV',
    'AV *' => 'T_AVREF',
    'FileHandle' => 'T_PTROBJ',
    'void *' => 'T_PTR',
    'wchar_t *' => 'T_PV',
    'Boolean' => 'T_BOOL',
    'caddr_t' => 'T_PV',
    'bool' => 'T_BOOL',
    'int' => 'T_IV',
    'wchar_t' => 'T_IV',
    'IV' => 'T_IV',
    'char *' => 'T_PV',
    'U16' => 'T_U_SHORT',
    'UV' => 'T_UV',
    'OutputStream' => 'T_OUT',
    'InOutStream' => 'T_INOUT',
    'I32' => 'T_IV',
    'PerlIO *' => 'T_INOUT',
    'double' => 'T_DOUBLE',
    'SV *' => 'T_SV',
    'unsigned short' => 'T_UV',
    'ssize_t' => 'T_IV',
    'CV *' => 'T_CVREF',
    'time_t' => 'T_NV',
    'SysRet' => 'T_SYSRET',
    'unsigned int' => 'T_UV'
  }
};



1;
