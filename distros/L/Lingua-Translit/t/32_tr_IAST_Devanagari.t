use strict;
use Lingua::Translit;
use Test::More tests => 2;
use utf8;

$/ = undef;

my $bhagavad_gita = <DATA>;

my $t  = new Lingua::Translit( 'IAST Devanagari' );
my $tr = new Lingua::Translit( 'Devanagari IAST' );
my $bgout = $tr->translit($t->translit($bhagavad_gita));

my @input = qw/
                a ā i ī u ū ṛ ṝ ḷ ḹ e ai o au ṃ aṃ ḥ aḥ ka kā ki kī ku kū
                kṛ kṝ kḷ kḹ ke kai ko kau kha ga gha ṅa ca cha ja jha ña
                ṭa ṭha ḍa ḍha ṇa ta tha da dha na pa pha ba bha ma ya ra
                la va śa ṣa sa ha bh
            /;
my $output = 'अ आ इ ई उ ऊ ऋ ॠ ऌ ॡ ए ऐ ओ औ ं अं ः अः क का कि की कु कू कृ कॄ कॢ कॣ के' .
             ' कै को कौ ख ग घ ङ च छ ज झ ञ ट ठ ड ढ ण त थ द ध न प फ ब भ म य र ल ' .
             'व श ष स ह भ्';

is($output, join(' ', map {$t->translit($_)} @input) , "IAST -> Devanagari");

# This tests a complete round-trip of transliterating the Bhagavad Gita from
# IAST to Devanāgarī and back to IAST
is($bgout, $bhagavad_gita, "IAST -> Devanagari -> IAST");


__DATA__
dhṛtarāṣṭra uvāca
dharmakṣetre kurukṣetre samavetā yuyutsavaḥ
māmakāḥ pāṇḍavāś caiva kim akurvata saṃjaya

saṃjaya uvāca
dṛṣṭvā tu pāṇḍavānīkaṃ vyūḍhaṃ duryodhanas tadā
ācāryam upasaṃgamya rājā vacanam abravīt

paśyaitāṃ pāṇḍuputrāṇām ācārya mahatīṃ camūm
vyūḍhāṃ drupadaputreṇa tava śiṣyeṇa dhīmatā

atra śūrā maheṣvāsā bhīmārjunasamā yudhi
yuyudhāno virāṭaś ca drupadaś ca mahārathaḥ

dhṛṣṭaketuś cekitānaḥ kāśirājaś ca vīryavān
purujit kuntibhojaś ca śaibyaś ca narapuṃgavaḥ

yudhāmanyuś ca vikrānta uttamaujāś ca vīryavān
saubhadro draupadeyāś ca sarva eva mahārathāḥ

asmākaṃ tu viśiṣṭā ye tān nibodha dvijottama
nāyakā mama sainyasya saṃjñārthaṃ tān bravīmi te

bhavān bhīṣmaś ca karṇaś ca kṛpaś ca samitiṃjayaḥ
aśvatthāmā vikarṇaś ca saumadattis tathaiva ca

anye ca bahavaḥ śūrā madarthe tyaktajīvitāḥ
nānāśastrapraharaṇāḥ sarve yuddhaviśāradāḥ

aparyāptaṃ tad asmākaṃ balaṃ bhīṣmābhirakṣitam
paryāptaṃ tv idam eteṣāṃ balaṃ bhīmābhirakṣitam

ayaneṣu ca sarveṣu yathābhāgam avasthitāḥ
bhīṣmam evābhirakṣantu bhavantaḥ sarva eva hi

tasya saṃjanayan harṣaṃ kuruvṛddhaḥ pitāmahaḥ
siṃhanādaṃ vinadyoccaiḥ śaṅkhaṃ dadhmau pratāpavān

tataḥ śaṅkhāś ca bheryaś ca paṇavānakagomukhāḥ
sahasaivābhyahanyanta sa śabdas tumulo 'bhavat

tataḥ śvetair hayair yukte mahati syandane sthitau
mādhavaḥ pāṇḍavaś caiva divyau śaṅkhau pradadhmatuḥ

pāñcajanyaṃ hṛṣīkeśo devadattaṃ dhanaṃjayaḥ
pauṇḍraṃ dadhmau mahāśaṅkhaṃ bhīmakarmā vṛkodaraḥ

anantavijayaṃ rājā kuntīputro yudhiṣṭhiraḥ
nakulaḥ sahadevaś ca sughoṣamaṇipuṣpakau

kāśyaś ca parameṣvāsaḥ śikhaṇḍī ca mahārathaḥ
dhṛṣṭadyumno virāṭaś ca sātyakiś cāparājitaḥ

drupado draupadeyāś ca sarvaśaḥ pṛthivīpate
saubhadraś ca mahābāhuḥ śaṅkhān dadhmuḥ pṛthak pṛthak

sa ghoṣo dhārtarāṣṭrāṇāṃ hṛdayāni vyadārayat
nabhaś ca pṛthivīṃ caiva tumulo vyanunādayan

atha vyavasthitān dṛṣṭvā dhārtarāṣṭrān kapidhvajaḥ
pravṛtte śastrasaṃpāte dhanur udyamya pāṇḍavaḥ

hṛṣīkeśaṃ tadā vākyam idam āha mahīpate
senayor ubhayor madhye rathaṃ sthāpaya me 'cyuta

yāvad etān nirīkṣe 'haṃ yoddhukāmān avasthitān
kair mayā saha yoddhavyam asmin raṇasamudyame

yotsyamānān avekṣe 'haṃ ya ete 'tra samāgatāḥ
dhārtarāṣṭrasya durbuddher yuddhe priyacikīrṣavaḥ

evam ukto hṛṣīkeśo guḍākeśena bhārata
senayor ubhayor madhye sthāpayitvā rathottamam

bhīṣmadroṇapramukhataḥ sarveṣāṃ ca mahīkṣitām
uvāca pārtha paśyaitān samavetān kurūn iti

tatrāpaśyat sthitān pārthaḥ pitṝn atha pitāmahān
ācāryān mātulān bhrātṝn putrān pautrān sakhīṃs tathā

śvaśurān suhṛdaś caiva senayor ubhayor api
tān samīkṣya sa kaunteyaḥ sarvān bandhūn avasthitān

kṛpayā parayāviṣṭo viṣīdann idam abravīt
dṛṣṭvemān svajanān kṛṣṇa yuyutsūn samavasthitān

sīdanti mama gātrāṇi mukhaṃ ca pariśuṣyati
vepathuś ca śarīre me romaharṣaś ca jāyate

gāṇḍīvaṃ sraṃsate hastāt tvak caiva paridahyate
na ca śaknomy avasthātuṃ bhramatīva ca me manaḥ

nimittāni ca paśyāmi viparītāni keśava
na ca śreyo 'nupaśyāmi hatvā svajanam āhave

na kāṅkṣe vijayaṃ kṛṣṇa na ca rājyaṃ sukhāni ca
kiṃ no rājyena govinda kiṃ bhogair jīvitena vā

yeṣām arthe kāṅkṣitaṃ no rājyaṃ bhogāḥ sukhāni ca
ta ime 'vasthitā yuddhe prāṇāṃs tyaktvā dhanāni ca

ācāryāḥ pitaraḥ putrās tathaiva ca pitāmahāḥ
mātulāḥ śvaśurāḥ pautrāḥ syālāḥ saṃbandhinas tathā

etān na hantum icchāmi ghnato 'pi madhusūdana
api trailokyarājyasya hetoḥ kiṃ nu mahīkṛte

nihatya dhārtarāṣṭrān naḥ kā prītiḥ syāj janārdana
pāpam evāśrayed asmān hatvaitān ātatāyinaḥ

tasmān nārhā vayaṃ hantuṃ dhārtarāṣṭrān sabāndhavān
svajanaṃ hi kathaṃ hatvā sukhinaḥ syāma mādhava

yady apy ete na paśyanti lobhopahatacetasaḥ
kulakṣayakṛtaṃ doṣaṃ mitradrohe ca pātakam

kathaṃ na jñeyam asmābhiḥ pāpād asmān nivartitum
kulakṣayakṛtaṃ doṣaṃ prapaśyadbhir janārdana

kulakṣaye praṇaśyanti kuladharmāḥ sanātanāḥ
dharme naṣṭe kulaṃ kṛtsnam adharmo 'bhibhavaty uta

adharmābhibhavāt kṛṣṇa praduṣyanti kulastriyaḥ
strīṣu duṣṭāsu vārṣṇeya jāyate varṇasaṃkaraḥ

saṃkaro narakāyaiva kulaghnānāṃ kulasya ca
patanti pitaro hy eṣāṃ luptapiṇḍodakakriyāḥ

doṣair etaiḥ kulaghnānāṃ varṇasaṃkarakārakaiḥ
utsādyante jātidharmāḥ kuladharmāś ca śāśvatāḥ

utsannakuladharmāṇāṃ manuṣyāṇāṃ janārdana
narake niyataṃ vāso bhavatīty anuśuśruma

aho bata mahat pāpaṃ kartuṃ vyavasitā vayam
yad rājyasukhalobhena hantuṃ svajanam udyatāḥ

yadi mām apratīkāram aśastraṃ śastrapāṇayaḥ
dhārtarāṣṭrā raṇe hanyus tan me kṣemataraṃ bhavet

evam uktvārjunaḥ saṃkhye rathopastha upāviśat
visṛjya saśaraṃ cāpaṃ śokasaṃvignamānasaḥ

saṃjaya uvāca
taṃ tathā kṛpayāviṣṭam aśrupūrṇākulekṣaṇam
viṣīdantam idaṃ vākyam uvāca madhusūdanaḥ

śrībhagavān uvāca
kutas tvā kaśmalam idaṃ viṣame samupasthitam
anāryajuṣṭam asvargyam akīrtikaram arjuna

klaibyaṃ mā sma gamaḥ pārtha naitat tvayy upapadyate
kṣudraṃ hṛdayadaurbalyaṃ tyaktvottiṣṭha paraṃtapa

arjuna uvāca
kathaṃ bhīṣmam ahaṃ saṃkhye droṇaṃ ca madhusūdana
iṣubhiḥ pratiyotsyāmi pūjārhāv arisūdana

gurūn ahatvā hi mahānubhāvāñ; śreyo bhoktuṃ bhaikṣam apīha loke
hatvārthakāmāṃs tu gurūn ihaiva; bhuñjīya bhogān rudhirapradigdhān

na caitad vidmaḥ kataran no garīyo; yad vā jayema yadi vā no jayeyuḥ
yān eva hatvā na jijīviṣāmas; te 'vasthitāḥ pramukhe dhārtarāṣṭrāḥ

kārpaṇyadoṣopahatasvabhāvaḥ; pṛcchāmi tvāṃ dharmasaṃmūḍhacetāḥ
yac chreyaḥ syān niścitaṃ brūhi tan me; śiṣyas te 'haṃ śādhi māṃ tvāṃ prapannam

na hi prapaśyāmi mamāpanudyād; yac chokam ucchoṣaṇam indriyāṇām
avāpya bhūmāv asapatnam ṛddhaṃ; rājyaṃ surāṇām api cādhipatyam

saṃjaya uvāca
evam uktvā hṛṣīkeśaṃ guḍākeśaḥ paraṃtapa
na yotsya iti govindam uktvā tūṣṇīṃ babhūva ha

tam uvāca hṛṣīkeśaḥ prahasann iva bhārata
senayor ubhayor madhye viṣīdantam idaṃ vacaḥ

śrībhagavān uvāca
aśocyān anvaśocas tvaṃ prajñāvādāṃś ca bhāṣase
gatāsūn agatāsūṃś ca nānuśocanti paṇḍitāḥ

na tv evāhaṃ jātu nāsaṃ na tvaṃ neme janādhipāḥ
na caiva na bhaviṣyāmaḥ sarve vayam ataḥ param

dehino 'smin yathā dehe kaumāraṃ yauvanaṃ jarā
tathā dehāntaraprāptir dhīras tatra na muhyati

mātrāsparśās tu kaunteya śītoṣṇasukhaduḥkhadāḥ
āgamāpāyino 'nityās tāṃs titikṣasva bhārata

yaṃ hi na vyathayanty ete puruṣaṃ puruṣarṣabha
samaduḥkhasukhaṃ dhīraṃ so 'mṛtatvāya kalpate

nāsato vidyate bhāvo nābhāvo vidyate sataḥ
ubhayor api dṛṣṭo 'ntas tv anayos tattvadarśibhiḥ

avināśi tu tad viddhi yena sarvam idaṃ tatam
vināśam avyayasyāsya na kaś cit kartum arhati

antavanta ime dehā nityasyoktāḥ śarīriṇaḥ
anāśino 'prameyasya tasmād yudhyasva bhārata

ya enaṃ vetti hantāraṃ yaś cainaṃ manyate hatam
ubhau tau na vijānīto nāyaṃ hanti na hanyate

na jāyate mriyate vā kadā cin; nāyaṃ bhūtvā bhavitā vā na bhūyaḥ
ajo nityaḥ śāśvato 'yaṃ purāṇo; na hanyate hanyamāne śarīre

vedāvināśinaṃ nityaṃ ya enam ajam avyayam
kathaṃ sa puruṣaḥ pārtha kaṃ ghātayati hanti kam

vāsāṃsi jīrṇāni yathā vihāya; navāni gṛhṇāti naro 'parāṇi
tathā śarīrāṇi vihāya jīrṇāny; anyāni saṃyāti navāni dehī

nainaṃ chindanti śastrāṇi nainaṃ dahati pāvakaḥ
na cainaṃ kledayanty āpo na śoṣayati mārutaḥ

acchedyo 'yam adāhyo 'yam akledyo 'śoṣya eva ca
nityaḥ sarvagataḥ sthāṇur acalo 'yaṃ sanātanaḥ

avyakto 'yam acintyo 'yam avikāryo 'yam ucyate
tasmād evaṃ viditvainaṃ nānuśocitum arhasi
atha cainaṃ nityajātaṃ nityaṃ vā manyase mṛtam
tathāpi tvaṃ mahābāho nainaṃ śocitum arhasi

jātasya hi dhruvo mṛtyur dhruvaṃ janma mṛtasya ca
tasmād aparihārye 'rthe na tvaṃ śocitum arhasi

avyaktādīni bhūtāni vyaktamadhyāni bhārata
avyaktanidhanāny eva tatra kā paridevanā

āścaryavat paśyati kaś cid enam; āścaryavad vadati tathaiva cānyaḥ
āścaryavac cainam anyaḥ śṛṇoti; śrutvāpy enaṃ veda na caiva kaś cit
dehī nityam avadhyo 'yaṃ dehe sarvasya bhārata
tasmāt sarvāṇi bhūtāni na tvaṃ śocitum arhasi

svadharmam api cāvekṣya na vikampitum arhasi
dharmyād dhi yuddhāc chreyo 'nyat kṣatriyasya na vidyate

yadṛcchayā copapannaṃ svargadvāram apāvṛtam
sukhinaḥ kṣatriyāḥ pārtha labhante yuddham īdṛśam

atha cet tvam imaṃ dharmyaṃ saṃgrāmaṃ na kariṣyasi
tataḥ svadharmaṃ kīrtiṃ ca hitvā pāpam avāpsyasi

akīrtiṃ cāpi bhūtāni kathayiṣyanti te 'vyayām
saṃbhāvitasya cākīrtir maraṇād atiricyate

bhayād raṇād uparataṃ maṃsyante tvāṃ mahārathāḥ
yeṣāṃ ca tvaṃ bahumato bhūtvā yāsyasi lāghavam

avācyavādāṃś ca bahūn vadiṣyanti tavāhitāḥ
nindantas tava sāmarthyaṃ tato duḥkhataraṃ nu kim

hato vā prāpsyasi svargaṃ jitvā vā bhokṣyase mahīm
tasmād uttiṣṭha kaunteya yuddhāya kṛtaniścayaḥ

sukhaduḥkhe same kṛtvā lābhālābhau jayājayau
tato yuddhāya yujyasva naivaṃ pāpam avāpsyasi

eṣā te 'bhihitā sāṃkhye buddhir yoge tv imāṃ śṛṇu
buddhyā yukto yayā pārtha karmabandhaṃ prahāsyasi

nehābhikramanāśo 'sti pratyavāyo na vidyate
svalpam apy asya dharmasya trāyate mahato bhayāt

vyavasāyātmikā buddhir ekeha kurunandana
bahuśākhā hy anantāś ca buddhayo 'vyavasāyinām

yām imāṃ puṣpitāṃ vācaṃ pravadanty avipaścitaḥ
vedavādaratāḥ pārtha nānyad astīti vādinaḥ

kāmātmānaḥ svargaparā janmakarmaphalapradām
kriyāviśeṣabahulāṃ bhogaiśvaryagatiṃ prati

bhogaiśvaryaprasaktānāṃ tayāpahṛtacetasām
vyavasāyātmikā buddhiḥ samādhau na vidhīyate

traiguṇyaviṣayā vedā nistraiguṇyo bhavārjuna
nirdvaṃdvo nityasattvastho niryogakṣema ātmavān

yāvān artha udapāne sarvataḥ saṃplutodake
tāvān sarveṣu vedeṣu brāhmaṇasya vijānataḥ

karmaṇy evādhikāras te mā phaleṣu kadā cana
mā karmaphalahetur bhūr mā te saṅgo 'stv akarmaṇi

yogasthaḥ kuru karmāṇi saṅgaṃ tyaktvā dhanaṃjaya
siddhyasiddhyoḥ samo bhūtvā samatvaṃ yoga ucyate

dūreṇa hy avaraṃ karma buddhiyogād dhanaṃjaya
buddhau śaraṇam anviccha kṛpaṇāḥ phalahetavaḥ

buddhiyukto jahātīha ubhe sukṛtaduṣkṛte
tasmād yogāya yujyasva yogaḥ karmasu kauśalam

karmajaṃ buddhiyuktā hi phalaṃ tyaktvā manīṣiṇaḥ
janmabandhavinirmuktāḥ padaṃ gacchanty anāmayam

yadā te mohakalilaṃ buddhir vyatitariṣyati
tadā gantāsi nirvedaṃ śrotavyasya śrutasya ca

śrutivipratipannā te yadā sthāsyati niścalā
samādhāv acalā buddhis tadā yogam avāpsyasi

arjuna uvāca
sthitaprajñasya kā bhāṣā samādhisthasya keśava
sthitadhīḥ kiṃ prabhāṣeta kim āsīta vrajeta kim

śrībhagavān uvāca
prajahāti yadā kāmān sarvān pārtha manogatān
ātmany evātmanā tuṣṭaḥ sthitaprajñas tadocyate

duḥkheṣv anudvignamanāḥ sukheṣu vigataspṛhaḥ
vītarāgabhayakrodhaḥ sthitadhīr munir ucyate

yaḥ sarvatrānabhisnehas tat tat prāpya śubhāśubham
nābhinandati na dveṣṭi tasya prajñā pratiṣṭhitā

yadā saṃharate cāyaṃ kūrmo 'ṅgānīva sarvaśaḥ
indriyāṇīndriyārthebhyas tasya prajñā pratiṣṭhitā

viṣayā vinivartante nirāhārasya dehinaḥ
rasavarjaṃ raso 'py asya paraṃ dṛṣṭvā nivartate

yatato hy api kaunteya puruṣasya vipaścitaḥ
indriyāṇi pramāthīni haranti prasabhaṃ manaḥ

tāni sarvāṇi saṃyamya yukta āsīta matparaḥ
vaśe hi yasyendriyāṇi tasya prajñā pratiṣṭhitā

dhyāyato viṣayān puṃsaḥ saṅgas teṣūpajāyate
saṅgāt saṃjāyate kāmaḥ kāmāt krodho 'bhijāyate

krodhād bhavati saṃmohaḥ saṃmohāt smṛtivibhramaḥ
smṛtibhraṃśād buddhināśo buddhināśāt praṇaśyati

rāgadveṣaviyuktais tu viṣayān indriyaiś caran
ātmavaśyair vidheyātmā prasādam adhigacchati

prasāde sarvaduḥkhānāṃ hānir asyopajāyate
prasannacetaso hy āśu buddhiḥ paryavatiṣṭhate

nāsti buddhir ayuktasya na cāyuktasya bhāvanā
na cābhāvayataḥ śāntir aśāntasya kutaḥ sukham

indriyāṇāṃ hi caratāṃ yan mano 'nuvidhīyate
tad asya harati prajñāṃ vāyur nāvam ivāmbhasi

tasmād yasya mahābāho nigṛhītāni sarvaśaḥ
indriyāṇīndriyārthebhyas tasya prajñā pratiṣṭhitā

yā niśā sarvabhūtānāṃ tasyāṃ jāgarti saṃyamī
yasyāṃ jāgrati bhūtāni sā niśā paśyato muneḥ

āpūryamāṇam acalapratiṣṭhaṃ; samudram āpaḥ praviśanti yadvat
tadvat kāmā yaṃ praviśanti sarve; sa śāntim āpnoti na kāmakāmī

vihāya kāmān yaḥ sarvān pumāṃś carati niḥspṛhaḥ
nirmamo nirahaṃkāraḥ sa śāntim adhigacchati

eṣā brāhmī sthitiḥ pārtha naināṃ prāpya vimuhyati
sthitvāsyām antakāle 'pi brahmanirvāṇam ṛcchati

arjuna uvāca
jyāyasī cet karmaṇas te matā buddhir janārdana
tat kiṃ karmaṇi ghore māṃ niyojayasi keśava

vyāmiśreṇaiva vākyena buddhiṃ mohayasīva me
tad ekaṃ vada niścitya yena śreyo 'ham āpnuyām

śrībhagavān uvāca
loke 'smin dvividhā niṣṭhā purā proktā mayānagha
jñānayogena sāṃkhyānāṃ karmayogena yoginām

na karmaṇām anārambhān naiṣkarmyaṃ puruṣo 'śnute
na ca saṃnyasanād eva siddhiṃ samadhigacchati

na hi kaś cit kṣaṇam api jātu tiṣṭhaty akarmakṛt
kāryate hy avaśaḥ karma sarvaḥ prakṛtijair guṇaiḥ

karmendriyāṇi saṃyamya ya āste manasā smaran
indriyārthān vimūḍhātmā mithyācāraḥ sa ucyate

yas tv indriyāṇi manasā niyamyārabhate 'rjuna
karmendriyaiḥ karmayogam asaktaḥ sa viśiṣyate

niyataṃ kuru karma tvaṃ karma jyāyo hy akarmaṇaḥ
śarīrayātrāpi ca te na prasidhyed akarmaṇaḥ

yajñārthāt karmaṇo 'nyatra loko 'yaṃ karmabandhanaḥ
tadarthaṃ karma kaunteya muktasaṅgaḥ samācara

sahayajñāḥ prajāḥ sṛṣṭvā purovāca prajāpatiḥ
anena prasaviṣyadhvam eṣa vo 'stv iṣṭakāmadhuk

devān bhāvayatānena te devā bhāvayantu vaḥ
parasparaṃ bhāvayantaḥ śreyaḥ param avāpsyatha

iṣṭān bhogān hi vo devā dāsyante yajñabhāvitāḥ
tair dattān apradāyaibhyo yo bhuṅkte stena eva saḥ

yajñaśiṣṭāśinaḥ santo mucyante sarvakilbiṣaiḥ
bhuñjate te tv aghaṃ pāpā ye pacanty ātmakāraṇāt

annād bhavanti bhūtāni parjanyād annasaṃbhavaḥ
yajñād bhavati parjanyo yajñaḥ karmasamudbhavaḥ

karma brahmodbhavaṃ viddhi brahmākṣarasamudbhavam
tasmāt sarvagataṃ brahma nityaṃ yajñe pratiṣṭhitam

evaṃ pravartitaṃ cakraṃ nānuvartayatīha yaḥ
aghāyur indriyārāmo moghaṃ pārtha sa jīvati

yas tv ātmaratir eva syād ātmatṛptaś ca mānavaḥ
ātmany eva ca saṃtuṣṭas tasya kāryaṃ na vidyate

naiva tasya kṛtenārtho nākṛteneha kaś cana
na cāsya sarvabhūteṣu kaś cid arthavyapāśrayaḥ

tasmād asaktaḥ satataṃ kāryaṃ karma samācara
asakto hy ācaran karma param āpnoti pūruṣaḥ

karmaṇaiva hi saṃsiddhim āsthitā janakādayaḥ
lokasaṃgraham evāpi saṃpaśyan kartum arhasi

yad yad ācarati śreṣṭhas tat tad evetaro janaḥ
sa yat pramāṇaṃ kurute lokas tad anuvartate

na me pārthāsti kartavyaṃ triṣu lokeṣu kiṃ cana
nānavāptam avāptavyaṃ varta eva ca karmaṇi

yadi hy ahaṃ na varteyaṃ jātu karmaṇy atandritaḥ
mama vartmānuvartante manuṣyāḥ pārtha sarvaśaḥ

utsīdeyur ime lokā na kuryāṃ karma ced aham
saṃkarasya ca kartā syām upahanyām imāḥ prajāḥ

saktāḥ karmaṇy avidvāṃso yathā kurvanti bhārata
kuryād vidvāṃs tathāsaktaś cikīrṣur lokasaṃgraham

na buddhibhedaṃ janayed ajñānāṃ karmasaṅginām
joṣayet sarvakarmāṇi vidvān yuktaḥ samācaran

prakṛteḥ kriyamāṇāni guṇaiḥ karmāṇi sarvaśaḥ
ahaṃkāravimūḍhātmā kartāham iti manyate

tattvavit tu mahābāho guṇakarmavibhāgayoḥ
guṇā guṇeṣu vartanta iti matvā na sajjate

prakṛter guṇasaṃmūḍhāḥ sajjante guṇakarmasu
tān akṛtsnavido mandān kṛtsnavin na vicālayet

mayi sarvāṇi karmāṇi saṃnyasyādhyātmacetasā
nirāśīr nirmamo bhūtvā yudhyasva vigatajvaraḥ

ye me matam idaṃ nityam anutiṣṭhanti mānavāḥ
śraddhāvanto 'nasūyanto mucyante te 'pi karmabhiḥ

ye tv etad abhyasūyanto nānutiṣṭhanti me matam
sarvajñānavimūḍhāṃs tān viddhi naṣṭān acetasaḥ

sadṛśaṃ ceṣṭate svasyāḥ prakṛter jñānavān api
prakṛtiṃ yānti bhūtāni nigrahaḥ kiṃ kariṣyati

indriyasyendriyasyārthe rāgadveṣau vyavasthitau
tayor na vaśam āgacchet tau hy asya paripanthinau

śreyān svadharmo viguṇaḥ paradharmāt svanuṣṭhitāt
svadharme nidhanaṃ śreyaḥ paradharmo bhayāvahaḥ

arjuna uvāca
atha kena prayukto 'yaṃ pāpaṃ carati pūruṣaḥ
anicchann api vārṣṇeya balād iva niyojitaḥ

śrībhagavān uvāca
kāma eṣa krodha eṣa rajoguṇasamudbhavaḥ
mahāśano mahāpāpmā viddhy enam iha vairiṇam

dhūmenāvriyate vahnir yathādarśo malena ca
yatholbenāvṛto garbhas tathā tenedam āvṛtam

āvṛtaṃ jñānam etena jñānino nityavairiṇā
kāmarūpeṇa kaunteya duṣpūreṇānalena ca

indriyāṇi mano buddhir asyādhiṣṭhānam ucyate
etair vimohayaty eṣa jñānam āvṛtya dehinam

tasmāt tvam indriyāṇy ādau niyamya bharatarṣabha
pāpmānaṃ prajahihy enaṃ jñānavijñānanāśanam

indriyāṇi parāṇy āhur indriyebhyaḥ paraṃ manaḥ
manasas tu parā buddhir yo buddheḥ paratas tu saḥ

evaṃ buddheḥ paraṃ buddhvā saṃstabhyātmānam ātmanā
jahi śatruṃ mahābāho kāmarūpaṃ durāsadam

śrībhagavān uvāca
imaṃ vivasvate yogaṃ proktavān aham avyayam
vivasvān manave prāha manur ikṣvākave 'bravīt

evaṃ paraṃparāprāptam imaṃ rājarṣayo viduḥ
sa kāleneha mahatā yogo naṣṭaḥ paraṃtapa

sa evāyaṃ mayā te 'dya yogaḥ proktaḥ purātanaḥ
bhakto 'si me sakhā ceti rahasyaṃ hy etad uttamam

arjuna uvāca
aparaṃ bhavato janma paraṃ janma vivasvataḥ
katham etad vijānīyāṃ tvam ādau proktavān iti

śrībhagavān uvāca
bahūni me vyatītāni janmāni tava cārjuna
tāny ahaṃ veda sarvāṇi na tvaṃ vettha paraṃtapa

ajo 'pi sann avyayātmā bhūtānām īśvaro 'pi san
prakṛtiṃ svām adhiṣṭhāya saṃbhavāmy ātmamāyayā

yadā yadā hi dharmasya glānir bhavati bhārata
abhyutthānam adharmasya tadātmānaṃ sṛjāmy aham

paritrāṇāya sādhūnāṃ vināśāya ca duṣkṛtām
dharmasaṃsthāpanārthāya saṃbhavāmi yuge yuge

janma karma ca me divyam evaṃ yo vetti tattvataḥ
tyaktvā dehaṃ punarjanma naiti mām eti so 'rjuna

vītarāgabhayakrodhā manmayā mām upāśritāḥ
bahavo jñānatapasā pūtā madbhāvam āgatāḥ

ye yathā māṃ prapadyante tāṃs tathaiva bhajāmy aham
mama vartmānuvartante manuṣyāḥ pārtha sarvaśaḥ

kāṅkṣantaḥ karmaṇāṃ siddhiṃ yajanta iha devatāḥ
kṣipraṃ hi mānuṣe loke siddhir bhavati karmajā

cāturvarṇyaṃ mayā sṛṣṭaṃ guṇakarmavibhāgaśaḥ
tasya kartāram api māṃ viddhy akartāram avyayam

na māṃ karmāṇi limpanti na me karmaphale spṛhā
iti māṃ yo 'bhijānāti karmabhir na sa badhyate

evaṃ jñātvā kṛtaṃ karma pūrvair api mumukṣubhiḥ
kuru karmaiva tasmāt tvaṃ pūrvaiḥ pūrvataraṃ kṛtam

kiṃ karma kim akarmeti kavayo 'py atra mohitāḥ
tat te karma pravakṣyāmi yaj jñātvā mokṣyase 'śubhāt

karmaṇo hy api boddhavyaṃ boddhavyaṃ ca vikarmaṇaḥ
akarmaṇaś ca boddhavyaṃ gahanā karmaṇo gatiḥ

karmaṇy akarma yaḥ paśyed akarmaṇi ca karma yaḥ
sa buddhimān manuṣyeṣu sa yuktaḥ kṛtsnakarmakṛt

yasya sarve samārambhāḥ kāmasaṃkalpavarjitāḥ
jñānāgnidagdhakarmāṇaṃ tam āhuḥ paṇḍitaṃ budhāḥ

tyaktvā karmaphalāsaṅgaṃ nityatṛpto nirāśrayaḥ
karmaṇy abhipravṛtto 'pi naiva kiṃ cit karoti saḥ

nirāśīr yatacittātmā tyaktasarvaparigrahaḥ
śārīraṃ kevalaṃ karma kurvan nāpnoti kilbiṣam

yadṛcchālābhasaṃtuṣṭo dvaṃdvātīto vimatsaraḥ
samaḥ siddhāv asiddhau ca kṛtvāpi na nibadhyate

gatasaṅgasya muktasya jñānāvasthitacetasaḥ
yajñāyācarataḥ karma samagraṃ pravilīyate

brahmārpaṇaṃ brahmahavir brahmāgnau brahmaṇā hutam
brahmaiva tena gantavyaṃ brahmakarmasamādhinā

daivam evāpare yajñaṃ yoginaḥ paryupāsate
brahmāgnāv apare yajñaṃ yajñenaivopajuhvati

śrotrādīnīndriyāṇy anye saṃyamāgniṣu juhvati
śabdādīn viṣayān anya indriyāgniṣu juhvati

sarvāṇīndriyakarmāṇi prāṇakarmāṇi cāpare
ātmasaṃyamayogāgnau juhvati jñānadīpite

dravyayajñās tapoyajñā yogayajñās tathāpare
svādhyāyajñānayajñāś ca yatayaḥ saṃśitavratāḥ

apāne juhvati prāṇaṃ prāṇe 'pānaṃ tathāpare
prāṇāpānagatī ruddhvā prāṇāyāmaparāyaṇāḥ

apare niyatāhārāḥ prāṇān prāṇeṣu juhvati
sarve 'py ete yajñavido yajñakṣapitakalmaṣāḥ

yajñaśiṣṭāmṛtabhujo yānti brahma sanātanam
nāyaṃ loko 'sty ayajñasya kuto 'nyaḥ kurusattama

evaṃ bahuvidhā yajñā vitatā brahmaṇo mukhe
karmajān viddhi tān sarvān evaṃ jñātvā vimokṣyase

śreyān dravyamayād yajñāj jñānayajñaḥ paraṃtapa
sarvaṃ karmākhilaṃ pārtha jñāne parisamāpyate

tad viddhi praṇipātena paripraśnena sevayā
upadekṣyanti te jñānaṃ jñāninas tattvadarśinaḥ

yaj jñātvā na punar moham evaṃ yāsyasi pāṇḍava
yena bhūtāny aśeṣeṇa drakṣyasy ātmany atho mayi

api ced asi pāpebhyaḥ sarvebhyaḥ pāpakṛttamaḥ
sarvaṃ jñānaplavenaiva vṛjinaṃ saṃtariṣyasi

yathaidhāṃsi samiddho 'gnir bhasmasāt kurute 'rjuna
jñānāgniḥ sarvakarmāṇi bhasmasāt kurute tathā

na hi jñānena sadṛśaṃ pavitram iha vidyate
tat svayaṃ yogasaṃsiddhaḥ kālenātmani vindati

śraddhāvāṃl labhate jñānaṃ tatparaḥ saṃyatendriyaḥ
jñānaṃ labdhvā parāṃ śāntim acireṇādhigacchati

ajñaś cāśraddadhānaś ca saṃśayātmā vinaśyati
nāyaṃ loko 'sti na paro na sukhaṃ saṃśayātmanaḥ

yogasaṃnyastakarmāṇaṃ jñānasaṃchinnasaṃśayam
ātmavantaṃ na karmāṇi nibadhnanti dhanaṃjaya

tasmād ajñānasaṃbhūtaṃ hṛtsthaṃ jñānāsinātmanaḥ
chittvainaṃ saṃśayaṃ yogam ātiṣṭhottiṣṭha bhārata

arjuna uvāca
saṃnyāsaṃ karmaṇāṃ kṛṣṇa punar yogaṃ ca śaṃsasi
yac chreya etayor ekaṃ tan me brūhi suniścitam

śrībhagavān uvāca
saṃnyāsaḥ karmayogaś ca niḥśreyasakarāv ubhau
tayos tu karmasaṃnyāsāt karmayogo viśiṣyate

jñeyaḥ sa nityasaṃnyāsī yo na dveṣṭi na kāṅkṣati
nirdvaṃdvo hi mahābāho sukhaṃ bandhāt pramucyate

sāṃkhyayogau pṛthag bālāḥ pravadanti na paṇḍitāḥ
ekam apy āsthitaḥ samyag ubhayor vindate phalam

yat sāṃkhyaiḥ prāpyate sthānaṃ tad yogair api gamyate
ekaṃ sāṃkhyaṃ ca yogaṃ ca yaḥ paśyati sa paśyati

saṃnyāsas tu mahābāho duḥkham āptum ayogataḥ
yogayukto munir brahma nacireṇādhigacchati

yogayukto viśuddhātmā vijitātmā jitendriyaḥ
sarvabhūtātmabhūtātmā kurvann api na lipyate

naiva kiṃ cit karomīti yukto manyeta tattvavit
paśyañ śṛṇvan spṛśañ jighrann aśnan gacchan svapañ śvasan

pralapan visṛjan gṛhṇann unmiṣan nimiṣann api
indriyāṇīndriyārtheṣu vartanta iti dhārayan

brahmaṇy ādhāya karmāṇi saṅgaṃ tyaktvā karoti yaḥ
lipyate na sa pāpena padmapatram ivāmbhasā

kāyena manasā buddhyā kevalair indriyair api
yoginaḥ karma kurvanti saṅgaṃ tyaktvātmaśuddhaye

yuktaḥ karmaphalaṃ tyaktvā śāntim āpnoti naiṣṭhikīm
ayuktaḥ kāmakāreṇa phale sakto nibadhyate

sarvakarmāṇi manasā saṃnyasyāste sukhaṃ vaśī
navadvāre pure dehī naiva kurvan na kārayan

na kartṛtvaṃ na karmāṇi lokasya sṛjati prabhuḥ
na karmaphalasaṃyogaṃ svabhāvas tu pravartate

nādatte kasya cit pāpaṃ na caiva sukṛtaṃ vibhuḥ
ajñānenāvṛtaṃ jñānaṃ tena muhyanti jantavaḥ

jñānena tu tad ajñānaṃ yeṣāṃ nāśitam ātmanaḥ
teṣām ādityavaj jñānaṃ prakāśayati tatparam

tadbuddhayas tadātmānas tanniṣṭhās tatparāyaṇāḥ
gacchanty apunarāvṛttiṃ jñānanirdhūtakalmaṣāḥ

vidyāvinayasaṃpanne brāhmaṇe gavi hastini
śuni caiva śvapāke ca paṇḍitāḥ samadarśinaḥ

ihaiva tair jitaḥ sargo yeṣāṃ sāmye sthitaṃ manaḥ
nirdoṣaṃ hi samaṃ brahma tasmād brahmaṇi te sthitāḥ

na prahṛṣyet priyaṃ prāpya nodvijet prāpya cāpriyam
sthirabuddhir asaṃmūḍho brahmavid brahmaṇi sthitaḥ

bāhyasparśeṣv asaktātmā vindaty ātmani yat sukham
sa brahmayogayuktātmā sukham akṣayam aśnute

ye hi saṃsparśajā bhogā duḥkhayonaya eva te
ādyantavantaḥ kaunteya na teṣu ramate budhaḥ

śaknotīhaiva yaḥ soḍhuṃ prāk śarīravimokṣaṇāt
kāmakrodhodbhavaṃ vegaṃ sa yuktaḥ sa sukhī naraḥ

yo 'ntaḥsukho 'ntarārāmas tathāntarjyotir eva yaḥ
sa yogī brahmanirvāṇaṃ brahmabhūto 'dhigacchati

labhante brahmanirvāṇam ṛṣayaḥ kṣīṇakalmaṣāḥ
chinnadvaidhā yatātmānaḥ sarvabhūtahite ratāḥ

kāmakrodhaviyuktānāṃ yatīnāṃ yatacetasām
abhito brahmanirvāṇaṃ vartate viditātmanām

sparśān kṛtvā bahir bāhyāṃś cakṣuś caivāntare bhruvoḥ
prāṇāpānau samau kṛtvā nāsābhyantaracāriṇau

yatendriyamanobuddhir munir mokṣaparāyaṇaḥ
vigatecchābhayakrodho yaḥ sadā mukta eva saḥ

bhoktāraṃ yajñatapasāṃ sarvalokamaheśvaram
suhṛdaṃ sarvabhūtānāṃ jñātvā māṃ śāntim ṛcchati

śrībhagavān uvāca
anāśritaḥ karmaphalaṃ kāryaṃ karma karoti yaḥ
sa saṃnyāsī ca yogī ca na niragnir na cākriyaḥ

yaṃ saṃnyāsam iti prāhur yogaṃ taṃ viddhi pāṇḍava
na hy asaṃnyastasaṃkalpo yogī bhavati kaś cana

ārurukṣor muner yogaṃ karma kāraṇam ucyate
yogārūḍhasya tasyaiva śamaḥ kāraṇam ucyate

yadā hi nendriyārtheṣu na karmasv anuṣajjate
sarvasaṃkalpasaṃnyāsī yogārūḍhas tadocyate

uddhared ātmanātmānaṃ nātmānam avasādayet
ātmaiva hy ātmano bandhur ātmaiva ripur ātmanaḥ

bandhur ātmātmanas tasya yenātmaivātmanā jitaḥ
anātmanas tu śatrutve vartetātmaiva śatruvat

jitātmanaḥ praśāntasya paramātmā samāhitaḥ
śītoṣṇasukhaduḥkheṣu tathā mānāvamānayoḥ

jñānavijñānatṛptātmā kūṭastho vijitendriyaḥ
yukta ity ucyate yogī samaloṣṭāśmakāñcanaḥ

suhṛnmitrāryudāsīnamadhyasthadveṣyabandhuṣu
sādhuṣv api ca pāpeṣu samabuddhir viśiṣyate

yogī yuñjīta satatam ātmānaṃ rahasi sthitaḥ
ekākī yatacittātmā nirāśīr aparigrahaḥ

śucau deśe pratiṣṭhāpya sthiram āsanam ātmanaḥ
nātyucchritaṃ nātinīcaṃ cailājinakuśottaram

tatraikāgraṃ manaḥ kṛtvā yatacittendriyakriyaḥ
upaviśyāsane yuñjyād yogam ātmaviśuddhaye

samaṃ kāyaśirogrīvaṃ dhārayann acalaṃ sthiraḥ
saṃprekṣya nāsikāgraṃ svaṃ diśaś cānavalokayan

praśāntātmā vigatabhīr brahmacārivrate sthitaḥ
manaḥ saṃyamya maccitto yukta āsīta matparaḥ

yuñjann evaṃ sadātmānaṃ yogī niyatamānasaḥ
śāntiṃ nirvāṇaparamāṃ matsaṃsthām adhigacchati

nātyaśnatas tu yogo 'sti na caikāntam anaśnataḥ
na cātisvapnaśīlasya jāgrato naiva cārjuna

yuktāhāravihārasya yuktaceṣṭasya karmasu
yuktasvapnāvabodhasya yogo bhavati duḥkhahā

yadā viniyataṃ cittam ātmany evāvatiṣṭhate
niḥspṛhaḥ sarvakāmebhyo yukta ity ucyate tadā

yathā dīpo nivātastho neṅgate sopamā smṛtā
yogino yatacittasya yuñjato yogam ātmanaḥ

yatroparamate cittaṃ niruddhaṃ yogasevayā
yatra caivātmanātmānaṃ paśyann ātmani tuṣyati

sukham ātyantikaṃ yat tad buddhigrāhyam atīndriyam
vetti yatra na caivāyaṃ sthitaś calati tattvataḥ

yaṃ labdhvā cāparaṃ lābhaṃ manyate nādhikaṃ tataḥ
yasmin sthito na duḥkhena guruṇāpi vicālyate

taṃ vidyād duḥkhasaṃyogaviyogaṃ yogasaṃjñitam
sa niścayena yoktavyo yogo 'nirviṇṇacetasā

saṃkalpaprabhavān kāmāṃs tyaktvā sarvān aśeṣataḥ
manasaivendriyagrāmaṃ viniyamya samantataḥ

śanaiḥ śanair uparamed buddhyā dhṛtigṛhītayā
ātmasaṃsthaṃ manaḥ kṛtvā na kiṃ cid api cintayet

yato yato niścarati manaś cañcalam asthiram
tatas tato niyamyaitad ātmany eva vaśaṃ nayet

praśāntamanasaṃ hy enaṃ yoginaṃ sukham uttamam
upaiti śāntarajasaṃ brahmabhūtam akalmaṣam

yuñjann evaṃ sadātmānaṃ yogī vigatakalmaṣaḥ
sukhena brahmasaṃsparśam atyantaṃ sukham aśnute

sarvabhūtastham ātmānaṃ sarvabhūtāni cātmani
īkṣate yogayuktātmā sarvatra samadarśanaḥ

yo māṃ paśyati sarvatra sarvaṃ ca mayi paśyati
tasyāhaṃ na praṇaśyāmi sa ca me na praṇaśyati

sarvabhūtasthitaṃ yo māṃ bhajaty ekatvam āsthitaḥ
sarvathā vartamāno 'pi sa yogī mayi vartate

ātmaupamyena sarvatra samaṃ paśyati yo 'rjuna
sukhaṃ vā yadi vā duḥkhaṃ sa yogī paramo mataḥ

arjuna uvāca
yo 'yaṃ yogas tvayā proktaḥ sāmyena madhusūdana
etasyāhaṃ na paśyāmi cañcalatvāt sthitiṃ sthirām

cañcalaṃ hi manaḥ kṛṣṇa pramāthi balavad dṛḍham
tasyāhaṃ nigrahaṃ manye vāyor iva suduṣkaram

śrībhagavān uvāca
asaṃśayaṃ mahābāho mano durnigrahaṃ calam
abhyāsena tu kaunteya vairāgyeṇa ca gṛhyate

asaṃyatātmanā yogo duṣprāpa iti me matiḥ
vaśyātmanā tu yatatā śakyo 'vāptum upāyataḥ

arjuna uvāca
ayatiḥ śraddhayopeto yogāc calitamānasaḥ
aprāpya yogasaṃsiddhiṃ kāṃ gatiṃ kṛṣṇa gacchati

kaccin nobhayavibhraṣṭaś chinnābhram iva naśyati
apratiṣṭho mahābāho vimūḍho brahmaṇaḥ pathi

etan me saṃśayaṃ kṛṣṇa chettum arhasy aśeṣataḥ
tvad anyaḥ saṃśayasyāsya chettā na hy upapadyate

śrībhagavān uvāca
pārtha naiveha nāmutra vināśas tasya vidyate
na hi kalyāṇakṛt kaś cid durgatiṃ tāta gacchati

prāpya puṇyakṛtāṃl lokān uṣitvā śāśvatīḥ samāḥ
śucīnāṃ śrīmatāṃ gehe yogabhraṣṭo 'bhijāyate

atha vā yoginām eva kule bhavati dhīmatām
etad dhi durlabhataraṃ loke janma yad īdṛśam

tatra taṃ buddhisaṃyogaṃ labhate paurvadehikam
yatate ca tato bhūyaḥ saṃsiddhau kurunandana

pūrvābhyāsena tenaiva hriyate hy avaśo 'pi saḥ
jijñāsur api yogasya śabdabrahmātivartate

prayatnād yatamānas tu yogī saṃśuddhakilbiṣaḥ
anekajanmasaṃsiddhas tato yāti parāṃ gatim

tapasvibhyo 'dhiko yogī jñānibhyo 'pi mato 'dhikaḥ
karmibhyaś cādhiko yogī tasmād yogī bhavārjuna

yoginām api sarveṣāṃ madgatenāntarātmanā
śraddhāvān bhajate yo māṃ sa me yuktatamo mataḥ

śrībhagavān uvāca
mayy āsaktamanāḥ pārtha yogaṃ yuñjan madāśrayaḥ
asaṃśayaṃ samagraṃ māṃ yathā jñāsyasi tac chṛṇu

jñānaṃ te 'haṃ savijñānam idaṃ vakṣyāmy aśeṣataḥ
yaj jñātvā neha bhūyo 'nyaj jñātavyam avaśiṣyate

manuṣyāṇāṃ sahasreṣu kaś cid yatati siddhaye
yatatām api siddhānāṃ kaś cin māṃ vetti tattvataḥ

bhūmir āpo 'nalo vāyuḥ khaṃ mano buddhir eva ca
ahaṃkāra itīyaṃ me bhinnā prakṛtir aṣṭadhā

apareyam itas tv anyāṃ prakṛtiṃ viddhi me parām
jīvabhūtāṃ mahābāho yayedaṃ dhāryate jagat

etadyonīni bhūtāni sarvāṇīty upadhāraya
ahaṃ kṛtsnasya jagataḥ prabhavaḥ pralayas tathā

mattaḥ parataraṃ nānyat kiṃ cid asti dhanaṃjaya
mayi sarvam idaṃ protaṃ sūtre maṇigaṇā iva

raso 'ham apsu kaunteya prabhāsmi śaśisūryayoḥ
praṇavaḥ sarvavedeṣu śabdaḥ khe pauruṣaṃ nṛṣu

puṇyo gandhaḥ pṛthivyāṃ ca tejaś cāsmi vibhāvasau
jīvanaṃ sarvabhūteṣu tapaś cāsmi tapasviṣu

bījaṃ māṃ sarvabhūtānāṃ viddhi pārtha sanātanam
buddhir buddhimatām asmi tejas tejasvinām aham

balaṃ balavatāṃ cāhaṃ kāmarāgavivarjitam
dharmāviruddho bhūteṣu kāmo 'smi bharatarṣabha

ye caiva sāttvikā bhāvā rājasās tāmasāś ca ye
matta eveti tān viddhi na tv ahaṃ teṣu te mayi

tribhir guṇamayair bhāvair ebhiḥ sarvam idaṃ jagat
mohitaṃ nābhijānāti mām ebhyaḥ param avyayam

daivī hy eṣā guṇamayī mama māyā duratyayā
mām eva ye prapadyante māyām etāṃ taranti te

na māṃ duṣkṛtino mūḍhāḥ prapadyante narādhamāḥ
māyayāpahṛtajñānā āsuraṃ bhāvam āśritāḥ

caturvidhā bhajante māṃ janāḥ sukṛtino 'rjuna
ārto jijñāsur arthārthī jñānī ca bharatarṣabha

teṣāṃ jñānī nityayukta ekabhaktir viśiṣyate
priyo hi jñānino 'tyartham ahaṃ sa ca mama priyaḥ

udārāḥ sarva evaite jñānī tv ātmaiva me matam
āsthitaḥ sa hi yuktātmā mām evānuttamāṃ gatim

bahūnāṃ janmanām ante jñānavān māṃ prapadyate
vāsudevaḥ sarvam iti sa mahātmā sudurlabhaḥ
kāmais tais tair hṛtajñānāḥ prapadyante 'nyadevatāḥ
taṃ taṃ niyamam āsthāya prakṛtyā niyatāḥ svayā

yo yo yāṃ yāṃ tanuṃ bhaktaḥ śraddhayārcitum icchati
tasya tasyācalāṃ śraddhāṃ tām eva vidadhāmy aham

sa tayā śraddhayā yuktas tasyā rādhanam īhate
labhate ca tataḥ kāmān mayaiva vihitān hi tān

antavat tu phalaṃ teṣāṃ tad bhavaty alpamedhasām
devān devayajo yānti madbhaktā yānti mām api

avyaktaṃ vyaktim āpannaṃ manyante mām abuddhayaḥ
paraṃ bhāvam ajānanto mamāvyayam anuttamam

nāhaṃ prakāśaḥ sarvasya yogamāyāsamāvṛtaḥ
mūḍho 'yaṃ nābhijānāti loko mām ajam avyayam

vedāhaṃ samatītāni vartamānāni cārjuna
bhaviṣyāṇi ca bhūtāni māṃ tu veda na kaś cana

icchādveṣasamutthena dvaṃdvamohena bhārata
sarvabhūtāni saṃmohaṃ sarge yānti paraṃtapa

yeṣāṃ tv antagataṃ pāpaṃ janānāṃ puṇyakarmaṇām
te dvaṃdvamohanirmuktā bhajante māṃ dṛḍhavratāḥ

jarāmaraṇamokṣāya mām āśritya yatanti ye
te brahma tad viduḥ kṛtsnam adhyātmaṃ karma cākhilam

sādhibhūtādhidaivaṃ māṃ sādhiyajñaṃ ca ye viduḥ
prayāṇakāle 'pi ca māṃ te vidur yuktacetasaḥ

arjuna uvāca
kiṃ tad brahma kim adhyātmaṃ kiṃ karma puruṣottama
adhibhūtaṃ ca kiṃ proktam adhidaivaṃ kim ucyate

adhiyajñaḥ kathaṃ ko 'tra dehe 'smin madhusūdana
prayāṇakāle ca kathaṃ jñeyo 'si niyatātmabhiḥ

śrībhagavān uvāca
akṣaraṃ brahma paramaṃ svabhāvo 'dhyātmam ucyate
bhūtabhāvodbhavakaro visargaḥ karmasaṃjñitaḥ

adhibhūtaṃ kṣaro bhāvaḥ puruṣaś cādhidaivatam
adhiyajño 'ham evātra dehe dehabhṛtāṃ vara

antakāle ca mām eva smaran muktvā kalevaram
yaḥ prayāti sa madbhāvaṃ yāti nāsty atra saṃśayaḥ

yaṃ yaṃ vāpi smaran bhāvaṃ tyajaty ante kalevaram
taṃ tam evaiti kaunteya sadā tadbhāvabhāvitaḥ

tasmāt sarveṣu kāleṣu mām anusmara yudhya ca
mayy arpitamanobuddhir mām evaiṣyasy asaṃśayaḥ

abhyāsayogayuktena cetasā nānyagāminā
paramaṃ puruṣaṃ divyaṃ yāti pārthānucintayan

kaviṃ purāṇam anuśāsitāram; aṇor aṇīyāṃsam anusmared yaḥ
sarvasya dhātāram acintyarūpam; ādityavarṇaṃ tamasaḥ parastāt

prayāṇakāle manasācalena; bhaktyā yukto yogabalena caiva
bhruvor madhye prāṇam āveśya samyak; sa taṃ paraṃ puruṣam upaiti divyam

yad akṣaraṃ vedavido vadanti; viśanti yad yatayo vītarāgāḥ
yad icchanto brahmacaryaṃ caranti; tat te padaṃ saṃgraheṇa pravakṣye

sarvadvārāṇi saṃyamya mano hṛdi nirudhya ca
mūrdhny ādhāyātmanaḥ prāṇam āsthito yogadhāraṇām

om ity ekākṣaraṃ brahma vyāharan mām anusmaran
yaḥ prayāti tyajan dehaṃ sa yāti paramāṃ gatim

ananyacetāḥ satataṃ yo māṃ smarati nityaśaḥ
tasyāhaṃ sulabhaḥ pārtha nityayuktasya yoginaḥ

mām upetya punarjanma duḥkhālayam aśāśvatam
nāpnuvanti mahātmānaḥ saṃsiddhiṃ paramāṃ gatāḥ

ā brahmabhuvanāl lokāḥ punarāvartino 'rjuna
mām upetya tu kaunteya punarjanma na vidyate

sahasrayugaparyantam ahar yad brahmaṇo viduḥ
rātriṃ yugasahasrāntāṃ te 'horātravido janāḥ

avyaktād vyaktayaḥ sarvāḥ prabhavanty aharāgame
rātryāgame pralīyante tatraivāvyaktasaṃjñake

bhūtagrāmaḥ sa evāyaṃ bhūtvā bhūtvā pralīyate
rātryāgame 'vaśaḥ pārtha prabhavaty aharāgame

paras tasmāt tu bhāvo 'nyo 'vyakto 'vyaktāt sanātanaḥ
yaḥ sa sarveṣu bhūteṣu naśyatsu na vinaśyati

avyakto 'kṣara ity uktas tam āhuḥ paramāṃ gatim
yaṃ prāpya na nivartante tad dhāma paramaṃ mama

puruṣaḥ sa paraḥ pārtha bhaktyā labhyas tv ananyayā
yasyāntaḥsthāni bhūtāni yena sarvam idaṃ tatam

yatra kāle tv anāvṛttim āvṛttiṃ caiva yoginaḥ
prayātā yānti taṃ kālaṃ vakṣyāmi bharatarṣabha

agnir jyotir ahaḥ śuklaḥ ṣaṇmāsā uttarāyaṇam
tatra prayātā gacchanti brahma brahmavido janāḥ

dhūmo rātris tathā kṛṣṇaḥ ṣaṇmāsā dakṣiṇāyanam
tatra cāndramasaṃ jyotir yogī prāpya nivartate

śuklakṛṣṇe gatī hy ete jagataḥ śāśvate mate
ekayā yāty anāvṛttim anyayāvartate punaḥ

naite sṛtī pārtha jānan yogī muhyati kaś cana
tasmāt sarveṣu kāleṣu yogayukto bhavārjuna

vedeṣu yajñeṣu tapaḥsu caiva; dāneṣu yat puṇyaphalaṃ pradiṣṭam
atyeti tat sarvam idaṃ viditvā; yogī paraṃ sthānam upaiti cādyam

śrībhagavān uvāca
idaṃ tu te guhyatamaṃ pravakṣyāmy anasūyave
jñānaṃ vijñānasahitaṃ yaj jñātvā mokṣyase 'śubhāt

rājavidyā rājaguhyaṃ pavitram idam uttamam
pratyakṣāvagamaṃ dharmyaṃ susukhaṃ kartum avyayam

aśraddadhānāḥ puruṣā dharmasyāsya paraṃtapa
aprāpya māṃ nivartante mṛtyusaṃsāravartmani

mayā tatam idaṃ sarvaṃ jagad avyaktamūrtinā
matsthāni sarvabhūtāni na cāhaṃ teṣv avasthitaḥ

na ca matsthāni bhūtāni paśya me yogam aiśvaram
bhūtabhṛn na ca bhūtastho mamātmā bhūtabhāvanaḥ

yathākāśasthito nityaṃ vāyuḥ sarvatrago mahān
tathā sarvāṇi bhūtāni matsthānīty upadhāraya

sarvabhūtāni kaunteya prakṛtiṃ yānti māmikām
kalpakṣaye punas tāni kalpādau visṛjāmy aham

prakṛtiṃ svām avaṣṭabhya visṛjāmi punaḥ punaḥ
bhūtagrāmam imaṃ kṛtsnam avaśaṃ prakṛter vaśāt

na ca māṃ tāni karmāṇi nibadhnanti dhanaṃjaya
udāsīnavad āsīnam asaktaṃ teṣu karmasu

mayādhyakṣeṇa prakṛtiḥ sūyate sacarācaram
hetunānena kaunteya jagad viparivartate

avajānanti māṃ mūḍhā mānuṣīṃ tanum āśritam
paraṃ bhāvam ajānanto mama bhūtamaheśvaram

moghāśā moghakarmāṇo moghajñānā vicetasaḥ
rākṣasīm āsurīṃ caiva prakṛtiṃ mohinīṃ śritāḥ

mahātmānas tu māṃ pārtha daivīṃ prakṛtim āśritāḥ
bhajanty ananyamanaso jñātvā bhūtādim avyayam

satataṃ kīrtayanto māṃ yatantaś ca dṛḍhavratāḥ
namasyantaś ca māṃ bhaktyā nityayuktā upāsate

jñānayajñena cāpy anye yajanto mām upāsate
ekatvena pṛthaktvena bahudhā viśvatomukham

ahaṃ kratur ahaṃ yajñaḥ svadhāham aham auṣadham
mantro 'ham aham evājyam aham agnir ahaṃ hutam

pitāham asya jagato mātā dhātā pitāmahaḥ
vedyaṃ pavitram oṃkāra ṛk sāma yajur eva ca

gatir bhartā prabhuḥ sākṣī nivāsaḥ śaraṇaṃ suhṛt
prabhavaḥ pralayaḥ sthānaṃ nidhānaṃ bījam avyayam

tapāmy aham ahaṃ varṣaṃ nigṛhṇāmy utsṛjāmi ca
amṛtaṃ caiva mṛtyuś ca sad asac cāham arjuna

traividyā māṃ somapāḥ pūtapāpā; yajñair iṣṭvā svargatiṃ prārthayante
te puṇyam āsādya surendralokam; aśnanti divyān divi devabhogān

te taṃ bhuktvā svargalokaṃ viśālaṃ; kṣīṇe puṇye martyalokaṃ viśanti
evaṃ trayīdharmam anuprapannā; gatāgataṃ kāmakāmā labhante

ananyāś cintayanto māṃ ye janāḥ paryupāsate
teṣāṃ nityābhiyuktānāṃ yogakṣemaṃ vahāmy aham

ye 'py anyadevatā bhaktā yajante śraddhayānvitāḥ
te 'pi mām eva kaunteya yajanty avidhipūrvakam

ahaṃ hi sarvayajñānāṃ bhoktā ca prabhur eva ca
na tu mām abhijānanti tattvenātaś cyavanti te

yānti devavratā devān pitṝn yānti pitṛvratāḥ
bhūtāni yānti bhūtejyā yānti madyājino 'pi mām

patraṃ puṣpaṃ phalaṃ toyaṃ yo me bhaktyā prayacchati
tad ahaṃ bhaktyupahṛtam aśnāmi prayatātmanaḥ

yat karoṣi yad aśnāsi yaj juhoṣi dadāsi yat
yat tapasyasi kaunteya tat kuruṣva madarpaṇam

śubhāśubhaphalair evaṃ mokṣyase karmabandhanaiḥ
saṃnyāsayogayuktātmā vimukto mām upaiṣyasi

samo 'haṃ sarvabhūteṣu na me dveṣyo 'sti na priyaḥ
ye bhajanti tu māṃ bhaktyā mayi te teṣu cāpy aham

api cet sudurācāro bhajate mām ananyabhāk
sādhur eva sa mantavyaḥ samyag vyavasito hi saḥ

kṣipraṃ bhavati dharmātmā śaśvacchāntiṃ nigacchati
kaunteya pratijānīhi na me bhaktaḥ praṇaśyati

māṃ hi pārtha vyapāśritya ye 'pi syuḥ pāpayonayaḥ
striyo vaiśyās tathā śūdrās te 'pi yānti parāṃ gatim

kiṃ punar brāhmaṇāḥ puṇyā bhaktā rājarṣayas tathā
anityam asukhaṃ lokam imaṃ prāpya bhajasva mām

manmanā bhava madbhakto madyājī māṃ namaskuru
mām evaiṣyasi yuktvaivam ātmānaṃ matparāyaṇaḥ

śrībhagavān uvāca
bhūya eva mahābāho śṛṇu me paramaṃ vacaḥ
yat te 'haṃ prīyamāṇāya vakṣyāmi hitakāmyayā

na me viduḥ suragaṇāḥ prabhavaṃ na maharṣayaḥ
aham ādir hi devānāṃ maharṣīṇāṃ ca sarvaśaḥ

yo mām ajam anādiṃ ca vetti lokamaheśvaram
asaṃmūḍhaḥ sa martyeṣu sarvapāpaiḥ pramucyate

buddhir jñānam asaṃmohaḥ kṣamā satyaṃ damaḥ śamaḥ
sukhaṃ duḥkhaṃ bhavo 'bhāvo bhayaṃ cābhayam eva ca

ahiṃsā samatā tuṣṭis tapo dānaṃ yaśo 'yaśaḥ
bhavanti bhāvā bhūtānāṃ matta eva pṛthagvidhāḥ

maharṣayaḥ sapta pūrve catvāro manavas tathā
madbhāvā mānasā jātā yeṣāṃ loka imāḥ prajāḥ

etāṃ vibhūtiṃ yogaṃ ca mama yo vetti tattvataḥ
so 'vikampena yogena yujyate nātra saṃśayaḥ

ahaṃ sarvasya prabhavo mattaḥ sarvaṃ pravartate
iti matvā bhajante māṃ budhā bhāvasamanvitāḥ

maccittā madgataprāṇā bodhayantaḥ parasparam
kathayantaś ca māṃ nityaṃ tuṣyanti ca ramanti ca

teṣāṃ satatayuktānāṃ bhajatāṃ prītipūrvakam
dadāmi buddhiyogaṃ taṃ yena mām upayānti te

teṣām evānukampārtham aham ajñānajaṃ tamaḥ
nāśayāmy ātmabhāvastho jñānadīpena bhāsvatā

arjuna uvāca
paraṃ brahma paraṃ dhāma pavitraṃ paramaṃ bhavān
puruṣaṃ śāśvataṃ divyam ādidevam ajaṃ vibhum

āhus tvām ṛṣayaḥ sarve devarṣir nāradas tathā
asito devalo vyāsaḥ svayaṃ caiva bravīṣi me

sarvam etad ṛtaṃ manye yan māṃ vadasi keśava
na hi te bhagavan vyaktiṃ vidur devā na dānavāḥ

svayam evātmanātmānaṃ vettha tvaṃ puruṣottama
bhūtabhāvana bhūteśa devadeva jagatpate

vaktum arhasy aśeṣeṇa divyā hy ātmavibhūtayaḥ
yābhir vibhūtibhir lokān imāṃs tvaṃ vyāpya tiṣṭhasi

kathaṃ vidyām ahaṃ yogiṃs tvāṃ sadā paricintayan
keṣu keṣu ca bhāveṣu cintyo 'si bhagavan mayā

vistareṇātmano yogaṃ vibhūtiṃ ca janārdana
bhūyaḥ kathaya tṛptir hi śṛṇvato nāsti me 'mṛtam

śrībhagavān uvāca
hanta te kathayiṣyāmi divyā hy ātmavibhūtayaḥ
prādhānyataḥ kuruśreṣṭha nāsty anto vistarasya me

aham ātmā guḍākeśa sarvabhūtāśayasthitaḥ
aham ādiś ca madhyaṃ ca bhūtānām anta eva ca

ādityānām ahaṃ viṣṇur jyotiṣāṃ ravir aṃśumān
marīcir marutām asmi nakṣatrāṇām ahaṃ śaśī

vedānāṃ sāmavedo 'smi devānām asmi vāsavaḥ
indriyāṇāṃ manaś cāsmi bhūtānām asmi cetanā

rudrāṇāṃ śaṃkaraś cāsmi vitteśo yakṣarakṣasām
vasūnāṃ pāvakaś cāsmi meruḥ śikhariṇām aham

purodhasāṃ ca mukhyaṃ māṃ viddhi pārtha bṛhaspatim
senānīnām ahaṃ skandaḥ sarasām asmi sāgaraḥ

maharṣīṇāṃ bhṛgur ahaṃ girām asmy ekam akṣaram
yajñānāṃ japayajño 'smi sthāvarāṇāṃ himālayaḥ

aśvatthaḥ sarvavṛkṣāṇāṃ devarṣīṇāṃ ca nāradaḥ
gandharvāṇāṃ citrarathaḥ siddhānāṃ kapilo muniḥ

uccaiḥśravasam aśvānāṃ viddhi mām amṛtodbhavam
airāvataṃ gajendrāṇāṃ narāṇāṃ ca narādhipam

āyudhānām ahaṃ vajraṃ dhenūnām asmi kāmadhuk
prajanaś cāsmi kandarpaḥ sarpāṇām asmi vāsukiḥ

anantaś cāsmi nāgānāṃ varuṇo yādasām aham
pitṝṇām aryamā cāsmi yamaḥ saṃyamatām aham

prahlādaś cāsmi daityānāṃ kālaḥ kalayatām aham
mṛgāṇāṃ ca mṛgendro 'haṃ vainateyaś ca pakṣiṇām

pavanaḥ pavatām asmi rāmaḥ śastrabhṛtām aham
jhaṣāṇāṃ makaraś cāsmi srotasām asmi jāhnavī

sargāṇām ādir antaś ca madhyaṃ caivāham arjuna
adhyātmavidyā vidyānāṃ vādaḥ pravadatām aham

akṣarāṇām akāro 'smi dvaṃdvaḥ sāmāsikasya ca
aham evākṣayaḥ kālo dhātāhaṃ viśvatomukhaḥ

mṛtyuḥ sarvaharaś cāham udbhavaś ca bhaviṣyatām
kīrtiḥ śrīr vāk ca nārīṇāṃ smṛtir medhā dhṛtiḥ kṣamā

bṛhatsāma tathā sāmnāṃ gāyatrī chandasām aham
māsānāṃ mārgaśīrṣo 'ham ṛtūnāṃ kusumākaraḥ

dyūtaṃ chalayatām asmi tejas tejasvinām aham
jayo 'smi vyavasāyo 'smi sattvaṃ sattvavatām aham

vṛṣṇīnāṃ vāsudevo 'smi pāṇḍavānāṃ dhanaṃjayaḥ
munīnām apy ahaṃ vyāsaḥ kavīnām uśanā kaviḥ

daṇḍo damayatām asmi nītir asmi jigīṣatām
maunaṃ caivāsmi guhyānāṃ jñānaṃ jñānavatām aham

yac cāpi sarvabhūtānāṃ bījaṃ tad aham arjuna
na tad asti vinā yat syān mayā bhūtaṃ carācaram

nānto 'sti mama divyānāṃ vibhūtīnāṃ paraṃtapa
eṣa tūddeśataḥ prokto vibhūter vistaro mayā

yad yad vibhūtimat sattvaṃ śrīmad ūrjitam eva vā
tat tad evāvagaccha tvaṃ mama tejoṃśasaṃbhavam

atha vā bahunaitena kiṃ jñātena tavārjuna
viṣṭabhyāham idaṃ kṛtsnam ekāṃśena sthito jagat

arjuna uvāca
madanugrahāya paramaṃ guhyam adhyātmasaṃjñitam
yat tvayoktaṃ vacas tena moho 'yaṃ vigato mama

bhavāpyayau hi bhūtānāṃ śrutau vistaraśo mayā
tvattaḥ kamalapatrākṣa māhātmyam api cāvyayam

evam etad yathāttha tvam ātmānaṃ parameśvara
draṣṭum icchāmi te rūpam aiśvaraṃ puruṣottama

manyase yadi tac chakyaṃ mayā draṣṭum iti prabho
yogeśvara tato me tvaṃ darśayātmānam avyayam

śrībhagavān uvāca
paśya me pārtha rūpāṇi śataśo 'tha sahasraśaḥ
nānāvidhāni divyāni nānāvarṇākṛtīni ca

paśyādityān vasūn rudrān aśvinau marutas tathā
bahūny adṛṣṭapūrvāṇi paśyāścaryāṇi bhārata

ihaikasthaṃ jagat kṛtsnaṃ paśyādya sacarācaram
mama dehe guḍākeśa yac cānyad draṣṭum icchasi

na tu māṃ śakyase draṣṭum anenaiva svacakṣuṣā
divyaṃ dadāmi te cakṣuḥ paśya me yogam aiśvaram

saṃjaya uvāca
evam uktvā tato rājan mahāyogeśvaro hariḥ
darśayām āsa pārthāya paramaṃ rūpam aiśvaram

anekavaktranayanam anekādbhutadarśanam
anekadivyābharaṇaṃ divyānekodyatāyudham

divyamālyāmbaradharaṃ divyagandhānulepanam
sarvāścaryamayaṃ devam anantaṃ viśvatomukham

divi sūryasahasrasya bhaved yugapad utthitā
yadi bhāḥ sadṛśī sā syād bhāsas tasya mahātmanaḥ

tatraikasthaṃ jagat kṛtsnaṃ pravibhaktam anekadhā
apaśyad devadevasya śarīre pāṇḍavas tadā

tataḥ sa vismayāviṣṭo hṛṣṭaromā dhanaṃjayaḥ
praṇamya śirasā devaṃ kṛtāñjalir abhāṣata

arjuna uvāca
paśyāmi devāṃs tava deva dehe; sarvāṃs tathā bhūtaviśeṣasaṃghān
brahmāṇam īśaṃ kamalāsanastham; ṛṣīṃś ca sarvān uragāṃś ca divyān

anekabāhūdaravaktranetraṃ; paśyāmi tvā sarvato 'nantarūpam
nāntaṃ na madhyaṃ na punas tavādiṃ; paśyāmi viśveśvara viśvarūpa

kirīṭinaṃ gadinaṃ cakriṇaṃ ca; tejorāśiṃ sarvato dīptimantam
paśyāmi tvāṃ durnirīkṣyaṃ samantād; dīptānalārkadyutim aprameyam

tvam akṣaraṃ paramaṃ veditavyaṃ; tvam asya viśvasya paraṃ nidhānam
tvam avyayaḥ śāśvatadharmagoptā; sanātanas tvaṃ puruṣo mato me

anādimadhyāntam anantavīryam; anantabāhuṃ śaśisūryanetram
paśyāmi tvāṃ dīptahutāśavaktraṃ; svatejasā viśvam idaṃ tapantam

dyāvāpṛthivyor idam antaraṃ hi; vyāptaṃ tvayaikena diśaś ca sarvāḥ
dṛṣṭvādbhutaṃ rūpam idaṃ tavograṃ; lokatrayaṃ pravyathitaṃ mahātman

amī hi tvā surasaṃghā viśanti; ke cid bhītāḥ prāñjalayo gṛṇanti
svastīty uktvā maharṣisiddhasaṃghāḥ; stuvanti tvāṃ stutibhiḥ puṣkalābhiḥ

rudrādityā vasavo ye ca sādhyā; viśve 'śvinau marutaś coṣmapāś ca
gandharvayakṣāsurasiddhasaṃghā; vīkṣante tvā vismitāś caiva sarve

rūpaṃ mahat te bahuvaktranetraṃ; mahābāho bahubāhūrupādam
bahūdaraṃ bahudaṃṣṭrākarālaṃ; dṛṣṭvā lokāḥ pravyathitās tathāham

nabhaḥspṛśaṃ dīptam anekavarṇaṃ; vyāttānanaṃ dīptaviśālanetram
dṛṣṭvā hi tvāṃ pravyathitāntarātmā; dhṛtiṃ na vindāmi śamaṃ ca viṣṇo

daṃṣṭrākarālāni ca te mukhāni; dṛṣṭvaiva kālānalasaṃnibhāni
diśo na jāne na labhe ca śarma; prasīda deveśa jagannivāsa

amī ca tvāṃ dhṛtarāṣṭrasya putrāḥ; sarve sahaivāvanipālasaṃghaiḥ
bhīṣmo droṇaḥ sūtaputras tathāsau; sahāsmadīyair api yodhamukhyaiḥ

vaktrāṇi te tvaramāṇā viśanti; daṃṣṭrākarālāni bhayānakāni
ke cid vilagnā daśanāntareṣu; saṃdṛśyante cūrṇitair uttamāṅgaiḥ

yathā nadīnāṃ bahavo 'mbuvegāḥ; samudram evābhimukhā dravanti
tathā tavāmī naralokavīrā; viśanti vaktrāṇy abhivijvalanti

yathā pradīptaṃ jvalanaṃ pataṃgā; viśanti nāśāya samṛddhavegāḥ
tathaiva nāśāya viśanti lokās; tavāpi vaktrāṇi samṛddhavegāḥ

lelihyase grasamānaḥ samantāl; lokān samagrān vadanair jvaladbhiḥ
tejobhir āpūrya jagat samagraṃ; bhāsas tavogrāḥ pratapanti viṣṇo

ākhyāhi me ko bhavān ugrarūpo; namo 'stu te devavara prasīda
vijñātum icchāmi bhavantam ādyaṃ; na hi prajānāmi tava pravṛttim

śrībhagavān uvāca
kālo 'smi lokakṣayakṛt pravṛddho; lokān samāhartum iha pravṛttaḥ
ṛte 'pi tvā na bhaviṣyanti sarve; ye 'vasthitāḥ pratyanīkeṣu yodhāḥ

tasmāt tvam uttiṣṭha yaśo labhasva; jitvā śatrūn bhuṅkṣva rājyaṃ samṛddham
mayaivaite nihatāḥ pūrvam eva; nimittamātraṃ bhava savyasācin

droṇaṃ ca bhīṣmaṃ ca jayadrathaṃ ca; karṇaṃ tathānyān api yodhavīrān
mayā hatāṃs tvaṃ jahi mā vyathiṣṭhā; yudhyasva jetāsi raṇe sapatnān

saṃjaya uvāca
etac chrutvā vacanaṃ keśavasya; kṛtāñjalir vepamānaḥ kirīṭī
namaskṛtvā bhūya evāha kṛṣṇaṃ; sagadgadaṃ bhītabhītaḥ praṇamya

arjuna uvāca
sthāne hṛṣīkeśa tava prakīrtyā; jagat prahṛṣyaty anurajyate ca
rakṣāṃsi bhītāni diśo dravanti; sarve namasyanti ca siddhasaṃghāḥ

kasmāc ca te na nameran mahātman; garīyase brahmaṇo 'py ādikartre
ananta deveśa jagannivāsa; tvam akṣaraṃ sad asat tatparaṃ yat

tvam ādidevaḥ puruṣaḥ purāṇas; tvam asya viśvasya paraṃ nidhānam
vettāsi vedyaṃ ca paraṃ ca dhāma; tvayā tataṃ viśvam anantarūpa

vāyur yamo 'gnir varuṇaḥ śaśāṅkaḥ; prajāpatis tvaṃ prapitāmahaś ca
namo namas te 'stu sahasrakṛtvaḥ; punaś ca bhūyo 'pi namo namas te

namaḥ purastād atha pṛṣṭhatas te; namo 'stu te sarvata eva sarva
anantavīryāmitavikramas tvaṃ; sarvaṃ samāpnoṣi tato 'si sarvaḥ

sakheti matvā prasabhaṃ yad uktaṃ; he kṛṣṇa he yādava he sakheti
ajānatā mahimānaṃ tavedaṃ; mayā pramādāt praṇayena vāpi

yac cāvahāsārtham asatkṛto 'si; vihāraśayyāsanabhojaneṣu
eko 'tha vāpy acyuta tatsamakṣaṃ; tat kṣāmaye tvām aham aprameyam

pitāsi lokasya carācarasya; tvam asya pūjyaś ca gurur garīyān
na tvatsamo 'sty abhyadhikaḥ kuto 'nyo; lokatraye 'py apratimaprabhāva

tasmāt praṇamya praṇidhāya kāyaṃ; prasādaye tvām aham īśam īḍyam
piteva putrasya sakheva sakhyuḥ; priyaḥ priyāyārhasi deva soḍhum

adṛṣṭapūrvaṃ hṛṣito 'smi dṛṣṭvā; bhayena ca pravyathitaṃ mano me
tad eva me darśaya deva rūpaṃ; prasīda deveśa jagannivāsa

kirīṭinaṃ gadinaṃ cakrahastam; icchāmi tvāṃ draṣṭum ahaṃ tathaiva
tenaiva rūpeṇa caturbhujena; sahasrabāho bhava viśvamūrte

śrībhagavān uvāca
mayā prasannena tavārjunedaṃ; rūpaṃ paraṃ darśitam ātmayogāt
tejomayaṃ viśvam anantam ādyaṃ; yan me tvad anyena na dṛṣṭapūrvam

na vedayajñādhyayanair na dānair; na ca kriyābhir na tapobhir ugraiḥ
evaṃrūpaḥ śakya ahaṃ nṛloke; draṣṭuṃ tvad anyena kurupravīra

mā te vyathā mā ca vimūḍhabhāvo; dṛṣṭvā rūpaṃ ghoram īdṛṅ mamedam
vyapetabhīḥ prītamanāḥ punas tvaṃ; tad eva me rūpam idaṃ prapaśya

saṃjaya uvāca
ity arjunaṃ vāsudevas tathoktvā; svakaṃ rūpaṃ darśayām āsa bhūyaḥ
āśvāsayām āsa ca bhītam enaṃ; bhūtvā punaḥ saumyavapur mahātmā

arjuna uvāca
dṛṣṭvedaṃ mānuṣaṃ rūpaṃ tava saumyaṃ janārdana
idānīm asmi saṃvṛttaḥ sacetāḥ prakṛtiṃ gataḥ

śrībhagavān uvāca
sudurdarśam idaṃ rūpaṃ dṛṣṭavān asi yan mama
devā apy asya rūpasya nityaṃ darśanakāṅkṣiṇaḥ

nāhaṃ vedair na tapasā na dānena na cejyayā
śakya evaṃvidho draṣṭuṃ dṛṣṭavān asi māṃ yathā

bhaktyā tv ananyayā śakya aham evaṃvidho 'rjuna
jñātuṃ draṣṭuṃ ca tattvena praveṣṭuṃ ca paraṃtapa

matkarmakṛn matparamo madbhaktaḥ saṅgavarjitaḥ
nirvairaḥ sarvabhūteṣu yaḥ sa mām eti pāṇḍava

arjuna uvāca
evaṃ satatayuktā ye bhaktās tvāṃ paryupāsate
ye cāpy akṣaram avyaktaṃ teṣāṃ ke yogavittamāḥ

śrībhagavān uvāca
mayy āveśya mano ye māṃ nityayuktā upāsate
śraddhayā parayopetās te me yuktatamā matāḥ

ye tv akṣaram anirdeśyam avyaktaṃ paryupāsate
sarvatragam acintyaṃ ca kūṭastham acalaṃ dhruvam

saṃniyamyendriyagrāmaṃ sarvatra samabuddhayaḥ
te prāpnuvanti mām eva sarvabhūtahite ratāḥ

kleśo 'dhikataras teṣām avyaktāsaktacetasām
avyaktā hi gatir duḥkhaṃ dehavadbhir avāpyate

ye tu sarvāṇi karmāṇi mayi saṃnyasya matparāḥ
ananyenaiva yogena māṃ dhyāyanta upāsate

teṣām ahaṃ samuddhartā mṛtyusaṃsārasāgarāt
bhavāmi nacirāt pārtha mayy āveśitacetasām

mayy eva mana ādhatsva mayi buddhiṃ niveśaya
nivasiṣyasi mayy eva ata ūrdhvaṃ na saṃśayaḥ

atha cittaṃ samādhātuṃ na śaknoṣi mayi sthiram
abhyāsayogena tato mām icchāptuṃ dhanaṃjaya

abhyāse 'py asamartho 'si matkarmaparamo bhava
madartham api karmāṇi kurvan siddhim avāpsyasi

athaitad apy aśakto 'si kartuṃ madyogam āśritaḥ
sarvakarmaphalatyāgaṃ tataḥ kuru yatātmavān

śreyo hi jñānam abhyāsāj jñānād dhyānaṃ viśiṣyate
dhyānāt karmaphalatyāgas tyāgāc chāntir anantaram

adveṣṭā sarvabhūtānāṃ maitraḥ karuṇa eva ca
nirmamo nirahaṃkāraḥ samaduḥkhasukhaḥ kṣamī

saṃtuṣṭaḥ satataṃ yogī yatātmā dṛḍhaniścayaḥ
mayy arpitamanobuddhir yo madbhaktaḥ sa me priyaḥ

yasmān nodvijate loko lokān nodvijate ca yaḥ
harṣāmarṣabhayodvegair mukto yaḥ sa ca me priyaḥ

anapekṣaḥ śucir dakṣa udāsīno gatavyathaḥ
sarvārambhaparityāgī yo madbhaktaḥ sa me priyaḥ

yo na hṛṣyati na dveṣṭi na śocati na kāṅkṣati
śubhāśubhaparityāgī bhaktimān yaḥ sa me priyaḥ

samaḥ śatrau ca mitre ca tathā mānāvamānayoḥ
śītoṣṇasukhaduḥkheṣu samaḥ saṅgavivarjitaḥ

tulyanindāstutir maunī saṃtuṣṭo yena kena cit
aniketaḥ sthiramatir bhaktimān me priyo naraḥ

ye tu dharmyāmṛtam idaṃ yathoktaṃ paryupāsate
śraddadhānā matparamā bhaktās te 'tīva me priyāḥ

śrībhagavān uvāca
idaṃ śarīraṃ kaunteya kṣetram ity abhidhīyate
etad yo vetti taṃ prāhuḥ kṣetrajña iti tadvidaḥ

kṣetrajñaṃ cāpi māṃ viddhi sarvakṣetreṣu bhārata
kṣetrakṣetrajñayor jñānaṃ yat taj jñānaṃ mataṃ mama

tat kṣetraṃ yac ca yādṛk ca yadvikāri yataś ca yat
sa ca yo yatprabhāvaś ca tat samāsena me śṛṇu

ṛṣibhir bahudhā gītaṃ chandobhir vividhaiḥ pṛthak
brahmasūtrapadaiś caiva hetumadbhir viniścitaiḥ

mahābhūtāny ahaṃkāro buddhir avyaktam eva ca
indriyāṇi daśaikaṃ ca pañca cendriyagocarāḥ

icchā dveṣaḥ sukhaṃ duḥkhaṃ saṃghātaś cetanā dhṛtiḥ
etat kṣetraṃ samāsena savikāram udāhṛtam

amānitvam adambhitvam ahiṃsā kṣāntir ārjavam
ācāryopāsanaṃ śaucaṃ sthairyam ātmavinigrahaḥ

indriyārtheṣu vairāgyam anahaṃkāra eva ca
janmamṛtyujarāvyādhiduḥkhadoṣānudarśanam

asaktir anabhiṣvaṅgaḥ putradāragṛhādiṣu
nityaṃ ca samacittatvam iṣṭāniṣṭopapattiṣu

mayi cānanyayogena bhaktir avyabhicāriṇī
viviktadeśasevitvam aratir janasaṃsadi

adhyātmajñānanityatvaṃ tattvajñānārthadarśanam
etaj jñānam iti proktam ajñānaṃ yad ato 'nyathā

jñeyaṃ yat tat pravakṣyāmi yaj jñātvāmṛtam aśnute
anādimat paraṃ brahma na sat tan nāsad ucyate

sarvataḥpāṇipādaṃ tat sarvatokṣiśiromukham
sarvataḥśrutimal loke sarvam āvṛtya tiṣṭhati

sarvendriyaguṇābhāsaṃ sarvendriyavivarjitam
asaktaṃ sarvabhṛc caiva nirguṇaṃ guṇabhoktṛ ca

bahir antaś ca bhūtānām acaraṃ caram eva ca
sūkṣmatvāt tad avijñeyaṃ dūrasthaṃ cāntike ca tat

avibhaktaṃ ca bhūteṣu vibhaktam iva ca sthitam
bhūtabhartṛ ca taj jñeyaṃ grasiṣṇu prabhaviṣṇu ca

jyotiṣām api taj jyotis tamasaḥ param ucyate
jñānaṃ jñeyaṃ jñānagamyaṃ hṛdi sarvasya viṣṭhitam

iti kṣetraṃ tathā jñānaṃ jñeyaṃ coktaṃ samāsataḥ
madbhakta etad vijñāya madbhāvāyopapadyate

prakṛtiṃ puruṣaṃ caiva viddhy anādī ubhāv api
vikārāṃś ca guṇāṃś caiva viddhi prakṛtisaṃbhavān

kāryakāraṇakartṛtve hetuḥ prakṛtir ucyate
puruṣaḥ sukhaduḥkhānāṃ bhoktṛtve hetur ucyate

puruṣaḥ prakṛtistho hi bhuṅkte prakṛtijān guṇān
kāraṇaṃ guṇasaṅgo 'sya sadasadyonijanmasu

upadraṣṭānumantā ca bhartā bhoktā maheśvaraḥ
paramātmeti cāpy ukto dehe 'smin puruṣaḥ paraḥ

ya evaṃ vetti puruṣaṃ prakṛtiṃ ca guṇaiḥ saha
sarvathā vartamāno 'pi na sa bhūyo 'bhijāyate

dhyānenātmani paśyanti ke cid ātmānam ātmanā
anye sāṃkhyena yogena karmayogena cāpare

anye tv evam ajānantaḥ śrutvānyebhya upāsate
te 'pi cātitaranty eva mṛtyuṃ śrutiparāyaṇāḥ

yāvat saṃjāyate kiṃ cit sattvaṃ sthāvarajaṅgamam
kṣetrakṣetrajñasaṃyogāt tad viddhi bharatarṣabha

samaṃ sarveṣu bhūteṣu tiṣṭhantaṃ parameśvaram
vinaśyatsv avinaśyantaṃ yaḥ paśyati sa paśyati

samaṃ paśyan hi sarvatra samavasthitam īśvaram
na hinasty ātmanātmānaṃ tato yāti parāṃ gatim

prakṛtyaiva ca karmāṇi kriyamāṇāni sarvaśaḥ
yaḥ paśyati tathātmānam akartāraṃ sa paśyati

yadā bhūtapṛthagbhāvam ekastham anupaśyati
tata eva ca vistāraṃ brahma saṃpadyate tadā

anāditvān nirguṇatvāt paramātmāyam avyayaḥ
śarīrastho 'pi kaunteya na karoti na lipyate

yathā sarvagataṃ saukṣmyād ākāśaṃ nopalipyate
sarvatrāvasthito dehe tathātmā nopalipyate

yathā prakāśayaty ekaḥ kṛtsnaṃ lokam imaṃ raviḥ
kṣetraṃ kṣetrī tathā kṛtsnaṃ prakāśayati bhārata

kṣetrakṣetrajñayor evam antaraṃ jñānacakṣuṣā
bhūtaprakṛtimokṣaṃ ca ye vidur yānti te param

śrībhagavān uvāca
paraṃ bhūyaḥ pravakṣyāmi jñānānāṃ jñānam uttamam
yaj jñātvā munayaḥ sarve parāṃ siddhim ito gatāḥ

idaṃ jñānam upāśritya mama sādharmyam āgatāḥ
sarge 'pi nopajāyante pralaye na vyathanti ca

mama yonir mahad brahma tasmin garbhaṃ dadhāmy aham
saṃbhavaḥ sarvabhūtānāṃ tato bhavati bhārata

sarvayoniṣu kaunteya mūrtayaḥ saṃbhavanti yāḥ
tāsāṃ brahma mahad yonir ahaṃ bījapradaḥ pitā

sattvaṃ rajas tama iti guṇāḥ prakṛtisaṃbhavāḥ
nibadhnanti mahābāho dehe dehinam avyayam

tatra sattvaṃ nirmalatvāt prakāśakam anāmayam
sukhasaṅgena badhnāti jñānasaṅgena cānagha

rajo rāgātmakaṃ viddhi tṛṣṇāsaṅgasamudbhavam
tan nibadhnāti kaunteya karmasaṅgena dehinam

tamas tv ajñānajaṃ viddhi mohanaṃ sarvadehinām
pramādālasyanidrābhis tan nibadhnāti bhārata

sattvaṃ sukhe sañjayati rajaḥ karmaṇi bhārata
jñānam āvṛtya tu tamaḥ pramāde sañjayaty uta

rajas tamaś cābhibhūya sattvaṃ bhavati bhārata
rajaḥ sattvaṃ tamaś caiva tamaḥ sattvaṃ rajas tathā

sarvadvāreṣu dehe 'smin prakāśa upajāyate
jñānaṃ yadā tadā vidyād vivṛddhaṃ sattvam ity uta

lobhaḥ pravṛttir ārambhaḥ karmaṇām aśamaḥ spṛhā
rajasy etāni jāyante vivṛddhe bharatarṣabha

aprakāśo 'pravṛttiś ca pramādo moha eva ca
tamasy etāni jāyante vivṛddhe kurunandana

yadā sattve pravṛddhe tu pralayaṃ yāti dehabhṛt
tadottamavidāṃ lokān amalān pratipadyate

rajasi pralayaṃ gatvā karmasaṅgiṣu jāyate
tathā pralīnas tamasi mūḍhayoniṣu jāyate

karmaṇaḥ sukṛtasyāhuḥ sāttvikaṃ nirmalaṃ phalam
rajasas tu phalaṃ duḥkham ajñānaṃ tamasaḥ phalam

sattvāt saṃjāyate jñānaṃ rajaso lobha eva ca
pramādamohau tamaso bhavato 'jñānam eva ca

ūrdhvaṃ gacchanti sattvasthā madhye tiṣṭhanti rājasāḥ
jaghanyaguṇavṛttasthā adho gacchanti tāmasāḥ

nānyaṃ guṇebhyaḥ kartāraṃ yadā draṣṭānupaśyati
guṇebhyaś ca paraṃ vetti madbhāvaṃ so 'dhigacchati

guṇān etān atītya trīn dehī dehasamudbhavān
janmamṛtyujarāduḥkhair vimukto 'mṛtam aśnute

arjuna uvāca
kair liṅgais trīn guṇān etān atīto bhavati prabho
kimācāraḥ kathaṃ caitāṃs trīn guṇān ativartate

śrībhagavān uvāca
prakāśaṃ ca pravṛttiṃ ca moham eva ca pāṇḍava
na dveṣṭi saṃpravṛttāni na nivṛttāni kāṅkṣati

udāsīnavad āsīno guṇair yo na vicālyate
guṇā vartanta ity eva yo 'vatiṣṭhati neṅgate

samaduḥkhasukhaḥ svasthaḥ samaloṣṭāśmakāñcanaḥ
tulyapriyāpriyo dhīras tulyanindātmasaṃstutiḥ
mānāvamānayos tulyas tulyo mitrāripakṣayoḥ
sarvārambhaparityāgī guṇātītaḥ sa ucyate

māṃ ca yo 'vyabhicāreṇa bhaktiyogena sevate
sa guṇān samatītyaitān brahmabhūyāya kalpate

brahmaṇo hi pratiṣṭhāham amṛtasyāvyayasya ca
śāśvatasya ca dharmasya sukhasyaikāntikasya ca

śrībhagavān uvāca
ūrdhvamūlam adhaḥśākham aśvatthaṃ prāhur avyayam
chandāṃsi yasya parṇāni yas taṃ veda sa vedavit

adhaś cordhvaṃ prasṛtās tasya śākhā; guṇapravṛddhā viṣayapravālāḥ
adhaś ca mūlāny anusaṃtatāni; karmānubandhīni manuṣyaloke

na rūpam asyeha tathopalabhyate; nānto na cādir na ca saṃpratiṣṭhā
aśvattham enaṃ suvirūḍhamūlam; asaṅgaśastreṇa dṛḍhena chittvā

tataḥ padaṃ tatparimārgitavyaṃ; yasmin gatā na nivartanti bhūyaḥ
tam eva cādyaṃ puruṣaṃ prapadye; yataḥ pravṛttiḥ prasṛtā purāṇī

nirmānamohā jitasaṅgadoṣā; adhyātmanityā vinivṛttakāmāḥ
dvaṃdvair vimuktāḥ sukhaduḥkhasaṃjñair; gacchanty amūḍhāḥ padam avyayaṃ tat

na tad bhāsayate sūryo na śaśāṅko na pāvakaḥ
yad gatvā na nivartante tad dhāma paramaṃ mama

mamaivāṃśo jīvaloke jīvabhūtaḥ sanātanaḥ
manaḥṣaṣṭhānīndriyāṇi prakṛtisthāni karṣati

śarīraṃ yad avāpnoti yac cāpy utkrāmatīśvaraḥ
gṛhītvaitāni saṃyāti vāyur gandhān ivāśayāt

śrotraṃ cakṣuḥ sparśanaṃ ca rasanaṃ ghrāṇam eva ca
adhiṣṭhāya manaś cāyaṃ viṣayān upasevate

utkrāmantaṃ sthitaṃ vāpi bhuñjānaṃ vā guṇānvitam
vimūḍhā nānupaśyanti paśyanti jñānacakṣuṣaḥ

yatanto yoginaś cainaṃ paśyanty ātmany avasthitam
yatanto 'py akṛtātmāno nainaṃ paśyanty acetasaḥ

yad ādityagataṃ tejo jagad bhāsayate 'khilam
yac candramasi yac cāgnau tat tejo viddhi māmakam

gām āviśya ca bhūtāni dhārayāmy aham ojasā
puṣṇāmi cauṣadhīḥ sarvāḥ somo bhūtvā rasātmakaḥ

ahaṃ vaiśvānaro bhūtvā prāṇināṃ deham āśritaḥ
prāṇāpānasamāyuktaḥ pacāmy annaṃ caturvidham

sarvasya cāhaṃ hṛdi saṃniviṣṭo; mattaḥ smṛtir jñānam apohanaṃ ca
vedaiś ca sarvair aham eva vedyo; vedāntakṛd vedavid eva cāham

dvāv imau puruṣau loke kṣaraś cākṣara eva ca
kṣaraḥ sarvāṇi bhūtāni kūṭastho 'kṣara ucyate

uttamaḥ puruṣas tv anyaḥ paramātmety udāhṛtaḥ
yo lokatrayam āviśya bibharty avyaya īśvaraḥ

yasmāt kṣaram atīto 'ham akṣarād api cottamaḥ
ato 'smi loke vede ca prathitaḥ puruṣottamaḥ

yo mām evam asaṃmūḍho jānāti puruṣottamam
sa sarvavid bhajati māṃ sarvabhāvena bhārata

iti guhyatamaṃ śāstram idam uktaṃ mayānagha
etad buddhvā buddhimān syāt kṛtakṛtyaś ca bhārata

śrībhagavān uvāca
abhayaṃ sattvasaṃśuddhir jñānayogavyavasthitiḥ
dānaṃ damaś ca yajñaś ca svādhyāyas tapa ārjavam

ahiṃsā satyam akrodhas tyāgaḥ śāntir apaiśunam
dayā bhūteṣv aloluptvaṃ mārdavaṃ hrīr acāpalam

tejaḥ kṣamā dhṛtiḥ śaucam adroho nātimānitā
bhavanti saṃpadaṃ daivīm abhijātasya bhārata

dambho darpo 'timānaś ca krodhaḥ pāruṣyam eva ca
ajñānaṃ cābhijātasya pārtha saṃpadam āsurīm

daivī saṃpad vimokṣāya nibandhāyāsurī matā
mā śucaḥ saṃpadaṃ daivīm abhijāto 'si pāṇḍava

dvau bhūtasargau loke 'smin daiva āsura eva ca
daivo vistaraśaḥ prokta āsuraṃ pārtha me śṛṇu

pravṛttiṃ ca nivṛttiṃ ca janā na vidur āsurāḥ
na śaucaṃ nāpi cācāro na satyaṃ teṣu vidyate

asatyam apratiṣṭhaṃ te jagad āhur anīśvaram
aparasparasaṃbhūtaṃ kim anyat kāmahaitukam

etāṃ dṛṣṭim avaṣṭabhya naṣṭātmāno 'lpabuddhayaḥ
prabhavanty ugrakarmāṇaḥ kṣayāya jagato 'hitāḥ

kāmam āśritya duṣpūraṃ dambhamānamadānvitāḥ
mohād gṛhītvāsadgrāhān pravartante 'śucivratāḥ

cintām aparimeyāṃ ca pralayāntām upāśritāḥ
kāmopabhogaparamā etāvad iti niścitāḥ

āśāpāśaśatair baddhāḥ kāmakrodhaparāyaṇāḥ
īhante kāmabhogārtham anyāyenārthasaṃcayān

idam adya mayā labdham idaṃ prāpsye manoratham
idam astīdam api me bhaviṣyati punar dhanam

asau mayā hataḥ śatrur haniṣye cāparān api
īśvaro 'ham ahaṃ bhogī siddho 'haṃ balavān sukhī

āḍhyo 'bhijanavān asmi ko 'nyo 'sti sadṛśo mayā
yakṣye dāsyāmi modiṣya ity ajñānavimohitāḥ

anekacittavibhrāntā mohajālasamāvṛtāḥ
prasaktāḥ kāmabhogeṣu patanti narake 'śucau

ātmasaṃbhāvitāḥ stabdhā dhanamānamadānvitāḥ
yajante nāmayajñais te dambhenāvidhipūrvakam

ahaṃkāraṃ balaṃ darpaṃ kāmaṃ krodhaṃ ca saṃśritāḥ
mām ātmaparadeheṣu pradviṣanto 'bhyasūyakāḥ

tān ahaṃ dviṣataḥ krūrān saṃsāreṣu narādhamān
kṣipāmy ajasram aśubhān āsurīṣv eva yoniṣu

āsurīṃ yonim āpannā mūḍhā janmani janmani
mām aprāpyaiva kaunteya tato yānty adhamāṃ gatim

trividhaṃ narakasyedaṃ dvāraṃ nāśanam ātmanaḥ
kāmaḥ krodhas tathā lobhas tasmād etat trayaṃ tyajet

etair vimuktaḥ kaunteya tamodvārais tribhir naraḥ
ācaraty ātmanaḥ śreyas tato yāti parāṃ gatim

yaḥ śāstravidhim utsṛjya vartate kāmakārataḥ
na sa siddhim avāpnoti na sukhaṃ na parāṃ gatim

tasmāc chāstraṃ pramāṇaṃ te kāryākāryavyavasthitau
jñātvā śāstravidhānoktaṃ karma kartum ihārhasi

arjuna uvāca
ye śāstravidhim utsṛjya yajante śraddhayānvitāḥ
teṣāṃ niṣṭhā tu kā kṛṣṇa sattvam āho rajas tamaḥ

śrībhagavān uvāca
trividhā bhavati śraddhā dehināṃ sā svabhāvajā
sāttvikī rājasī caiva tāmasī ceti tāṃ śṛṇu

sattvānurūpā sarvasya śraddhā bhavati bhārata
śraddhāmayo 'yaṃ puruṣo yo yacchraddhaḥ sa eva saḥ

yajante sāttvikā devān yakṣarakṣāṃsi rājasāḥ
pretān bhūtagaṇāṃś cānye yajante tāmasā janāḥ

aśāstravihitaṃ ghoraṃ tapyante ye tapo janāḥ
dambhāhaṃkārasaṃyuktāḥ kāmarāgabalānvitāḥ

karśayantaḥ śarīrasthaṃ bhūtagrāmam acetasaḥ
māṃ caivāntaḥśarīrasthaṃ tān viddhy āsuraniścayān
āhāras tv api sarvasya trividho bhavati priyaḥ
yajñas tapas tathā dānaṃ teṣāṃ bhedam imaṃ śṛṇu

āyuḥsattvabalārogyasukhaprītivivardhanāḥ
rasyāḥ snigdhāḥ sthirā hṛdyā āhārāḥ sāttvikapriyāḥ

kaṭvamlalavaṇātyuṣṇatīkṣṇarūkṣavidāhinaḥ
āhārā rājasasyeṣṭā duḥkhaśokāmayapradāḥ

yātayāmaṃ gatarasaṃ pūti paryuṣitaṃ ca yat
ucchiṣṭam api cāmedhyaṃ bhojanaṃ tāmasapriyam

aphalākāṅkṣibhir yajño vidhidṛṣṭo ya ijyate
yaṣṭavyam eveti manaḥ samādhāya sa sāttvikaḥ

abhisaṃdhāya tu phalaṃ dambhārtham api caiva yat
ijyate bharataśreṣṭha taṃ yajñaṃ viddhi rājasam

vidhihīnam asṛṣṭānnaṃ mantrahīnam adakṣiṇam
śraddhāvirahitaṃ yajñaṃ tāmasaṃ paricakṣate

devadvijaguruprājñapūjanaṃ śaucam ārjavam
brahmacaryam ahiṃsā ca śārīraṃ tapa ucyate

anudvegakaraṃ vākyaṃ satyaṃ priyahitaṃ ca yat
svādhyāyābhyasanaṃ caiva vāṅmayaṃ tapa ucyate

manaḥprasādaḥ saumyatvaṃ maunam ātmavinigrahaḥ
bhāvasaṃśuddhir ity etat tapo mānasam ucyate

śraddhayā parayā taptaṃ tapas tat trividhaṃ naraiḥ
aphalākāṅkṣibhir yuktaiḥ sāttvikaṃ paricakṣate

satkāramānapūjārthaṃ tapo dambhena caiva yat
kriyate tad iha proktaṃ rājasaṃ calam adhruvam

mūḍhagrāheṇātmano yat pīḍayā kriyate tapaḥ
parasyotsādanārthaṃ vā tat tāmasam udāhṛtam

dātavyam iti yad dānaṃ dīyate 'nupakāriṇe
deśe kāle ca pātre ca tad dānaṃ sāttvikaṃ smṛtam

yat tu pratyupakārārthaṃ phalam uddiśya vā punaḥ
dīyate ca parikliṣṭaṃ tad dānaṃ rājasaṃ smṛtam

adeśakāle yad dānam apātrebhyaś ca dīyate
asatkṛtam avajñātaṃ tat tāmasam udāhṛtam

oṃ tat sad iti nirdeśo brahmaṇas trividhaḥ smṛtaḥ
brāhmaṇās tena vedāś ca yajñāś ca vihitāḥ purā

tasmād om ity udāhṛtya yajñadānatapaḥkriyāḥ
pravartante vidhānoktāḥ satataṃ brahmavādinām

tad ity anabhisaṃdhāya phalaṃ yajñatapaḥkriyāḥ
dānakriyāś ca vividhāḥ kriyante mokṣakāṅkṣibhiḥ

sadbhāve sādhubhāve ca sad ity etat prayujyate
praśaste karmaṇi tathā sacchabdaḥ pārtha yujyate

yajñe tapasi dāne ca sthitiḥ sad iti cocyate
karma caiva tadarthīyaṃ sad ity evābhidhīyate

aśraddhayā hutaṃ dattaṃ tapas taptaṃ kṛtaṃ ca yat
asad ity ucyate pārtha na ca tat pretya no iha

arjuna uvāca
saṃnyāsasya mahābāho tattvam icchāmi veditum
tyāgasya ca hṛṣīkeśa pṛthak keśiniṣūdana

śrībhagavān uvāca
kāmyānāṃ karmaṇāṃ nyāsaṃ saṃnyāsaṃ kavayo viduḥ
sarvakarmaphalatyāgaṃ prāhus tyāgaṃ vicakṣaṇāḥ

tyājyaṃ doṣavad ity eke karma prāhur manīṣiṇaḥ
yajñadānatapaḥkarma na tyājyam iti cāpare

niścayaṃ śṛṇu me tatra tyāge bharatasattama
tyāgo hi puruṣavyāghra trividhaḥ saṃprakīrtitaḥ
yajñadānatapaḥkarma na tyājyaṃ kāryam eva tat
yajño dānaṃ tapaś caiva pāvanāni manīṣiṇām

etāny api tu karmāṇi saṅgaṃ tyaktvā phalāni ca
kartavyānīti me pārtha niścitaṃ matam uttamam

niyatasya tu saṃnyāsaḥ karmaṇo nopapadyate
mohāt tasya parityāgas tāmasaḥ parikīrtitaḥ

duḥkham ity eva yat karma kāyakleśabhayāt tyajet
sa kṛtvā rājasaṃ tyāgaṃ naiva tyāgaphalaṃ labhet

kāryam ity eva yat karma niyataṃ kriyate 'rjuna
saṅgaṃ tyaktvā phalaṃ caiva sa tyāgaḥ sāttviko mataḥ

na dveṣṭy akuśalaṃ karma kuśale nānuṣajjate
tyāgī sattvasamāviṣṭo medhāvī chinnasaṃśayaḥ

na hi dehabhṛtā śakyaṃ tyaktuṃ karmāṇy aśeṣataḥ
yas tu karmaphalatyāgī sa tyāgīty abhidhīyate

aniṣṭam iṣṭaṃ miśraṃ ca trividhaṃ karmaṇaḥ phalam
bhavaty atyāgināṃ pretya na tu saṃnyāsināṃ kva cit

pañcaitāni mahābāho kāraṇāni nibodha me
sāṃkhye kṛtānte proktāni siddhaye sarvakarmaṇām

adhiṣṭhānaṃ tathā kartā karaṇaṃ ca pṛthagvidham
vividhāś ca pṛthakceṣṭā daivaṃ caivātra pañcamam

śarīravāṅmanobhir yat karma prārabhate naraḥ
nyāyyaṃ vā viparītaṃ vā pañcaite tasya hetavaḥ

tatraivaṃ sati kartāram ātmānaṃ kevalaṃ tu yaḥ
paśyaty akṛtabuddhitvān na sa paśyati durmatiḥ

yasya nāhaṃkṛto bhāvo buddhir yasya na lipyate
hatvāpi sa imāṃl lokān na hanti na nibadhyate

jñānaṃ jñeyaṃ parijñātā trividhā karmacodanā
karaṇaṃ karma karteti trividhaḥ karmasaṃgrahaḥ

jñānaṃ karma ca kartā ca tridhaiva guṇabhedataḥ
procyate guṇasaṃkhyāne yathāvac chṛṇu tāny api

sarvabhūteṣu yenaikaṃ bhāvam avyayam īkṣate
avibhaktaṃ vibhakteṣu taj jñānaṃ viddhi sāttvikam

pṛthaktvena tu yaj jñānaṃ nānābhāvān pṛthagvidhān
vetti sarveṣu bhūteṣu taj jñānaṃ viddhi rājasam

yat tu kṛtsnavad ekasmin kārye saktam ahaitukam
atattvārthavad alpaṃ ca tat tāmasam udāhṛtam

niyataṃ saṅgarahitam arāgadveṣataḥ kṛtam
aphalaprepsunā karma yat tat sāttvikam ucyate

yat tu kāmepsunā karma sāhaṃkāreṇa vā punaḥ
kriyate bahulāyāsaṃ tad rājasam udāhṛtam

anubandhaṃ kṣayaṃ hiṃsām anapekṣya ca pauruṣam
mohād ārabhyate karma yat tat tāmasam ucyate

muktasaṅgo 'nahaṃvādī dhṛtyutsāhasamanvitaḥ
siddhyasiddhyor nirvikāraḥ kartā sāttvika ucyate

rāgī karmaphalaprepsur lubdho hiṃsātmako 'śuciḥ
harṣaśokānvitaḥ kartā rājasaḥ parikīrtitaḥ

ayuktaḥ prākṛtaḥ stabdhaḥ śaṭho naikṛtiko 'lasaḥ
viṣādī dīrghasūtrī ca kartā tāmasa ucyate

buddher bhedaṃ dhṛteś caiva guṇatas trividhaṃ śṛṇu
procyamānam aśeṣeṇa pṛthaktvena dhanaṃjaya

pravṛttiṃ ca nivṛttiṃ ca kāryākārye bhayābhaye
bandhaṃ mokṣaṃ ca yā vetti buddhiḥ sā pārtha sāttvikī

yayā dharmam adharmaṃ ca kāryaṃ cākāryam eva ca
ayathāvat prajānāti buddhiḥ sā pārtha rājasī

adharmaṃ dharmam iti yā manyate tamasāvṛtā
sarvārthān viparītāṃś ca buddhiḥ sā pārtha tāmasī

dhṛtyā yayā dhārayate manaḥprāṇendriyakriyāḥ
yogenāvyabhicāriṇyā dhṛtiḥ sā pārtha sāttvikī

yayā tu dharmakāmārthān dhṛtyā dhārayate 'rjuna
prasaṅgena phalākāṅkṣī dhṛtiḥ sā pārtha rājasī

yayā svapnaṃ bhayaṃ śokaṃ viṣādaṃ madam eva ca
na vimuñcati durmedhā dhṛtiḥ sā pārtha tāmasī

sukhaṃ tv idānīṃ trividhaṃ śṛṇu me bharatarṣabha
abhyāsād ramate yatra duḥkhāntaṃ ca nigacchati

yat tadagre viṣam iva pariṇāme 'mṛtopamam
tat sukhaṃ sāttvikaṃ proktam ātmabuddhiprasādajam

viṣayendriyasaṃyogād yat tadagre 'mṛtopamam
pariṇāme viṣam iva tat sukhaṃ rājasaṃ smṛtam

yad agre cānubandhe ca sukhaṃ mohanam ātmanaḥ
nidrālasyapramādotthaṃ tat tāmasam udāhṛtam

na tad asti pṛthivyāṃ vā divi deveṣu vā punaḥ
sattvaṃ prakṛtijair muktaṃ yad ebhiḥ syāt tribhir guṇaiḥ

brāhmaṇakṣatriyaviśāṃ śūdrāṇāṃ ca paraṃtapa
karmāṇi pravibhaktāni svabhāvaprabhavair guṇaiḥ

śamo damas tapaḥ śaucaṃ kṣāntir ārjavam eva ca
jñānaṃ vijñānam āstikyaṃ brahmakarma svabhāvajam

śauryaṃ tejo dhṛtir dākṣyaṃ yuddhe cāpy apalāyanam
dānam īśvarabhāvaś ca kṣatrakarma svabhāvajam

kṛṣigorakṣyavāṇijyaṃ vaiśyakarma svabhāvajam
paricaryātmakaṃ karma śūdrasyāpi svabhāvajam

sve sve karmaṇy abhirataḥ saṃsiddhiṃ labhate naraḥ
svakarmanirataḥ siddhiṃ yathā vindati tac chṛṇu

yataḥ pravṛttir bhūtānāṃ yena sarvam idaṃ tatam
svakarmaṇā tam abhyarcya siddhiṃ vindati mānavaḥ

śreyān svadharmo viguṇaḥ paradharmāt svanuṣṭhitāt
svabhāvaniyataṃ karma kurvan nāpnoti kilbiṣam

sahajaṃ karma kaunteya sadoṣam api na tyajet
sarvārambhā hi doṣeṇa dhūmenāgnir ivāvṛtāḥ

asaktabuddhiḥ sarvatra jitātmā vigataspṛhaḥ
naiṣkarmyasiddhiṃ paramāṃ saṃnyāsenādhigacchati

siddhiṃ prāpto yathā brahma tathāpnoti nibodha me
samāsenaiva kaunteya niṣṭhā jñānasya yā parā

buddhyā viśuddhayā yukto dhṛtyātmānaṃ niyamya ca
śabdādīn viṣayāṃs tyaktvā rāgadveṣau vyudasya ca

viviktasevī laghvāśī yatavākkāyamānasaḥ
dhyānayogaparo nityaṃ vairāgyaṃ samupāśritaḥ

ahaṃkāraṃ balaṃ darpaṃ kāmaṃ krodhaṃ parigraham
vimucya nirmamaḥ śānto brahmabhūyāya kalpate

brahmabhūtaḥ prasannātmā na śocati na kāṅkṣati
samaḥ sarveṣu bhūteṣu madbhaktiṃ labhate parām

bhaktyā mām abhijānāti yāvān yaś cāsmi tattvataḥ
tato māṃ tattvato jñātvā viśate tadanantaram

sarvakarmāṇy api sadā kurvāṇo madvyapāśrayaḥ
matprasādād avāpnoti śāśvataṃ padam avyayam

cetasā sarvakarmāṇi mayi saṃnyasya matparaḥ
buddhiyogam upāśritya maccittaḥ satataṃ bhava

maccittaḥ sarvadurgāṇi matprasādāt tariṣyasi
atha cet tvam ahaṃkārān na śroṣyasi vinaṅkṣyasi

yad ahaṃkāram āśritya na yotsya iti manyase
mithyaiṣa vyavasāyas te prakṛtis tvāṃ niyokṣyati

svabhāvajena kaunteya nibaddhaḥ svena karmaṇā
kartuṃ necchasi yan mohāt kariṣyasy avaśo 'pi tat

īśvaraḥ sarvabhūtānāṃ hṛddeśe 'rjuna tiṣṭhati
bhrāmayan sarvabhūtāni yantrārūḍhāni māyayā

tam eva śaraṇaṃ gaccha sarvabhāvena bhārata
tatprasādāt parāṃ śāntiṃ sthānaṃ prāpsyasi śāśvatam

iti te jñānam ākhyātaṃ guhyād guhyataraṃ mayā
vimṛśyaitad aśeṣeṇa yathecchasi tathā kuru

sarvaguhyatamaṃ bhūyaḥ śṛṇu me paramaṃ vacaḥ
iṣṭo 'si me dṛḍham iti tato vakṣyāmi te hitam

manmanā bhava madbhakto madyājī māṃ namaskuru
mām evaiṣyasi satyaṃ te pratijāne priyo 'si me

sarvadharmān parityajya mām ekaṃ śaraṇaṃ vraja
ahaṃ tvā sarvapāpebhyo mokṣayiṣyāmi mā śucaḥ

idaṃ te nātapaskāya nābhaktāya kadā cana
na cāśuśrūṣave vācyaṃ na ca māṃ yo 'bhyasūyati

ya idaṃ paramaṃ guhyaṃ madbhakteṣv abhidhāsyati
bhaktiṃ mayi parāṃ kṛtvā mām evaiṣyaty asaṃśayaḥ

na ca tasmān manuṣyeṣu kaś cin me priyakṛttamaḥ
bhavitā na ca me tasmād anyaḥ priyataro bhuvi

adhyeṣyate ca ya imaṃ dharmyaṃ saṃvādam āvayoḥ
jñānayajñena tenāham iṣṭaḥ syām iti me matiḥ

śraddhāvān anasūyaś ca śṛṇuyād api yo naraḥ
so 'pi muktaḥ śubhāṃl lokān prāpnuyāt puṇyakarmaṇām

kaccid etac chrutaṃ pārtha tvayaikāgreṇa cetasā
kaccid ajñānasaṃmohaḥ pranaṣṭas te dhanaṃjaya

arjuna uvāca
naṣṭo mohaḥ smṛtir labdhā tvatprasādān mayācyuta
sthito 'smi gatasaṃdehaḥ kariṣye vacanaṃ tava

saṃjaya uvāca
ity ahaṃ vāsudevasya pārthasya ca mahātmanaḥ
saṃvādam imam aśrauṣam adbhutaṃ romaharṣaṇam

vyāsaprasādāc chrutavān etad guhyam ahaṃ param
yogaṃ yogeśvarāt kṛṣṇāt sākṣāt kathayataḥ svayam

rājan saṃsmṛtya saṃsmṛtya saṃvādam imam adbhutam
keśavārjunayoḥ puṇyaṃ hṛṣyāmi ca muhur muhuḥ

tac ca saṃsmṛtya saṃsmṛtya rūpam atyadbhutaṃ hareḥ
vismayo me mahān rājan hṛṣyāmi ca punaḥ punaḥ

yatra yogeśvaraḥ kṛṣṇo yatra pārtho dhanurdharaḥ
tatra śrīr vijayo bhūtir dhruvā nītir matir mama

