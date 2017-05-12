
SV * GF_escape_html(SV * str, int b_inplace, int b_lftobr, int b_sptonbsp, int b_leaveknown);
SV * GF_generate_attributes(HV * attrhv);
SV * GF_generate_tag(SV * tag, HV * attrhv, SV * val, int b_escapeval, int b_addnewline, int b_closetag);
SV * GF_escape_uri(SV * str, SV * escchars, int b_inplace);
int GF_is_known_entity(char * sp, int i, int origlen, int * maxlen);
int GF_estimate_attribute_value_len(SV * val);
void GF_generate_attribute_value(SV * attrstr, SV * val);
void GF_set_paranoia(int paranoia);
