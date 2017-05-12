#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More tests => 492;
use Lingua::GA::Gramadoir::Languages;
use Lingua::GA::Gramadoir;
use Encode 'decode';

BEGIN { use_ok('Lingua::GA::Gramadoir') };

my $lh = Lingua::GA::Gramadoir::Languages->get_handle('ga');

ok( defined $lh, 'Irish language handle created' );

my $gr = new Lingua::GA::Gramadoir(
			fix_spelling => 1,
			use_ignore_file => 0,
			interface_language => 'ga',
			input_encoding => 'ISO-8859-1');

ok (defined $gr, 'grammar checker created' );

my $test = <<'EOF';
N� raibh l�on m�r daoine bainteach leis an scaifte a bh� ag iarraidh mioscais a choth�.
Ach thosna�os-sa ag l�amh agus bhog m� isteach ionam f�in.
Tabhair go leor leor de na na ruda� do do chara, a Chaoimh�n.
Seo � a chuntas f�in ar ar tharla ina dhiaidh sin (OK).
Aithn�onn ciar�g ciar�g eile (OK).
Go deo deo ar�s n� fheicfeadh s� a cheannaithe snoite (OK).
Tabhair iad seo do do mh�thair (OK).
Sin � � ...  T� s� anseo (OK)!
T� siad le feice�il ann le fada fada an l� (OK).
Bh� go leor leor le r� aici (OK).
Cuirfidh m� m� f�in in aithne d� l�n cin�ocha (OK).
Fanann r�alta chobhsa� ar feadh idir milli�n agus milli�n milli�n bliain (OK).
Bh�odh an-t�ir ar sp�osra� go m�r m�r (OK).
Bh� an dara cup�n tae �lta agam nuair a th�inig an fear m�r m�r.
Agus sin sin de sin (OK)!
Chuaigh s� in olcas ina dhiaidh sin agus bh� an-fhait�os orthu.
Tharla s� seo ar l� an-m�fheili�nach, an D�ardaoin.
N� maith liom na daoine m�intleacht�la.
Tr� chomhtharl�int, bh� siad sa tuaisceart ag an am.
S�lim n�rbh ea, agus is docha nach bhfuil i gceist ach easpa smaoinimh.
T� s�il le feabhas nuair a thos�idh airgead ag teacht isteach � ola agus g�s i mBearna Timor.
Bh� s� cos�il le cla�omh Damocles ar crochadh sa sp�ir.
Beidh nuacht�in shuaracha i ngreim c� nach mbeadh cinsireacht den droch-chin�al i gceist.
Bh� s� p�irteach sa ch�ad l�iri� poibl� de Adaptation.
Beidh an tionchar le moth� n�os m� i gc�s comhlachta� �ireannacha mar gur mionairgeadra � an punt.
Bh� an dream d�-armtha ag iarraidh a gcuid gunna�.
An bhfuil uachtar roeite agattt?
B�onn an ge�l ag satailt ar an dubh.
Ach go rithe an fh�r�antacht mar uisce agus an t-ionracas mar shruth gan d�sc (OK)!
Ba iad mo shinsear rithe Ch�ige Uladh.
Is iad na tr� chol�n sin le cheile an tAontas Eorpach.
Scri��il s� an glas seo ar ch�l an doras.
Ach bh� m� ag lean�int ar aghaidh an t-am ar fad leis (OK).
Bhain s� sult as cl�r toghch�in TG4 a chur i l�thair an mh� seo caite (OK).
Bhrostaigh s� go dt� an t-ospid�al (OK).
Sa dara alt, d�an cur s�os ar a bhfaca siad sa Sp�inn.
D'oirfeadh s�ol �iti�il n�os fearr n� an s�ol a hadhlaic s� anuraidh.
N� hinis do dhuine ar bith � (OK).
T� ceacht stairi�il uath�il do chuairteoir� san t-ionad seo.
Faightear an t-ainm isteach faoin t�r freisin (OK).
C�n t-ainm at� air (OK)?
Aistr�odh � go tSualainnis, Gearm�inis, agus Fraincis.
C�n chaoi a n-aims�onn scoil an tseirbh�s seo (OK)?
T� sonra� ann faoin tsl� ina n-iarrtar taifid faoin Acht (OK).
C�n tsl� bheatha a bh� ag Naoi (OK)?
Bh� imn� ag teacht ar dhearth�ir an tsagairt (OK).
T� s� riachtanach ar mhaithe le feidhmi� an phlean a bheidh ceaptha ag an eagra�ocht ceannasach.
Bh� na ranganna seo ar si�l an bhliain seo caite (OK).
L�imeann an fharraige c�ad m�adar suas sa sp�ir (OK).
Briseadh b�d �amoinn �ig o�che gaoithe m�ire (OK).
Bh�odh na daoir scaoilte saor �na gcuid oibre agus bh�odh saoirse cainte acu (OK).
Bh� m� ag t�g�il balla agus ag baint m�na (OK).
Is as Londain Shasana m� � dh�chas (OK).
Se�n a d'imigh ar iarraidh ar o�che ghaoithe m�ire.
Mar chuid den socr� beidh Michelle ag labhairt Ghaeilge ag �c�id� poibl�.
Tugadh cuireadh d� a theacht i l�thair an fhir m�ir.
Tugaimid � amach le haghaidh b�ile Polain�isigh. 
Bh� torann an dorais cloiste agam (OK).
T� na lachain slachtmhara ar eitilt.
Mhair cuid mh�r d�r sinsir c�ad caoga bliain � shin (OK).
T� s� le cloiste�il sna me�in gach seachtain (OK).
D�anann siad na breise�in brabhs�la don tionscal r�omhaireachta.
Is ar �isc mara agus ar na hainmhithe mara eile at�imid ag d�ri�.
Chonaic m� l�on agus crainn t�g�la ann (OK).
Bh� picti�ir le feice�il ar sc�ile�in theilif�se ar fud an domhain.
Maidin l� ar na mh�rach thug a fhear gaoil cuairt air.
Cad � mar a t� t�?
Bh� deich tobar f�oruisce agus seacht� crann pailme ann.
Rinneadh an roinnt do na naoi treibh go leith ar chrainn.
Bh� ocht t�bla ar fad ar a mara�d�s na h�obairt�.
S�ra�onn s� na seacht n� na hocht bliana.
T� seacht lampa air agus seacht p�opa ar gach ceann d�obh.
A aon, a d�, a tr�.
Ba � a aon aidhm ar an saol daoine a ghn�th� don ch�is (OK).
T� an Rialtas tar �is �it na Gaeilge i saol na t�re a ceisti�.
Ach sin sc�al eile mar a d�arfadh an t� a d�arfadh (OK).
Is ioma� uair a fuair m� locht ar an rialtas (OK).
Bh�odar ag r� ar an aonach gur agamsa a bh� na huain ab fearr.
N� bheidh ach mhallacht i nd�n d� � na cin�ocha agus fuath � na n�isi�in.
N� theasta�onn uaithi ach bheith ina ball den chumann (OK).
An bhfuil aon uachtar reoite ar an cuntar?
Baintear feidhm as chun aic�d� s�l a mhaol� (OK).
M� shu�onn t� ag bhord le flaith, tabhair faoi deara go c�ramach c�ard at� leagtha romhat.
T� s� ag ullmh� �.
Chuir s� ag machnamh � (OK).
Bh� neach oilbh�asach ag lean�int m�.
Bl�tha�onn s� amhail bhl�th an mhachaire.
An chuir an bhean bheag m�r�n ceisteanna ort?
An ndeachaigh t� ag iascaireacht inniu (OK)?
An raibh aon bhealach praitici�il eile chun na hIndia (OK)?
An dhearna m� an rud ceart?
An bainim sult as b�s an drochdhuine?
An �ireodh n�os fearr leo d� mba mar sin a bheid�s (OK)?
N� f�idir an Gaeltacht a choinne�il mar r�igi�n Gaeilge go n�isi�nta gan athr� bun�sach.
I gc�s An Comhairle Eala�on n� m�r � seo a dh�anamh.
An bean sin, t� s� ina m�inteoir.
Chuala s� a mh�thair ag labhairt chomh caoin seo leis an mbean nua (OK).
Chinn s� an cruinni� a chur ar an m�ar fhada (OK).
Cad � an chomhairle a thug an ochtapas d�?
An Acht um Chomhionannas Fosta�ochta.
Dath b�nbhu� �adrom at� ar an adhmad (OK).
Ch�irigh s� na lampa� le solas a chaitheamh os comhair an coinnleora.
Comhl�n�idh saor�nacht an Aontais an saor�nacht n�isi�nta agus n� ghabhfaidh s� a hionad.
Ritheann an Sl�ine tr�d an ph�irc.
N� raibh guth an s�il�ara le clos a thuilleadh.
T� sin r�ite cheana f�in acu le muintir an t�re seo.
Is � is d�ich� go raibh baint ag an eisimirce leis an laghd� i l�on an gcainteoir� Gaeilge.
Is iad an tr� chol�n le ch�ile an tAontas Eorpach.
Sheol an ceithre mh�le de na meirligh amach san fh�sach (OK).
N� bh�onn an dh�ograis n� an dh�thracht i gceist.
An fh�idir le duine ar bith eile breathn� ar mo script?
N� bh�onn aon dh� chl�r as an chrann ch�anna mar a ch�ile go d�reach.
N� bheidh aon bunt�iste againn orthu sin.
Rogha aon de na focail a th�inig i d'intinn.
N� hith aon ar�n gabh�la mar aon l�i (OK).
Freagair aon d� cheann ar bith d�obh seo a leanas (OK).
Bh�omar ag f�achaint ar an Ghaeltacht mar ionad chun feabhas a chur ar ar gcuid Gaeilge.
Bh� daoine le f�il i Sasana a chreid gach ar d�radh sa bholscaireacht.
T� treoirl�nte mionsonraithe curtha ar fail ag an gCoimisi�n.
Bh� cead againn fanacht ag obair ar an talamh ar fead tr� mh�.
T� s� an ch�ad su�omh gr�as�n ar bronnadh teastas air (OK).
Cosc a bheith ar cic a thabhairt don sliotar.
Cosc a bheith ar CIC leabhair a dh�ol (OK).
Beidh cairde d� cuid ar Gaeilgeoir� iad (OK).
Ar gcaith t� do chiall agus do ch�adfa� ar fad?
N� amh�in �r dh� chosa, ach nigh �r l�mha!
Gheobhaimid maoin de gach s�rt, agus l�onfaimid �r tithe le creach.
N�l aon n� arbh fi� a shant� seachas �.
Ba maith liom fios a thabhairt anois daoibh.
D�irt daoine go mba ceart an poll a dh�nadh suas ar fad.
Ba eol duit go hioml�n m'anam.
T� beinn agus buaic orm.
D'fhan beirt buachaill sa champa.
D'fhan beirt bhuachaill cancrach sa champa.
Moth�idh Pobal Osra� an bheirt laoch sin uathu (OK).
N� amh�in bhur dh� chosa, ach nigh bhur l�mha!
D�anaig� beart leis de r�ir bhur briathra.
Cad d�arfaidh m� libh mar sin?
C� mh�id gealladh ar briseadh ar an Indiach bocht?
Nach raibh a fhios aige c� mh�ad daoine a bh�onn ag �isteacht leis an st�isi�n.
Faigh amach c� mh�ad salainn a bh�onn i sampla d'uisce.
C� �it a nochtfadh s� � f�in ach i mBost�n!
C� ch�s d�inn bheith ag m�inne�il thart anseo?
C� mhinice ba riachtanach d� stad (OK)?
C� n-oibrigh an t-�dar sular imigh s� le ceol?
C� raibh na ruda� go l�ir (OK)?
C� cuireann t� do thr�ad ar f�arach?
C� �s�idfear an mh�in?
C�r f�g t� eisean?
C�r bhf�g t� eisean?
C�r f�gadh eisean (OK)?
Sin � a dh�antar i gcas cuntair oibre cistine.
C� iad na fir seo ag fanacht farat?
C� ea, rachaidh m� ann leat (OK).
C� an ceart at� agamsa a thuilleadh f�s a lorg ar an r�?
D'fhoilsigh s� a c�ad cnuasach fil�ochta i 1995.
Chuir siad fios orm ceithre uaire ar an tsl� sin.
Beidh ar Bhord Feidhmi�ch�in an tUachtar�n agus ceithre ball eile.
T� s� tuigthe aige go bhfuil na ceithre d�ile ann (OK).
C�n amhr�na� is fearr leat?
C�n sl� ar fhoghlaim t� an teanga?
Cha dtug m� cur s�os ach ar dh� bhabhta colla�ochta san �rsc�al ar fad (OK).
Bh� an ch�ad cruinni� den Choimisi�n i Ros Muc i nGaeltacht na Gaillimhe.
T� s� chomh iontach le sneachta dearg.
Chuir m� c�ad punt chuig an banaltra.
N�l t� do do sheoladh chuig dhaoine a labhra�onn teanga dhothuigthe.
Seo deis iontach chun an Ghaeilge a chur chun chinn.
Tiocfaidh deontas faoin alt seo chun bheith in�octha (OK).
D'�ir�d�s ar maidin ar a ceathair a clog.
Shocraigh s� ar an toirt gur choir an t-�bhar t�bhachtach seo a phl� leis na daoine.
Caithfidh siad turas c�ig uaire a chloig a dh�anamh.
Bh� s� c�ig bhanl�mh ar fhad, c�ig banl�mh ar leithead.
Beirim mo mhionn dar an beart a rinne Dia le mo shinsir.
An l� dar gcionn nochtadh gealltanas an Taoisigh sa nuacht�n.
Sa dara bliain d�ag d�r braighdeanas, th�inig fear ar a theitheadh.
Beidh pic�id ar an monarcha �na naoi a chlog maidin Dh� Luain.
B�onn ranganna ar si�l o�che Dh�ardaoin.
Cuireadh t�s le himeachta� ar Dh�ardaoin na F�ile le cluiche m�r.
D'oibrigh m� liom go dt� D� Aoine.
M�le naoi gc�ad a hocht nd�ag is fiche.
Feicim go bhfuil aon duine d�ag curtha san uaigh seo.
D'fh�s s� ag deireadh na nao� haoise d�ag agus f�s an n�isi�nachais (OK).
Tabharfaidh an tUachtar�n a �r�id ag leath i ndiaidh a d� d�ag D� Sathairn.
Bhuail an clog a tr� dh�ag.
T� tr� d�ag litir san fhocal seo.
T�gfaidh m� do coinnleoir �na ionad, mura nd�ana t� aithr�.
Is c�is imn� don pobal a laghad maoinithe a dh�antar ar Na�scoileanna.
Daoine eile at� ina mbaill den dhream seo.
Creidim go raibh siad de an thuairim seo.
T� dh� teanga oifigi�la le st�das bunreacht�il � labhairt sa t�r seo.
Dh� fiacail l�rnacha i ngach aon chomhla.
Rug s� greim ar mo dh� gualainn agus an fhearg a bh� ina s�ile.
Bh� an d� taobh seo d� phearsantacht le feice�il go soil�ir.
Bh� Eibhl�n ar a dh� gl�in (OK).
Is l�ir nach bhfuil an dh� theanga ar chomhch�im lena ch�ile.
Tion�ladh an ch�ad dh� chom�rtas i nGaoth Dobhair.
C� bhfuil feoil le f�il agamsa le tabhairt do an mhuintir?
Is amhlaidh a bheidh freisin do na tagairt� do airteagail.
T� s� de ch�ram seirbh�s a chur ar f�il do a chustaim�ir� i nGaeilge.
Seinnig� moladh ar an gcruit do �r m�thair.
Is � seo mo Mhac muirneach do ar thug m� gnaoi.
T� an domhan go l�ir faoi suaimhneas.
Caithfidh pobal na Gaeltachta iad f�in cinneadh a dh�anamh faoi an Ghaeilge.
Cuireann s� a neart mar chrios faoi a coim.
Cuireann s� cin�ocha faoi �r smacht agus cuireann s� n�isi�in faoin�r gcosa.
T� dualgas ar an gComhairle sin tabhairt faoin c�ram seo.
Tugadh mioneolas faoin dtionscnamh seo in Eagr�n a haon.
Bh� l�ch�ir ar an Tiarna faoina dhearna s�!
N� bheidh gear�n ag duine ar bith faoin gciste fial at� faoin�r c�ram.
Beidh par�id L� Fh�ile Ph�draig i mBost�n.
T� F�ile Bhealtaine an Oireachtais ar si�l an tseachtain seo (OK).
F�gtar na m�lte eile gan gh�aga n� radharc na s�l.
T� ar chumas an duine saol ioml�n a chaitheamh gan theanga eile � br� air.
T� gruaim mh�r orm gan Chaitl�n.
Deir daoine eile, �fach, gur dailt�n gan maith �.
Fuarthas an fear marbh ar an tr�, a chorp gan m�chail gan ghort�.
D�irt s� liom gan p�sadh (OK).
Na duilleoga ar an ngas beag, cruth lansach orthu agus iad gan cos f�thu (OK).
D'fh�g sin gan meas d� laghad ag duine ar bith air (OK).
T� m� gan cos go br�ch (OK).
N�l s� ceadaithe aistri� � rang go ch�ile gan cead a fh�il uaim (OK).
Is st�it ilteangacha iad cuid mh�r de na st�it sin at� aonteangach go oifigi�il.
N� bheidh bonn compar�ide ann go beidh tortha� Dhaon�ireamh 2007 ar f�il.
Rug s� ar ais m� go dhoras an Teampaill.
Tiocfaidh coimhlint� chun tosaigh sa Chumann � am go ch�ile (OK).
Is turas iontach � an turas � bheith i do thosaitheoir go bheith i do mh�inteoir (OK).
Chuaigh m� suas go an doras c�il a chaisle�in.
Th�inig P�l � Coile�in go mo theach ar maidin.
Bh� an teachtaireacht dulta go m'inchinn.
Tar, t�anam go dt� bhean na bhf�seanna.
Agus rachaidh m� siar go dt� th� tr�thn�na, m�s maith leat (OK).
Ba mhaith liom gur bhf�gann daoine �ga an scoil agus iad ullmhaithe.
Bhraith m� gur fuair m� boladh trom tais uathu.
An ea nach c�s leat gur bhf�g mo dheirfi�r an freastal f�msa i m'aonar?
B'fh�idir gurbh fearr � seo duit n� leamhnacht na b� ba mhilse i gcontae Chill Mhant�in.
T� ainm i n-easnamh a mbeadh coinne agat leis.
T� ainm i easnamh a mbeadh coinne agat leis.
An bhfuil aon uachtar reoite agat i dh� chuisneoir?
An bhfuil aon uachtar reoite agat i cuisneoir?
An bhfuil aon uachtar reoite agat i chuisneoir?
T�imid ag lorg 200 Club Gailf i gach cearn d'�irinn.
An bhfuil aon uachtar reoite agaibh i bhur m�la?
Bh� sl�m de ph�ip�ar tais ag cruinni� i mhullach a ch�ile.
Fuair Derek Bell b�s tobann i Phoenix (OK).
T� n�os m� n� 8500 m�inteoir ann i thart faoi 540 scoil (OK).
An bhfuil aon uachtar reoite agat i an chuisneoir?
An bhfuil aon uachtar reoite agat i na cuisneoir�?
An bhfuil aon uachtar reoite i a cuisneoir?
Roghnaigh na teangacha i a nochtar na leathanaigh seo.
Rinne gach cine � sin sna cathracha i ar lonna�odar.
An bhfuil aon uachtar reoite i �r m�la?
Thug s� seo deis dom breathn� in mo thimpeall.
Ph�s s� P�draig, fear �n mBlascaod M�r, in 1982.
Ph�s s� P�draig, fear �n mBlascaod M�r, in 1892 (OK).
Theastaigh uaibh beirt bheith in bhur scr�bhneoir� (OK).
Beidh an sp�rt seo � imirt in dh� ionad (OK).
Cad � an rud is m� faoi na Gaeil ina chuireann s� suim?
T� beirfean in�r craiceann faoi mar a bheimis i sorn.
Is tuar d�chais � an m�id dul chun cinn at� d�anta le bhlianta beaga.
Leanaig� oraibh le bhur nd�lseacht d�inn (OK).
Baineann an sc�im le thart ar 28,000 miond�olt�ir ar fud na t�re (OK).
N�or cuireadh aon tine s�os, ar nd�igh, le chomh bre� is a bh� an aimsir (OK).
T� s� ag teacht le th� a fheice�il (OK).
D'fh�adfadh t�bhacht a bheith ag baint le an gc�ad toisc d�obh sin.
Molann an Coimisi�n go maoineofa� sc�im chun tac� le na pobail.
Labhra�odh gach duine an fh�rinne le a chomharsa.
Le halt 16 i nd�il le hiarratas ar ord� le a meastar gur tugadh toili�.
Beir i do l�imh ar an tslat le ar bhuail t� an abhainn, agus seo leat.
Ba mhaith liom bu�ochas a ghlacadh le �r seirbh�s riarach�in.
T�gann siad cuid de le iad f�in a th�amh.
T� do scrios chomh leathan leis an farraige.
Cuir alt eile lenar bhfuil scr�ofa agat i gCeist a tr�.
Is linne � ar nd�igh agus len�r clann.
M� thiocfaidh acmhainn� breise ar f�il, beidh m� s�sta.
M� tugann r� breith ar na boicht le cothromas, bun�far a r�chathaoir go br�ch.
M� deirim libh �, n� chreidfidh sibh (OK).
M� t� suim agat sa turas seo, seol d'ainm chugamsa (OK).
M� fuair n�or fhreagair s� an facs (OK).
Roghna�tear an bhliain 1961 mar pointe tosaigh don anail�s.
Aithn�tear � mar an �dar�s.
M�s mhian leat tuilleadh eolais a fh�il, scr�obh chugainn.
T� caitheamh na hola ag dul i m�ad i gc�na�.
Tosa�odh ar mhodh adhlactha eile ina mbaint� �s�id as clocha measartha m�ra.
Comhl�on mo aitheanta agus mairfidh t� beo.
Ceapadh mise i mo bolscaire.
T� m� ag scl�bha�ocht ag iarraidh mo dh� gas�r a chur tr� scoil. 
Agus anois bh� m�rsheisear in�onacha ag an sagart.
Mura dtuig siad �, nach d�ibh f�in is m� n�ire?
Mura bhfuair, sin an chraobh aige (OK).
Mura tagann aon duine i gcabhair orainn, rachaimid anonn chugaibh.
Fi� mura �ir�onn liom, beidh m� �balta cabhr� ar bhonn deonach.
Murach bheith mar sin, bheadh s� dodh�anta d� oibri� na huaireanta fada (OK).
Murar chrutha�tear l� agus o�che... teilgim uaim sliocht Iac�ib.
Murar gcruthaigh mise l� agus o�che... teilgim uaim sliocht Iac�ib.
An bhfuil aon uachtar reoite ag fear na b�d?
Is m�r ag n�isi�n na �ireann a choibhneas speisialta le daoine de bhunadh na h�ireann at� ina gc�na� ar an gcoigr�och.
Chuir an Coimisi�n f�in comhfhreagras chuig na eagra�ochta� seo ag lorg eolais faoina ngn�omha�ochta�.
T� an tr�ith sin coitianta i measc na n�ireannaigh sa t�r seo.
Athdh�antar na sn�ithe i ngach ceann de na curaclaim seo.
N� iompa�g� chun na n-�ol, agus n� dealbha�g� d�ithe de mhiotal.
T� t� n�os faide sa t�r n� is dleathach duit a bheith (OK).
Ach n� sin an cult�r a bh� n� at� go f�ill (OK).
Agus creid n� n� chreid, nach bhfuil an l�mhscr�bhinn agam f�in.
Is fearr de bh�ile luibheanna agus gr� leo n� mhart m�ith agus gr�in leis.
Is fearr an b�s n� bheith beo ar dh�irc (OK).
Nach raibh d�thain eolais aige (OK)?
Nach bainfidh m� uaidh an m�id a ghoid s� uaim?
Nach ghasta a fuair t� �!
Th�inig na br�ga chomh fada siar le haimsir Naomh Ph�draig f�in.
N�r bre� liom cla�omh a bheith agam i mo ghlac!
N�r bhfreagair s� th�, focal ar fhocal.
Feicimid gur de dheasca a n-easumhla�ochta n�rbh f�idir leo dul isteach ann.
N� fuaireamar puinn eile tuairisce air i ndiaidh sin.
N� chuireadar aon �thas ar Mhac Dara.
N� d�irt s� cad a bh� d�anta acu (OK).
N� f�adfaidh a gcuid airgid n� �ir iad a sh�bh�il.
N� bhfaighidh t� aon d�irce uaim (OK).
N� deir s� � seo le haon ghr�in (OK).
N� iad sin do ph�opa� ar an t�bla!
N� dheireadh aon duine acu aon rud liom.
N� fh�idir d�ibh duine a shaoradh �n mb�s.
Bh� an m�id sin airgid n�ba luachmhar d�inn n� maoin an domhain.
An raibh duine ar bith acu n� ba bhocht n� eisean?
Eisean beag�n n�b �ga n� mise.
Agus do na daoine a bh� n�b boichte n� iad f�in.
Eisean beag�n n�ba �ige n� mise.
Bh� na p�ist� ag �ir� n�ba tr�ine.
T� tuairisc ar an l�acht a thug Niamh Nic Suibhne ar leathanach a hocht.
Is saoririseoir agus ceolt�ir � Aoife Nic Chormaic.
"T�," ar sise, "ach n�or fhacthas � sin."
N�or g� do dheora� riamh codladh sa tsr�id; Bh� mo dhoras riamh ar leathadh.
"T�," ar sise, "ach n�or fuair muid aon ocras f�s.
N�or mbain s� leis an dream a bh� i gcogar ceilge.
N�orbh fol�ir d� �isteacht a thabhairt dom.
Eoghan � Anluain a thabharfaidh l�acht deiridh na comhdh�la.
Ach anois � cuimhn�m air, bh� ard�n coincr�ite sa ph�irc.
Bhuel, fan ar strae mar sin � t� t� chomh m�mh�inte sin (OK).
N� maith liom � ar chor ar bith � fuair s� an litir sin (OK).
Tabhair an t-ord� seo leanas � b�al.
B�odh bhur ngr� saor � an chur i gc�ill.
Beidh an ch�ad chruinni� oifigi�il ag an gcoiste o�che D� Luain.
B�odh bhur ngr� saor �n cur i gc�ill.
N� glacaim sos �n thochailt.
Amharcann s� � a ionad c�naithe ar gach aon neach d� maireann ar talamh.
Seo iad a gc�imeanna de r�ir na n-�iteanna � ar thosa�odar.
Agus rinne s� �r bhfuascailt � �r naimhde.
Seo teaghlach ag a bhfuil go leor fadhbanna agus �nar dteasta�onn taca�ocht at� d�rithe.
Bh�odh s�il in airde againn �n�r t�ir faire.
T� do gh�aga spr�ite ar bhraill�n ghl�igeal os fharraige faoile�n.
Ar ais leis ansin os chomhair an teilif�se�in.
Uaidh f�in, b'fh�idir, p� � f�in.
Agus th�inig sc�in air roimh an pobal seo ar a l�onmhaireacht.
Is gaiste � eagla roimh daoine.
An bhfuil aon uachtar reoite agat sa oighear?
Gorta�odh ceathrar sa n-eachtra.
An bhfuil aon uachtar reoite agat sa cuisneoir?
N� m�r dom umhl� agus cic maith sa th�in a thabhairt duit. 
An bhfuil aon uachtar reoite agat sa seamair?
An bhfuil aon uachtar reoite agat sa scoil (OK)?
An bhfuil aon uachtar reoite agat sa samhradh (OK)?
T� s� br�thair de chuid Ord San Phroinsias.
San f�sach cuirfidh m� crainn ch�adrais.
An bhfuil aon uachtar reoite agat san foraois?
Tugaimid faoi abhainn na Sionainne san bh�d locha � Ros Com�in.
T�gadh an foirgneamh f�in san 18� haois (OK).
N� f�idir iad a sheinm le sn�thaid ach c�ig n� s� uaire.
D�irt s� uair amh�in nach raibh �it eile ar mhaith leis c�na� ann (OK).
C�ard at� ann n� s� cathaoirleach coiste.
Cuireadh bosca� tice�la isteach seachas bhosca� le freagra� a scr�obh isteach.
D� nd�anfadh s� amhlaidh r�iteodh s� an fhadhb seachas bheith � gh�ar� (OK).
Is siad na ruda� crua a mhairfidh.
T� ar a laghad ceithre n� sa litir a chuir scaoll sna oifigigh.
Sol�thra�onn an Roinn seisi�in sna Gaeilge labhartha do na mic l�inn.
Sula sroicheadar an bun ar�s, bh� an o�che ann agus chuadar ar strae.
Sula ndearna s� amhlaidh, m�s ea, l�irigh s� a chreidi�int san fhoireann (OK).
Iompr�idh siad th� lena l�mha sula bhuailfe� do chos in aghaidh cloiche.
Ach sular sroich s�, d�irt s�: "D�naig� an doras air!"
Chuir s� iad ina su� mar a raibh on�ir acu thar an cuid eile a fuair cuireadh.
Bh� an chathair ag cur thar maol le fil� de gach cine�l.
Timpeall tr� uaire a chloig ina dhiaidh sin th�inig an bhean isteach.
Scr�obhaim chugaibh mar gur maitheadh daoibh bhur bpeaca� tr� a ainm.
Cuirtear i l�thair na strucht�ir tr� a re�cht�lfar gn�omhartha ag an leibh�al n�isi�nta.
N� fhillfidh siad ar an ngeata tr� ar ghabh siad isteach.
Beirimid an bua go caithr�imeach tr� an t� �d a thug gr� d�inn.
Coinn�odh len�r s�la sa chaoi n�rbh fh�idir si�l tr� �r sr�ideanna.
Gabhfaidh siad tr� muir na h�igipte.
Feidhmeoidh an ciste coimisi�naithe tr�d na foilsitheoir� go pr�omha.
Ba � an gleann c�ng tr�na ghabh an abhainn.
Is mar a ch�ile an pr�iseas tr�nar nd�antar � seo.
Mar tr�n�r peaca�, t� do phobal ina �bhar g�ire ag c�ch m�guaird orainn.
Beidh c�rsa Gaeilge ar si�l do mhic l�inn in �ras Mh�irt�n U� Cadhain.
N�r thug s� p�g do gach uile duine?
D'ith na daoine uile bia (OK).
Idir dh� sholas, um tr�thn�na, faoi choim na ho�che agus sa dorchadas.
Strait�is Chomhphobail um bainist�ocht dramha�ola (OK).
Bh�odh an dinn�ar acu um mhe�n lae.
Conas a bheadh �irinn agus Meirice� difri�il?
Ba chois tine � (OK).
Bh� cuid mh�r teannais agus ioma�ochta ann (OK).
Galar cr�ibe is b�il (OK).
Caitheann s� go leor ama ann (OK).
An raibh m�r�n daoine ag an tsiopa?
N� raibh d�il bheo le feice�il ar na bhfuinneog.
Bh�, d�la an sc�il, ocht mbean d�ag aige (OK).
C� bhfuil an tseomra?
Is iad na nGarda�.
�ir� Amach na C�sca (OK).
Leas phobal na h�ireann agus na hEorpa (OK).
F�ilte an deamhain is an diabhail romhat (OK).
Go deo na ndeor, go deo na d�leann (OK).
Clann na bPoblachta a thug siad orthu f�in.
Crutha�odh an chloch sin go domhain faoin dtalamh.
T� ainm in n-easnamh a mbeadh coinne agat leis.
T� muid compordach inar gcuid "f�rinn�" f�in.
T� siad ag �ileamh go n-�ocfa� iad as a gcuid costais agus iad mbun traen�la.
Crutha�odh an chloch sin go domhain faoin gcrann (OK).
An n-�lfaidh t� rud �igin?
Nach holc an mhaise duit a bheith ag magadh.
D�n do bh�al, a mhi�il na haon chloiche (OK)!
Scaoileadh seachtar duine chun b�is i mBaile �tha Cliath le hocht m� anuas (OK).
N� dh�nfaidh an t-ollmhargadh go dt� a haon a chlog ar maidin (OK).
Is mar gheall ar sin at� l�n�ocht phicti�rtha chomh h�s�ideach sin (OK).
T� s� ag feidhmi� go h�ifeachtach (OK).
N� hionann cuingir na ngabhar agus cuingir na l�n�ine (OK).
Ba hiad na hamhr�in i dtosach ba ch�is leis.
N� h� l� na gaoithe l� na scolb (OK).
Ba iad na tr� h�it iad Bost�n, Baile �tha Cliath agus Nua Eabhrac.
Ph�s s� bean eile ina h�it (OK).
C� ham a th�inig s� a staid�ar anseo � th�s (OK)?
Bh� a dhearth�ir ag si�l na gceithre hairde agus bh� seisean ina shu� (OK).
Chaith s� an dara ho�che i Sligeach (OK).
T� s� i gc�ip a rinneadh i l�r na c�igi� haoise d�ag (OK).
Chuir s� a dh� huillinn ar an bhord (OK).
Chuir m� mo dh� huillinn ar an bhord.
Cuireadh cuid mhaith acu go h�irinn (OK).
T� t�s curtha le cl�r chun rampa� luchtaithe a chur sna hotharcharranna (OK).
Cuimhn�g� ar na h�achta� a rinne s� (OK).
Creidim go mbeidh iontas ar mhuintir na h�ireann nuair a fheiceann siad an feidhmchl�r seo (OK).
Th�inig m�inteoir �r i gceithre huaire fichead (OK).
Caithfidh siad turas c�ig huaire a chloig a dh�anamh (OK).
In �irinn chaitheann breis is 30 faoin gc�ad de mhn� toit�n�.
Chuirfear in i�l do dhaoine gurb � sin an aidhm at� againn.
D�an cur s�os ar dh� thoradh a bh�onn ag caitheamh tobac ar an tsl�inte (OK).
M� bhr�itear idir chn�nna agus bhlaoscanna faightear ola inchaite (OK).
N� chotha�onn na briathra na br�ithre (OK).
Cha bh�onn striapachas agus seaf�id Mheirice� ann feasta (OK).
T� cleachtadh ag daoine � bh�onn siad an-�g ar uaigneas imeachta (OK).
Ar an l�ithre�n seo gheofar focl�ir� agus liosta� t�arma�ochta (OK).
An o�che sin, sular chuaigh s� a chodladh, chuir s� litir fhada dom.
T� mioneolas faoinar rinne s� ansin.
N�or rinneadh a leith�id le fada agus n� raibh aon slat tomhais acu.
Teasta�onn uaidh an sc�al a insint sula ngeobhaidh s� b�s.
T� fol�ntas sa chomhlacht ina t� m� ag obair faoi l�thair.
N� gheobhaidh an meallt�ir nathrach aon t�ille.
M� dhearna s� praiseach de, thosaigh s� ar�s go bhfuair s� ceart �.
Nuair a raibh m� �g.
An clapsholas a raibh m� ag dr�im leis (OK).
Chan fhacthas dom go raibh an saibhreas c�anna i mB�arla (OK).
Chuaigh s� chun na huaimhe agus fh�ach s� isteach.
F�gadh faoi smacht a l�mh iad (OK).
An �osf� ubh eile (OK)?
N�orbh fhada, �mh, gur d'fhoghlaim s� an t�arma ceart uathu.
N�lim ag r� gur d'aon ghuth a ainmn�odh Sheehy (OK).
Scr�obh s� soisc�al ina d'athr�dh an eaglais � f�in go deo.
T� bonn i bhfad n�os dhoimhne n� sin le F�ilte an Oireachtais.
T� a chuid leabhar tiontaithe go dh� theanga fichead (OK).
T� d�n cosanta eile ar an taobh thoir den oile�n (OK).
D�an teagmh�il leis an Rann�g ag an seoladh thuasluaite (OK).
Nochtadh na f�rinne sa d�igh a n-admh�dh an t� is br�aga� � (OK).
Abairt a chuireann in i�l dear�ile na h�ireann sa 18� agus sa 19� haois.
O�che na gaoithe m�ra.
O�che na gaoithe m�r.
T� a chumas sa Ghaeilge n�os airde n� cumas na bhfear �ga.
Beirt bhan Mheirice�nacha a bh� ann (OK).
T� s�-- t� s�- mo ---shin-seanathair (OK).
Is fol�ir d�ibh a ndualgais a chomhl�onadh.
Bhain na toibreacha le re eile agus le dream daoine at� imithe.
Labhair m� ar shon na daoine.
T� s� t�bhachtach bheith ag obair an son na cearta.
Ba � an fear an phortaigh a th�inig thart leis na pl�ta� bia.
T� dh� shiombail ag an bharr gach leathanaigh.
Tabharfaimid an t-ainm do mh�thar uirthi.
Is iad na tr� cheist sin (OK).
Lena chois sin, d� bharr seo, d� bhr� sin, ina aghaidh seo (OK).
C�n t-ionadh sin (OK)?
EOF

my $results = <<'RESEOF';
<error fromy="0" fromx="43" toy="0" tox="49" ruleId="Lingua::GA::Gramadoir/CAIGHDEAN{scata}" msg="Foirm neamhchaighdeánach de ‘scata’" context="Ní raibh líon mór daoine bainteach leis an scaifte a bhí ag iarraidh mioscais a chothú." contextoffset="43" errorlength="7"/>
<error fromy="1" fromx="4" toy="1" tox="15" ruleId="Lingua::GA::Gramadoir/CAIGHDEAN{thosnaigh (thosaigh)}" msg="Foirm neamhchaighdeánach de ‘thosnaigh (thosaigh)’" context="Ach thosnaíos-sa ag léamh agus bhog mé isteach ionam féin." contextoffset="4" errorlength="12"/>
<error fromy="2" fromx="24" toy="2" tox="28" ruleId="Lingua::GA::Gramadoir/DUBAILTE" msg="An focal céanna faoi dhó" context="Tabhair go leor leor de na na rudaí do do chara, a Chaoimhín." contextoffset="24" errorlength="5"/>
<error fromy="3" fromx="51" toy="3" tox="52" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Seo é a chuntas féin ar ar tharla ina dhiaidh sin (OK)." contextoffset="51" errorlength="2"/>
<error fromy="4" fromx="30" toy="4" tox="31" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Aithníonn ciaróg ciaróg eile (OK)." contextoffset="30" errorlength="2"/>
<error fromy="5" fromx="55" toy="5" tox="56" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Go deo deo arís ní fheicfeadh sí a cheannaithe snoite (OK)." contextoffset="55" errorlength="2"/>
<error fromy="6" fromx="32" toy="6" tox="33" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Tabhair iad seo do do mháthair (OK)." contextoffset="32" errorlength="2"/>
<error fromy="7" fromx="26" toy="7" tox="27" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Sin é é ... Tá sé anseo (OK)!" contextoffset="25" errorlength="2"/>
<error fromy="8" fromx="44" toy="8" tox="45" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Tá siad le feiceáil ann le fada fada an lá (OK)." contextoffset="44" errorlength="2"/>
<error fromy="9" fromx="29" toy="9" tox="30" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Bhí go leor leor le rá aici (OK)." contextoffset="29" errorlength="2"/>
<error fromy="10" fromx="47" toy="10" tox="48" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Cuirfidh mé mé féin in aithne dá lán ciníocha (OK)." contextoffset="47" errorlength="2"/>
<error fromy="11" fromx="74" toy="11" tox="75" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Fanann réalta chobhsaí ar feadh idir milliún agus milliún milliún bliain (OK)." contextoffset="74" errorlength="2"/>
<error fromy="12" fromx="39" toy="12" tox="40" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Bhíodh an-tóir ar spíosraí go mór mór (OK)." contextoffset="39" errorlength="2"/>
<error fromy="13" fromx="56" toy="13" tox="62" ruleId="Lingua::GA::Gramadoir/DUBAILTE" msg="An focal céanna faoi dhó" context="Bhí an dara cupán tae ólta agam nuair a tháinig an fear mór mór." contextoffset="56" errorlength="7"/>
<error fromy="14" fromx="21" toy="14" tox="22" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Agus sin sin de sin (OK)!" contextoffset="21" errorlength="2"/>
<error fromy="15" fromx="45" toy="15" tox="55" ruleId="Lingua::GA::Gramadoir/MOIRF{fhaitíos}" msg="Focal anaithnid ach bunaithe ar ‘fhaitíos’ is dócha" context="Chuaigh sí in olcas ina dhiaidh sin agus bhí an-fhaitíos orthu." contextoffset="45" errorlength="11"/>
<error fromy="16" fromx="20" toy="16" tox="35" ruleId="Lingua::GA::Gramadoir/DROCHMHOIRF{mífheiliúnach}" msg="Bunaithe go mícheart ar an bhfréamh ‘mífheiliúnach’" context="Tharla sé seo ar lá an-mífheiliúnach, an Déardaoin." contextoffset="20" errorlength="16"/>
<error fromy="17" fromx="24" toy="17" tox="37" ruleId="Lingua::GA::Gramadoir/DROCHMHOIRF{intleachtúla (intleachtacha,_intleachtaí)}" msg="Bunaithe go mícheart ar an bhfréamh ‘intleachtúla (intleachtacha, intleachtaí)’" context="Ní maith liom na daoine míintleachtúla." contextoffset="24" errorlength="14"/>
<error fromy="18" fromx="4" toy="18" tox="17" ruleId="Lingua::GA::Gramadoir/CAIGHDEAN{chomhtharlú}" msg="Foirm neamhchaighdeánach de ‘chomhtharlú’" context="Trí chomhtharlúint, bhí siad sa tuaisceart ag an am." contextoffset="4" errorlength="14"/>
<error fromy="19" fromx="24" toy="19" tox="28" ruleId="Lingua::GA::Gramadoir/MICHEART{dócha}" msg="An raibh ‘dócha’ ar intinn agat?" context="Sílim nárbh ea, agus is docha nach bhfuil i gceist ach easpa smaoinimh." contextoffset="24" errorlength="5"/>
<error fromy="20" fromx="87" toy="20" tox="91" ruleId="Lingua::GA::Gramadoir/MICHEART{Tíomór}" msg="An raibh ‘Tíomór’ ar intinn agat?" context="Tá súil le feabhas nuair a thosóidh airgead ag teacht isteach ó ola agus gás i mBearna Timor." contextoffset="87" errorlength="5"/>
<error fromy="21" fromx="25" toy="21" tox="32" ruleId="Lingua::GA::Gramadoir/MICHEART{Dámaicléas}" msg="An raibh ‘Dámaicléas’ ar intinn agat?" context="Bhí sí cosúil le claíomh Damocles ar crochadh sa spéir." contextoffset="25" errorlength="8"/>
<error fromy="22" fromx="66" toy="22" tox="78" ruleId="Lingua::GA::Gramadoir/CAIGHMOIRF{chineál}" msg="Bunaithe ar fhoirm neamhchaighdeánach de ‘chineál’" context="Beidh nuachtáin shuaracha i ngreim cé nach mbeadh cinsireacht den droch-chinéal i gceist." contextoffset="66" errorlength="13"/>
<error fromy="23" fromx="43" toy="23" tox="52" ruleId="Lingua::GA::Gramadoir/GRAM{dap}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘dap’ neamhchoitianta)" context="Bhí sé páirteach sa chéad léiriú poiblí de Adaptation." contextoffset="43" errorlength="10"/>
<error fromy="24" fromx="74" toy="24" tox="86" ruleId="Lingua::GA::Gramadoir/COMHFHOCAL{mion+airgeadra}" msg="Focal anaithnid ach b'fhéidir gur comhfhocal ‘mion+airgeadra’ é?" context="Beidh an tionchar le mothú níos mó i gcás comhlachtaí Éireannacha mar gur mionairgeadra é an punt." contextoffset="74" errorlength="13"/>
<error fromy="25" fromx="13" toy="25" tox="21" ruleId="Lingua::GA::Gramadoir/COMHCHAIGH{dí+armtha}" msg="Focal anaithnid ach b'fhéidir gur comhfhocal neamhchaighdeánach ‘dí+armtha’ é?" context="Bhí an dream dí-armtha ag iarraidh a gcuid gunnaí." contextoffset="13" errorlength="9"/>
<error fromy="26" fromx="18" toy="26" tox="23" ruleId="Lingua::GA::Gramadoir/MOLADH{reoite}" msg="Focal anaithnid: ‘reoite’?" context="An bhfuil uachtar roeite agattt?" contextoffset="18" errorlength="6"/>
<error fromy="26" fromx="25" toy="26" tox="30" ruleId="Lingua::GA::Gramadoir/GRAM{att}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘att’ neamhchoitianta)" context="An bhfuil uachtar roeite agattt?" contextoffset="25" errorlength="6"/>
<error fromy="27" fromx="9" toy="27" tox="12" ruleId="Lingua::GA::Gramadoir/NEAMHCHOIT" msg="Focal ceart ach an-neamhchoitianta - an é atá uait anseo?" context="Bíonn an geál ag satailt ar an dubh." contextoffset="9" errorlength="4"/>
<error fromy="28" fromx="79" toy="28" tox="80" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Ach go rithe an fhíréantacht mar uisce agus an t-ionracas mar shruth gan dísc (OK)!" contextoffset="79" errorlength="2"/>
<error fromy="29" fromx="19" toy="29" tox="23" ruleId="Lingua::GA::Gramadoir/NOSUBJ" msg="Ní dócha go raibh intinn agat an modh foshuiteach a úsáid anseo" context="Ba iad mo shinsear rithe Chúige Uladh." contextoffset="19" errorlength="5"/>
<error fromy="30" fromx="28" toy="30" tox="33" ruleId="Lingua::GA::Gramadoir/NOSUBJ" msg="Ní dócha go raibh intinn agat an modh foshuiteach a úsáid anseo" context="Is iad na trí cholún sin le cheile an tAontas Eorpach." contextoffset="28" errorlength="6"/>
<error fromy="31" fromx="24" toy="31" tox="39" ruleId="Lingua::GA::Gramadoir/GENITIVE" msg="Tá gá leis an leagan ginideach anseo" context="Scriúáil sé an glas seo ar chúl an doras." contextoffset="24" errorlength="16"/>
<error fromy="32" fromx="55" toy="32" tox="56" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Ach bhí mé ag leanúint ar aghaidh an t-am ar fad leis (OK)." contextoffset="55" errorlength="2"/>
<error fromy="33" fromx="71" toy="33" tox="72" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Bhain sé sult as clár toghcháin TG4 a chur i láthair an mhí seo caite (OK)." contextoffset="71" errorlength="2"/>
<error fromy="34" fromx="36" toy="34" tox="37" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Bhrostaigh sé go dtí an t-ospidéal (OK)." contextoffset="36" errorlength="2"/>
<error fromy="35" fromx="3" toy="35" tox="10" ruleId="Lingua::GA::Gramadoir/PREFIXH" msg="Réamhlitir ‘h’ ar iarraidh" context="Sa dara alt, déan cur síos ar a bhfaca siad sa Spáinn." contextoffset="3" errorlength="8"/>
<error fromy="36" fromx="48" toy="36" tox="55" ruleId="Lingua::GA::Gramadoir/NIAITCH" msg="Réamhlitir ‘h’ gan ghá" context="D'oirfeadh síol áitiúil níos fearr ná an síol a hadhlaic sé anuraidh." contextoffset="48" errorlength="8"/>
<error fromy="37" fromx="30" toy="37" tox="31" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Ná hinis do dhuine ar bith é (OK)." contextoffset="30" errorlength="2"/>
<error fromy="38" fromx="48" toy="38" tox="54" ruleId="Lingua::GA::Gramadoir/NITEE" msg="Réamhlitir ‘t’ gan ghá" context="Tá ceacht stairiúil uathúil do chuairteoirí san t-ionad seo." contextoffset="48" errorlength="7"/>
<error fromy="39" fromx="47" toy="39" tox="48" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Faightear an t-ainm isteach faoin tír freisin (OK)." contextoffset="47" errorlength="2"/>
<error fromy="40" fromx="20" toy="40" tox="21" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Cén t-ainm atá air (OK)?" contextoffset="20" errorlength="2"/>
<error fromy="41" fromx="15" toy="41" tox="25" ruleId="Lingua::GA::Gramadoir/NITEE" msg="Réamhlitir ‘t’ gan ghá" context="Aistríodh é go tSualainnis, Gearmáinis, agus Fraincis." contextoffset="15" errorlength="11"/>
<error fromy="42" fromx="47" toy="42" tox="48" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Cén chaoi a n-aimsíonn scoil an tseirbhís seo (OK)?" contextoffset="47" errorlength="2"/>
<error fromy="43" fromx="58" toy="43" tox="59" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Tá sonraí ann faoin tslí ina n-iarrtar taifid faoin Acht (OK)." contextoffset="58" errorlength="2"/>
<error fromy="44" fromx="32" toy="44" tox="33" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Cén tslí bheatha a bhí ag Naoi (OK)?" contextoffset="32" errorlength="2"/>
<error fromy="45" fromx="46" toy="45" tox="47" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Bhí imní ag teacht ar dheartháir an tsagairt (OK)." contextoffset="46" errorlength="2"/>
<error fromy="46" fromx="74" toy="46" tox="94" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Tá sé riachtanach ar mhaithe le feidhmiú an phlean a bheidh ceaptha ag an eagraíocht ceannasach." contextoffset="74" errorlength="21"/>
<error fromy="47" fromx="50" toy="47" tox="51" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Bhí na ranganna seo ar siúl an bhliain seo caite (OK)." contextoffset="50" errorlength="2"/>
<error fromy="48" fromx="49" toy="48" tox="50" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Léimeann an fharraige céad méadar suas sa spéir (OK)." contextoffset="49" errorlength="2"/>
<error fromy="49" fromx="46" toy="49" tox="47" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Briseadh bád Éamoinn Óig oíche gaoithe móire (OK)." contextoffset="46" errorlength="2"/>
<error fromy="50" fromx="78" toy="50" tox="79" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Bhíodh na daoir scaoilte saor óna gcuid oibre agus bhíodh saoirse cainte acu (OK)." contextoffset="78" errorlength="2"/>
<error fromy="51" fromx="43" toy="51" tox="44" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Bhí mé ag tógáil balla agus ag baint móna (OK)." contextoffset="43" errorlength="2"/>
<error fromy="52" fromx="36" toy="52" tox="37" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Is as Londain Shasana mé ó dhúchas (OK)." contextoffset="36" errorlength="2"/>
<error fromy="53" fromx="30" toy="53" tox="49" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Seán a d'imigh ar iarraidh ar oíche ghaoithe móire." contextoffset="30" errorlength="20"/>
<error fromy="54" fromx="35" toy="54" tox="54" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Mar chuid den socrú beidh Michelle ag labhairt Ghaeilge ag ócáidí poiblí." contextoffset="35" errorlength="20"/>
<error fromy="55" fromx="42" toy="55" tox="50" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Tugadh cuireadh dó a theacht i láthair an fhir móir." contextoffset="42" errorlength="9"/>
<error fromy="56" fromx="29" toy="56" tox="46" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Tugaimid é amach le haghaidh béile Polainéisigh." contextoffset="29" errorlength="18"/>
<error fromy="57" fromx="35" toy="57" tox="36" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Bhí torann an dorais cloiste agam (OK)." contextoffset="35" errorlength="2"/>
<error fromy="58" fromx="6" toy="58" tox="24" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Tá na lachain slachtmhara ar eitilt." contextoffset="6" errorlength="19"/>
<error fromy="59" fromx="53" toy="59" tox="54" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Mhair cuid mhór dár sinsir céad caoga bliain ó shin (OK)." contextoffset="53" errorlength="2"/>
<error fromy="60" fromx="46" toy="60" tox="47" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Tá sé le cloisteáil sna meáin gach seachtain (OK)." contextoffset="46" errorlength="2"/>
<error fromy="61" fromx="16" toy="61" tox="34" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Déanann siad na breiseáin brabhsála don tionscal ríomhaireachta." contextoffset="16" errorlength="19"/>
<error fromy="62" fromx="6" toy="62" tox="14" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Is ar éisc mara agus ar na hainmhithe mara eile atáimid ag díriú." contextoffset="6" errorlength="9"/>
<error fromy="63" fromx="40" toy="63" tox="41" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Chonaic mé líon agus crainn tógála ann (OK)." contextoffset="40" errorlength="2"/>
<error fromy="64" fromx="28" toy="64" tox="47" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Bhí pictiúir le feiceáil ar scáileáin theilifíse ar fud an domhain." contextoffset="28" errorlength="20"/>
<error fromy="65" fromx="16" toy="65" tox="22" ruleId="Lingua::GA::Gramadoir/INPHRASE{arna mhárach}" msg="Ní úsáidtear an focal seo ach san abairtín ‘arna mhárach’ de ghnáth" context="Maidin lá ar na mhárach thug a fhear gaoil cuairt air." contextoffset="16" errorlength="7"/>
<error fromy="66" fromx="10" toy="66" tox="13" ruleId="Lingua::GA::Gramadoir/BACHOIR{atá}" msg="Ba chóir duit ‘atá’ a úsáid anseo" context="Cad é mar a tá tú?" contextoffset="10" errorlength="4"/>
<error fromy="67" fromx="4" toy="67" tox="14" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="Bhí deich tobar fíoruisce agus seachtó crann pailme ann." contextoffset="4" errorlength="11"/>
<error fromy="68" fromx="25" toy="68" tox="35" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="Rinneadh an roinnt do na naoi treibh go leith ar chrainn." contextoffset="25" errorlength="11"/>
<error fromy="69" fromx="4" toy="69" tox="13" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="Bhí ocht tábla ar fad ar a maraídís na híobairtí." contextoffset="4" errorlength="10"/>
<error fromy="70" fromx="28" toy="70" tox="39" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="Sáraíonn sé na seacht nó na hocht bliana." contextoffset="28" errorlength="12"/>
<error fromy="71" fromx="25" toy="71" tox="36" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="Tá seacht lampa air agus seacht píopa ar gach ceann díobh." contextoffset="25" errorlength="12"/>
<error fromy="72" fromx="0" toy="72" tox="4" ruleId="Lingua::GA::Gramadoir/PREFIXH" msg="Réamhlitir ‘h’ ar iarraidh" context="A aon, a dó, a trí." contextoffset="0" errorlength="5"/>
<error fromy="73" fromx="56" toy="73" tox="57" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Ba é a aon aidhm ar an saol daoine a ghnóthú don chúis (OK)." contextoffset="56" errorlength="2"/>
<error fromy="74" fromx="52" toy="74" tox="60" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Tá an Rialtas tar éis áit na Gaeilge i saol na tíre a ceistiú." contextoffset="52" errorlength="9"/>
<error fromy="75" fromx="52" toy="75" tox="53" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Ach sin scéal eile mar a déarfadh an té a déarfadh (OK)." contextoffset="52" errorlength="2"/>
<error fromy="76" fromx="46" toy="76" tox="47" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Is iomaí uair a fuair mé locht ar an rialtas (OK)." contextoffset="46" errorlength="2"/>
<error fromy="77" fromx="53" toy="77" tox="60" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Bhíodar ag rá ar an aonach gur agamsa a bhí na huain ab fearr." contextoffset="53" errorlength="8"/>
<error fromy="78" fromx="10" toy="78" tox="22" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Ní bheidh ach mhallacht i ndán dó ó na ciníocha agus fuath ó na náisiúin." contextoffset="10" errorlength="13"/>
<error fromy="79" fromx="55" toy="79" tox="56" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Ní theastaíonn uaithi ach bheith ina ball den chumann (OK)." contextoffset="55" errorlength="2"/>
<error fromy="80" fromx="29" toy="80" tox="40" ruleId="Lingua::GA::Gramadoir/CLAOCHLU" msg="Urú nó séimhiú ar iarraidh" context="An bhfuil aon uachtar reoite ar an cuntar?" contextoffset="29" errorlength="12"/>
<error fromy="81" fromx="45" toy="81" tox="46" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Baintear feidhm as chun aicídí súl a mhaolú (OK)." contextoffset="45" errorlength="2"/>
<error fromy="82" fromx="14" toy="82" tox="21" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Má shuíonn tú ag bhord le flaith, tabhair faoi deara go cúramach céard atá leagtha romhat." contextoffset="14" errorlength="8"/>
<error fromy="83" fromx="6" toy="83" tox="16" ruleId="Lingua::GA::Gramadoir/BACHOIR{á X}" msg="Ba chóir duit ‘á X’ a úsáid anseo" context="Tá sí ag ullmhú é." contextoffset="6" errorlength="11"/>
<error fromy="84" fromx="24" toy="84" tox="25" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Chuir sí ag machnamh é (OK)." contextoffset="24" errorlength="2"/>
<error fromy="85" fromx="22" toy="85" tox="35" ruleId="Lingua::GA::Gramadoir/BACHOIR{do mo X}" msg="Ba chóir duit ‘do mo X’ a úsáid anseo" context="Bhí neach oilbhéasach ag leanúint mé." contextoffset="22" errorlength="14"/>
<error fromy="86" fromx="14" toy="86" tox="26" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Bláthaíonn sé amhail bhláth an mhachaire." contextoffset="14" errorlength="13"/>
<error fromy="87" fromx="0" toy="87" tox="7" ruleId="Lingua::GA::Gramadoir/BACHOIR{ar}" msg="Ba chóir duit ‘ar’ a úsáid anseo" context="An chuir an bhean bheag mórán ceisteanna ort?" contextoffset="0" errorlength="8"/>
<error fromy="88" fromx="40" toy="88" tox="41" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="An ndeachaigh tú ag iascaireacht inniu (OK)?" contextoffset="40" errorlength="2"/>
<error fromy="89" fromx="55" toy="89" tox="56" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="An raibh aon bhealach praiticiúil eile chun na hIndia (OK)?" contextoffset="55" errorlength="2"/>
<error fromy="90" fromx="0" toy="90" tox="9" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="An dhearna mé an rud ceart?" contextoffset="0" errorlength="10"/>
<error fromy="91" fromx="0" toy="91" tox="8" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="An bainim sult as bás an drochdhuine?" contextoffset="0" errorlength="9"/>
<error fromy="92" fromx="52" toy="92" tox="53" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="An éireodh níos fearr leo dá mba mar sin a bheidís (OK)?" contextoffset="52" errorlength="2"/>
<error fromy="93" fromx="10" toy="93" tox="21" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Ní féidir an Gaeltacht a choinneáil mar réigiún Gaeilge go náisiúnta gan athrú bunúsach." contextoffset="10" errorlength="12"/>
<error fromy="94" fromx="7" toy="94" tox="18" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="I gcás An Comhairle Ealaíon ní mór é seo a dhéanamh." contextoffset="7" errorlength="12"/>
<error fromy="95" fromx="0" toy="95" tox="6" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="An bean sin, tá sí ina múinteoir." contextoffset="0" errorlength="7"/>
<error fromy="96" fromx="68" toy="96" tox="69" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Chuala sé a mháthair ag labhairt chomh caoin seo leis an mbean nua (OK)." contextoffset="68" errorlength="2"/>
<error fromy="97" fromx="46" toy="97" tox="47" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Chinn sé an cruinniú a chur ar an méar fhada (OK)." contextoffset="46" errorlength="2"/>
<error fromy="98" fromx="27" toy="98" tox="37" ruleId="Lingua::GA::Gramadoir/PREFIXT" msg="Réamhlitir ‘t’ ar iarraidh" context="Cad é an chomhairle a thug an ochtapas dó?" contextoffset="27" errorlength="11"/>
<error fromy="99" fromx="0" toy="99" tox="6" ruleId="Lingua::GA::Gramadoir/PREFIXT" msg="Réamhlitir ‘t’ ar iarraidh" context="An Acht um Chomhionannas Fostaíochta." contextoffset="0" errorlength="7"/>
<error fromy="100" fromx="38" toy="100" tox="39" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Dath bánbhuí éadrom atá ar an adhmad (OK)." contextoffset="38" errorlength="2"/>
<error fromy="101" fromx="55" toy="101" tox="67" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Chóirigh sé na lampaí le solas a chaitheamh os comhair an coinnleora." contextoffset="55" errorlength="13"/>
<error fromy="102" fromx="34" toy="102" tox="46" ruleId="Lingua::GA::Gramadoir/PREFIXT" msg="Réamhlitir ‘t’ ar iarraidh" context="Comhlánóidh saoránacht an Aontais an saoránacht náisiúnta agus ní ghabhfaidh sí a hionad." contextoffset="34" errorlength="13"/>
<error fromy="103" fromx="9" toy="103" tox="17" ruleId="Lingua::GA::Gramadoir/PREFIXT" msg="Réamhlitir ‘t’ ar iarraidh" context="Ritheann an Sláine tríd an pháirc." contextoffset="9" errorlength="9"/>
<error fromy="104" fromx="14" toy="104" tox="24" ruleId="Lingua::GA::Gramadoir/PREFIXT" msg="Réamhlitir ‘t’ ar iarraidh" context="Ní raibh guth an séiléara le clos a thuilleadh." contextoffset="14" errorlength="11"/>
<error fromy="104" fromx="26" toy="104" tox="32" ruleId="Lingua::GA::Gramadoir/CAIGHDEAN{le cloisteáil}" msg="Foirm neamhchaighdeánach de ‘le cloisteáil’" context="Ní raibh guth an séiléara le clos a thuilleadh." contextoffset="26" errorlength="7"/>
<error fromy="105" fromx="40" toy="105" tox="46" ruleId="Lingua::GA::Gramadoir/BACHOIR{na}" msg="Ba chóir duit ‘na’ a úsáid anseo" context="Tá sin ráite cheana féin acu le muintir an tíre seo." contextoffset="40" errorlength="7"/>
<error fromy="106" fromx="68" toy="106" tox="81" ruleId="Lingua::GA::Gramadoir/BACHOIR{na}" msg="Ba chóir duit ‘na’ a úsáid anseo" context="Is é is dóichí go raibh baint ag an eisimirce leis an laghdú i líon an gcainteoirí Gaeilge." contextoffset="68" errorlength="14"/>
<error fromy="107" fromx="7" toy="107" tox="12" ruleId="Lingua::GA::Gramadoir/BACHOIR{na}" msg="Ba chóir duit ‘na’ a úsáid anseo" context="Is iad an trí cholún le chéile an tAontas Eorpach." contextoffset="7" errorlength="6"/>
<error fromy="108" fromx="57" toy="108" tox="58" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Sheol an ceithre mhíle de na meirligh amach san fhásach (OK)." contextoffset="57" errorlength="2"/>
<error fromy="109" fromx="10" toy="109" tox="21" ruleId="Lingua::GA::Gramadoir/NICLAOCHLU" msg="Urú nó séimhiú gan ghá" context="Ní bhíonn an dhíograis ná an dhúthracht i gceist." contextoffset="10" errorlength="12"/>
<error fromy="109" fromx="26" toy="109" tox="38" ruleId="Lingua::GA::Gramadoir/NICLAOCHLU" msg="Urú nó séimhiú gan ghá" context="Ní bhíonn an dhíograis ná an dhúthracht i gceist." contextoffset="26" errorlength="13"/>
<error fromy="110" fromx="0" toy="110" tox="9" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="An fhéidir le duine ar bith eile breathnú ar mo script?" contextoffset="0" errorlength="10"/>
<error fromy="111" fromx="10" toy="111" tox="16" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Ní bhíonn aon dhá chlár as an chrann chéanna mar a chéile go díreach." contextoffset="10" errorlength="7"/>
<error fromy="112" fromx="10" toy="112" tox="22" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Ní bheidh aon buntáiste againn orthu sin." contextoffset="10" errorlength="13"/>
<error fromy="113" fromx="6" toy="113" tox="11" ruleId="Lingua::GA::Gramadoir/CUPLA" msg="Cor cainte aisteach" context="Rogha aon de na focail a tháinig i d'intinn." contextoffset="6" errorlength="6"/>
<error fromy="114" fromx="38" toy="114" tox="39" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Ná hith aon arán gabhála mar aon léi (OK)." contextoffset="38" errorlength="2"/>
<error fromy="115" fromx="51" toy="115" tox="52" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Freagair aon dá cheann ar bith díobh seo a leanas (OK)." contextoffset="51" errorlength="2"/>
<error fromy="116" fromx="71" toy="116" tox="78" ruleId="Lingua::GA::Gramadoir/BACHOIR{ár}" msg="Ba chóir duit ‘ár’ a úsáid anseo" context="Bhíomar ag féachaint ar an Ghaeltacht mar ionad chun feabhas a chur ar ar gcuid Gaeilge." contextoffset="71" errorlength="8"/>
<error fromy="117" fromx="42" toy="117" tox="50" ruleId="Lingua::GA::Gramadoir/BACHOIR{a, an}" msg="Ba chóir duit ‘a, an’ a úsáid anseo" context="Bhí daoine le fáil i Sasana a chreid gach ar dúradh sa bholscaireacht." contextoffset="42" errorlength="9"/>
<error fromy="118" fromx="36" toy="118" tox="42" ruleId="Lingua::GA::Gramadoir/WEAKSEIMHIU{ar}" msg="Leanann séimhiú an réamhfhocal ‘ar’ go minic, ach ní léir é sa chás seo" context="Tá treoirlínte mionsonraithe curtha ar fail ag an gCoimisiún." contextoffset="36" errorlength="7"/>
<error fromy="119" fromx="46" toy="119" tox="52" ruleId="Lingua::GA::Gramadoir/WEAKSEIMHIU{ar}" msg="Leanann séimhiú an réamhfhocal ‘ar’ go minic, ach ní léir é sa chás seo" context="Bhí cead againn fanacht ag obair ar an talamh ar fead trí mhí." contextoffset="46" errorlength="7"/>
<error fromy="120" fromx="55" toy="120" tox="56" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Tá sé an chéad suíomh gréasán ar bronnadh teastas air (OK)." contextoffset="55" errorlength="2"/>
<error fromy="121" fromx="14" toy="121" tox="19" ruleId="Lingua::GA::Gramadoir/WEAKSEIMHIU{ar}" msg="Leanann séimhiú an réamhfhocal ‘ar’ go minic, ach ní léir é sa chás seo" context="Cosc a bheith ar cic a thabhairt don sliotar." contextoffset="14" errorlength="6"/>
<error fromy="122" fromx="39" toy="122" tox="40" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Cosc a bheith ar CIC leabhair a dhíol (OK)." contextoffset="39" errorlength="2"/>
<error fromy="123" fromx="41" toy="123" tox="42" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Beidh cairde dá cuid ar Gaeilgeoirí iad (OK)." contextoffset="41" errorlength="2"/>
<error fromy="124" fromx="0" toy="124" tox="8" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Ar gcaith tú do chiall agus do chéadfaí ar fad?" contextoffset="0" errorlength="9"/>
<error fromy="125" fromx="10" toy="125" tox="21" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="Ní amháin ár dhá chosa, ach nigh ár lámha!" contextoffset="10" errorlength="12"/>
<error fromy="126" fromx="48" toy="126" tox="55" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="Gheobhaimid maoin de gach sórt, agus líonfaimid ár tithe le creach." contextoffset="48" errorlength="8"/>
<error fromy="127" fromx="11" toy="127" tox="18" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Níl aon ní arbh fiú a shantú seachas í." contextoffset="11" errorlength="8"/>
<error fromy="128" fromx="0" toy="128" tox="7" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Ba maith liom fios a thabhairt anois daoibh." contextoffset="0" errorlength="8"/>
<error fromy="129" fromx="16" toy="129" tox="24" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Dúirt daoine go mba ceart an poll a dhúnadh suas ar fad." contextoffset="16" errorlength="9"/>
<error fromy="130" fromx="0" toy="130" tox="5" ruleId="Lingua::GA::Gramadoir/BACHOIR{b', ab}" msg="Ba chóir duit ‘b', ab’ a úsáid anseo" context="Ba eol duit go hiomlán m'anam." contextoffset="0" errorlength="6"/>
<error fromy="131" fromx="3" toy="131" tox="7" ruleId="Lingua::GA::Gramadoir/CAIGHDEAN{binn}" msg="Foirm neamhchaighdeánach de ‘binn’" context="Tá beinn agus buaic orm." contextoffset="3" errorlength="5"/>
<error fromy="132" fromx="7" toy="132" tox="21" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="D'fhan beirt buachaill sa champa." contextoffset="7" errorlength="15"/>
<error fromy="133" fromx="7" toy="133" tox="31" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="D'fhan beirt bhuachaill cancrach sa champa." contextoffset="7" errorlength="25"/>
<error fromy="134" fromx="48" toy="134" tox="49" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Mothóidh Pobal Osraí an bheirt laoch sin uathu (OK)." contextoffset="48" errorlength="2"/>
<error fromy="135" fromx="10" toy="135" tox="23" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="Ní amháin bhur dhá chosa, ach nigh bhur lámha!" contextoffset="10" errorlength="14"/>
<error fromy="136" fromx="28" toy="136" tox="40" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="Déanaigí beart leis de réir bhur briathra." contextoffset="28" errorlength="13"/>
<error fromy="137" fromx="0" toy="137" tox="12" ruleId="Lingua::GA::Gramadoir/BACHOIR{a}" msg="Ba chóir duit ‘a’ a úsáid anseo" context="Cad déarfaidh mé libh mar sin?" contextoffset="0" errorlength="13"/>
<error fromy="138" fromx="0" toy="138" tox="7" ruleId="Lingua::GA::Gramadoir/CAIGHDEAN{cé mhéad}" msg="Foirm neamhchaighdeánach de ‘cé mhéad’" context="Cé mhéid gealladh ar briseadh ar an Indiach bocht?" contextoffset="0" errorlength="8"/>
<error fromy="139" fromx="24" toy="139" tox="38" ruleId="Lingua::GA::Gramadoir/UATHA" msg="Tá gá leis an leagan uatha anseo" context="Nach raibh a fhios aige cé mhéad daoine a bhíonn ag éisteacht leis an stáisiún." contextoffset="24" errorlength="15"/>
<error fromy="140" fromx="12" toy="140" tox="27" ruleId="Lingua::GA::Gramadoir/UATHA" msg="Tá gá leis an leagan uatha anseo" context="Faigh amach cé mhéad salainn a bhíonn i sampla d'uisce." contextoffset="12" errorlength="16"/>
<error fromy="141" fromx="0" toy="141" tox="5" ruleId="Lingua::GA::Gramadoir/PREFIXH" msg="Réamhlitir ‘h’ ar iarraidh" context="Cá áit a nochtfadh sé é féin ach i mBostún!" contextoffset="0" errorlength="6"/>
<error fromy="142" fromx="0" toy="142" tox="6" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Cá chás dúinn bheith ag máinneáil thart anseo?" contextoffset="0" errorlength="7"/>
<error fromy="143" fromx="35" toy="143" tox="36" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Cá mhinice ba riachtanach dó stad (OK)?" contextoffset="35" errorlength="2"/>
<error fromy="144" fromx="0" toy="144" tox="11" ruleId="Lingua::GA::Gramadoir/BACHOIR{cár}" msg="Ba chóir duit ‘cár’ a úsáid anseo" context="Cá n-oibrigh an t-údar sular imigh sí le ceol?" contextoffset="0" errorlength="12"/>
<error fromy="145" fromx="27" toy="145" tox="28" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Cá raibh na rudaí go léir (OK)?" contextoffset="27" errorlength="2"/>
<error fromy="146" fromx="0" toy="146" tox="10" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="Cá cuireann tú do thréad ar féarach?" contextoffset="0" errorlength="11"/>
<error fromy="147" fromx="0" toy="147" tox="11" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="Cá úsáidfear an mhóin?" contextoffset="0" errorlength="12"/>
<error fromy="148" fromx="0" toy="148" tox="6" ruleId="Lingua::GA::Gramadoir/BACHOIR{cá}" msg="Ba chóir duit ‘cá’ a úsáid anseo" context="Cár fág tú eisean?" contextoffset="0" errorlength="7"/>
<error fromy="149" fromx="0" toy="149" tox="8" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Cár bhfág tú eisean?" contextoffset="0" errorlength="9"/>
<error fromy="150" fromx="19" toy="150" tox="20" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Cár fágadh eisean (OK)?" contextoffset="19" errorlength="2"/>
<error fromy="151" fromx="17" toy="151" tox="22" ruleId="Lingua::GA::Gramadoir/IONADAI{i gcás}" msg="Focal ceart ach tá ‘i gcás’ níos coitianta" context="Sin é a dhéantar i gcas cuntair oibre cistine." contextoffset="17" errorlength="6"/>
<error fromy="152" fromx="0" toy="152" tox="5" ruleId="Lingua::GA::Gramadoir/PREFIXH" msg="Réamhlitir ‘h’ ar iarraidh" context="Cé iad na fir seo ag fanacht farat?" contextoffset="0" errorlength="6"/>
<error fromy="153" fromx="29" toy="153" tox="30" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Cé ea, rachaidh mé ann leat (OK)." contextoffset="29" errorlength="2"/>
<error fromy="154" fromx="0" toy="154" tox="4" ruleId="Lingua::GA::Gramadoir/BACHOIR{cén}" msg="Ba chóir duit ‘cén’ a úsáid anseo" context="Cé an ceart atá agamsa a thuilleadh fós a lorg ar an rí?" contextoffset="0" errorlength="5"/>
<error fromy="155" fromx="15" toy="155" tox="29" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="D'fhoilsigh sí a céad cnuasach filíochta i 1995." contextoffset="15" errorlength="15"/>
<error fromy="156" fromx="20" toy="156" tox="32" ruleId="Lingua::GA::Gramadoir/BACHOIR{huaire}" msg="Ba chóir duit ‘huaire’ a úsáid anseo" context="Chuir siad fios orm ceithre uaire ar an tslí sin." contextoffset="20" errorlength="13"/>
<error fromy="157" fromx="48" toy="157" tox="59" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Beidh ar Bhord Feidhmiúcháin an tUachtarán agus ceithre ball eile." contextoffset="48" errorlength="12"/>
<error fromy="158" fromx="51" toy="158" tox="52" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Tá sé tuigthe aige go bhfuil na ceithre dúile ann (OK)." contextoffset="51" errorlength="2"/>
<error fromy="159" fromx="0" toy="159" tox="11" ruleId="Lingua::GA::Gramadoir/PREFIXT" msg="Réamhlitir ‘t’ ar iarraidh" context="Cén amhránaí is fearr leat?" contextoffset="0" errorlength="12"/>
<error fromy="160" fromx="0" toy="160" tox="6" ruleId="Lingua::GA::Gramadoir/PREFIXT" msg="Réamhlitir ‘t’ ar iarraidh" context="Cén slí ar fhoghlaim tú an teanga?" contextoffset="0" errorlength="7"/>
<error fromy="161" fromx="72" toy="161" tox="73" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Cha dtug mé cur síos ach ar dhá bhabhta collaíochta san úrscéal ar fad (OK)." contextoffset="72" errorlength="2"/>
<error fromy="162" fromx="7" toy="162" tox="20" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Bhí an chéad cruinniú den Choimisiún i Ros Muc i nGaeltacht na Gaillimhe." contextoffset="7" errorlength="14"/>
<error fromy="163" fromx="6" toy="163" tox="18" ruleId="Lingua::GA::Gramadoir/PREFIXH" msg="Réamhlitir ‘h’ ar iarraidh" context="Tá sé chomh iontach le sneachta dearg." contextoffset="6" errorlength="13"/>
<error fromy="164" fromx="25" toy="164" tox="35" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Chuir mé céad punt chuig an banaltra." contextoffset="25" errorlength="11"/>
<error fromy="165" fromx="22" toy="165" tox="34" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Níl tú do do sheoladh chuig dhaoine a labhraíonn teanga dhothuigthe." contextoffset="22" errorlength="13"/>
<error fromy="166" fromx="41" toy="166" tox="50" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Seo deis iontach chun an Ghaeilge a chur chun chinn." contextoffset="41" errorlength="10"/>
<error fromy="167" fromx="54" toy="167" tox="55" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Tiocfaidh deontas faoin alt seo chun bheith iníoctha (OK)." contextoffset="54" errorlength="2"/>
<error fromy="168" fromx="34" toy="168" tox="39" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="D'éirídís ar maidin ar a ceathair a clog." contextoffset="34" errorlength="6"/>
<error fromy="169" fromx="25" toy="169" tox="33" ruleId="Lingua::GA::Gramadoir/IONADAI{chóir}" msg="Focal ceart ach tá ‘chóir’ níos coitianta" context="Shocraigh sé ar an toirt gur choir an t-ábhar tábhachtach seo a phlé leis na daoine." contextoffset="25" errorlength="9"/>
<error fromy="170" fromx="21" toy="170" tox="30" ruleId="Lingua::GA::Gramadoir/BACHOIR{huaire}" msg="Ba chóir duit ‘huaire’ a úsáid anseo" context="Caithfidh siad turas cúig uaire a chloig a dhéanamh." contextoffset="21" errorlength="10"/>
<error fromy="171" fromx="30" toy="171" tox="41" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Bhí sé cúig bhanlámh ar fhad, cúig banlámh ar leithead." contextoffset="30" errorlength="12"/>
<error fromy="172" fromx="17" toy="172" tox="28" ruleId="Lingua::GA::Gramadoir/CLAOCHLU" msg="Urú nó séimhiú ar iarraidh" context="Beirim mo mhionn dar an beart a rinne Dia le mo shinsir." contextoffset="17" errorlength="12"/>
<error fromy="173" fromx="6" toy="173" tox="15" ruleId="Lingua::GA::Gramadoir/BACHOIR{dár gcionn}" msg="Ba chóir duit ‘dár gcionn’ a úsáid anseo" context="An lá dar gcionn nochtadh gealltanas an Taoisigh sa nuachtán." contextoffset="6" errorlength="10"/>
<error fromy="174" fromx="20" toy="174" tox="35" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="Sa dara bliain déag dár braighdeanas, tháinig fear ar a theitheadh." contextoffset="20" errorlength="16"/>
<error fromy="175" fromx="52" toy="175" tox="60" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Beidh picéid ar an monarcha óna naoi a chlog maidin Dhé Luain." contextoffset="52" errorlength="9"/>
<error fromy="176" fromx="29" toy="176" tox="38" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Bíonn ranganna ar siúl oíche Dhéardaoin." contextoffset="29" errorlength="10"/>
<error fromy="177" fromx="30" toy="177" tox="39" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Cuireadh tús le himeachtaí ar Dhéardaoin na Féile le cluiche mór." contextoffset="30" errorlength="10"/>
<error fromy="178" fromx="25" toy="178" tox="32" ruleId="Lingua::GA::Gramadoir/PREFIXH" msg="Réamhlitir ‘h’ ar iarraidh" context="D'oibrigh mé liom go dtí Dé Aoine." contextoffset="25" errorlength="8"/>
<error fromy="179" fromx="24" toy="179" tox="28" ruleId="Lingua::GA::Gramadoir/CAIGHDEAN{déag}" msg="Foirm neamhchaighdeánach de ‘déag’" context="Míle naoi gcéad a hocht ndéag is fiche." contextoffset="24" errorlength="5"/>
<error fromy="180" fromx="21" toy="180" tox="30" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Feicim go bhfuil aon duine déag curtha san uaigh seo." contextoffset="21" errorlength="10"/>
<error fromy="181" fromx="69" toy="181" tox="70" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="D'fhás sé ag deireadh na naoú haoise déag agus fás an náisiúnachais (OK)." contextoffset="69" errorlength="2"/>
<error fromy="182" fromx="53" toy="182" tox="61" ruleId="Lingua::GA::Gramadoir/INPHRASE{a dó dhéag, dhá X déag}" msg="Ní úsáidtear an focal seo ach san abairtín ‘a dó dhéag, dhá X déag’ de ghnáth" context="Tabharfaidh an tUachtarán a óráid ag leath i ndiaidh a dó déag Dé Sathairn." contextoffset="53" errorlength="9"/>
<error fromy="183" fromx="15" toy="183" tox="25" ruleId="Lingua::GA::Gramadoir/INPHRASE{a trí déag, trí X déag}" msg="Ní úsáidtear an focal seo ach san abairtín ‘a trí déag, trí X déag’ de ghnáth" context="Bhuail an clog a trí dhéag." contextoffset="15" errorlength="11"/>
<error fromy="184" fromx="3" toy="184" tox="10" ruleId="Lingua::GA::Gramadoir/INPHRASE{a trí déag, trí X déag}" msg="Ní úsáidtear an focal seo ach san abairtín ‘a trí déag, trí X déag’ de ghnáth" context="Tá trí déag litir san fhocal seo." contextoffset="3" errorlength="8"/>
<error fromy="185" fromx="12" toy="185" tox="24" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Tógfaidh mé do coinnleoir óna ionad, mura ndéana tú aithrí." contextoffset="12" errorlength="13"/>
<error fromy="186" fromx="13" toy="186" tox="21" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Is cúis imní don pobal a laghad maoinithe a dhéantar ar Naíscoileanna." contextoffset="13" errorlength="9"/>
<error fromy="187" fromx="27" toy="187" tox="36" ruleId="Lingua::GA::Gramadoir/NICLAOCHLU" msg="Urú nó séimhiú gan ghá" context="Daoine eile atá ina mbaill den dhream seo." contextoffset="27" errorlength="10"/>
<error fromy="188" fromx="25" toy="188" tox="35" ruleId="Lingua::GA::Gramadoir/NICLAOCHLU" msg="Urú nó séimhiú gan ghá" context="Creidim go raibh siad de an thuairim seo." contextoffset="25" errorlength="11"/>
<error fromy="189" fromx="3" toy="189" tox="12" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Tá dhá teanga oifigiúla le stádas bunreachtúil á labhairt sa tír seo." contextoffset="3" errorlength="10"/>
<error fromy="190" fromx="0" toy="190" tox="10" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Dhá fiacail lárnacha i ngach aon chomhla." contextoffset="0" errorlength="11"/>
<error fromy="191" fromx="19" toy="191" tox="30" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Rug sí greim ar mo dhá gualainn agus an fhearg a bhí ina súile." contextoffset="19" errorlength="12"/>
<error fromy="192" fromx="7" toy="192" tox="14" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Bhí an dá taobh seo dá phearsantacht le feiceáil go soiléir." contextoffset="7" errorlength="8"/>
<error fromy="193" fromx="28" toy="193" tox="29" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Bhí Eibhlín ar a dhá glúin (OK)." contextoffset="28" errorlength="2"/>
<error fromy="194" fromx="20" toy="194" tox="25" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Is léir nach bhfuil an dhá theanga ar chomhchéim lena chéile." contextoffset="20" errorlength="6"/>
<error fromy="195" fromx="13" toy="195" tox="21" ruleId="Lingua::GA::Gramadoir/NIDARASEIMHIU" msg="Ní gá leis an dara séimhiú" context="Tionóladh an chéad dhá chomórtas i nGaoth Dobhair." contextoffset="13" errorlength="9"/>
<error fromy="196" fromx="43" toy="196" tox="47" ruleId="Lingua::GA::Gramadoir/BACHOIR{don}" msg="Ba chóir duit ‘don’ a úsáid anseo" context="Cá bhfuil feoil le fáil agamsa le tabhairt do an mhuintir?" contextoffset="43" errorlength="5"/>
<error fromy="197" fromx="44" toy="197" tox="56" ruleId="Lingua::GA::Gramadoir/BACHOIR{d'}" msg="Ba chóir duit ‘d'’ a úsáid anseo" context="Is amhlaidh a bheidh freisin do na tagairtí do airteagail." contextoffset="44" errorlength="13"/>
<error fromy="198" fromx="40" toy="198" tox="43" ruleId="Lingua::GA::Gramadoir/BACHOIR{dá}" msg="Ba chóir duit ‘dá’ a úsáid anseo" context="Tá sé de chúram seirbhís a chur ar fáil do a chustaiméirí i nGaeilge." contextoffset="40" errorlength="4"/>
<error fromy="199" fromx="29" toy="199" tox="33" ruleId="Lingua::GA::Gramadoir/BACHOIR{dár}" msg="Ba chóir duit ‘dár’ a úsáid anseo" context="Seinnigí moladh ar an gcruit do ár máthair." contextoffset="29" errorlength="5"/>
<error fromy="200" fromx="27" toy="200" tox="31" ruleId="Lingua::GA::Gramadoir/BACHOIR{dár}" msg="Ba chóir duit ‘dár’ a úsáid anseo" context="Is é seo mo Mhac muirneach do ar thug mé gnaoi." contextoffset="27" errorlength="5"/>
<error fromy="201" fromx="21" toy="201" tox="35" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Tá an domhan go léir faoi suaimhneas." contextoffset="21" errorlength="15"/>
<error fromy="202" fromx="59" toy="202" tox="65" ruleId="Lingua::GA::Gramadoir/BACHOIR{faoin}" msg="Ba chóir duit ‘faoin’ a úsáid anseo" context="Caithfidh pobal na Gaeltachta iad féin cinneadh a dhéanamh faoi an Ghaeilge." contextoffset="59" errorlength="7"/>
<error fromy="203" fromx="31" toy="203" tox="36" ruleId="Lingua::GA::Gramadoir/BACHOIR{faoina}" msg="Ba chóir duit ‘faoina’ a úsáid anseo" context="Cuireann sí a neart mar chrios faoi a coim." contextoffset="31" errorlength="6"/>
<error fromy="204" fromx="21" toy="204" tox="27" ruleId="Lingua::GA::Gramadoir/BACHOIR{faoinár}" msg="Ba chóir duit ‘faoinár’ a úsáid anseo" context="Cuireann sé ciníocha faoi ár smacht agus cuireann sé náisiúin faoinár gcosa." contextoffset="21" errorlength="7"/>
<error fromy="205" fromx="41" toy="205" tox="51" ruleId="Lingua::GA::Gramadoir/CLAOCHLU" msg="Urú nó séimhiú ar iarraidh" context="Tá dualgas ar an gComhairle sin tabhairt faoin cúram seo." contextoffset="41" errorlength="11"/>
<error fromy="206" fromx="17" toy="206" tox="33" ruleId="Lingua::GA::Gramadoir/NICLAOCHLU" msg="Urú nó séimhiú gan ghá" context="Tugadh mioneolas faoin dtionscnamh seo in Eagrán a haon." contextoffset="17" errorlength="17"/>
<error fromy="207" fromx="25" toy="207" tox="38" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="Bhí lúcháir ar an Tiarna faoina dhearna sé!" contextoffset="25" errorlength="14"/>
<error fromy="208" fromx="56" toy="208" tox="68" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="Ní bheidh gearán ag duine ar bith faoin gciste fial atá faoinár cúram." contextoffset="56" errorlength="13"/>
<error fromy="209" fromx="16" toy="209" tox="30" ruleId="Lingua::GA::Gramadoir/NIDARASEIMHIU" msg="Ní gá leis an dara séimhiú" context="Beidh paráid Lá Fhéile Phádraig i mBostún." contextoffset="16" errorlength="15"/>
<error fromy="210" fromx="62" toy="210" tox="63" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Tá Féile Bhealtaine an Oireachtais ar siúl an tseachtain seo (OK)." contextoffset="62" errorlength="2"/>
<error fromy="211" fromx="21" toy="211" tox="41" ruleId="Lingua::GA::Gramadoir/BACHOIR{ná}" msg="Ba chóir duit ‘ná’ a úsáid anseo" context="Fágtar na mílte eile gan ghéaga nó radharc na súl." contextoffset="21" errorlength="21"/>
<error fromy="212" fromx="47" toy="212" tox="57" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Tá ar chumas an duine saol iomlán a chaitheamh gan theanga eile á brú air." contextoffset="47" errorlength="11"/>
<error fromy="213" fromx="19" toy="213" tox="30" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Tá gruaim mhór orm gan Chaitlín." contextoffset="19" errorlength="12"/>
<error fromy="214" fromx="37" toy="214" tox="45" ruleId="Lingua::GA::Gramadoir/WEAKSEIMHIU{gan}" msg="Leanann séimhiú an réamhfhocal ‘gan’ go minic, ach ní léir é sa chás seo" context="Deir daoine eile, áfach, gur dailtín gan maith é." contextoffset="37" errorlength="9"/>
<error fromy="215" fromx="42" toy="215" tox="52" ruleId="Lingua::GA::Gramadoir/WEAKSEIMHIU{gan}" msg="Leanann séimhiú an réamhfhocal ‘gan’ go minic, ach ní léir é sa chás seo" context="Fuarthas an fear marbh ar an trá, a chorp gan máchail gan ghortú." contextoffset="42" errorlength="11"/>
<error fromy="216" fromx="26" toy="216" tox="27" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Dúirt sé liom gan pósadh (OK)." contextoffset="26" errorlength="2"/>
<error fromy="217" fromx="74" toy="217" tox="75" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Na duilleoga ar an ngas beag, cruth lansach orthu agus iad gan cos fúthu (OK)." contextoffset="74" errorlength="2"/>
<error fromy="218" fromx="52" toy="218" tox="53" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="D'fhág sin gan meas dá laghad ag duine ar bith air (OK)." contextoffset="52" errorlength="2"/>
<error fromy="219" fromx="24" toy="219" tox="25" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Tá mé gan cos go brách (OK)." contextoffset="24" errorlength="2"/>
<error fromy="220" fromx="65" toy="220" tox="66" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Níl sé ceadaithe aistriú ó rang go chéile gan cead a fháil uaim (OK)." contextoffset="65" errorlength="2"/>
<error fromy="221" fromx="67" toy="221" tox="78" ruleId="Lingua::GA::Gramadoir/PREFIXH" msg="Réamhlitir ‘h’ ar iarraidh" context="Is stáit ilteangacha iad cuid mhór de na stáit sin atá aonteangach go oifigiúil." contextoffset="67" errorlength="12"/>
<error fromy="222" fromx="30" toy="222" tox="37" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="Ní bheidh bonn comparáide ann go beidh torthaí Dhaonáireamh 2007 ar fáil." contextoffset="30" errorlength="8"/>
<error fromy="223" fromx="17" toy="223" tox="25" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Rug sé ar ais mé go dhoras an Teampaill." contextoffset="17" errorlength="9"/>
<error fromy="224" fromx="61" toy="224" tox="62" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Tiocfaidh coimhlintí chun tosaigh sa Chumann ó am go chéile (OK)." contextoffset="61" errorlength="2"/>
<error fromy="225" fromx="82" toy="225" tox="83" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Is turas iontach é an turas ó bheith i do thosaitheoir go bheith i do mhúinteoir (OK)." contextoffset="82" errorlength="2"/>
<error fromy="226" fromx="16" toy="226" tox="20" ruleId="Lingua::GA::Gramadoir/BACHOIR{go dtí an}" msg="Ba chóir duit ‘go dtí an’ a úsáid anseo" context="Chuaigh mé suas go an doras cúil a chaisleáin." contextoffset="16" errorlength="5"/>
<error fromy="227" fromx="23" toy="227" tox="27" ruleId="Lingua::GA::Gramadoir/BACHOIR{go dtí}" msg="Ba chóir duit ‘go dtí’ a úsáid anseo" context="Tháinig Pól Ó Coileáin go mo theach ar maidin." contextoffset="23" errorlength="5"/>
<error fromy="228" fromx="28" toy="228" tox="39" ruleId="Lingua::GA::Gramadoir/BACHOIR{go dtí}" msg="Ba chóir duit ‘go dtí’ a úsáid anseo" context="Bhí an teachtaireacht dulta go m'inchinn." contextoffset="28" errorlength="12"/>
<error fromy="229" fromx="12" toy="229" tox="23" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Tar, téanam go dtí bhean na bhfíseanna." contextoffset="12" errorlength="12"/>
<error fromy="230" fromx="60" toy="230" tox="61" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Agus rachaidh mé siar go dtí thú tráthnóna, más maith leat (OK)." contextoffset="60" errorlength="2"/>
<error fromy="231" fromx="15" toy="231" tox="26" ruleId="Lingua::GA::Gramadoir/BACHOIR{go}" msg="Ba chóir duit ‘go’ a úsáid anseo" context="Ba mhaith liom gur bhfágann daoine óga an scoil agus iad ullmhaithe." contextoffset="15" errorlength="12"/>
<error fromy="232" fromx="11" toy="232" tox="19" ruleId="Lingua::GA::Gramadoir/BACHOIR{go}" msg="Ba chóir duit ‘go’ a úsáid anseo" context="Bhraith mé gur fuair mé boladh trom tais uathu." contextoffset="11" errorlength="9"/>
<error fromy="233" fromx="20" toy="233" tox="28" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="An ea nach cás leat gur bhfág mo dheirfiúr an freastal fúmsa i m'aonar?" contextoffset="20" errorlength="9"/>
<error fromy="234" fromx="10" toy="234" tox="20" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="B'fhéidir gurbh fearr é seo duit ná leamhnacht na bó ba mhilse i gcontae Chill Mhantáin." contextoffset="10" errorlength="11"/>
<error fromy="235" fromx="8" toy="235" tox="18" ruleId="Lingua::GA::Gramadoir/BACHOIR{in}" msg="Ba chóir duit ‘in’ a úsáid anseo" context="Tá ainm i n-easnamh a mbeadh coinne agat leis." contextoffset="8" errorlength="11"/>
<error fromy="236" fromx="8" toy="236" tox="16" ruleId="Lingua::GA::Gramadoir/BACHOIR{in}" msg="Ba chóir duit ‘in’ a úsáid anseo" context="Tá ainm i easnamh a mbeadh coinne agat leis." contextoffset="8" errorlength="9"/>
<error fromy="237" fromx="34" toy="237" tox="38" ruleId="Lingua::GA::Gramadoir/BACHOIR{in dhá}" msg="Ba chóir duit ‘in dhá’ a úsáid anseo" context="An bhfuil aon uachtar reoite agat i dhá chuisneoir?" contextoffset="34" errorlength="5"/>
<error fromy="238" fromx="34" toy="238" tox="44" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="An bhfuil aon uachtar reoite agat i cuisneoir?" contextoffset="34" errorlength="11"/>
<error fromy="239" fromx="34" toy="239" tox="45" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="An bhfuil aon uachtar reoite agat i chuisneoir?" contextoffset="34" errorlength="12"/>
<error fromy="240" fromx="30" toy="240" tox="35" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="Táimid ag lorg 200 Club Gailf i gach cearn d'Éirinn." contextoffset="30" errorlength="6"/>
<error fromy="241" fromx="36" toy="241" tox="41" ruleId="Lingua::GA::Gramadoir/BACHOIR{in bhur}" msg="Ba chóir duit ‘in bhur’ a úsáid anseo" context="An bhfuil aon uachtar reoite agaibh i bhur mála?" contextoffset="36" errorlength="6"/>
<error fromy="242" fromx="38" toy="242" tox="47" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Bhí slám de pháipéar tais ag cruinniú i mhullach a chéile." contextoffset="38" errorlength="10"/>
<error fromy="243" fromx="39" toy="243" tox="40" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Fuair Derek Bell bás tobann i Phoenix (OK)." contextoffset="39" errorlength="2"/>
<error fromy="244" fromx="57" toy="244" tox="58" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Tá níos mó ná 8500 múinteoir ann i thart faoi 540 scoil (OK)." contextoffset="57" errorlength="2"/>
<error fromy="245" fromx="34" toy="245" tox="37" ruleId="Lingua::GA::Gramadoir/BACHOIR{sa}" msg="Ba chóir duit ‘sa’ a úsáid anseo" context="An bhfuil aon uachtar reoite agat i an chuisneoir?" contextoffset="34" errorlength="4"/>
<error fromy="246" fromx="34" toy="246" tox="37" ruleId="Lingua::GA::Gramadoir/BACHOIR{sna}" msg="Ba chóir duit ‘sna’ a úsáid anseo" context="An bhfuil aon uachtar reoite agat i na cuisneoirí?" contextoffset="34" errorlength="4"/>
<error fromy="247" fromx="29" toy="247" tox="31" ruleId="Lingua::GA::Gramadoir/BACHOIR{ina}" msg="Ba chóir duit ‘ina’ a úsáid anseo" context="An bhfuil aon uachtar reoite i a cuisneoir?" contextoffset="29" errorlength="3"/>
<error fromy="248" fromx="23" toy="248" tox="25" ruleId="Lingua::GA::Gramadoir/BACHOIR{ina}" msg="Ba chóir duit ‘ina’ a úsáid anseo" context="Roghnaigh na teangacha i a nochtar na leathanaigh seo." contextoffset="23" errorlength="3"/>
<error fromy="249" fromx="36" toy="249" tox="39" ruleId="Lingua::GA::Gramadoir/BACHOIR{inar}" msg="Ba chóir duit ‘inar’ a úsáid anseo" context="Rinne gach cine é sin sna cathracha i ar lonnaíodar." contextoffset="36" errorlength="4"/>
<error fromy="250" fromx="29" toy="250" tox="32" ruleId="Lingua::GA::Gramadoir/BACHOIR{inár}" msg="Ba chóir duit ‘inár’ a úsáid anseo" context="An bhfuil aon uachtar reoite i ár mála?" contextoffset="29" errorlength="4"/>
<error fromy="251" fromx="30" toy="251" tox="34" ruleId="Lingua::GA::Gramadoir/BACHOIR{i}" msg="Ba chóir duit ‘i’ a úsáid anseo" context="Thug sé seo deis dom breathnú in mo thimpeall." contextoffset="30" errorlength="5"/>
<error fromy="252" fromx="40" toy="252" tox="46" ruleId="Lingua::GA::Gramadoir/BACHOIR{i}" msg="Ba chóir duit ‘i’ a úsáid anseo" context="Phós sí Pádraig, fear ón mBlascaod Mór, in 1982." contextoffset="40" errorlength="7"/>
<error fromy="253" fromx="49" toy="253" tox="50" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Phós sí Pádraig, fear ón mBlascaod Mór, in 1892 (OK)." contextoffset="49" errorlength="2"/>
<error fromy="254" fromx="52" toy="254" tox="53" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Theastaigh uaibh beirt bheith in bhur scríbhneoirí (OK)." contextoffset="52" errorlength="2"/>
<error fromy="255" fromx="41" toy="255" tox="42" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Beidh an spórt seo á imirt in dhá ionad (OK)." contextoffset="41" errorlength="2"/>
<error fromy="256" fromx="33" toy="256" tox="45" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="Cad é an rud is mó faoi na Gaeil ina chuireann sé suim?" contextoffset="33" errorlength="13"/>
<error fromy="257" fromx="12" toy="257" tox="25" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="Tá beirfean inár craiceann faoi mar a bheimis i sorn." contextoffset="12" errorlength="14"/>
<error fromy="258" fromx="51" toy="258" tox="61" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Is tuar dóchais é an méid dul chun cinn atá déanta le bhlianta beaga." contextoffset="51" errorlength="11"/>
<error fromy="259" fromx="42" toy="259" tox="43" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Leanaigí oraibh le bhur ndílseacht dúinn (OK)." contextoffset="42" errorlength="2"/>
<error fromy="260" fromx="66" toy="260" tox="67" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Baineann an scéim le thart ar 28,000 miondíoltóir ar fud na tíre (OK)." contextoffset="66" errorlength="2"/>
<error fromy="261" fromx="74" toy="261" tox="75" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Níor cuireadh aon tine síos, ar ndóigh, le chomh breá is a bhí an aimsir (OK)." contextoffset="74" errorlength="2"/>
<error fromy="262" fromx="36" toy="262" tox="37" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Tá sí ag teacht le thú a fheiceáil (OK)." contextoffset="36" errorlength="2"/>
<error fromy="263" fromx="39" toy="263" tox="43" ruleId="Lingua::GA::Gramadoir/BACHOIR{leis an}" msg="Ba chóir duit ‘leis an’ a úsáid anseo" context="D'fhéadfadh tábhacht a bheith ag baint le an gcéad toisc díobh sin." contextoffset="39" errorlength="5"/>
<error fromy="264" fromx="50" toy="264" tox="54" ruleId="Lingua::GA::Gramadoir/BACHOIR{leis na}" msg="Ba chóir duit ‘leis na’ a úsáid anseo" context="Molann an Coimisiún go maoineofaí scéim chun tacú le na pobail." contextoffset="50" errorlength="5"/>
<error fromy="265" fromx="34" toy="265" tox="37" ruleId="Lingua::GA::Gramadoir/BACHOIR{lena}" msg="Ba chóir duit ‘lena’ a úsáid anseo" context="Labhraíodh gach duine an fhírinne le a chomharsa." contextoffset="34" errorlength="4"/>
<error fromy="266" fromx="40" toy="266" tox="43" ruleId="Lingua::GA::Gramadoir/BACHOIR{lena}" msg="Ba chóir duit ‘lena’ a úsáid anseo" context="Le halt 16 i ndáil le hiarratas ar ordú le a meastar gur tugadh toiliú." contextoffset="40" errorlength="4"/>
<error fromy="267" fromx="28" toy="267" tox="32" ruleId="Lingua::GA::Gramadoir/BACHOIR{lenar}" msg="Ba chóir duit ‘lenar’ a úsáid anseo" context="Beir i do láimh ar an tslat le ar bhuail tú an abhainn, agus seo leat." contextoffset="28" errorlength="5"/>
<error fromy="268" fromx="35" toy="268" tox="39" ruleId="Lingua::GA::Gramadoir/BACHOIR{lenár}" msg="Ba chóir duit ‘lenár’ a úsáid anseo" context="Ba mhaith liom buíochas a ghlacadh le ár seirbhís riaracháin." contextoffset="35" errorlength="5"/>
<error fromy="269" fromx="20" toy="269" tox="25" ruleId="Lingua::GA::Gramadoir/PREFIXH" msg="Réamhlitir ‘h’ ar iarraidh" context="Tógann siad cuid de le iad féin a théamh." contextoffset="20" errorlength="6"/>
<error fromy="270" fromx="32" toy="270" tox="42" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Tá do scrios chomh leathan leis an farraige." contextoffset="32" errorlength="11"/>
<error fromy="271" fromx="14" toy="271" tox="25" ruleId="Lingua::GA::Gramadoir/BACHOIR{lena}" msg="Ba chóir duit ‘lena’ a úsáid anseo" context="Cuir alt eile lenar bhfuil scríofa agat i gCeist a trí." contextoffset="14" errorlength="12"/>
<error fromy="272" fromx="26" toy="272" tox="36" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="Is linne í ar ndóigh agus lenár clann." contextoffset="26" errorlength="11"/>
<error fromy="273" fromx="0" toy="273" tox="12" ruleId="Lingua::GA::Gramadoir/PRESENT" msg="Ba chóir duit an aimsir láithreach a úsáid anseo" context="Má thiocfaidh acmhainní breise ar fáil, beidh mé sásta." contextoffset="0" errorlength="13"/>
<error fromy="274" fromx="0" toy="274" tox="8" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Má tugann rí breith ar na boicht le cothromas, bunófar a ríchathaoir go brách." contextoffset="0" errorlength="9"/>
<error fromy="275" fromx="38" toy="275" tox="39" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Má deirim libh é, ní chreidfidh sibh (OK)." contextoffset="38" errorlength="2"/>
<error fromy="276" fromx="52" toy="276" tox="53" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Má tá suim agat sa turas seo, seol d'ainm chugamsa (OK)." contextoffset="52" errorlength="2"/>
<error fromy="277" fromx="36" toy="277" tox="37" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Má fuair níor fhreagair sé an facs (OK)." contextoffset="36" errorlength="2"/>
<error fromy="278" fromx="28" toy="278" tox="37" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Roghnaítear an bhliain 1961 mar pointe tosaigh don anailís." contextoffset="28" errorlength="10"/>
<error fromy="279" fromx="13" toy="279" tox="25" ruleId="Lingua::GA::Gramadoir/PREFIXT" msg="Réamhlitir ‘t’ ar iarraidh" context="Aithnítear é mar an údarás." contextoffset="13" errorlength="13"/>
<error fromy="280" fromx="0" toy="280" tox="8" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Más mhian leat tuilleadh eolais a fháil, scríobh chugainn." contextoffset="0" errorlength="9"/>
<error fromy="281" fromx="30" toy="281" tox="33" ruleId="Lingua::GA::Gramadoir/CAIGHDEAN{méid, mhéid}" msg="Foirm neamhchaighdeánach de ‘méid, mhéid’" context="Tá caitheamh na hola ag dul i méad i gcónaí." contextoffset="30" errorlength="4"/>
<error fromy="282" fromx="61" toy="282" tox="74" ruleId="Lingua::GA::Gramadoir/UATHA" msg="Tá gá leis an leagan uatha anseo" context="Tosaíodh ar mhodh adhlactha eile ina mbaintí úsáid as clocha measartha móra." contextoffset="61" errorlength="14"/>
<error fromy="283" fromx="9" toy="283" tox="20" ruleId="Lingua::GA::Gramadoir/BACHOIR{m'}" msg="Ba chóir duit ‘m'’ a úsáid anseo" context="Comhlíon mo aitheanta agus mairfidh tú beo." contextoffset="9" errorlength="12"/>
<error fromy="284" fromx="15" toy="284" tox="26" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Ceapadh mise i mo bolscaire." contextoffset="15" errorlength="12"/>
<error fromy="285" fromx="37" toy="285" tox="45" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Tá mé ag sclábhaíocht ag iarraidh mo dhá gasúr a chur trí scoil." contextoffset="37" errorlength="9"/>
<error fromy="286" fromx="15" toy="286" tox="35" ruleId="Lingua::GA::Gramadoir/UATHA" msg="Tá gá leis an leagan uatha anseo" context="Agus anois bhí mórsheisear iníonacha ag an sagart." contextoffset="15" errorlength="21"/>
<error fromy="287" fromx="0" toy="287" tox="9" ruleId="Lingua::GA::Gramadoir/BACHOIR{murar}" msg="Ba chóir duit ‘murar’ a úsáid anseo" context="Mura dtuig siad é, nach dóibh féin is mó náire?" contextoffset="0" errorlength="10"/>
<error fromy="288" fromx="35" toy="288" tox="36" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Mura bhfuair, sin an chraobh aige (OK)." contextoffset="35" errorlength="2"/>
<error fromy="289" fromx="0" toy="289" tox="10" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="Mura tagann aon duine i gcabhair orainn, rachaimid anonn chugaibh." contextoffset="0" errorlength="11"/>
<error fromy="290" fromx="4" toy="290" tox="15" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="Fiú mura éiríonn liom, beidh mé ábalta cabhrú ar bhonn deonach." contextoffset="4" errorlength="12"/>
<error fromy="291" fromx="73" toy="291" tox="74" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Murach bheith mar sin, bheadh sé dodhéanta dó oibriú na huaireanta fada (OK)." contextoffset="73" errorlength="2"/>
<error fromy="292" fromx="0" toy="292" tox="17" ruleId="Lingua::GA::Gramadoir/BACHOIR{mura}" msg="Ba chóir duit ‘mura’ a úsáid anseo" context="Murar chruthaítear lá agus oíche... teilgim uaim sliocht Iacóib." contextoffset="0" errorlength="18"/>
<error fromy="293" fromx="0" toy="293" tox="15" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Murar gcruthaigh mise lá agus oíche... teilgim uaim sliocht Iacóib." contextoffset="0" errorlength="16"/>
<error fromy="294" fromx="37" toy="294" tox="42" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="An bhfuil aon uachtar reoite ag fear na bád?" contextoffset="37" errorlength="6"/>
<error fromy="295" fromx="18" toy="295" tox="27" ruleId="Lingua::GA::Gramadoir/PREFIXH" msg="Réamhlitir ‘h’ ar iarraidh" context="Is mór ag náisiún na Éireann a choibhneas speisialta le daoine de bhunadh na hÉireann atá ina gcónaí ar an gcoigríoch." contextoffset="18" errorlength="10"/>
<error fromy="296" fromx="44" toy="296" tox="58" ruleId="Lingua::GA::Gramadoir/PREFIXH" msg="Réamhlitir ‘h’ ar iarraidh" context="Chuir an Coimisiún féin comhfhreagras chuig na eagraíochtaí seo ag lorg eolais faoina ngníomhaíochtaí." contextoffset="44" errorlength="15"/>
<error fromy="297" fromx="35" toy="297" tox="49" ruleId="Lingua::GA::Gramadoir/GENITIVE" msg="Tá gá leis an leagan ginideach anseo" context="Tá an tréith sin coitianta i measc na nÉireannaigh sa tír seo." contextoffset="35" errorlength="15"/>
<error fromy="298" fromx="12" toy="298" tox="21" ruleId="Lingua::GA::Gramadoir/BACHOIR{an}" msg="Ba chóir duit ‘an’ a úsáid anseo" context="Athdhéantar na snáithe i ngach ceann de na curaclaim seo." contextoffset="12" errorlength="10"/>
<error fromy="299" fromx="0" toy="299" tox="10" ruleId="Lingua::GA::Gramadoir/PREFIXH" msg="Réamhlitir ‘h’ ar iarraidh" context="Ná iompaígí chun na n-íol, agus ná dealbhaígí déithe de mhiotal." contextoffset="0" errorlength="11"/>
<error fromy="300" fromx="55" toy="300" tox="56" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Tá tú níos faide sa tír ná is dleathach duit a bheith (OK)." contextoffset="55" errorlength="2"/>
<error fromy="301" fromx="44" toy="301" tox="45" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Ach ní sin an cultúr a bhí ná atá go fóill (OK)." contextoffset="44" errorlength="2"/>
<error fromy="302" fromx="14" toy="302" tox="22" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Agus creid nó ná chreid, nach bhfuil an lámhscríbhinn agam féin." contextoffset="14" errorlength="9"/>
<error fromy="303" fromx="43" toy="303" tox="50" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Is fearr de bhéile luibheanna agus grá leo ná mhart méith agus gráin leis." contextoffset="43" errorlength="8"/>
<error fromy="304" fromx="41" toy="304" tox="42" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Is fearr an bás ná bheith beo ar dhéirc (OK)." contextoffset="41" errorlength="2"/>
<error fromy="305" fromx="32" toy="305" tox="33" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Nach raibh dóthain eolais aige (OK)?" contextoffset="32" errorlength="2"/>
<error fromy="306" fromx="0" toy="306" tox="12" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="Nach bainfidh mé uaidh an méid a ghoid sé uaim?" contextoffset="0" errorlength="13"/>
<error fromy="307" fromx="0" toy="307" tox="10" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Nach ghasta a fuair tú í!" contextoffset="0" errorlength="11"/>
<error fromy="308" fromx="44" toy="308" tox="57" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Tháinig na bróga chomh fada siar le haimsir Naomh Phádraig féin." contextoffset="44" errorlength="14"/>
<error fromy="309" fromx="0" toy="309" tox="7" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Nár breá liom claíomh a bheith agam i mo ghlac!" contextoffset="0" errorlength="8"/>
<error fromy="310" fromx="0" toy="310" tox="13" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Nár bhfreagair sé thú, focal ar fhocal." contextoffset="0" errorlength="14"/>
<error fromy="311" fromx="43" toy="311" tox="54" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Feicimid gur de dheasca a n-easumhlaíochta nárbh féidir leo dul isteach ann." contextoffset="43" errorlength="12"/>
<error fromy="312" fromx="0" toy="312" tox="12" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="Ní fuaireamar puinn eile tuairisce air i ndiaidh sin." contextoffset="0" errorlength="13"/>
<error fromy="313" fromx="0" toy="313" tox="12" ruleId="Lingua::GA::Gramadoir/BACHOIR{níor}" msg="Ba chóir duit ‘níor’ a úsáid anseo" context="Ní chuireadar aon áthas ar Mhac Dara." contextoffset="0" errorlength="13"/>
<error fromy="314" fromx="34" toy="314" tox="35" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Ní dúirt sé cad a bhí déanta acu (OK)." contextoffset="34" errorlength="2"/>
<error fromy="315" fromx="0" toy="315" tox="11" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Ní féadfaidh a gcuid airgid ná óir iad a shábháil." contextoffset="0" errorlength="12"/>
<error fromy="316" fromx="34" toy="316" tox="35" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Ní bhfaighidh tú aon déirce uaim (OK)." contextoffset="34" errorlength="2"/>
<error fromy="317" fromx="33" toy="317" tox="34" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Ní deir sé é seo le haon ghráin (OK)." contextoffset="33" errorlength="2"/>
<error fromy="318" fromx="0" toy="318" tox="5" ruleId="Lingua::GA::Gramadoir/PREFIXH" msg="Réamhlitir ‘h’ ar iarraidh" context="Ní iad sin do phíopaí ar an tábla!" contextoffset="0" errorlength="6"/>
<error fromy="319" fromx="0" toy="319" tox="11" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Ní dheireadh aon duine acu aon rud liom." contextoffset="0" errorlength="12"/>
<error fromy="320" fromx="0" toy="320" tox="9" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Ní fhéidir dóibh duine a shaoradh ón mbás." contextoffset="0" errorlength="10"/>
<error fromy="321" fromx="23" toy="321" tox="36" ruleId="Lingua::GA::Gramadoir/BREISCHEIM" msg="Ba chóir duit an bhreischéim a úsáid anseo" context="Bhí an méid sin airgid níba luachmhar dúinn ná maoin an domhain." contextoffset="23" errorlength="14"/>
<error fromy="322" fromx="27" toy="322" tox="31" ruleId="Lingua::GA::Gramadoir/BREISCHEIM" msg="Ba chóir duit an bhreischéim a úsáid anseo" context="An raibh duine ar bith acu ní ba bhocht ná eisean?" contextoffset="27" errorlength="5"/>
<error fromy="323" fromx="14" toy="323" tox="16" ruleId="Lingua::GA::Gramadoir/BREISCHEIM" msg="Ba chóir duit an bhreischéim a úsáid anseo" context="Eisean beagán níb óga ná mise." contextoffset="14" errorlength="3"/>
<error fromy="324" fromx="24" toy="324" tox="34" ruleId="Lingua::GA::Gramadoir/BACHOIR{níba}" msg="Ba chóir duit ‘níba’ a úsáid anseo" context="Agus do na daoine a bhí níb boichte ná iad féin." contextoffset="24" errorlength="11"/>
<error fromy="325" fromx="14" toy="325" tox="22" ruleId="Lingua::GA::Gramadoir/BACHOIR{níb}" msg="Ba chóir duit ‘níb’ a úsáid anseo" context="Eisean beagán níba óige ná mise." contextoffset="14" errorlength="9"/>
<error fromy="326" fromx="22" toy="326" tox="32" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Bhí na páistí ag éirí níba tréine." contextoffset="22" errorlength="11"/>
<error fromy="327" fromx="38" toy="327" tox="48" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Tá tuairisc ar an léacht a thug Niamh Nic Suibhne ar leathanach a hocht." contextoffset="38" errorlength="11"/>
<error fromy="328" fromx="38" toy="328" tox="49" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Is saoririseoir agus ceoltóir í Aoife Nic Chormaic." contextoffset="38" errorlength="12"/>
<error fromy="329" fromx="20" toy="329" tox="32" ruleId="Lingua::GA::Gramadoir/BACHOIR{ní}" msg="Ba chóir duit ‘ní’ a úsáid anseo" context="&quot;Tá,&quot; ar sise, &quot;ach níor fhacthas é sin.&quot;" contextoffset="35" errorlength="13"/>
<error fromy="330" fromx="0" toy="330" tox="6" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Níor gá do dheoraí riamh codladh sa tsráid; Bhí mo dhoras riamh ar leathadh." contextoffset="0" errorlength="7"/>
<error fromy="331" fromx="20" toy="331" tox="29" ruleId="Lingua::GA::Gramadoir/BACHOIR{ní}" msg="Ba chóir duit ‘ní’ a úsáid anseo" context="&quot;Tá,&quot; ar sise, &quot;ach níor fuair muid aon ocras fós." contextoffset="35" errorlength="10"/>
<error fromy="332" fromx="0" toy="332" tox="9" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Níor mbain sé leis an dream a bhí i gcogar ceilge." contextoffset="0" errorlength="10"/>
<error fromy="333" fromx="0" toy="333" tox="12" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Níorbh foláir dó éisteacht a thabhairt dom." contextoffset="0" errorlength="13"/>
<error fromy="334" fromx="7" toy="334" tox="15" ruleId="Lingua::GA::Gramadoir/PREFIXH" msg="Réamhlitir ‘h’ ar iarraidh" context="Eoghan Ó Anluain a thabharfaidh léacht deiridh na comhdhála." contextoffset="7" errorlength="9"/>
<error fromy="335" fromx="10" toy="335" tox="19" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Ach anois ó cuimhním air, bhí ardán coincréite sa pháirc." contextoffset="10" errorlength="10"/>
<error fromy="336" fromx="57" toy="336" tox="58" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Bhuel, fan ar strae mar sin ó tá tú chomh mímhúinte sin (OK)." contextoffset="57" errorlength="2"/>
<error fromy="337" fromx="57" toy="337" tox="58" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Ní maith liom é ar chor ar bith ó fuair sé an litir sin (OK)." contextoffset="57" errorlength="2"/>
<error fromy="338" fromx="29" toy="338" tox="34" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Tabhair an t-ordú seo leanas ó béal." contextoffset="29" errorlength="6"/>
<error fromy="339" fromx="21" toy="339" tox="24" ruleId="Lingua::GA::Gramadoir/BACHOIR{ón}" msg="Ba chóir duit ‘ón’ a úsáid anseo" context="Bíodh bhur ngrá saor ó an chur i gcéill." contextoffset="21" errorlength="4"/>
<error fromy="340" fromx="49" toy="340" tox="62" ruleId="Lingua::GA::Gramadoir/NIGA{Dé}" msg="Níl gá leis an fhocal ‘Dé’" context="Beidh an chéad chruinniú oifigiúil ag an gcoiste oíche Dé Luain." contextoffset="49" errorlength="14"/>
<error fromy="341" fromx="21" toy="341" tox="26" ruleId="Lingua::GA::Gramadoir/CLAOCHLU" msg="Urú nó séimhiú ar iarraidh" context="Bíodh bhur ngrá saor ón cur i gcéill." contextoffset="21" errorlength="6"/>
<error fromy="342" fromx="15" toy="342" tox="26" ruleId="Lingua::GA::Gramadoir/NICLAOCHLU" msg="Urú nó séimhiú gan ghá" context="Ná glacaim sos ón thochailt." contextoffset="15" errorlength="12"/>
<error fromy="343" fromx="13" toy="343" tox="15" ruleId="Lingua::GA::Gramadoir/BACHOIR{óna}" msg="Ba chóir duit ‘óna’ a úsáid anseo" context="Amharcann sé ó a ionad cónaithe ar gach aon neach dá maireann ar talamh." contextoffset="13" errorlength="3"/>
<error fromy="344" fromx="43" toy="344" tox="46" ruleId="Lingua::GA::Gramadoir/BACHOIR{ónar}" msg="Ba chóir duit ‘ónar’ a úsáid anseo" context="Seo iad a gcéimeanna de réir na n-áiteanna ó ar thosaíodar." contextoffset="43" errorlength="4"/>
<error fromy="345" fromx="29" toy="345" tox="32" ruleId="Lingua::GA::Gramadoir/BACHOIR{ónár}" msg="Ba chóir duit ‘ónár’ a úsáid anseo" context="Agus rinne sé ár bhfuascailt ó ár naimhde." contextoffset="29" errorlength="4"/>
<error fromy="346" fromx="49" toy="346" tox="64" ruleId="Lingua::GA::Gramadoir/BACHOIR{óna}" msg="Ba chóir duit ‘óna’ a úsáid anseo" context="Seo teaghlach ag a bhfuil go leor fadhbanna agus ónar dteastaíonn tacaíocht atá dírithe." contextoffset="49" errorlength="16"/>
<error fromy="347" fromx="28" toy="347" tox="36" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="Bhíodh súil in airde againn ónár túir faire." contextoffset="28" errorlength="9"/>
<error fromy="348" fromx="44" toy="348" tox="55" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Tá do ghéaga spréite ar bhraillín ghléigeal os fharraige faoileán." contextoffset="44" errorlength="12"/>
<error fromy="349" fromx="18" toy="349" tox="28" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Ar ais leis ansin os chomhair an teilifíseáin." contextoffset="18" errorlength="11"/>
<error fromy="350" fromx="23" toy="350" tox="26" ruleId="Lingua::GA::Gramadoir/PREFIXH" msg="Réamhlitir ‘h’ ar iarraidh" context="Uaidh féin, b'fhéidir, pé é féin." contextoffset="23" errorlength="4"/>
<error fromy="351" fromx="23" toy="351" tox="36" ruleId="Lingua::GA::Gramadoir/CLAOCHLU" msg="Urú nó séimhiú ar iarraidh" context="Agus tháinig scéin air roimh an pobal seo ar a líonmhaireacht." contextoffset="23" errorlength="14"/>
<error fromy="352" fromx="18" toy="352" tox="29" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Is gaiste é eagla roimh daoine." contextoffset="18" errorlength="12"/>
<error fromy="353" fromx="34" toy="353" tox="43" ruleId="Lingua::GA::Gramadoir/BACHOIR{san}" msg="Ba chóir duit ‘san’ a úsáid anseo" context="An bhfuil aon uachtar reoite agat sa oighear?" contextoffset="34" errorlength="10"/>
<error fromy="354" fromx="19" toy="354" tox="30" ruleId="Lingua::GA::Gramadoir/BACHOIR{san}" msg="Ba chóir duit ‘san’ a úsáid anseo" context="Gortaíodh ceathrar sa n-eachtra." contextoffset="19" errorlength="12"/>
<error fromy="355" fromx="34" toy="355" tox="45" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="An bhfuil aon uachtar reoite agat sa cuisneoir?" contextoffset="34" errorlength="12"/>
<error fromy="356" fromx="32" toy="356" tox="39" ruleId="Lingua::GA::Gramadoir/NICLAOCHLU" msg="Urú nó séimhiú gan ghá" context="Ní mór dom umhlú agus cic maith sa thóin a thabhairt duit." contextoffset="32" errorlength="8"/>
<error fromy="357" fromx="34" toy="357" tox="43" ruleId="Lingua::GA::Gramadoir/PREFIXT" msg="Réamhlitir ‘t’ ar iarraidh" context="An bhfuil aon uachtar reoite agat sa seamair?" contextoffset="34" errorlength="10"/>
<error fromy="358" fromx="44" toy="358" tox="45" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="An bhfuil aon uachtar reoite agat sa scoil (OK)?" contextoffset="44" errorlength="2"/>
<error fromy="359" fromx="47" toy="359" tox="48" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="An bhfuil aon uachtar reoite agat sa samhradh (OK)?" contextoffset="47" errorlength="2"/>
<error fromy="360" fromx="28" toy="360" tox="41" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Tá sé bráthair de chuid Ord San Phroinsias." contextoffset="28" errorlength="14"/>
<error fromy="361" fromx="0" toy="361" tox="9" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="San fásach cuirfidh mé crainn chéadrais." contextoffset="0" errorlength="10"/>
<error fromy="362" fromx="34" toy="362" tox="44" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="An bhfuil aon uachtar reoite agat san foraois?" contextoffset="34" errorlength="11"/>
<error fromy="363" fromx="35" toy="363" tox="42" ruleId="Lingua::GA::Gramadoir/BACHOIR{sa}" msg="Ba chóir duit ‘sa’ a úsáid anseo" context="Tugaimid faoi abhainn na Sionainne san bhád locha ó Ros Comáin." contextoffset="35" errorlength="8"/>
<error fromy="364" fromx="41" toy="364" tox="42" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Tógadh an foirgneamh féin san 18ú haois (OK)." contextoffset="41" errorlength="2"/>
<error fromy="365" fromx="47" toy="365" tox="54" ruleId="Lingua::GA::Gramadoir/BACHOIR{huaire}" msg="Ba chóir duit ‘huaire’ a úsáid anseo" context="Ní féidir iad a sheinm le snáthaid ach cúig nó sé uaire." contextoffset="47" errorlength="8"/>
<error fromy="366" fromx="67" toy="366" tox="68" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Dúirt sé uair amháin nach raibh áit eile ar mhaith leis cónaí ann (OK)." contextoffset="67" errorlength="2"/>
<error fromy="367" fromx="17" toy="367" tox="32" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Céard atá ann ná sé cathaoirleach coiste." contextoffset="17" errorlength="16"/>
<error fromy="368" fromx="32" toy="368" tox="46" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Cuireadh boscaí ticeála isteach seachas bhoscaí le freagraí a scríobh isteach." contextoffset="32" errorlength="15"/>
<error fromy="369" fromx="72" toy="369" tox="73" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Dá ndéanfadh sí amhlaidh réiteodh sí an fhadhb seachas bheith á ghéarú (OK)." contextoffset="72" errorlength="2"/>
<error fromy="370" fromx="0" toy="370" tox="6" ruleId="Lingua::GA::Gramadoir/BACHOIR{iad}" msg="Ba chóir duit ‘iad’ a úsáid anseo" context="Is siad na rudaí crua a mhairfidh." contextoffset="0" errorlength="7"/>
<error fromy="371" fromx="50" toy="371" tox="61" ruleId="Lingua::GA::Gramadoir/PREFIXH" msg="Réamhlitir ‘h’ ar iarraidh" context="Tá ar a laghad ceithre ní sa litir a chuir scaoll sna oifigigh." contextoffset="50" errorlength="12"/>
<error fromy="372" fromx="31" toy="372" tox="41" ruleId="Lingua::GA::Gramadoir/BACHOIR{sa, san}" msg="Ba chóir duit ‘sa, san’ a úsáid anseo" context="Soláthraíonn an Roinn seisiúin sna Gaeilge labhartha do na mic léinn." contextoffset="31" errorlength="11"/>
<error fromy="373" fromx="0" toy="373" tox="15" ruleId="Lingua::GA::Gramadoir/BACHOIR{sular}" msg="Ba chóir duit ‘sular’ a úsáid anseo" context="Sula sroicheadar an bun arís, bhí an oíche ann agus chuadar ar strae." contextoffset="0" errorlength="16"/>
<error fromy="374" fromx="74" toy="374" tox="75" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Sula ndearna sé amhlaidh, más ea, léirigh sé a chreidiúint san fhoireann (OK)." contextoffset="74" errorlength="2"/>
<error fromy="375" fromx="30" toy="375" tox="43" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="Iompróidh siad thú lena lámha sula bhuailfeá do chos in aghaidh cloiche." contextoffset="30" errorlength="14"/>
<error fromy="376" fromx="4" toy="376" tox="15" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Ach sular sroich sé, dúirt sí: &quot;Dúnaigí an doras air!&quot;" contextoffset="4" errorlength="12"/>
<error fromy="377" fromx="48" toy="377" tox="54" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Chuir sé iad ina suí mar a raibh onóir acu thar an cuid eile a fuair cuireadh." contextoffset="48" errorlength="7"/>
<error fromy="378" fromx="23" toy="378" tox="31" ruleId="Lingua::GA::Gramadoir/INPHRASE{thar maoil}" msg="Ní úsáidtear an focal seo ach san abairtín ‘thar maoil’ de ghnáth" context="Bhí an chathair ag cur thar maol le filí de gach cineál." contextoffset="23" errorlength="9"/>
<error fromy="379" fromx="9" toy="379" tox="17" ruleId="Lingua::GA::Gramadoir/BACHOIR{huaire}" msg="Ba chóir duit ‘huaire’ a úsáid anseo" context="Timpeall trí uaire a chloig ina dhiaidh sin tháinig an bhean isteach." contextoffset="9" errorlength="9"/>
<error fromy="380" fromx="58" toy="380" tox="62" ruleId="Lingua::GA::Gramadoir/BACHOIR{trína}" msg="Ba chóir duit ‘trína’ a úsáid anseo" context="Scríobhaim chugaibh mar gur maitheadh daoibh bhur bpeacaí trí a ainm." contextoffset="58" errorlength="5"/>
<error fromy="381" fromx="33" toy="381" tox="37" ruleId="Lingua::GA::Gramadoir/BACHOIR{trína}" msg="Ba chóir duit ‘trína’ a úsáid anseo" context="Cuirtear i láthair na struchtúir trí a reáchtálfar gníomhartha ag an leibhéal náisiúnta." contextoffset="33" errorlength="5"/>
<error fromy="382" fromx="31" toy="382" tox="36" ruleId="Lingua::GA::Gramadoir/BACHOIR{trínar}" msg="Ba chóir duit ‘trínar’ a úsáid anseo" context="Ní fhillfidh siad ar an ngeata trí ar ghabh siad isteach." contextoffset="31" errorlength="6"/>
<error fromy="383" fromx="33" toy="383" tox="38" ruleId="Lingua::GA::Gramadoir/BACHOIR{tríd an}" msg="Ba chóir duit ‘tríd an’ a úsáid anseo" context="Beirimid an bua go caithréimeach trí an té úd a thug grá dúinn." contextoffset="33" errorlength="6"/>
<error fromy="384" fromx="49" toy="384" tox="54" ruleId="Lingua::GA::Gramadoir/BACHOIR{trínár}" msg="Ba chóir duit ‘trínár’ a úsáid anseo" context="Coinníodh lenár sála sa chaoi nárbh fhéidir siúl trí ár sráideanna." contextoffset="49" errorlength="6"/>
<error fromy="385" fromx="15" toy="385" tox="22" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Gabhfaidh siad trí muir na hÉigipte." contextoffset="15" errorlength="8"/>
<error fromy="386" fromx="36" toy="386" tox="42" ruleId="Lingua::GA::Gramadoir/BACHOIR{trí na}" msg="Ba chóir duit ‘trí na’ a úsáid anseo" context="Feidhmeoidh an ciste coimisiúnaithe tríd na foilsitheoirí go príomha." contextoffset="36" errorlength="7"/>
<error fromy="387" fromx="20" toy="387" tox="30" ruleId="Lingua::GA::Gramadoir/BACHOIR{trínar}" msg="Ba chóir duit ‘trínar’ a úsáid anseo" context="Ba é an gleann cúng trína ghabh an abhainn." contextoffset="20" errorlength="11"/>
<error fromy="388" fromx="28" toy="388" tox="42" ruleId="Lingua::GA::Gramadoir/BACHOIR{trína}" msg="Ba chóir duit ‘trína’ a úsáid anseo" context="Is mar a chéile an próiseas trínar ndéantar é seo." contextoffset="28" errorlength="15"/>
<error fromy="389" fromx="4" toy="389" tox="16" ruleId="Lingua::GA::Gramadoir/URU" msg="Urú ar iarraidh" context="Mar trínár peacaí, tá do phobal ina ábhar gáire ag cách máguaird orainn." contextoffset="4" errorlength="13"/>
<error fromy="390" fromx="59" toy="390" tox="68" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Beidh cúrsa Gaeilge ar siúl do mhic léinn in Áras Mháirtín Uí Cadhain." contextoffset="59" errorlength="10"/>
<error fromy="391" fromx="19" toy="391" tox="33" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Nár thug sí póg do gach uile duine?" contextoffset="19" errorlength="15"/>
<error fromy="392" fromx="26" toy="392" tox="27" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="D'ith na daoine uile bia (OK)." contextoffset="26" errorlength="2"/>
<error fromy="393" fromx="17" toy="393" tox="28" ruleId="Lingua::GA::Gramadoir/SEIMHIU" msg="Séimhiú ar iarraidh" context="Idir dhá sholas, um tráthnóna, faoi choim na hoíche agus sa dorchadas." contextoffset="17" errorlength="12"/>
<error fromy="394" fromx="51" toy="394" tox="52" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Straitéis Chomhphobail um bainistíocht dramhaíola (OK)." contextoffset="51" errorlength="2"/>
<error fromy="395" fromx="22" toy="395" tox="29" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Bhíodh an dinnéar acu um mheán lae." contextoffset="22" errorlength="8"/>
<error fromy="396" fromx="15" toy="396" tox="20" ruleId="Lingua::GA::Gramadoir/NODATIVE" msg="Ní úsáidtear an tabharthach ach in abairtí speisialta" context="Conas a bheadh Éirinn agus Meiriceá difriúil?" contextoffset="15" errorlength="6"/>
<error fromy="397" fromx="17" toy="397" tox="18" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Ba chois tine é (OK)." contextoffset="17" errorlength="2"/>
<error fromy="398" fromx="44" toy="398" tox="45" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Bhí cuid mhór teannais agus iomaíochta ann (OK)." contextoffset="44" errorlength="2"/>
<error fromy="399" fromx="22" toy="399" tox="23" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Galar crúibe is béil (OK)." contextoffset="22" errorlength="2"/>
<error fromy="400" fromx="30" toy="400" tox="31" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Caitheann sé go leor ama ann (OK)." contextoffset="30" errorlength="2"/>
<error fromy="401" fromx="22" toy="401" tox="33" ruleId="Lingua::GA::Gramadoir/NOGENITIVE" msg="Níl gá leis an leagan ginideach anseo" context="An raibh mórán daoine ag an tsiopa?" contextoffset="22" errorlength="12"/>
<error fromy="402" fromx="31" toy="402" tox="46" ruleId="Lingua::GA::Gramadoir/NOGENITIVE" msg="Níl gá leis an leagan ginideach anseo" context="Ní raibh dúil bheo le feiceáil ar na bhfuinneog." contextoffset="31" errorlength="16"/>
<error fromy="403" fromx="42" toy="403" tox="43" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Bhí, dála an scéil, ocht mbean déag aige (OK)." contextoffset="42" errorlength="2"/>
<error fromy="404" fromx="3" toy="404" tox="19" ruleId="Lingua::GA::Gramadoir/NOGENITIVE" msg="Níl gá leis an leagan ginideach anseo" context="Cá bhfuil an tseomra?" contextoffset="3" errorlength="17"/>
<error fromy="405" fromx="3" toy="405" tox="16" ruleId="Lingua::GA::Gramadoir/NOGENITIVE" msg="Níl gá leis an leagan ginideach anseo" context="Is iad na nGardaí." contextoffset="3" errorlength="14"/>
<error fromy="406" fromx="21" toy="406" tox="22" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Éirí Amach na Cásca (OK)." contextoffset="21" errorlength="2"/>
<error fromy="407" fromx="40" toy="407" tox="41" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Leas phobal na hÉireann agus na hEorpa (OK)." contextoffset="40" errorlength="2"/>
<error fromy="408" fromx="42" toy="408" tox="43" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Fáilte an deamhain is an diabhail romhat (OK)." contextoffset="42" errorlength="2"/>
<error fromy="409" fromx="36" toy="409" tox="37" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Go deo na ndeor, go deo na díleann (OK)." contextoffset="36" errorlength="2"/>
<error fromy="410" fromx="9" toy="410" tox="18" ruleId="Lingua::GA::Gramadoir/NIURU" msg="Urú gan ghá" context="Clann na bPoblachta a thug siad orthu féin." contextoffset="9" errorlength="10"/>
<error fromy="411" fromx="36" toy="411" tox="48" ruleId="Lingua::GA::Gramadoir/NICLAOCHLU" msg="Urú nó séimhiú gan ghá" context="Cruthaíodh an chloch sin go domhain faoin dtalamh." contextoffset="36" errorlength="13"/>
<error fromy="412" fromx="11" toy="412" tox="19" ruleId="Lingua::GA::Gramadoir/NIURU" msg="Urú gan ghá" context="Tá ainm in n-easnamh a mbeadh coinne agat leis." contextoffset="11" errorlength="9"/>
<error fromy="413" fromx="24" toy="413" tox="28" ruleId="Lingua::GA::Gramadoir/NIURU" msg="Urú gan ghá" context="Tá muid compordach inar gcuid &quot;fírinní&quot; féin." contextoffset="24" errorlength="5"/>
<error fromy="414" fromx="63" toy="414" tox="66" ruleId="Lingua::GA::Gramadoir/NIURU" msg="Urú gan ghá" context="Tá siad ag éileamh go n-íocfaí iad as a gcuid costais agus iad mbun traenála." contextoffset="63" errorlength="4"/>
<error fromy="415" fromx="50" toy="415" tox="51" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Cruthaíodh an chloch sin go domhain faoin gcrann (OK)." contextoffset="50" errorlength="2"/>
<error fromy="416" fromx="3" toy="416" tox="11" ruleId="Lingua::GA::Gramadoir/NIURU" msg="Urú gan ghá" context="An n-ólfaidh tú rud éigin?" contextoffset="3" errorlength="9"/>
<error fromy="417" fromx="5" toy="417" tox="8" ruleId="Lingua::GA::Gramadoir/NIAITCH" msg="Réamhlitir ‘h’ gan ghá" context="Nach holc an mhaise duit a bheith ag magadh." contextoffset="5" errorlength="4"/>
<error fromy="418" fromx="41" toy="418" tox="42" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Dún do bhéal, a mhiúil na haon chloiche (OK)!" contextoffset="41" errorlength="2"/>
<error fromy="419" fromx="76" toy="419" tox="77" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Scaoileadh seachtar duine chun báis i mBaile Átha Cliath le hocht mí anuas (OK)." contextoffset="76" errorlength="2"/>
<error fromy="420" fromx="63" toy="420" tox="64" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Ní dhúnfaidh an t-ollmhargadh go dtí a haon a chlog ar maidin (OK)." contextoffset="63" errorlength="2"/>
<error fromy="421" fromx="68" toy="421" tox="69" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Is mar gheall ar sin atá líníocht phictiúrtha chomh húsáideach sin (OK)." contextoffset="68" errorlength="2"/>
<error fromy="422" fromx="35" toy="422" tox="36" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Tá sí ag feidhmiú go héifeachtach (OK)." contextoffset="35" errorlength="2"/>
<error fromy="423" fromx="55" toy="423" tox="56" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Ní hionann cuingir na ngabhar agus cuingir na lánúine (OK)." contextoffset="55" errorlength="2"/>
<error fromy="424" fromx="3" toy="424" tox="6" ruleId="Lingua::GA::Gramadoir/NIAITCH" msg="Réamhlitir ‘h’ gan ghá" context="Ba hiad na hamhráin i dtosach ba chúis leis." contextoffset="3" errorlength="4"/>
<error fromy="425" fromx="33" toy="425" tox="34" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Ní hé lá na gaoithe lá na scolb (OK)." contextoffset="33" errorlength="2"/>
<error fromy="426" fromx="14" toy="426" tox="17" ruleId="Lingua::GA::Gramadoir/NIAITCH" msg="Réamhlitir ‘h’ gan ghá" context="Ba iad na trí háit iad Bostún, Baile Átha Cliath agus Nua Eabhrac." contextoffset="14" errorlength="4"/>
<error fromy="427" fromx="28" toy="427" tox="29" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Phós sé bean eile ina háit (OK)." contextoffset="28" errorlength="2"/>
<error fromy="428" fromx="45" toy="428" tox="46" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Cá ham a tháinig sí a staidéar anseo ó thús (OK)?" contextoffset="45" errorlength="2"/>
<error fromy="429" fromx="71" toy="429" tox="72" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Bhí a dheartháir ag siúl na gceithre hairde agus bhí seisean ina shuí (OK)." contextoffset="71" errorlength="2"/>
<error fromy="430" fromx="37" toy="430" tox="38" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Chaith sé an dara hoíche i Sligeach (OK)." contextoffset="37" errorlength="2"/>
<error fromy="431" fromx="54" toy="431" tox="55" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Tá sé i gcóip a rinneadh i lár na cúigiú haoise déag (OK)." contextoffset="54" errorlength="2"/>
<error fromy="432" fromx="37" toy="432" tox="38" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Chuir sí a dhá huillinn ar an bhord (OK)." contextoffset="37" errorlength="2"/>
<error fromy="433" fromx="16" toy="433" tox="23" ruleId="Lingua::GA::Gramadoir/NIAITCH" msg="Réamhlitir ‘h’ gan ghá" context="Chuir mé mo dhá huillinn ar an bhord." contextoffset="16" errorlength="8"/>
<error fromy="434" fromx="37" toy="434" tox="38" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Cuireadh cuid mhaith acu go hÉirinn (OK)." contextoffset="37" errorlength="2"/>
<error fromy="435" fromx="73" toy="435" tox="74" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Tá tús curtha le clár chun rampaí luchtaithe a chur sna hotharcharranna (OK)." contextoffset="73" errorlength="2"/>
<error fromy="436" fromx="37" toy="436" tox="38" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Cuimhnígí ar na héachtaí a rinne sé (OK)." contextoffset="37" errorlength="2"/>
<error fromy="437" fromx="92" toy="437" tox="93" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Creidim go mbeidh iontas ar mhuintir na hÉireann nuair a fheiceann siad an feidhmchlár seo (OK)." contextoffset="92" errorlength="2"/>
<error fromy="438" fromx="48" toy="438" tox="49" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Tháinig múinteoir úr i gceithre huaire fichead (OK)." contextoffset="48" errorlength="2"/>
<error fromy="439" fromx="54" toy="439" tox="55" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Caithfidh siad turas cúig huaire a chloig a dhéanamh (OK)." contextoffset="54" errorlength="2"/>
<error fromy="440" fromx="10" toy="440" tox="19" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="In Éirinn chaitheann breis is 30 faoin gcéad de mhná toitíní." contextoffset="10" errorlength="10"/>
<error fromy="441" fromx="0" toy="441" tox="8" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Chuirfear in iúl do dhaoine gurb é sin an aidhm atá againn." contextoffset="0" errorlength="9"/>
<error fromy="442" fromx="73" toy="442" tox="74" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Déan cur síos ar dhá thoradh a bhíonn ag caitheamh tobac ar an tsláinte (OK)." contextoffset="73" errorlength="2"/>
<error fromy="443" fromx="67" toy="443" tox="68" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Má bhrúitear idir chnónna agus bhlaoscanna faightear ola inchaite (OK)." contextoffset="67" errorlength="2"/>
<error fromy="444" fromx="39" toy="444" tox="40" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Ní chothaíonn na briathra na bráithre (OK)." contextoffset="39" errorlength="2"/>
<error fromy="445" fromx="58" toy="445" tox="59" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Cha bhíonn striapachas agus seafóid Mheiriceá ann feasta (OK)." contextoffset="58" errorlength="2"/>
<error fromy="446" fromx="66" toy="446" tox="67" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Tá cleachtadh ag daoine ó bhíonn siad an-óg ar uaigneas imeachta (OK)." contextoffset="66" errorlength="2"/>
<error fromy="447" fromx="64" toy="447" tox="65" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Ar an láithreán seo gheofar foclóirí agus liostaí téarmaíochta (OK)." contextoffset="64" errorlength="2"/>
<error fromy="448" fromx="14" toy="448" tox="26" ruleId="Lingua::GA::Gramadoir/RELATIVE" msg="Tá gá leis an fhoirm spleách anseo" context="An oíche sin, sular chuaigh sé a chodladh, chuir sé litir fhada dom." contextoffset="14" errorlength="13"/>
<error fromy="449" fromx="13" toy="449" tox="25" ruleId="Lingua::GA::Gramadoir/RELATIVE" msg="Tá gá leis an fhoirm spleách anseo" context="Tá mioneolas faoinar rinne sé ansin." contextoffset="13" errorlength="13"/>
<error fromy="450" fromx="0" toy="450" tox="12" ruleId="Lingua::GA::Gramadoir/RELATIVE" msg="Tá gá leis an fhoirm spleách anseo" context="Níor rinneadh a leithéid le fada agus ní raibh aon slat tomhais acu." contextoffset="0" errorlength="13"/>
<error fromy="451" fromx="35" toy="451" tox="49" ruleId="Lingua::GA::Gramadoir/RELATIVE" msg="Tá gá leis an fhoirm spleách anseo" context="Teastaíonn uaidh an scéal a insint sula ngeobhaidh sé bás." contextoffset="35" errorlength="15"/>
<error fromy="452" fromx="26" toy="452" tox="31" ruleId="Lingua::GA::Gramadoir/RELATIVE" msg="Tá gá leis an fhoirm spleách anseo" context="Tá folúntas sa chomhlacht ina tá mé ag obair faoi láthair." contextoffset="26" errorlength="6"/>
<error fromy="453" fromx="0" toy="453" tox="12" ruleId="Lingua::GA::Gramadoir/RELATIVE" msg="Tá gá leis an fhoirm spleách anseo" context="Ní gheobhaidh an mealltóir nathrach aon táille." contextoffset="0" errorlength="13"/>
<error fromy="454" fromx="3" toy="454" tox="9" ruleId="Lingua::GA::Gramadoir/ABSOLUTE" msg="Níl gá leis an fhoirm spleách" context="Má dhearna sí praiseach de, thosaigh sí arís go bhfuair sí ceart é." contextoffset="3" errorlength="7"/>
<error fromy="455" fromx="8" toy="455" tox="12" ruleId="Lingua::GA::Gramadoir/ABSOLUTE" msg="Níl gá leis an fhoirm spleách" context="Nuair a raibh mé óg." contextoffset="8" errorlength="5"/>
<error fromy="456" fromx="40" toy="456" tox="41" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="An clapsholas a raibh mé ag dréim leis (OK)." contextoffset="40" errorlength="2"/>
<error fromy="457" fromx="58" toy="457" tox="59" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Chan fhacthas dom go raibh an saibhreas céanna i mBéarla (OK)." contextoffset="58" errorlength="2"/>
<error fromy="458" fromx="32" toy="458" tox="37" ruleId="Lingua::GA::Gramadoir/PREFIXD" msg="Réamhlitir ‘d'’ ar iarraidh" context="Chuaigh sé chun na huaimhe agus fhéach sé isteach." contextoffset="32" errorlength="6"/>
<error fromy="459" fromx="31" toy="459" tox="32" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Fágadh faoi smacht a lámh iad (OK)." contextoffset="31" errorlength="2"/>
<error fromy="460" fromx="19" toy="460" tox="20" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="An íosfá ubh eile (OK)?" contextoffset="19" errorlength="2"/>
<error fromy="461" fromx="19" toy="461" tox="33" ruleId="Lingua::GA::Gramadoir/NIDEE" msg="Réamhlitir ‘d'’ gan ghá" context="Níorbh fhada, ámh, gur d'fhoghlaim sí an téarma ceart uathu." contextoffset="19" errorlength="15"/>
<error fromy="462" fromx="48" toy="462" tox="49" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Nílim ag rá gur d'aon ghuth a ainmníodh Sheehy (OK)." contextoffset="48" errorlength="2"/>
<error fromy="463" fromx="20" toy="463" tox="32" ruleId="Lingua::GA::Gramadoir/NIDEE" msg="Réamhlitir ‘d'’ gan ghá" context="Scríobh sé soiscéal ina d'athródh an eaglais í féin go deo." contextoffset="20" errorlength="13"/>
<error fromy="464" fromx="21" toy="464" tox="28" ruleId="Lingua::GA::Gramadoir/NISEIMHIU" msg="Séimhiú gan ghá" context="Tá bonn i bhfad níos dhoimhne ná sin le Féilte an Oireachtais." contextoffset="21" errorlength="8"/>
<error fromy="465" fromx="54" toy="465" tox="55" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Tá a chuid leabhar tiontaithe go dhá theanga fichead (OK)." contextoffset="54" errorlength="2"/>
<error fromy="466" fromx="50" toy="466" tox="51" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Tá dún cosanta eile ar an taobh thoir den oileán (OK)." contextoffset="50" errorlength="2"/>
<error fromy="467" fromx="57" toy="467" tox="58" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Déan teagmháil leis an Rannóg ag an seoladh thuasluaite (OK)." contextoffset="57" errorlength="2"/>
<error fromy="468" fromx="61" toy="468" tox="62" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Nochtadh na fírinne sa dóigh a n-admhódh an té is bréagaí í (OK)." contextoffset="61" errorlength="2"/>
<error fromy="469" fromx="47" toy="469" tox="52" ruleId="Lingua::GA::Gramadoir/BACHOIR{san}" msg="Ba chóir duit ‘san’ a úsáid anseo" context="Abairt a chuireann in iúl dearóile na hÉireann sa 18ú agus sa 19ú haois." contextoffset="47" errorlength="6"/>
<error fromy="470" fromx="6" toy="470" tox="20" ruleId="Lingua::GA::Gramadoir/GENITIVE" msg="Tá gá leis an leagan ginideach anseo" context="Oíche na gaoithe móra." contextoffset="6" errorlength="15"/>
<error fromy="471" fromx="6" toy="471" tox="19" ruleId="Lingua::GA::Gramadoir/GENITIVE" msg="Tá gá leis an leagan ginideach anseo" context="Oíche na gaoithe mór." contextoffset="6" errorlength="14"/>
<error fromy="472" fromx="47" toy="472" tox="56" ruleId="Lingua::GA::Gramadoir/UATHA" msg="Tá gá leis an leagan uatha anseo" context="Tá a chumas sa Ghaeilge níos airde ná cumas na bhfear óga." contextoffset="47" errorlength="10"/>
<error fromy="473" fromx="37" toy="473" tox="38" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Beirt bhan Mheiriceánacha a bhí ann (OK)." contextoffset="37" errorlength="2"/>
<error fromy="474" fromx="38" toy="474" tox="39" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Tá sé-- tá sé- mo ---shin-seanathair (OK)." contextoffset="38" errorlength="2"/>
<error fromy="475" fromx="3" toy="475" tox="8" ruleId="Lingua::GA::Gramadoir/INPHRASE{ní foláir}" msg="Ní úsáidtear an focal seo ach san abairtín ‘ní foláir’ de ghnáth" context="Is foláir dóibh a ndualgais a chomhlíonadh." contextoffset="3" errorlength="6"/>
<error fromy="476" fromx="23" toy="476" tox="24" ruleId="Lingua::GA::Gramadoir/IONADAI{ré}" msg="Focal ceart ach tá ‘ré’ níos coitianta" context="Bhain na toibreacha le re eile agus le dream daoine atá imithe." contextoffset="23" errorlength="2"/>
<error fromy="477" fromx="14" toy="477" tox="17" ruleId="Lingua::GA::Gramadoir/INPHRASE{ar son}" msg="Ní úsáidtear an focal seo ach san abairtín ‘ar son’ de ghnáth" context="Labhair mé ar shon na daoine." contextoffset="14" errorlength="4"/>
<error fromy="478" fromx="37" toy="478" tox="39" ruleId="Lingua::GA::Gramadoir/INPHRASE{ar son}" msg="Ní úsáidtear an focal seo ach san abairtín ‘ar son’ de ghnáth" context="Tá sé tábhachtach bheith ag obair an son na cearta." contextoffset="37" errorlength="3"/>
<error fromy="479" fromx="5" toy="479" tox="24" ruleId="Lingua::GA::Gramadoir/ONEART" msg="Níl gá leis an gcéad alt cinnte anseo" context="Ba é an fear an phortaigh a tháinig thart leis na plátaí bia." contextoffset="5" errorlength="20"/>
<error fromy="480" fromx="20" toy="480" tox="44" ruleId="Lingua::GA::Gramadoir/BADART" msg="Níl gá leis an alt cinnte anseo" context="Tá dhá shiombail ag an bharr gach leathanaigh." contextoffset="20" errorlength="25"/>
<error fromy="481" fromx="13" toy="481" tox="32" ruleId="Lingua::GA::Gramadoir/BADART" msg="Níl gá leis an alt cinnte anseo" context="Tabharfaimid an t-ainm do mháthar uirthi." contextoffset="13" errorlength="20"/>
<error fromy="482" fromx="26" toy="482" tox="27" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Is iad na trí cheist sin (OK)." contextoffset="26" errorlength="2"/>
<error fromy="483" fromx="60" toy="483" tox="61" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Lena chois sin, dá bharr seo, dá bhrí sin, ina aghaidh seo (OK)." contextoffset="60" errorlength="2"/>
<error fromy="484" fromx="18" toy="484" tox="19" ruleId="Lingua::GA::Gramadoir/GRAM{^OK}" msg="B'fhéidir gur focal iasachta é seo (tá na litreacha ‘^OK’ neamhchoitianta)" context="Cén t-ionadh sin (OK)?" contextoffset="18" errorlength="2"/>
RESEOF

$results = decode('utf8', $results);

my @resultarr = split(/\n/,$results);

my $output = $gr->grammatical_errors($test);
my $errorno = 0;
is( @resultarr, @$output, 'Verifying correct number of errors found');
foreach my $error (@$output) {
	(my $ln, my $snt, my $offset, my $len) = $error =~ m/^<error fromy="([0-9]+)".* context="([^"]+)" contextoffset="([0-9]+)" errorlength="([0-9]+)"\/>$/;
	my $errortext = substr($snt,$offset,$len);
	$ln++;
	is ( $error, $resultarr[$errorno], "Verifying error \"$errortext\" found on input line $ln" );
	++$errorno;
}

exit;
