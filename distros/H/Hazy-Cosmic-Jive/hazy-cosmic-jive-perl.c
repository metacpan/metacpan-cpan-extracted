SV *
bcd_float_to_string (SV * d)
{
    char buffer[0x100] = {0};
    int printed;
    SV * r;
    if (! SvNOK (d)) {
	warn ("Not a number");
	return & PL_sv_undef;
    }
    printed = print_double (SvNV (d), buffer);
    if (printed < 0) {
	warn ("Error %d printing number %g", printed, SvNV (d));
	return & PL_sv_undef;
    }
    r = newSVpv (buffer, (STRLEN) printed);
    return r;
}
