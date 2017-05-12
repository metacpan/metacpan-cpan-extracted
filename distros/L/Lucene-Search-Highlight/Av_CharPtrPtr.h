/* Modified from API Cookbook A Example 8 */

char ** XS_unpack_charPtrPtr ( SV *rv );
void XS_pack_charPtrPtr ( SV *st, char **s );
void XS_release_charPtrPtr ( char **s );

