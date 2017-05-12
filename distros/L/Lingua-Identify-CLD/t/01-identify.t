#!perl -T

use utf8;

use Test::More;

use Lingua::Identify::CLD;

my %langs = (
             GALICIAN => q{Baixo a fachada de prosperidade económica o fenómeno inmobiliario agacha a emigración, a falla de industrias, a desestruturación económica e a especulación perfilando un futuro no que os pobos se desartellan e onde se promove un desprezo total ao contorno, un contorno que en certa medida é o que nos di quen somos.},
             CATALAN => q{En la nostra vida quotidiana actual ja no podem fer abstracció de la tècnica. Els estris tècnics, aparells, maquinària ens envolten per tots cantons i diàriament. No obstant la tècnica mostra moltes facetes. Un martell, unes tenalles, un ganivet: són instruments i llur ús és quasi tan antic com la humanitat mateixa. En les vitrines de tot museu de pre-història i d´història antiga hi ha: pics, pedres fogueres, tal com foren emprats pels avantpassats en la cacera. Però els mecanismes amb què foren   construïdes les piràmides a Egipte eren més elaborats: màquines simples com rampes o cabrestants.},
             SPANISH => q{Las normas relativas a los derechos fundamentales y a las libertades que la Constitución reconoce se interpretarán de conformidad con la Declaración Universal de Derechos Humanos y los tratados y acuerdos internacionales sobre las mismas materias ratificados por España.},
             IRISH => q{Saolaítear na daoine uile saor agus comhionann ina ndínit agus ina gcearta. Tá bua an réasúin agus an choinsiasa acu agus dlíd iad féin d'iompar de mheon bráithreachais i leith a chéile.},
             SLOVENIAN => q{Lionel Messi je sinoči že tretjič zapored prejel Zlato žogo. Na svečani razglasitvi nagrad svetovne nogometne zveze za minulo leto v Zürichu, je največ pozornosti požel trenutno prvi svetovni nogometni junak, 24-letni Argentinec, ki z reprezentanco še ni napravil največjih stvari.},
             ICELANDIC => q{Landsbankinn veitti í dag 5 milljónir króna í umhverfisstyrki úr Samfélagssjóði Landsbankans. Veittir voru 17 styrkir, þrír að upphæð 500 þúsund krónur hver og tólf að fjárhæð 250 þúsund krónur. Ríflega 130 umsóknir bárust.},
             NORWEGIAN => q{Utviklingen er slående. Mens tre av fire små helsekontor vurderer nettbrett, har ifølge en annen udnersøkelse, som Kaiser Health News skriver om, at bare én av hundre, sykehus i USA formelt bruker nettbrett. Det kommer også frem at Apple foreløpig er den store vinneren på dette markedet. Hele 70 prosent av legene ønsker seg en Ipad, mens bare tre av ti vurderer andre typer brett. },
             SWEDISH => q{Jag var ute och cyklade en sväng igår kväll. Skulle cykla förbi ett stort gäng killar då en av dem plötsligt drog upp en pistol och sa till mig att stanna. Har alltid funderat på hur jag skulle reagera i en sådan situation. Inte helt förvånande så stannade jag och var beredd på att ge från mig allt utan protest. Rädd för mitt liv.},
             DANISH => q{Som noget af det første her i det nye år, er jeg gået i gang med at lave en del ændringer på siden og disse vil for alvor komme til at slå igennem i løbet af de næste måneder. Jeg har en målsætning om at siden skal vækste ganske kraftigt i år og for at kunne gøre dette, er det nødvendigt at lave en del ændringer, så flere får glæde af siden og de artikler, der er her.},
             GERMAN => q{Deutschland, Deutschland über alles, Über alles in der Welt, Wenn es stets zu Schutz und Trutze Brüderlich zusammenhält. Von der Maas bis an die Memel, Von der Etsch bis an den Belt, Deutschland, Deutschland über alles, Über alles in der Welt! },
             ITALIAN => q{Fratelli d'Italia, l'Italia s'è desta, dell'elmo di Scipio s'è cinta la testa. Dov'è la Vittoria? Le porga la chioma, ché schiava di Roma Iddio la creò.},
             FRENCH => q{Allons enfants de la Patrie, Le jour de gloire est arrivé! Contre nous de la tyrannie, L'étendard sanglant est levé, Entendez-vous dans les campagnes Mugir ces féroces soldats?},
             PORTUGUESE => q{As armas e os barões assinalados, que da ocidental praia lusitana, por mares nunca de antes navegados, passaram ainda além da traprobana},
             ENGLISH => q{confiscation of goods is assigned as the penalty part most of the courts consist of members and when it is necessary to bring public cases before a jury of members two courts combine for the purpose the most important cases of all are brought jurors or},
             HINDI => q{
  नेपाल एसिया 
  मंज अख मुलुक
   राजधानी काठ
  माडौं नेपाल 
  अधिराज्य पेर
  ेग्वाय 
  दक्षिण अमेरि
  का महाद्वीपे
   मध् यक्षेत्
  रे एक देश अस
  ् ति फणीश्वर
   नाथ रेणु 
  फिजी छु दक्ष
  िण प्रशान् त
   महासागर मंज
   अख देश बहाम
  ास छु केरेबि
  यन मंज 
  अख मुलुख राज
  धानी नसौ सम्
   बद्घ विषय ब
  ुरुंडी अफ्री
  का महाद्वीपे
   मध् 
  यक्षेत्रे दे
  श अस् ति सम्
   बद्घ विषय
},
             CROATIAN =>  q{Zimski popusti rastu i u Dieselu. Evo što je sve sniženo i koliko: 50% na kape, šalove, čarape, nakit i ženski donji veš. 40% na jakne, košulje, majice, pulovere, kožne jakne, remenje, cipele, torbe 30% na traperice, hlače, suknje, tajice, haljine, kombinezone, muški donji veš, veste, tenisice, naočale, biciklei kacige.},
             SERBIAN => q{Ako se za neko lovačko udruženje može reći da je primer kako se neguje i čuva tradicija, onda je to kragujevačka ’’Šumadija’’. A nije ni čudno, jer je najstarije lovačko udruženje u Srbiji i jedno od osnivača Lovačkog saveza Srbije. Jedna od njihovih manifestacija održava se svakog 9. septembra, na dan kada su kragujevački lovci 1901. godine podigli i osveštali Spomen česmu u manastiru Divostin, posvećenu prvom počasnom predsedniku Saveza lovačkih udruženja u Kraljevini Srbiji - Milanu Obrenoviću. Kod česme se održava parastos, u znak pijeteta i pomena najvećem poborniku lovstva Srbije},
             ARMENIAN => q{«Իմ առաջին լուրջ ձեռքբերումը ընտանիքս է, եթե իմ կինը չլիներ այն կինը, որը հիմա կա, ես հաջողությունների չէի հասնի: Շատ քիչ կանայք են այնպես անում, որ իրենց տղամարդիկ առաջատար լինեն»},
             ALBANIAN => q{Shqisa e prekjes zhvillohet në javën e tetë të tremujorit të parë. Ndjeshmëria në prekje lajmërohet së pari në faqe, mandej zgjerohet në zonën e gjenitaleve (java e 10), pëllëmbë (java e 11), dhe shputa (java e 12). Në atë periudhë të shtatzanisë gjatë vizitës me ultrazë mund të vëreni nëse foshnja thith gishtin apo nëse prek pjesët tjera të trupit. Gjatë javës së 17 zhvillohet ndjeshmëria në prekje të abdomenit, ndërsa gjer në javën e 32 të gjitha pjesët e trupit të foshnjes në bark janë të ndjeshme në nxehtësi, në të ftohtit, në shtypje apo dhembje.},
             RUSSIAN => q{Теоретическая часть курса и дегустации проходили в здании школы. Особенно запомнилось занятие, когда мы сами пытались создать бордосский ассамбляж, смешивая в разных пропорциях вина каберне-совиньон, мерло и каберне-фран. Практическая часть обучения проходила после обеда. Мы выезжали в разные хозяйства региона, на виноградники, где нас радушно встреча­ли владельцы шато, показывали нам свои владения, винодельни и погреба, устраивали интересные дегустации и дискуссии. В конце курса нас ждал экзаменационный тест и дегустация вслепую, в ходе которой мы должны были определить, что за вино находится в сто­ящих перед нами бокалах},
             BULGARIAN => q{Добре поддържаната коса придава допълнително самочувствие и на всяка жена. С невероятната оферта на салон за красота "Нелита" ще можете да боядисате косата си, да се насладите на масажно измиване и заслепяваща прическа направена със сешоар.},
             CHINESE => q{尊敬的用户您好：您访问的网站被机房安全管理系统拦截，有可能是以下原因造成：您的网站未备案，或者原备案号被取消。域名在访问黑名单中。 其它原因造成的人为对您域名的拦截},
             CZECH => q{Jsme malou nemocnicí, proto v poskytování zdravotní péče nemůžeme soutěžit s velkými, které jsou zaměřeny na péči komplexní nebo jsou úzce specializovány. Jde nám o to, aby se pacienti u nás cítili pokud možno jako doma. Snažíme se vytvořit takové prostředí, v němž léčba, přístup k pacientovi, komunikace s ním, respektování jeho potřeb a zájmů budou tvořit jednotu s kvalitou poskytované péče.},
             BELARUSIAN => q{Следчы камітэт на працягу 2012 года павінен дакладна выбудаваць сваю работу і стаць паўнацэннай дзейснай структурай. Такую задачу паставіў 9 студзеня Прэзідэнт Рэспублікі Беларусь Аляксандр Лукашэнка, прымаючы з дакладам Старшыню Следчага камітэта Валерыя Вакульчыка.},
             UKRAINIAN => q{    Верховна Рада України від імені Українського народу - громадян України всіх національностей, виражаючи суверенну волю народу, спираючись на багатовікову історію українського державотворення і на основі здійсненого українською нацією, усім Українським народом права на самовизначення, дбаючи про забезпечення прав і свобод людини та гідних умов її життя, піклуючись про зміцнення громадянської злагоди на землі України, прагнучи розвивати і зміцнювати демократичну, соціальну, правову державу,},
            );

my %extra = (
#             PIGLATIN => q{c0NFI5c@7i0N 0F g0od5 i$ a5signed @5 7he P3N@l7Y P@r7 m057 of th3 c0UR75 C0n$I57 0f M3M83R5 @ND wheN I7 i$ n3C35$@ry 70 8rinG pU8Lic Ca53$ 83f0r3 @ JUry 0F m3m83r5 7W0 c0Ur7$ c0M8in3 F0r th3 PuRpo$e 7h3 M0$7 imp0rt@n7 Ca$35 of @LL @R3 8R0Ugh7 Jur0r$ 0r},
            );

plan tests => scalar(keys %langs) + 2 * scalar(keys %extra);

my $cld = Lingua::Identify::CLD->new();
for my $lang (keys %langs) {
    is $cld->identify($langs{$lang}), $lang, "Identifying $lang";
}

for my $lang (keys %extra) {
    is $cld->identify($extra{$lang}, allowExtendedLanguages => 1), $lang, "Identifying $lang";
    is $cld->identify($extra{$lang}, allowExtendedLanguages => 0), $lang, "Identifying $lang";
}
