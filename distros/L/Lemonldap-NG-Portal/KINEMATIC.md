# Lemonldap::NG::Manager kinematic

## Main requests (index.pl)

### Main initialization (`new()`)

Simple::new():

* `getConf()`
* load `Menu` and `Display`
* load `Auth/UserDB/PasswordDB/RegisterDB`
* load `IssuerDBx`
* (load `Notifications`)

### Request managing

Scenarii:

* F: unknown user comes for the first time
* P: (good) post for authentication
* M: menu display
* L: simple logout

|   |              Method               |     Comment                           | F | P | M | L | Proposed PSGI route (for 2.0)
|---|-----------------------------------|:-------------------------------------:|---|---|---|---|------------------------------
| 0 |               _startSoapServices_ | Manage som path info                  |   |   |   |   | /sessions
| 1 | controlUrlOrigin                  | check `url` parameter (+confirmation) | X | X | X | X |
| 2 | checkNotifBack                    | check accepted notifications          | X | X | X | X | /notif ?
| 3 | controlExistingSession            | check cookie                          | X | X | X | X |
|   |                                   | * display captcha image               | X |   |   |   | /captcha
|   |                                   | * logout                              |   |   |   |   | /logout
|   |                                   | * remove existing sessions            |   | X |   |   |
|   |                                   | * respond to ping                     |   |   |   |   | /ping
|   |                                   | * respond to `storeAppsListOrder`     |   |   |   |   | /storeAppsListOrder
|   |                                   | * _If user is authenticated, call:_   |   |   |   |   |
|   |                                   |   - _issuerForAuthUser_               |   |   |   |   |
|   |                                   |   - _authFinish_                      |   |   |   |   |
|   |                                   |   - _autoRedirect_                    |   |   |   |   |
|   |                 _existingSession_ | manage reauthentication and force     |   |   | X |   |
|   |                       _authForce_ |                                       |   |   | X |   |
|   | _IssuerDB::issuerDBInit_          |                                       | X | X | X | X | _(init^)_
|   |                _IssuerDB::logout_ |                                       |   |   |   | X |
|   | _Auth::authInit_                  |                                       | X | X | X | X | _(init^)_
|   |                    _Auth::logout_ |                                       |   |   |   | X |
| 4 | __Issuer__::issuerForUnAuthUser   |                                       | X | X |   |   | Many (SSO, SLO, SOAP,...)
| 5 | __Auth__::extractFormInfo         | First call to auth module             | X | X |   |   |
|   | _UserDB::userDBInit_              |                                       |   | X |   |   | _(init^)_
| 6 | __UserDB__::getUser               | First call to UserDB: set $\_user     |   | X |   |   |
| 7 | __Auth__::setAuthSessionInfo      | Auth module can set infos to session  |   | X |   |   |
|   | _PasswordDB::passwordDBInit_      |                                       |   | X |   |   | _(init^)_
| 8 | __PasswordDB__::modifyPassword    | Unique call to PasswordDB             |   | X |   |   | ?
| 9 | setSessionInfo                    | Store datas in `$sessionInfo`         |   | X |   |   |
| 10 | setMacros                        | Update $sessionInfo with macros       |   | X |   |   |
|    |               _create safe jail_ |                                       |   | X |   |   |
| 11 | __UserDB__::setGroups            | Set `$sessionInfo-&gt;{group}`        |   | X |   |   |
| 12 | setPersistentSessionInfo         | Store some datas in persistent DB     |   | X |   |   |
| 13 | setLocalGroups                   | Set `$sessionInfo-&gt;{group}`        |   | X |   |   |
| 14 | __MailReset__::sendPasswordMail  | Called if password was changed        |   | X |_3_|   |
| 15 | __Auth__::authenticate           | 3rd call to _Auth_ module (for LDAP)  |   | X |   |   |
| 16 | __Auth__::authFinish             | Last call to _Auth_                   |   | X |_1_|   |
| 17 | __UserDB__::userDBFinish         | Last call to _UserDB_                 |   | X |   |   |
| 18 | __PasswordDB__::passwordDBFinish | Last call to _PasswordDB_             |   | X |_2_|   |
| 19 | grantSession                     | Apply the rule (user is authenticated |   | X |   |   |
| 20 | removeOther                      | Remove other opened sessions          |   | X |   |   |
| 21 | store                            | Store session in DB                   |   | X |   |   |
|    |                  _setApacheUser_ |                                       |   |   |   |   |
| 22 | buildCookie                      | Build LLNG cookie(s)                  |   | X |   |   |
| 23 | checkNotification                | Check if current user has messages    |   | X | X |   |
| 24 | __IssuerDB__::issuerForAuthUser  |                                       |   | X | X |   | Many (SSO, SLO, SOAP, Attribute query,...)
| 25 | autoRedirect                     | Redirects to wanted url               |   | X |   |   |
|    |                       _menuInit_ |                                       |   |   | X |   |

Notes:

1. Called after issuerForAuthUser
2. Called after menuInit
3. called after passwordDBFinish

## Other requests

### /saml/metadata (metadata.pl)

Returns the content of Lemonldap::NG::Common::Conf::SAML::Metadata-&gt;serviceToXML()

### /openid-configuration.pl

Display OpenID-Connect JSON configuration

### /mail.pl

Launch MailReset

### /register.pl

Registration

### /cdc.pl

Display SAML cross domain cookies

