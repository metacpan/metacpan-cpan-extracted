// this was an extract from http://jsgettext.berlios.de/doc/html/Gettext.html

alert(_("some string"));
alert(gt.gettext("some string"));
alert(gt.gettext("some string"));
var myString = this._("this will get translated");
alert( _("text") );
alert( gt.gettext("Hello World!\n") );
var translated = Gettext.strargs( gt.gettext("Hello %1"), [full_name] );
Code: Gettext.strargs( gt.gettext("This is the %1 %2"), ["red", "ball"] );
printf( ngettext("One file deleted.\n",
                 "%d files deleted.\n",
                 count),
        count);
Gettext.strargs( gt.ngettext( "One file deleted.\n",
                              "%d files deleted.\n",
                              count), // argument to ngettext!
                 count);
alert( pgettext( "Verb: To View", "View" ) );
alert( pgettext( "Noun: A View", "View"  ) );
var count = 14;
Gettext.strargs( gt.ngettext('one banana', '%1 bananas', count), [count] );


// do not find _('error 1'); _("error 2");

/*
    do not find
    _('error 3');
    _("error 4");
*/

// this are all combinations

_     ( 'MSGID_' );
_x    ( 'MSGID_x {key1} {key2}', { 'key1' : 'value1', 'key2' : 'value2' } );
_n    ( 'MSGID_n', 'PLURAL_n', COUNT );
_nx   ( 'MSGID_nx', 'PLURAL_nx', COUNT );
_p    ( 'MSGCTXT', 'MSGID_p' );
_px   ( 'MSGCTXT', 'MSGID_px' );
_np   ( 'MSGCTXT', 'MSGID_np', 'PLURAL_np', COUNT );
_npx  ( 'MSGCTXT', 'MSGID_npx', 'PLURAL_npx', COUNT );

_d    ( 'TEXTDOMAIN', 'MSGID_d' );
_dx   ( 'TEXTDOMAIN', 'MSGID_dx' );
_dn   ( 'TEXTDOMAIN', 'MSGID_dn', 'PLURAL_dn', COUNT );
_dnx  ( 'TEXTDOMAIN', 'MSGID_dnx', 'PLURAL_dnx', COUNT );
_dp   ( 'TEXTDOMAIN', 'MSGCTXT', 'MSGID_dp' );
_dpx  ( 'TEXTDOMAIN', 'MSGCTXT', 'MSGID_dpx' );
_dnp  ( 'TEXTDOMAIN', 'MSGCTXT', 'MSGID_dnp', 'PLURAL_dnp', COUNT );
_dnpx ( 'TEXTDOMAIN', 'MSGCTXT', 'MSGID_dnpx', 'PLURAL_dnpx', COUNT );

_c    ( 'MSGID_c', 'CATEGORY' );
_cx   ( 'MSGID_cx', 'CATEGORY' );
_cn   ( 'MSGID_cn', 'PLURAL_cn', COUNT, 'CATEGORY' );
_cnx  ( 'MSGID_cnx', 'PLURAL_cnx', COUNT, 'CATEGORY' );
_cp   ( 'MSGCTXT', 'MSGID_cp', 'CATEGORY' );
_cpx  ( 'MSGCTXT', 'MSGID_cpx', 'CATEGORY' );
_cnp  ( 'MSGCTXT', 'MSGID_cnp', 'PLURAL_cnp', COUNT, 'CATEGORY' );
_cnpx ( 'MSGCTXT', 'MSGID_cnpx', 'PLURAL_cnpx', COUNT, 'CATEGORY' );

_dc   ( 'TEXTDOMAIN', 'MSGID_dc', 'CATEGORY' );
_dcx  ( 'TEXTDOMAIN', 'MSGID_dcx', 'CATEGORY' );
_dcn  ( 'TEXTDOMAIN', 'MSGID_dcn', 'PLURAL_dcn', COUNT, 'CATEGORY' );
_dcnx ( 'TEXTDOMAIN', 'MSGID_dcnx', 'PLURAL_dcnx', COUNT, 'CATEGORY' );
_dcp  ( 'TEXTDOMAIN', 'MSGCTXT', 'MSGID_dcp', 'CATEGORY' );
_dcpx ( 'TEXTDOMAIN', 'MSGCTXT', 'MSGID_dcpx', 'CATEGORY' );
_dcnp ( 'TEXTDOMAIN', 'MSGCTXT', 'MSGID_dcnp', 'PLURAL_dcnp', COUNT, 'CATEGORY' );
_dcnpx( 'TEXTDOMAIN', 'MSGCTXT', 'MSGID_dcnpx', 'PLURAL_dcnpx', COUNT, 'CATEGORY' );

gettext    ( 'MSGID %0 %1', 'placeholder 0', 'placeholder 1' );
ngettext   ( 'MSGID n', 'PLURAL n', COUNT );
pgettext   ( 'MSGCTXT', 'MSGID p' );
npgettext  ( 'MSGCTXT', 'MSGID np', 'PLURAL np', COUNT );

dgettext   ( 'TEXTDOMAIN', 'MSGID d' );
dngettext  ( 'TEXTDOMAIN', 'MSGID dn', 'PLURAL dn', COUNT );
dpgettext  ( 'TEXTDOMAIN', 'MSGCTXT', 'MSGID dp' );
dnpgettext ( 'TEXTDOMAIN', 'MSGCTXT', 'MSGID dpn', 'PLURAL dpn', COUNT );

cgettext   ( 'MSGID c', 'CATEGORY' );
cngettext  ( 'MSGID cn', 'PLURAL cn', COUNT, 'CATEGORY' );
cpgettext  ( 'MSGCTXT', 'MSGID cp', 'CATEGORY' );
cnpgettext ( 'MSGCTXT', 'MSGID cnp', 'PLURAL cnp', COUNT, 'CATEGORY' );

dcgettext  ( 'TEXTDOMAIN', 'MSGID dc', 'CATEGORY' );
dcngettext ( 'TEXTDOMAIN', 'MSGID dcn', 'PLURAL dcn', COUNT, 'CATEGORY' );
dcpgettext ( 'TEXTDOMAIN', 'MSGCTXT', 'MSGID dcp', 'CATEGORY' );
dcnpgettext( 'TEXTDOMAIN', 'MSGCTXT', 'MSGID dcnp', 'PLURAL dcnp', COUNT, 'CATEGORY' );
