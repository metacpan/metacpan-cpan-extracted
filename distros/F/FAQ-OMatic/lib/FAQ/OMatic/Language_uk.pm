#--------------------------------------------------------------------
#   Language_uk.pm
#   Generated automatically from uk.po by po2pm
#--------------------------------------------------------------------

sub translations {
    my $tx = shift;

    my %data = (

# Ukrainian translation for FAQ-O-Matic.
# Translated by Andrew W. Nosenko <awn@bcs.zp.ua>, 2001
#
# This is partial translation indeed.  For most phrases appropriate
# Russian phrases is used.  These phrases marked as Russian in comments.
# Contributions of proper Ukrainian translations are welcomed (same as
# any other contributions ;-).
#
# Some words:
# bag     "м╕шок"
# content вм╕ст
# data    вм╕ст   FIXME: хто-небудь зна╓ кращ╕й переклад?
# define  визначити
# script  ???     FIXME: я використав `скрипт', але...
#
# ATTENTION: don't remove fuzzy mark from this startup entry!
#, fuzzy
 ""
# fuzzy # => "Project-Id-Version: faqomatic 2.711_01\nPOT-Creation-Date: 2001-08-07 14:22+0300\nPO-Revision-Date: 2001-08-06 19:55+0300\nLast-Translator: FULL NAME <EMAIL@ADDRESS>\nLanguage-Team: Ukrainian <someone@somewhere.org>\nMIME-Version: 1.0\nContent-Type: text/plain; charset=koi8-u\nContent-Transfer-Encoding: 8bit\n",
 => "",

#: lib/FAQ/OMatic.pm:95 lib/FAQ/OMatic/install.pm:1040
 "Warnings:"
 => "Попередження:",

#: lib/FAQ/OMatic.pm:135 lib/FAQ/OMatic/authenticate.pm:151
 "Log In"
 => "Ув╕йти",

#: lib/FAQ/OMatic.pm:136
 "Change Password"
 => "Зм╕нити Пароль",

#: lib/FAQ/OMatic.pm:137
 "Edit Title of %0 %1"
 => "%0 %1: Редагування заголовка",

# Intentionally left blank
#: lib/FAQ/OMatic.pm:138
#, c-format
 "New %0"
 => "",

#: lib/FAQ/OMatic.pm:139
 "Edit Part in %0 %1"
 => "%0 %1: Редагування частки",

#: lib/FAQ/OMatic.pm:140
 "Insert Part in %0 %1"
 => "%0 %1: Вставка частки",

#: lib/FAQ/OMatic.pm:141
 "Move %0 %1"
 => "%0 %1: Перем╕щення",

#: lib/FAQ/OMatic.pm:142 lib/FAQ/OMatic/Appearance.pm:168
 "Search"
 => "Пошук",

#: lib/FAQ/OMatic.pm:143
 "Access Statistics"
 => "Статистика доступу",

#: lib/FAQ/OMatic.pm:144 lib/FAQ/OMatic/submitPass.pm:145
 "Validate"
 => "Перев╕рити",

#: lib/FAQ/OMatic.pm:145
 "%0 Permissions for %1"
 => "%0 %1: Настройки та права доступу",

#: lib/FAQ/OMatic.pm:146
 "Upload bag for %0 %1"
 => "",

#: lib/FAQ/OMatic/Appearance.pm:177
 "Appearance"
 => "Зовн╕шн╕й Вигляд",

#: lib/FAQ/OMatic/Appearance.pm:191
 "Show Top Category Only"
 => "Показати Т╕льки Верхню Категор╕ю",

#: lib/FAQ/OMatic/Appearance.pm:198
 "Show This <em>Entire</em> Category"
 => "Показати <em>Геть Усю</em> Категор╕ю",

#: lib/FAQ/OMatic/Appearance.pm:209
 "Show This Category As Text"
 => "Показати Цю Категор╕ю Як Текст",

#: lib/FAQ/OMatic/Appearance.pm:213
 "Show This Answer As Text"
 => "Показати Цю В╕дпов╕дь Як Текст",

# Intentionally left blank.
#: lib/FAQ/OMatic/Appearance.pm:218
 "Show This %0 As Text"
 => "",

#: lib/FAQ/OMatic/Appearance.pm:232
 "Show This <em>Entire</em> Category As Text"
 => "Показати <em>Геть Усю</em> Категор╕ю Як Текст",

#: lib/FAQ/OMatic/Appearance.pm:244
 "Hide Expert Edit Commands"
 => "Сховати Поширен╕ Команди Редагування",

#: lib/FAQ/OMatic/Appearance.pm:253
 "Show Expert Edit Commands"
 => "Показати Поширен╕ Команди Редагування",

#: lib/FAQ/OMatic/Appearance.pm:269 lib/FAQ/OMatic/Item.pm:1955
#: lib/FAQ/OMatic/stats.pm:133
 "Return to the FAQ"
 => "Повернутися до FAQ",

#: lib/FAQ/OMatic/Appearance.pm:276
 "This is a"
 => "Це ╓",

#: lib/FAQ/OMatic/Auth.pm:475
 "the administrator of this Faq-O-Matic"
 => "адм╕н╕стратор цього FAQ-O-Matic'а",

#: lib/FAQ/OMatic/Auth.pm:476
 "someone who has proven their identification"
 => "хто-небудь, хто з усп╕хом пройшов ╕дентиф╕кац╕ю",

#: lib/FAQ/OMatic/Auth.pm:477
 "someone who has offered identification"
 => "хто-небудь, хто ╕дентиф╕кував себе (досить email-адреси)",

#: lib/FAQ/OMatic/Auth.pm:478
 "anybody"
 => "хто завгодно",

#: lib/FAQ/OMatic/Auth.pm:491
 "the moderator of the item"
 => "модератор",

#: lib/FAQ/OMatic/Auth.pm:495
#, c-format
 "%0 group members"
 => "члени групи %0",

#: lib/FAQ/OMatic/Groups.pm:142
 "Select a group to edit:"
 => "Виберить групу для редагування:",

#: lib/FAQ/OMatic/Groups.pm:150
 "(Members of this group are allowed to access these group definition pages.)"
 => "(Члени ц╕╓╖ групи мають доступ до ц╕╓╖ стор╕нки керування групами.)",

#: lib/FAQ/OMatic/Groups.pm:168
 "Add Group"
 => "Додати Групу",

#: lib/FAQ/OMatic/Groups.pm:175
 "Up To List Of Groups"
 => "Нагору до Списку Груп",

#: lib/FAQ/OMatic/Groups.pm:187
 "Remove Member"
 => "Стерти Члена Групи",

#: lib/FAQ/OMatic/Groups.pm:196
 "Add Member"
 => "Додати Члена Групи",

#: lib/FAQ/OMatic/Groups.pm:206 lib/FAQ/OMatic/install.pm:466
#: lib/FAQ/OMatic/install.pm:470
 "Go to the Faq-O-Matic"
 => "Перейти до Faq-O-Matic'а",

#: lib/FAQ/OMatic/Groups.pm:209
 "Go To Install/Configuration Page"
 => "Перейти до стор╕нки Установок ╕ Конф╕гурац╕╖",

#: lib/FAQ/OMatic/Item.pm:74
 "New Item"
 => "(Елемент без назви)",

#: lib/FAQ/OMatic/Item.pm:630
 "Parts"
 => "Частки",

#: lib/FAQ/OMatic/Item.pm:749
 "Previous"
 => "Попередн╕й документ",

#: lib/FAQ/OMatic/Item.pm:767
 "Next"
 => "Наступний документ",

#: lib/FAQ/OMatic/Item.pm:861 lib/FAQ/OMatic/Item.pm:1268
#: lib/FAQ/OMatic/Item.pm:1452
 "Moderator"
 => "Модератор",

#: lib/FAQ/OMatic/Item.pm:862
 "(inherited from parent)"
 => "(успадковуеться в╕д батьк╕вського елемента)",

#: lib/FAQ/OMatic/Item.pm:876
 "Category Title and Options"
 => "Заголовок та Настройки Категор╕╖",

#: lib/FAQ/OMatic/Item.pm:877
 "Edit Category Permissions"
 => "Редагувати Права Доступу до Категор╕╖",

#: lib/FAQ/OMatic/Item.pm:878
 "Move Category"
 => "Перем╕стити Категор╕ю",

#: lib/FAQ/OMatic/Item.pm:879
 "Trash Category"
 => "Викинути Категор╕ю",

#: lib/FAQ/OMatic/Item.pm:883
 "Answer Title and Options"
 => "Заголовок та Настройки В╕дпов╕д╕",

#: lib/FAQ/OMatic/Item.pm:884
 "Edit Answer Permissions"
 => "Редагувати Права Доступу до В╕дпов╕д╕",

#: lib/FAQ/OMatic/Item.pm:885
 "Move Answer"
 => "Перем╕стити В╕дпов╕дь",

#: lib/FAQ/OMatic/Item.pm:886
 "Trash Answer"
 => "Викинути В╕дпов╕дь",

# Intentionally left blank.
#: lib/FAQ/OMatic/Item.pm:892
 "%0 Title and Options"
 => "",

# Intentionally left blank.
#: lib/FAQ/OMatic/Item.pm:893 lib/FAQ/OMatic/Item.pm:894
 "Edit %0 Permissions"
 => "",

# Intentionally left blank.
#: lib/FAQ/OMatic/Item.pm:895
#, c-format
 "Move %0"
 => "",

# Intentionally left blank.
#: lib/FAQ/OMatic/Item.pm:896
#, c-format
 "Trash %0"
 => "",

#: lib/FAQ/OMatic/Item.pm:934
 "Duplicate Answer"
 => "Скоп╕ювати В╕дпов╕дь",

#: lib/FAQ/OMatic/Item.pm:935
 "Duplicate Category as Answer"
 => "Скоп╕ювати Категор╕ю як В╕дпов╕дь",

#: lib/FAQ/OMatic/Item.pm:978
 "Convert to Answer"
 => "Перетворити на В╕дпов╕дь",

#: lib/FAQ/OMatic/Item.pm:988
 "Convert to Category"
 => "Перетворити на Категор╕ю",

#: lib/FAQ/OMatic/Item.pm:1004 lib/FAQ/OMatic/Item.pm:1084
 "New Answer in \"%0\""
 => "Додати нову пару Питання/В╕дпов╕дь до \"%0\"",

#: lib/FAQ/OMatic/Item.pm:1011
 "New Subcategory of \"%0\""
 => "Додати Нову Категор╕ю до \"%0\"",

#: lib/FAQ/OMatic/Item.pm:1037 lib/FAQ/OMatic/Part.pm:342
 "Insert Text Here"
 => "Вставити Текст Сюди",

#: lib/FAQ/OMatic/Item.pm:1050 lib/FAQ/OMatic/Part.pm:353
 "Insert Uploaded Text Here"
 => "",

#: lib/FAQ/OMatic/Item.pm:1100
 "Append to This Answer"
 => "Додати до ц╕╓╖ В╕дпов╕д╕",

#: lib/FAQ/OMatic/Item.pm:1216
 "This document is:"
 => "Цей документ:",

#: lib/FAQ/OMatic/Item.pm:1218
 "This document is at:"
 => "Цей документ доступен на:",

#: lib/FAQ/OMatic/Item.pm:1262
#, c-format
 "Group %0"
 => "Група %0",

#: lib/FAQ/OMatic/Item.pm:1266
 "Users giving their names"
 => "Користувач╕, як╕ надали сво╖ ╕мена",

#: lib/FAQ/OMatic/Item.pm:1267
 "Authenticated users"
 => "Аутентиф╕кован╕ користувач╕",

#: lib/FAQ/OMatic/Item.pm:1282
 "New Category"
 => "Нова Категор╕я",

#: lib/FAQ/OMatic/Item.pm:1284
 "New Answer"
 => "Нова В╕дпов╕дь",

#: lib/FAQ/OMatic/Item.pm:1288
 "Editing Category <b>%0</b>"
 => "Редагування Категор╕╖ <b>\"%0\"</b>",

#: lib/FAQ/OMatic/Item.pm:1292
 "Editing Answer <b>%0</b>"
 => "Редагування В╕дпов╕д╕ <b>\"%0\"</b>",

# Intentionally left blank.
#: lib/FAQ/OMatic/Item.pm:1297
 "Editing %0 <b>%1</b>"
 => "",

#: lib/FAQ/OMatic/Item.pm:1327
 "Title:"
 => "Заголовок:",

#: lib/FAQ/OMatic/Item.pm:1332
 "<p>New Order for Text Parts:"
 => "<p>Нова черга для текстових часток:",

#: lib/FAQ/OMatic/Item.pm:1344
 "Show attributions from all parts together at bottom"
 => "Показувати п╕дписи, з╕бран╕ з ус╕х часток, разом у низу (Show attributions from all parts together at bottom)",

#: lib/FAQ/OMatic/Item.pm:1357 lib/FAQ/OMatic/Item.pm:1511
#: lib/FAQ/OMatic/Part.pm:556 lib/FAQ/OMatic/editBag.pm:118
 "Submit Changes"
 => "Внести Зм╕ни",

#: lib/FAQ/OMatic/Item.pm:1358 lib/FAQ/OMatic/Item.pm:1512
#: lib/FAQ/OMatic/Part.pm:557 lib/FAQ/OMatic/editBag.pm:119
 "Revert"
 => "В╕дкотити",

#: lib/FAQ/OMatic/Item.pm:1378
 "Who can add a new text part to this item:"
 => "Хто ма╓ право додавати нов╕ текстов╕ частки до цього елементу:",

#: lib/FAQ/OMatic/Item.pm:1380
 "Who can add a new answer or category to this category:"
 => "Хто ма╓ право додавати нов╕ в╕дпов╕д╕ або категор╕╖ до ц╕╓╖ категор╕╖:",

#: lib/FAQ/OMatic/Item.pm:1382
 "Who can edit or remove existing text parts from this item:"
 => "Хто ма╓ право редагувати або стирати ╕снуюч╕ текстов╕ частки у цьому елемент╕:",

#: lib/FAQ/OMatic/Item.pm:1384
 "Who can move answers or subcategories from this category; or turn this category into an answer or vice versa:"
 => "Хто ма╓ право перем╕щувати в╕дпов╕д╕ або п╕дкатегор╕╖ ╕з ц╕╓╖ категор╕╖; або \"перетворювати\" цю категор╕ю на в╕дпов╕дь ╕ навпаки:",

#: lib/FAQ/OMatic/Item.pm:1386
 "Who can edit the title and options of this answer or category:"
 => "Хто ма╓ право редагувати заголовок та зм╕нювати настройки ц╕╓╖ в╕дпов╕д╕ або категор╕╖:",

#: lib/FAQ/OMatic/Item.pm:1388
 "Who can use untranslated HTML when editing the text of this answer or category:"
 => "Хто ма╓ право використовувати \"чистий\" HTML при редагуванн╕ текста ц╕╓╖ в╕дпов╕д╕ або категор╕╖:",

#: lib/FAQ/OMatic/Item.pm:1390
 "Who can change these moderator options and permissions:"
 => "Хто ма╓ право зм╕нювати ц╕ настройки та права доступу модератора:",

#: lib/FAQ/OMatic/Item.pm:1392
 "Who can create new bags:"
 => "Хто ма╓ право створювати нов╕ \"м╕шки\":",

#: lib/FAQ/OMatic/Item.pm:1394
 "Who can replace existing bags:"
 => "Хто ма╓ право зам╕нювати ╕снуюч╕ \"м╕шки\":",

#: lib/FAQ/OMatic/Item.pm:1396
 "Who can access the installation/configuration page (use caution!):"
 => "Хто ма╓ доступ до Стор╕нки Установок та Настройок (використовуйте з обережн╕стю!):",

#: lib/FAQ/OMatic/Item.pm:1398
 "Who can use the group membership pages:"
 => "Хто ма╓ право користуватися стор╕нками членства в групах:",

#: lib/FAQ/OMatic/Item.pm:1415
 "Moderator options for category"
 => "Настройки модератора для категор╕╖",

#: lib/FAQ/OMatic/Item.pm:1419
 "Moderator options for answer"
 => "Настройки модератора для в╕дпов╕д╕",

# Intentionally left blank
#: lib/FAQ/OMatic/Item.pm:1424
 "Moderator options for"
 => "",

#: lib/FAQ/OMatic/Item.pm:1442
 "Name & Description"
 => "Назва та Опис",

#: lib/FAQ/OMatic/Item.pm:1443
 "Setting"
 => "Установка",

#: lib/FAQ/OMatic/Item.pm:1444
 "Setting if Inherited"
 => "Установка якщо \"Успадковувати\"",

#: lib/FAQ/OMatic/Item.pm:1453
 "(will inherit if empty)"
 => "(буде успадковано, якщо залишити пустим)",

#: lib/FAQ/OMatic/Item.pm:1463
 "Send mail to the moderator when someone other than the moderator edits this item:"
 => "Посилати пошту модератору, коли хтось ╕нший (не модератор), редагу╓ цей елемент:",

#: lib/FAQ/OMatic/Item.pm:1469
 "No"
 => "Н╕",

#: lib/FAQ/OMatic/Item.pm:1469
 "Yes"
 => "Так",

#: lib/FAQ/OMatic/Item.pm:1469 lib/FAQ/OMatic/Item.pm:1505
 "undefined"
 => "невизначено",

#: lib/FAQ/OMatic/Item.pm:1474
 "Permissions"
 => "Права Доступу",

#: lib/FAQ/OMatic/Item.pm:1496
 "Blah blah"
 => "Мама мила раму ;-)",

#: lib/FAQ/OMatic/Item.pm:1500 lib/FAQ/OMatic/Item.pm:1504
 "Relax"
 => "",

#: lib/FAQ/OMatic/Item.pm:1500 lib/FAQ/OMatic/Item.pm:1504
 "Don't Relax"
 => "",

#: lib/FAQ/OMatic/Item.pm:1500
 "Inherit"
 => "Успадковувати",

#: lib/FAQ/OMatic/Item.pm:1534 lib/FAQ/OMatic/Item.pm:1548
 "(system default)"
 => "(системний по-замовчанню)",

#: lib/FAQ/OMatic/Item.pm:1540
 "defined in"
 => "визначен у",

#: lib/FAQ/OMatic/Item.pm:1617
#, c-format
 "File %0 seems broken."
 => "Файл %0 ма╓ вигляд пошкодженого.",

#: lib/FAQ/OMatic/Item.pm:1886
 "Category"
 => "Категор╕я",

#: lib/FAQ/OMatic/Item.pm:1887
 "Answer"
 => "В╕дпов╕дь",

#: lib/FAQ/OMatic/Item.pm:1957
 "Either someone has changed the answer or category you were editing since you received the editing form, or you submitted the same form twice"
 => "Або хтось зм╕нив в╕дпов╕дь або категор╕ю, яку ви редагували п╕сля того, як ви почали заповнювати форму; або ви над╕слали одну ╕ туж саму форму дв╕ч╕.",

#: lib/FAQ/OMatic/Item.pm:1959
 "Please %0 and start again to make sure no changes are lost. Sorry for the inconvenience."
 => "Будьте ласкав╕, %0 ╕ почнить с початку, щоб бути впевненим, що зм╕ни не загубилися.  Вибачайте за незручн╕сть.",

#: lib/FAQ/OMatic/Item.pm:1962
 "(Sequence number in form: %0; in item: %1)"
 => "(Посл╕довний номер в форм╕: %0; в елемент╕: %1)",

#: lib/FAQ/OMatic/Part.pm:266
 "Edit This Text"
 => "Редагувати Цей Текст",

#: lib/FAQ/OMatic/Part.pm:277
 "Duplicate This Text"
 => "Скоп╕ювати Цей Текст",

#: lib/FAQ/OMatic/Part.pm:288 lib/FAQ/OMatic/Part.pm:301
 "Remove This Text"
 => "Стерти Цей Текст",

#: lib/FAQ/OMatic/Part.pm:313
 "Replace %0 with new upload"
 => "",

#: lib/FAQ/OMatic/Part.pm:320
 "Select bag to replace with new upload"
 => "",

#: lib/FAQ/OMatic/Part.pm:329
 "Upload New Bag Here"
 => "",

#: lib/FAQ/OMatic/Part.pm:494
 "Upload file:"
 => "",

#: lib/FAQ/OMatic/Part.pm:499
 "Warning: file contents will <b>replace</b> previous text"
 => "Попередження: вм╕ст файлу <b>зам╕нить</b> попередн╕й текст",

#: lib/FAQ/OMatic/Part.pm:506
 "Hide Attributions"
 => "Сховати п╕дписи",

#: lib/FAQ/OMatic/Part.pm:509
 "Format text as:"
 => "Форматувати текст як:",

#: lib/FAQ/OMatic/Part.pm:519
 "Directory"
 => "Каталог",

#: lib/FAQ/OMatic/Part.pm:526
 "Natural text"
 => "Природний текст",

#: lib/FAQ/OMatic/Part.pm:530
 "Monospaced text (code, tables)"
 => "Моношир╕нний текст (код, таблиц╕)",

#: lib/FAQ/OMatic/Part.pm:545
 "Untranslated HTML"
 => "\"Чистий\" HTML",

#: lib/FAQ/OMatic/Part.pm:695 lib/FAQ/OMatic/addItem.pm:85
#: lib/FAQ/OMatic/install.pm:1138 lib/FAQ/OMatic/submitAnsToCat.pm:67
 "Answers in this category:"
 => "В╕дпов╕д╕ в ц╕й категор╕╖:",

#: lib/FAQ/OMatic/Slow.pm:137
 "This page will reload every %0 seconds, showing the last %1 lines of the process output."
 => "Ця стор╕нка буде автоматично в╕дновлюватися кожн╕ %0 секунд, показуючи останн╕ %1 строк виводу процеса.",

#: lib/FAQ/OMatic/Slow.pm:141
 "Show the entire process log"
 => "Показати вивод процеса ц╕лком",

#: lib/FAQ/OMatic/addItem.pm:48 lib/FAQ/OMatic/delPart.pm:47
#: lib/FAQ/OMatic/editItem.pm:50 lib/FAQ/OMatic/editModOptions.pm:50
#: lib/FAQ/OMatic/faq.pm:74 lib/FAQ/OMatic/moveItem.pm:50
#: lib/FAQ/OMatic/selectBag.pm:60 lib/FAQ/OMatic/submitAnsToCat.pm:49
#: lib/FAQ/OMatic/submitCatToAns.pm:48 lib/FAQ/OMatic/submitItem.pm:48
#: lib/FAQ/OMatic/submitModOptions.pm:46 lib/FAQ/OMatic/submitPart.pm:47
 "The file (%0) doesn't exist."
 => "Файл (%0) не ╕сну╓.",

#: lib/FAQ/OMatic/addItem.pm:67
 "Copy of"
 => "Коп╕я",

#: lib/FAQ/OMatic/addItem.pm:85 lib/FAQ/OMatic/install.pm:1138
#: lib/FAQ/OMatic/submitAnsToCat.pm:67
 "Subcategories:"
 => "П╕дкатегор╕╖:",

#: lib/FAQ/OMatic/appearanceForm.pm:46
 "Appearance Options"
 => "Настройки Зовн╕шнього Вигляду",

#: lib/FAQ/OMatic/appearanceForm.pm:60 lib/FAQ/OMatic/appearanceForm.pm:64
#: lib/FAQ/OMatic/appearanceForm.pm:68 lib/FAQ/OMatic/appearanceForm.pm:84
#: lib/FAQ/OMatic/appearanceForm.pm:92
 "Show"
 => "Показати",

#: lib/FAQ/OMatic/appearanceForm.pm:60
 "Compact"
 => "Компактно",

#: lib/FAQ/OMatic/appearanceForm.pm:60 lib/FAQ/OMatic/appearanceForm.pm:64
#: lib/FAQ/OMatic/appearanceForm.pm:68 lib/FAQ/OMatic/appearanceForm.pm:84
#: lib/FAQ/OMatic/appearanceForm.pm:92
 "Hide"
 => "Сховати",

#: lib/FAQ/OMatic/appearanceForm.pm:62 lib/FAQ/OMatic/install.pm:776
 "expert editing commands"
 => "поширен╕ команди редагування",

#: lib/FAQ/OMatic/appearanceForm.pm:66 lib/FAQ/OMatic/install.pm:781
 "name of moderator who organizes current category"
 => "╕м'я модератора, керуючого ц╕╓ю категор╕╓ю",

#: lib/FAQ/OMatic/appearanceForm.pm:70 lib/FAQ/OMatic/install.pm:786
 "last modified date"
 => "дату останньо╖ зм╕ни",

#: lib/FAQ/OMatic/appearanceForm.pm:84
 "Default"
 => "По замовчанню",

#: lib/FAQ/OMatic/appearanceForm.pm:86 lib/FAQ/OMatic/install.pm:791
 "attributions"
 => "п╕дписи",

#: lib/FAQ/OMatic/appearanceForm.pm:88
 "Simple"
 => "Простий",

#: lib/FAQ/OMatic/appearanceForm.pm:88
 "Fancy"
 => "Примхливий",

#: lib/FAQ/OMatic/appearanceForm.pm:94 lib/FAQ/OMatic/install.pm:796
 "commands for generating text output"
 => "команди для генерац╕╖ текстового виводу",

#: lib/FAQ/OMatic/appearanceForm.pm:126
 "Accept"
 => "Прийняти",

#: lib/FAQ/OMatic/authenticate.pm:55
 "Set a New Password"
 => "Установити Новий Пароль",

#: lib/FAQ/OMatic/authenticate.pm:60
 "Create a New Login"
 => "Створити Новий Вх╕д",

#: lib/FAQ/OMatic/authenticate.pm:63
 "That password is invalid. If you've forgotten your old password, you can"
 => "Цей пароль не ╓ правильним. Якщо ви забули св╕й старий пароль, ви ма╓те можлив╕сть",

#: lib/FAQ/OMatic/authenticate.pm:81
#, c-format
 "New items can only be added by %0."
 => "Додавати нов╕ елементи мають право лише: %0",

#: lib/FAQ/OMatic/authenticate.pm:83
#, c-format
 "New text parts can only be added by %0."
 => "Додавати нов╕ текстов╕ частки мають право лише: %0",

#: lib/FAQ/OMatic/authenticate.pm:85
#, c-format
 "Text parts can only be removed by %0."
 => "Стирати текстов╕ частки мають право лише: %0",

#: lib/FAQ/OMatic/authenticate.pm:89
 "This part contains raw HTML. To avoid pages with invalid HTML, the moderator has specified that only %0 can edit HTML parts. If you are %0 you may authenticate yourself with this form."
 => "Ця частка м╕стить &quot;чистий&quot; HTML.  Щоб запоб╕гти появ╕ стор╕нок, м╕стящих неправильний HTML, модератор визначив, що редагувати HTML частки мають право лише: %0.  Якщо ви з ╖х числа, ви ма╓те п╕дтвердити свою особу за допомогою подальшо╖ форми.",

#: lib/FAQ/OMatic/authenticate.pm:91
#, c-format
 "Text parts can only be added by %0."
 => "Додавати текстов╕ частки мають право лише: %0",

#: lib/FAQ/OMatic/authenticate.pm:93
#, c-format
 "Text parts can only be edited by %0."
 => "Редагувати текстов╕ частки мають право лише: %0",

#: lib/FAQ/OMatic/authenticate.pm:96
#, c-format
 "The title and options for this item can only be edited by %0."
 => "Редагувати заголовок та настройки для цього елемента мають право лише: %0",

#: lib/FAQ/OMatic/authenticate.pm:98
#, c-format
 "The moderator options can only be edited by %0."
 => "Редагувати настройки модератора мають право лише: %0",

#: lib/FAQ/OMatic/authenticate.pm:101
 "This item can only be moved by someone who can edit both the source and destination parent items."
 => "Перем╕щувати цей елемент ма╓ право лише той, хто ма╓ право редагувати обидва батьк╕вських елемента (як пох╕дний, так ╕ ц╕льовий).",

#: lib/FAQ/OMatic/authenticate.pm:103
#, c-format
 "This item can only be moved by %0."
 => "Перем╕щувати ц╕й елемент мають право лише: %0",

#: lib/FAQ/OMatic/authenticate.pm:110
#, c-format
 "Existing bags can only be replaced by %0."
 => "Зам╕нювати ╕снуюч╕ \"м╕шки\" мають право лише: %0.",

#: lib/FAQ/OMatic/authenticate.pm:112
#, c-format
 "Bags can only be posted by %0."
 => "Надсилати &quot;м╕шки&quot; мають право лише: %0",

#: lib/FAQ/OMatic/authenticate.pm:115
#, c-format
 "The FAQ-O-Matic can only be configured by %0."
 => "Конф╕гугрувати FAQ-O-Matic мають право: %0.",

#: lib/FAQ/OMatic/authenticate.pm:117
 "The operation you attempted (%0) can only be done by %1."
 => "Операц╕ю, яку ви спробували виконати (%0), мають право виконувати лише: %1",

#: lib/FAQ/OMatic/authenticate.pm:120
 "If you have never established a password to use with FAQ-O-Matic, you can"
 => "Якщо у вас нема╓ свого входу до FAQ-O-Matic'а, ви ма╓те можлив╕сть",

#: lib/FAQ/OMatic/authenticate.pm:121
 "If you have forgotten your password, you can"
 => "Якщо ви забули св╕й пароль, ви ма╓те можлив╕сть",

#: lib/FAQ/OMatic/authenticate.pm:122
 "If you have already logged in earlier today, it may be that the token I use to identify you has expired. Please log in again."
 => "Якщо ви ре╓струвалися (входили) сьогодн╕, то поява цього пов╕домлення означа╓, що ╕дентиф╕катор вашо╖ сес╕╖ вже застар╕в. Будьте ласкав╕, заре╓струйтеся знову.",

#: lib/FAQ/OMatic/authenticate.pm:136
 "Please offer one of the following forms of identification:"
 => "Будьте ласкав╕, надайте одну з посл╕дуючих форм ╕дентиф╕кац╕╖:",

#: lib/FAQ/OMatic/authenticate.pm:139
 "No authentication, but my email address is:"
 => "Без аутентиф╕кац╕╖, лише email-адреса:",

# Intentionally left blank.
#: lib/FAQ/OMatic/authenticate.pm:140
 "Email:"
 => "",

#: lib/FAQ/OMatic/authenticate.pm:147
 "Authenticated login:"
 => "Аутентиф╕кований вх╕д:",

#: lib/FAQ/OMatic/authenticate.pm:149 lib/FAQ/OMatic/changePass.pm:64
 "Password:"
 => "Пароль:",

#: lib/FAQ/OMatic/changePass.pm:48
 "Please enter your username, and select a password."
 => "Будьте ласкав╕, введить ваше ре╓страц╕йне ╕м'я та пароль.",

#: lib/FAQ/OMatic/changePass.pm:49
 "I will send a secret number to the email address you enter to verify that it is valid."
 => "На email-адресу, яку ви запровадите, буде в╕дправлено Те╓мний Код (Secret Number), який вам знадобиться для п╕дтвердження, що ця email-адреса ╕сну╓ ╕ що вона д╕йсно ваша (або, як найменьш╓, ма╓те до не╖ доступ).",

#: lib/FAQ/OMatic/changePass.pm:50
 "If you prefer not to give your email address to this web form, please contact"
 => "Якщо вам не до вподоби запроважувати вашу email-адресу через цю форму, будьте ласкав╕, св'яжитесь з",

#: lib/FAQ/OMatic/changePass.pm:52
 "Please <b>do not</b> use a password you use anywhere else, as it will not be transferred or stored securely!"
 => "Будьте ласкв╕, <b>НЕ ВИКОРИСТОВУЙТЕ</b> пароль, який ви вже використову╓те будь-де, оск╕льки в╕н <b>НЕ БУДЕ</b> передаватися та хранитися достатньо безпечно!",

#: lib/FAQ/OMatic/changePass.pm:66
 "Set Password"
 => "Установити Пароль",

#: lib/FAQ/OMatic/editBag.pm:75
 "Replace bag"
 => "Зам╕нити &quot;м╕шок&quot;",

#: lib/FAQ/OMatic/editBag.pm:81
 "Upload new bag to show in the %0 part in <b>%1</b>."
 => "",

#: lib/FAQ/OMatic/editBag.pm:97
 "Bag name:"
 => "Назва &quot;м╕шка&quot;:",

#: lib/FAQ/OMatic/editBag.pm:99
 "The bag name is used as a filename, so it is restricted to only contain letters, numbers, underscores (_), hyphens (-), and periods (.). It should also carry a meaningful extension (such as .gif) so that web browsers will know what to do with the data."
 => "Назва &quot;м╕шка&quot; використову╓ться, як им'я файла, отже повинна мати лише букви, цифри, знаки п╕дкреслення (`_'), знаки переносу (`-') та крапки (`.').  Вона повинна також включати осмислене поширення (наприклад, .gif), щоб web-бровзер знав, що робити з його вм╕стом.",

#: lib/FAQ/OMatic/editBag.pm:102
 "Bag data:"
 => "Вм╕ст &quot;м╕шка&quot;:",

#: lib/FAQ/OMatic/editBag.pm:105
 "(Leave blank to keep original bag data and change only the associated information below.)"
 => "(Залиште пустим, щоб зберегти вм╕ст \"м╕шку\" незм╕неним, а зм╕нити лише зв'язану з ним ╕нформац╕ю.)",

#: lib/FAQ/OMatic/editBag.pm:110
 "If this bag is an image, fill in its dimensions."
 => "Якщо цей \"м╕шок\" ╓ зображення -- заповнить його розм╕рност╕.",

#: lib/FAQ/OMatic/editBag.pm:111
 "Width:"
 => "Ширина:",

#: lib/FAQ/OMatic/editBag.pm:113
 "Height:"
 => "Висота:",

#: lib/FAQ/OMatic/editPart.pm:146
 "Enter the answer to <b>%0</b>"
 => "Введить в╕дпов╕дь на питання <b>%0</b>",

#: lib/FAQ/OMatic/editPart.pm:148
 "Enter a description for <b>%0</b>"
 => "Введить опис для <b>%0</b>",

#: lib/FAQ/OMatic/editPart.pm:150
 "Edit duplicated text for <b>%0</b>"
 => "Редагування скоп╕йованого тексту для <b>%0</b>",

#: lib/FAQ/OMatic/editPart.pm:152
 "Enter new text for <b>%0</b>"
 => "Введить новий текст для <b>%0</b>",

#: lib/FAQ/OMatic/editPart.pm:157
 "Editing the %0 text part in <b>%1</b>."
 => "Редагування текстово╖ частки N %0 в <b>%1</b>.",

#: lib/FAQ/OMatic/editPart.pm:171
 "If you later need to edit or delete this text, use the [Appearance] page to turn on the expert editing commands."
 => "Якщо вам п╕зн╕ше знадобиться в╕дредагувати або стерти цей текст, використовуйте стор╕нку <code>[Зовн╕шн╕й Вигляд]</code> щоб вв╕мкнути поширен╕ команди редагування.",

#: lib/FAQ/OMatic/install.pm:93
 "Faq-O-Matic Installer"
 => "╤нсталятор FAQ-O-Matic'а",

#: lib/FAQ/OMatic/install.pm:121
#, c-format
 "%0 failed: "
 => "Помилка п╕д час %0: ",

#: lib/FAQ/OMatic/install.pm:127
 "Unknown step: \"%0\"."
 => "Нев╕домий крок: \"%0\".",

#: lib/FAQ/OMatic/install.pm:138
 "Updating config to reflect new meta location <b>%0</b>."
 => "В╕дновлення конф╕гурац╕╖ для в╕дображення нового м╕сцезнаходження каталога meta: <b>%0</b>.",

#: lib/FAQ/OMatic/install.pm:156
 "(Can't find <b>config</b> in '%0' -- assuming this is a new installation.)"
 => "(Не в змоз╕ знайти <b>config</b> в '%0' -- припускаю, що це ╓ нова ╕нсталяц╕я.)",

#: lib/FAQ/OMatic/install.pm:180
#, c-format
 "Click here</a> to create %0."
 => "Клацн╕ть сюди, щоб створити %0.",

#: lib/FAQ/OMatic/install.pm:182
 "If you want to change the CGI stub to point to another directory, edit the script and then"
 => "Якщо ви бажа╓те зм╕нити CGI-скрипт, щоб в╕н вказував на ╕нший каталог, в╕дредагуйте скрипт ╕ п╕сля цього",

#: lib/FAQ/OMatic/install.pm:185
 "click here to use the new location"
 => "клацн╕ть сюди, щоб почати використовувати нове м╕сцезнаходження",

#: lib/FAQ/OMatic/install.pm:187
 "FAQ-O-Matic stores files in two main directories.<p>The <b>meta/</b> directory path is encoded in your CGI stub (%0). It contains:"
 => "FAQ-O-Matic збер╕га╓ файли у двох головних каталогах. <p>Шлях до каталога <b>meta/</b> прописан у вашому CGI-скрипт╕ (%0).  В╕н м╕стить:",

#: lib/FAQ/OMatic/install.pm:188
 "<ul><li>the <b>config</b> file that tells FAQ-O-Matic where everything else lives. That's why the CGI stub needs to know where meta/ is, so it can figure out the rest of its configuration. <li>the <b>idfile</b> file that lists user identities. Therefore, meta/ should not be accessible via the web server. <li>the <b>RCS/</b> subdirectory that tracks revisions to FAQ items. <li>various hint files that are used as FAQ-O-Matic runs. These can be regenerated automatically.</ul>"
 => "<ul><li>файл <b>config</b>, який пов╕домля╓ FAQ-O-Matic, де шукати усе ╕нше.  Через це CGI-скрипт повинен знати де знаходиться каталог meta/, знаюч╕ це в╕н буде у змоз╕ визначити усю ╕ншу конф╕гурац╕ю.  <li>файл <b>idfile</b>, який м╕стить список ╕дентиф╕катор╕в користувач╕в.  Через це meta/ повинен бути НЕ доступним через web-сервер. <li>у п╕дкаталоз╕ <b>RCS/</b> трасируються верс╕╖ елементов FAQ.  <li>р╕зноман╕тн╕ файлы-п╕дказки (hint files), якими користу╓ться працюючий FAQ-O-Matic.  Вони створюються автоматично.</ul>",

#: lib/FAQ/OMatic/install.pm:189
 "<p>The <b>serve/</b> directory contains three subdirectories <b>item/</b>, <b>cache/</b>, and <b>bags/</b>. These directories are created and populated by the FAQ-O-Matic CGI, but should be directly accessible via the web server (without invoking the CGI)."
 => "Каталог <b>serve/</b> м╕стить три п╕дкаталога: <b>item/</b>, <b>cache/</b> та <b>bags/</b>.  Ц╕ п╕дкаталоги створюються та заповнюються FAQ-O-Matic'ом, але повинн╕ бути доступн╕ web-серверов╕ напряму (без звернення до CGI).",

#: lib/FAQ/OMatic/install.pm:190
 "<ul><li>serve/item/ contains only FAQ-O-Matic formatted source files, which encode both user-entered text and the hierarchical structure of the answers and categories in the FAQ. These files are only accessed through the web server (rather than the CGI) when another FAQ-O-Matic is mirroring this one. <li>serve/cache/ contains a cache of automatically-generated HTML versions of FAQ answers and categories. When possible, the CGI directs users to the cache to reduce load on the server. (CGI hits are far more expensive than regular file loads.) <li>serve/bags/ contains image files and other ``bags of bits.'' Bit-bags can be linked to or inlined into FAQ items (in the case of images). </ul>"
 => "<ul><li>serve/item/ м╕стить лише в╕дформатован╕ пох╕дн╕ файли для FAQ-O-Matic'а, як╕ м╕стять як наданий користувачем текст, так ╕ опис ╕╓рарх╕чно╖ структури в╕дпов╕дей та категор╕й FAQ.  Доступ до ц╕х файлов йде лише через web-сервер (на в╕дм╕ну в╕д доступу через CGI) коли який-небудь ╕нший FAQ-O-Matic робить дзеркальну коп╕ю (mirroring) с цього FAQ-O-Matic'a.  <li>serve/cache/ м╕стить кеш автоматично згенерованих HTML верс╕й в╕дпов╕дей та категор╕й FAQ.  Коли можливо, CGI перенаправля╓ користувач╕в до цього кэшу, пом╕ньшуючи, тим самим, навантаження на сервер.  (В╕дпрацьовка CGI потребу╓ набагато б╕льше ресурс╕в, н╕ж просто в╕ддати вже ╕снуючий файл.) <li>serve/bags/ м╕стить файли зображень, чи, ╕ншими словами, &quot;м╕шки с б╕тами&quot; (&quot;bags of bits&quot;).  &quot;М╕шки&quot; можуть бути прив'язан╕ до або вставлен╕ до (якщо це зображення) елемента FAQ. </ul>",

#: lib/FAQ/OMatic/install.pm:202 lib/FAQ/OMatic/install.pm:217
#: lib/FAQ/OMatic/install.pm:276 lib/FAQ/OMatic/install.pm:612
 "I couldn't create <b>%0</b>: %1"
 => "Не вдалося створити <b>%0</b>: %1",

#: lib/FAQ/OMatic/install.pm:206 lib/FAQ/OMatic/install.pm:221
#: lib/FAQ/OMatic/install.pm:615
 "Created <b>%0</b>."
 => "Створено <b>%0</b>.",

#: lib/FAQ/OMatic/install.pm:209 lib/FAQ/OMatic/install.pm:224
#: lib/FAQ/OMatic/install.pm:618
 "I don't have write permission to <b>%0</b>."
 => "Нема╓ прав на запис до <b>%0</b>.",

#: lib/FAQ/OMatic/install.pm:268
 "Created new config file."
 => "Створено новий конф╕гурац╕йний файл.",

#: lib/FAQ/OMatic/install.pm:282
 "The idfile exists."
 => "Файл <code>idfile</code> вже ╕сну╓.",

#: lib/FAQ/OMatic/install.pm:331
 "Configuration Main Menu (install module)"
 => "Конф╕гурац╕я, Головне Меню (модуль ╕нсталяц╕╖)",

#: lib/FAQ/OMatic/install.pm:332
 "Perform these tasks in order to prepare your FAQ-O-Matic version %0:"
 => "Виконайте ц╕ задач╕ для п╕дготовки вашого FAQ-O-Matic'а верс╕╖ %0:",

#: lib/FAQ/OMatic/install.pm:337
 "Define configuration parameters"
 => "Визначити конф╕гурац╕йн╕ параметри",

#: lib/FAQ/OMatic/install.pm:342 lib/FAQ/OMatic/install.pm:347
 "Set your password and turn on installer security"
 => "Установити ваш пароль ╕ вв╕мкнути безпеку ╕нсталятора",

#: lib/FAQ/OMatic/install.pm:348
 "(Need to configure \$mailCommand and \$adminAuth)"
 => "(Необх╕дно сконф╕гурувати \$mailCommand и \$adminAuth)",

#: lib/FAQ/OMatic/install.pm:354
 "(Installer security is on)"
 => "(Безпека ╕нсталятора вв╕мкнена)",

#: lib/FAQ/OMatic/install.pm:359
 "Create item, cache, and bags directories in serve dir"
 => "Создати item, cache, и bags п╕дкаталоги в каталоз╕ serve",

#: lib/FAQ/OMatic/install.pm:367
 "Copy old items</a> from <tt>%0</tt> to <tt>%1</tt>."
 => "Коп╕ювати стар╕ елементи з <tt>%0</tt> до <tt>%1</tt>.",

#: lib/FAQ/OMatic/install.pm:374
 "Install any new items that come with the system"
 => "Поставити ус╕ нов╕ елементи, що йдуть разом ╕з системою.",

#: lib/FAQ/OMatic/install.pm:379
 "Create system default items"
 => "Создати системн╕ елементи по-замовчанню",

#: lib/FAQ/OMatic/install.pm:387 lib/FAQ/OMatic/install.pm:498
 "Rebuild the cache and dependency files"
 => "Пересоздати кеш-файли та файли залежностей",

#: lib/FAQ/OMatic/install.pm:394
 "Install system images and icons"
 => "Установити системн╕ зображення та ╕конки",

#: lib/FAQ/OMatic/install.pm:402
 "Update mirror from master now. (this can be slow!)"
 => "",

#: lib/FAQ/OMatic/install.pm:408
 "Set up the maintenance cron job"
 => "",

#: lib/FAQ/OMatic/install.pm:414 lib/FAQ/OMatic/install.pm:419
 "Run maintenance script manually now"
 => "Виконати обслуговуючий скрипт вручну, зараз",

#: lib/FAQ/OMatic/install.pm:421
 "(Need to set up the maintenance cron job first)"
 => "(Необх╕дно спочатку установити обслуговуючу cron-задачу)",

#: lib/FAQ/OMatic/install.pm:429
 "Maintenance last run at:"
 => "Обслуговуюча задача виконувалась в останн╓:",

#: lib/FAQ/OMatic/install.pm:434
#, c-format
 "Mark the config file as upgraded to Version %0"
 => "Позначити конф╕гурац╕йний файл, як оновлений до верс╕╖ %0",

#: lib/FAQ/OMatic/install.pm:440
 "Select custom colors for your Faq-O-Matic</a> (optional)"
 => "Зм╕нити кольори вашого FAQ-O-Matic'а</a> (не обов'язковий)",

#: lib/FAQ/OMatic/install.pm:444
 "Define groups</a> (optional)"
 => "Визначити групи</a> (не обов'язковий)",

#: lib/FAQ/OMatic/install.pm:450
 "Upgrade to CGI.pm version 2.49 or newer."
 => "В╕дновити CGI.pm до верс╕╖ 2.49 або нов╕шо╖.",

#: lib/FAQ/OMatic/install.pm:453
 "(optional; older versions have bugs that affect bags)"
 => "(не обов'язковий; стар╕ верс╕╖ мають помилку, яка робить &quot;м╕шки&quot; не працездатними)",

#: lib/FAQ/OMatic/install.pm:456
#, c-format
 "You are using version %0 now."
 => "Ви зараз використову╓те верс╕ю %0.",

#: lib/FAQ/OMatic/install.pm:461
 "Bookmark this link to be able to return to this menu."
 => "Зробити закладку до ц╕╓╖ стор╕нки, щоб полегшити повернення до цього меню (працю╓ не на ус╕х бровзерах).",

#: lib/FAQ/OMatic/install.pm:472
 "(need to turn on installer security)"
 => "(необх╕дно, щоби вв╕мкнути безпеку ╕нсталятора)",

#: lib/FAQ/OMatic/install.pm:475
 "Other available tasks:"
 => "╤нш╕ доступн╕ завдання:",

#: lib/FAQ/OMatic/install.pm:479
 "See access statistics"
 => "Подивитися статистику доступу",

#: lib/FAQ/OMatic/install.pm:484
 "Examine all bags"
 => "Перев╕рити ус╕ \"м╕шки\"",

#: lib/FAQ/OMatic/install.pm:490
 "Check for unreferenced bags (not linked by any FAQ item)"
 => "Перев╕рити на \"п╕дв╕шен╕ м╕шки\" (\"м╕шки\", на як╕ нема╓ посилань н╕ з жодного елементу FAQ)",

#: lib/FAQ/OMatic/install.pm:503
#, c-format
 "The Faq-O-Matic modules are version %0."
 => "Модул╕ FAQ-O-Matic мають верс╕ю %0.",

# HERE
# Russian
#: lib/FAQ/OMatic/install.pm:622
 "I wasn't able to change the permissions on <b>%0</b> to 755 (readable/searchable by all)."
 => "[R] Не удалось изменить права доступа к <b>%0</b> на 755 (чтение/поиск для всех).",

#: lib/FAQ/OMatic/install.pm:637 lib/FAQ/OMatic/install.pm:638
 "updated config file:"
 => "оновлений файл конф╕гурац╕╖:",

# Russian
#: lib/FAQ/OMatic/install.pm:645
 "Redefine configuration parameters to ensure that <b>%0</b> is valid."
 => "[R] Переопределите (определите заново?) конфигурационные параметры, дабы быть уверенным, что <b>%0</b> в порядке.",

# Intentionally left blank.
#: lib/FAQ/OMatic/install.pm:657
 "Jon made a mistake here; key=%0, property=%1."
 => "",

#: lib/FAQ/OMatic/install.pm:686
 "<b>Mandatory:</b> System information"
 => "<b>Обов'язковий:</b> ╤нформац╕я про систему",

# Russian
#: lib/FAQ/OMatic/install.pm:689
 "Identity of local FAQ-O-Matic administrator (an email address)"
 => "[R] Идентификатор локального администратора FAQ-O-Matic (email-адрес)",

# Russian
#: lib/FAQ/OMatic/install.pm:691
 "A command FAQ-O-Matic can use to send mail. It must either be sendmail, or it must understand the -s (Subject) switch."
 => "[R] Команда, используемая FAQ-O-Matic'ом для отправки почты.  Это должен быть sendmail или что-нибудь другое, что понимает опцию -s (Subject).",

# Russian
#: lib/FAQ/OMatic/install.pm:693
 "The command FAQ-O-Matic can use to install a cron job."
 => "[R] Команда, которую FAQ-O-Matic может использовать для установки cron job.",

# Russian
#: lib/FAQ/OMatic/install.pm:696
 "Path to the <b>ci</b> command from the RCS package."
 => "[R] Путь к команде <b>ci</b> из пакета RCS.",

#: lib/FAQ/OMatic/install.pm:699
 "<b>Mandatory:</b> Server directory configuration"
 => "<b>Обов'язковий:</b> Конф╕гурац╕я каталог╕в сервера",

#: lib/FAQ/OMatic/install.pm:701
 "Protocol, host, and port parts of the URL to your site. This will be used to construct link URLs. Omit the trailing '/'; for example: <tt>http://www.dartmouth.edu</tt>"
 => "Протокол-, хост- ╕ порт-частини URL, що вказу╓ на ваш сайт.  Вони будуть використовуватися для створення URL в посиланнях.  Не запроваджуйте к╕нцевий '/'; приклад: <tt>http://www.dartmouth.edu</tt>",

#: lib/FAQ/OMatic/install.pm:704
 "The path part of the URL used to access this CGI script, beginning with '/' and omitting any parameters after the '?'. For example: <tt>/cgi-bin/cgiwrap/jonh/faq.pl</tt>"
 => "Частина URL, в╕дпов╕дальна за путь до цього CGI-скрипта.  Повинна починатися з '/' ╕ не м╕стити н╕яких параметр╕в п╕сля '?'.  Приклад: <tt>/cgi-bin/cgiwrap/jonh/faq.pl</tt>",

# Russian
#: lib/FAQ/OMatic/install.pm:707
 "Filesystem directory where FAQ-O-Matic will keep item files, image and other bit-bag files, and a cache of generated HTML files. This directory must be accessible directly via the http server. It might be something like /home/faqomatic/public_html/fom-serve/"
 => "[R] Каталог в файловой системе, где FAQ-O-Matic хранит файлы элементов, изображения и другие \"мешки с битами\", а так же кэширует сгенерированные HTML файлы.  Этот каталог должен быть доступен напрямую через web-сервер.  Это может быть что-нибудь наподобие <code>/home/faqomatic/public_html/fom-serve/</code>",

# Russian
#: lib/FAQ/OMatic/install.pm:709
 "The path prefix of the URL needed to access files in <b>\$serveDir</b>. It should be relative to the root of the server (omit http://hostname:port, but include a leading '/'). It should also end with a '/'."
 => "[R] Префикс пути в URL, необходимый для доступа к файлам, расположенным в <b>\$serveDir</b>.  Он должен быть задан корневого каталога сервера (опуская http://hostname:port, но включая лидирующий '/').  Он должен, также, завершаться на '/'.",

# ? настройки
#: lib/FAQ/OMatic/install.pm:712
 "<i>Optional:</i> Miscellaneous configurations"
 => "<i>Не обов'язковий:</i> Разн╕тн╕ настройки",

# Russian
#: lib/FAQ/OMatic/install.pm:717
 "Select the display language."
 => "[R] Выберите язык для отображения. (Select the display language.)",

# Russian
#: lib/FAQ/OMatic/install.pm:722
 "Show dates in 24-hour time or am/pm format."
 => "[R] Отображать даты в 24-часовом формате, или в формате am/pm.",

# Russian
#: lib/FAQ/OMatic/install.pm:726
 "If this parameter is set, this FAQ will become a mirror of the one at the given URL. The URL should be the base name of the CGI script of the master FAQ-O-Matic."
 => "[R] Если этот параметр установлен, то этот FAQ станет зеркальной копией (mirror) FAQ, находящегося по указанному URL.  URL должен быть базовым именем (base name) CGI-скрипта &quot;ведущего&quot; FAQ-O-Matic'а.",

# Russian
#: lib/FAQ/OMatic/install.pm:728
 "An HTML fragment inserted at the top of each page. You might use this to place a corporate logo."
 => "[R] HTML фрагмент, который вставляется в начало каждой страницы.  Вы можете использовать его, например, для размещения вашего логотипа.",

# Russian
#: lib/FAQ/OMatic/install.pm:730 lib/FAQ/OMatic/install.pm:743
 "If this field begins with <tt>file=</tt>, the text will come from the named file in the meta directory; otherwise, this field is included verbatim."
 => "[R] Если содержимое этого поля начинается с <tt>file=</tt>, то текст будет взят из указанного файла в каталоге meta; в противном случае содержимое поля будет вставлено &quot;как есть&quot;.",

# Russian
#: lib/FAQ/OMatic/install.pm:738
 "The <tt>width=</tt> tag in a table. If your <b>\$pageHeader</b> has <tt>align=left</tt>, you will want to make this empty."
 => "[R] Тег <tt>width=</tt> в таблице.  Если ваш <b>\$pageHeader</b> имеет <tt>align=left</tt>, вы, возможно, пожелаете оставить его пустым.",

# Russian
#: lib/FAQ/OMatic/install.pm:741
 "An HTML fragment appended to the bottom of each page. You might use this to identify the webmaster for this site."
 => "[R] HTML фрагмент, который добавляется в конец каждой страницы.  Вы можете использовать его, например, для сообщения, кто есть webmaster вашего сайта.",

# Russian
#: lib/FAQ/OMatic/install.pm:746
 "Where FAQ-O-Matic should send email when it wants to alert the administrator (usually same as \$adminAuth)"
 => "[R] Куда FAQ-O-Matic должен посылать email, когда он хочет привлечь внимание администратора (обычно, тоже самое, что и \$adminAuth)",

# Russian
#: lib/FAQ/OMatic/install.pm:748
 "If true, FAQ-O-Matic will mail the log file to the administrator whenever it is truncated."
 => "[R] Если 'true', то FAQ-O-Matic будет отсылать log-файл администратору всякий раз при его усечении.",

# Russian
#: lib/FAQ/OMatic/install.pm:751
 "User to use for RCS ci command (default is process UID)"
 => "[R] Пользователь, используемый для RCS-команды <code>ci</code> (по-умолчанию: UID процесса)",

# Russian
#: lib/FAQ/OMatic/install.pm:755
 "Links from cache to CGI are relative to the server root, rather than absolute URLs including hostname:"
 => "[R] Использовать в кэше относительные ссылки на CGI (относительно корневого каталога сервера), вместо абсолютных URL, включающих имя хоста:",

# Russian
#: lib/FAQ/OMatic/install.pm:759
 "mailto: links can be rewritten such as jonhATdartmouthDOTedu (cheesy), jonh (nameonly), or e-mail addresses suppressed entirely (hide)."
 => "[R] Для защиты от spam'а, ссылки <code>mailto:</code> могут искажаться до вида jonhATdartmouthDOTedu (cheesy), jonh (nameonly), или email-адрес может быть скрыт вообще (hide).  'off' означает не искажать ссылки <code>mailto:</code>.",

# Russian
#: lib/FAQ/OMatic/install.pm:763
 "Number of seconds that authentication cookies remain valid. These cookies are stored in URLs, and so can be retrieved from a browser history file. Hence they should usually time-out fairly quickly."
 => "[R] Количество секунд, в течении которых аутентификационные &quot;крошки&quot; (cookies) остаются действительными.  Эти &quot;крошки&quot; сохраняются в URL, и, следовательно, могут быть извлечены из файла истории бровзера (browser history file).  Посему это значение должно быть достаточно небольшим.",

# Russian
#: lib/FAQ/OMatic/install.pm:766
 "<i>Optional:</i> These options set the default [Appearance] modes."
 => "[R] <i>Не обов'язковий:</i> Эти настройки определяют, каким будет <code>[Зовн╕шн╕й Вигляд]</code> по умолчанию.",

# Russian
#: lib/FAQ/OMatic/install.pm:771
 "Page rendering scheme. Do not choose 'text' as the default."
 => "[R] Схема отрисовки страниц.  Не используйте 'text', в качестве схемы по-умолчанию.",

# Russian
#: lib/FAQ/OMatic/install.pm:799
 "<i>Optional:</i> These options fine-tune the appearance of editing features."
 => "[R] <i>Не обов'язковий:</i> &quot;Тонкая&quot; настройка вида команд редактирования.",

# Russian
#: lib/FAQ/OMatic/install.pm:802
 "The old [Show Edit Commands] button appears in the navigation bar."
 => "[R] Старая кнопка <code>[Показать Команды Редактирования]</code> входит в навигационную линейку.",

# Russian
#: lib/FAQ/OMatic/install.pm:806
 "Navigation links appear at top of page as well as at the bottom."
 => "[R] Отображать навигационные ссылки вверху страницы, так же, как и внизу.",

#: lib/FAQ/OMatic/install.pm:810
 "Hide [Append to This Answer] and [Add New Answer in ...] buttons."
 => "Сховати кнопки <code>[Додати до Ц╕╓╖ В╕дпов╕д╕]</code> та <code>[Нова В╕дпов╕дь у ...]</code>",

# Russian
#: lib/FAQ/OMatic/install.pm:815
 "Editing commands appear with neat-o icons rather than [In Brackets]."
 => "[R] Команды редактирования отображаются вместе с иконками, а не <code>[в квадратных скобках]</code>.",

# Russian
#: lib/FAQ/OMatic/install.pm:818
 "<i>Optional:</i> Other configurations that you should probably ignore if present."
 => "[R] <i>Не обов'язковий:</i> Другие настройки, которые вы, возможно, захотите проигнорировать.",

#: lib/FAQ/OMatic/install.pm:822
 "Draw Item titles John Nolan's way."
 => "",

# Russian
#: lib/FAQ/OMatic/install.pm:826
 "Hide sibling (Previous, Next) links"
 => "[R] Спрятать ссылки на предыдущий и следующий документы",

# Russian
#: lib/FAQ/OMatic/install.pm:830
 "Use DBM-based search databases. Faster on machines with non-broken DBM."
 => "[R] Использовать поисковый движок, основанный на DBM.  Он быстрее, но не каждая машина имеет неповрежденный (работающий) DBM.",

# Russian
#: lib/FAQ/OMatic/install.pm:937
 "This is a command, so only letters, hyphens, and slashes are allowed."
 => "[R] Это команда, посему допускаются только буквы, знаки переноса ('-') и слэши ('/').",

# Russian
#: lib/FAQ/OMatic/install.pm:996
 "If this is your first time installing a FAQ-O-Matic, I recommend only filling in the sections marked <b>Mandatory</b>."
 => "[R] Если вы устанавливаете FAQ-O-Matic в первый раз, рекомендуем заполнять только секции, маркированные, как <b>Обязательные</b> (<b>Mandatory</b>).",

#: lib/FAQ/OMatic/install.pm:1000
 "Define"
 => "Установити",

# Russian
#: lib/FAQ/OMatic/install.pm:1041
 "You should <a href=\"%0\">go back</a> and fix these configurations."
 => "[R] Вы должны <a href=\"%0\">вернуться</a> и исправить эти установки.",

#: lib/FAQ/OMatic/install.pm:1044
 "Rewrote configuration file."
 => "Конф╕гурац╕йний файл переписано.",

# Russian
#: lib/FAQ/OMatic/install.pm:1058
 "%0 (%1) has an internal apostrophe, which will certainly make Perl choke on the config file."
 => "[R] %0 (%1) содержит апостроф, который может быть неправильно воспринят Perl'ом внутри конфигурационного файла.",

# Russian
#: lib/FAQ/OMatic/install.pm:1062 lib/FAQ/OMatic/install.pm:1068
 "%0 (%1) doesn't look like a fully-qualified email address."
 => "[R] %0 (%1) не выглядит, как полный email-адрес.",

# Russian
#: lib/FAQ/OMatic/install.pm:1074 lib/FAQ/OMatic/install.pm:1079
 "%0 (%1) isn't executable."
 => "[R] %0 (%1) не является исполнимым файлом.",

# Russian
#: lib/FAQ/OMatic/install.pm:1096
 "%0 has funny characters."
 => "[R] %0 имеет \"опасные\" символы.",

# Russian
#: lib/FAQ/OMatic/install.pm:1125
 "Untitled Faq-O-Matic"
 => "[R] Безымянный Faq-O-Matic",

# Russian
#: lib/FAQ/OMatic/install.pm:1131
 "To name your FAQ-O-Matic, use the [Appearance] page to show the expert editing commands, then click [Edit Category Title and Options]."
 => "[R] Дабы назвать ваш FAQ-O-Matic, используйте страницу [Зовн╕шн╕й Вигляд] и разрешите на ней расширенные команды редактирования, после чего нажмите [Заголовок и Настройки Категории]",

#: lib/FAQ/OMatic/install.pm:1141 lib/FAQ/OMatic/install.pm:1153
#: lib/FAQ/OMatic/install.pm:1165
 "Created category \"%0\"."
 => "Создана категор╕я \"%0\".",

# Russian
#: lib/FAQ/OMatic/install.pm:1143 lib/FAQ/OMatic/install.pm:1155
#: lib/FAQ/OMatic/install.pm:1167
 "<b>%0</b> already contains a file '%1'."
 => "[R] <b>%0</b> уже содержит файл '%1'.",

# Russian
#: lib/FAQ/OMatic/install.pm:1205
 "Copied %0 items from <tt>%1</tt> to <tt>%2</tt>."
 => "[R] Скопировано %0 элементов из <tt>%1</tt> в <tt>%2</tt>.",

# Russian
#: lib/FAQ/OMatic/install.pm:1262
 "Attempting to install cron job:"
 => "[R] Попытка установить cron job:",

# Russian
#: lib/FAQ/OMatic/install.pm:1310
 "I replaced this old crontab line, which appears to be an older one for this same FAQ:"
 => "[R] Была заменена старая строка в файле crontab, которая относилась к этому же FAQ (или была очень на нее похожа)",

#: lib/FAQ/OMatic/install.pm:1319
 "I thought I installed a new cron job, but it didn't appear to take."
 => "",

# Russian
#: lib/FAQ/OMatic/install.pm:1321
 "You better add %0 to some crontab yourself with <b><tt>crontab -e</tt></b>"
 => "[R] Вам лучше добавить \`%0' в какой-нибудь crontab самим с помощью команды <b><tt>crontab -e</tt></b>",

#: lib/FAQ/OMatic/install.pm:1327
 "Cron job installed. The maintenance script should run hourly."
 => "",

# Russian
#: lib/FAQ/OMatic/install.pm:1383
 "Use the <u>%0</u> links to change the color of a feature."
 => "[R] используйте ссылки <u>%0</u>, чтобы изменить соответствующий цвет.",

# Russian
#: lib/FAQ/OMatic/install.pm:1397
 "An Item Title"
 => "[R] Заголовок Элемента",

# Russian
#: lib/FAQ/OMatic/install.pm:1405
 "A regular part is how most of your content will appear. The text colors should be most pleasantly readable on this background."
 => "[R] Обычная текстовая часть.  Почти все содержимое FAQ располагается именно в них.  Цвета текста должны быть подобраны так, чтобы быть наиболее комфортными для чтения.",

# Russian
#: lib/FAQ/OMatic/install.pm:1407 lib/FAQ/OMatic/install.pm:1419
#: lib/FAQ/OMatic/install.pm:1446
 "A new link"
 => "[R] Новая ссылка",

# Russian
#: lib/FAQ/OMatic/install.pm:1408 lib/FAQ/OMatic/install.pm:1420
#: lib/FAQ/OMatic/install.pm:1450
 "A visited link"
 => "[R] Посещенная ссылка",

#: lib/FAQ/OMatic/install.pm:1410 lib/FAQ/OMatic/install.pm:1422
#: lib/FAQ/OMatic/install.pm:1455
 "A search hit"
 => "&quot;Попадання&quot; пошука",

# Russian
#: lib/FAQ/OMatic/install.pm:1418
 "A directory part should stand out"
 => "[R] Часть-каталог.  Она должна выделяться.",

#: lib/FAQ/OMatic/install.pm:1442
 "Regular text"
 => "Звичайний текст",

# Russian
#: lib/FAQ/OMatic/install.pm:1467
 "Select a color for %0:"
 => "[R] Выберите цвет для &quot;%0&quot;",

# Russian
#: lib/FAQ/OMatic/install.pm:1478
 "Or enter an HTML color specification manually:"
 => "[R] Или введите HTML-спецификацию цвета вручную:",

#: lib/FAQ/OMatic/install.pm:1481
 "Select"
 => "Вибрати",

# Russian
#: lib/FAQ/OMatic/install.pm:1490
 "Unrecognized config parameter"
 => "[R] Нераспознанный конфигурационный параметр",

#: lib/FAQ/OMatic/install.pm:1538
#, c-format
 "Proceed to step '%0'"
 => "Пройти до крока '%0'",

#: lib/FAQ/OMatic/moveItem.pm:112
 "Make <b>%0</b> belong to which other item?"
 => "",

#: lib/FAQ/OMatic/moveItem.pm:116
 "No item that already has sub-items can become the parent of"
 => "",

#: lib/FAQ/OMatic/moveItem.pm:118
 "No item can become the parent of"
 => "",

# Russian
#: lib/FAQ/OMatic/moveItem.pm:122
 "Some destinations are not available (not clickable) because you do not have permission to edit them as currently authorized."
 => "[R] Некоторые цели недоступны (на них нельзя щелкнуть), поскольку вы не имеете достаточно прав для их редактирования (по крайней мере под тем идентификатором, под которым вы сейчас вошли).",

#: lib/FAQ/OMatic/moveItem.pm:125
 "Click here</a> to provide better authentication."
 => "",

#: lib/FAQ/OMatic/moveItem.pm:131
 "Hide answers, show only categories"
 => "Сховати в╕дпов╕д╕, показувати лише категор╕╖",

#: lib/FAQ/OMatic/moveItem.pm:134
 "Show both categories and answers"
 => "Показувати як катагор╕╖, так ╕ в╕дпов╕д╕",

# Russian
#: lib/FAQ/OMatic/search.pm:72
 "No items matched all of these words"
 => "[R] Не найдено ни одного документа, удовлетворяющего всем заданным словам",

# Russian
#: lib/FAQ/OMatic/search.pm:76
#, c-format
 "No items matched at least %0 of these words"
 => "[R] Не найдено ни одного документа, удовлетворяющего, как минимум, %0 из заданных слов",

# Russian
#: lib/FAQ/OMatic/search.pm:85
 "Search results for all of these words"
 => "[R] Результаты поиска документов, удовлетворяющих всем заданным словам",

# Russian
#: lib/FAQ/OMatic/search.pm:89
#, c-format
 "Search results for at least %0 of these words"
 => "[R] Результаты поиска документов, удовлетворяющих, как минимум, %0 из заданных слов",

# Russian
#: lib/FAQ/OMatic/search.pm:106
 "Results may be incomplete, because the search index has not been refreshed since the most recent change to the database."
 => "[R] Результат может быть неполон, поскольку поисковый индекс не успел обновиться после самого свежего изменения в базе данных.",

# Russian
#: lib/FAQ/OMatic/searchForm.pm:52
 "search for keywords"
 => "[R] поиск по ключевым словам",

#: lib/FAQ/OMatic/searchForm.pm:57
 "Search for"
 => "Шукати",

#: lib/FAQ/OMatic/searchForm.pm:58
 "matching"
 => "повинн╕ сп╕впадати:",

#: lib/FAQ/OMatic/searchForm.pm:60
 "all"
 => "ус╕",

#: lib/FAQ/OMatic/searchForm.pm:61
 "any"
 => "будь-яке",

#: lib/FAQ/OMatic/searchForm.pm:62
 "two"
 => "два",

#: lib/FAQ/OMatic/searchForm.pm:63
 "three"
 => "три",

#: lib/FAQ/OMatic/searchForm.pm:64
 "four"
 => "чотири",

#: lib/FAQ/OMatic/searchForm.pm:65
 "five"
 => "п'ять",

#: lib/FAQ/OMatic/searchForm.pm:67
 "words"
 => "слов(а,о)/сл╕в",

#: lib/FAQ/OMatic/searchForm.pm:75
 "search for recent changes"
 => "пошук св╕жих зм╕н",

#: lib/FAQ/OMatic/searchForm.pm:81
 "Show documents"
 => "Показати документи",

#: lib/FAQ/OMatic/searchForm.pm:82
 "modified in the last"
 => "яких було зм╕нено за останн╕(й)",

#: lib/FAQ/OMatic/searchForm.pm:84
 "day"
 => "день",

#: lib/FAQ/OMatic/searchForm.pm:85
 "two days"
 => "два дня",

#: lib/FAQ/OMatic/searchForm.pm:86
 "three days"
 => "три дня",

#: lib/FAQ/OMatic/searchForm.pm:87
 "week"
 => "тиждень",

#: lib/FAQ/OMatic/searchForm.pm:88
 "fortnight"
 => "два тиждя",

#: lib/FAQ/OMatic/searchForm.pm:89
 "month"
 => "м╕сяць",

#: lib/FAQ/OMatic/selectBag.pm:69
 "Replace which bag?"
 => "",

#: lib/FAQ/OMatic/stats.pm:69
 "Hits Per Day"
 => "",

#: lib/FAQ/OMatic/stats.pm:70
 "Cumulative Hits"
 => "",

#: lib/FAQ/OMatic/stats.pm:74
 "New Hosts Per Day"
 => "",

#: lib/FAQ/OMatic/stats.pm:75
 "Total Hosts"
 => "",

#: lib/FAQ/OMatic/stats.pm:79
 "Hits Per Host"
 => "",

#: lib/FAQ/OMatic/stats.pm:80
 "Cumulative Searches"
 => "",

#: lib/FAQ/OMatic/stats.pm:83
 "Submissions Per Day"
 => "",

#: lib/FAQ/OMatic/stats.pm:84
 "Cumulative Submissions"
 => "",

# Russian
#: lib/FAQ/OMatic/stats.pm:87
 "Please be patient ... the image files are generated dynamically, and can take from 20 to 50 seconds to create.\n"
 => "[R] Пожалуйста, будьте терпеливы... изображения генерируются динамически, и на их создание может потребоваться от 20 до 50 секунд.\n",

#: lib/FAQ/OMatic/stats.pm:137
 "Change View Duration"
 => "",

#: lib/FAQ/OMatic/stats.pm:140
 "One Month"
 => "",

#: lib/FAQ/OMatic/stats.pm:142
 "Two Months"
 => "",

#: lib/FAQ/OMatic/stats.pm:144
 "Three Months"
 => "",

#: lib/FAQ/OMatic/stats.pm:146
 "History"
 => "",

# Russian
#: lib/FAQ/OMatic/submitBag.pm:50
 "Bag names may only contain letters, numbers, underscores (_), hyphens (-), and periods (.), and may not end in '.desc'. Yours was"
 => "[R] Названия \"мешков\" могут содержать только буквы, цифры, знаки подчеркивания (_), знаки переноса (-) и точки (.), и не могут заканчиваться на '.desc'.  Ваше было",

#: lib/FAQ/OMatic/submitItem.pm:61
 "Your browser or WWW cache has truncated your POST."
 => "",

# Russian
#: lib/FAQ/OMatic/submitItem.pm:72
 "Changed the item title, was \"%0\""
 => "[R] Изменен заголовок элемента, было \"%0\"",

#: lib/FAQ/OMatic/submitItem.pm:88 lib/FAQ/OMatic/submitItem.pm:98
 "Your part order list (%0) "
 => "",

#: lib/FAQ/OMatic/submitItem.pm:89
 "doesn't have the same number of parts (%0) as the original item."
 => "",

#: lib/FAQ/OMatic/submitItem.pm:99
#, c-format
 "doesn't say what to do with part %0."
 => "",

# Russian
#: lib/FAQ/OMatic/submitMove.pm:51
 "The moving file (%0) is broken or missing."
 => "[R] Перемещаемый файл (%0) поврежден или отсутствует.",

#: lib/FAQ/OMatic/submitMove.pm:57
 "The newParent file (%0) is broken or missing."
 => "",

#: lib/FAQ/OMatic/submitMove.pm:66
 "The oldParent file (%0) is broken or missing."
 => "",

#: lib/FAQ/OMatic/submitMove.pm:74
 "The new parent (%0) is the same as the old parent."
 => "",

#: lib/FAQ/OMatic/submitMove.pm:79
 "The new parent (%0) is the same as the item you want to move."
 => "",

#: lib/FAQ/OMatic/submitMove.pm:86
 "The new parent (%0) is a child of the item being moved (%1)."
 => "",

# Russian
#: lib/FAQ/OMatic/submitMove.pm:92
 "You can't move the top item."
 => "[R] Вы не можете перемещать верхний элемент.",

# Russian
#: lib/FAQ/OMatic/submitMove.pm:130
#, c-format
 "moved a sub-item to %0"
 => "[R] перемещен, как подэлемент в %0",

# Russian
#: lib/FAQ/OMatic/submitMove.pm:133
#, c-format
 "moved a sub-item from %0"
 => "[R] перемещен, как подэлемент из %0",

#: lib/FAQ/OMatic/submitPass.pm:49
 "An email address must look like 'name\@some.domain'."
 => "Email-адреса повинна мати вигляд 'name\@some.domain'.",

# Russian
#: lib/FAQ/OMatic/submitPass.pm:51
 "If yours (%0) does and I keep rejecting it, please mail %1 and tell him what's happening."
 => "[R] Если вид вашего email (%0) удовлетворяет этому критерию, но все-равно отвергается, пожалуйста, напишите %1 и расскажите ему, что произошло (только, пожалуйста, пишите по-английски!)",

# Russian
#: lib/FAQ/OMatic/submitPass.pm:58
 "Your password may not contain spaces or carriage returns."
 => "[R] Ваш пароль не может содержать пробелов и возвратов каретки.",

# Russian
#: lib/FAQ/OMatic/submitPass.pm:90
 "Your Faq-O-Matic authentication secret"
 => "[R] ",

# Russian
#: lib/FAQ/OMatic/submitPass.pm:113
 "I couldn't mail the authentication secret to \"%0\" and I'm not sure why."
 => "[R] Не удалось отправить аутентификационный Секретный Код на \"%0\" и нет никакой уверенности почему.",

# Russian
#: lib/FAQ/OMatic/submitPass.pm:123
 "The secret you entered is not correct."
 => "[R] Секретный Код, который вы ввели -- неправильный.",

# Russian
#: lib/FAQ/OMatic/submitPass.pm:125
 "Did you copy and paste the secret or the URL completely?"
 => "[R] Вы уверены, что скопировали Секретный Код или URL полностью?",

# Russian
#: lib/FAQ/OMatic/submitPass.pm:129
 "I sent email to you at \"%0\". It should arrive soon, containing a URL."
 => "[R] На ваш адрес \"%0\" было послано письмо.  Оно должно скоро прийти и содержать в себе URL.",

# Russian
#: lib/FAQ/OMatic/submitPass.pm:133
 "Either open the URL directly, or paste the secret into the form below and click Validate."
 => "[R] Или откройте этот URL напрямую, или скопируйте Секретный Код (Secret) в расположенную ниже форму и нажмите <code>[Проверить]</code>.",

# Russian
#: lib/FAQ/OMatic/submitPass.pm:135
 "Thank you for taking the time to sign up."
 => "[R] Спасибо, что нашли время подписаться.",

# Russian
#: lib/FAQ/OMatic/submitPass.pm:143
 "Secret:"
 => "[R] Секретный Код:",


);  # end of %data hash

    my $msgid;

    foreach $msgid (keys(%data))
    {
        $tx->{$msgid} = $data{$msgid};
    }
    return 1;
}
