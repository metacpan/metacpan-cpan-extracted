// 45UNqWe - pokr.c written by Pip Stuart <Pip@CPAN.Org> to run through
//   Texas Hold'Em Poker hands && output XML to query for odds.
// Please e-mail me if you'd like the header file (pdat.h) needed to
//   compile this.  It's 6MB so I didn't package it with my
//   Games::Cards::Poker.pm but I'd be glad to ftp it to you if you have
//   an anonymous account somewhere && want it.  The file is that big
//   because I traded (wasted) space for speed.  I wanted to be able to
//   just look up any score as fast as possible && this approach was the
//   best I came up with.
// This code is distributed under the GNU General Public License (version 2).
// 2do:
//   port all necessary functions
//   + char* SortCards(char* hand) returns char[7]
//   + char* ShortHand(char* hand) returns char[7]
//   + int   ScoreHand(char* shrt)  loop through backwards
//   + int   RemoveCard(int  indx, char* deck)  just substr?
//   + int     FindCard(char card, char* deck)
//   + char* BestHand(char* hole, char* bord) returns char[6] hand
//   + ChooseSubsets as a fast function
//   + replace all char* functions to use own global pre-calloc'd mem
//   + mk the Choose variables global so it can pickup where it left
//      off && RemoveCard can be given global indices after
//   + mk specific versions of ChooseFlop, ChooseOpponentHole
//   + tk 2nd main param as which flop subset to do
//   + mk hole && flop shorthand datas && funcs to find index
//   + turn flop subset into shorthand && index
//   + loop turn && rivers finding shorthand index
//   + go through every possible flop
//   + ch BestHand to be BestScore for comparison
//   + fill data in inner loop
//   + benchmrk... probably about 2.5 hours per hole+flop
//   + dump results to XML file per hole+flop
//   + pre-calc totals for each step
//   + setup some benchmarking shell
//   + optimize!
//   + mk ScoreHands faster... some sort of hash?
//   + optimize!!!
//   + ScoreHands binary search                               162secs/flop
//   + ScoreHands index all chars for direct scores           107secs/flop
//   + profile: `cc -pg -c pokr.c`, `cc -pg pokr.o` > *a.out, `a.out`, `gprof`
//   + imp QuickSort as ifs up to 5
//   + mv big data to separate file to include
//   + gen hole data same as hand && mk FindHole fast too
//   + mk ShortHand faster
//   + replace ChooseFlop with selection of pre-calc'd flop groups 2do at once
//   + fread progress to pickup where left off
//   + don't store unnecessary per ohole data
//   + rm hdek && other extraneous stuff like shrh?
//       bleh... for whatever reason /un!/ lines are useless but are faster?!?
//       must be some goofy word-boundary alignment crap or something
//   + mk separate ShortOne()
//   + mk hpnd auto-inc at end too
//   + only calc BestScore for main hole + board once
//   + fix bug in ShortHand where 'CG is a diff suit from 'ae'
//   + rewrite everything from scratch to use all integers 0..51
//   + fix mkPPX.pl to read h.ppx for ones to skip
//   + mk src test if it can read from first write of a hole && skip
//   + squash scoring bug && start all over
//   + updt web IF for XML
//    add oppo     calc 2 cgi
//    add pot-odds calc 2 cgi
//    setup timed runs again && test doing ShortHand inside of BestScore
//    port to local Tk app
//    profile && optimize
//    rewrite with exact cards && start over
// maybe 2do:
//    figure out which flops will be the same && do each unique only once
// ordr: ( * = doing, + = done&&sync'd, / = left partway done&&sync'd )
//      0+== AA : 25+== KK : 48+== QQ : 69+== JJ : 88+== TT :105+== 99 :
//    120+== 88 :  1+== AKs:  3+== AQs:133+== 77 :  5+== AJs:  2+== AK :
//      7+== ATs:  4+== AQ :  6+== AJ : 26+== KQs:  9+== A9s:  8+== AT :
//    144+== 66 : 28 == KJs: 30 == KTs: 13+== A7s: 17 == A5s: 15 == A6s:
//     49+== QJs: 12+== A8 :153+== 55 : 19 == A4s: 21 == A3s: 23 == A2s:
//     70+== JTs:160+== 44 : 89+== T9s:165+== 33 :106+== 98s:168+== 22 :
//
//    0 + AA  <hAA  w=  "35630168360" t=    "228046240" l=   "6093233400"/>
//    1 + AKs <hAKs w=  "27780084300" t=    "692219520" l=  "13479144180"/>
//    2 + AK  <hAK  w=  "27043697240" t=    "713756780" l=  "14191853600"/>
//    3 + AQs <hAQs w=  "27400042340" t=    "751068280" l=  "13800337380"/>
//    4 + AQ  <hAQ  w=  "26640715628" t=    "774467380" l=  "14534124612"/>
//    5 + AJs <hAJs w=  "27015734340" t=    "834882800" l=  "14100830860"/>
//    6 + AJ  <hAJ  w=  "26232271236" t=    "862591260" l=  "14854445124"/>
//    7 + ATs <hATs w=  "26634519240" t=    "934234920" l=  "14382693840"/>
//    8 + AT  <hAT  w=  "25826562664" t=    "967878980" l=  "15154865976"/>
//    9 + A9s <hA9s w=  "25804198800" t=   "1066859020" l=  "15080390180"/>
//   10 + A9  <hA9  w=  "24937887168" t=   "1110089900" l=  "15901330552"/>
//   11 + A8s <hA8s w=  "25383902100" t=   "1204846820" l=  "15362699080"/>
//   12 + A8  <hA8  w=  "24486663360" t=   "1257242580" l=  "16205401680"/>
//   13 + A7s <hA7s w=  "24913569000" t=   "1340169320" l=  "15697709680"/>
//   14 + A7  <hA7  w=  "23981299392" t=   "1402587960" l=  "16565420268"/>
//   15 + A6s <hA6s w=  "24406890120" t=   "1448944360" l=  "16095613520"/>
//   16 + A6  <hA6  w=  "23436262084" t=   "1520443560" l=  "16992601976"/>
//   17 + A5s <hA5s w=  "24358738860" t=   "1559592240" l=  "16033116900"/>
//   18 + A5  <hA5  w=  "23382559364" t=   "1639664260" l=  "16927083996"/>
//   19 + A4s <hA4s w=  "23970134160" t=   "1590661880" l=  "16390651960"/>
//   20 + A4  <hA4  w=  "22959091540" t=   "1675379060" l=  "17314837020"/>
//   21 + A3s <hA3s w=  "23633370720" t=   "1581793600" l=  "16736283680"/>
//   22 + A3  <hA3  w=  "22590943056" t=   "1669072180" l=  "17689292384"/>
//   23 + A2s <hA2s w=  "23285680020" t=   "1571196960" l=  "17094571020"/>
//   24 + A2  <hA2  w=  "22210021132" t=   "1662328820" l=  "18076957668"/>
//   25 + KK  <hKK  w=  "34449411160" t=    "233539200" l=   "7268497640"/>
//   26 + KQs <hKQs w=  "26181235800" t=    "832302840" l=  "14937909360"/>
//   27 + KQ  <hKQ  w=  "25350064816" t=    "858785800" l=  "15740457004"/>
//   28 + KJs <hKJs w=  "25790305720" t=    "915198880" l=  "15245943400"/>
//   29 + KJ  <hKJ  w=  "24934317824" t=    "945964800" l=  "16069024996"/>
//   30 + KTs <hKTs w=  "25417151100" t=   "1008087500" l=  "15526209400"/>
//   31 + KT  <hKT  w=  "24537058992" t=   "1044281480" l=  "16367967148"/>
//   32 + K9s <hK9s w=  "24599548580" t=   "1132971060" l=  "16218928360"/>
//   33 + K9  <hK9  w=  "23661683096" t=   "1178232500" l=  "17109392024"/>
//   34 + K8s <hK8s w=  "23824399360" t=   "1276951600" l=  "16850097040"/>
//   35 + K8  <hK8  w=  "22832718300" t=   "1332830240" l=  "17783759080"/>
//   36 + K7s <hK7s w=  "23428340280" t=   "1419147500" l=  "17103960220"/>
//   37 + K7  <hK7  w=  "22407202492" t=   "1485099780" l=  "18057005348"/>
//   38 + K6s <hK6s w=  "22991353240" t=   "1540510940" l=  "17419583820"/>
//   39 + K6  <hK6  w=  "21937259184" t=   "1616102740" l=  "18395945696"/>
//   40 + K5s <hK5s w=  "22584080480" t=   "1643712700" l=  "17723654820"/>
//   41 + K5  <hK5  w=  "21499620416" t=   "1728446140" l=  "18721241064"/>
//   42 + K4s <hK4s w=  "22187635680" t=   "1674528180" l=  "18089284140"/>
//   43 + K4  <hK4  w=  "21068039392" t=   "1763905460" l=  "19117362768"/>
//   44 + K3s <hK3s w=  "21844172260" t=   "1665346160" l=  "18441929580"/>
//   45 + K3  <hK3  w=  "20693039508" t=   "1757283580" l=  "19498984532"/>
//   46 + K2s <hK2s w=  "21495901900" t=   "1654377280" l=  "18801168820"/>
//   47 + K2  <hK2  w=  "20311918144" t=   "1750165340" l=  "19887224136"/>
//   48 + QQ  <hQQ  w=  "33406772880" t=    "245981520" l=   "8298693600"/>
//   49 + QJs <hQJs w=  "24781087880" t=    "997042460" l=  "16173317660"/>
//   50 + QJ  <hQJ  w=  "23870847932" t=   "1030711860" l=  "17047747828"/>
//   51 + QTs <hQTs w=  "24403425700" t=   "1088153040" l=  "16459869260"/>
//   52 + QT  <hQT  w=  "23468599860" t=   "1127145620" l=  "17353562140"/>
//   53 + Q9s <hQ9s w=  "23586277160" t=   "1209481560" l=  "17155689280"/>
//   54 + Q9  <hQ9  w=  "22593750384" t=   "1257227020" l=  "18098330216"/>
//   55 + Q8s <hQ8s w=  "22828727280" t=   "1343045680" l=  "17779675040"/>
//   56 + Q8  <hQ8  w=  "21783465748" t=   "1400566000" l=  "18765275872"/>
//   57 + Q7s <hQ7s w=  "22034363120" t=   "1492445180" l=  "18424639700"/>
//   58 + Q7  <hQ7  w=  "20933463432" t=   "1561685740" l=  "19454158448"/>
//   59 + Q6s <hQ6s w=  "21680191240" t=   "1622113380" l=  "18649143380"/>
//   60 + Q6  <hQ6  w=  "20552601444" t=   "1701174420" l=  "19695531756"/>
//   61 + Q5s <hQ5s w=  "21275026680" t=   "1725010580" l=  "18951410740"/>
//   62 + Q5  <hQ5  w=  "20117354816" t=   "1813211100" l=  "20018741704"/>
//   63 + Q4s <hQ4s w=  "20876314700" t=   "1755470740" l=  "19319662560"/>
//   64 + Q4  <hQ4  w=  "19683478432" t=   "1848312580" l=  "20417516608"/>
//   65 + Q3s <hQ3s w=  "20530371340" t=   "1745882640" l=  "19675194020"/>
//   66 + Q3  <hQ3  w=  "19305970608" t=   "1841281740" l=  "20802055272"/>
//   67 + Q2s <hQ2s w=  "20179408280" t=   "1734456920" l=  "20037582800"/>
//   68 + Q2  <hQ2  w=  "18922128724" t=   "1833703420" l=  "21193475476"/>
//   69 + JJ  <hJJ  w=  "32366792080" t=    "265547120" l=   "9319108800"/>
//   70 + JTs <hJTs w=  "23557743720" t=   "1152050680" l=  "17241653600"/>
//   71 + JT  <hJT  w=  "22578648348" t=   "1192845740" l=  "18177813532"/>
//   72 + J9s <hJ9s w=  "22700761020" t=   "1300902740" l=  "17949784240"/>
//   73 + J9  <hJ9  w=  "21661327772" t=   "1352360420" l=  "18935619428"/>
//   74 + J8s <hJ8s w=  "21945495940" t=   "1429697880" l=  "18576254180"/>
//   75 + J8  <hJ8  w=  "20853458976" t=   "1490539640" l=  "19605309004"/>
//   76 + J7s <hJ7s w=  "21166375700" t=   "1569255340" l=  "19215816960"/>
//   77 + J7  <hJ7  w=  "20019662720" t=   "1640975360" l=  "20288669540"/>
//   78 + J6s <hJ6s w=  "20377599020" t=   "1704623600" l=  "19869225380"/>
//   79 + J6  <hJ6  w=  "19175351424" t=   "1787747580" l=  "20986208616"/>
//   80 + J5s <hJ5s w=  "20061578720" t=   "1817256920" l=  "20072612360"/>
//   81 + J5  <hJ5  w=  "18836009916" t=   "1909831540" l=  "21203466164"/>
//   82 + J4s <hJ4s w=  "19662084860" t=   "1847361760" l=  "20442001380"/>
//   83 + J4  <hJ4  w=  "18401429372" t=   "1944575180" l=  "21603303068"/>
//   84 + J3s <hJ3s w=  "19315180880" t=   "1837367580" l=  "20798899540"/>
//   85 + J3  <hJ3  w=  "18023038828" t=   "1937135380" l=  "21989133412"/>
//   86 + J2s <hJ2s w=  "18963078460" t=   "1825485020" l=  "21162884520"/>
//   87 + J2  <hJ2  w=  "17638135664" t=   "1929096980" l=  "22382074976"/>
//   88 + TT  <hTT  w=  "31321062200" t=    "294931320" l=  "10335454480"/>
//   89 + T9s <hT9s w=  "21972856840" t=   "1384947500" l=  "18593643660"/>
//   90 + T9  <hT9  w=  "20896265440" t=   "1439754220" l=  "19613287960"/>
//   91 + T8s <hT8s w=  "21189318860" t=   "1531414920" l=  "19230714220"/>
//   92 + T8  <hT8  w=  "20058247304" t=   "1596813580" l=  "20294246736"/>
//   93 + T7s <hT7s w=  "20409896960" t=   "1667825080" l=  "19873725960"/>
//   94 + T7  <hT7  w=  "19224109288" t=   "1743814240" l=  "20981384092"/>
//   95 + T6s <hT6s w=  "19633360540" t=   "1795923140" l=  "20522164320"/>
//   96 + T6  <hT6  w=  "18392783072" t=   "1882679180" l=  "21673845368"/>
//   97 + T5s <hT5s w=  "18852571840" t=   "1910664980" l=  "21188211180"/>
//   98 + T5  <hT5  w=  "17557676976" t=   "2008194020" l=  "22383436624"/>
//   99 + T4s <hT4s w=  "18544247180" t=   "1951937300" l=  "21455263520"/>
//  100 + T4  <hT4  w=  "17221189872" t=   "2054546500" l=  "22673571248"/>
//  101/+ T3s <hT3s w=  "18197901900" t=   "1941537040" l=  "21812009060"/>
//  102/+ T3  <hT3  w=  "16843541828" t=   "2046697740" l=  "23059068052"/>
//  103 + T2s <hT2s w=  "17846213460" t=   "1929197640" l=  "22176036900"/>
//  104/+ T2  <hT2  w=  "16459236624" t=   "2038199260" l=  "23451871736"/>
//  105 + 99  <h99  w=  "30064778720" t=    "328563720" l=  "11558105560"/>
//  106 + 98s <h98s w=  "20495914380" t=   "1631476200" l=  "19824057420"/>
//  107/+ 98  <h98  w=  "19324192212" t=   "1702138580" l=  "20922976828"/>
//  108 + 97s <h97s w=  "19713106960" t=   "1784984920" l=  "20453356120"/>
//  109 + 97  <h97  w=  "18486727076" t=   "1867465880" l=  "21595114664"/>
//  110 + 96s <h96s w=  "18941568320" t=   "1910572840" l=  "21099306840"/>
//  111 + 96  <h96  w=  "17660842900" t=   "2003561060" l=  "22284903660"/>
//  112 + 95s <h95s w=  "18170307940" t=   "2021360980" l=  "21759779080"/>
//  113 + 95  <h95  w=  "16835795264" t=   "2124775760" l=  "22988736596"/>
//  114 + 94s <h94s w=  "17370887540" t=   "2059688680" l=  "22520871780"/>
//  115 + 94  <h94  w=  "15975402612" t=   "2169106260" l=  "23804798748"/>
//  116 + 93s <h93s w=  "17119038980" t=   "2061887260" l=  "22770521760"/>
//  117 + 93  <h93  w=  "15699411648" t=   "2174427900" l=  "24075468072"/>
//  118 + 92s <h92s w=  "16769233260" t=   "2049091020" l=  "23133123720"/>
//  119 + 92  <h92  w=  "15317275564" t=   "2165469340" l=  "24466562716"/>
//  120 + 88  <h88  w=  "28827936960" t=    "373915800" l=  "12749595240"/>
//  121/+ 87s <h87s w=  "19165144740" t=   "1889688220" l=  "20896615040"/>
//  122 + 87  <h87  w=  "17908314924" t=   "1978025960" l=  "22062966736"/>
//  123 + 86s <h86s w=  "18382499940" t=   "2034442240" l=  "21534505820"/>
//  124 + 86  <h86  w=  "17070666328" t=   "2134755960" l=  "22743885332"/>
//  125 + 85s <h85s w=  "17615605920" t=   "2143327060" l=  "22192515020"/>
//  126 + 85  <h85  w=  "16250384012" t=   "2253845760" l=  "23445077848"/>
//  127 + 84s <h84s w=  "16823696260" t=   "2180509420" l=  "22947242320"/>
//  128 + 84  <h84  w=  "15397889040" t=   "2296942060" l=  "24254476520"/>
//  129 + 83s <h83s w=  "16060089300" t=   "2173875040" l=  "23717483660"/>
//  130 + 83  <h83  w=  "14575924768" t=   "2293874460" l=  "25079508392"/>
//  131 + 82s <h82s w=  "15806979280" t=   "2175109000" l=  "23969359720"/>
//  132 + 82  <h82  w=  "14297778444" t=   "2299647860" l=  "25351881316"/>
//  133 + 77  <h77  w=  "27572737560" t=    "428466200" l=  "13950244240"/>
//  134 + 76s <h76s w=  "17967585600" t=   "2133054980" l=  "21850807420"/>
//  135 + 76  <h76  w=  "16633208096" t=   "2239313780" l=  "23076785744"/>
//  136 + 75s <h75s w=  "17191286000" t=   "2262468080" l=  "22497693920"/>
//  137 + 75  <h75  w=  "15802935420" t=   "2380563980" l=  "23765808220"/>
//  138 + 74s <h74s w=  "16406753420" t=   "2299277780" l=  "23245416800"/>
//  139 + 74  <h74  w=  "14958471448" t=   "2423198760" l=  "24567637412"/>
//  140 + 73s <h73s w=  "15649382080" t=   "2292545480" l=  "24009520440"/>
//  141 + 73  <h73  w=  "14143011596" t=   "2420050100" l=  "25386245924"/>
//  142 + 72s <h72s w=  "14867525140" t=   "2278849340" l=  "24805073520"/>
//  143 + 72  <h72  w=  "13300781444" t=   "2410838400" l=  "26237687776"/>
//  144 + 66  <h66  w=  "26303567800" t=    "490600880" l=  "15157279320"/>
//  145/+ 65s <h65s w=  "16926648900" t=   "2336862380" l=  "22687936720"/>
//  146 + 65  <h65  w=  "15525246608" t=   "2459652900" l=  "23964408112"/>
//  147 + 64s <h64s w=  "16143327200" t=   "2393197280" l=  "23414923520"/>
//  148 + 64  <h64  w=  "14682120456" t=   "2523379180" l=  "24743807984"/>
//  149 + 63s <h63s w=  "15390068980" t=   "2389663720" l=  "24171715300"/>
//  150 + 63  <h63  w=  "13871115284" t=   "2523666260" l=  "25554526076"/>
//  151 + 62s <h62s w=  "14614855720" t=   "2375640340" l=  "24960951940"/>
//  152 + 62  <h62  w=  "13035805892" t=   "2514135720" l=  "26399366008"/>
//  153 + 55  <h55  w=  "25019858440" t=    "574638440" l=  "16356951120"/>
//  154/+ 54s <h54s w=  "16164954960" t=   "2450710260" l=  "23335782780"/>
//  155 + 54  <h54  w=  "14712254804" t=   "2584600880" l=  "24652451936"/>
//  156 + 53s <h53s w=  "15420797140" t=   "2461950680" l=  "24068700180"/>
//  157 + 53  <h53  w=  "13911049692" t=   "2600813440" l=  "25437444488"/>
//  158 + 52s <h52s w=  "14653445820" t=   "2449790660" l=  "24848211520"/>
//  159 + 52  <h52  w=  "13084113660" t=   "2593302740" l=  "26271891220"/>
//  160 + 44  <h44  w=  "23600422200" t=    "642953960" l=  "17708071840"/>
//  161 + 43s <h43s w=  "14988144060" t=   "2445425640" l=  "24517878300"/>
//  162 + 43  <h43  w=  "13450139072" t=   "2583863860" l=  "25915304688"/>
//  163 + 42s <h42s w=  "14229068800" t=   "2442472320" l=  "25279906880"/>
//  164 + 42  <h42  w=  "12632547980" t=   "2586175460" l=  "26730584180"/>
//  165 + 33  <h33  w=  "22166824880" t=    "716396280" l=  "19068226840"/>
//  166 + 32s <h32s w=  "13882561260" t=   "2426856860" l=  "25642029880"/>
//  167 + 32  <h32  w=  "12264232300" t=   "2570598900" l=  "27114476420"/>
//  168 + 22  <h22  w=  "20717796440" t=    "796106800" l=  "20437544760"/>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "pdat.h"

// Debug printing flag
//#define DBUG

const unsigned int   mjvr =  1;            // MaJor   VeRsion number
const unsigned int   mnvr =  0;            // MiNor   VeRsion number
const unsigned char *ptvr = "46QCejV";     // PipTime VeRsion string
const unsigned char *auth = "Pip Stuart <Pip@CPAN.Org>"; // me =)
const unsigned char *rnkz = "AKQJT98765432";
      unsigned char *fprm = "";            // flop index parameter
      unsigned char *hprm = "";            // hole index parameter
      unsigned int   fpnd =  0;            // actual flop index
      unsigned int   hpnd =  0;            // actual hole index
      unsigned int   rslt[741][13][13][3]; // fat results data  ~1.5MB
      unsigned int   bord[7];              // community board cards
      unsigned int   shnd[6];              // short/score hand indices
      unsigned int   fndx;                 // chosen flop shorthand index

void usag() { // display command usage && exit w/ error status
  fprintf(stderr, 
    " pokr v%d.%d.%s - by %s\n\n", mjvr, mnvr, ptvr, auth);
  fprintf(stderr, 
    "usage: pokr <HoleIndex> <FlopIndex>\n");
  exit(1);
}

void SortCards() { // sorts global shnd[5] quickly
  unsigned int swap;
  if(shnd[0] > shnd[1]) { swap = shnd[0]; shnd[0] = shnd[1]; shnd[1] = swap;}
  if(shnd[3] > shnd[4]) { swap = shnd[3]; shnd[3] = shnd[4]; shnd[4] = swap;}
  if(shnd[1] > shnd[3]) {
                            swap = shnd[1]; shnd[1] = shnd[3]; shnd[3]=swap;
    if(shnd[0] > shnd[1]) { swap = shnd[0]; shnd[0] = shnd[1]; shnd[1]=swap;}
    if(shnd[3] > shnd[4]) { swap = shnd[3]; shnd[3] = shnd[4]; shnd[4]=swap;}
    if(shnd[1] > shnd[3]) { swap = shnd[1]; shnd[1] = shnd[3]; shnd[3]=swap;}
  }
  if       (shnd[2] > shnd[3]) {
                            swap = shnd[2]; shnd[2] = shnd[3]; shnd[3]=swap;
    if(shnd[3] > shnd[4]) { swap = shnd[3]; shnd[3] = shnd[4]; shnd[4]=swap;}
  } else if(shnd[1] > shnd[2]) {
                            swap = shnd[1]; shnd[1] = shnd[2]; shnd[2]=swap;
    if(shnd[0] > shnd[1]) { swap = shnd[0]; shnd[0] = shnd[1]; shnd[1]=swap;}
  }
}

void ShortHand() { // uses global shnd[5] cards && assigns indices of 'AKQJTs'
  unsigned int fsut = rkst[shnd[0]][1], sutd = 1, ndxc;
  SortCards();
  for(ndxc = 0; ndxc < 5; ndxc++) {
    if(fsut != rkst[shnd[ndxc]][1]) { sutd = 0; }
    shnd[ndxc] = rkst[shnd[ndxc]][0];
  }
  if(sutd) { shnd[5] = 0; }
  else     { shnd[5] = 1; }
}

unsigned int BestScore() {
  int bscr = 7462; int tndx, cndx, tscr = bscr;

  for(tndx = 0; tndx < 21; tndx++) {  // loop through best sets
    for(cndx = 0; cndx < 5; cndx++) { // loop through cards
      shnd[cndx] = bord[bnds[tndx][cndx]];
    }
    ShortHand();
    tscr = hndi[shnd[0]][shnd[1]][shnd[2]][shnd[3]][shnd[4] - 1][shnd[5]];
    if(tscr < bscr) { bscr = tscr; }
  }
  return(bscr);
}

void LoadProgressIndex() {                   // read progress.txt
  FILE *fptr = fopen("progress.txt", "r"); int tmph, tmpf;
  if(fptr) {
    fseek(fptr, 5, SEEK_SET);
    fscanf(fptr, "%3d", &tmph);
    hpnd = (char)tmph;
    fseek(fptr, 6, SEEK_CUR);
    fscanf(fptr, "%5d", &tmpf);
    fpnd = (short)tmpf;
    fclose(fptr);
  }
}

void WriteProgressIndex(int indx) { // dump progress.txt
  FILE *fptr = fopen("progress.txt", "w");
  if(fptr) {
    fprintf(fptr, "hpnd:%3d fpnd:%5d", hpnd, indx + 1);
    fclose(fptr);
  }
}

unsigned int ReadFlopXML() { // check if flop XML file can be read from
  unsigned int wndx = 0; char fnam[31]; FILE *fptr;
  fnam[wndx++] = 'h';
  fnam[wndx++] = holz[hpnd][0];
  fnam[wndx++] = holz[hpnd][1];
  if((int)strlen(holz[hpnd]) == 3) { fnam[wndx++] = holz[hpnd][2]; }
  fnam[wndx++] = '/';//'\\';
  fnam[wndx++] = 'f';
  fnam[wndx++] = flpz[fndx][0];
  fnam[wndx++] = flpz[fndx][1];
  fnam[wndx++] = flpz[fndx][2];
  if((int)strlen(flpz[fndx]) == 4) { fnam[wndx++] = flpz[fndx][3]; }
  fnam[wndx++] = '.';
  fnam[wndx++] = 'p';
  fnam[wndx++] = 'p';
  fnam[wndx++] = 'x'; // adding .ppx filename extension (for Pip's Poker XML)
  fnam[wndx] = '\0';  // null-terminate
  fptr = fopen(fnam, "r");
  if(fptr) { wndx = 1; fclose(fptr); }
  else     { wndx = 0; }
  return(wndx);
}

void WriteFlopXML() { // dump data to the flop XML file
  unsigned int jndx, kndx, lndx, wndx = 0; char fnam[31]; FILE *fptr;
  unsigned int totr[13][13][3];
  unsigned int tott[13][3];
  unsigned int totl[3];
  fnam[wndx++] = 'h';
  fnam[wndx++] = holz[hpnd][0];
  fnam[wndx++] = holz[hpnd][1];
  if((int)strlen(holz[hpnd]) == 3) { fnam[wndx++] = holz[hpnd][2]; }
//  printf("mkdir %s\n", fnam); // mkdir taken care of by mkHoleDirz.pl
  fnam[wndx++] = '/';//'\\';
  fnam[wndx++] = 'f';
  fnam[wndx++] = flpz[fndx][0];
  fnam[wndx++] = flpz[fndx][1];
  fnam[wndx++] = flpz[fndx][2];
  if((int)strlen(flpz[fndx]) == 4) { fnam[wndx++] = flpz[fndx][3]; }
  fnam[wndx++] = '.';
  fnam[wndx++] = 'p';
  fnam[wndx++] = 'p';
  fnam[wndx++] = 'x'; // adding .ppx filename extension (for Pip's Poker XML)
  fnam[wndx] = '\0';  // null-terminate
  printf("mkfil %s\n", fnam);
  for(    jndx = 0; jndx <  13; jndx++) { // init totals empty
    for(  kndx = 0; kndx <  13; kndx++) {
      for(lndx = 0; lndx <   3; lndx++) { totr[jndx][kndx][lndx] = 0; }
    }
    for(  lndx = 0; lndx <   3; lndx++) { tott[jndx][lndx] = 0; }
  }
  for(    lndx = 0; lndx <   3; lndx++) { totl[lndx] = 0; }
  for(    jndx = 0; jndx <  13; jndx++) { // pre-calc totals
    for(  kndx = 0; kndx <  13; kndx++) {
      for(lndx = 0; lndx <   3; lndx++) {
        totr[jndx][kndx][lndx] = rslt[fndx][jndx][kndx][lndx];
      }
      for(lndx = 0; lndx <   3; lndx++) {
        tott[jndx][lndx] += totr[jndx][kndx][lndx];
      }
    }
    for(  lndx = 0; lndx <   3; lndx++) {
      totl[lndx] += tott[jndx][lndx];
    }
  }
  fptr = fopen(fnam, "w");
  fprintf(fptr, "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n");
  fprintf(fptr, "<f%-4s w=\"%d\" t=\"%d\" l=\"%d\">\n", flpz[fndx], totl[0], totl[1], totl[2]);
  for(    jndx = 0; jndx <  13; jndx++) {
    if(tott[jndx][0] ||
       tott[jndx][1] ||
       tott[jndx][2]) {
      fprintf(fptr, "  <t%c w=\"%d\" t=\"%d\" l=\"%d\">\n", rnkz[jndx],
       tott[jndx][0],
       tott[jndx][1],
       tott[jndx][2]);
      for(kndx = 0; kndx <  13; kndx++) {
        if(totr[jndx][kndx][0] ||
           totr[jndx][kndx][1] ||
           totr[jndx][kndx][2]) {
          fprintf(fptr, "    <r%c w=\"%d\" t=\"%d\" l=\"%d\"/>\n", rnkz[kndx],
           totr[jndx][kndx][0],
           totr[jndx][kndx][1],
           totr[jndx][kndx][2]);
        }
      }
      fprintf(fptr, "  </t%c>\n", rnkz[jndx]);
    }
  }
  fprintf(fptr, "</f%s>", flpz[fndx]);
  fclose(fptr);
}

int main(int argc, char *argv[]) {
  unsigned int indx, jndx, kndx, lndx, mndx, mscr, oscr;
  unsigned int flim = 22100; // (22100|19600)
  if     (argc >  3) { usag();            }     // call usage if wrong arg#
  else if(argc == 3) { fprm = argv[2];          // save flop index param
                       hprm = argv[1];          // save hole index param
                       fpnd = atoi(fprm);       // obtain integer flop index
                       hpnd = atoi(hprm); }     // obtain integer hole index
  else if(argc == 2) { hprm = argv[1];          // save hole index param
                       hpnd = atoi(hprm); }     // obtain integer index
  else               { LoadProgressIndex(); }   // load last progress 4!params
//hpnd = 0; fpnd = 0; flim = 25; if(1) {
  while(hpnd < 169) {
    for(      indx = 0; indx < 741; indx++) {
      for(    jndx = 0; jndx <  13; jndx++) {
        for(  kndx = 0; kndx <  13; kndx++) {
          for(lndx = 0; lndx <   3; lndx++) {
            rslt[indx][jndx][kndx][lndx] = 0; // init empty results
          }
        }
      }
    }
    printf("Running hole index:%3d flop index:%5d...\n", hpnd, fpnd);
    for(indx = fpnd; indx < flim; indx++) { // flops up to flop-limit
      if(flpg[indx][0] != hoiz[hpnd][0] && flpg[indx][0] != hoiz[hpnd][1] &&
         flpg[indx][1] != hoiz[hpnd][0] && flpg[indx][1] != hoiz[hpnd][1] &&
         flpg[indx][2] != hoiz[hpnd][0] && flpg[indx][2] != hoiz[hpnd][1]) {
        fndx = flpg[indx][3];
        bord[0] = flpg[indx][0];
        bord[1] = flpg[indx][1];
        bord[2] = flpg[indx][2];
        for(jndx = 0; jndx < 52; jndx++) {
          if(jndx != hoiz[hpnd][0] && jndx != hoiz[hpnd][1] &&
             jndx != flpg[indx][0] && jndx != flpg[indx][1] &&
             jndx != flpg[indx][2]) {
            bord[3] = jndx;
            for(kndx = 0; kndx < 52; kndx++) {
              if(kndx != hoiz[hpnd][0] && kndx != hoiz[hpnd][1] &&
                 kndx != flpg[indx][0] && kndx != flpg[indx][1] &&
                 kndx != flpg[indx][2] && kndx != jndx) {
                bord[4] = kndx;
                bord[5] = hoiz[hpnd][0];
                bord[6] = hoiz[hpnd][1];
                mscr = BestScore();
                for(lndx = 0; lndx < 51; lndx++) {
                  if(lndx != hoiz[hpnd][0] && lndx != hoiz[hpnd][1] &&
                     lndx != flpg[indx][0] && lndx != flpg[indx][1] &&
                     lndx != flpg[indx][2] && lndx != jndx && lndx != kndx) {
                    bord[5] = lndx;
                    for(mndx = lndx + 1; mndx < 52; mndx++) {
                      if(mndx != hoiz[hpnd][0] && mndx != hoiz[hpnd][1] &&
                         mndx != flpg[indx][0] && mndx != flpg[indx][1] &&
                         mndx != flpg[indx][2] && mndx != jndx && mndx !=kndx){
                        bord[6] = mndx;
                        oscr = BestScore();
                        if       (mscr <  oscr) { // win
                          rslt[fndx][rkst[jndx][0]][rkst[kndx][0]][0]++;
                        } else if(mscr == oscr) { // tie
                          rslt[fndx][rkst[jndx][0]][rkst[kndx][0]][1]++;
                        } else                  { // loss
                          rslt[fndx][rkst[jndx][0]][rkst[kndx][0]][2]++;
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        printf("Completed: hpnd:%3d shrh:%-3s fndx:%5d shrf:%s\n",
                           hpnd,    holz[hpnd], indx,  flpz[fndx]);
        if(indx == 22099 || fndx != flpg[indx + 1][3]) {
          WriteProgressIndex(indx);    // write out latest progress
          mndx = ReadFlopXML();        // try to read the XML file first
          if(mndx) { indx = flim; }    // if it's readable, skip to next
          else     { WriteFlopXML(); } // write out XML for completed flop set
//return(0); // test just a single block
        }
      }
    }
    hpnd++; fpnd = 0;
  }
  return(0);                                    //   && exit
}
