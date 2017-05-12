    
$r = shift ;

%messages =
    (
    'de' =>
        {
        'add_item'=> 'Eintrag hinzufügen',
        'items_of'=> 'Bearbeiten der Einträge von',
        'addsel1' => 'Klicken Sie auf die Kategorie zu der Sie etwas hinzufügen möchten:',
        'addsel2' => 'oder fügen Sie eine neue Kategorie hinzu. Bitte geben Sie die Beschreibung in so vielen Sprachen wie Ihnen möglich ein.',
        'addsel3' => 'Falls Sie die Übersetzung nicht wissen, lassen Sie das entsprechende Eingabefeld leer.',
        'addsel4' => 'Kategorie hinzufügen',
        'addsel_upd' => 'Klicken Sie auf die Kategorie in der Sie etwas ändern möchten:',
        'addsel_login1' => 'Wenn Sie etwas an Ihren bisherigen Eingaben ändern möchten, müssen Sie sich zuerst',
        'addsel_login2' => 'anmelden',
        'addsel_login3' => '.',
        'add1'    => 'Hinzufügen eines neuen Eintrages zu',
        'edit1'   => 'Bearbeiten eines Eintrages von',
        'del1'    => 'Löschen eines Eintrages',
        'add2a'   => 'Bitte geben Sie die Beschreibung in so vielen Sprachen wie Ihnen möglich ein.',
        'add2b'   => 'Falls Sie die Übersetzung nicht wissen, lassen Sie das entsprechende Eingabefeld leer.',
        'add3'    => 'Hinzufügen zu',
        'update3' => 'Übernehmen',
        'delete3' => 'Löschen',
        'heading' => 'Überschrift',
        'url'     => 'URL',
        'description'  => 'Beschreibung',
	'state'   => 'Status',
        'show2'   => 'Folgender Eintrag wurde erfolgreich der Datenbank hinzugefügt/geändert',
        'del2'    => 'Der Eintrag wurde erfolgreich aus der Datenbank entfernt',
        'Search'  => 'Suchen',
        'under_construction' => 'Hinweis: Dieser Teil der Website befindet sich noch im Aufbau.',
        'more_news' => 'Weitere News...',
        'add_news' => 'News hinzufügen...',
        'display'  => 'anzeigen',
        'hide'     => 'nicht anzeigen',
        'logged_in_as'  => 'Angemeldet als',
        'already_logged_in_as'  => 'Sie sind bereits angemeldet als',
        'logoff'  => 'Hier können Sie sich wieder abmelden',
        'need_login'    => 'Sie müssen sich erst anmelden um diesen Bereich zu nutzen.',
        'login_head'      => q{Hier können Sie sich auf der Embperl-Site anmelden. Dies erlaubt Ihnen
                             Informationen bezüglich Embperl (Neugigkeiten, Sites die Embperl benutzen, 
                             Veröffentlichungen, Beispiele etc.) hinzuzufügen, zu ändern und zu löschen.},
        'loginnew'      => 'Sie erhalten Ihr Kennwort per E-Mail zugeschickt, bitte tragen Sie es unten ein um die Anmeldung zu vollenden und klicken dann auf "Anmelden".',
        'login1'        => 'Wenn Sie sich schon einmal angemeldet haben, geben Sie bitte Ihre E-Mail Adresse und Ihr Kennwort ein und klicken dann auf "Anmelden".',
        'login2'        => q{Wenn Sie sich das erste Mal anmelden, geben Sie lediglich Ihre E-Mail Adresse an 
                             und klicken auf "Neuen Benutzer-Account einrichten".
                             Sie bekommen dann ein neues Kennwort zugeschickt.},
        'login3'        => q{Haben Sie Ihr Kennwort vergessen, geben Sie Ihre E-Mail Adresse ein und klicken dann
                            auf "Neues Kennwort". Sie bekommen
                            dann ein neues Kennwort zugesandt.},
        'cookie_note' => 'HINWEIS: Zur Anmeldung ist es erforderlich das Ihr Browser Cookies akzeptiert',
        'user_email'     => 'E-Mail Adresse',
        'user_password'  => 'Kennwort',
        'user_name'      => 'Name',
        'login'     => 'Anmelden',
        'logout'    => 'Abmelden',
        'newuser'   => 'Neuen Benutzer-Account einrichten',
        'newpassword'  => 'Neues Kennwort',
	'error'        => 'Fehler',
	'warning'      => 'Warnung',
	'error_reason' => 'Grund',

	# Mail Handling
        'mail_greeting' => 'Hallo!',
	'mail_account_request' => 'Sie oder jemand anderes haben ein Benutzer-Konto auf der Embperl Website angefordert.',
	'mail_note1' => 'Ihr Kontoname ist Ihre E-Mail-Adresse, d.h. sie sollten auf der Embperl-Webseite',
	'mail_note2' => 'als Login-Name angeben.',
	'mail_your_pw_is' => 'Ihr Kennwort ist auf',
	'mail_note_quotes' => 'gesetzt (ohne die Hochkommata)',
	'mail_note_login' => 'Sie können sich jetzt unter folgender Adresse anmelden:',
	'mail_sig' => 'Grüße von der Embperl Webseite',
        'mail_pw' => 'Sie oder jemand anders hat ein neues Kennwort für Ihr Benutzerkonto auf der Embperl Webseite beantragt.',
	'mail_subj_newuser' => 'Ihr Benutzerkonto auf der Embperl Website',
	'mail_subj_newpw' => 'Ihr neues Kennwort auf der Embperl Website',

	# Errors
        'err_notfound'      => 'Das angeforderte Dokument konnte nicht gefunden werden.',
	'err_email_needed' => "Sie müssen eine E-Mail Adresse eingeben.",
	'err_access_denied' => 'Zugriff verweigert. Entweder die E-Mail Adresse oder das Kennwort sind falsch.',
	'err_user_exists' => 'Benutzer existiert bereits. Vielleicht möchten Sie ein neues Kennwort an diese Adresse senden?',
	'err_user_not_exists' => "Benutzer existiert nicht. Vielleicht haben Sie sich vertippt oder sich unter einer anderen E-Mail Adresse registriert?",
	'err_user_mail' => 'Mail kann nicht an den Benutzer gesendet werden.',
	'err_pw_mail' => 'Kennwort kann nicht per Mail an den Benutzer versendet werden.',
	'err_db' => 'Datenbankfehler',
	'err_update_db' => 'Datenbankfehler beim Update',
	'err_update_lang_db' => 'Datenbankehler wärend Update der Sprachversionen',
	'err_cannot_update_no_id' => 'Update fehlgeschlagen: Zugriff verweigert',
	'err_cannot_update_maybe_wrong_user' => 'Update fehlgeschlagen: Berechtigung fehlt',
	'err_cannot_delete_no_id' => 'Löschen fehlgeschlagen: Berechtigung fehlt',
	'err_cannot_delete_maybe_wrong_user_or_no_such_item' => 'Löschen fehlgeschlagen: Berechtigung fehlt',
	'err_cannot_delete_db_error' => 'Löschen fehlgeschlagen: Datenbankfehler',
	'err_item_not_found_or_access_denied' => 'Eintrag nicht gefunden oder Zugriff verweigert',
        'err_item_admin_mail'  => 'Fehler beim Mailversand',

	# Warnings
	'warn_url_removed_white_space' => 'Leerzeichen wurden aus URL entfernt',
	'warn_url_added_http' => '"http://" zu URL hinzugefügt',

	# Success
	'suc_login' => 'Anmeldung erfolgreich',
	'suc_logout' => 'Abmeldung erfolgreich',
	'suc_password_sent' => 'Das Kennwort wurde erfolgreich versendet',
	'suc_item_deleted' => 'Eintrag erfolgreich gelöscht',
	'suc_item_updated' => 'Eintrag erfolgreich geändert',
	'suc_item_created' => 'Eintrag erfolgreich erstellt',
        },
     'en' =>
        {
        'add_item'=> 'Add new entry',
        'items_of'=> 'Edit items from',
        'addsel1' => 'Click on the category for wich you want to add a new item:',
        'addsel2' => 'or add new category. Please enter the description in as much languages as possible.',
        'addsel3' => 'If you don\'t know the translation leave the corresponding input field empty.',
        'addsel4' => 'Add category',
        'addsel_upd' => 'Click on the category for wich you want to edit a item:',
        'addsel_login1' => 'If you like to change your previous entries, you need to', 
        'addsel_login2' => 'login', 
        'addsel_login3' => 'first.', 
        'add1'    => 'Add a new item to',
        'edit1'   => 'Edit item of',
        'del1'    => 'Delete item',
        'add2a'   => 'Please enter the description in as much languages as possible.',
        'add2b'   => 'If you don\'t know the translation leave the corresponding input field empty.',
        'add3'    => 'Add to',
        'update3' => 'Apply',
        'delete3' => 'Delete',
        'heading' => 'Heading',
        'url'     => 'URL',
        'description' => 'Description',
	'state'   => 'State',
        'show2'   => 'The following entry has been sucessfully added/modified to the database',
        'del2'    => 'The entry has been sucessfully removed from the database',
        'Search'  => 'Search',
        'under_construction' => 'NOTE: This part of the site is still under contruction.',
        'more_news' => 'more news...',
        'add_news' => 'add news...',
        'display'  => 'display',
        'hide'     => 'hide',
        'logged_in_as'  => 'logged in as',
        'already_logged_in_as'  => 'You are already logged in as',
        'logoff'        => 'Here you can logoff from the site',
        'need_login'    => q{You must be logged in to access this area.}, 
        'login_head'    => q{Here you can logon to the Embperl-Site.
                             This allows you to enter information about Embperl like news,
                             sites using Embperl, publications, examples etc.
                             You may also edit and delete the information you have enterd before},
        'loginnew'      => 'You will receive your new password via e-mail. Please enter it in the form below and click on "Login".',
        'login1'        => q{If you have already a user account, please enter your email address and 
                             password and click on 'Login'. },
        'login2'        => q{If you have not already a user account, just enter your email and click
                             on 'Create new account'.
                            A new account will be created and the password will be imediately mailed 
                            to address you entered.},
        'login3'        => q{In case you have forgotten your password, click on 'New password', 
                             a new password will be mailed
                            to your email address.},
        'cookie_note' => 'NOTE: For login it\'s necessary that your browser accepts cookies',
        'user_email'     => 'E-Mail address',
        'user_password'  => 'Password',
        'user_name'      => 'Name',
        'login'     => 'Login',
        'logout'    => 'Logout',
        'newuser'   => 'Create new account',
        'newpassword'  => 'New password',
	'error'        => 'Error',
	'warning'      => 'Warning',
	'error_reason' => 'Reason',

	# Mail Handling
        'mail_greeting' => 'Hi!',
	'mail_account_request' => 'You or someone else requested a user account for the Embperl website.',
	'mail_note1' => 'Your account name is your e-mail address, that means you should enter',
	'mail_note2' => 'as login name on the Embperl website.',
	'mail_your_pw_is' => 'Your password is set to',
	'mail_note_quotes' => '(without the single quotes)',
	'mail_note_login' => 'You can now log in at the following address:',
	'mail_sig' => 'Regards, Your Embperl Website',
        'mail_pw' => 'You or possible someone else requested a new password for your account on the Embperl Website',
	'mail_subj_newuser' => 'Your Embperl Website Account',
	'mail_subj_newpw' => 'Your new Embperl Website password',

	# Errors
        'err_notfound'      => 'The document you requested wasn\'t found.',
	'err_email_needed' => "You haven't entered an email address. This is mandatory for the requested action.",
	'err_access_denied' => 'Access Denied. Either user name (e-mail address) or password were wrong.',
	'err_user_exists' => 'User already exists. Perhaps you want a new password sent to this address?',
	'err_user_not_exists' => "User doesn't exists. Maybe there's a typo in the address or you registered with a different address?",
	'err_user_mail' => 'Could not sent mail to user.',
	'err_pw_mail' => 'Could not sent mail with password to user.',
	'err_db' => 'Database error',
	'err_update_db' => 'Database error while updating',
	'err_update_lang_db' => 'Database error while updating languages',
	'err_cannot_update_no_id' => 'Update failed: Permission denied',
	'err_cannot_update_maybe_wrong_user' => 'Update failed: Permission denied',
	'err_cannot_delete_no_id' => 'Deletion failed: Permission denied',
	'err_cannot_delete_maybe_wrong_user_or_no_such_item' => 'Deletion failed: Permission denied',
	'err_cannot_delete_db_error' => 'Deletion failed: Database error',
	'err_item_not_found_or_access_denied' => 'Item not found or access denied',
        'err_item_admin_mail'  => 'Error sending mail',

	# Warnings
	'warn_url_removed_white_space' => 'Removed whitespaces from URL.',
	'warn_url_added_http' => 'Added "http://" to the incomplete URL.',

	# Success
	'suc_login' => 'Successfully logged in',
	'suc_logout' => 'Successfully logged out',
	'suc_password_sent' => 'Successfully sent password to given e-mail address',
	'suc_item_deleted' => 'Item successfully deleted',
	'suc_item_updated' => 'Item successfully updated',
	'suc_item_created' => 'Item successfully created',
        },
    ) ;


$lang = $r -> param -> language ;
push @{$r -> messages}, $messages{$lang} ;
push @{$r -> default_messages}, $messages{'en'} if ($lang ne 'en') ;
    


