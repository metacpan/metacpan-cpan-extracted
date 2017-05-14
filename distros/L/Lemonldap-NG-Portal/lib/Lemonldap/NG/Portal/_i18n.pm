##@file
# Internationalization for Lemonldap::NG portal

##@class
# Internationalization for Lemonldap::NG portal
package Lemonldap::NG::Portal::_i18n;

# Developpers warning : this file must stay UTF-8 encoded

use AutoLoader qw(AUTOLOAD);
our $VERSION = '1.9.3';
use utf8;

## @fn string msg(int msg, array ref lang)
# @param $msg Number of msg to resolve
# @param $lang Array ref for 2-letters languages (e.g. ['es', 'fr'])
# @return Message string in the first matching language
sub msg {
    my ( $msg, $lang ) = @_;
    foreach ( @{$lang} ) {
        if ( __PACKAGE__->can("msg_$_") ) {
            return &{"msg_$_"}->[$msg];
        }
    }
    return &msg_en->[$msg];
}

## @fn string error(int error, array ref lang)
# @param $error Number of error to resolve
# @param $lang Array ref for 2-letters languages (e.g. ['es', 'fr'])
# @return Error string in the first matching language
sub error {
    my ( $error, $lang ) = @_;
    $error = 0 if ( $error < 0 );
    foreach ( @{$lang} ) {
        if ( __PACKAGE__->can("error_$_") ) {
            my $tmp = &{"error_$_"}->[$error];
            return $tmp;
        }
    }
    return &error_en->[$error];
}

1;

__END__
# Order of the constants:
# * PE_OK                                 0
# * PE_SESSIONEXPIRED                     1
# * PE_FORMEMPTY                          2
# * PE_WRONGMANAGERACCOUNT                3
# * PE_USERNOTFOUND                       4
# * PE_BADCREDENTIALS                     5
# * PE_LDAPCONNECTFAILED                  6
# * PE_LDAPERROR                          7
# * PE_APACHESESSIONERROR                 8
# * PE_FIRSTACCESS                        9
# * PE_BADCERTIFICATE                    10
# * PE_LA_FAILED                         11
# * PE_LA_ARTFAILED                      12
# * PE_LA_DEFEDFAILED                    13
# * PE_LA_QUERYEMPTY                     14
# * PE_LA_SOAPFAILED                     15
# * PE_LA_SLOFAILED                      16
# * PE_LA_SSOFAILED                      17
# * PE_LA_SSOINITFAILED                  18
# * PE_LA_SESSIONERROR                   19
# * PE_LA_SEPFAILED                      20
# * PE_PP_ACCOUNT_LOCKED                 21
# * PE_PP_PASSWORD_EXPIRED               22
# * PE_CERTIFICATEREQUIRED               23
# * PE_ERROR                             24
# * PE_PP_CHANGE_AFTER_RESET             25
# * PE_PP_PASSWORD_MOD_NOT_ALLOWED       26
# * PE_PP_MUST_SUPPLY_OLD_PASSWORD       27
# * PE_PP_INSUFFICIENT_PASSWORD_QUALITY  28
# * PE_PP_PASSWORD_TOO_SHORT             29
# * PE_PP_PASSWORD_TOO_YOUNG             30
# * PE_PP_PASSWORD_IN_HISTORY            31
# * PE_PP_GRACE                          32
# * PE_PP_EXP_WARNING                    33
# * PE_PASSWORD_MISMATCH                 34
# * PE_PASSWORD_OK                       35
# * PE_NOTIFICATION                      36
# * PE_BADURL                            37
# * PE_NOSCHEME                          38
# * PE_BADOLDPASSWORD                    39
# * PE_MALFORMEDUSER                     40
# * PE_SESSIONNOTGRANTED                 41
# * PE_CONFIRM                           42
# * PE_MAILFORMEMPTY                     43
# * PE_BADMAILTOKEN                      44
# * PE_MAILERROR                         45
# * PE_MAILOK                            46
# * PE_LOGOUT_OK                         47
# * PE_SAML_ERROR                        48
# * PE_SAML_LOAD_SERVICE_ERROR           49
# * PE_SAML_LOAD_IDP_ERROR               50
# * PE_SAML_SSO_ERROR                    51
# * PE_SAML_UNKNOWN_ENTITY               52
# * PE_SAML_DESTINATION_ERROR            53
# * PE_SAML_CONDITIONS_ERROR             54
# * PE_SAML_IDPSSOINITIATED_NOTALLOWED   55
# * PE_SAML_SLO_ERROR                    56
# * PE_SAML_SIGNATURE_ERROR              57
# * PE_SAML_ART_ERROR                    58
# * PE_SAML_SESSION_ERROR                59
# * PE_SAML_LOAD_SP_ERROR                60
# * PE_SAML_ATTR_ERROR                   61
# * PE_OPENID_EMPTY                      62
# * PE_OPENID_BADID                      63
# * PE_MISSINGREQATTR                    64
# * PE_BADPARTNER                        65
# * PE_MAILCONFIRMATION_ALREADY_SENT     66
# * PE_PASSWORDFORMEMPTY                 67
# * PE_CAS_SERVICE_NOT_ALLOWED           68
# * PE_MAILFIRSTACCESS                   69
# * PE_MAILNOTFOUND                      70
# * PE_PASSWORDFIRSTACCESS               71
# * PE_MAILCONFIRMOK                     72
# * PE_RADIUSCONNECTFAILED               73
# * PE_MUST_SUPPLY_OLD_PASSWORD          74
# * PE_FORBIDDENIP                       75
# * PE_CAPTCHAERROR                      76
# * PE_CAPTCHAEMPTY                      77
# * PE_REGISTERFIRSTACCESS               78
# * PE_REGISTERFORMEMPTY                 79
# * PE_REGISTERALREADYEXISTS             80

# Not used in errors:
# * PE_DONE                -1
# * PE_REDIRECT            -2

## @fn private arrayRef error_fr()
# French translation.
# @return Array of error messages
sub error_fr {
    use utf8;
    [
        'Utilisateur authentifié',
        'Votre session a expiré, vous devez vous réauthentifier',
        'Identifiant ou mot de passe non renseigné',
        'Compte ou mot de passe LDAP de l\'application incorrect',
        'Utilisateur inexistant',
        'Mot de passe ou identifiant incorrect',
        'Connexion impossible au serveur LDAP',
        'Erreur anormale du serveur LDAP',
        'Erreur du module Apache::Session choisi',
        'Veuillez vous authentifier',
        'Certificat invalide',
        'Échec de l\'initialisation de Lasso:Login ou Lasso:Logout',
        'Échec de la résolution de l\'artefact Liberty Alliance',
        'Échec de la défédération Liberty Alliance',
        'La requête renvoyée par le fournisseur d\'identité Liberty Alliance est vide',
        'Un des appels SOAP Liberty Alliance a échoué',
        'Un des appels de déconnexion Liberty Alliance a échoué',
        'Aucun artefact SAML trouvé, ou échec de l\'auto-acceptation SSO',
        'Initialisation, construction ou requête SSO en échec',
        'Impossible d\'enregistrer l\'identifiant de connexion Liberty Alliance',
        'Un processus terminal Liberty Alliance a échoué',
        'Votre compte est bloqué',
        'Votre mot de passe a expiré',
        'Certificat exigé',
        'Erreur',
        'Le mot de passe a été réinitialisé et doit être changé',
        'Modification du mot de passe non autorisée',
        'Ancien mot de passe à fournir pour le changer',
        'Qualité de mot de passe insuffisante',
        'Mot de passe trop court',
        'Mot de passe trop récent',
        'Mot de passe utilisé trop récemment',
        ' authentifications restantes, changez votre mot de passe !',
        '%d jours, %d heures, %d minutes et %d secondes avant expiration de votre mot de passe, pensez à le changer !',
        'Les mots de passe ne correspondent pas',
        'Le mot de passe a été changé',
        'Vous avez un nouveau message',
        'Mauvaise URL',
        'Aucun schéma disponible',
        'Ancien mot de passe invalide',
        'Nom d\'utilisateur incorrect',
        'Ouverture de session interdite',
        'Confirmation demandée',
        'L\'adresse mail est obligatoire ',
        'La clé de confirmation est invalide ou trop ancienne',
        'L\'envoi du mail a échoué',
        'Un mail vous a été envoyé',
        'Vous avez été déconnecté',
        'Erreur SAML non définie',
        'Impossible de charger le service SAML',
        'Problème au chargement d\'un fournisseur d\'identité',
        'Une erreur est survenue lors de l\'authentification SAML',
        'Le partenaire SAML n\'est pas reconnu',
        'La destination du message SAML est incorrecte',
        'Les conditions du message SAML ne sont pas respectées',
        'L\'authentification initiée par le fournisseur d\'identité n\'est pas autorisée',
        'Une erreur est survenue lors de la déconnexion SAML',
        'Erreur lors de la gestion de la signature du message SAML',
        'Une erreur est survenue lors de l\'utilisation d\'un artefact SAML',
        'Erreur de communication avec les sessions SAML',
        'Problème au chargement d\'un fournisseur de service',
        'Une erreur est survenue lors de l\'échange d\'attributs SAML',
        'Ceci est une page destinée aux serveurs OpenID',
        'Vous tentez d\'utiliser une identité OpenID qui ne vous appartient pas',
        'Un attribut exigé n\'est pas disponible',
        'Fédération interdite par la politique de sécurité',
        'Le mail de confirmation a déjà été envoyé',
        'Mot de passe non renseigné',
        'Accès non autorisé au service CAS',
        'Merci de saisir votre adresse mail',
        'Pas d\'utilisateur correspondant',
        'Merci de saisir votre nouveau mot de passe',
        'Un mail de confirmation vous a été envoyé',
        'La connexion au serveur Radius a échoué',
        "L'ancien mot de passe est obligatoire",
        'Vous venez d\'une adresse IP qui n\'est pas accréditée',
        'Erreur dans la saisie du captcha',
        'Vous devez saisir le captcha',
        'Merci de saisir vos informations',
        'Une information est manquante',
        'Cette adresse est déjà utilisée',
    ];
}

## @fn private arrayRef error_en()
# English translation.
# @return Array of error messages
sub error_en {
    [
        'User authenticated',
        'Your connection has expired, you must authenticate once again',
        'User and password fields must be filled',
        'Wrong directory manager account or password',
        'User not found in directory',
        'Wrong credentials',
        'Unable to connect to LDAP server',
        'Abnormal error from LDAP server',
        'Apache::Session module failed',
        'Authentication required',
        'Invalid certificate',
        'Initialization of Lasso:Login or Lasso:Logout failed',
        'Liberty-Alliance artefact resolution failed',
        'Liberty-Alliance defederation failed',
        'Liberty-Alliance query returned by IDP in assertion is empty',
        'One of Liberty-Alliance soap calls failed',
        'One of Liberty-Alliance single logout failed',
        'No SAML artefact found, or auto-accepting SSO failed',
        'Initializing, building or requesting SSO failed',
        'Unable to store Liberty-Alliance session id',
        'A Liberty-Alliance Soap End Point process failed',
        'Your account is locked',
        'Your password has expired',
        'Certificate required',
        'Error',
        'Password has been reset and now must be changed',
        'Password may not be modified',
        'Old password must also be supplied when setting a new password',
        'Insufficient password quality',
        'Password too short',
        'Password too young',
        'Password used too recently',
        ' authentications remaining, change your password!',
        '%d days, %d hours, %d minutes and %d seconds before password expiration, change it!',
        'Passwords mismatch',
        'Password successfully changed',
        'You have a new message',
        'Bad URL',
        'No scheme available',
        'Bad old password',
        'Bad username',
        'Session opening not allowed',
        'Confirmation required',
        'Your mail address is mandatory',
        'Confirmation key is invalid or too old',
        'An error occurs when sending mail',
        'A mail has been sent',
        'You have been disconnected',
        'Undefined SAML error',
        'Unable to load SAML service',
        'Problem when loading an identity provider',
        'An error occured during SAML single sign on',
        'SAML entity is not known',
        'SAML message destination is not correct',
        'SAML message conditions are not respected',
        'Identity provider initiated single sign on is not authorized',
        'An error occured during SAML single logout',
        'Error in SAML message signature management',
        'An error occured during SAML artifact use',
        'Communication error with SAML sessions',
        'Problem when loading a service provider',
        'An error occured during SAML attributes exchange',
        'This is an OpenID endpoint page',
        'You try to use an OpenID identity which is not yours',
        'A required attribute is not available',
        'Federation forbidden by security policy',
        'The confirmation mail was already sent',
        'Password field must be filled',
        'Access non granted on CAS service',
        'Please provide your mail address',
        'No matching user',
        'Please provide your new password',
        'A confirmation mail has been sent',
        'Radius connection has failed',
        'Old password is required',
        'You came from an unaccredited IP address',
        'You failed at typing the captcha',
        'You have to type the captcha',
        'Please enter your information',
        'An information is missing',
        'This address is already used',
    ];
}

## @fn private arrayRef error_es()
# Spanish translation.
# @return Array of error messages

sub error_es {
    use utf8;
    [
        'Usuario autentificado',
        'Su sesión ha expirado. Vuelva a autenticarse',
        'Introduzca su identificante o contraseña',
        'Cuenta o contraseña LDAP de la aplicación incorrecta',
        'Usuario no reconocido',
        'Contraseña o identificador incorrecto',
        'Conexión fallida al servidor LDAP',
        'Error anómalo del servidor LDAP',
        'Error del módulo Apache::Session seleccionado',
        'Autenticación necesaria',
        'Certificado inválido',
        'Inicialización fallida de Lasso:Login o Lasso:Logout',
        'Resolución fallida del artefacto Liberty Alliance',
        'Desfragmentación fallida de Liberty Alliance',
        'La solicitud enviada por el proveedor de identidad Liberty Alliance está vacía',
        'Una de las llamadas SOAP Liberty Alliance ha fracasado',
        'Una de las llamadas de desconexión Liberty Alliance ha fracasado',
        'No se ha encontrado ningún artefacto SAML, o autoaceptación SSO fallida',
        'Error de inicialización, construcción o solicitud SSO',
        'No se puede registrar el identificador de conexión Liberty Alliance',
        'Un proceso terminal Liberty Alliance ha fracasado',
        'Su cuenta está bloqueada',
        'Su contraseña ha caducado',
        'Certificado requerido',
        'Error',
        'La contraseña se ha reiniciado y se debe cambiar',
        'Modificación de contraseña no autorizada',
        'Para modificarla, introduzca la antigua contraseña',
        'Calidad de contraseña insuficiente',
        'Contraseña demasiado corta',
        'Contraseña demasiado reciente',
        'Contraseña utilizada demasiado recientemente',
        ' autenticaciones restantes, cambie de contraseña',
        'cambie su contraseña antes de %d días, %d horas, %d minutos y %d segundos antes de su expiración',
        'Las contraseñas no coinciden',
        'La contraseña se ha modificado',
        'Tiene un nuevo mensaje',
        'URL incorrecta',
        'Ningún esquema disponible',
        'Antigua contraseña inválida',
        'Nombre de usuario incorrecto',
        'Inicio de sesión no autorizada',
        'Confirmación requerida',
        'Dirección e-mail obligatoria',
        'Llave de confirmación inválida o demasiado antigua',
        'El envío de e-mail ha fracasado',
        'Ha recibido un e-mail',
        'La sesión se ha desconectado',
        'Error SAML no definido',
        'No se puede cargar el servicio SAML',
        'Problema al cargar un proveedor de identidad',
        'Error de autenticación SAML',
        'Colaborador SAML no reconocido',
        'Dirección de destino SAML incorrecta',
        'Las condiciones del mensaje SAML no se respetan',
        'La autenticación iniciada por el proveedor de identidad no está autorizada',
        'Error de desconexión SAML',
        'Error de gestión de la firma del mensaje SAML',
        'Error de utilización de un artefacto SAML',
        'Error de comunicación con las sesiones SAML',
        'Problema al cargar un proveedor de servicio',
        'Error de intercambio de atributos SAML',
        'Página destinada a los servidores OpenID',
        'La identidad OpenID que quiere utilizar no le pertenece',
        'Un atributo exigido no está disponible',
        'Agrupación prohibida por la política de seguridad',
        'E-mail de confirmación ya enviado',
        'Contraseña no registrada',
        'Acceso no autorizado al servicio CAS',
        'Introduzca su dirección e-mail',
        'Sin usuario correspondiente',
        'Introduzca su nueva contraseña',
        'Ha recibido un e-mail de confirmación',
        'La conexión al servidor Radius ha fracasado',
        'La antigua contraseña es obligatoria',
        'Dirección IP no acreditada',
        'Error al registrar el captcha',
        'Introduzca el captcha',
        'Introduzca sus datos',
        'Faltan datos',
        'Esta dirección ya está utilizada',
    ];
}

## @fn private arrayRef error_it()
# Italian translation.
# @return Array of error messages
sub error_it {
    use utf8;
    [
        'Utente autenticato',
        'La sessione è scaduta, devi autenticarti di nuovo',
        'ID o password mancante',
        'Account o password LDAP dell\'applicazione errata',
        'Utente inesistente',
        'Password o ID errati',
        'Impossibile connettersi al server LDAP',
        'Errore anomalo del server LDAP',
        'Errore del modulo Apache::Session',
        'Autenticazione necessaria',
        'Certificato non valido',
        'Inizializzazione di Lasso:Login o Lasso:Logout fallita',
        'Risoluzione dell\'artefatto Liberty Alliance fallita',
        'Liberty-Alliance defederation fallita',
        'La richiesta rinviata dal provider d\'identità Liberty Alliance è vuota',
        'Una delle chiamate SOAP Liberty Alliance è fallita',
        'Una delle chiamate di logout Liberty Alliance è fallita',
        'Nessun artefatto SAML trovato, o auto-accettazione SSO fallita',
        'Inizializzazione, costruzione o richiesta SSO fallita',
        'Impossibile registrare l\'ID di connessione Liberty Alliance',
        'Un processo di end point SOAP Liberty Alliance fallito',
        'Account bloccato',
        'Password scaduta',
        'Certificato richiesto',
        'Errore',
        'La password è stata resettata e deve essere modificata',
        'Modifica della password non autorizzata',
        'Per modificarla inserire la vecchia password',
        'Qualità della password insufficiente',
        'Password troppo corta',
        'Password troppo recente',
        'Password utilizzata troppo di recente',
        ' autenticazioni restanti, modifica la password!',
        '%d giorni, %d ore, %d minuti e %d secondi prima della scadenza della password, ricordati di modificarla!',
        'Le password non corrispondono',
        'La password è stata modificata',
        'Hai un nuovo messaggio',
        'URL errato',
        'Nessuno schema disponibile',
        'Vecchia password errata',
        'Nome utente errato',
        'Apertura di sessione vietata',
        'Conferma richiesta',
        'L\'indirizzo mail è obbligatorio ',
        'Chiave di conferma errata o troppo vecchia',
        'Invio della mail fallito',
        'Ti è stata inviata una mail',
        'Sei stato disconnesso',
        'Errore SAML indefinito',
        'Impossibile caricare il servizio SAML',
        'Problema di caricamento di un provider d\'identità',
        'Si è verificato un errore al momento dell\'autenticazione SAML',
        'Partner SAML non riconosciuto',
        'Destinazione del messaggio SAML errata',
        'Condizioni del messaggio SAML non rispettate',
        'L\'autenticazione avviata dal provider d\'identità non è autorizzata',
        'Si è verificato un errore al momento della disconnessione SAML',
        'Errore durante la gestione della firma del messaggio SAML',
        'Si è verificato un errore durante l\'utilizzo di un artefatto SAML',
        'Errore di comunicazione con le sessioni SAML',
        'Problema di caricamento di un provider di servizio',
        'Si è verificato un errore durante lo scambio di attributi SAML',
        'Pagina destinata al server OpenID',
        'Stai cercando di utilizzare un\'identità OpenID che non ti appartiene',
        'Attributo richiesto non disponibile',
        'Federation forbidden by security policy',
        'La mail di conferma è già stata inviata',
        'Password mancante',
        'Accesso non autorizzato al servizio CAS',
        'Inserisci il tuo indirizzo mail',
        'Nessun utente corrispondente',
        'Inserisci la nuova password',
        'Ti è stata inviata una mail di conferma',
        'Connessione al server Radius fallita',
        'La vecchia password è obbligatoria',
        'Indirizzo IP di provenienza non accreditato',
        'Errore di digitazione del captcha',
        'Devi inserire il captcha',
        'Inserisci le informazioni',
        'Manca un\'informazione',
        'Questo indirizzo è già utilizzato',
    ];
}

## @fn private arrayRef error_pt()
# Portiguese translation.
# @return Array of error messages
sub error_pt {
    use utf8;
    [
        'Utilizador autenticado',
        'A sua sessão expirou, deve se autenticar novamente',
        'Identificante ou senha não informados',
        'Conta ou senha LDAP da aplicação incorreta',
        'Utilizador inexistente',
        'Senha ou identificante incorretos',
        'Conexão ao servidor LDAP impossível',
        'Erro anormal do servidor LDAP',
        'Erro do módulo Apache::Sessão escolhida',
        'Queira autenticar-se',
        'Certificado inválido',
        'Fracasso da inicialização de Lasso:Login ou Lasso:Logout',
        'Fracasso da resolução do artefacto Liberty Alliance',
        'Échec de la défédération Liberty Alliance',
        'O pedido transmitido pelo fornecedor de identidade Liberty Alliance está vazio',
        'Uma das chamadas SOAP Liberty Alliance fracassou',
        'Uma das chamadas de desconexão Liberty Alliance fracassou',
        'Nenhum artefacto SAML encontrado, ou fracasso da auto-aceitação SSO',
        'Fracasso de Inicialização, construção ou pedido SSO',
        'Impossível registar o identificante de conexão Liberty Alliance',
        'Um processo terminal SOAP Liberty Alliance fracassou',
        'A sua conta está bloqueada',
        'A sua senha expirou',
        'Certificado exigido',
        'Erro',
        'A senha foi reinicializada e deve ser mudada',
        'Modificação da senha não autorizada',
        'A senha antiga deve ser fornecida para ser modificada',
        'Qualidade da senha insuficiente',
        'Senha demasiado curta',
        'Senha demasiado recente',
        'Senha utilizada demasiado recentemente',
        ' autenticações restantes, modifique a sua senha!',
        '%d dias, %d horas, %d minutos e %d segundos antes da expiração da sua senha, pense em substitui-la!',
        'As senhas não correspondem',
        'A senha foi mudada',
        'Recebeu uma nova mensagem',
        'URL incorreta',
        'Nenhum esquema disponível',
        'Antiga senha inválida',
        'Nome de utilizador incorreto',
        'Abertura de sessão proibida',
        'Confirmação pedida',
        'O endereço mail é obrigatório',
        'A  chave de confirmação é inválida ou demasiado antiga',
        'O  envio do mail fracassou',
        'Um mail foi-lhe enviado',
        'Foi desconectado',
        'Erro SAML não definido',
        'Impossível mudar o serviço SAML',
        'Problema no carregamento de um fornecedor de identidade',
        'Um erro ocorreu aquando da autenticação SAML',
        'O parceiro SAML não é reconhecido',
        'O destino da mensagem SAML está incorreto',
        'As condições da mensagem SAML não são respeitadas',
        'A  autenticação iniciada pelo fornecedor de identidade não é autorizada',
        'Um erro ocorreu aquando da desconexão SAML',
        'Erro na gestão da assinatura da mensagem SAML',
        'Um erro ocorreu aquando da utilização de um artefacto SAML',
        'Erro de comunicação com as sessões SAML',
        'Problema no carregamento de um fornecedor de serviço',
        'Um erro ocorreu aquando da mudança de atributos SAML',
        'Esta é uma página destinada aos servidores OpenID',
        'Tenta utilizar uma identidade OpenID que não lhe pertence',
        'Um atributo exigido não está disponível',
        'Federação proibida pela política de segurança',
        'O mail de confirmação já lhe foi enviado',
        'Senha não informada',
        'Acesso não autorizado ao serviço CAS',
        'Queira introduzir o seu endereço mail',
        'Não há utilizador correspondente',
        'Queira introduzir a sua nova senha',
        'Um mail de confirmação foi-lhe enviado',
        'A conexão ao servidor Radius fracassou',
        'A antiga senha é obrigatória',
        'Vem de um endereço IP que  não está autorizado',
        'Erro na introdução do captcha',
        'Deve introduzir o captcha',
        'Queira introduzir as suas informações',
        'Falta uma informação',
        'Este endereço já é utilizado',
    ];
}

## @fn private arrayRef error_de()
# Deutch translation.
# @return Array of error messages
sub error_de {
    use utf8;
    [
        'Benutzer authentifiziert',
        'Ihre Sitzung ist abgelaufen, Sie müssen sich neu authentifizieren',
        'Benutzername oder Passwort nicht eingegeben',
        'LDAP-Konto oder Passwort der Anwendung nicht korrekt',
        'Dieser Benutzer existiert nicht',
        'Benutzername oder Passwort nicht korrekt',
        'Verbindung mit dem LDAP-Server nicht möglich',
        'Anormaler Fehler des LDAP-Servers',
        'Fehler des gewählten Apache::Session Moduls',
        'Authentifizieren Sie sich bitte',
        'Zertifikat ungültig',
        'Fehler bei der Initialisierung von Lasso:Login oder Lasso:Logout',
        'Fehler bei der Auflösung des Artefakts Liberty Alliance',
        'Fehler bei der Deföderation von Liberty Alliance',
        'Die vom Identity-Provider Liberty Alliance zurückgesendete Anfrage ist leer',
        'Fehler bei einem der SOAP Liberty Alliance Aufrufe',
        'Fehler bei einem der Liberty Alliance Abmeldeaufrufe',
        'Es wurde kein SAML Artefakt gefunden oder Fehler bei der SSO Autoannahme',
        'Fehler bei der Initialisierung, Erstellung oder Anfrage SSO',
        'Der Liberty Alliance Benutzername kann nicht registriert werden',
        'Fehler bei einem Liberty Alliance Terminal-Prozess',
        'Ihr Konto ist blockiert',
        'Ihr Passwort ist abgelaufen',
        'Zertifikat erforderlich',
        'Fehler',
        'Das Passwort wurde reinitialisiert und muss geändert werden',
        'Änderung des Passworts nicht genehmigt',
        'Das alte Passwort muss eingegeben werden, um es zu ändern',
        'Passwort von unzureichender Qualität',
        'Passwort zu kurz',
        'Passwort zu neu',
        'Passwort wurde vor zu kurzer Zeit verwendet',
        ' Verbleibende Authentifizierungen, ändern Sie Ihr Passwort!',
        '%d Tage, %d Stunden, %d Minuten und %d Sekunden vor Ablauf Ihres Passworts; denken Sie daran, es zu ändern!',
        'Die Passwörter sind nicht gleich',
        'Das Passwort wurde geändert',
        'Sie haben eine neue Nachricht',
        'Fehlerhafte URL',
        'Kein Schema verfügbar',
        'Altes Passwort ungültig',
        'Benutzername nicht korrekt',
        'Öffnen einer Sitzung verboten',
        'Bestätigung angefordert',
        'Die E-Mail-Adresse ist obligatorisch',
        'Der Bestätigungsschlüssel ist ungültig oder zu alt',
        'Fehler beim Senden der E-Mail',
        'Es wurde eine E-Mail an Sie gesendet',
        'Sie wurden abgemeldet',
        'Nicht definierter SAML-Fehler',
        'Der SAML-Service konnte nicht geladen werden',
        'Problem beim Laden eines Identity Providers',
        'Bei der SAML-Authentifizierung ist ein Fehler eingetreten',
        'Der SAML-Partner wurde nicht erkannt',
        'Die Zieladresse der SAML-Nachricht ist nicht korrekt',
        'Die Bedingungen der SAML-Nachricht sind nicht erfüllt',
        'Die vom Identity Provider initiierte Authentifizierung ist nicht genehmigt',
        'Bei der SAML-Abmeldung ist ein Fehler eingetreten',
        'Fehler bei der Verwaltung der Signatur der SAML-Nachricht',
        'Bei der Verwendung eines SAML-Artefakts ist ein Fehler eingetreten',
        'Kommunikationsfehler mit den SAML-Sitzungen',
        'Problem beim Laden eines Service-Providers',
        'Beim Austausch von SAML-Attributen ist ein Fehler eingetreten',
        'Diese Seite ist für die OpenID-Server bestimmt',
        'Sie versuchen, eine OpenID-Identität, die Ihnen nicht gehört, zu verwenden',
        'Ein gefordertes Attribut ist nicht verfügbar',
        'Föderation durch die Sicherheitspolitik verboten',
        'Die Bestätigungs-E-Mail wurde bereits gesendet',
        'Passwort nicht eingegeben',
        'Zugang zum CAS-Service nicht genehmigt',
        'Geben Sie bitte Ihre E-Mail-Adresse ein',
        'Kein entsprechender Benutzer',
        'Geben Sie bitte Ihr neues Passwort ein',
        'Es wurde eine Bestätigungs-E-Mail an Sie gesendet',
        'Die Verbindung mit dem Radius-Server konnte nicht hergestellt werden',
        'Das alte Passwort ist obligatorisch',
        'Sie kommen von einer IP-Adresse, die nicht akkreditiert ist',
        'Fehler bei der Eingabe des Captchas',
        'Sie müssen das Captcha eingeben',
        'Geben Sie bitte Ihre Informationen ein',
        'Es fehlt eine Information',
        'Diese Adresse wird bereits verwendet',
    ];
}

## @fn private arrayRef error_nl()
# Dutch translation.
# @return Array of error messages
sub error_nl {
    use utf8;
    [
        'Geverifieerde gebruiker',
        'Uw sessie is verlopen, u moet zich opnieuw aanmelden',
        'Onbekende gebruikersnaam of wachtwoord',
        'LDAP-account of wachtwoord van de toepassing is niet correct',
        'Niet bestaande gebruiker',
        'Wachtwoord of identifier  is niet correct',
        'Kan geen verbinding maken met LDAP-server',
        'Abnormale fout van de LDAP-server',
        'Fout Apache-module::Gekozen sessie',
        'Identificeer uzelf',
        'Ongeldig certificaat',
        'Initialisatie Lasso mislukt : Login of Lasso: Afmelden',
        'Mislukte resolutie artefact Liberty Alliance',
        'Échec de la défédération Liberty Alliance',
        'Het verzoek verzonden door de identiteitsprovider Liberty Alliance is leeg',
        'Een van de oproepen SOAP Liberty Alliance is mislukt',
        'Een van de oproepen Liberty Alliance voor verbreken verbinding is mislukt',
        'Geen enkel SAML artefact gevonden, of zelfacceptatie SSO mislukt',
        'Initialisatie, opbouw of verzoek SSO mislukt',
        'Kon identifier verbinding Liberty Alliance niet registreren',
        'Een terminalproces Liberty Alliance is mislukt',
        'Uw account is geblokkeerd',
        'Uw wachtwoord is verlopen',
        'Certificaat nodig',
        'Fout',
        'Het wachtwoord is gereset en moet worden gewijzigd',
        'Niet-toegelaten wijziging wachtwoord',
        'Het oude wachtwoord is vereist voor wijziging',
        'Het wachtwoord is niet voldoende veilig',
        'Te kort wachtwoord',
        'Te recent wachtwoord',
        'Wachtwoord te recent gebruikt',
        'Resterende authenticaties, wijzig uw wachtwoord!',
        '%d dagen%d uur,%d minuten en %d seconden voor het verstrijken van de geldigheid van uw wachtwoord, vergeet niet om het te wijzigen!',
        'De wachtwoorden komen niet overeen',
        'Het wachtwoord is  gewijzigd',
        'U hebt een nieuw bericht ontvangen',
        'Onjuiste URL',
        'Geen enkel schema beschikbaar',
        'Oud ongeldig wachtwoord',
        'Gebruikersnaam onjuist',
        'Inloggen verboden',
        'Bevestiging gevraagd',
        'Het e-mailadres is verplicht',
        'Het bevestigingswachtwoord is ongeldig of te oud',
        'Het verzenden van de e-mail is mislukt',
        'Er is u een e-mail verzonden',
        'Uw verbinding is verbroken',
        'Niet-gedefinieerde SAML-fout',
        'Kan de service SAML niet laden',
        'Probleem laden identiteitsprovider',
        'Er is een fout opgetreden tijdens het inloggen van SAML',
        'De SAML partner is niet herkend',
        'De bestemming van het SAML-bericht is onjuist',
        'De voorwaarden van het SAML-bericht zijn niet voldaan',
        'Het inloggen geïnitieerd door de identiteitsprovider is niet toegestaan',
        'Er is een fout opgetreden tijdens het uitloggen van SAML',
        'Fout tijdens het beheer handtekening SAML bericht',
        'Er is een fout opgetreden tijdens het gebruik van een SAML-artefact',
        'Communicatiefout met sessies SAML',
        'Probleem laden van een identiteitsprovider',
        'Er is een fout opgetreden tijdens het uitwisselen van SAML-atributen',
        'Dit is een pagina bedoeld voor servers OpenID',
        'U probeert gebruik te maken van een OpenID-identiteit die niet de uwe is',
        'Een vereist attribuut is niet beschikbaar',
        'Federatie verboden door veiligheidsbeleid',
        'De e-mail ter bevestiging is verzonden',
        'Onbekend wachtwoord',
        'Onbevoegde toegang tot de CAS-service',
        'Vul uw e-mailadres in',
        'Geen overeenkomstige gebruiker',
        'Voer uw nieuwe wachtwoord in',
        'Er is u een e-mail ter bevestiging verzonden',
        'De verbinding met de server-Radius-is mislukt',
        'Het oude wachtwoord is vereist',
        'U hebt een IP-adres dat niet is erkend',
        'Fout in de captcha-invoer',
        'U moet de captcha invoeren',
        'Geef uw informatie',
        'Er ontbreekt een informatie',
        'Dit adres is al in gebruik',
    ];
}

## @fn private arrayRef error_ro()
# Romanian translation.
# @return Array of error messages
sub error_ro {
    use utf8;
    [
        'Utilizator autentificat',
        'Sesiunea dvs. a expirat, trebuie să vă reautentificaţi',
        'Identificator sau parolă inexistentă',
        'Cont sau parolă LDAP a aplicaţiei incorect',
        'Utilizator inexistent',
        'Parolă sau identificator incorect',
        'Conexiune imposibilă la serverul LDAP',
        'Eroare anormală a serverului LDAP',
        'Eroare a modulului Apache::Session aleasă',
        'Autentificare cerută',
        'Certificat invalid',
        'Eşec al iniţializării Lasso:Login sau Lasso:Logout',
        'Eşec al rezoluţiei artefact-ului Liberty Alliance',
        'Eşec al defederaţiei Liberty Alliance',
        'Cererea retrimisă de către furnizorul de identitate Liberty Alliance este goală',
        'Unul dintre apelurile SOAP Liberty Alliance a eşuat',
        'Unul dintre apelurile de deconectare Liberty Alliance a eşuat',
        'Nici un artefact SAML găsit, sau eşec al auto-acceptării SSO',
        'Iniţiere, construcţie sau cerere SSO în eşec',
        'Imposibil de a înregistra identificatorul de conectare Liberty Alliance',
        'Un proces terminal Liberty Alliance a eşuat',
        'Contul dvs. este blocat',
        'Parola dvs. a expirat',
        'Certificat cerut',
        'Eroare',
        'Parola a fost de resetare şi acum trebuie să fie schimbat',
        'Parola nu poate fi modificat',
        'Vechea parolă trebuie să fi, de asemenea, furnizate atunci când stabilesc o nouă parolă',
        'Calitate parola insuficiente',
        'Parola prea scurt',
        'Prea parolă nouă',
        'Parola folosit prea recent',
        ' authentications rămase, schimbaţi-vă parola!',
        '%d zile, %d ora, %d minute şi %d secundes înainte de expirarea parola dvs., asiguraţi-vă pentru a schimba!',
        'Parolele nu se potrivesc',
        'Parola a fost schimbată',
        'Ai un mesaj nou',
        'Rea URL',
        'Nici o posibilitate disponibilă',
        'Parola rău vechi',
        'Nume de utilizator gresit',
        'Conectare neautorizată',
        'Confirmare necesare',
        'Vă rugăm să introduceţi adresa dvs. de e-mail',
        'Cheie de confirmare este invalid sau prea veche',
        'Trimiterea mail nu a reuşit',
        'Un e-mail a fost trimis',
        'Aţi fost deconectat',
        'SAML eroare necunoscută',
        'Imposibil de a incarca serviciul SAML',
        'Problem when loading an identity provider',
        'Nu a fost o problemă la încărcarea unui furnizor de identitate',
        'Entitatea SAML este necunoscut',
        'Destinaţie de mesaj SAML nu este corectă',
        'Condiţiile de mesaj SAML nu sunt îndeplinite',
        'Autentificarea iniţiat de furnizor de identitate nu este permisă',
        'A apărut o eroare atunci când debranşaţi SAML',
        'Mesaj de eroare de gestionare a SAML semnatura',
        'A apărut o eroare în timp ce folosiţi un artefact SAML',
        'eroare de comunicare cu sesiuni SAML',
        'Problemă la încărcarea unui furnizor de servicii',
        'A apărut o eroare în timpul schimbului de SAML atribute',
        'Această pagină este proiectat pentru servere OpenID',
        'Când încercaţi să utilizaţi o identitate OpenID care nu vă aparţine',
        'Un atribut solicitate nu sunt disponibile',
        'Federation forbidden by security policy',
        'The confirmation mail was already sent',
        'Password field must be filled',
        'Access non granted on CAS service',
        'Vă rugăm să introduceţi adresa dvs. de e-mail',
        'No matching user',
        'Please provide your new password',
        'Un e-mail a fost trimis',
        'Radius connection has failed',
        'Old password is required',
        'You came from an unaccredited IP address',
        'You failed at typing the captcha',
        'trebuie să introduceţi CAPTCHA',
        'Please enter your information',
        'An information is missing',
        'This address is already used',
    ];
}

# Order of the constants:
# * PM_USER			0
# * PM_DATE			1
# * PM_IP			2
# * PM_SESSIONS_DELETED		3
# * PM_OTHER_SESSIONS		4
# * PM_REMOVE_OTHER_SESSIONS	5
# * PM_PP_GRACE			6
# * PM_PP_EXP_WARNING		7
# * PM_SAML_IDPSELECT           8
# * PM_SAML_IDPCHOOSEN          9
# * PM_REMEMBERCHOICE          10
# * PM_SAML_SPLOGOUT           11
# * PM_REDIRECTION             12
# * PM_BACKTOSP                13
# * PM_BACKTOCASURL            14
# * PM_LOGOUT                  15
# * PM_OPENID_EXCHANGE         16
# * PM_CDC_WRITER              17
# * PM_OPENID_RPNS             18
# * PM_OPENID_PA               19
# * PM_OPENID_AP               20
# * PM_ERROR_MSG               21
# * PM_LAST_LOGINS             22
# * PM_LAST_FAILED_LOGINS      23
# * PM_OIDC_CONSENT            24
# * PM_OIDC_SCOPE_OPENID       25
# * PM_OIDC_SCOPE_PROFILE      26
# * PM_OIDC_SCOPE_EMAIL        27
# * PM_OIDC_SCOPE_ADDRESS      28
# * PM_OIDC_SCOPE_PHONE        29
# * PM_OIDC_SCOPE_OTHER        30
# * PM_OIDC_CONFIRM_LOGOUT     31

sub msg_en {
    use utf8;
    [
        'User',
        'Date',
        'IP address',
        'The following sessions have been closed',
        'Other active sessions',
        'Remove other sessions',
        'authentications remaining, change your password!',
        '%d days, %d hours, %d minutes and %d seconds before password expiration, change it!',
        'Select your Identity Provider',
        'Redirection to your Identity Provider',
        'Remember my choice',
        'Logout from service providers...',
        'Redirection in progress...',
        'Go back to service provider',
        'The application you just logged out of has provided a link it would like you to follow',
        'Logout from other applications...',
        'Do you want to authenticate yourself on %s ?',
        'Update Common Domain Cookie',
        'Parameter %s requested for federation isn\'t available',
        'Data usage policy is available at',
        'Do you agree to provide the following parameters?',
        'Error Message',
        'Your last logins',
        'Your last failed logins',
        'The application %s would like to know:',
        'Your identity',
        'Your profile',
        'Your email',
        'Your address',
        'Your phone number',
        'Another information:',
        'Do you want to logout?',
    ];
}

sub msg_fr {
    use utf8;
    [
        'Utilisateur',
        'Date',
        'Adresse IP',
        'Les sessions suivantes ont été fermées',
        'Autres sessions ouvertes',
        'Fermer les autres sessions',
        'authentifications restantes, changez votre mot de passe !',
        '%d jours, %d heures, %d minutes et %d secondes avant expiration de votre mot de passe, pensez à le changer !',
        'Choisissez votre fournisseur d\'identité',
        'Redirection vers votre fournisseur d\'identité',
        'Se souvenir de mon choix',
        'Déconnexion des services...',
        'Redirection en cours...',
        'Retourner sur le fournisseur de service',
        'Le service duquel vous arrivez a fourni un lien que vous êtes invité à suivre',
        'Déconnexion des autres applications...',
        'Souhaitez-vous vous identifier sur le site %s ?',
        'Mise à jour du cookie de domaine commun',
        'Le paramètre %s exigé pour la fédération n\'est pas disponible',
        'La politique d\'utilisation des données est disponible ici',
        'Consentez-vous à communiquer les paramètres suivants&nbsp;?',
        'Message d\'erreur',
        'Vos dernières connexions',
        'Vos dernières connexions refusées',
        'L\'application %s voudrait connaître :',
        'Votre identité',
        'Vos informations personnelles',
        'Votre adresse électronique',
        'Votre adresse',
        'Votre numéro de téléphone',
        'Une autre information :',
        'Souhaitez-vous vous déconnecter&nbsp;?',
    ];
}

