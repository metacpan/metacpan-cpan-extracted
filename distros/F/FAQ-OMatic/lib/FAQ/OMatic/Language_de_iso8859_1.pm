################################################
###
### Language_de_iso8859_1.pm
###

sub translations {
	my $tx = shift;
	my $txfile = <<'__EOF__';
### 
### submitItem.pm
###

msgid "The file (%0) doesn't exist."
msgstr "Die Datei (%0) existiert nicht."

msgid "To name your FAQ-O-Matic, use the [Appearance] page to show the expert editing commands, then click [Edit Category Title and Options]."
msgstr "Um Ihre FAQ-O-Matic umzubenennen, klicken Sie auf [Anzeige] zur Anzeige der erweiterten Editier-Funktionen und wählen dann [Kategorie-Titel & -Optionen]."

msgid "Your browser or WWW cache has truncated your POST."
msgstr "Ihr Browser oder WWW-Cache hat Ihr Posting gekürzt."

msgid "Changed the item title, was "%0""
msgstr "Der bisherige Titel <i>%0</i> wurde geändert"

msgid "Your part order list (%0) "
msgstr "Ihre Liste mit den Abschnitten (%0) "

msgid "doesn't have the same number of parts (%0) as the original item."
msgstr "hat nicht die gleiche Anzahl von Abschnitten (%0) wie das Original."

msgid "doesn't say what to do with part %0."
msgstr "sagt nicht, was mit Abschnitt %0 passieren soll."

###
### submitMove.pm
###

msgid "The moving file (%0) is broken or missing."
msgstr "Das zu verschiebene Objekt (%0) ist defekt oder nicht vorhanden."

msgid "The newParent file (%0) is broken or missing."
msgstr "Das Ziel-Elternobjekt (%0) ist defekt oder nicht vorhanden."

msgid "The oldParent file (%0) is broken or missing."
msgstr "Das Quell-Elternobjekt (%0) ist defekt oder nicht vorhanden."

msgid "The new parent (%0) is the same as the old parent."
msgstr "Das Ziel-Elternobjekt (%0) stimmt mit dem Quell-Elternobjekt überein."

msgid "The new parent (%0) is the same as the item you want to move."
msgstr "Das Ziel-Elternobjekt (%0) ist gleich dem zu verschiebendem Objekt."

msgid "The new parent (%0) is a child of the item being moved (%1)."
msgstr "Das Ziel-Elternobjekt (%0) ist ein Kind des zu verschiebenden Objekts (%1)."

msgid "You can't move the top item."
msgstr "Sie können das in der Hierarchie höchste Objekt nicht verschieben."

msgid "moved a sub-item to %0"
msgstr "Subeintrag verschoben nach %0"

msgid "moved a sub-item from %0"
msgstr "Subeintrag verschoben von %0"

###
### submitPass.pm
###

msgid "An email address must look like 'name@some.domain'."
msgstr "Eine eMail-Adresse muss aussehen wie 'name@some.domain'."

msgid "If yours (%0) does and I keep rejecting it, please mail %1 and tell him what's happening."
msgstr "Wenn Ihre Mailadresse (<i>%0</i>) dies tut und nicht akzeptiert wurde, schicken Sie bitte eine eMail mit der Fehlerbeschreibung an %1."

msgid "Your password may not contain spaces or carriage returns."
msgstr "Ihr Passwort darf keine Leerzeichen oder Zeilenvorschübe enthalten."

msgid "Your Faq-O-Matic authentication secret"
msgstr "Ihr Faq-O-Matic Schlüssel"

msgid "I couldn't mail the authentication secret to "%0" and I'm not sure why."
msgstr "Konnte den Schlüssel aus ungeklärter Ursache nicht an <i>%0</i> senden."

msgid "The secret you entered is not correct."
msgstr "Der eingegebe Schlüssel ist falsch."

msgid "Did you copy and paste the secret or the URL completely?"
msgstr "Haben Sie die URL komplett kopiert und wieder eingefügt?"

msgid "I sent email to you at "%0". It should arrive soon, containing a URL."
msgstr "Es wurde eine eMail zur Adresse <i>%0</i> geschickt. Die Mail, die eine URL enthält, wird gleich in Ihrer Mailbox sein."

msgid "Either open the URL directly, or paste the secret into the form below and click Validate."
msgstr "Öffnen Sie entweder die URL direkt oder aber fügen Sie den Schlüssel in das Eingabefeld unten ein und klicken auf Überprüfen."

msgid "Thank you for taking the time to sign up."
msgstr "Vielen Dank das Sie sich Zeit genommen haben für die Registrierung."

msgid "Secret:"
msgstr "Schlüssel:"

msgid "Validate"
msgstr "Überprüfen"

###
### editBag.pm
###

msgid "Replace bag"
msgstr "Ersetze Datei-Objekt"

msgid "Replace which bag?"
msgstr "Welches Datei-Objekt ersetzen?"

msgid "Hint: Leave blank and Bag Data filename will be used."
msgstr "Hinweis: Bei leerem Objektnamen wird der Dateiname verwendet."

msgid "Inline (Images only):"
msgstr "Inline (Nur Grafiken):"

###
### OMatic.pm
###

msgid "Warnings:"
msgstr "Warnungen:"

###
### install.pm
###

msgid "Untitled Faq-O-Matic"
msgstr "Unbenannte Faq-O-Matic"

msgid "Faq-O-Matic Installer"
msgstr "Faq-O-Matic Installation"

msgid "%0 failed: "
msgstr "%0 schlug fehl: "

msgid "Unknown step: "%0"."
msgstr "Unbekannter Schritt: "%0"."

msgid "Updating config to reflect new meta location <b>%0</b>."
msgstr "Konfiguration wird aktualisiert für neues meta-Verzeichnis <b>%0</b>."

msgid "(Can't find <b>config</b> in '%0' -- assuming this is a new installation.)"
msgstr "(Konnte <b>config</b> nicht in '%0' finden -- vermutlich ist dies eine Neuinstallation.)"

msgid "Click here</a> to create %0."
msgstr "Klicken Sie hier</a>, um %0 zu erzeugen."

msgid "If you want to change the CGI stub to point to another directory, edit the script and then"
msgstr "Wenn Sie den CGI-Abschnitt in einem anderem Verzeichnis ablegen möchten, editieren Sie das Skript und dann"

msgid "click here to use the new location"
msgstr "klicken Sie hier, um das neue Verzeichnis zu benutzen"

msgid "FAQ-O-Matic stores files in two main directories.<p>The <b>meta/</b> directory path is encoded in your CGI stub ($0). It contains:"
msgstr "FAQ-O-Matic speichert Dateien in zwei Haupverzeichnisse.<p>Das <b>meta/</b>-Verzeichnis ist im CGI-Script ($0) codiert. Es enthält:"

msgid "<ul><li>the <b>config</b> file that tells FAQ-O-Matic where everything else lives. That's why the CGI stub needs to know where meta/ is, so it can figure out the rest of its configuration. <li>the <b>idfile</b> file that lists user identities. Therefore, meta/ should not be accessible via the web server. <li>the <b>RCS/</b> subdirectory that tracks revisions to FAQ items. <li>various hint files that are used as FAQ-O-Matic runs. These can be regenerated automatically.</ul>"
msgstr "<ul><li>Das <b>config</b>-File, wo alle FAQ-O-Matic-Verzeichniseinträge abgelegt sind. Daher muss das CGI-Script wissen, wo meta/ liegt, um so den Rest der Konfiguration herausfinden zu können. <li>Das <b>idfile</b> wo Benutzerdaten abgelegt werden. Deshalb sollte das Verzeichnis meta/ nicht via Web-Server freigegeben sein. <li>Das <b>RCS/</b> Unterverzeichnis, was die verschiedenen Versionen der FAQ-Einträge vorhält. <li>verschiedene Dateien die zur Laufzeit von FAQ-O-Matic angelegt und benötigt werden.</ul>"

msgid "<p>The <b>serve/</b> directory contains three subdirectories <b>item/</b>, <b>cache/</b>, and <b>bags/</b>. These directories are created and populated by the FAQ-O-Matic CGI, but should be directly accessible via the web server (without invoking the CGI)."
msgstr "<p>Das <b>serve/</b>-Verzeichnis enthält drei Unterverzeichnisse: <b>item/</b>, <b>cache/</b> und <b>bags/</b>. Diese Verzeichnisse werden erzeugt und benutzt von FAQ-O-Matic-CGI und sollten daher auf dem Webserver frei verfügbar sein (ohne CGI einzuschalten)."

msgid "<ul><li>serve/item/ contains only FAQ-O-Matic formatted source files, which encode both user-entered text and the hierarchical structure of the answers and categories in the FAQ. These files are only accessed through the web server (rather than the CGI) when another FAQ-O-Matic is mirroring this one. <li>serve/cache/ contains a cache of automatically-generated HTML versions of FAQ answers and categories. When possible, the CGI directs users to the cache to reduce load on the server. (CGI hits are far more expensive than regular file loads.) <li>serve/bags/ contains image files and other ``bags of bits.'' Bit-bags can be linked to or inlined into FAQ items (in the case of images). </ul>"
msgstr "<ul><li>serve/item/ enthält ausschließlich FAQ-O-Matic-formatierte Source-Files, die den vom Benutzer eingegebenen Text und die hierachische Struktur der Einträge und Kategorien enthalten. Auf diese Dateien kann nur über den Webserver zugegriffen werden, wenn ein anderes FAQ-O-Matic diese spiegelt. <li>serve/cache/ enthält einen Cache automatisch erstellter HTML-Versionen von FAQ-Einträgen und Kategorien. Wenn möglich, wird der Cache benutzt, um den Server zu entlasten. (CGI-Zugriffe sind weitaus teurer als reguläre Dateizugriffe.) <li>serve/bags/ enthält Bild-Dateien und und andere Datei-Objekte. Datei-Objekte können in FAQ-Einträge eingefügt werden).</ul>"

msgid "I don't have write permission to <b>%0</b>."
msgstr "Habe keine Schreib-Berechtigung für <b>%0</b>."

msgid "I couldn't create <b>%0</b>: %1"
msgstr "Fehler beim Erzeugen von <b>%0</b>: %1"

msgid "<b>%0</b> already contains a file '%1'."
msgstr "<b>%0</b> enthält bereits eine Datei '%1'."

msgid "Created <b>%0</b>."
msgstr "<b>%0</b> erzeugt."

msgid "Created new config file."
msgstr "Neues Config-File erzeugt."

msgid "The idfile exists."
msgstr "Das ID-File ist vorhanden."

msgid "Configuration Main Menu (install module)"
msgstr "Konfigurationsmenü"

msgid "Go To Install/Configuration Page"
msgstr "Zum Konfigurationsmenü"

msgid "Perform these tasks in order to prepare your FAQ-O-Matic version %0:"
msgstr "Führen Sie diese Schritte zur Installation und Konfiguration Ihrer FAQ-O-Matic Version %0 durch:"

msgid "Define configuration parameters"
msgstr "Festlegen der Konfigurationsparameter"

msgid "Set your password and turn on installer security"
msgstr "Wählen Sie Ihr Passwort und Installations-Sicherheit"

msgid "(Need to configure $mailCommand and $adminAuth)"
msgstr "($mailCommand und $adminAuth müssen definiert sein)"

msgid "(Installer security is on)"
msgstr "(Installations-Sicherheit ist aktiviert)"

msgid "Create item, cache, and bags directories in serve dir"
msgstr "Erzeugen der Eintrags-, Cache und Datei-Objekt-Verzeichnisse"

msgid "Copy old items</a> from <tt>%0</tt> to <tt>%1</tt>."
msgstr "Kopieren alter Einträge</a> von <tt>%0</tt> nach <tt>%1</tt>."

msgid "Install any new items that come with the system"
msgstr "Installieren neuer System-Einträge"

msgid "Create system default items"
msgstr "Erstellen der Standard-Objekte"

msgid "Created category "%0"."
msgstr "Kategorie <b>%0</b> erzeugt."

msgid "Rebuild the cache and dependency files"
msgstr "Erneuern des Cache und der davon abhängigen Dateien"

msgid "Install system images and icons"
msgstr "Installieren der Systemgrafiken und Icons"

msgid "Update mirror from master now. (this can be slow!)"
msgstr "Update der Mirror-Files vom Master (kann lange dauern!)"

msgid "Set up the maintenance cron job"
msgstr "Einrichten des Wartungs-Scripts in cron"

msgid "Run maintenance script manually now"
msgstr "Starte Wartungs-Skript jetzt manuell"

msgid "(Need to set up the maintenance cron job first)"
msgstr "(Das Wartungs-Script muss zuerst installiert werden)"

msgid "Maintenance last run at:"
msgstr "Letzte Ausführung des Wartungs-Scripts:"

msgid "Mark the config file as upgraded to Version %0"
msgstr "Vermerken der neuen Version %0 im Konfigurationsfile"

msgid "Select custom colors for your Faq-O-Matic</a> (optional)"
msgstr "Festlegung benutzerdefinierter Farben für Faq-O-Matic</a> (optional)"

msgid "Define groups</a> (optional)"
msgstr "Einrichtung von Gruppen</a> (optional)"

msgid "Upgrade to CGI.pm version 2.49 or newer."
msgstr "Upgrade auf CGI.pm Version 2.49 oder neuer."

msgid "(optional; older versions have bugs that affect bags)"
msgstr "(optional; ältere Versionen haben Fehler beim Umgang mit Datei-Objekten)"

msgid "You are using version %0 now."
msgstr "Sie benutzen derzeit Version %0."

msgid "Bookmark this link to be able to return to this menu."
msgstr "Setzen Sie ein Lesezeichen auf diese URL, damit Sie wieder zum Menü zurückkehren können."

msgid "Go to the Faq-O-Matic"
msgstr "Zur Faq-O-Matic"

msgid "(need to turn on installer security)"
msgstr "(Installations-Sicherheit geht verloren)"

msgid "Other available tasks:"
msgstr "Weitere vorhandene Tasks:"

msgid "See access statistics"
msgstr "Zugriffs-Statistik anzeigen"

msgid "Examine all bags"
msgstr "Untersuchen aller Datei-Objekte"

msgid "Check for unreferenced bags (not linked by any FAQ item)"
msgstr "Suche nach Datei-Objekten, die in keinem FAQ-Eintrag vorhanden sind"

msgid "Rebuild the cache and dependency files"
msgstr "Erneuern des Cache und der davon abhängigen Dateien"

msgid "The Faq-O-Matic modules are version %0."
msgstr "Die Faq-O-Matic-Module haben die Version %0."

msgid "I wasn't able to change the permissions on <b>%0</b> to 755 (readable/searchable by all)."
msgstr "Kann die Zugriffsrechte von <b>%0</b> nicht auf 755 (lesbar/suchbar von allen) ändern."

msgid "Rewrote configuration file."
msgstr "Config-File neu geschrieben."

msgid "%0 (%1) has an internal apostrophe, which will certainly make Perl choke on the config file."
msgstr "%0 (%1) enthält einen Apostroph, der Perl am Lesen des Config-File scheitern lassen wird."

msgid "%0 (%1) doesn't look like a fully-qualified email address."
msgstr "%0 (%1) ist keine vollqualifizierte eMail-Adresse"

msgid "%0 (%1) isn't executable."
msgstr "%0 (%1) ist nicht ausführbar."

msgid "%0 has funny characters."
msgstr "%0 enthält nicht erlaubt Zeichen."

msgid "You should <a href="%0">go back</a> and fix these configurations."
msgstr "Sie sollten <a href="%0">zurückgehen</a> und diese Einstellungen korrigieren."

msgid "updated config file:"
msgstr "Config-File aktualisiert:"

msgid "Redefine configuration parameters to ensure that <b>%0</b> is valid."
msgstr "Passen Sie die konfigurationsparameter an, um die Gültigkeit von <b>%0</b> sicherzustellen."

msgid "Jon made a mistake here; key=%0, property=%1."
msgstr "Jon hat hier einen Fehler gemacht; key=%0, property=%1."

msgid "<b>Mandatory:</b> System information"
msgstr "<b>Nötig:</b> System-Information"

msgid "Identity of local FAQ-O-Matic administrator (an email address)"
msgstr "Identität (eMail-Adresse) des FAQ-O-Matic Administrators"

msgid "A command FAQ-O-Matic can use to send mail. It must either be sendmail, or it must understand the -s (Subject) switch."
msgstr "Kommando, das FAQ-O-Matic zum eMail-Versand nutzen kann. Es muss die -s (Subject) Option verstehen (z.B. sendmail)."

msgid "The command FAQ-O-Matic can use to install a cron job."
msgstr "Kommando, das FAQ-O-Matic zur Installation eines cron-Jobs nutzen kann"

msgid "Path to the <b>ci</b> command from the RCS package."
msgstr "Pfad zum <b>ci</b> Kommando aus dem RCS-Paket."

msgid "<b>Mandatory:</b> Server directory configuration"
msgstr "<b>Nötig:</b> Server-Verzeichnis-Konfiguration"

msgid "Protocol, host, and port parts of the URL to your site. This will be used to construct link URLs. Omit the trailing '/'; for example: <tt>http://www.dartmouth.edu</tt>"
msgstr "Protokoll-, Host- und Port-Teil der URL Ihrer Site. Dies wird benutzt, um Link-URLs zu konstruieren (ohne abschliessendes '/'). Beispiel: <tt>http://www.dartmouth.edu</tt>"

msgid "The path part of the URL used to access this CGI script, beginning with '/' and omitting any parameters after the '?'. For example: <tt>/cgi-bin/cgiwrap/jonh/faq.pl</tt>"
msgstr "Lokaler Pfad-Teil der URL, um das FOM CGI-Script anzusprechen (beginnend mit dem führenden '/', aber ohne '?' und die folgenden Parameter). Beispiel: <tt>/cgi-bin/cgiwarp/faq.pl</tt>"

msgid "Filesystem directory where FAQ-O-Matic will keep item files, image and other bit-bag files, and a cache of generated HTML files. This directory must be accessible directly via the http server. It might be something like /home/faqomatic/public_html/fom-serve/"
msgstr "Dateisystem-Verzeichnis, in dem FAQ-O-Matic die item-Files, andere Datei-Objekte und den Cache von erzeugten HTML-Files ablegt. Das Verzeichnis muss für den HTTP-Server schreibbar sein. Beispiel : <tt>/home/faqomatic/public_html/fom-serve/<tt>"

msgid "The path prefix of the URL needed to access files in <b>$serveDir</b>. It should be relative to the root of the server (omit http://hostname:port, but include a leading '/'). It should also end with a '/'."
msgstr "Lokales Pfad-Präfix der URL, um Dateien in <b>$serveDir</b> anzusprechen (ohne Protokoll-, Host- und Port-Teil, aber einschliesslich führendem und abschliessendem '/'). Beispiel: <tt>/faqomatic/fom-serve/</tt>"

msgid "Use the <u>%0</u> links to change the color of a feature."
msgstr "Benutzen Sie die <u>%0</u> Links um die entsprechende Farbe zu ändern."

msgid "An Item Title"
msgstr "Titel eines Eintrags"

msgid "A regular part is how most of your content will appear. The text colors should be most pleasantly readable on this background."
msgstr "In solch einem normalen Text-Abschnitt wird der meiste Inhalt erscheinen.<br>Die Textfarben sollten auf diesem Hintergrund gut lesbar sein."

msgid "A new link"
msgstr "Ein neuer/nicht besuchter Link"

msgid "A visited link"
msgstr "Ein besuchter Link"

msgid "A search hit"
msgstr "Ein Suchergebnis"

msgid "A directory part should stand out"
msgstr "Ein Kategorie-Abschnitt sollte optisch gegenüber normalen Text-Abschnitten hervortreten"

msgid "Regular text"
msgstr "Normaler Text"

msgid "Proceed to step '%0'"
msgstr "Weiter mit Schritt '%0'"

msgid "Select a color for %0:"
msgstr "Wählen Sie eine Farbe für %0:"

msgid "Or enter an HTML color specification manually:"
msgstr "Oder geben Sie einen HTML-Farben-Code ein:"

msgid "Select"
msgstr "OK"

msgid "<i>Optional:</i> Miscellaneous configurations"
msgstr "<i>Optional:</i> Verschiedene Einstellungen"

msgid "Select the display language."
msgstr "Sprachauswahl"

msgid "Show dates in 24-hour time or am/pm format."
msgstr "Zeit-Anzeige im 24h- oder am/pm-Format"

msgid "If this parameter is set, this FAQ will become a mirror of the one at the given URL. The URL should be the base name of the CGI script of the master FAQ-O-Matic."
msgstr "Wenn diese Einstellung gesetzt ist, wird FAQ-O-Matic von der angegebenen URL gespiegelt. Die URL sollte auf das FAQ-O-Matic-CGI-Script auf dem Master zeigen."

msgid "An HTML fragment inserted at the top of each page. You might use this to place a corporate logo."
msgstr "HTML-Fragment, das an jedem Seitenanfang eingefügt wird, und zur Anzeige eines Firmen-Logo benutzt werden kann."

msgid "If this field begins with <tt>file=</tt>, the text will come from the named file in the meta directory; otherwise, this field is included verbatim."
msgstr "Beginnt dieses Feld mit <tt>file=</tt>, wird der Text aus der so referenzierten Datei im meta-Verzeichnis genommen. Ansonsten wird der Feldinhalt wörtlich übernommen."

msgid "The <tt>width=</tt> tag in a table. If your <b>$pageHeader</b> has <tt>align=left</tt>, you will want to make this empty."
msgstr "<tt>width=</tt> Tag in Tabellen. Enthält Ihr <b>$pageHeader</b> <tt>align=left</tt>, sollte dieses Feld leer gelassen werden."

msgid "An HTML fragment appended to the bottom of each page. You might use this to identify the webmaster for this site."
msgstr "HTML-Fragment, das an jedem Seiten-Ende eingefügt wird, und zur Identifikation des Webmasters benutzt werden kann."

msgid "Where FAQ-O-Matic should send email when it wants to alert the administrator (usually same as $adminAuth)"
msgstr "An wen soll FAQ-O-Matic eine Mail schicken, wenn der Administrator alarmiert werden soll (normalerweise gleich $adminAuth)"

msgid "If true, FAQ-O-Matic will mail the log file to the administrator whenever it is truncated."
msgstr "Wenn gesetzt, schickt FAQ-O-Matic das Logfile bei jeder Kürzung als Mail an den Administrator."

msgid "User to use for RCS ci command (default is process UID)"
msgstr "Benutzer, unter dessen ID das RCS ci-Kommando ablaufen soll (default: UID)"

msgid "Links from cache to CGI are relative to the server root, rather than absolute URLs including hostname:"
msgstr "Links vom Cache zu CGI sind relativ zum Server-Root, nicht absolute URLs inklusive Hostname:"

msgid "mailto: links can be rewritten such as jonhATdartmouthDOTedu (cheesy), jonh (nameonly), or e-mail addresses suppressed entirely (hide)."
msgstr "Ausgabe von mailto:-Links ohne Modifikation (off), als jonhATdartmouthDOTedu (cheesy), jonh (nameonly) oder komplett ohne eMail-Adresse (hide)."

msgid "Number of seconds that authentication cookies remain valid. These cookies are stored in URLs, and so can be retrieved from a browser history file. Hence they should usually time-out fairly quickly."
msgstr "Zeit in Sekunden, in der die Authentifikationscookies gültig sind. Die Cookies werden in URLs gespeichert und können mit der Browser-History aufgerufen werden. Daher sollte der TimeOut kurz genug gewählt werden."

msgid "<i>Optional:</i> These options set the default [Appearance] modes."
msgstr "<i>Optional:</i> Diese Einstellungen werden als Default-Werte bei [Anzeige] verwendet."

msgid "Page rendering scheme. Do not choose 'text' as the default."
msgstr "Seitenaufbau (Bitte nicht 'text' als Standardeinstellung wählen)"

msgid "expert editing commands"
msgstr "Anzeige der erweiterten Editier-Funktionen"

msgid "name of moderator who organizes current category"
msgstr "Anzeige des Moderators für die aktuelle Kategorie"

msgid "last modified date"
msgstr "Anzeige des Datums der letzten Änderung"

msgid "attributions"
msgstr "Anzeige der Autoren"

msgid "commands for generating text output"
msgstr "Anzeige der Funktionen für das Erzeugen der Textausgabe"

msgid "<i>Optional:</i> These options fine-tune the appearance of editing features."
msgstr "<i>Optional:</i> Diese Einstellungen sind für die Feineinstellung der Texteingabe."

msgid "The old [Show Edit Commands] button appears in the navigation bar."
msgstr "Anzeige des alten Buttons [Erweiterte Editier-Funktionen] in der Navigationszeile."

msgid "Navigation links appear at top of page as well as at the bottom."
msgstr "Anzeige der Navigations-Links oben und unten auf der Seite."

msgid "Hide [Append to This Answer] and [New Answer in ...] buttons."
msgstr "Verstecke [Eintrag erweitern] und [Neuer Eintrag in...]"

msgid "icons-and-label"
msgstr "Icons und Text"

msgid "Editing commands appear with neat-o icons rather than [In Brackets]."
msgstr "Anzeige der Editier-Kommandos als Icons statt als Text in [eckigen Klammern]."

msgid "<i>Optional:</i> Other configurations that you should probably ignore if present."
msgstr "<i>Optional:</i> Andere Einstellungen, die ignoriert werden können."

msgid "Draw Item titles John Nolan's way."
msgstr "Anzeige des Titels auf John Nolan's Art"

msgid "Hide sibling (Previous, Next) links"
msgstr "Navigations-Links (Vorherige, Nächste) nicht anzeigen"

msgid "Arguments to make ci quietly log changes (default is probably fine)"
msgstr "Argumente für ci um Änderungen an der log-Datei vorzunehmen (Standard sollte passen)"

msgid "off"
msgstr "aus"

msgid "true"
msgstr "wahr"

msgid "cheesy"
msgstr "cheesy"

msgid "This is a command, so only letters, hyphens, and slashes are allowed."
msgstr "Bei diesem Kommando sind nur Buchstaben, Bindestrich (-) und Slashes (/) erlaubt."

msgid "If this is your first time installing a FAQ-O-Matic, I recommend only filling in the sections marked <b>Mandatory</b>."
msgstr "Installieren Sie zum ersten Mal FAQ-O-Matic, wird empfohlen, nur die mit <b>Nötig</b> markierten Anschnitte auszufüllen."

msgid "Define"
msgstr "Änderungen übernehmen"

msgid "(no description)"
msgstr "(kein Eintrag)"

msgid "Unrecognized config parameter"
msgstr "Unbekannter Konfigurationsparameter"

msgid "Please report this problem to"
msgstr "Bitte wenden Sie sich mit diesem Problem an"

msgid "Attempting to install cron job:"
msgstr "Versuche folgenden cron-Job zu installieren:"

msgid "Cron job installed. The maintenance script should run hourly."
msgstr "Der Cron-Job wurde installiert. Das Script wird nun stündlich aufgerufen."

msgid "I thought I installed a new cron job, but it didn't appear to take."
msgstr "Der neue cron-Job wurde installiert, wird aber nicht ausgeführt"

msgid "You better add %0 to some crontab yourself with <b><tt>crontab -e</tt></b>."
msgstr "Am besten tragen Sie die Zeile %0 selbst mit <b><tt>crontab -e</tt></b> in cron ein."

msgid "I replaced this old crontab line, which appears to be an older one for this same FAQ:"
msgstr "Der alte crontab-Eintrag für diese FAQ wurde ersetzt:"


###
### submitBag.pm
###

msgid "Bag names may only contain letters, numbers, underscores (_), hyphens (-), and periods (.), and may not end in '.desc'. Yours was"
msgstr "Objekt-Dateinamen dürfen nur Buchstaben, Nummern, Unterstriche (_), Bindestriche (-) und Punkte (.) enthalten. Die Dateiendung '.desc' ist nicht erlaubt. Ihr Dateiname war"


###
### editBag.pm
###

msgid "Upload new bag to show in the %0 part in <b>%1</b>."
msgstr "Upload eines Datei-Objekts in den %0 Textteil von <b>%1</b>"

msgid "Bag name:"
msgstr "Objekt-Name:"

msgid "The bag name is used as a filename, so it is restricted to only contain letters, numbers, underscores (_), hyphens (-), and periods (.). It should also carry a meaningful extension (such as .gif) so that web browsers will know what to do with the data."
msgstr "Der Objektname wird von FAQ-O-Matic als Dateiname benutzt (nur Buchstaben, Zahlen, Unterstriche, Bindestriche und Punkte sind erlaubt) und sollte eine sinnvolle Erweiterung haben (beispielsweise .gif), damit der Webbrowser die Datei korrekt darstellt."

msgid "Bag data:"
msgstr "Objekt-Datei:"

msgid "If this bag is an image, fill in its dimensions."
msgstr "Ist das Objekt eine Bild-Datei, geben Sie hier die Dimensionen ein."

msgid "Width:"
msgstr "Breite:"

msgid "Height:"
msgstr "Höhe:"

msgid "(Leave blank to keep original bag data and change only the associated information below.)"
msgstr "(Nicht ausfüllen, wenn nur die Zusatzinformationen des Objekts geändert werden sollen.)"


###
### appearanceForm.pm
###

msgid "Appearance Options"
msgstr "Anzeige-Einstellungen"

msgid "Show"
msgstr "Alle"

msgid "Compact"
msgstr "Kompakt"

msgid "Hide"
msgstr "Keine"

msgid "all categories and answers below current category"
msgstr "Anzeige aller Kategorien und Einträge unter der aktuellen Kategorie"

msgid "Default"
msgstr "Standard"

msgid "Simple"
msgstr "Einfaches"

msgid "Fancy"
msgstr "Erweitertes"

msgid "Accept"
msgstr "Änderungen übernehmen"


###
### addItem.pm
###

msgid "Subcategories:"
msgstr "Kategorien:"

msgid "Answers in this category:"
msgstr "Einträge in dieser Kategorie:"

msgid "Copy of"
msgstr "Kopie von"


###
### changePass.pm
###

msgid "Please enter your username, and select a password."
msgstr "Bitte geben Sie Ihren Usernamen und Ihr Passwort ein."

msgid "I will send a secret number to the email address you enter to verify that it is valid."
msgstr "Es wird ein Schlüssel zu der eingegebenen eMail-Adresse geschickt, um die Richtigkeit Ihrer Eingaben zu überprüfen."

msgid "If you prefer not to give your email address to this web form, please contact"
msgstr "Wenn Sie Ihre eMail-Adresse nicht in dieses Formular eingeben möchten, wenden Sie sich bitte an"

msgid "Please <b>do not</b> use a password you use anywhere else, as it will not be transferred or stored securely!"
msgstr "Da das Passwort unverschlüsselt übertragen und gespeichert wird, wählen Sie bitte keinesfalls ein Passwort, das Sie schon anderweitig benutzen!"

msgid "Password:"
msgstr "Passwort:"

msgid "Set Password"
msgstr "Setze Passwort"


###
### Auth.pm
###

msgid "the administrator of this Faq-O-Matic"
msgstr "vom Administrator der FAQ-O-Matic"

msgid "someone who has proven their identification"
msgstr "von Benutzern, die ihre Identifikation bewiesen haben,"

msgid "someone who has offered identification"
msgstr "von Benutzern, die ihre eMail-Adresse eingegeben haben,"

msgid "anybody"
msgstr "von allen"

msgid "the moderator of the item"
msgstr "vom Moderator des Eintrags"

msgid "%0 group members"
msgstr "von Mitgliedern der Gruppe <i>%0</i>"

msgid "I don't know who"
msgstr "von (unbekannt)"

msgid "Email:"
msgstr "eMail:"


###
### Authenticate.pm
###

msgid "That password is invalid. If you've forgotten your old password, you can"
msgstr "Das Passwort ist falsch. Wenn Sie Ihr altes Passwort vergessen haben, können Sie"

msgid "Set a New Password"
msgstr "ein neues Passwort eingeben"

msgid "Create a New Login"
msgstr "ein neues Login erstellen"

msgid "New items can only be added by %0."
msgstr "Neue Einträge können nur %0 eingefügt werden."

msgid "New text parts can only be added by %0."
msgstr "Neue Texteinträge können nur %0 eingefügt werden."

msgid "Text parts can only be removed by %0."
msgstr "Texteinträge können nur %0 verschoben werden."

msgid "This part contains raw HTML. To avoid pages with invalid HTML, the moderator has specified that only %0 can edit HTML parts. If you are %0 you may authenticate yourself with this form."
msgstr "Dieser Eintrag enthält HTML-Code. Um Seiten mit ungültigem HTML-Code zu vermeiden wurde festgelegt, daß er nur von %0 geändert werden darf. Melden Sie sich dazu mit diesem Formular an!"

msgid "Text parts can only be added by %0."
msgstr "Texteinträge können nur %0 hinzugefügt werden."

msgid "Text parts can only be edited by %0."
msgstr "Texteinträge können nur %0 geändert werden."

msgid "The title and options for this item can only be edited by %0."
msgstr "Der Titel und die Einstellungen für diesen Eintrag können nur %0 geändert werden."

msgid "The moderator options can only be edited by %0."
msgstr "Die Moderator-Einstellungen können nur %0 geändert werden."

msgid "This item can only be moved by someone who can edit both the source and destination parent items."
msgstr "Dieser Einträg kann nur vom rechtmässigem Besitzer verschoben werden."

msgid "This item can only be moved by %0."
msgstr "Dieser Eintrag kann nur %0 verschoben werden."

msgid "Existing bags can only be replaced by %0."
msgstr "Dateiobjekte dürfen nur %0 ersetzt werden."

msgid "Bags can only be posted by %0."
msgstr "Datei-Objekte dürfen nur %0 erstellt werden."

msgid "The FAQ-O-Matic can only be configured by %0."
msgstr "FAQ-O-Matic kann nur %0 konfiguriert werden."

msgid "The operation you attempted (%0) can only be done by %1."
msgstr "Die von Ihnen versuchte Operation (%0) kann nur %1 ausgeführt werden."

msgid "If you have never established a password to use with FAQ-O-Matic, you can"
msgstr "Wenn Sie noch kein Passwort zur Benutzung von FAQ-O-Matic festgelegt haben, können Sie"

msgid "If you have forgotten your password, you can"
msgstr "Wenn Sie Ihr Passwort vergessen haben, können Sie"

msgid "If you have already logged in earlier today, it may be that the token I use to identify you has expired. Please log in again."
msgstr "Wenn Sie heute schon eingeloggt waren, ist möglicherweise Ihr Zugangsschlüssel abgelaufen. Bitte loggen Sie sich erneut ein."

msgid "Please offer one of the following forms of identification:"
msgstr "Bitte wählen Sie die Art der Identifikation:"

msgid "No authentication, but my email address is:"
msgstr "Keine Authentisierung, aber meine eMail-Adresse lautet:"

msgid "Authenticated login:"
msgstr "Authentisiertes Login:"


###
### moveItem.pm
###

msgid "Make <b>%0</b> belong to which other item?"
msgstr "Zu welchem Eintrag soll <b>%0</b> verschoben werden?"

msgid "No item that already has sub-items can become the parent of"
msgstr "Der Eintrag hat Subeinträge und kann daher nicht verwendet werden als Oberbegriff von"

msgid "No item can become the parent of"
msgstr "Der Eintrag kann nicht als Oberbegriff verwendet werden von"

msgid "Some destinations are not available (not clickable) because you do not have permission to edit them as currently autorized."
msgstr "Sie haben keine Zugriffsrechte auf einige Einträge, deshalb können diese nicht angeklickt werden."

msgid "Click here</a> to provide better authentication."
msgstr "Klicken Sie hier</a>, um die Zugriffsrechte zu ändern."

msgid "Hide answers, show only categories"
msgstr "Zeige keine Einträge, nur Kategorien"

msgid "Show both categories and answers"
msgstr "Zeige Kategorien und Einträge"


###
### editPart.pm
###

msgid "Enter the answer to <b>%0</b>"
msgstr "Bearbeite Text in <b>%0</b>"

msgid "Enter a description for <b>%0</b>"
msgstr "Beschreibung eingeben für <b>%0</b>"

msgid "Edit duplicated text for <b>%0</b>"
msgstr "Bearbeite kopierten Textteil in <b>%0</b>"

msgid "Enter new text for <b>%0</b>"
msgstr "Neuen Textteil eingeben in <b>%0</b>"

msgid "Editing the %0 text part in <b>%1</b>."
msgstr "Bearbeite %0 Textteil in <b>%1</b>."

msgid "If you later need to edit or delete this text, use the [Appearance] page to turn on the expert editing commands."
msgstr "Um diesen Text später zu bearbeiten oder zu löschen, benutzen Sie [Anzeige] zur Anzeige der erweiterten Editier-Funktionen."


###
### Part.pm
###

msgid "Upload file:"
msgstr "Zu ladende Datei:"

msgid "Warning: file contents will <b>replace</b> previous text"
msgstr "Warnung: Die Datei wird den vorhandenen Text <b>ersetzen</b>"

msgid "Replace %0 with new upload"
msgstr "<i>%0</i> ersetzen"

msgid "Select bag to replace with new upload"
msgstr "Wähle ein neues Datei-Objekt"

msgid "Hide Attributions"
msgstr "Autor verbergen"

msgid "Format text as:"
msgstr "Formatiere Text als:"

msgid "Directory"
msgstr "Kategorie"

msgid "Natural text"
msgstr "Normaler Text"

msgid "Monospaced text (code, tables)"
msgstr "Text mit festen Zeichenabständen"

msgid "Untranslated HTML"
msgstr "HTML-Code"

msgid "Submit Changes"
msgstr "Änderungen abschicken"

msgid "Revert"
msgstr "Eingabe zurücksetzen"

msgid "Insert Uploaded Text Here"
msgstr "Textdatei einfügen"

msgid "Insert Text Here"
msgstr "Text einfügen"

msgid "Edit This Text"
msgstr "Text editieren"

msgid "Duplicate This Text"
msgstr "Text kopieren"

msgid "Remove This Text"
msgstr "Text löschen"

msgid "Upload New Bag Here"
msgstr "Datei-Objekt einfügen"

msgid "Category Title and Options"
msgstr "Kategorie-Titel und Optionen"

msgid "Edit Category Permissions"
msgstr "Kategorie-Zugriffsrechte ändern"

msgid "Move Category"
msgstr "Kategorie verschieben"

msgid "Trash Category"
msgstr "Kategorie löschen"


###
### searchForm.pm
###

msgid "Search for"
msgstr "Suche nach"

msgid "matching"
msgstr "passend auf"

msgid "all"
msgstr "alle"

msgid "any"
msgstr "jedes"

msgid "two"
msgstr "zwei"

msgid "three"
msgstr "drei"

msgid "four"
msgstr "vier"

msgid "five"
msgstr "fünf"

msgid "words"
msgstr "der Wörter"

msgid "Show documents"
msgstr "Zeige Dokumente"

msgid "modified in the last"
msgstr "die verändert wurden"

msgid "day"
msgstr "am letzten Tag"

msgid "two days"
msgstr "in den letzten beiden Tagen"

msgid "three days"
msgstr "in den letzten drei Tagen"

msgid "week"
msgstr "in der letzten Woche"

msgid "fortnight"
msgstr "in den letzten vierzehn Tagen"

msgid "month"
msgstr "im letzten Monat"

msgid "three months"
msgstr "in den letzten drei Monaten"

msgid "six months"
msgstr "in den letzten sechs Monaten"

msgid "year"
msgstr "im letzten Jahr"


###
### search.pm
###

msgid "No items matched all of these words"
msgstr "Kein Eintrag passte auf alle diese Wörter"

msgid "No items matched at least %0 of these words"
msgstr "Kein Eintrag passte auf mindestens %0 dieser Wörter"

msgid "Search results for at least %0 of these words"
msgstr "Such-Ergebnisse für mindestens %0 dieser Wörter"

msgid "Search results for all of these words"
msgstr "Suchergebnisse für alle diese Wörter"

msgid "Results may be incomplete, because the search index has not been refreshed since the most recent change to the database."
msgstr "Die Ergebnisse können unvollständig sein, da der Index nicht erneuert wurde seit der letzten Änderung an der Datenbasis."


###
### Item.pm
###

msgid "defined in"
msgstr "definiert in"

msgid "Name & Description"
msgstr "Name und Beschreibung"

msgid "Setting"
msgstr "Einstellung"

msgid "Setting if Inherited"
msgstr "Vererbter Wert"

msgid "Group %0"
msgstr "Gruppe %0"

msgid "Moderator"
msgstr "Moderator"

msgid "nobody"
msgstr "niemand"

msgid "(system default)"
msgstr "(Systemvorgabe)"

msgid "(inherited from parent)"
msgstr "(vererbt von übergeordnetem Eintrag)"

msgid "(will inherit if empty)"
msgstr "(vererbter Wert wenn leer)"

msgid "Send mail to the moderator when someone other than the moderator edits this item:"
msgstr "Schicke dem Moderator eine Mail, wenn jemand anders diesen Eintrag ändert:"

msgid "Permissions"
msgstr "Zugriffsrechte"

msgid "Blah blah"
msgstr "Bla bla"

msgid "Yes"
msgstr "Ja"

msgid "No"
msgstr "Nein"

msgid "Relax"
msgstr "Lockerer"

msgid "Don't Relax"
msgstr "Nicht lockerer"

msgid "undefined"
msgstr "Nicht definiert"

msgid "<p>New Order for Text Parts:"
msgstr "<p>Neue Reihenfolge für Textabschnitte:"

msgid "Who can access the installation/configuration page (use caution!):"
msgstr "Wer darf auf die Installations-/Konfigurationsseiten zugreifen (Vorsicht !):"

msgid "Who can add a new text part to this item:"
msgstr "Wer darf neuen Text zu diesem Eintrag hinzufügen:"

msgid "Who can add a new answer or category to this category:"
msgstr "Wer darf neue Einträge oder Unterkategorien in diese Katagorie einfügen:"

msgid "Who can edit or remove existing text parts from this item:"
msgstr "Wer darf in diesem Eintrag vorhandenen Text editieren bzw. löschen:"

msgid "Who can move answers or subcategories from this category; or turn this category into an answer or vice versa:"
msgstr "Wer darf Einträge oder Unterkategorien dieser Kategorie verschieben bzw. diese Kategorie in einen Eintrag und umgekehrt umwandeln:"

msgid "Who can edit the title and options of this answer or category:"
msgstr "Wer darf den Titel und die Einstellungen dieses Eintrags bzw. dieser Kategorie ändern:"

msgid "Who can use untranslated HTML when editing the text of this answer or category:"
msgstr "Wer darf HTML-Code beim Editieren dieser Eintrags bzw. dieser Kategorie benutzen:"

msgid "Who can change these moderator options and permissions:"
msgstr "Wer darf diese Moderator-Einstellungen und Zugriffsrechte ändern:"

msgid "Who can use the group membership pages:"
msgstr "Wer darf die Gruppenmitgliedschafts-Seiten benutzen:"

msgid "Who can create new bags:"
msgstr "Wer darf neue Datei-Objekte einfügen:"

msgid "Who can replace existing bags:"
msgstr "Wer darf vorhandene Datei-Objekte ersetzen:"

msgid "Group"
msgstr "Gruppe"

msgid "Authenticated users"
msgstr "Authentisierte Benutzer"

msgid "Users giving their names"
msgstr "Namentlich bekannte Benutzer"

msgid "Inherit"
msgstr "Erben von Elternobjekt"

msgid "File %0 seems broken."
msgstr "Datei %0 scheint defekt zu sein."

msgid "Permissions:"
msgstr "Zugriffsrechte:"

msgid "Moderator options for"
msgstr "Moderator-Einstellungen für"

msgid "Title:"
msgstr "Titel:"

msgid "Category"
msgstr "Kategorie"

msgid "Answer"
msgstr "Eintrag"

msgid "Show attributions from all parts together at bottom"
msgstr "Anzeige der Autoren aller Einträge am unteren Rand"

msgid "New Item"
msgstr "Neuer Eintrag"

msgid "Convert to Answer"
msgstr "In Eintrag umwandeln"

msgid "Convert to Category"
msgstr "In Kategorie umwandeln"

msgid "New Subcategory of "%0""
msgstr "Neue Kategorie in <i>%0</i>"

msgid "Parts"
msgstr "Einträge"

msgid "New Category"
msgstr "Neue Kategorie"

msgid "New Answer"
msgstr "Neuer Eintrag"

msgid "Editing Answer <b>%0</b>"
msgstr "Eintrag <b>%0</b> ändern"

msgid "New Answer in "%0""
msgstr "Neuer Eintrag in <i>%0</i>"

msgid "Duplicate Category as Answer"
msgstr "Kategorie kopieren"

msgid "Duplicate Answer"
msgstr "Eintrag kopieren"

msgid "Move Answer"
msgstr "Eintrag verschieben"

msgid "Trash Answer"
msgstr "Eintrag löschen"

msgid "Answer Title and Options"
msgstr "Titel und Optionen ändern"

msgid "Edit Answer Permissions"
msgstr "Eintrags-Rechte ändern"

msgid "Append to This Answer"
msgstr "Eintrag erweitern"

msgid "This document is:"
msgstr "Dieses Dokument ist erreichbar via:"

msgid "This document is at:"
msgstr "Dieses Dokument hat die URL:"

msgid "Previous"
msgstr "Vorhergehende"

msgid "Next"
msgstr "Nächste"

msgid "Editing Category <b>%0</b>"
msgstr "Ändere Kategorie <b>%0</b>"

msgid "Moderator options for answer"
msgstr "Moderator-Optionen für Eintrag"

msgid "Relax: New answers and subcategories will be moderated by the creator of the item, allowing that person full freedom to edit that new item."
msgstr "Lockerer: Neue Einträge und Kategorien werden durch die Ersteller moderiert."

msgid "Don't Relax: new items will be moderated by the moderator of this item."
msgstr "Nicht lockerer: Neue Einträge und Kategorien werden durch den Moderator dieses Eintrags moderiert."


###
### Appearance.pm
###

msgid "Search"
msgstr "Suchen"

msgid "Appearance"
msgstr "Anzeige"

msgid "Show Top Category Only"
msgstr "Zeige nur die oberste Kategorie"

msgid "Show This <em>Entire</em> Category"
msgstr "Zeige <em>gesamte</em> Kategorie"

msgid "Show This %0 As Text"
msgstr "%0 als Text anzeigen"

msgid "Show This Category As Text"
msgstr "Zeige diese Kategorie als Text"

msgid "Show This Answer As Text"
msgstr "Zeige diesen Eintrag als Text"

msgid "Show This <em>Entire</em> Category As Text"
msgstr "Zeige <em>gesamte</em> Kategorie als Text"

msgid "Hide Expert Edit Commands"
msgstr "Basis-Editier-Funktionen"

msgid "Show Expert Edit Commands"
msgstr "Erweiterte Editier-Funktionen"

msgid "This is a"
msgstr "Dies ist eine"

msgid "Hide Help"
msgstr "Hilfe verstecken"

msgid "Help"
msgstr "Hilfe"

msgid "Log In"
msgstr "Einloggen"

msgid "Change Password"
msgstr "Ändere Passwort"

msgid "Edit Title of %0 %1"
msgstr "Bearbeite Titel von %0 %1"

msgid "New %0"
msgstr "Neue %0"

msgid "Edit Part in %0 %1"
msgstr "Bearbeite Abschnitt in %0 %1"

msgid "Insert Part in %0 %1"
msgstr "Einfügen eines Textteils in %0 %1"

msgid "Move %0 %1"
msgstr "Verschiebe %0 %1"

msgid "Access Statistics"
msgstr "Zugriffs-Statistik"

msgid "%0 Permissions for %1"
msgstr "%0 Zugriffsrechte für %1"

msgid "Upload bag for %0 %1"
msgstr "Upload eines Datei-Objekts für %0 %1"


###
### Slow.pm
###

msgid "Either someone has changed the answer or category you were editing since you received the editing form, or you submitted the same form twice."
msgstr "Entweder hat jemand anderer den Eintrag oder die Kategorie geändert seit Sie sie bearbeiten, oder Sie haben das Formular mehrfach abgeschickt."

msgid "Return to the FAQ"
msgstr "Zurück zur Faq-O-Matic"

msgid "Please %0 and start again to make sure no changes are lost. Sorry for the inconvenience."
msgstr "Bitte gehen Sie %0 und starten Sie neu, um keine Änderungen zu verlieren. Sorry für die Umstände."

msgid "(Sequence number in form: %0; in item: %1)"
msgstr "(Versionsnummer im Formular: %0; im Eintrag: %1)"

msgid "This page will reload every %0 seconds, showing the last %1 lines of the process output."
msgstr "Diese Seite lädt alle %0 Sekunden neu und zeigt die letzten %1 Zeilen des Prozess-Log."

msgid "Show the entire process log"
msgstr "Anzeige des gesamten Prozess-Log"

msgid "Select a group to edit:"
msgstr "Wählen Sie eine Gruppe zur Bearbeitung:"

msgid "Add Group"
msgstr "Neue Gruppe"

msgid "(Members of this group are allowed to access these group definition pages.)"
msgstr "(Mitglieder dieser Gruppe haben Zugriff auf die Gruppenmitgliedschafts-Seiten.)"

msgid "Up To List Of Groups"
msgstr "Zurück zur Gruppen-Liste"

msgid "Add Member"
msgstr "Neues Mitglied"

msgid "Remove Member"
msgstr "Mitglied löschen"

msgid "search for keywords"
msgstr "Suche nach Begriffen"

msgid "search for recent changes"
msgstr "Suche nach kürzlichen Änderungen" 


###
### END
###

);
__EOF__

	my @txs = grep { m/^msg/ } split(/\n/, $txfile);
	for (my $i=0; $i<@txs; $i+=2) {
		$txs[$i] =~ m/msgid \"(.*)\"$/s;
		my $from = $1;
		$txs[$i+1] =~ m/msgstr \"(.*)\"$/s;
		my $to = $1;
		if (not defined $from or not defined $to) {
			die "bad translation at pair $i";
		}
		$tx->{$from} = $to;
	}
};

