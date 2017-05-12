#!/usr/bin/perl
use utf8;
use Test::More tests => 4 + 3 * 26;
BEGIN { use_ok('Lingua::Identify', qw/:language_manipulation :language_identification/) };

my %texts = (
             cs => "Asi 4000 lidí v sobotu demonstrovaly v centru tureckého největšího města Istanbulu, aby vyjádřily podporu islámským konzervativcům v Egyptě. Ty podporuje i turecká vláda. V libyjském Benghází vybuchla bomba v před egyptským konzulátem. Tlaková vlna vyrazila okna budovy, okolních domů a poblíž zaparkovaných aut.",
             hi => "इस पोजीशन मे महिला पुरुष का चेहरे से बेहतर संपर्क रहता है. इस पोजीशन में दोनों के बीच काफी निकटता रहती है और यह पोजीशन उन जोड़ो के लिये बेहतर है जो रतिक्रीड़ा के दौरान एक दूसरे को चुंबन करने में ज्यादा रुचि रखते हैं. इस पोजीशन के लिये पुरुष किसी पलंग या उस जैसे किसी अन्य जगह पर पांव नीचे करके बैठ जाता है. फिर महिला उसके चेहरे की ओर अपना चेहरा करते हूए उसके लिंग के उपर या सामने अपने योनि को ले जाते हुए अपनी टांगे सामने फैला देती है. साथ ही महिला के हाथ पुरुष के शरीर से सहारा लेने के काम आते है. इस पोजीशन में रतिक्रीड़ा के दौरान पुरुष चाहे तो अपने हाथ पीछे कर सहारे के रुप में प्रयुक्त कर सकता है वहीं दूसरी ओर हाथों को महिला के कूल्हों या कमर के पास से सहारा देकर धक्कों में मदद के साथ गति भी बढ़ा सकता है. बदकिस्मती से चित्र में दिखाई गई पोजीशन धक्कों के हिसाब से उतनी बेहतर नहीं कही जा सकती (जितनी रेटिंग में दिखाई गई है) . पोजीशन के संपूर्ण आनंद के लिये स्टूल या चेयर का प्रयोग करें इसमेंमहिला को पांव के सहारे के ज्यादा सही अवसर होते हैं. इसके अलावा भी इसमें अपने हिसाब से बैठने की व्यवस्था बनाकर पोजीशन को ज्यादा आनंददायी बनाया जा सकता है.",
             uk => "Блокування роботи Верховної Ради тривало — депутати від опозиції і надалі вимагали негайно заслухати Генпрокурора та керівника Державної пенітенціарної служби щодо начебто засто ... ",
             el => "Μέτρα, το ύψος των οποίων ξεπερνά τα 13 δισ. ευρώ και δεν έχουν ακόμη προσδιοριστεί αν και περιλαμβάνονται από τον περασμένο Μάιο στο Μνημόνιο, θα ενσωματώνει το «μεσοπρόθεσμο δημοσιονομικό στρατηγικό πλαίσιο 2012-2014. Το κείμενο, που θα συνταχθεί από κοινού με την τρόικα, θα γίνει νόμος του κράτους στο τέλος Απριλίου του 2011. Το χρονοδιάγραμμα για την αποκάλυψη των κρυφών μέτρων του μνημονίου ανακοίνωσε ο Γιώργος Παπακωνσταντίνου, ενώ σχετική αναφορά έκαναν και οι εκπρόσωποι της τρόικας οι οποίοι μίλησαν για λήψη μέτρων που θα αντιστοιχούν στο 5% του ΑΕΠ. ",
             'tr' => "Ölüm bu işin kaderinde var' diyordu 1 gün önce Başbakan.. Haklı çıktı.. Hepsi öldü. Aileler isyan etti böyle kadere.. Ama 23 madencinin durumu, isyan edilmeyecek gibi değildi. Türkİye 3 gündür yerin 540 metre dibinde mahsur kalmış 30 madenci için dua ediyordu. Dün sabah patlamanın olduğu kuyudan ocağa inen ekipler, acı gerçekle yüzleşti. Hiç biri kurtulamamıştı. Cesetler yeryüzüne çıkarıldıkça feryatlar göğe yükseldi.",
             ms => 'Ahli Parlimen Jerai, Mohd Firdaus Jaafar ketika mengulas isu itu berkata Umno sepatutnya bangun untuk menentang kemungkaran yang berlaku setelah dengan jelas melibatkan perjudian yang sememangnya diharamkan oleh agama Islam. Apakah pemimpin Umno ini tidak berasa malu apabila DAP sanggup menentang pemberian lesen judi tersebut sedangkan pemimpin-pemimpin Umno hanya mendiamkan diri. Kita juga ingin bertanya kemanakah perginya suara-suara yang sebelum ini melaung-laungkan perjuangan untuk agama sepertimana yang mereka uar-uarkan, katanya.',
             fy => "Us Heit, dy't yn de himelen is jins namme wurde hillige. Jins keninkryk komme. Jins wollen barre, allyk yn 'e himel sa ek op ierde. Jou ús hjoed ús deistich brea. En ferjou ús ús skulden, allyk ek wy ferjouwe ús skuldners. En lied ús net yn fersiking, mar ferlos ús fan 'e kweade.",
             cy => 'Gwraig Huan ap Gwydion, a vu un o ladd ei gwr, ag a ddyfod ei fyned ef i hely oddi gartref, ai dad ef Gwdion brenhin Gwynedd y gerddis bob tir yw amofyn, ac or diwedd y gwnaeth ef Gaergwdion (sef: via laactua( sy yn yr awyr yw geissio: ag yn y nef y cafas ei chwedyl , lle yr oedd ei enaid: am hynny y troes y wraig iefanc yn ederyn, a ffo rhag ei thad yn y gyfraith, ag a elwir er hynny hyd heddiw Twyll huan. ',
             br => "Ul lec'hienn gouestlet d'ar brezhoneg abaoe 1995 eo Kervarker.org. Amañ e kaver a bep seurt servijoù evit deskiñ pe peurzeskiñ ar yezh, evit an dudi hag evit kejañ gant brezhonegerien eus ar bed a-bezh. Evit tennañ splet eus ar gwellañ kinniget gant al lec'hienn-mañ, n'ho peus ken emezeliñ  : digoust eo !",
#             bs => ' oči podigao prema meni, kao da se on zaista tako zove i kao da sam izgovorio nešto što se samo po sebi razumije. Je li on lud ili je potpuno otupio ležeći u tvrđavi u kojoj je, mojim odgojem, izbrisan,',
             eo => 'En multaj lokoj de Ĉinio estis temploj de drako-reĝo. Dum trosekeco oni preĝis en la temploj, ke la drako-reĝo donu pluvon al la homa mondo. Tiam drako estis simbolo de la supernatura estaĵo. Kaj pli poste, ĝi fariĝis prapatro de la plej altaj regantoj kaj simbolis la absolutan aŭtoritaton de feŭda imperiestro. La imperiestro pretendis, ke li estas filo de la drako. Ĉiuj liaj vivbezonaĵoj portis la nomon drako kaj estis ornamitaj per diversaj drakofiguroj. Nun ĉie en Ĉinio videblas drako-ornamentaĵoj, kaj cirkulas legendoj pri drakoj.',
             sq => 'Kryetari i Partisë Socialiste ka deklaruar në mënyrë të drejtpërdrejtë se është gati të pranojë marrëveshjen e propozuar nga ndërkombëtarët dhe Presidenti për hapjen e kutive të materiale zgjedhore që do të çonte edhe në përfundim e grevës së urisë dhe rinisjen e jetës parlamentare dhe politike në vend. "Unë jam i gatshëm që të pranoj marrëveshjen për hapjen e materialeve zgjedhore, më pas nëse aty del e nevojshme të hetohem kutitë e votave le të vendosë Komisioni i Venecias". Kështu deklaroi lideri socialist Edi Rama, dy orë pas deklaratës së Kryeministrit Berisha i cili përgënjështroi ambasadorin e OSBE-së, në vendin tonë, Robert Bosch, se ka një draft marrëveshje për zgjidhjen e krizës.',
             is => 'Alls fá 34 verkefni framlög frá Menningarráði Vestfjarða samtals að upphæð 15 milljónir, í fyrri styrkúthlutun ráðsins á árinu 2010. Styrkirnir eru á bilinu 75 þúsund til ein milljón króna. Umsóknir sem bárust að þessu sinni voru 78 og var samtals beðið um rúmar 55 milljónir í verkefnastyrki, en heildarupphæð fjárhagsáætlana var þrisvar sinnum hærri. Styrkirnir fara til margvíslegra verkefna í fjölbreyttum listgreinum og var áhersla að þessu sinni lögð á að styrkja verkefni sem fólu í sér nýsköpun og fjölgun atvinnutækifæra tengd listum og menningu, samvinnu og menningartengda ferðaþjónustu. „Vestfirskt menningarlíf lætur engan bilbug á sér finna og sóknarhugur og bjartsýni eru ríkjandi,“ segir í tilkynningu Menningarráðs.',
             hu => 'A magyar intézkedés által érintett tárcák vezetőinek elemzést kell készíteniük a helyzetről és ki kell dolgozniuk a szükséges törvényalkotási javaslatokat, amelyekkel minimalizálnák a magyar törvény szlovákiai hatásait és kockázatait. A kormány kezdeményezésére ezt követően rendkívüli ülést fog tartani a szlovák parlament is, hogy gyorsított eljárásban politikai választ fogadjon el.',
             af => 'Toe daal die HERE neer om die stad en die toring te besien waaraan die mensekinders gebou het. En die HERE sê: Daar is hulle nou een volk en het almal een taal! En dit is net die begin van hulle onderneming: nou sal niks vir hulle meer onmoontlik wees van wat hulle van plan is om te doen nie. Kom, laat Ons neerdaal en hulle taal daar verwar, sodat die een die taal van die ander nie kan verstaan nie. So het die HERE hulle dan daarvandaan oor die hele aarde verstrooi; en hulle het opgehou om die stad te bou. Daarom het hulle dit Babel genoem, want daar het die HERE die taal van die hele aarde verwar, en daarvandaan het die HERE hulle oor die hele aarde verstrooi',
             da => 'For to måneder siden var det tæt på, at der kom en ny ejer til indkøbscentret i centrum. Sådan lød det også for fire måneder siden. Men nu trækker det altså ud igen. Konkurskurator Lars Grøngaard har ellers været i gang med at finde nye ejere ganske længe, og siger i Folkebladet i dag, at der er interesserede til at købe Bytorv Horsens, deriblandt en række af de nuværende panthavere. Bytorv Horsens blev tilbage i maj 2007 solgt for 635 mill. kr. til EBH Ejendomme. Siden er andre dele af koncernen EBH Bank kollapset, og EBH Fonden er gået konkurs. Det fremgår af det senest tilgængelige årsregnskab fra 2008, at der er indgået et realkreditlån på 381 mill. kr., mens der i øvrigt er en samlet gæld for i alt 508 mill.',
             fi => 'Tanska nöyryyttää jälleen isolla kädellä yhtä kiekkoilun suurmaista. Tanska johtaa avauserän jälkeen Slovakiaa murskaavasti 6-0. Tanskalaiset tahkoivat ottelun alussa kiekkoa maaliin oikein urakalla. 6-0 tilanne oli jo tosiasia ajassa 13.42. Slovakia vaihtoi maalivahtiaan ajassa 4.40, jolloin tilanne oli 3-0. Peter Budaj sai väistyä Rastislav Stanan tieltä, joka imaisi vielä toiset kolme avauserässä. Kun tätä tilannetta katsoo, niin Leijona-ryhmän Tanska-tappio tuntuu varsin lievältä!',
             nl => 'Ambulancevliegtuig. Libië heeft een ambulancevliegtuig ter beschikking gesteld om het slachtoffertje naar Nederland te brengen. Naast zijn oom en tante is wordt hij ook begeleidt door een behandelend arts. Het toestel vertrekt om 10.00 uur vanuit Tripoli. Geheime locatie. Op uitdrukkelijk verzoek van de familie van Ruben wordt de aankomstplaats niet bekend gemaakt en zullen de media niet in de gelegenheid worden gesteld bij de aankomst aanwezig te zijn.',
             hr => 'Gradišćanske Hrvate u Austriji, Mađarskoj i Slovačkoj predstavlja osam folklornih i pjevačkih ansambala: Kolo Slavuj, Graničari, Štrabanci, Hajdenjaki, Čunovski bećari, Basbaritenori, Staro vino i Paxi. Kao što kaže jedan od glavnih organizatora, predsjednik društva Anno 93 Perica Mijić, emisija "Lijepom našom" obljubljena je u Hrvatskoj i dijaspori. Prije 15 godina je posljednji put gostovala u Beču, a sada je opet vrijeme da se emitira iz glavnoga grada Austrije, veli Mijić. Ulaznice se mogu nabaviti u Hrvatskom centru po cijeni od 25 eura.',
             sv => 'Det var i onsdags som den thailändska regeringen förklarade att det planerade nyvalet i november har blåsts av. Målet uppges vara att finna en annan väg till försoning, men beslutet ledde snabbt till att de redan långt gångna demonstrationerna trappades upp. Redan samma dag som påbudet meddelades hotade regeringen att från midnatt natten till torsdagen stoppa tillgången på el, telefon, mat och vatten för demonstrantlägret i centrala Bangkok. Hjälpte inte det kunde det bli aktuellt att ”med våld återta området.',
             sl => 'Letalske povezave pa bi bile še kako ugodne tudi za udeležence dveh dogodkov desetletja, univerzijado in evropsko prestolnico kulture. Zagotovo bosta ta dva dogodka nekakšen zrelostni izpit za mesto ob Dravi in hkrati najboljša priložnost, da dokažemo, da je Maribor zares mesto priložnosti. Za zdaj ocena ni najboljša, še vedno je preveč ‘soliranja’ in iskanja razlogov, zakaj kakšna zadeva ne bo uspela. Župan sam seveda ne bo mogel narediti veliko in če ne bomo stopili skupaj.',
             ro => 'Preşedintele Traian Băsescu a declarat aseară, într-o conferinţă de presă, că autorităţile „speră” ca în anul 2011 „să existe toate resursele necesare pentru a acoperi necesităţile bugetului de asigurări sociale”. „Pot spune doar intenţia, aşa cum am discutat cu Guvernul. Intenţia este să menţinem această reducere până la 31 decembrie 2010, dar este doar o intenţie, în speranţa că în bugetului anului 2011 vom avea resursele să acoperim integral necesităţile bugetului de asigurări sociale din bugetul de stat. Această acoperire depinde de foarte multe, de programul Guvernului de relansare a creşterii economice, de lupta împotriva evaziunii fiscale şi a contrabandei. Sunt foarte multe elemente, nu vreau să mă substitui programului pe care Guvernul îl va lansa  odată cu aplicarea măsurilor din scrisoarea cu FMI", a precizat Traian Băsescu.',
             id => 'Disebutkannya, berdasarkan pernyataan Ketua Desk Pilkada Nasional I Gusti Putu Artha melihat sikap ngotot Komisi Pemilihan Umum Medan tetap menggelar pemungutan suara meski sejumlah masalah belum dituntaskan, sepertinya bakal banyak pihak agar pilkada tetap diulang. Apalagi KPU melihat banyaknya masalah yang dilakukan KPU Medan itu pastilah memberi peluang untuk pilkada harus diulang. Jika dilakukan pilkada ulang, dengan demikian KPU memastikan semua anggota Komisi Pemilihan Umum Medan dipecat',
             no => 'Norge har i alle år benyttet pengepolitikken til å stimulere sentralisering av privat og offentlig virksomhet til Oslofjord regionen.  Prinsippet er det samme som vestlige land bruker som motkonjunkturpolitikk i finanskrisen. Kunnskapsløshet hos distriktsbefolkningen kan være årsaken til at denne utviklingen fortsetter å forsterke seg.Den britiske økonomen John Maynard Keynes formulerte en teori som litt forenklet sier at det offentlige kan påvirke den innenlandske etterspørselen etter varer og  tjenester ved å øke offentlige utgifter i form av økte investeringer og økt offentlig etterspørsel etter varer og tjenester. På grunn av en positiv multiplikatoreffekt vil dette bidra til en selvforsterkende vekst i økonomien. Keynes teori har fått fornyet aktualitet i forbindelse med den pågående finanskrisen. Så å si alle nasjoner har brukt offentlige stimuleringspakker for å få fart på økonomien.',
             pl => 'Zgłoszenie chęci wzięcia udziału w Konkursie poprzez wysłanie e-maila na adres: do dnia 13 maja 2010 włącznie. W temacie korespondencji elektronicznej należy wpisać słowo „Konkurs”. W treści podać swoje imię, nazwisko oraz datę urodzenia. Każdy uczestnik Konkursu zobowiązany jest do posiadania aktywnej skrzynki mailowej, w celu komunikowania się z Organizatorem. Po otrzymaniu wiadomości z chęcią wzięcia udziału w Konkursie, Organizator przesyła uczestnikowi potwierdzenie wpisania na listę obecności. Wszelkie uwagi dotyczące listy obecności należy zgłaszać Organizatorowi w terminie do 13 maja 2010 włącznie. Po tym terminie na listę obecności nie będą nanoszone żadne zmiany.',
             ga => 'Lecht Fir Death forsind áth la Coin Culaind atchíi cách Cethern mac Fintain anair dorochair oc Smirommair. oca togail docer Luan oc techt immach assa thaig. fríth lecht Lóegaire Buadaig. fri Dún Lethglasse anair; bás Blaí Briuga tria chin mná i ndesciurt Oenaig Macha. Aided Cuscraid la Mac Cecht. de luin Cheltchair croda in t-echt. dorochair Mac Cecht iar tain.',
             la => 'Horum ego puer morum in limine iacebam miser, et huius harenae palaestra erat illa, ubi magis timebam barbarismum facere, quam cavebam, si facerem, non facientibus invidere. dico haec et confiteor tibi, deus meus, in quibus laudabar ab eis, quibus placere tunc mihi erat honeste vivere. non enim videbam voraginem turpitudinis, in quam proiectus eram ab oculis tuis. nam in illis iam quid me foedius fuit, ubi etiam talibus displicebam, fallendo innumerabilibus mendaciis et paedagogum et magistros et parentes, amore ludendi, studio spectandi nugatoria et imitandi ludicra inquietudine?',
             ru => 'При чем тут Генплан? Генплан как и СССР навегда ушел в прошлое. Как и старые схемы. Руководители России должны заботиться именно о собственной стране. А не спонсировать чужую экономику за счет собственных граждан, и не повышать конкурентоспособность чужих предприятий в ущерб своим. Если нет аналога в том что было утрачено (как верфь для авианосцев в Николаеве) - нужно строить заново, обеспечивая работой своих собственных сограждан а не чужих (судьба твоей страны меня не волнует, это ваши проблемы. Ничего кроме скорейшего развала на части и присоединения бга и востока к России лично я ей вообще не желаю)',
             it => "L'operazione di Boston ha interessato una casa di Watertown e una stazione di servizio nella zona residenziale di Brookline, dove le telecamere di una tv locale hanno ripreso la polizia locale che aiutava gli agenti dell'Fbi a perquisire un'auto. Indagini e perquisizioni anche a Long Island, nello stato di New York, e in New Jersey. In tutto sarebbero state perquisiti quattro edifici. In un comunicato, le autorità di Boston hanno specificato che non esistono minacce immediate alla sicurezza.",
             fr => "Une commission d'enquête sera créée, afin d'éclaircir les raisons de l'incident et d'en définir les responsabilités. L'entreprise publique Petroleos de Venezuela est l'opérateur de cette plateforme depuis 2009. Dans un communiqué, le groupe a immédiatement rappelé que ses activités d'exploration et de production de gaz et de pétrole étaient «conformes aux procédures et standards internationaux». Assumant toutefois sa part de responsabilité, Petroleos de Venezuela a entamé sa propre enquête.",
             'es' => 'Un día después del ajuste draconiano en España, el Gobierno portugués que preside José Sócrates (socialista) ha aprobado un aumento generalizado de impuestos y un recorte drástico del gasto para ahorrar 2.100 millones de euros y reducir este año el déficit público al 7% del PIB, por debajo del 8,3% previsto inicialmente por el Ejecutivo. A diferencia de su vecino ibérico, el plan portugués ha sido pactado con el Partido Social Demócrata (PSD), principal fuerza de la oposición (conservadora). "Son necesarias para defender Portugal y defender la moneda única", ha justificado Sócrates.',
             'de' => 'soviel nehmen darf, als man ihr giebt, wenn sie nur ihre Tugend behauptet?  Das gilt auch fuer Minister und erlaubt mir, in dieser kargen Zeit unter Umstaenden auf mein Gehalt zu verzichten.  Dafuer kannst du dir zuweilen ein gutes Bild kaufen, Fraenzchen.  Du musst auch deine ehrbare Ergoetzung haben.',
             'pt' => 'As armas e os barões assassinados, que da Ocidental praia Lusitana, Por mares que nunca antes foram navegados, Passaram além de uma tal Taprobana E em perigos e guerras esforçados Mais do que prometia a força humana, E entre gente remota edificaram Novo Reino, que tanto sublinharam; ',
             'en' => "this is an example of an English text; hopefully, it won't be mistaken for a Gaelic text, this time! That is not the purpose for this line.",
             bg => 'Смисълът на правовата държава е не да защитава престъпниците. Смисълът и е да не позволи държавата да стане престъпник. Защото когато тя е такава, това е най-лошият възможен вариант за обществото. Именно поради тази причина, след векове на демократична еволюция, западът е стигнал до правовата държава. Тя не е наше изобретение, не е измислена от българите или от Тройната коалиция. Тя е разумният избор на доста по-мъдри от нас нации.',
);

for my $lang (get_all_languages()) {
    die "\n\n*** $lang test is not available." unless exists($texts{$lang});
    my @x = langof($texts{$lang});
    is($x[0], $lang, "Identifying $lang text...");
    cmp_ok($x[1],'>','0.14');
    cmp_ok(confidence(@x),'>','0.50');
}





my @pt = langof(<<EOT);

as armas e os barões assinalados que, da ocidental praia lusitana, por
mares nunca de antes navegados, passaram ainda além da taprobana e em
perigos e guerras esforçados, mais do que prometia a força humana, e
entre gente remota edificaram, novo reino, que tanto sublimaram; e
também as memórias gloriosas, daqueles reis que foram dilatando a fé,
o império, e as terras viciosas, de áfrica e de ásia andaram
devastando, e aqueles que por obras valerosas, se vão da lei da morte
libertando: cantando espalharei por toda parte, se a tanto me ajudar o
engenho e arte. cessem do sábio grego e do troiano as navegações
grandes que fizeram; cale-se de alexandro e de trajano a fama das
vitórias que tiveram; que eu canto o peito ilustre lusitano, a quem
neptuno e marte obedeceram. cesse tudo o que a musa antiga canta, que
outro valor mais alto se alevanta.  e vós, tágides minhas, pois criado
tendes em mi um novo engenho ardente se sempre, em verso humilde,
celebrado foi de mi vosso rio alegremente, dai-me agora um som alto e
sublimado, um estilo grandíloco e corrente, por que de vossas águas
febo ordene que não tenham enveja às de hipocrene.  dai-me húa fúria
grande e sonorosa, e não de agreste avena ou frauta ruda, mas de tuba
canora e belicosa, que o peito acende e a cor ao gesto muda; dai-me
igual canto aos feitos da famosa gente vossa, que a marte tanto ajuda;
que se espalhe e se cante no universo, se tão sublime preço cabe em
verso.  e vós, ó bem nascida segurança da lusitana antiga liberdade, e
não menos certíssima esperança de aumento da pequena cristandade; vós,
ó novo temor da maura lança, maravilha fatal da nossa idade, dada ao
mundo por deus (que todo o mande, pera do mundo a deus dar parte
grande); vós, tenro e novo ramo florecente, de húa árvore, de cristo
mais amada que nenhúa nascida no ocidente, cesárea ou cristianíssima
chamada, (vede-o no vosso escudo, que presente vos amostra a vitória
já passada, na qual vos deu por armas e deixou, as que ele pera si na
cruz tomou); vós, poderoso rei, cujo alto império, o sol, logo em
nascendo, vê primeiro; vê-o também no meio do hemisfério, e, quando
dece, o deixa derradeiro; vós, que esperamos jugo e vitupério do torpe
lsmaelita cavaleiro, do turco oriental e do gentio que inda bebe o
licor do santo rio: inclinai por um pouco a majestade, que nesse tenro
gesto vos contemplo, que já se mostra qual na inteira idade, quando
subindo ireis ao eterno templo; os olhos da real benignidade ponde no
chão: vereis um novo exemplo de amor dos pátrios feitos valerosos, em
versos devulgado numerosos.  vereis amor da pátria, não movido de
prêmio vil, mas alto e quase eterno; que não é prêmio vil ser
conhecido por um pregão do ninho meu paterno. ouvi: vereis o nome
engrandecido daqueles de quem sois senhor superno, e julgareis qual é
mais excelente, se ser do mundo rei, se de tal gente. ouvi: que não
vereis com vãs façanhas, fantásticas, fingidas, mentirosas, louvar os
vossos, como nas estranhas musas, de engrandecer-se desejosas: as
verdadeiras vossas são tamanhas, que excedem as sonhadas, fabulosas,
que excedem rodamonte e o vão rugeiro, e orlando, inda que fora
verdadeiro.  por estes vos darei um nuno fero, Que fez ao Rei e ao
Reino tal serviço, Um Egas e um Dom Fuas, que de Homero A cítara para
eles só cobiço; Pois polos Doze Pares dar-vos quero Os Doze de
Inglaterra e o seu Magriço; Dou-vos também aquele ilustre Gama, Que
para si de Eneias toma a fama. Pois, se a troco de Carlos, Rei de
França, Ou de César, quereis igual memória, Vede o primeiro Afonso,
cuja lança Escura faz qualquer estranha glória; E aquele que a seu
Reino a segurança Deixou, co a grande e próspera vitória; Outro
Joanne, invicto cavaleiro; O quarto e quinto Afonsos e o terceiro.
Nem deixarão meus versos esquecidos Aqueles que, nos Reinos lá da
Aurora, Se fizeram por armas tão subidos, Vossa bandeira sempre
vencedora: Um Pacheeo fortíssimo e os temidos Almeidas, por quem
sempre o Tejo chora, Albuquerque terribil, Castro forte, E outros em
quem poder não teve a morte.  E, enquanto eu estes canto, e a vós não
posso, Sublime Rei, que não me atrevo a tanto, Tomai as rédeas vós do
Reino vosso: Dareis matéria a nunca ouvido canto.  Comecem a sentir o
peso grosso (Que polo mundo todo faça espanto) De exércitos e feitos
singulares De África as terras e do Oriente os mares.
EOT

is($pt[0],'pt');
cmp_ok($pt[1],'>','0.14');
cmp_ok(confidence(@pt),'>','0.50');
