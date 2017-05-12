### Fr : Translation Basile Chandesris - base@citeweb.net
###
### Status : Runs but Not finished (version 3)
#########################################################
### Perl warning : Subroutine translation redefined at  
### ..../OMatic/Language_de...pm line 5 [now: line 17]
### ???
#########################################################
### Perl warning : Use of unitilized value at
### .../OMatic/Item.pm line 939
###

###
### submitItem.pm
###

sub translations {
	my $tx = shift;
	my $txfile = <<'__EOF__';
### 
### submitItem.pm
###

msgid "The file (%0) doesn't exist."
msgstr "Le fichier (%0) n'existe pas."

msgid "To name your FAQ-O-Matic, use the [Appearance] page to show the expert editing commands, then click [Edit Category Title and Options]."
msgstr "Pour donner un nom a votre FAQ-O-Matic, utilisez la page [Apparence] à montrer des commandes d'édition experte, puis cliquez [Edit Category Title and Options]."

msgid "Your browser or WWW cache has truncated your POST."
msgtr "Votre navigateur ou cache web a tronqué votre envoi."
 
msgid "Changed the item title, was "%0""
msgstr "Le titre de l'élément a changé, il a eté: <i>%0</i>."

msgid "Your part order list (%0) "
msgstr "Votre liste de sections (%0) "

msgid "doesn't have the same number of parts (%0) as the original item."
msgstr "n'a pas le même nombre de sections (%0) que l'élément d'origine."

msgid "doesn't say what to do with part %0."
msgstr "ne décrit pas l'action à réaliser sur la section %0."

###
### submitMove.pm
###

msgid "The moving file (%0) is broken or missing."
msgstr "Le fichier à déplacer (%0) est défecteux ou manquant."

msgid "The newParent file (%0) is broken or missing."
msgstr "Le nouveau fichier parent (%0) est défecteux ou manquant."

msgid "The oldParent file (%0) is broken or missing."
msgstr "L'ancien fichier parent (%0) est défecteux ou manquant."

msgid "The new parent (%0) is the same as the old parent."
msgstr "Le nouveau fichier parent (%0) est le même que l'ancien fichier parent."

msgid "The new parent (%0) is the same as the item you want to move."
msgstr "Le nouveau fichier parent (%0) est le même élément que vous souhaitez déplacer."

msgid "The new parent (%0) is a child of the item being moved (%1)."
msgstr "Le nouveau fichier parent (%0) est un fils de l'élément (%1) que vous a été déplacé."

msgid "You can't move the top item."
msgstr "Vous ne pouvez pas déplacer l'entrée au sommet de la hiérarchie."

msgid "moved a sub-item to %0"
msgstr "a déplacé un sous-entrée vers %0"

msgid "moved a sub-item from %0"
msgstr "a déplacé un sous-entré de %0"

###
### submitPass.pm
###

msgid "An email address must look like 'name@some.domain'."
msgstr "L'adresse mèl doit avoir la forme 'nome@quelque.domain'."

msgid "If yours (%0) does and I keep rejecting it, please mail %1 and tell him what's happening."
msgstr "Si votre adresse mèl (%0) sonne et n'est pas accepté, envoyez svp un mél à %1 en décrivant l'incident."

msgid "Your password may not contain spaces or carriage returns."
msgstr "Votre mot de passe ne doit contenir aucun caractère vide (esp, rtn)."

msgid "Your Faq-O-Matic authentication secret"
msgstr "Votre clé d'accès Faq-O-Matic"

msgid "I couldn't mail the authentication secret to "%0" and I'm not sure why."
msgstr "Je ne peux pas vous envoyer la clé d'accès à <i>%0</i> et je ne sais pas pourquoi."

msgid "The secret you entered is not correct."
msgstr "La clé d'accès donnée n'est pas correcte."

msgid "Did you copy and paste the secret or the URL completely?"
msgstr "Avez vous copié la clé d'accès ou complÈtement collé l'URL ?"

msgid "I sent email to you at "%0". It should arrive soon, containing a URL."
msgstr "Un mèl vous est envoyé à <i>%0</i>. Le mèl devrait être arrivé dans votre boîte aux lettre."

msgid "Either open the URL directly, or paste the secret into the form below and click Validate."
msgstr "Il contient un URL et une clé d'accès. Soit vous activez l'URL, soit vous utilisez la clé d'accès dans le formulaire ci-dessous et cliquez sur valider."

msgid "Thank you for taking the time to sign up."
msgstr "Merci beaucoup de prendre du temps pour s'inscrire."

msgid "Secret:"
msgstr "Clé d'accès : "

msgid "Validate"
msgstr "Valider"

###
### editBag.pm
###

msgid "Replace bag"
msgstr "Remplacer le fichier objet"

msgid "Replace which bag?"
msgstr "Remplacer quel fichier objet?"

###
### OMatic.pm
###

msgid "Warnings:"
msgstr "Alertes:"

###
### install.pm
###

msgid "Untitled Faq-O-Matic"
msgstr "Faq-O-Matic sans nom"

msgid "Faq-O-Matic Installer"
msgstr "Installation de Faq-O-Matic"

msgid "%0 failed: "
msgstr "%0 est échoué: "

msgid "Unknown step: "%0"."
msgstr "Pas inconnu: "%0"."

msgid "Updating config to reflect new meta location <b>%0</b>."
msgstr "La configuration sera actualisé pour une nouvelle meta localisation <b>%0</b>."

msgid "(Can't find <b>config</b> in '%0' -- assuming this is a new installation.)"
msgstr "(Ne trouve pas la <b>config</b> dans '%0' -- il s'agit vraissemblablement d'une nouvelle installation)."

msgid "Click here</a> to create %0."
msgstr "Cliquez ici</a> pour créer %0."

msgid "If you want to change the CGI stub to point to another directory, edit the script and then"
msgstr "Si vous souhaitez transformer le CGI d'une section pour qu'il pointe vers un autre répertoire, éditez le script et ensuite"

msgid "click here to use the new location"
msgstr "Cliquez ici, pour utiliser la nouvelle localisation"

msgid "FAQ-O-Matic stores files in two main directories.<p>The <b>meta/</b> directory path is encoded in your CGI stub ($0). It contains:"
msgstr "FAQ-O-Matic enregistre les fichiers dans deux répertoires principaux.<p>Le répertoire <b>meta/</b> est enregistré dans votre CGI ($0). Il contient : "

msgid "<ul><li>the <b>config</b> file that tells FAQ-O-Matic where everything else lives. That's why the CGI stub needs to know where meta/ is, so it can figure out the rest of its configuration. <li>the <b>idfile</b> file that lists user identities. Therefore, meta/ should not be accessible via the web server. <li>the <b>RCS/</b> subdirectory that tracks revisions to FAQ items. <li>various hint files that are used as FAQ-O-Matic runs. These can be regenerated automatically.</ul>"
msgstr "<ul><li>Le fichier <b>config</b>, décrit où tous les éléments de la FAQ-O-Matic sont. C'est pourquoi le CGI a besoin de connaître où le répertoire meta/ doit être trouvé. <li>Le fichier <b>idfile</b> contient la liste des identités des utilisateurs. Cependant, meta/ ne doit pas être accessible au travers du serveur Web. <li>Le sous-répertoire <b>RCS/</b>, suit les mises à jours de la FAQ. <li>différents fichiers cachés sont utilisés lorsque la FAQ-O-Matic tourne. Ils peuvent être recréés automatiquement.</ul>"

msgid "<p>The <b>serve/</b> directory contains three subdirectories <b>item/</b>, <b>cache/</b>, and <b>bags/</b>. These directories are created and populated by the FAQ-O-Matic CGI, but should be directly accessible via the web server (without invoking the CGI)."
msgstr "<p>Le répertoire <b>serve/</b> contient trois sous répertoires : <b>item/</b>, <b>cache/</b> et <b>bags/</b>. Ces répertoires sont crées et contiennent les CGI de la FAQ-O-Matic, mais ils doivent être accessible du serveur web (sans appeller de CGI)."

msgid "<ul><li>serve/item/ contains only FAQ-O-Matic formatted source files, which encode both user-entered text and the hierarchical structure of the answers and categories in the FAQ. These files are only accessed through the web server (rather than the CGI) when another FAQ-O-Matic is mirroring this one. <li>serve/cache/ contains a cache of automatically-generated HTML versions of FAQ answers and categories. When possible, the CGI directs users to the cache to reduce load on the server. (CGI hits are far more expensive than regular file loads.) <li>serve/bags/ contains image files and other ``bags of bits.'' Bit-bags can be linked to or inlined into FAQ items (in the case of images). </ul>"
msgstr "<ul><li>serve/item/ contient les fichiers sources formatés de la FAQ-O-Matic, qui codent à la fois les entrées des utilisateurs et les structures hiérarchiques des réponses et des catégories dans la FAQ. Ces fichiers ne sont accèdés qu'au travers du serveur web (plutôt que par CGI) lorsqu'une autre FAQ-O-Matic joue le rôle de miroir. <li>serve/cache/ contient un cache des réponses et catégories de la FAQ, automatiquement généré en HTML afin de réduire la charge sur le serveur. (Les requêtes sur CGI sont beaucoup plus chères en ressources que le déchargement de fichiers) <li>serve/bags/ contient les images de fichiers et autres fichiers-objets. Les fichiers-objets peuvent être liés À ou insérés dans les éléments de la FAQ (dans le cas des images).</ul>"

msgid "I don't have write permission to <b>%0</b>."
msgstr "Je n'ai pas la permission d'écriture pour <b>%0</b>."

msgid "I couldn't create <b>%0</b>: %1"
msgstr "Erreur à la création de <b>%0</b>: %1"

msgid "<b>%0</b> already contains a file '%1'."
msgstr "%0 déjà contient un fichier <b>%1</b>"

msgid "Created <b>%0</b>."
msgstr "Crée <b>%0</b>."

msgid "Created new config file."
msgstr "Création d'un nouveau fichier de configuration."

msgid "The idfile exists."
msgstr "Le fichier idfile existe."

msgid "Configuration Main Menu (install module)"
msgstr "Menu de configuration principal (installation du module)"

msgid "Go To Install/Configuration Page"
msgstr "Retour au menu de configuration pincipal"

msgid "Perform these tasks in order to prepare your FAQ-O-Matic version %0:"
msgstr "Réalisez ces tâches afin de préparer votre FAQ-O-Matic version %0:"

msgid "Define configuration parameters"
msgstr "Définissez les paramètres de configuration"

msgid "Set your password and turn on installer security"
msgstr "Mettez en place votre mot de passe et mettez en route la sécurité de l'installation"

msgid "(Need to configure $mailCommand and $adminAuth)"
msgstr "($mailCommand et $adminAuth doivent être configuré)"

msgid "(Installer security is on)"
msgstr "(La sécurité de l'installation est activée)"

msgid "Create item, cache, and bags directories in serve dir"
msgstr "Créez des éléments, des caches et des répertoires de fichiers objets"

msgid "Copy old items</a> from <tt>%0</tt> to <tt>%1</tt>."
msgstr "Copiez les anciens éléments</a> de <tt>%0</tt> vers <tt>%1</tt>."

msgid "Install any new items that come with the system"
msgstr "Installez les nouveaux éléments du système"

msgid "Create system default items"
msgstr "Créez les éléments par défaut du système"

msgid "Created category "%0"."
msgstr "Crée categorie <b>%0</b>."

msgid "Rebuild the cache and dependency files"
msgstr "Reconstruisez le cache et les fichiers de dépendance"

msgid "Install system images and icons"
msgstr "Installez les images et les icônes du système"

msgid "Update mirror from master now. (this can be slow!)"
msgstr "Mettre à jour les fichiers du miroir (cela peut durer longtemps !)"

msgid "Set up the maintenance cron job"
msgstr "Mettez en route le service de maintenance."

msgid "Run maintenance script manually now"
msgstr "Mettez en route la maintenance manuellement"

msgid "(Need to set up the maintenance cron job first)"
msgstr "(Besoin de mettre en route tout d'abord le service de maintenance)"

msgid "Maintenance last run at:"
msgstr "Dernière mise en route du service de maintenance:"

msgid "Mark the config file as upgraded to Version %0"
msgstr "Marquez le fichier de configuration à la nouvelle mise à jour de la version %0"

msgid "Select custom colors for your Faq-O-Matic</a> (optional)"
msgstr "Personnalisez les couleurs de votre Faq-O-Matic</a> (optionnel)"

msgid "Define groups</a> (optional)"
msgstr "Définissez des groupes</a> (optionnel)"

msgid "Upgrade to CGI.pm version 2.49 or newer."
msgstr "Mettre à jour À CGI.pm version 2.49 ou plus nouvelle."

msgid "(optional; older versions have bugs that affect bags)"
msgstr "(optionnel; les anciennes versions ont des bogues qui affectent les fichiers objets)"

msgid "You are using version %0 now."
msgstr "Actuellement vous utilisez la version %0."

msgid "Bookmark this link to be able to return to this menu."
msgstr "Créez un signet pour pouvoir retrouver ce menu."

msgid "Go to the Faq-O-Matic"
msgstr "Allez à la Faq-O-Matic"

msgid "(need to turn on installer security)"
msgstr "(il faut réactiver l'installation de sécurité)"

msgid "Other available tasks:"
msgstr "Autres tâches disponibles:"

msgid "See access statistics"
msgstr "Visualiser les statistiques d'accès"

msgid "Examine all bags"
msgstr "Examiner tous les fichiers objets"

msgid "Check for unreferenced bags (not linked by any FAQ item)"
msgstr "Vérification des fichiers objets non référencés (qui ne sont liés à aucun élément de FAQ)"

msgid "Rebuild the cache and dependency files"
msgstr "Reconstruire le cache et les fichiers de dépendance"

msgid "The Faq-O-Matic modules are version %0."
msgstr "Les modules Faq-O-Matic sont de version %0."

msgid "I wasn't able to change the permissions on <b>%0</b> to 755 (readable/searchable by all)."
msgstr "Je ne peux pas modifier les permissions de <b>%0</b> vers 755 (à lire/À rechercher par tous)."

msgid "Rewrote configuration file."
msgstr "Le fichier de configuration a été re-écrit."

msgid "%0 (%1) has an internal apostrophe, which will certainly make Perl choke on the config file."
msgstr "%0 (%1) contient un apostrophe à'intérieur, qui fail Perl échouer en lisant le fichier de configuration."

msgid "%0 (%1) doesn't look like a fully-qualified email address."
msgstr "%0 (%1) n'a pas l'air d'une adresse mèl."

msgid "%0 (%1) isn't executable."
msgstr "%0 (%1) n'est pas exécutable."

msgid "%0 has funny characters."
msgstr "%0 contient des charactères drôles."

msgid "You should <a href="%0">go back</a> and fix these configurations."
msgstr "<a href="%0">Retournez</a> et correctez ces configurations."

msgid "updated config file:"
msgstr "Mise à jour le ficier de configuration:"

msgid "Redefine configuration parameters to ensure that <b>%0</b> is valid."
msgstr "Redéfinir les paramètres de configuration pour assurer que <b>%0</b> est valide."

msgid "Jon made a mistake here; key=%0, property=%1."
msgstr "Jon a fait une erreur ici; key=%0, property=%1."

msgid "<b>Mandatory:</b> System information"
msgstr "<b>Obligatoire: </b> Informations du système"

msgid "Identity of local FAQ-O-Matic administrator (an email address)"
msgstr "Identité de l'administrateur de la FAQ-O-Matic (adresse mèl)"

msgid "A command FAQ-O-Matic can use to send mail. It must either be sendmail, or it must understand the -s (Subject) switch."
msgstr "Une commande que FAQ-O-Matic peut utiliser pour envoyer du mèl. Il doit être sendmail ou soutenir l'option -s (Sujet)."

msgid "The command FAQ-O-Matic can use to install a cron job."
msgstr "La commande que FAQ-O-Matic peut iutiliser pour installer un cron job."

msgid "Path to the <b>ci</b> command from the RCS package."
msgstr "La commande <b>ci</b> du paquet RCS."

msgid "<b>Mandatory:</b> Server directory configuration"
msgstr "<b>Obligatoire:</b> Configuration du répertoire du serveur"

msgid "Protocol, host, and port parts of the URL to your site. This will be used to construct link URLs. Omit the trailing '/'; for example: <tt>http://www.dartmouth.edu</tt>"
msgstr "Protocol, ordinateur et port de l'URL de votre site. Cela est utilitsé pour construire des liens URL. Ommettez le '/' a la fin. Exemple: <tt>http://www.dartmouth.edu</tt>"

msgid "The path part of the URL used to access this CGI script, beginning with '/' and omitting any parameters after the '?'. For example: <tt>/cgi-bin/cgiwrap/jonh/faq.pl</tt>"
msgstr "Le part des répertoires de l'URL pour atteindre à votre script CGI, commençant avec '/', mais sans '?' et des arguments derrières. Exemple: <tt>/cgi-bin/cgiwrap/jonh/faq.pl</tt>"

msgid "Filesystem directory where FAQ-O-Matic will keep item files, image and other bit-bag files, and a cache of generated HTML files. This directory must be accessible directly via the http server. It might be something like /home/faqomatic/public_html/fom-serve/"
msgstr "Répertoire du fichier système dans lequel FAQ-O-Matic garde les éléments, images et fichiers objets, ainsi que le cache des fichiers HTML générés. Ce répertoire doit être accessible par le serveur http. Cela peut être quelque chose comme : /home/faqomatic/public_html/fom-serve/"

msgid "The path prefix of the URL needed to access files in <b>$serveDir</b>. It should be relative to the root of the server (omit http://hostname:port, but include a leading '/'). It should also end with a '/'."
msgstr "Le préfixe de l'URL necessaire pour accéder des fichiers dans <b>$serveDir</b>. Il doit être relatif a la racine principale du serveur (sans http://hostname:port, mais avec '/' au début et a la fin)."

msgid "Use the <u>%0</u> links to change the color of a feature."
msgstr "Utilisez les liens <u>%0</u> pour modifier la couleur d'un objet."

msgid "An Item Title"
msgstr "Un titre d'élément"

msgid "A regular part is how most of your content will appear. The text colors should be most pleasantly readable on this background."
msgstr "Cette partie présente comment le contenu apparaîtra. Les couleurs du texte doivent être agréables à lire sur ce fond."

msgid "A new link"
msgstr "Un nouveau lien"

msgid "A visited link"
msgstr "Un lien visité"

msgid "A search hit"
msgstr "Un résultat de recherche"

msgid "A directory part should stand out"
msgstr "Une section de répertoire doit apparaître"

msgid "Regular text"
msgstr "Texte normal"

msgid "Proceed to step '%0'"
msgstr "Continuer en faisant: %0"

msgid "Select a color for %0:"
msgstr "Sélectionnez la couleur pour %0:"

msgid "Or enter an HTML color specification manually:"
msgstr "Ou entrez une couleur en code HTML:"

msgid "Select"
msgstr "OK"

msgid "<i>Optional:</i> Miscellaneous configurations"
msgstr "<i>Optionnel:</i> Configurations diverses"

msgid "Select the display language."
msgstr "Selectionnez la langue utilisée."

msgid "Show dates in 24-hour time or am/pm format."
msgstr "Montrer les dates dans le format 24 heures ou dans le format am/pm."

msgid "If this parameter is set, this FAQ will become a mirror of the one at the given URL. The URL should be the base name of the CGI script of the master FAQ-O-Matic."
msgstr "Si ce paramètre est mis, cette FAQ deviendra un miroir d'une à l'URL donné. Cet URL doit pointer vers le script CGI de la FAQ-O-Matic."

msgid "An HTML fragment inserted at the top of each page. You might use this to place a corporate logo."
msgstr "Un fragment d'HTML inséré en haut de chaque page. Profitez en pour utiliser cet emplacement pour afficher votre logo."

msgid "If this field begins with <tt>file=</tt>, the text will come from the named file in the meta directory; otherwise, this field is included verbatim."
msgstr "Si ce paramètre commence avec <tt>file=</tt>, le texte est lit du fichier nommé dans le repértoire meta; en d'autres temps, le texte es pris verbatim."

msgid "The <tt>width=</tt> tag in a table. If your <b>$pageHeader</b> has <tt>align=left</tt>, you will want to make this empty."
msgstr "Le <tt>width=</tt> tag dans un tableau. Si votre <b>$pageHeader</b> contient <tt>align=left</tt>, ce champs doit être vide."

msgid "An HTML fragment appended to the bottom of each page. You might use this to identify the webmaster for this site."
msgstr "Un fragment d'HTML inséré en bas de chaque page. Vous pouvez utilisez celui-ci pour présenter le webmestre du site."

msgid "Where FAQ-O-Matic should send email when it wants to alert the administrator (usually same as $adminAuth)"
msgstr "Où FAQ-O-Matic doit envoyer un mèl lorque l'on souhaite contacter l'administrateur (habituellement le mêeme q'$adminAuth)"

msgid "If true, FAQ-O-Matic will mail the log file to the administrator whenever it is truncated."
msgstr "Si mis, FAQ-O-Matic envoie le fichier log par mèl à l'administrateur."

msgid "User to use for RCS ci command (default is process UID)"
msgstr "Utilisateur qui exécute la commande ci (par défaut l'UID du process)"

msgid "Links from cache to CGI are relative to the server root, rather than absolute URLs including hostname:"
msgstr "Des liens du cache vers le CGI sont relatif à la racine principale du serveur, au lieu d'être des URLs absolues utilisant le nom de la machine (hostname):"

msgid "mailto: links can be rewritten such as jonhATdartmouthDOTedu (cheesy), jonh (nameonly), or e-mail addresses suppressed entirely (hide)."
msgstr "Des liens <i>mailto:</i> peuvent être réécris comme par exemple jonhATdartmouthDOTedu (cheesy), jonh (nameonly), ou des adresses de mèl supprimées completement (hide)."

msgid "Number of seconds that authentication cookies remain valid. These cookies are stored in URLs, and so can be retrieved from a browser history file. Hence they should usually time-out fairly quickly."
msgstr "Nombre de secondes pour laquelle l'authentification par cookie reste valide. Les cookies sont stockés en fonction des URLs, et ainsi ils peuvent étre déchargés par le biais du fichier historique du navigateur. Ils doivent donc être rapidement désactivés (leur time-out doit être court)."

msgid "<i>Optional:</i> These options set the default [Appearance] modes."
msgstr "<i>Optionnel:</i> Ces options définissent le mode [Apparence] par défaut."

msgid "Page rendering scheme. Do not choose 'text' as the default."
msgstr "Schéma de la représentation d'une page. Svp ne choisissez pas 'text' comme pour le modèle par défaut."

msgid "expert editing commands"
msgstr"Commandes d'édition expert"

msgid "name of moderator who organizes current category"
msgstr "Nom du modérateur qui organise la catégorie courante"

msgid "last modified date"
msgstr "Dernière date de modification"

msgid "attributions"
msgstr "Montrer les auteurs"

msgid "commands for generating text output"
msgstr "commandes pour créer le texte en sortie"

msgid "<i>Optional:</i> These options fine-tune the appearance of editing features."
msgstr "<i>Optionnel:</i> Ces options définissent l'apparence des outils d'édition."

msgid "The old [Show Edit Commands] button appears in the navigation bar."
msgstr "L'ancien bouton [Montrer les commandes d'édition] apparaîtra dans la barre de navigation."
 
msgid "Navigation links appear at top of page as well as at the bottom."
msgstr "Les liens de navigation apparaîtront en haut et en bas de la page."

msgid "Hide [Append to This Answer] and [New Answer in ...] buttons."
msgstr "Cacher les boutons [Contribuer à cette Entrée] et [Nouvelle Entrée dans ...]."

msgid "icons-and-label"
msgstr "Icônes et titres"

msgid "Editing commands appear with neat-o icons rather than [In Brackets]."
msgstr "Les commandes d'édition apparaîtrons comme des icônes et non dans des [crochets]."
 
msgid "<i>Optional:</i> Other configurations that you should probably ignore if present."
msgstr "<i>Optionnel:</i> D'autres options de configuration que vous devriez ignorer à présent."

msgid "Draw Item titles John Nolan's way."
msgstr "Dessiner les titres au style de John Nolan."

msgid "Hide sibling (Previous, Next) links"
msgstr "Cacher les liens de navigation (Précédent, Suivant)"

msgid "Arguments to make ci quietly log changes (default is probably fine)"
msgstr "Arguments pour réliser avec ci les modifications de log (le choix par défaut est le mieux)"

msgid "off"
msgstr "désactivié"

msgid "true"
msgstr "activé"

msgid "cheesy"
msgstr "chessy"

msgid "This is a command, so only letters, hyphens, and slashes are allowed."
msgstr "Il s'agit d'une commande, ainsi seul les lettres, moins (-) et slash (/) sont autorisé."

msgid "If this is your first time installing a FAQ-O-Matic, I recommend only filling in the sections marked <b>Mandatory</b>."
msgstr "Si il s'agit de votre première installation de la FAQ-O-Matic, je vous recommande de ne remplir que les sections marquées <b>important</b>."

msgid "Define"
msgstr "Définir"

msgid "(no description)"
msgstr "(aucune description)"

msgid "Unrecognized config parameter"
msgstr "Paramétre de configuration inconnu"

msgid "Please report this problem to"
msgstr "S'il vous plaît faites un rapport de votre problème à"

msgid "Attempting to install cron job:"
msgstr "Essayant d' installer le cron job:"

msgid "Cron job installed. The maintenance script should run hourly."
msgstr "Le cron job est installé. La maintenance s'effectue automatiquement toutes les heures."

msgid "I thought I installed a new cron job, but it didn't appear to take."
msgstr "Le nouveau cron job sera installé, mais ne sera pas apparaît prendre."

msgid "You better add %0 to some crontab yourself with <b><tt>crontab -e</tt></b>."
msgstr "Vous devriez ajouter %0 pour une crontab avec <b><tt>crontab -e</tt></b>."

msgid "I replaced this old crontab line, which appears to be an older one for this same FAQ:"
msgstr "J'ai remplacé cette ancienne ligne de crontab, qui apparait comme une ancienne ligne pour cette même FAQ : "


###
### submitBag.pm
###

msgid "Bag names may only contain letters, numbers, underscores (_), hyphens (-), and periods (.), and may not end in '.desc'. Yours was"
msgstr "Un fichier objet ne doit contenir que des lettres, des nombres, des underscores (_), des moins (-), et des points (.), et ne doit pas se terminer par '.desc'. Le votre était"


###
### editBag.pm
###

msgid "Upload new bag to show in the %0 part in <b>%1</b>."
msgstr "Charger un nouveau fichier objet dans la %0 partie dans <b>%1</b>"

msgid "Bag name:"
msgstr "Nom de l'objet"

msgid "The bag name is used as a filename, so it is restricted to only contain letters, numbers, underscores (_), hyphens (-), and periods (.). It should also carry a meaningful extension (such as .gif) so that web browsers will know what to do with the data."
msgstr "Le nom de l'objet est utilisé comme un nom de fichier, ainsi il ne doit contenir que des lettres, des nombres, des underscores (_), des moins (-), et des points (.). Il faut aussi utiliser avec attention les extensions (comme .gif) pour que les navigateurs web puissent savoir que faire des données."

msgid "Bag data:"
msgstr "Objet donné : "

msgid "If this bag is an image, fill in its dimensions."
msgstr "Si un objet est une image, remplissez ses dimensions."

msgid "Width:"
msgstr "Largeur:"

msgid "Height:"
msgstr "Hauteur:"

msgid "(Leave blank to keep original bag data and change only the associated information below.)"
msgstr "(Laissez en blanc pour garder le fichier objet original et ne modifié que l'information ci-dessous)."


###
### appearanceForm.pm
###

msgid "Appearance Options"
msgstr "Options d'apparence"

msgid "Show"
msgstr "Montrer"

msgid "Compact"
msgstr "Compact"

msgid "Hide"
msgstr "Cacher"

msgid "all categories and answers below current category"
msgstr "toutes les catégories et réponses de la catégorie courante"

msgid "Default"
msgstr "Standard"

msgid "Simple"
msgstr "Simple"

msgid "Fancy"
msgstr "Décoré"

msgid "Accept"
msgstr "Modifier l'apparence"


###
### addItem.pm
###

msgid "Subcategories:"
msgstr "Sous-catégories :"

msgid "Answers in this category:"
msgstr "Réponses dans cette catégorie : "

msgid "Copy of"
msgstr "Copie de"


###
### changePass.pm
###

msgid "Please enter your username, and select a password."
msgstr "Entrez votre nom d'utilisateur, et un mot de passe."

msgid "I will send a secret number to the email address you enter to verify that it is valid."
msgstr "Je vous envoi un nombre secret à l'adresse mèl que vous avez entrée pour vérifier la validité de votre adresse."

msgid "If you prefer not to give your email address to this web form, please contact"
msgstr "Si vous ne souhaitez pas donner votre adresse mél dans ce formulaire web, alors contactez"

msgid "Please <b>do not</b> use a password you use anywhere else, as it will not be transferred or stored securely!"
msgstr "Svp <b>n'utilisez pas</b> un mot de passe que vous utilisez pour autre chose, car le transfert et le stockage ne sont pas sécurisé !"

msgid "Password:"
msgstr "Mot de passe :"

msgid "Set Password"
msgstr "Entrez un mot de passe"


###
### Auth.pm
###

msgid "the administrator of this Faq-O-Matic"
msgstr "l'administrateur de FAQ-O-Matic"

msgid "someone who has proven their identification"
msgstr "quelqu'un qui a validé son identification"

msgid "someone who has offered identification"
msgstr "quelqu'un qui a été identifié"

msgid "anybody"
msgstr "n'importe qui"

msgid "the moderator of the item"
msgstr "modérateur de cette section"

msgid "%0 group members"
msgstr "membres du groupe %0"

msgid "I don't know who"
msgstr "Je ne sais qui"

msgid "Email:"
msgstr "Adresse mèl:"

###
### Authenticate.pm
###

msgid "That password is invalid. If you've forgotten your old password, you can"
msgstr "Ce mot de passe est faux. Si vous avez oublié votre ancien mot de passe, vous pouvez"

msgid "Set a New Password"
msgstr "Configurer un nouveau mot de passe"

msgid "Create a New Login"
msgstr "Créer un nouveau login"

msgid "New items can only be added by %0."
msgstr "Les nouvelles sections ne peuvent être ajoutées que par %0."

msgid "New text parts can only be added by %0."
msgstr "Les nouveaux articles ne peuvent être ajoutés que par %0."

msgid "Text parts can only be removed by %0."
msgstr "Les articles ne peuvent être effacés que par %0."

msgid "This part contains raw HTML. To avoid pages with invalid HTML, the moderator has specified that only %0 can edit HTML parts. If you are %0 you may authenticate yourself with this form."
msgstr "Cette section contient du HTML pur. Afin d'éviter les pages avec du code HTML invalide, le modérateur a spécifié que personne que %0 peut éditer des sections en HTML. Si vous êtes %0, vous devez vous authentifier avec ce formulaire."

msgid "Text parts can only be added by %0."
msgstr "Les articles ne peuvent être ajoutées que par %0."

msgid "Text parts can only be edited by %0."
msgstr "Les articles ne peuvent être édités que par %0."

msgid "The title and options for this item can only be edited by %0."
msgstr "Le titre et les options de cette section ne peuvent être édités que par %0."

msgid "The moderator options can only be edited by %0."
msgstr "Les options de modération ne peuvent être édité que par %0."

msgid "This item can only be moved by someone who can edit both the source and destination parent items."
msgstr "Cette section ne peut être déplacée que par quelqu'un qui peut à la fois éditer la source et la destination parente de la section."

msgid "This item can only be moved by %0."
msgstr "Cet élément ne peut être déplacé que par %0."

msgid "Existing bags can only be replaced by %0."
msgstr "Personne que %0 peut remplacer les fichiers objets existants."

msgid "Bags can only be posted by %0."
msgstr "Personne que %0 peut ajouter des fichiers objet."

msgid "The FAQ-O-Matic can only be configured by %0."
msgstr "La FAQ-O-Matic ne peut être configurée que par %0."

msgid "The operation you attempted (%0) can only be done by %1."
msgstr "L'opération que vous avez tenté (%0) ne peut être réalisé que par %1."

msgid "If you have never established a password to use with FAQ-O-Matic, you can"
msgstr "Si vous n'avez jamais configuré de mot de passe dans cette FAQ-O-Matic, vous pouvez"

msgid "If you have forgotten your password, you can"
msgstr "Si vous avez oublié votre mot de passe, vous pouvez"

msgid "If you have already logged in earlier today, it may be that the token I use to identify you has expired. Please log in again."
msgstr "Si vous vous ètes déjà logué, il se peut que l'authentification  est expirée. Reloguez vous À nouveau."

msgid "Please offer one of the following forms of identification:"
msgstr "Svp remplissez une de ces formes d'authentification : "

msgid "No authentication, but my email address is:"
msgstr "Pas d'authentification, mais mon adresse mèl est : "

msgid "Authenticated login:"
msgstr "Login d'authentification : "


###
### moveItem.pm
###

msgid "Make <b>%0</b> belong to which other item?"
msgstr "Faire <b>%0</b> appartient à quel autre entré ?"

msgid "No item that already has sub-items can become the parent of"
msgstr "Aucune entré qui posséde déjà des sous-entré ne peut devenir parent de"

msgid "No item can become the parent of"
msgstr "L'entrée ne peut pas devenir le parent de"

msgid "Some destinations are not available (not clickable) because you do not have permission to edit them as currently autorized."
msgstr "Certaines destinations ne sont pas accessibles car vous n'avez pas la permission d'éditer celle-ci."

msgid "Click here</a> to provide better authentication."
msgstr "Cliquez ici</a> pour permettre une meilleure authentification."

msgid "Hide answers, show only categories"
msgstr "Cacher les réponses, ne montrer que les catégories"

msgid "Show both categories and answers"
msgstr "Montrer à la fois les catégories et les réponses"


###
### editPart.pm
###

msgid "Enter the answer to <b>%0</b>"
msgstr "Répondre à <b>%0</b>"

msgid "Enter a description for <b>%0</b>"
msgstr "Décrire <b>%0</b>"

msgid "Edit duplicated text for <b>%0</b>"
msgstr "Dupliquer un texte de <b>%0</b>"

msgid "Enter new text for <b>%0</b>"
msgstr "éditer un nouveau texte dans <b>%0</b>"

msgid "Editing the %0 text part in <b>%1</b>."
msgstr "éditer la partie de texte n°%0 dans <b>%1</b>."

msgid "If you later need to edit or delete this text, use the [Appearance] page to turn on the expert editing commands."
msgstr "Si vous voulez éditer ou effacer ce texte plus tard, utilisez la page [Apparence] pour les commandes d'édition expert."


###
### Part.pm
###

msgid "Upload file:"
msgstr "Charger le fichier:"

msgid "Warning: file contents will <b>replace</b> previous text"
msgstr "Attention: Le contenu du fichier va <b>remplacer</b> le texte précédent"

msgid "Replace %0 with new upload"
msgstr "Remplacer %0 avec un nouveau chargement de fichier"

msgid "Select bag to replace with new upload"
msgstr "Sélectionner le nouveau fichier objet"

msgid "Hide Attributions"
msgstr "Ne pas montrer le nom des auteurs"

msgid "Format text as:"
msgstr "Formater le texte comme : "

msgid "Directory"
msgstr "un répertoire"

msgid "Natural text"
msgstr "un texte normal"

msgid "Monospaced text (code, tables)"
msgstr "un texte monospace (code, tableau)"

msgid "Untranslated HTML"
msgstr "du code HTML"

msgid "Submit Changes"
msgstr "Soumettre les modifications"

msgid "Revert"
msgstr "Annuler"

msgid "Insert Uploaded Text Here"
msgstr "Insérer un texte à charger"

msgid "Insert Text Here"
msgstr "Insérer un texte"

msgid "Edit This Text"
msgstr "éditer ce texte"

msgid "Duplicate This Text"
msgstr "Dupliquer ce texte"

msgid "Remove This Text"
msgstr "Effacer ce texte"

msgid "Upload New Bag Here"
msgstr "Charger un nouveau fichier objet"


###
### searchForm.pm
###

msgid "Search for"
msgstr "Rechercher"

msgid "matching"
msgstr "contenant"

msgid "all"
msgstr "tout les"

msgid "any"
msgstr "un des"

msgid "two"
msgstr "deux"

msgid "three"
msgstr "trois"

msgid "four"
msgstr "quatre"

msgid "five"
msgstr "cinq"

msgid "words"
msgstr "mots"

msgid "Show documents"
msgstr "Montrer les documents"

msgid "modified in the last"
msgstr "qui ont été modifiés"

msgid "day"
msgstr "il y a un jour"

msgid "two days"
msgstr "il y a deux jours"

msgid "three days"
msgstr "il y a trois jours"

msgid "week"
msgstr "cette semaine"

msgid "fortnight"
msgstr "il y a deux semaines"

msgid "month"
msgstr "depuis un mois"


###
### search.pm
###

msgid "No items matched"
msgstr "Aucun élémént trouvé"

msgid "of these words"
msgstr "contenant ces mots"

msgid "Search results for"
msgstr "Résultat de la recherche de"

msgid "at least"
msgstr "à la fin"

msgid "Results may be incomplete, because the search index has not been refreshed since the most recent change to the database."
msgstr "Les résultats peuvent être incomplets, car l'index de recherche n'a peut être pas été remis à jour depuis les modifications récentes de la base de données."


###
### Item.pm
###

msgid "defined in"
msgstr "définit dans"

msgid "Name & Description"
msgstr "Nom et description"

msgid "Setting"
msgstr "Configuration"

msgid "Setting if Inherited"
msgstr "Configuration hérité"

msgid "Group %0"
msgstr "Groupe %0"

msgid "Moderator"
msgstr "Modérateur"

msgid "nobody"
msgstr "personne"

msgid "(system default)"
msgstr "(système par défaut)"

msgid "(inherited from parent)"
msgstr "(herité du parent)"

msgid "(will inherit if empty)"
msgstr "(héritera si c'est vide)"

msgid "Send mail to the moderator when someone other than the moderator edits this item:"
msgstr "Envoyer un mèl au modérateur, si quelqu'un d'autre que le modérateur édite la section : "

msgid "Permissions"
msgstr "Permissions"

msgid "Blah blah"
msgstr "Blah blah"

msgid "Yes"
msgstr "Oui"

msgid "No"
msgstr "Non"

msgid "Relax"
msgstr "Relax"

msgid "Don't Relax"
msgstr "Don't Relax"

msgid "undefined"
msgstr "pas definé"

msgid "<p>New Order for Text Parts:"
msgstr "<p>Nouvel ordre des articles:"

msgid "Who can access the installation/configuration page (use caution!):"
msgstr "Qui peut avoir accès à la page de configuration (attention!):"

msgid "Who can add a new text part to this item:"
msgstr "Qui peut ajouter un nouvel article dans cette section:"

msgid "Who can add a new answer or category to this category:"
msgstr "Qui peut ajouter une nouvelle réponse ou catégorie dans cette catégorie:"

msgid "Who can edit or remove existing text parts from this item:"
msgstr "Qui peut éditer ou effacer un article existant dans cette section:"

msgid "Who can move answers or subcategories from this category; or turn this category into an answer or vice versa:"
msgstr "Qui peut déplacer les réponses ou les sous-catégories de cette catégorie;  ou transformer cette catégorie en réponse ou cette réponse en catégorie:"

msgid "Who can edit the title and options of this answer or category:"
msgstr "Qui peut éditer le titre et les options de cette réponse ou catégorie:"

msgid "Who can use untranslated HTML when editing the text of this answer or category:"
msgstr "Qui peut utiliser l'HTML pour éditer un texte de la réponse ou la catégorie:"

msgid "Who can change these moderator options and permissions:"
msgstr "Qui peut modifier les options et permissions du modérateurs:"

msgid "Who can use the group membership pages:"
msgstr "Qui peut utiliser les pages d'appartenance des groupes:"

msgid "Who can create new bags:"
msgstr "Qui peut créer de nouveaux fichiers objets:"

msgid "Who can replace existing bags:"
msgstr "Qui peut remplacer des fichiers objets existant:"

msgid "Group"
msgstr "Groupe"

msgid "Authenticated users"
msgstr "utilisateurs authentifiés"

msgid "Users giving their names"
msgstr "Utilisateurs ayant donné leurs noms"

msgid "Inherit"
msgstr "Hérité"

msgid "File %0 seems broken."
msgstr "Le fichier %0 a l'air d'être défecteux."

msgid "Permissions:"
msgstr "Permissions:"

msgid "Moderator options for"
msgstr "Les options du modérateur sont"

msgid "Title:"
msgstr "Titre:"

msgid "Category"
msgstr "Catégorie"

msgid "Answer"
msgstr "l'Entrée"

msgid "Show attributions from all parts together at bottom"
msgstr "Montrer en bas de la page, tous les auteurs de la catégorie."
 
msgid "New Item"
msgstr "Nouvelle Entrée"

msgid "Convert to Answer"
msgstr "Transformer en Entrée"

msgid "Convert to Category"
msgstr "Transformer en Catégorie"

msgid "New Subcategory of "%0""
msgstr "Nouvelle Sous-Catégorie de <i>%0</i>"

msgid "Move %0"
msgstr "Déplacer %0"

msgid "Trash %0"
msgstr "Supprimer %0"

msgid "Parts"
msgstr "Des Entrées"

msgid "New Category"
msgstr "Nouvelle Catégorie"

msgid "New Answer"
msgstr "Nouvelle Entrée"

msgid "Editing %0 <b>%1</b>"
msgstr "Éditer %0 <b>%1</b>"

msgid "New Answer in "%0""
msgstr "Nouvelle Entrée dans <i>%0</i>"

msgid "Duplicate Category as Answer"
msgstr "Dupliquer la Catégorie"

msgid "Duplicate Answer"
msgstr "Dupliquer l'Entrée"

msgid "%0 Title and Options"
msgstr "%0: Options (Titre, ordre des articles...)"

msgid "Edit %0 Permissions"
msgstr "Éditer des permissions pour %0"

msgid "Append to This Answer"
msgstr "Contribuer à cette Entrée"

msgid "This document is:"
msgstr "Ce document est:"

msgid "This document is at:"
msgstr "Ce document est à l'URL:"

msgid "Previous"
msgstr "Précédent"

msgid "Next"
msgstr "Suivant"


###
### Appearance.pm
###

msgid "Search"
msgstr "Chercher"

msgid "Appearance"
msgstr "Apparence"

msgid "Show Top Category Only"
msgstr "Ne montrer que la catégorie principale"

msgid "Show This <em>Entire</em> Category"
msgstr "Montrer <em>toute</em> la Catégorie"

msgid "Show This %0 As Text"
msgstr "Montrer ce %0 comme un texte"

msgid "Show This <em>Entire</em> Category As Text"
msgstr "Montrer <em>toute</em> la Catégorie comme un texte"

msgid "Hide Expert Edit Commands"
msgstr "Cacher les commandes d'édition expert"

msgid "Show Expert Edit Commands"
msgstr "Montrer les commandes d'édition expert"

msgid "This is a"
msgstr "C'est une"

msgid "Hide Help"
msgstr "Cacher l'aide"

msgid "Help"
msgstr "Aide"

msgid "Log In"
msgstr "Se loguer"

msgid "Change Password"
msgstr "Changer de mot de passe"

msgid "Edit Title of %0 %1"
msgstr "Éditer le Titre de %0 %1"

msgid "New %0"
msgstr "Nouveau %0"

msgid "Edit Part in %0 %1"
msgstr "Éditer la section de %0 %1"

msgid "Insert Part in %0 %1"
msgstr "Insérer une section dans %0 %1"

msgid "Move %0 %1"
msgstr "Déplace %0 %1"

msgid "Access Statistics"
msgstr "Statistique d'accès"

msgid "%0 Permissions for %1"
msgstr "%0 permissions pour %1"

msgid "Upload bag for %0 %1"
msgstr "Charger un fichier objet pour %0 %1"

###
### Adds
###

msgid "Either someone has changed the answer or category you were editing since you received the editing form, or you submitted the same form twice."
msgstr "Quelqu'un a du changé l'entrée ou la catégorie pendant que vous receviez le formulaire d'édition, ou alors vous avez soumis le formulaire une deuxiéme fois."

msgid "Return to the FAQ"
msgstr "Retourner à la FAQ"

msgid "Please %0 and start again to make sure no changes are lost. Sorry for the inconvenience."
msgstr "Svp cliquez %0 et recommencez pour être sur que les modifications n'ont pas été perdues. Désolé pour l'inconveniant."

msgid "(Sequence number in form: %0; in item: %1)"
msgstr "(Numéro de séquence dans le formulaire %0; dans l'entrée: %1)."

msgid "This page will reload every %0 seconds, showing the last %1 lines of the process output."
msgstr "Cette page se redésignera toute les %0 secondes, et montre les %1 dernières lignes du process."

msgid "Show the entire process log"
msgstr "Montrer tout le log du procès"


###
### 'sub'-messages
###

msgid "Select a group to edit:"
msgstr "Sélectionnez une groupe:"

msgid "Add Group"
msgstr "Ajouter une groupe nouvelle"

msgid "(Members of this group are allowed to access these group definition pages.)"
msgstr "(Des mebres de cette groupe on accès aux pages qui definissent les membres des groupes.)"

msgid "Up To List Of Groups"
msgstr "Retourner à la liste des groupes"

msgid "Add Member"
msgstr "Ajouter un membre nouveau"

msgid "Remove Member"
msgstr "Supprimer un membre"


###
### END
###

);
__EOF__

	my @txs = grep { m/^msg/ } split(/\n/, $txfile);
	for (my $i=0; $i<@txs; $i+=2) {
		$txs[$i] =~ m/msgid \"(.*)\"$/;
		my $from = $1;
		$txs[$i+1] =~ m/msgstr \"(.*)\"$/;
		my $to = $1;
		if (not defined $from or not defined $to) {
			die "bad translation for ".$txs[$i]." at pair $i";
		}
		$tx->{$from} = $to;
	}
};

