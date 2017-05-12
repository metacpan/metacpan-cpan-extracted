#--------------------------------------------------------------------
#   Language_ru.pm
#   Generated automatically from ru.po by po2pm
#--------------------------------------------------------------------

sub translations {
    my $tx = shift;

    my %data = (

# Russian translation for FAQ-O-Matic.
# Translated by Andrew W. Nosenko <awn@bcs.zp.ua>, 2001
#
# ATTENTION: don't remove fuzzy mark from this startup entry!
#, fuzzy
 ""
# fuzzy # => "Project-Id-Version: faqomatic 2.711_01\nPOT-Creation-Date: 2001-10-05 03:43+0300\nPO-Revision-Date: 2001-08-06 19:55+0300\nLast-Translator: FULL NAME <EMAIL@ADDRESS>\nLanguage-Team: Russian <someone@somewhere.org>\nMIME-Version: 1.0\nContent-Type: text/plain; charset=koi8-r\nContent-Transfer-Encoding: 8bit\n",
 => "",

#: lib/FAQ/OMatic.pm:95 lib/FAQ/OMatic/install.pm:1040
 "Warnings:"
 => "Предупреждения:",

#: lib/FAQ/OMatic.pm:135 lib/FAQ/OMatic/authenticate.pm:151
 "Log In"
 => "Войти",

#: lib/FAQ/OMatic.pm:136
 "Change Password"
 => "Изменить Пароль",

#: lib/FAQ/OMatic.pm:137
#, c-format
 "Edit Title of %0 %1"
 => "%0 %1: Редактирование заголовка",

# Intentionally left blank
#: lib/FAQ/OMatic.pm:138
#, c-format
 "New %0"
 => "",

#: lib/FAQ/OMatic.pm:139
#, c-format
 "Edit Part in %0 %1"
 => "%0 %1: Редактирование части",

#: lib/FAQ/OMatic.pm:140
#, c-format
 "Insert Part in %0 %1"
 => "%0 %1: Вставка части",

#: lib/FAQ/OMatic.pm:141
#, c-format
 "Move %0 %1"
 => "%0 %1: Перемещение",

#: lib/FAQ/OMatic.pm:142 lib/FAQ/OMatic/Appearance.pm:168
 "Search"
 => "Поиск",

#: lib/FAQ/OMatic.pm:143
 "Access Statistics"
 => "Статистика доступа",

#: lib/FAQ/OMatic.pm:144 lib/FAQ/OMatic/submitPass.pm:145
 "Validate"
 => "Проверить",

#: lib/FAQ/OMatic.pm:145
 "%0 Permissions for %1"
 => "%0 %1: Настройки и права доступа",

#: lib/FAQ/OMatic.pm:146
#, c-format
 "Upload bag for %0 %1"
 => "",

#: lib/FAQ/OMatic/Appearance.pm:177
 "Appearance"
 => "Внешний Вид",

#: lib/FAQ/OMatic/Appearance.pm:191
 "Show Top Category Only"
 => "Показать Только Верхнюю Категорию",

#: lib/FAQ/OMatic/Appearance.pm:198
 "Show This <em>Entire</em> Category"
 => "Показать Эту Категорию <em>Всплошную</em>",

#: lib/FAQ/OMatic/Appearance.pm:209
 "Show This Category As Text"
 => "Показать Эту Категорию Как Текст",

#: lib/FAQ/OMatic/Appearance.pm:213
 "Show This Answer As Text"
 => "Показать Этот Ответ Как Текст",

# Intentionally left blank.
#: lib/FAQ/OMatic/Appearance.pm:218
 "Show This %0 As Text"
 => "",

#: lib/FAQ/OMatic/Appearance.pm:232
 "Show This <em>Entire</em> Category As Text"
 => "Показать Эту Категорию <em>Всплошную</em> Как Текст",

#: lib/FAQ/OMatic/Appearance.pm:244
 "Hide Expert Edit Commands"
 => "Спрятать Расширенные Команды Редактирования",

#: lib/FAQ/OMatic/Appearance.pm:253
 "Show Expert Edit Commands"
 => "Показать Расширенные Команды Редактирования",

#: lib/FAQ/OMatic/Appearance.pm:269 lib/FAQ/OMatic/Item.pm:1955
#: lib/FAQ/OMatic/stats.pm:133
 "Return to the FAQ"
 => "Вернуться в FAQ",

#: lib/FAQ/OMatic/Appearance.pm:276
 "This is a"
 => "Это",

#: lib/FAQ/OMatic/Auth.pm:475
 "the administrator of this Faq-O-Matic"
 => "администратор этого FAQ-O-Matic'а",

#: lib/FAQ/OMatic/Auth.pm:476
 "someone who has proven their identification"
 => "кто-угодно, кто успешно прошел идентификацию",

#: lib/FAQ/OMatic/Auth.pm:477
 "someone who has offered identification"
 => "кто-угодно, идентифицировавший себя (достаточно email-адреса)",

#: lib/FAQ/OMatic/Auth.pm:478
 "anybody"
 => "кто угодно",

#: lib/FAQ/OMatic/Auth.pm:491
 "the moderator of the item"
 => "модератор",

#: lib/FAQ/OMatic/Auth.pm:495
#, c-format
 "%0 group members"
 => "члены группы %0",

#: lib/FAQ/OMatic/Groups.pm:142
 "Select a group to edit:"
 => "Выберите группу для редактирования:",

#: lib/FAQ/OMatic/Groups.pm:150
 "(Members of this group are allowed to access these group definition pages.)"
 => "(Члены этой группы имеют доступ к этой странице определения групп.)",

#: lib/FAQ/OMatic/Groups.pm:168
 "Add Group"
 => "Добавить группу",

#: lib/FAQ/OMatic/Groups.pm:175
 "Up To List Of Groups"
 => "Наверх к Списку Групп",

#: lib/FAQ/OMatic/Groups.pm:187
 "Remove Member"
 => "Удалить Члена Группы",

#: lib/FAQ/OMatic/Groups.pm:196
 "Add Member"
 => "Добавить Члена Группы",

#: lib/FAQ/OMatic/Groups.pm:206 lib/FAQ/OMatic/install.pm:466
#: lib/FAQ/OMatic/install.pm:470
 "Go to the Faq-O-Matic"
 => "Перейти к Faq-O-Matic'у",

#: lib/FAQ/OMatic/Groups.pm:209
 "Go To Install/Configuration Page"
 => "Перейти к странице Установок и Конфигурации",

#: lib/FAQ/OMatic/Item.pm:74
 "New Item"
 => "(Элемент без названия)",

#: lib/FAQ/OMatic/Item.pm:630
 "Parts"
 => "Части",

#: lib/FAQ/OMatic/Item.pm:749
 "Previous"
 => "Предыдущий документ",

#: lib/FAQ/OMatic/Item.pm:767
 "Next"
 => "Следующий документ",

#: lib/FAQ/OMatic/Item.pm:861 lib/FAQ/OMatic/Item.pm:1268
#: lib/FAQ/OMatic/Item.pm:1452
 "Moderator"
 => "Модератор",

#: lib/FAQ/OMatic/Item.pm:862
 "(inherited from parent)"
 => "(наследуется из родительского элемента)",

#: lib/FAQ/OMatic/Item.pm:876
 "Category Title and Options"
 => "Заголовок и Настройки Категории",

#: lib/FAQ/OMatic/Item.pm:877
 "Edit Category Permissions"
 => "Редактировать Права Доступа для Категории",

#: lib/FAQ/OMatic/Item.pm:878
 "Move Category"
 => "Переместить Категорию",

#: lib/FAQ/OMatic/Item.pm:879
 "Trash Category"
 => "Выбросить Категорию",

#: lib/FAQ/OMatic/Item.pm:883
 "Answer Title and Options"
 => "Заголовок и Настройки Ответа",

#: lib/FAQ/OMatic/Item.pm:884
 "Edit Answer Permissions"
 => "Редактировать Права Доступа для Ответа",

#: lib/FAQ/OMatic/Item.pm:885
 "Move Answer"
 => "Переместить Ответ",

#: lib/FAQ/OMatic/Item.pm:886
 "Trash Answer"
 => "Выбросить Ответ",

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
 => "Сдублировать Ответ ",

#: lib/FAQ/OMatic/Item.pm:935
 "Duplicate Category as Answer"
 => "Сдублировать Категорию как Ответ",

#: lib/FAQ/OMatic/Item.pm:978
 "Convert to Answer"
 => "Преобразовать в Ответ",

#: lib/FAQ/OMatic/Item.pm:988
 "Convert to Category"
 => "Преобразовать в Категорию",

#: lib/FAQ/OMatic/Item.pm:1004 lib/FAQ/OMatic/Item.pm:1084
 "New Answer in \"%0\""
 => "Добавить новую пару Вопрос/Ответ в \"%0\"",

#: lib/FAQ/OMatic/Item.pm:1011
 "New Subcategory of \"%0\""
 => "Добавить Новую Подкатегорию в \"%0\"",

#: lib/FAQ/OMatic/Item.pm:1037 lib/FAQ/OMatic/Part.pm:342
 "Insert Text Here"
 => "Вставить Текст Сюда",

#: lib/FAQ/OMatic/Item.pm:1050 lib/FAQ/OMatic/Part.pm:353
 "Insert Uploaded Text Here"
 => "",

#: lib/FAQ/OMatic/Item.pm:1100
 "Append to This Answer"
 => "Добавить к этому Ответу",

#: lib/FAQ/OMatic/Item.pm:1216
 "This document is:"
 => "Этот документ:",

#: lib/FAQ/OMatic/Item.pm:1218
 "This document is at:"
 => "Этот документ доступен на:",

#: lib/FAQ/OMatic/Item.pm:1262
#, c-format
 "Group %0"
 => "Группа %0",

#: lib/FAQ/OMatic/Item.pm:1266
 "Users giving their names"
 => "Пользователи, предоставившие свои имена",

#: lib/FAQ/OMatic/Item.pm:1267
 "Authenticated users"
 => "Аутентифицированные пользователи",

#: lib/FAQ/OMatic/Item.pm:1282
 "New Category"
 => "Новая Категория",

#: lib/FAQ/OMatic/Item.pm:1284
 "New Answer"
 => "Новый Ответ",

#: lib/FAQ/OMatic/Item.pm:1288
 "Editing Category <b>%0</b>"
 => "Редактирование Категории <b>\"%0\"</b>",

#: lib/FAQ/OMatic/Item.pm:1292
 "Editing Answer <b>%0</b>"
 => "Редактирование Ответа <b>\"%0\"</b>",

# Intentionally left blank.
#: lib/FAQ/OMatic/Item.pm:1297
 "Editing %0 <b>%1</b>"
 => "",

#: lib/FAQ/OMatic/Item.pm:1327
 "Title:"
 => "Заголовок:",

#: lib/FAQ/OMatic/Item.pm:1332
 "<p>New Order for Text Parts:"
 => "<p>Новый порядок для текстовых частей:",

#: lib/FAQ/OMatic/Item.pm:1344
 "Show attributions from all parts together at bottom"
 => "Показывать подписи, собранные из всех частей, вместе внизу (Show attributions from all parts together at bottom)",

#: lib/FAQ/OMatic/Item.pm:1357 lib/FAQ/OMatic/Item.pm:1511
#: lib/FAQ/OMatic/Part.pm:556 lib/FAQ/OMatic/editBag.pm:118
 "Submit Changes"
 => "Внести Изменения",

#: lib/FAQ/OMatic/Item.pm:1358 lib/FAQ/OMatic/Item.pm:1512
#: lib/FAQ/OMatic/Part.pm:557 lib/FAQ/OMatic/editBag.pm:119
 "Revert"
 => "Откатить",

#: lib/FAQ/OMatic/Item.pm:1378
 "Who can add a new text part to this item:"
 => "Кто может добавлять новую текстовую часть к этому элементу:",

#: lib/FAQ/OMatic/Item.pm:1380
 "Who can add a new answer or category to this category:"
 => "Кто может добавлять новый ответ или категорию в эту категорию:",

#: lib/FAQ/OMatic/Item.pm:1382
 "Who can edit or remove existing text parts from this item:"
 => "Кто может редактировать или удалять существующие текстовые части в этом элементе:",

#: lib/FAQ/OMatic/Item.pm:1384
 "Who can move answers or subcategories from this category; or turn this category into an answer or vice versa:"
 => "Кто может перемещать ответы или подкатегории из этой категории; или \"превращать\" эту категорию в ответ и наоборот:",

#: lib/FAQ/OMatic/Item.pm:1386
 "Who can edit the title and options of this answer or category:"
 => "Кто может редактировать заголовок и изменять настройки этого ответа или категории:",

#: lib/FAQ/OMatic/Item.pm:1388
 "Who can use untranslated HTML when editing the text of this answer or category:"
 => "Кто может использовать \"чистый\" HTML при редактировании текста этого ответа или категории:",

#: lib/FAQ/OMatic/Item.pm:1390
 "Who can change these moderator options and permissions:"
 => "Кто может изменять эти настройки и права доступа модератора:",

#: lib/FAQ/OMatic/Item.pm:1392
 "Who can create new bags:"
 => "Кто может создавать новые \"мешки\":",

#: lib/FAQ/OMatic/Item.pm:1394
 "Who can replace existing bags:"
 => "Кто может заменять существующие \"мешки\":",

#: lib/FAQ/OMatic/Item.pm:1396
 "Who can access the installation/configuration page (use caution!):"
 => "Кто имеет доступ Странице Установок и Настроек (используйте с осторожностью!):",

#: lib/FAQ/OMatic/Item.pm:1398
 "Who can use the group membership pages:"
 => "Кто может использовать страницы управления членством в группах:",

#: lib/FAQ/OMatic/Item.pm:1415
 "Moderator options for category"
 => "Настройки модератора для категории",

#: lib/FAQ/OMatic/Item.pm:1419
 "Moderator options for answer"
 => "Настройки модератора для ответа",

# Intentionally left blank
#: lib/FAQ/OMatic/Item.pm:1424
 "Moderator options for"
 => "Настройки модератора для",

#: lib/FAQ/OMatic/Item.pm:1442
 "Name & Description"
 => "Название и Описание",

#: lib/FAQ/OMatic/Item.pm:1443
 "Setting"
 => "Установка",

#: lib/FAQ/OMatic/Item.pm:1444
 "Setting if Inherited"
 => "Установка если \"Наследовать\"",

#: lib/FAQ/OMatic/Item.pm:1453
 "(will inherit if empty)"
 => "(будет унаследовано, если оставить пустым)",

#: lib/FAQ/OMatic/Item.pm:1463
 "Send mail to the moderator when someone other than the moderator edits this item:"
 => "Посылать почту модератору, когда кто-то иной (не модератор), редактирует этот элемент:",

#: lib/FAQ/OMatic/Item.pm:1469
 "No"
 => "Нет",

#: lib/FAQ/OMatic/Item.pm:1469
 "Yes"
 => "Да",

#: lib/FAQ/OMatic/Item.pm:1469 lib/FAQ/OMatic/Item.pm:1505
 "undefined"
 => "неопределено",

#: lib/FAQ/OMatic/Item.pm:1474
 "Permissions"
 => "Права Доступа",

#: lib/FAQ/OMatic/Item.pm:1496
 "Blah blah"
 => "Мама мыла раму ;-)",

#: lib/FAQ/OMatic/Item.pm:1500 lib/FAQ/OMatic/Item.pm:1504
 "Relax"
 => "",

#: lib/FAQ/OMatic/Item.pm:1500 lib/FAQ/OMatic/Item.pm:1504
 "Don't Relax"
 => "",

#: lib/FAQ/OMatic/Item.pm:1500
 "Inherit"
 => "Наследовать",

#: lib/FAQ/OMatic/Item.pm:1534 lib/FAQ/OMatic/Item.pm:1548
 "(system default)"
 => "(системный по-умолчанию)",

#: lib/FAQ/OMatic/Item.pm:1540
 "defined in"
 => "определен в",

#: lib/FAQ/OMatic/Item.pm:1617
#, c-format
 "File %0 seems broken."
 => "Файл %0 выглядит поврежденным.",

#: lib/FAQ/OMatic/Item.pm:1886
 "Category"
 => "Категория",

#: lib/FAQ/OMatic/Item.pm:1887
 "Answer"
 => "Ответ",

#: lib/FAQ/OMatic/Item.pm:1957
 "Either someone has changed the answer or category you were editing since you received the editing form, or you submitted the same form twice"
 => "Либо кто-то изменил ответ или категорию, который(ую) вы редактировали после того, как вы начали заполнять форму; или вы отослали одну и ту же форму дважды.",

#: lib/FAQ/OMatic/Item.pm:1959
 "Please %0 and start again to make sure no changes are lost. Sorry for the inconvenience."
 => "Пожалуйста, %0 и начните сначала, дабы быть уверенным, что изменения не потерялись.  Извините за неудобство.",

#: lib/FAQ/OMatic/Item.pm:1962
 "(Sequence number in form: %0; in item: %1)"
 => "(Последовательный номер в форме: %0; в элементе: %1)",

#: lib/FAQ/OMatic/Part.pm:266
 "Edit This Text"
 => "Редактировать Этот Текст",

#: lib/FAQ/OMatic/Part.pm:277
 "Duplicate This Text"
 => "Сдублировать Этот Текст",

#: lib/FAQ/OMatic/Part.pm:288 lib/FAQ/OMatic/Part.pm:301
 "Remove This Text"
 => "Удалить Этот Текст",

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
 => "Предупреждение: содержимое файла <b>заменит</b> предыдущий текст",

#: lib/FAQ/OMatic/Part.pm:506
 "Hide Attributions"
 => "Спрятать подписи",

#: lib/FAQ/OMatic/Part.pm:509
 "Format text as:"
 => "Форматировать текст как:",

#: lib/FAQ/OMatic/Part.pm:519
 "Directory"
 => "Каталог",

#: lib/FAQ/OMatic/Part.pm:526
 "Natural text"
 => "Естественный текст",

#: lib/FAQ/OMatic/Part.pm:530
 "Monospaced text (code, tables)"
 => "Моноширинный текст (исходные тексты, таблицы)",

#: lib/FAQ/OMatic/Part.pm:545
 "Untranslated HTML"
 => "\"Чистый\" HTML",

#: lib/FAQ/OMatic/Part.pm:695 lib/FAQ/OMatic/addItem.pm:85
#: lib/FAQ/OMatic/install.pm:1138 lib/FAQ/OMatic/submitAnsToCat.pm:67
 "Answers in this category:"
 => "Ответы в этой категории:",

#: lib/FAQ/OMatic/Slow.pm:137
 "This page will reload every %0 seconds, showing the last %1 lines of the process output."
 => "Эта страница будет автоматически перечитываться каждые %0 секунд, показывая последние %1 строк вывода процесса.",

#: lib/FAQ/OMatic/Slow.pm:141
 "Show the entire process log"
 => "Показать вывод процесса целиком",

#: lib/FAQ/OMatic/addItem.pm:48 lib/FAQ/OMatic/delPart.pm:47
#: lib/FAQ/OMatic/editItem.pm:50 lib/FAQ/OMatic/editModOptions.pm:50
#: lib/FAQ/OMatic/faq.pm:74 lib/FAQ/OMatic/moveItem.pm:50
#: lib/FAQ/OMatic/selectBag.pm:60 lib/FAQ/OMatic/submitAnsToCat.pm:49
#: lib/FAQ/OMatic/submitCatToAns.pm:48 lib/FAQ/OMatic/submitItem.pm:48
#: lib/FAQ/OMatic/submitModOptions.pm:46 lib/FAQ/OMatic/submitPart.pm:47
 "The file (%0) doesn't exist."
 => "Файл (%0) не существует.",

#: lib/FAQ/OMatic/addItem.pm:67
 "Copy of"
 => "Копия",

#: lib/FAQ/OMatic/addItem.pm:85 lib/FAQ/OMatic/install.pm:1138
#: lib/FAQ/OMatic/submitAnsToCat.pm:67
 "Subcategories:"
 => "Подкатегории:",

#: lib/FAQ/OMatic/appearanceForm.pm:46
 "Appearance Options"
 => "Настройки Внешнего Вида",

#: lib/FAQ/OMatic/appearanceForm.pm:60 lib/FAQ/OMatic/appearanceForm.pm:64
#: lib/FAQ/OMatic/appearanceForm.pm:68 lib/FAQ/OMatic/appearanceForm.pm:84
#: lib/FAQ/OMatic/appearanceForm.pm:92
 "Show"
 => "Показать",

#: lib/FAQ/OMatic/appearanceForm.pm:60
 "Compact"
 => "Компактно",

#: lib/FAQ/OMatic/appearanceForm.pm:60 lib/FAQ/OMatic/appearanceForm.pm:64
#: lib/FAQ/OMatic/appearanceForm.pm:68 lib/FAQ/OMatic/appearanceForm.pm:84
#: lib/FAQ/OMatic/appearanceForm.pm:92
 "Hide"
 => "Спрятать",

#: lib/FAQ/OMatic/appearanceForm.pm:62 lib/FAQ/OMatic/install.pm:776
 "expert editing commands"
 => "расширенные команды редактирования",

#: lib/FAQ/OMatic/appearanceForm.pm:66 lib/FAQ/OMatic/install.pm:781
 "name of moderator who organizes current category"
 => "имя модератора, управляющего текущей категорией",

#: lib/FAQ/OMatic/appearanceForm.pm:70 lib/FAQ/OMatic/install.pm:786
 "last modified date"
 => "дату последней модификации",

#: lib/FAQ/OMatic/appearanceForm.pm:84
 "Default"
 => "По умолчанию",

#: lib/FAQ/OMatic/appearanceForm.pm:86 lib/FAQ/OMatic/install.pm:791
 "attributions"
 => "подписи",

#: lib/FAQ/OMatic/appearanceForm.pm:88
 "Simple"
 => "Простой",

#: lib/FAQ/OMatic/appearanceForm.pm:88
 "Fancy"
 => "Прихотливый",

#: lib/FAQ/OMatic/appearanceForm.pm:94 lib/FAQ/OMatic/install.pm:796
 "commands for generating text output"
 => "команды для генерации текстового вывода",

#: lib/FAQ/OMatic/appearanceForm.pm:126
 "Accept"
 => "Принять",

#: lib/FAQ/OMatic/authenticate.pm:55
 "Set a New Password"
 => "Установить Новый Пароль",

#: lib/FAQ/OMatic/authenticate.pm:60
 "Create a New Login"
 => "Создать Новый Вход",

#: lib/FAQ/OMatic/authenticate.pm:63
 "That password is invalid. If you've forgotten your old password, you can"
 => "Этот пароль неправильный. Если вы забыли ваш старый пароль, вы можете",

#: lib/FAQ/OMatic/authenticate.pm:81
#, c-format
 "New items can only be added by %0."
 => "Новые элементы могут добавлять только: %0",

#: lib/FAQ/OMatic/authenticate.pm:83
#, c-format
 "New text parts can only be added by %0."
 => "Новые текстовые части могут добавлять только: %0",

#: lib/FAQ/OMatic/authenticate.pm:85
#, c-format
 "Text parts can only be removed by %0."
 => "Текстовые части могут удалять только: %0",

#: lib/FAQ/OMatic/authenticate.pm:89
 "This part contains raw HTML. To avoid pages with invalid HTML, the moderator has specified that only %0 can edit HTML parts. If you are %0 you may authenticate yourself with this form."
 => "Эта часть содержит &quot;чистый&quot; HTML.  Во избежание появления страниц, содержащих неправильный HTML, модератор определил, что редактировать HTML части могут только: %0.  Если вы входите в их число, вы можете подтвердить свою личность с помощью следующей формы.",

#: lib/FAQ/OMatic/authenticate.pm:91
#, c-format
 "Text parts can only be added by %0."
 => "Текстовые части могут добавлять только: %0",

#: lib/FAQ/OMatic/authenticate.pm:93
#, c-format
 "Text parts can only be edited by %0."
 => "Текстовые части могут редактировать только: %0",

#: lib/FAQ/OMatic/authenticate.pm:96
#, c-format
 "The title and options for this item can only be edited by %0."
 => "Заголовок и настройки для этого элемента может редактировать только: %0",

#: lib/FAQ/OMatic/authenticate.pm:98
#, c-format
 "The moderator options can only be edited by %0."
 => "Настройки модератора может редактировать только: %0",

#: lib/FAQ/OMatic/authenticate.pm:101
 "This item can only be moved by someone who can edit both the source and destination parent items."
 => "Этот элемент может перемещать только тот, кто может редактировать оба родительских элемента (и исходный, и целевой).",

#: lib/FAQ/OMatic/authenticate.pm:103
#, c-format
 "This item can only be moved by %0."
 => "Этот элемент может перемещать только: %0",

#: lib/FAQ/OMatic/authenticate.pm:110
#, c-format
 "Existing bags can only be replaced by %0."
 => "Заменять существующие \"мешки\" имеют право только: %0.",

#: lib/FAQ/OMatic/authenticate.pm:112
#, c-format
 "Bags can only be posted by %0."
 => "&quot;Мешки&quot; могут быть посланы только: %0",

#: lib/FAQ/OMatic/authenticate.pm:115
#, c-format
 "The FAQ-O-Matic can only be configured by %0."
 => "Конфигурировать FAQ-O-Matic может только: %0.",

#: lib/FAQ/OMatic/authenticate.pm:117
 "The operation you attempted (%0) can only be done by %1."
 => "Операцию, которую вы попытались произвести (%0), имеют право исполнять только: %1",

#: lib/FAQ/OMatic/authenticate.pm:120
 "If you have never established a password to use with FAQ-O-Matic, you can"
 => "Если у вас нет своего входа в FAQ-O-Matic, вы можете",

#: lib/FAQ/OMatic/authenticate.pm:121
 "If you have forgotten your password, you can"
 => "Если вы забыли свой пароль, вы можете",

#: lib/FAQ/OMatic/authenticate.pm:122
 "If you have already logged in earlier today, it may be that the token I use to identify you has expired. Please log in again."
 => "Если вы уже регистрировались (входили) сегодня, то появление этого сообщения может означать, что идентификатор вашей сессии уже устарел. Пожалуйста, зарегистрируйтесь снова.",

#: lib/FAQ/OMatic/authenticate.pm:136
 "Please offer one of the following forms of identification:"
 => "Пожалуйста, предоставьте одну из следующих форм идентификации:",

#: lib/FAQ/OMatic/authenticate.pm:139
 "No authentication, but my email address is:"
 => "Без аутентификации, только email-адрес:",

# Intentionally left blank.
#: lib/FAQ/OMatic/authenticate.pm:140
 "Email:"
 => "",

#: lib/FAQ/OMatic/authenticate.pm:147
 "Authenticated login:"
 => "Аутентифицированный вход:",

#: lib/FAQ/OMatic/authenticate.pm:149 lib/FAQ/OMatic/changePass.pm:64
 "Password:"
 => "Пароль:",

#: lib/FAQ/OMatic/changePass.pm:48
 "Please enter your username, and select a password."
 => "Пожалуйста, введите ваше регистрационное имя и пароль.",

#: lib/FAQ/OMatic/changePass.pm:49
 "I will send a secret number to the email address you enter to verify that it is valid."
 => "На email-адрес, который вы введете, будет отправлен Секретный Код, который вам понадобится, дабы подтвердить, что этот email существует и он действительно ваш (или, по крайней мере, вы имеете к нему доступ).",

#: lib/FAQ/OMatic/changePass.pm:50
 "If you prefer not to give your email address to this web form, please contact"
 => "Если вы предпочитаете не вводить свой email-адрес в эту форму, пожалуйста, свяжитесь с",

#: lib/FAQ/OMatic/changePass.pm:52
 "Please <b>do not</b> use a password you use anywhere else, as it will not be transferred or stored securely!"
 => "Пожалуйста, <b>НЕ ИСПОЛЬЗУЙТЕ</b> пароль, который вы уже используете где бы то ни было, поскольку он <b>НЕ БУДЕТ</b> передаваться и храниться достаточно безопасно!",

#: lib/FAQ/OMatic/changePass.pm:66
 "Set Password"
 => "Установить Пароль",

#: lib/FAQ/OMatic/editBag.pm:75
 "Replace bag"
 => "Заменить &quot;мешок&quot;",

#: lib/FAQ/OMatic/editBag.pm:81
 "Upload new bag to show in the %0 part in <b>%1</b>."
 => "",

#: lib/FAQ/OMatic/editBag.pm:97
 "Bag name:"
 => "Название &quot;мешка&quot;:",

#: lib/FAQ/OMatic/editBag.pm:99
 "The bag name is used as a filename, so it is restricted to only contain letters, numbers, underscores (_), hyphens (-), and periods (.). It should also carry a meaningful extension (such as .gif) so that web browsers will know what to do with the data."
 => "Имя &quot;мешка&quot; используется, как имя файла, и, следовательно должно содержать только буквы, цифры, знаки подчеркивания (`_'), знаки переноса (`-') и точки (`.').  Оно должно также включать осмысленное расширение (например, .gif), чтобы web-бровзер смог понять, что делать с его содержимым.",

#: lib/FAQ/OMatic/editBag.pm:102
 "Bag data:"
 => "Данные &quot;мешка&quot;:",

#: lib/FAQ/OMatic/editBag.pm:105
 "(Leave blank to keep original bag data and change only the associated information below.)"
 => "(Оставьте пустым если хотите оставить данные в \"мешке\" неизменными, а изменить только нижеследующую связанную с ним информацию.)",

#: lib/FAQ/OMatic/editBag.pm:110
 "If this bag is an image, fill in its dimensions."
 => "Если этот \"мешок\" является изображением -- заполните эти размерности.",

#: lib/FAQ/OMatic/editBag.pm:111
 "Width:"
 => "Ширина:",

#: lib/FAQ/OMatic/editBag.pm:113
 "Height:"
 => "Высота:",

#: lib/FAQ/OMatic/editPart.pm:146
 "Enter the answer to <b>%0</b>"
 => "Введите ответ на вопрос <b>%0</b>",

#: lib/FAQ/OMatic/editPart.pm:148
 "Enter a description for <b>%0</b>"
 => "Введите описание для <b>%0</b>",

#: lib/FAQ/OMatic/editPart.pm:150
 "Edit duplicated text for <b>%0</b>"
 => "Редактирование сдублированного текста для <b>%0</b>",

#: lib/FAQ/OMatic/editPart.pm:152
 "Enter new text for <b>%0</b>"
 => "Введите новый текст для <b>%0</b>",

#: lib/FAQ/OMatic/editPart.pm:157
 "Editing the %0 text part in <b>%1</b>."
 => "Редактирование текстовой части N %0 в <b>%1</b>.",

#: lib/FAQ/OMatic/editPart.pm:171
 "If you later need to edit or delete this text, use the [Appearance] page to turn on the expert editing commands."
 => "Если вам позже понадобится отредактировать или удалить этот текст, используйте ссылку <code>[Внешний Вид]</code> дабы включить расширенные команды редактирования.",

#: lib/FAQ/OMatic/install.pm:93
 "Faq-O-Matic Installer"
 => "Инсталятор FAQ-O-Matic'а",

#: lib/FAQ/OMatic/install.pm:121
#, c-format
 "%0 failed: "
 => "Ошибка во время %0: ",

#: lib/FAQ/OMatic/install.pm:127
 "Unknown step: \"%0\"."
 => "Неизвестный шаг: \"%0\".",

#: lib/FAQ/OMatic/install.pm:138
 "Updating config to reflect new meta location <b>%0</b>."
 => "Обновление конфигурации для отражения нового местоположения каталога meta: <b>%0</b>.",

#: lib/FAQ/OMatic/install.pm:156
 "(Can't find <b>config</b> in '%0' -- assuming this is a new installation.)"
 => "(Не удалось найти <b>config</b> в '%0' -- предполагаю, что это новая инсталляция.)",

#: lib/FAQ/OMatic/install.pm:180
#, c-format
 "Click here</a> to create %0."
 => "Щелкните сюда</a>, чтобы создать %0.",

#: lib/FAQ/OMatic/install.pm:182
 "If you want to change the CGI stub to point to another directory, edit the script and then"
 => "Если вы хотите изменить CGI-скрипт, чтобы указывал на другой каталог, отредактируйте скрипт и после этого",

#: lib/FAQ/OMatic/install.pm:185
 "click here to use the new location"
 => "щелкните сюда, дабы начать использовать новое местоположение",

#: lib/FAQ/OMatic/install.pm:187
 "FAQ-O-Matic stores files in two main directories.<p>The <b>meta/</b> directory path is encoded in your CGI stub (%0). It contains:"
 => "FAQ-O-Matic сохраняет файлы в двух главных каталогах.<p> Путь к каталогу <b>meta/</b> прописан в вашем CGI-скрипте (%0).  Он содержит:",

#: lib/FAQ/OMatic/install.pm:188
 "<ul><li>the <b>config</b> file that tells FAQ-O-Matic where everything else lives. That's why the CGI stub needs to know where meta/ is, so it can figure out the rest of its configuration. <li>the <b>idfile</b> file that lists user identities. Therefore, meta/ should not be accessible via the web server. <li>the <b>RCS/</b> subdirectory that tracks revisions to FAQ items. <li>various hint files that are used as FAQ-O-Matic runs. These can be regenerated automatically.</ul>"
 => "<ul><li>файл <b>config</b>, который сообщает FAQ-O-Matic'у, где искать все остальное. Поэтому CGI-скрипт должен знать где находится каталог meta/, зная это он сможет определить всю остальную конфигурацию. <li>файл <b>idfile</b>, который содержит список идентификаторов пользователей. Следовательно, meta/ не должен быть доступен через web-сервер. <li>подкаталог <b>RCS/</b>, в котором трассируются версии элементов FAQ. <li>различные файлы-подсказки, используемые работающим FAQ-O-Matic'ом. Они пересоздаются автоматически.</ul>",

#: lib/FAQ/OMatic/install.pm:189
 "<p>The <b>serve/</b> directory contains three subdirectories <b>item/</b>, <b>cache/</b>, and <b>bags/</b>. These directories are created and populated by the FAQ-O-Matic CGI, but should be directly accessible via the web server (without invoking the CGI)."
 => "Каталог <b>serve/</b> содержит три подкаталога: <b>item/</b>, <b>cache/</b> и <b>bags/</b>.  Эти каталоги создаются и заполняются FAQ-O-Matic'ом, но должны быть доступны web-серверу напрямую (без вызова CGI).",

#: lib/FAQ/OMatic/install.pm:190
 "<ul><li>serve/item/ contains only FAQ-O-Matic formatted source files, which encode both user-entered text and the hierarchical structure of the answers and categories in the FAQ. These files are only accessed through the web server (rather than the CGI) when another FAQ-O-Matic is mirroring this one. <li>serve/cache/ contains a cache of automatically-generated HTML versions of FAQ answers and categories. When possible, the CGI directs users to the cache to reduce load on the server. (CGI hits are far more expensive than regular file loads.) <li>serve/bags/ contains image files and other ``bags of bits.'' Bit-bags can be linked to or inlined into FAQ items (in the case of images). </ul>"
 => "<ul><li>serve/item/ содержит только исходные отформатированные файлы для FAQ-O-Matic'а, которые содержат как определенный пользователем текст, так и описание иерархической структуры ответов и категорий в FAQ.  Доступ к этим файлам производится только через web-сервер (в противовес доступу через CGI) когда какой-либо другой FAQ-O-Matic производит зеркальную копию (mirroring) с этого.  <li>serve/cache/ содержит кэш автоматически сгенерированных HTML версий ответов и категорий FAQ.  Когда возможно, CGI перенаправляет пользователей на этот кэш, уменьшая, тем самым, нагрузку на сервер.  (Отработка CGI требует гораздо больше ресурсов, чем просто отдать уже существующий файл.) <li>serve/bags/ содержит файлы изображений, или иными словами &quot;мешки с битами&quot; (&quot;bags of bits&quot;).  &quot;Мешки&quot; могут быть привязаны к или вставлены в (если это изображения) элементы FAQ. </ul>",

#: lib/FAQ/OMatic/install.pm:202 lib/FAQ/OMatic/install.pm:217
#: lib/FAQ/OMatic/install.pm:276 lib/FAQ/OMatic/install.pm:612
 "I couldn't create <b>%0</b>: %1"
 => "Не удалось создать <b>%0</b>: %1",

#: lib/FAQ/OMatic/install.pm:206 lib/FAQ/OMatic/install.pm:221
#: lib/FAQ/OMatic/install.pm:615
 "Created <b>%0</b>."
 => "Создан <b>%0</b>.",

#: lib/FAQ/OMatic/install.pm:209 lib/FAQ/OMatic/install.pm:224
#: lib/FAQ/OMatic/install.pm:618
 "I don't have write permission to <b>%0</b>."
 => "Нет прав на запись в <b>%0</b>.",

#: lib/FAQ/OMatic/install.pm:268
 "Created new config file."
 => "Создан новый конфигурационный файл.",

#: lib/FAQ/OMatic/install.pm:282
 "The idfile exists."
 => "Файл <code>idfile</code> существует.",

#: lib/FAQ/OMatic/install.pm:331
 "Configuration Main Menu (install module)"
 => "Конфигурация, Главное Меню (модуль инсталяции)",

#: lib/FAQ/OMatic/install.pm:332
 "Perform these tasks in order to prepare your FAQ-O-Matic version %0:"
 => "Исполните эти задачи для подготовки вашего FAQ-O-Matic'а версии %0:",

#: lib/FAQ/OMatic/install.pm:337
 "Define configuration parameters"
 => "Определить конфигурационные параметры",

#: lib/FAQ/OMatic/install.pm:342 lib/FAQ/OMatic/install.pm:347
 "Set your password and turn on installer security"
 => "Установить ваш пароль и включить безопасность инсталятора",

#: lib/FAQ/OMatic/install.pm:348
 "(Need to configure \$mailCommand and \$adminAuth)"
 => "(Необходимо сконфигурировать \$mailCommand и \$adminAuth)",

#: lib/FAQ/OMatic/install.pm:354
 "(Installer security is on)"
 => "(Безопасность инсталятора включена)",

#: lib/FAQ/OMatic/install.pm:359
 "Create item, cache, and bags directories in serve dir"
 => "Создать item, cache, и bags подкаталоги в каталоге serve",

#: lib/FAQ/OMatic/install.pm:367
 "Copy old items</a> from <tt>%0</tt> to <tt>%1</tt>."
 => "Копировать старые элементы</a> из <tt>%0</tt> в <tt>%1</tt>.",

#: lib/FAQ/OMatic/install.pm:374
 "Install any new items that come with the system"
 => "Установить любые элементы, которые идут вместе с системой",

#: lib/FAQ/OMatic/install.pm:379
 "Create system default items"
 => "Создать системные элементы по-умолчанию",

#: lib/FAQ/OMatic/install.pm:387 lib/FAQ/OMatic/install.pm:498
 "Rebuild the cache and dependency files"
 => "Пересоздать кэш-файлы и файлы зависимостей",

#: lib/FAQ/OMatic/install.pm:394
 "Install system images and icons"
 => "Установить системные изображения и иконки",

#: lib/FAQ/OMatic/install.pm:402
 "Update mirror from master now. (this can be slow!)"
 => "",

#: lib/FAQ/OMatic/install.pm:408
 "Set up the maintenance cron job"
 => "Устанивить обслуживающую cron-задачу",

#: lib/FAQ/OMatic/install.pm:414 lib/FAQ/OMatic/install.pm:419
 "Run maintenance script manually now"
 => "Запустить обслуживающий скрипт вручную, сейчас",

#: lib/FAQ/OMatic/install.pm:421
 "(Need to set up the maintenance cron job first)"
 => "(Необходимо сперва установить обслуживающую cron-задачу)",

#: lib/FAQ/OMatic/install.pm:429
 "Maintenance last run at:"
 => "Обслуживающая задача в последний раз исполнялась:",

#: lib/FAQ/OMatic/install.pm:434
#, c-format
 "Mark the config file as upgraded to Version %0"
 => "Маркировать конфигурационный файл, как обновленный до версии %0",

#: lib/FAQ/OMatic/install.pm:440
 "Select custom colors for your Faq-O-Matic</a> (optional)"
 => "Переопределить цвета для вашего FAQ-O-Matic'а</a> (не обязательный)",

#: lib/FAQ/OMatic/install.pm:444
 "Define groups</a> (optional)"
 => "Определить группы</a> (не обязательный)",

#: lib/FAQ/OMatic/install.pm:450
 "Upgrade to CGI.pm version 2.49 or newer."
 => "Обновить CGI.pm до версии 2.49 или новее.",

#: lib/FAQ/OMatic/install.pm:453
 "(optional; older versions have bugs that affect bags)"
 => "(не обязательный; старые версии содержат ошибку, которая делает &quot;мешки&quot; не работоспособными)",

#: lib/FAQ/OMatic/install.pm:456
#, c-format
 "You are using version %0 now."
 => "Вы сейчас используете версию %0.",

#: lib/FAQ/OMatic/install.pm:461
 "Bookmark this link to be able to return to this menu."
 => "Создать закладку на эту страницу, дабы легче было сюда вернуться (работает не на всех бровзерах).",

#: lib/FAQ/OMatic/install.pm:472
 "(need to turn on installer security)"
 => "(необходимо, чтобы включить безопасность инсталятора)",

#: lib/FAQ/OMatic/install.pm:475
 "Other available tasks:"
 => "Другие доступные задачи:",

#: lib/FAQ/OMatic/install.pm:479
 "See access statistics"
 => "Посмотреть статистику доступа",

#: lib/FAQ/OMatic/install.pm:484
 "Examine all bags"
 => "Проверить все \"мешки\"",

#: lib/FAQ/OMatic/install.pm:490
 "Check for unreferenced bags (not linked by any FAQ item)"
 => "Проверить на \"подвешенные мешки\" (на которые нет ссылок ни из одного элемента FAQ)",

#: lib/FAQ/OMatic/install.pm:503
#, c-format
 "The Faq-O-Matic modules are version %0."
 => "Модули FAQ-O-Matic имеют версию %0.",

#: lib/FAQ/OMatic/install.pm:622
 "I wasn't able to change the permissions on <b>%0</b> to 755 (readable/searchable by all)."
 => "Не удалось изменить права доступа к <b>%0</b> на 755 (чтение/поиск для всех).",

#: lib/FAQ/OMatic/install.pm:637 lib/FAQ/OMatic/install.pm:638
 "updated config file:"
 => "обновленный файл конфигурации:",

#: lib/FAQ/OMatic/install.pm:645
 "Redefine configuration parameters to ensure that <b>%0</b> is valid."
 => "Переопределите (определите заново?) конфигурационные параметры, дабы быть уверенным, что <b>%0</b> в порядке.",

# Intentionally left blank.
#: lib/FAQ/OMatic/install.pm:657
 "Jon made a mistake here; key=%0, property=%1."
 => "",

#: lib/FAQ/OMatic/install.pm:686
 "<b>Mandatory:</b> System information"
 => "<b>Обязательный:</b> Информация о системе",

#: lib/FAQ/OMatic/install.pm:689
 "Identity of local FAQ-O-Matic administrator (an email address)"
 => "Идентификатор локального администратора FAQ-O-Matic (email-адрес)",

#: lib/FAQ/OMatic/install.pm:691
 "A command FAQ-O-Matic can use to send mail. It must either be sendmail, or it must understand the -s (Subject) switch."
 => "Команда, используемая FAQ-O-Matic'ом для отправки почты.  Это должен быть sendmail или что-нибудь другое, что понимает опцию -s (Subject).",

#: lib/FAQ/OMatic/install.pm:693
 "The command FAQ-O-Matic can use to install a cron job."
 => "Команда, которую FAQ-O-Matic может использовать для установки cron-задачи.",

#: lib/FAQ/OMatic/install.pm:696
 "Path to the <b>ci</b> command from the RCS package."
 => "Путь к команде <b>ci</b> из пакета RCS.",

#: lib/FAQ/OMatic/install.pm:699
 "<b>Mandatory:</b> Server directory configuration"
 => "<b>Обязательный:</b> Конфигурация каталогов сервера",

#: lib/FAQ/OMatic/install.pm:701
 "Protocol, host, and port parts of the URL to your site. This will be used to construct link URLs. Omit the trailing '/'; for example: <tt>http://www.dartmouth.edu</tt>"
 => "Протокол-, хост- и порт-части URL, указывающего на ваш сайт.  Они будут использоваться для создания URL'ей в ссылках.  Не вводите концевой '/'; пример: <tt>http://www.dartmouth.edu</tt>",

#: lib/FAQ/OMatic/install.pm:704
 "The path part of the URL used to access this CGI script, beginning with '/' and omitting any parameters after the '?'. For example: <tt>/cgi-bin/cgiwrap/jonh/faq.pl</tt>"
 => "Часть URL, отвечающая за путь к этому CGI-скрипту.  Должна начинаться с '/' и не содержать никаких параметров после '?'.  Пример: <tt>/cgi-bin/cgiwrap/jonh/faq.pl</tt>",

#: lib/FAQ/OMatic/install.pm:707
 "Filesystem directory where FAQ-O-Matic will keep item files, image and other bit-bag files, and a cache of generated HTML files. This directory must be accessible directly via the http server. It might be something like /home/faqomatic/public_html/fom-serve/"
 => "Каталог в файловой системе, где FAQ-O-Matic хранит файлы элементов, изображения и другие \"мешки с битами\", а так же кэширует сгенерированные HTML файлы.  Этот каталог должен быть доступен напрямую через web-сервер.  Это может быть что-нибудь наподобие <code>/home/faqomatic/public_html/fom-serve/</code>",

#: lib/FAQ/OMatic/install.pm:709
 "The path prefix of the URL needed to access files in <b>\$serveDir</b>. It should be relative to the root of the server (omit http://hostname:port, but include a leading '/'). It should also end with a '/'."
 => "Префикс пути в URL, необходимый для доступа к файлам, расположенным в <b>\$serveDir</b>.  Он должен быть задан корневого каталога сервера (опуская http://hostname:port, но включая лидирующий '/').  Он должен, также, завершаться на '/'.",

#: lib/FAQ/OMatic/install.pm:712
 "<i>Optional:</i> Miscellaneous configurations"
 => "<i>Не обязательный:</i> Разнообразные настройки",

#: lib/FAQ/OMatic/install.pm:717
 "Select the display language."
 => "Выберите язык для отображения. (Select the display language.)",

#: lib/FAQ/OMatic/install.pm:722
 "Show dates in 24-hour time or am/pm format."
 => "Отображать даты в 24-часовом формате, или в формате am/pm.",

#: lib/FAQ/OMatic/install.pm:726
 "If this parameter is set, this FAQ will become a mirror of the one at the given URL. The URL should be the base name of the CGI script of the master FAQ-O-Matic."
 => "Если этот параметр установлен, то этот FAQ станет зеркальной копией (mirror) FAQ, находящегося по указанному URL.  URL должен быть базовым именем (base name) CGI-скрипта &quot;ведущего&quot; FAQ-O-Matic'а.",

#: lib/FAQ/OMatic/install.pm:728
 "An HTML fragment inserted at the top of each page. You might use this to place a corporate logo."
 => "HTML фрагмент, который вставляется в начало каждой страницы.  Вы можете использовать его, например, для размещения вашего логотипа.",

#: lib/FAQ/OMatic/install.pm:730 lib/FAQ/OMatic/install.pm:743
 "If this field begins with <tt>file=</tt>, the text will come from the named file in the meta directory; otherwise, this field is included verbatim."
 => "Если содержимое этого поля начинается с <tt>file=</tt>, то текст будет взят из указанного файла в каталоге meta; в противном случае содержимое поля будет вставлено &quot;как есть&quot;.",

#: lib/FAQ/OMatic/install.pm:738
 "The <tt>width=</tt> tag in a table. If your <b>\$pageHeader</b> has <tt>align=left</tt>, you will want to make this empty."
 => "Тег <tt>width=</tt> в таблице.  Если ваш <b>\$pageHeader</b> имеет <tt>align=left</tt>, вы, возможно, пожелаете оставить его пустым.",

#: lib/FAQ/OMatic/install.pm:741
 "An HTML fragment appended to the bottom of each page. You might use this to identify the webmaster for this site."
 => "HTML фрагмент, который добавляется в конец каждой страницы.  Вы можете использовать его, например, для сообщения, кто есть webmaster вашего сайта.",

#: lib/FAQ/OMatic/install.pm:746
 "Where FAQ-O-Matic should send email when it wants to alert the administrator (usually same as \$adminAuth)"
 => "Куда FAQ-O-Matic должен посылать email, когда он хочет привлечь внимание администратора (обычно, тоже самое, что и \$adminAuth)",

#: lib/FAQ/OMatic/install.pm:748
 "If true, FAQ-O-Matic will mail the log file to the administrator whenever it is truncated."
 => "Если 'true', то FAQ-O-Matic будет отсылать log-файл администратору всякий раз при его усечении.",

#: lib/FAQ/OMatic/install.pm:751
 "User to use for RCS ci command (default is process UID)"
 => "Пользователь, используемый для RCS-команды <code>ci</code> (по-умолчанию: UID процесса)",

#: lib/FAQ/OMatic/install.pm:755
 "Links from cache to CGI are relative to the server root, rather than absolute URLs including hostname:"
 => "Использовать в кэше относительные ссылки на CGI (относительно корневого каталога сервера), вместо абсолютных URL, включающих имя хоста:",

#: lib/FAQ/OMatic/install.pm:759
 "mailto: links can be rewritten such as jonhATdartmouthDOTedu (cheesy), jonh (nameonly), or e-mail addresses suppressed entirely (hide)."
 => "Для защиты от spam'а, ссылки <code>mailto:</code> могут искажаться до вида jonhATdartmouthDOTedu (cheesy), jonh (nameonly), или email-адрес может быть скрыт вообще (hide).  'off' означает не искажать ссылки <code>mailto:</code>.",

#: lib/FAQ/OMatic/install.pm:763
 "Number of seconds that authentication cookies remain valid. These cookies are stored in URLs, and so can be retrieved from a browser history file. Hence they should usually time-out fairly quickly."
 => "Количество секунд, в течении которых аутентификационные &quot;крошки&quot; (cookies) остаются действительными.  Эти &quot;крошки&quot; сохраняются в URL, и, следовательно, могут быть извлечены из файла истории бровзера (browser history file).  Посему это значение должно быть достаточно небольшим.",

#: lib/FAQ/OMatic/install.pm:766
 "<i>Optional:</i> These options set the default [Appearance] modes."
 => "<i>Не обязательный:</i> Эти настройки определяют, каким будет <code>[Внешний Вид]</code> по умолчанию.",

#: lib/FAQ/OMatic/install.pm:771
 "Page rendering scheme. Do not choose 'text' as the default."
 => "Схема отрисовки страниц.  Не используйте 'text', в качестве схемы по-умолчанию.",

#: lib/FAQ/OMatic/install.pm:799
 "<i>Optional:</i> These options fine-tune the appearance of editing features."
 => "<i>Не обязательный:</i> &quot;Тонкая&quot; настройка вида команд редактирования.",

#: lib/FAQ/OMatic/install.pm:802
 "The old [Show Edit Commands] button appears in the navigation bar."
 => "Старая кнопка <code>[Показать Команды Редактирования]</code> входит в навигационную линейку.",

#: lib/FAQ/OMatic/install.pm:806
 "Navigation links appear at top of page as well as at the bottom."
 => "Отображать навигационные ссылки вверху страницы, так же, как и внизу.",

#: lib/FAQ/OMatic/install.pm:810
 "Hide [Append to This Answer] and [Add New Answer in ...] buttons."
 => "Спрятать кнопки <code>[Добавить к Этому Ответу]</code> и <code>[Новый Ответ в ...]</code>",

#: lib/FAQ/OMatic/install.pm:815
 "Editing commands appear with neat-o icons rather than [In Brackets]."
 => "Команды редактирования отображаются вместе с иконками, а не <code>[в квадратных скобках]</code>.",

#: lib/FAQ/OMatic/install.pm:818
 "<i>Optional:</i> Other configurations that you should probably ignore if present."
 => "<i>Не обязательный:</i> Другие настройки, которые вы, возможно, захотите проигнорировать.",

#: lib/FAQ/OMatic/install.pm:822
 "Draw Item titles John Nolan's way."
 => "",

#: lib/FAQ/OMatic/install.pm:826
 "Hide sibling (Previous, Next) links"
 => "Спрятать ссылки на предыдущий и следующий документы",

#: lib/FAQ/OMatic/install.pm:830
 "Use DBM-based search databases. Faster on machines with non-broken DBM."
 => "Использовать поисковый движок, основанный на DBM.  Он быстрее, но не каждая машина имеет неповрежденный (работающий) DBM.",

#: lib/FAQ/OMatic/install.pm:937
 "This is a command, so only letters, hyphens, and slashes are allowed."
 => "Это команда, посему допускаются только буквы, знаки переноса ('-') и слэши ('/').",

#: lib/FAQ/OMatic/install.pm:996
 "If this is your first time installing a FAQ-O-Matic, I recommend only filling in the sections marked <b>Mandatory</b>."
 => "Если вы устанавливаете FAQ-O-Matic в первый раз, рекомендуем заполнять только секции, маркированные, как <b>Обязательные</b> (<b>Mandatory</b>).",

#: lib/FAQ/OMatic/install.pm:1000
 "Define"
 => "Установить",

#: lib/FAQ/OMatic/install.pm:1041
 "You should <a href=\"%0\">go back</a> and fix these configurations."
 => "Вы должны <a href=\"%0\">вернуться</a> и исправить эти установки.",

#: lib/FAQ/OMatic/install.pm:1044
 "Rewrote configuration file."
 => "Конфигурационный файл переписан.",

#: lib/FAQ/OMatic/install.pm:1058
 "%0 (%1) has an internal apostrophe, which will certainly make Perl choke on the config file."
 => "%0 (%1) содержит апостроф, который может быть неправильно воспринят Perl'ом внутри конфигурационного файла.",

#: lib/FAQ/OMatic/install.pm:1062 lib/FAQ/OMatic/install.pm:1068
 "%0 (%1) doesn't look like a fully-qualified email address."
 => "%0 (%1) не выглядит, как полный email-адрес.",

#: lib/FAQ/OMatic/install.pm:1074 lib/FAQ/OMatic/install.pm:1079
 "%0 (%1) isn't executable."
 => "%0 (%1) не является исполнимым файлом.",

#: lib/FAQ/OMatic/install.pm:1096
 "%0 has funny characters."
 => "%0 имеет \"опасные\" символы.",

#: lib/FAQ/OMatic/install.pm:1125
 "Untitled Faq-O-Matic"
 => "Безымянный Faq-O-Matic",

#: lib/FAQ/OMatic/install.pm:1131
 "To name your FAQ-O-Matic, use the [Appearance] page to show the expert editing commands, then click [Edit Category Title and Options]."
 => "Дабы назвать ваш FAQ-O-Matic, используйте страницу [Внешний Вид] и разрешите на ней расширенные команды редактирования, после чего нажмите [Заголовок и Настройки Категории]",

#: lib/FAQ/OMatic/install.pm:1141 lib/FAQ/OMatic/install.pm:1153
#: lib/FAQ/OMatic/install.pm:1165
 "Created category \"%0\"."
 => "Создана категория \"%0\".",

#: lib/FAQ/OMatic/install.pm:1143 lib/FAQ/OMatic/install.pm:1155
#: lib/FAQ/OMatic/install.pm:1167
 "<b>%0</b> already contains a file '%1'."
 => "<b>%0</b> уже содержит файл '%1'.",

#: lib/FAQ/OMatic/install.pm:1205
 "Copied %0 items from <tt>%1</tt> to <tt>%2</tt>."
 => "Скопировано %0 элементов из <tt>%1</tt> в <tt>%2</tt>.",

#: lib/FAQ/OMatic/install.pm:1262
 "Attempting to install cron job:"
 => "Попытка установить cron-задачу:",

#: lib/FAQ/OMatic/install.pm:1310
 "I replaced this old crontab line, which appears to be an older one for this same FAQ:"
 => "Была заменена старая строка в файле crontab, которая относилась к этому же FAQ (или была очень на нее похожа)",

#: lib/FAQ/OMatic/install.pm:1319
 "I thought I installed a new cron job, but it didn't appear to take."
 => "",

#: lib/FAQ/OMatic/install.pm:1321
 "You better add %0 to some crontab yourself with <b><tt>crontab -e</tt></b>"
 => "Вам лучше добавить `%0' в какой-нибудь crontab самим с помощью команды <b><tt>crontab -e</tt></b>",

#: lib/FAQ/OMatic/install.pm:1327
 "Cron job installed. The maintenance script should run hourly."
 => "Cron-задача установлена.  Обслуживающий скрипт должен исполняться каждый час.",

#: lib/FAQ/OMatic/install.pm:1383
 "Use the <u>%0</u> links to change the color of a feature."
 => "используйте ссылки <u>%0</u>, чтобы изменить соответствующий цвет.",

#: lib/FAQ/OMatic/install.pm:1397
 "An Item Title"
 => "Заголовок Элемента",

#: lib/FAQ/OMatic/install.pm:1405
 "A regular part is how most of your content will appear. The text colors should be most pleasantly readable on this background."
 => "Обычная текстовая часть.  Почти все содержимое FAQ располагается именно в них.  Цвета текста должны быть подобраны так, чтобы быть наиболее комфортными для чтения.",

#: lib/FAQ/OMatic/install.pm:1407 lib/FAQ/OMatic/install.pm:1419
#: lib/FAQ/OMatic/install.pm:1446
 "A new link"
 => "Новая ссылка",

#: lib/FAQ/OMatic/install.pm:1408 lib/FAQ/OMatic/install.pm:1420
#: lib/FAQ/OMatic/install.pm:1450
 "A visited link"
 => "Посещенная ссылка",

#: lib/FAQ/OMatic/install.pm:1410 lib/FAQ/OMatic/install.pm:1422
#: lib/FAQ/OMatic/install.pm:1455
 "A search hit"
 => "&quot;Попадание&quot; поиска",

#: lib/FAQ/OMatic/install.pm:1418
 "A directory part should stand out"
 => "Часть-каталог.  Она должна выделяться.",

#: lib/FAQ/OMatic/install.pm:1442
 "Regular text"
 => "Обычный текст",

#: lib/FAQ/OMatic/install.pm:1467
 "Select a color for %0:"
 => "Выберите цвет для &quot;%0&quot;",

#: lib/FAQ/OMatic/install.pm:1478
 "Or enter an HTML color specification manually:"
 => "Или введите HTML-спецификацию цвета вручную:",

#: lib/FAQ/OMatic/install.pm:1481
 "Select"
 => "Выбрать",

#: lib/FAQ/OMatic/install.pm:1490
 "Unrecognized config parameter"
 => "Нераспознанный конфигурационный параметр",

#: lib/FAQ/OMatic/install.pm:1538
#, c-format
 "Proceed to step '%0'"
 => "Пройти до шага '%0'",

#: lib/FAQ/OMatic/moveItem.pm:112
 "Make <b>%0</b> belong to which other item?"
 => "",

#: lib/FAQ/OMatic/moveItem.pm:116
 "No item that already has sub-items can become the parent of"
 => "",

#: lib/FAQ/OMatic/moveItem.pm:118
 "No item can become the parent of"
 => "",

#: lib/FAQ/OMatic/moveItem.pm:122
 "Some destinations are not available (not clickable) because you do not have permission to edit them as currently authorized."
 => "Некоторые цели недоступны (на них нельзя щелкнуть), поскольку вы не имеете достаточно прав для их редактирования (по крайней мере под тем идентификатором, под которым вы сейчас вошли).",

#: lib/FAQ/OMatic/moveItem.pm:125
 "Click here</a> to provide better authentication."
 => "",

#: lib/FAQ/OMatic/moveItem.pm:131
 "Hide answers, show only categories"
 => "Спрятать ответы, показывать только категории",

#: lib/FAQ/OMatic/moveItem.pm:134
 "Show both categories and answers"
 => "Показать и категории, и ответы",

#: lib/FAQ/OMatic/search.pm:72
 "No items matched all of these words"
 => "Не найдено ни одного документа, удовлетворяющего всем заданным словам",

#: lib/FAQ/OMatic/search.pm:76
#, c-format
 "No items matched at least %0 of these words"
 => "Не найдено ни одного документа, удовлетворяющего, как минимум, %0 из заданных слов",

#: lib/FAQ/OMatic/search.pm:85
 "Search results for all of these words"
 => "Результаты поиска документов, удовлетворяющих всем заданным словам",

#: lib/FAQ/OMatic/search.pm:89
#, c-format
 "Search results for at least %0 of these words"
 => "Результаты поиска документов, удовлетворяющих, как минимум, %0 из заданных слов",

#: lib/FAQ/OMatic/search.pm:106
 "Results may be incomplete, because the search index has not been refreshed since the most recent change to the database."
 => "Результат может быть неполон, поскольку поисковый индекс не успел обновиться после самого свежего изменения в базе данных.",

#: lib/FAQ/OMatic/searchForm.pm:52
 "search for keywords"
 => "поиск по ключевым словам",

#: lib/FAQ/OMatic/searchForm.pm:57
 "Search for"
 => "Искать",

#: lib/FAQ/OMatic/searchForm.pm:58
 "matching"
 => "должны совпасть:",

#: lib/FAQ/OMatic/searchForm.pm:60
 "all"
 => "все",

#: lib/FAQ/OMatic/searchForm.pm:61
 "any"
 => "любое",

#: lib/FAQ/OMatic/searchForm.pm:62
 "two"
 => "два",

#: lib/FAQ/OMatic/searchForm.pm:63
 "three"
 => "три",

#: lib/FAQ/OMatic/searchForm.pm:64
 "four"
 => "четыре",

#: lib/FAQ/OMatic/searchForm.pm:65
 "five"
 => "пять",

#: lib/FAQ/OMatic/searchForm.pm:67
 "words"
 => "слов(а,о)",

#: lib/FAQ/OMatic/searchForm.pm:75
 "search for recent changes"
 => "поиск свежих изменений",

#: lib/FAQ/OMatic/searchForm.pm:81
 "Show documents"
 => "Показать документы",

#: lib/FAQ/OMatic/searchForm.pm:82
 "modified in the last"
 => "измененные за последнюю(ий,ие)",

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
 => "неделю",

#: lib/FAQ/OMatic/searchForm.pm:88
 "fortnight"
 => "две недели",

#: lib/FAQ/OMatic/searchForm.pm:89
 "month"
 => "месяц",

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

#: lib/FAQ/OMatic/stats.pm:87
 "Please be patient ... the image files are generated dynamically, and can take from 20 to 50 seconds to create.\n"
 => "Пожалуйста, будьте терпеливы... изображения генерируются динамически, и на их создание может потребоваться от 20 до 50 секунд.\n",

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

#: lib/FAQ/OMatic/submitBag.pm:50
 "Bag names may only contain letters, numbers, underscores (_), hyphens (-), and periods (.), and may not end in '.desc'. Yours was"
 => "Названия \"мешков\" могут содержать только буквы, цифры, знаки подчеркивания (_), знаки переноса (-) и точки (.), и не могут заканчиваться на '.desc'.  Ваше было",

#: lib/FAQ/OMatic/submitItem.pm:61
 "Your browser or WWW cache has truncated your POST."
 => "",

#: lib/FAQ/OMatic/submitItem.pm:72
 "Changed the item title, was \"%0\""
 => "Изменен заголовок элемента, было \"%0\"",

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

#: lib/FAQ/OMatic/submitMove.pm:51
 "The moving file (%0) is broken or missing."
 => "Перемещаемый файл (%0) поврежден или отсутствует.",

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

#: lib/FAQ/OMatic/submitMove.pm:92
 "You can't move the top item."
 => "Вы не можете перемещать верхний элемент.",

#: lib/FAQ/OMatic/submitMove.pm:130
#, c-format
 "moved a sub-item to %0"
 => "перемещен, как подэлемент в %0",

#: lib/FAQ/OMatic/submitMove.pm:133
#, c-format
 "moved a sub-item from %0"
 => "перемещен, как подэлемент из %0",

#: lib/FAQ/OMatic/submitPass.pm:49
 "An email address must look like 'name\@some.domain'."
 => "Email-адрес должен иметь вид 'name\@some.domain'.",

#: lib/FAQ/OMatic/submitPass.pm:51
 "If yours (%0) does and I keep rejecting it, please mail %1 and tell him what's happening."
 => "Если вид вашего email (%0) удовлетворяет этому критерию, но все-равно отвергается, пожалуйста, напишите %1 и расскажите ему, что произошло (только, пожалуйста, пишите по-английски!)",

#: lib/FAQ/OMatic/submitPass.pm:58
 "Your password may not contain spaces or carriage returns."
 => "Ваш пароль не может содержать пробелов и возвратов каретки.",

#: lib/FAQ/OMatic/submitPass.pm:90
 "Your Faq-O-Matic authentication secret"
 => "",

#: lib/FAQ/OMatic/submitPass.pm:113
 "I couldn't mail the authentication secret to \"%0\" and I'm not sure why."
 => "Не удалось отправить аутентификационный Секретный Код на \"%0\" и нет никакой уверенности почему.",

#: lib/FAQ/OMatic/submitPass.pm:123
 "The secret you entered is not correct."
 => "Секретный Код, который вы ввели -- неправильный.",

#: lib/FAQ/OMatic/submitPass.pm:125
 "Did you copy and paste the secret or the URL completely?"
 => "Вы уверены, что скопировали Секретный Код или URL полностью?",

#: lib/FAQ/OMatic/submitPass.pm:129
 "I sent email to you at \"%0\". It should arrive soon, containing a URL."
 => "На ваш адрес \"%0\" было послано письмо.  Оно должно скоро прийти и содержать в себе URL.",

#: lib/FAQ/OMatic/submitPass.pm:133
 "Either open the URL directly, or paste the secret into the form below and click Validate."
 => "Или откройте этот URL напрямую, или скопируйте Секретный Код (Secret) в расположенную ниже форму и нажмите <code>[Проверить]</code>.",

#: lib/FAQ/OMatic/submitPass.pm:135
 "Thank you for taking the time to sign up."
 => "Спасибо, что нашли время подписаться.",

#: lib/FAQ/OMatic/submitPass.pm:143
 "Secret:"
 => "Секретный Код:",


);  # end of %data hash

    my $msgid;

    foreach $msgid (keys(%data))
    {
        $tx->{$msgid} = $data{$msgid};
    }
    return 1;
}
