package Lingua::ZH::PinyinConvert::ID;

use 5.010001;
use strict;
use warnings;

our $VERSION = '0.04'; # VERSION

# notes:

# * for 'w' as alternative spelling to 'u'/'o', only those occuring
# after vowel is listed (e.g. taw, but not khwai), except kwa/kwe/kwi
# and hwaX (commonly encountered)

my %hy2id = (
    a      => 'a',
    ai     => 'ai',
    an     => 'an',
    ang    => 'ang',
    ao     => ['au', 'ao', 'aw'],

    ba     => 'pa',
    bai    => 'pai',
    ban    => 'pan',
    bang   => 'pang',
    bao    => ['pau', 'pao', 'paw'],
    bei    => 'pei',
    ben    => 'pen',
    beng   => 'peng',
    bi     => 'pi',
    bian   => 'pien',
    biao   => ['piau', 'piao', 'piaw'],
    bie    => 'pie',
    bin    => 'pin',
    bing   => 'ping',
    bo     => ['po', 'puo'], #pwo
    bu     => 'pu',

    ca     => 'cha',
    cai    => 'chai',
    can    => 'chan',
    cang   => 'chang',
    cao    => ['chau', 'chao', 'chaw'],
    ce     => 'che',
    cen    => 'chen',
    ceng   => 'cheng',
    cha    => 'cha',
    chai   => 'chai',
    chan   => 'chan',
    chang  => 'chang',
    chao   => ['chau', 'chao', 'chaw'],
    che    => 'che',
    chen   => 'chen',
    cheng  => 'cheng',
    chi    => 'che',
    chong  => 'chung',
    chou   => ['chou', 'chow', 'cheu'], # chEw
    chu    => 'chu',
    chuai  => ['chuai'],# 'chwai'],
    chuan  => ['chuan'],# 'chwan'],
    chuang => ['chuang'],# 'chwang'],
    chui   => ['chuei'],# 'chwei'],
    chun   => ['chuen'],# 'chwen'],
    chuo   => ['chuo'],# 'chwo'],
    ci     => 'che',
    cong   => 'chung',
    cou    => ['chou', 'chow', 'chew'], # chEw
    cu     => 'chu',
    cuan   => ['chuan'],# 'chwan'],
    cui    => ['chuei'],# 'chwei'],
    cun    => ['chuen'],# 'chwen'],
    cuo    => ['chuo'],# 'chwo'],

    da     => 'ta',
    dai    => 'tai',
    dan    => 'tan',
    dang   => 'tang',
    dao    => ['tau', 'tao', 'taw'],
    de     => 'te',
    dei    => 'tei',
    deng   => 'teng',
    di     => 'ti',
    dian   => 'tien',
    diao   => ['tiau', 'tiao', 'tiaw'],
    die    => 'tie',
    ding   => 'ting',
    diu    => 'tiu',
    dong   => 'tung',
    dou    => ['tou', 'tow', 'teu', 'tew'],
    du     => 'tu',
    duan   => ['tuan'],# 'twan'],
    dui    => ['tuei'],# 'twei'],
    dun    => ['tuen'],# 'twen'],
    duo    => 'tuo', # two

    e      => 'e',
    en     => 'en',
    er     => ['er', 'el'],

    fa     => 'fa',
    fan    => 'fan',
    fang   => 'fang',
    fei    => 'fei',
    fen    => 'fen',
    feng   => 'feng',
    fo     => ['fo', 'fuo'], # fwo
    fou    => ['fou', 'fow'],
    fu     => 'fu',

    ga     => 'ka',
    gai    => 'kai',
    gan    => 'kan',
    gang   => 'kang',
    gao    => ['kau', 'kao', 'kaw'],
    ge     => 'ke',
    gei    => 'kei',
    gen    => 'ken',
    geng   => 'keng',
    gong   => 'kung',
    gou    => ['kou', 'kow', 'keu'], # kEw
    gu     => 'ku',
    gua    => ['kua', 'kwa'],
    guai   => ['kuai', 'kwai'],
    guan   => ['kuan', 'kwan'],
    guang  => ['kuang', 'kwang'],
    gui    => ['kuei', 'kwei'],
    gun    => ['kuen'],# 'kwen'],
    guo    => ['kuo'],# 'kwo'],

    ha     => 'ha',
    hai    => 'hai',
    han    => 'han',
    hang   => 'hang',
    hao    => ['hau', 'hao', 'haw'],
    he     => 'he',
    hei    => 'hei',
    hen    => 'hen',
    heng   => 'heng',
    hong   => 'hung',
    hou    => ['hou', 'how', 'heu'], # hEw
    hu     => 'hu',
    hua    => ['hua', 'hwa'],
    huai   => ['huai', 'hwai'],
    huan   => ['huan', 'hwan'],
    huang  => ['huang', 'hwang'],
    hui    => ['huei', 'hwei'],
    hun    => ['huen'],# 'hwen'],
    huo    => 'huo', # hwo

    ji     => 'ci',
    jia    => 'cia',
    jian   => 'cien',
    jiang  => 'ciang',
    jiao   => ['ciau', 'ciao', 'ciaw'],
    jie    => 'cie',
    jin    => 'cin',
    jing   => 'cing',
    jiong  => 'ciung',
    jiu    => 'ciu',
    ju     => 'cu', #?
    juan   => 'cien', #?
    jue    => 'cue', #?
    jun    => ['cun', 'cin'], #?

    ka     => 'kha',
    kai    => 'khai',
    kan    => 'khan',
    kang   => 'khang',
    kao    => ['khau', 'khao', 'khaw'],
    ke     => 'khe',
    ken    => 'khen',
    keng   => 'kheng',
    kong   => 'khung',
    kou    => ['khou', 'khow', 'kheu'], # khEw
    ku     => 'khu',
    kua    => ['khua'],# 'khwa'],
    kuai   => ['khuai'],# 'khwai'],
    kuan   => ['khuan'],# 'khwan'],
    kuang  => ['khuang'],# 'khwang'],
    kui    => ['khuei'],# 'khwei'],
    kun    => 'khuen', # khwen
    kuo    => 'khuo', # khwo

    la     => 'la',
    lai    => 'lai',
    lan    => 'lan',
    lang   => 'lang',
    lao    => ['lau', 'lao'],
    le     => 'le',
    lei    => 'lei',
    leng   => 'leng',
    li     => 'li',
    lia    => 'lia',
    lian   => 'lien',
    liang  => 'liang',
    liao   => ['liau', 'liao', 'liaw'],
    lie    => 'lie',
    lin    => 'lin',
    ling   => 'ling',
    liu    => 'liu',
    long   => 'lung',
    lou    => ['lou', 'low', 'leu'],#, 'lEw']
    lu     => 'lu',
    lv     => ['li'], # lu
    luan   => ['luan'], # lwan
    lve    => ['lie'], #'lue'], # lwe
    lun    => ['luen'], # lwen
    luo    => ['luo'], # lwo

    ma     => 'ma',
    mai    => 'mai',
    man    => 'man',
    mang   => 'mang',
    mao    => ['mau', 'mao', 'maw'],
    me     => 'me',
    mei    => 'mei',
    men    => 'men',
    meng   => 'meng',
    mi     => 'mi',
    mian   => 'mien',
    miao   => ['miau', 'miao', 'miaw'],
    mie    => 'mie',
    min    => 'min',
    ming   => 'ming',
    miu    => 'miu',
    mo     => ['mo', 'muo'], # mwo
    mou    => ['mou', 'mow'],
    mu     => 'mu',

    na     => 'na',
    nai    => 'nai',
    nan    => 'nan',
    nang   => 'nang',
    nao    => ['nau', 'nao'],
    ne     => 'ne',
    nei    => 'nei',
    nen    => 'nen',
    neng   => 'neng',
    ni     => 'ni',
    nian   => 'nien',
    niang  => 'niang',
    niao   => ['niau', 'niao'],
    nie    => 'nie',
    nin    => 'nin',
    ning   => 'ning',
    niu    => 'niu',
    nong   => 'nung',
    nou    => ['nou'], # now
    nu     => 'nu',
    nv     => ['ni'], # nu
    nuan   => 'nuan',
    nve    => 'nie', #nue?
    nuo    => 'nuo',

    o      => 'o',
    ou     => ['ou', 'ow'],

    pa     => 'pha',
    pai    => 'phai',
    pan    => 'phan',
    pang   => 'phang',
    pao    => ['phau', 'phao', 'phaw'],
    pei    => 'phei',
    pen    => 'phen',
    peng   => 'pheng',
    pi     => 'phi',
    pian   => 'phien',
    piao   => ['phiau', 'phiao', 'phiaw'],
    pie    => 'phie',
    pin    => 'phin',
    ping   => 'phing',
    po     => ['pho', 'phuo'],
    pou    => ['phou', 'phow'],
    pu     => 'phu',

    qi     => 'chi',
    qia    => 'chia',
    qian   => 'chien',
    qiang  => 'chiang',
    qiao   => ['chiau', 'chiao', 'chiaw'],
    qie    => 'chie',
    qin    => 'chin',
    qing   => 'ching',
    qiong  => 'chiung',
    qiu    => 'chiu',
    qu     => 'chi',
    quan   => 'chuen', #?
    que    => 'chue',
    qun    => 'chuen',

    ran    => ['ran', 'jan'],
    rang   => ['rang', 'jang'],
    rao    => ['rau', 'rao', 'raw', 'jau', 'jao', 'jaw'],
    re     => ['re', 'je'],
    ren    => ['ren', 'jen'],
    reng   => ['reng', 'jeng'],
    ri     => ['re', 'je'],
    rong   => ['rung', 'jung'],
    rou    => ['rou', 'row', 'jou', 'jow', 'reu', 'jeu'], # rEw
    ru     => ['ru', 'ju'],
    ruan   => ['ruan', 'juan'],
    rui    => ['ruei', 'juei'],
    run    => ['ruen', 'juen'],
    ruo    => ['ruo', 'juo'],

    sa     => 'sa',
    sai    => 'sai',
    san    => 'san',
    sang   => 'sang',
    sao    => ['sau', 'sao', 'saw'],
    se     => 'se',
    sen    => 'sen',
    seng   => 'seng',
    sha    => 'sha',
    shai   => 'shai',
    shan   => 'shan',
    shang  => 'shang',
    shao   => ['shau', 'shao', 'shaw'],
    she    => 'she',
    shei   => 'shei',
    shen   => 'shen',
    sheng  => 'sheng',
    shi    => 'she',
    shou   => ['shou', 'sheu'],# 'shEw', 'show'],
    shu    => 'shu',
    shua   => 'shua',
    shuai  => 'shuai',
    shuan  => 'shuan',
    shuang => 'shuang',
    shui   => 'shuei',
    shun   => 'shuen',
    shuo   => 'shuo',
    si     => 'se',
    song   => 'sung',
    sou    => ['sou', 'sow', 'seu', 'sew'],
    su     => 'su',
    suan   => 'suan',
    sui    => 'suei',
    sun    => 'suen',
    suo    => 'suo',

    ta     => 'tha',
    tai    => 'thai',
    tan    => 'than',
    tang   => 'thang',
    tao    => ['thau', 'thao', 'thaw'],
    te     => 'the',
    teng   => 'theng',
    ti     => 'thi',
    tian   => 'thien',
    tiao   => ['thiau', 'thiao', 'thiaw'],
    tie    => 'thie',
    ting   => 'thing',
    tong   => 'thung',
    tou    => ['thou', 'thow', 'theu', 'thew'],
    tu     => 'thu',
    tuan   => 'thuan',
    tui    => 'thuei',
    tun    => 'thuen',
    tuo    => 'thuo',

    wa     => 'wa',
    wai    => 'wai',
    wan    => 'wan',
    wang   => 'wang',
    wei    => 'wei',
    wen    => 'wen',
    weng   => 'weng',
    wo     => 'wo',
    wu     => 'wu',

    xi     => 'si',
    xia    => 'sia',
    xian   => 'sien',
    xiang  => 'siang',
    xiao   => ['siau', 'siao', 'siau'],
    xie    => 'sie',
    xin    => 'sin',
    xing   => 'sing',
    xiong  => 'siung',
    xiu    => 'siu',
    xu     => ['si', 'syu'],
    xuan   => ['suan', 'swan'],
    xue    => ['sie'],# 'sue'],
    xun    => 'suen',

    ya     => 'ya',
    yai    => 'yai',
    yan    => 'yen',
    yang   => 'yang',
    yao    => ['yau', 'yao', 'yaw'],
    ye     => 'ye',
    yi     => ['i', 'yi'],
    yin    => ['in', 'yin'],
    ying   => ['ing', 'ying'],
    yong   => 'yung',
    you    => ['yu', 'you'],# 'yow'],
    yu     => ['yi', 'yu'],
    yuan   => 'yuen',
    yue    => ['yue', 'ye'],
    yun    => ['yun', 'yin'],

    za     => 'ca',
    zai    => 'cai',
    zan    => 'can',
    zang   => 'cang',
    zao    => ['cau', 'cao', 'caw'],
    ze     => 'ce',
    zei    => 'cei',
    zen    => 'cen',
    zeng   => 'ceng',
    zha    => 'ca',
    zhai   => 'cai',
    zhan   => 'can',
    zhang  => 'cang',
    zhao   => ['cau', 'cao', 'caw'],
    zhe    => 'ce',
    zhei   => 'cei',
    zhen   => 'cen',
    zheng  => 'ceng',
    zhi    => 'ce',
    zhong  => 'cung',
    zhou   => ['cou', 'ceu', 'cew'], #cow
    zhu    => 'cu',
    zhua   => 'cua',
    zhuai  => 'cuai',
    zhuan  => 'cuan',
    zhuang => 'cuang',
    zhui   => 'cuei',
    zhun   => 'cuen',
    zhuo   => 'cuo',
    zi     => 'ce',
    zong   => 'cung',
    zou    => ['cou', 'ceu', 'cew'], #cow
    zu     => 'cu',
    zuan   => 'cuan',
    zui    => 'cuei',
    zun    => 'cuen',
    zuo    => 'cuo',
);

my %jy2id = (
    aa     => 'a',
    aai    => 'ai',
    aak    => ['ak', 'ngak'],
    aam    => 'am',
    aan    => ['an', 'ngan'],
    aang   => ['ang', 'ngang'],
    aap    => ['ap', 'ngap'],
    aat    => ['at', 'ngat'],
    aau    => ['au', 'ngau'],
    ai     => ['ai', 'ngai'],
    ak     => ['ak', 'ngak'],
    am     => 'am',
    ang    => ['ang', 'ngang'],
    ap     => 'ap',
    au     => 'au',

    baa    => 'pa',
    baai   => 'pai',
    baak   => 'pak',
    baan   => 'pan',
    baang  => 'pang',
    baat   => 'pat',
    baau   => 'pau',
    bai    => 'pai',
    bak    => 'pak',
    bam    => 'pam',
    ban    => 'pan',
    bang   => 'pang',
    bat    => 'pat',
    bau    => 'pau',
    be     => 'pe',
    bei    => 'pei',
    bek    => 'pek',
    beng   => 'peng',
    bik    => 'pik',
    bin    => 'pin',
    bing   => 'ping',
    bit    => 'pit',
    biu    => 'piu',
    bo     => 'po',
    bok    => 'pok',
    bong   => 'pong',
    bou    => 'pou', # pow
    bui    => 'pui',
    buk    => 'puk',
    bun    => 'pun',
    bung   => 'pung',
    but    => 'put',

    caa    => 'cha',
    caai   => 'chai',
    caak   => 'chak',
    caam   => 'cham',
    caan   => 'chan',
    caang  => 'chang',
    caap   => 'chap',
    caat   => 'chat',
    caau   => 'chau',
    cai    => 'chai',
    cak    => 'chak',
    cam    => 'cham',
    can    => 'chan',
    cang   => 'chang',
    cap    => 'chap',
    cat    => 'chat',
    cau    => 'chau',
    ce     => 'che',
    cek    => 'chek',
    ceng   => 'cheng',
    ceoi   => ['cheui', 'cheoi' ,
               'cheuy', 'cheoy' ],
    ceon   => ['cheun', 'cheon' ],
    ceot   => ['cheut', 'cheot' ],
    ci     => 'chi',
    cik    => 'chik',
    cim    => 'chim',
    cin    => 'chin',
    cing   => 'ching',
    cip    => 'chip',
    cit    => 'chit',
    ciu    => 'chiu',
    co     => 'cho',
    coek   => ['cheuk', 'choek'],
    coeng  => ['cheung', 'choeng'],
    coi    => ['choi', 'choy'],
    cok    => 'chok',
    cong   => 'chong',
    cou    => ['chou', 'chow'],
    cuk    => 'chuk',
    cung   => 'chung',
    cyu    => ['chyu', 'chiu'],
    cyun   => ['chyun', 'chiun'],
    cyut   => ['chyut', 'chiut'],

    daa    => 'ta',
    daai   => 'tai',
    daak   => 'tak',
    daam   => 'tam',
    daan   => 'tan',
    daap   => 'tap',
    daat   => 'tat',
    dai    => 'tai',
    dak    => 'tak',
    dam    => 'tam',
    dan    => 'tan',
    dang   => 'tang',
    dap    => 'tap',
    dat    => 'tat',
    dau    => 'tau',
    de     => 'te',
    dei    => 'tei',
    dek    => 'tek',
    deng   => 'teng',
    deoi   => ['teui', 'teoi',
               'teuy', 'teoy'],
    deon   => ['teun', 'teon'],
    deot   => ['teut', 'teot'],
    deu    => ['teu','tew'],
    dik    => 'tik',
    dim    => 'tim',
    din    => 'tin',
    ding   => 'ting',
    dip    => 'tip',
    dit    => 'tit',
    diu    => 'tiu',
    do     => 'to',
    doe    => ['teu','toe'],
    doek   => ['teuk', 'toek'],
    doi    => ['toi', 'toy'],
    dok    => 'tok',
    dong   => 'tong',
    dou    => ['tou', 'tow'],
    duk    => 'tuk',
    dung   => 'tung',
    dyun   => ['tyun', 'tiun'],
    dyut   => ['tyut', 'tiut'],

    e      => 'e',
    ei     => 'ei',

    faa    => 'fa',
    faai   => 'fai',
    faak   => 'fak',
    faan   => 'fan',
    faat   => 'fat',
    fai    => 'fai',
    fan    => 'fan',
    fang   => 'fang',
    fat    => 'fat',
    fau    => 'fau',
    fe     => 'fe',
    fei    => 'fei',
    fo     => 'fo',
    fok    => 'fok',
    fong   => 'fong',
    fu     => 'fu',
    fui    => 'fui',
    fuk    => 'fuk',
    fun    => 'fun',
    fung   => 'fung',
    fut    => 'fut',

    # i think g is also a common indo transliteration for
    # non-mandarin, for instance in names, e.g. kwik kian gee. but
    # i'll default to k.
    gaa    => ['ka', 'ga'],
    gaai   => ['kai', 'gai'],
    gaak   => ['kak', 'gak'],
    gaam   => ['kam', 'gam'],
    gaan   => ['kan', 'gan'],
    gaang  => ['kang', 'gang'],
    gaap   => ['kap', 'gap'],
    gaat   => ['kat', 'gat'],
    gaau   => ['kau', 'gau'],
    gai    => ['kai', 'gai'],
    gam    => ['kam','gam'],
    gan    => ['kan','gan'],
    gang   => ['kang','gang'],
    gap    => ['kap','gap'],
    gat    => ['kat','gat'],
    gau    => ['kau','gau'],
    ge     => ['ke','ge'],
    gei    => ['kei','gei'],
    geng   => ['keng','geng'],
    geoi   => ['keui', 'geui', 'keoi', 'geoi',
               'keuy', 'geuy', 'keoy', 'geoy'],
    gep    => ['kep','gep'],
    gik    => ['kik','gik'],
    gim    => ['kim','gim'],
    gin    => ['kin','gin'],
    ging   => ['king','ging'],
    gip    => ['kip','gip'],
    git    => ['kit','git'],
    giu    => ['kiu','giu'],
    go     => ['ko','go'],
    goe    => ['keu','geu','koe','goe'],
    goek   => ['keuk','geuk','koek','goek'],
    goeng  => ['keung','geung','koeng','goeng'],
    goi    => ['koi','goi',
               'koy','goy'],
    gok    => ['kok','gok'],
    gon    => ['kon','gon'],
    gong   => ['kong','gong'],
    got    => ['kot','got'],
    gou    => ['kou', 'kow', 'gou', 'gow'],
    gu     => ['ku','gu'],
    gui    => ['kui','gui'],
    guk    => ['kuk','guk'],
    gun    => ['kun','gun'],
    gung   => ['kung','gung'],
    gwaa   => ['kwa','gwa', 'kua','gua'],
    gwaai  => ['kwai','gwai','kuai','guai'],
    gwaak  => ['kwak','gwak'],
    gwaan  => ['kwan','gwan'],
    gwaang => ['kwang','gwang'],
    gwaat  => ['kwat','gwat'],
    gwai   => ['kwai','gwai'],
    gwan   => ['kwan','gwan'],
    gwang  => ['kwang','gwang'],
    gwat   => ['kwat','gwat'],
    gwik   => ['kwik','gwik'],
    gwing  => ['kwing','gwing'],
    gwo    => ['kwo','gwo'],
    gwok   => ['kwok','gwok'],
    gwong  => ['kwong','gwong'],
    gyun   => ['kyun','gyun','kiun','giun'],
    gyut   => ['kyut','gyut','kiut','kyut'],

    haa    => 'ha',
    haai   => 'hai',
    haak   => 'hak',
    haam   => 'ham',
    haan   => 'han',
    haang  => 'hang',
    haap   => 'hap',
    haau   => 'hau',
    hai    => 'hai',
    hak    => 'hak',
    ham    => 'ham',
    han    => 'han',
    hang   => 'hang',
    hap    => 'hap',
    hat    => 'hat',
    hau    => 'hau',
    hei    => 'hei',
    hek    => 'hek',
    heng   => 'heng',
    heoi   => ['heoi',
               'heoy'],
    hik    => 'hik',
    him    => 'him',
    hin    => 'hin',
    hing   => 'hing',
    hip    => 'hip',
    hit    => 'hit',
    hiu    => 'hiu',
    hm     => 'hm',
    hng    => 'hng',
    ho     => 'ho',
    hoe    => ['heu','hoe'],
    hoeng  => ['heung','hoeng'],
    hoi    => ['hoi','hoy'],
    hok    => 'hok',
    hon    => 'hon',
    hong   => 'hong',
    hot    => 'hot',
    hou    => ['hou','how'],
    huk    => 'huk',
    hung   => 'hung',
    hyun   => ['hiun','hyun'],
    hyut   => ['hyut','hiut'],

    jaa    => 'ya',
    jaai   => 'yai',
    jaak   => 'yak',
    jai    => 'yai',
    jam    => 'yam',
    jan    => 'yan',
    jap    => 'yap',
    jat    => 'yat',
    jau    => 'yau',
    je     => 'ye',
    jeng   => 'yeng',
    jeoi   => ['yeui','yeoi',
               'yeuy','yeoy'],
    jeon   => ['yeun','yeon'],
    ji     => 'yi',
    jik    => 'yik',
    jim    => 'yim',
    jin    => 'yin',
    jing   => 'ying',
    jip    => 'yip',
    jit    => 'yit',
    jiu    => 'yiu',
    jo     => 'yo',
    joek   => ['yeuk','yoek'],
    joeng  => ['yeung','yoeng'],
    juk    => 'yuk',
    jung   => 'yung',
    jyu    => ['yiu', 'yu'],
    jyun   => ['yiun', 'yun'],
    jyut   => ['yiut', 'yut'],

    kaa    => 'kha',
    kaai   => 'khai',
    kaak   => 'khak',
    kaat   => 'khat',
    kaau   => 'khau',
    kai    => 'khai',
    kam    => 'kham',
    kan    => 'khan',
    kang   => 'khang',
    kap    => 'khap',
    kat    => 'khat',
    kau    => 'khau',
    ke     => 'khe',
    kei    => 'khei',
    kek    => 'khek',
    keoi   => ['kheui', 'kheoi',
               'kheuy', 'kheoy'],
    kik    => 'khik',
    kim    => 'khim',
    kin    => 'khin',
    king   => 'khing',
    kit    => 'khit',
    kiu    => 'khiu',
    ko     => 'kho',
    koe    => ['kheu','khoe'],
    koek   => ['kheuk','khoek'],
    koeng  => ['kheung','khoeng'],
    koi    => ['khoi','khoy'],
    kok    => 'khok',
    kong   => 'khong',
    ku     => 'khu',
    kui    => 'khui',
    kuk    => 'khuk',
    kung   => 'khung',
    kut    => 'khut',
    kwaa   => 'khwa',
    kwaai  => 'khwai',
    kwaang => 'khwang',
    kwai   => 'khwai',
    kwan   => 'khwan',
    kwik   => 'khwik',
    kwok   => 'khwok',
    kwong  => 'khwong',
    kyun   => ['khiun','khyun'],
    kyut   => ['khiut','khyut'],

    laa    => 'la',
    laai   => 'lai',
    laak   => 'lak',
    laam   => 'lam',
    laan   => 'lan',
    laang  => 'lang',
    laap   => 'lap',
    laat   => 'lat',
    laau   => 'lau',
    lai    => 'lai',
    lak    => 'lak',
    lam    => 'lam',
    lang   => 'lang',
    lap    => 'lap',
    lat    => 'lat',
    lau    => 'lau',
    le     => 'le',
    lei    => 'lei',
    lek    => 'lek',
    lem    => 'lem',
    leng   => 'leng',
    leoi   => ['leui','leoi',
               'leuy','leoy'],
    leon   => ['leun','leon'],
    leot   => ['leut','leot'],
    li     => 'li',
    lik    => 'lik',
    lim    => 'lim',
    lin    => 'lin',
    ling   => 'ling',
    lip    => 'lip',
    lit    => 'lit',
    liu    => 'liu',
    lo     => 'lo',
    loek   => ['leuk','loek'],
    loeng  => ['leung','loeng'],
    loi    => ['loi','loy'],
    lok    => 'lok',
    long   => 'long',
    lou    => ['lou','low'],
    luk    => 'luk',
    lung   => 'lung',
    lyun   => ['liun','lyun'],
    lyut   => ['liut','lyut'],

    m      => 'm',
    maa    => 'ma',
    maai   => 'mai',
    maak   => 'mak',
    maan   => 'man',
    maang  => 'mang',
    maat   => 'mat',
    maau   => 'mau',
    mai    => 'mai',
    mak    => 'mak',
    man    => 'man',
    mang   => 'mang',
    mat    => 'mat',
    mau    => 'mau',
    me     => 'me',
    mei    => 'mei',
    meng   => 'meng',
    mi     => 'mi',
    mik    => 'mik',
    min    => 'min',
    ming   => 'ming',
    mit    => 'mit',
    miu    => 'miu',
    mo     => 'mo',
    mok    => 'mok',
    mong   => 'mong',
    mou    => ['mou','mow'],
    mui    => 'mui',
    muk    => 'muk',
    mun    => 'mun',
    mung   => 'mung',
    mut    => 'mut',

    naa    => 'na',
    naai   => 'nai',
    naam   => 'nam',
    naan   => 'nan',
    naap   => 'nap',
    naat   => 'nat',
    naau   => 'nau',
    nai    => 'nai',
    nam    => 'nam',
    nan    => 'nan',
    nang   => 'nang',
    nap    => 'nap',
    nat    => 'nat',
    nau    => 'nau',
    ne     => 'ne',
    nei    => 'nei',
    neoi   => ['neui','neoi',
               'neuy','neoy'],
    neot   => ['neut','neot'],
    ng     => 'ng',

    ngaa   => 'nga',
    ngaai  => 'ngai',
    ngaak  => 'ngak',
    ngaam  => 'ngam',
    ngaan  => 'ngan',
    ngaang => 'ngang',
    ngaap  => 'ngap',
    ngaat  => 'ngat',
    ngaau  => 'ngau',
    ngai   => 'ngai',
    ngak   => 'ngak',
    ngam   => 'ngam',
    ngan   => 'ngan',
    ngang  => 'ngang',
    ngap   => 'ngap',
    ngat   => 'ngat',
    ngau   => 'ngau',
    ngit   => 'ngit',
    ngo    => 'ngo',
    ngoi   => ['ngoi','ngoy'],
    ngok   => 'ngok',
    ngon   => 'ngon',
    ngong  => 'ngong',
    ngou   => ['ngou','ngow'],
    nguk   => 'nguk',
    ngung  => 'ngung',

    ni     => 'ni',
    nik    => 'nik',
    nim    => 'nim',
    nin    => 'nin',
    ning   => 'ning',
    nip    => 'nip',
    niu    => 'niu',
    no     => 'no',
    noeng  => ['neung','noeng'],
    noi    => ['noi','noy'],
    nok    => 'nok',
    nong   => 'nong',
    nou    => ['nou','now'],
    nuk    => 'nuk',
    nung   => 'nung',
    nyun   => ['niun','nyun'],

    o      => 'o',
    oi     => ['oi','oy'],
    ok     => 'ok',
    on     => 'on',
    ong    => 'ong',
    ou     => ['ou','ow'],

    paa    => 'pha',
    paai   => 'phai',
    paak   => 'phak',
    paan   => 'phan',
    paang  => 'phang',
    paau   => 'phau',
    pai    => 'phai',
    pan    => 'phan',
    pang   => 'phang',
    pat    => 'phat',
    pau    => 'phau',
    pei    => 'phei',
    pek    => 'phek',
    peng   => 'pheng',
    pik    => 'phik',
    pin    => 'phin',
    ping   => 'phing',
    pit    => 'phit',
    piu    => 'phiu',
    po     => 'pho',
    poi    => 'phoi',
    pok    => 'phok',
    pong   => 'phong',
    pou    => ['phou','phow'],
    pui    => 'phui',
    puk    => 'phuk',
    pun    => 'phun',
    pung   => 'phung',
    put    => 'phut',

    saa    => 'sa',
    saai   => 'sai',
    saak   => 'sak',
    saam   => 'sam',
    saan   => 'san',
    saang  => 'sang',
    saap   => 'sap',
    saat   => 'sat',
    saau   => 'sau',
    sai    => 'sai',
    sak    => 'sak',
    sam    => 'sam',
    san    => 'san',
    sang   => 'sang',
    sap    => 'sap',
    sat    => 'sat',
    sau    => 'sau',
    se     => 'se',
    sei    => 'sei',
    sek    => 'sek',
    seng   => 'seng',
    seoi   => ['seui','seoi',
               'seuy','seoy'],
    seon   => ['seun','seon'],
    seot   => ['seut','seot'],
    si     => 'si',
    sik    => 'sik',
    sim    => 'sim',
    sin    => 'sin',
    sing   => 'sing',
    sip    => 'sip',
    sit    => 'sit',
    siu    => 'siu',
    so     => 'so',
    soek   => ['seuk','soek'],
    soeng  => ['seung','soeng'],
    soi    => ['soi','soy'],
    sok    => 'sok',
    song   => 'song',
    sou    => ['sou','sow'],
    suk    => 'suk',
    sung   => 'sung',
    syu    => ['siu','syu'],
    syun   => ['siun','syun'],
    syut   => ['siut','syut'],

    taa    => 'tha',
    taai   => 'thai',
    taam   => 'tham',
    taan   => 'than',
    taap   => 'thap',
    taat   => 'that',
    tai    => 'thai',
    tam    => 'tham',
    tan    => 'than',
    tang   => 'thang',
    tau    => 'thau',
    tek    => 'thek',
    teng   => 'theng',
    teoi   => ['theui','theoi',
               'theuy','theoy'],
    teon   => ['theun','theon'],
    tik    => 'thik',
    tim    => 'thim',
    tin    => 'thin',
    ting   => 'thing',
    tip    => 'thip',
    tit    => 'thit',
    tiu    => 'thiu',
    to     => 'tho',
    toe    => ['theu','thoe'],
    toi    => ['thoi','thoy'],
    tok    => 'thok',
    tong   => 'thong',
    tou    => ['thou', 'thow'],
    tuk    => 'thuk',
    tung   => 'thung',
    tyun   => ['thiun','thyun'],
    tyut   => ['thiut','thyut'],

    uk     => 'uk',
    ung    => 'ung',

    waa    => 'wa',
    waai   => 'wai',
    waak   => 'wak',
    waan   => 'wan',
    waang  => 'wang',
    waat   => 'wat',
    wai    => 'wai',
    wan    => 'wan',
    wang   => 'wang',
    wat    => 'wat',
    wik    => 'wik',
    wing   => 'wing',
    wo     => 'wo',
    wok    => 'wok',
    wong   => 'wong',
    wu     => 'wu',
    wui    => 'wui',
    wun    => 'wun',
    wut    => 'wut',

    zaa    => 'ca',
    zaai   => 'cai',
    zaak   => 'cak',
    zaam   => 'cam',
    zaan   => 'can',
    zaang  => 'cang',
    zaap   => 'cap',
    zaat   => 'cat',
    zaau   => 'cau',
    zai    => 'cai',
    zak    => 'cak',
    zam    => 'cam',
    zan    => 'can',
    zang   => 'cang',
    zap    => 'cap',
    zat    => 'cat',
    zau    => 'cau',
    ze     => 'ce',
    zek    => 'cek',
    zeng   => 'ceng',
    zeoi   => ['ceui','ceoi',
               'ceuy','ceoy'],
    zeon   => ['ceun','ceon'],
    zeot   => ['ceut','ceot'],
    zi     => 'ci',
    zik    => 'cik',
    zim    => 'cim',
    zin    => 'cin',
    zing   => 'cing',
    zip    => 'cip',
    zit    => 'cit',
    ziu    => 'ciu',
    zo     => 'co',
    zoek   => ['ceuk','coek'],
    zoeng  => ['ceung','coeng'],
    zoi    => ['coi','coy'],
    zok    => 'cok',
    zong   => 'cong',
    zou    => ['cou','cow'],
    zuk    => 'cuk',
    zung   => 'cung',
    zyu    => ['ciu','cyu'],
    zyun   => ['ciun','cyun'],
    zyut   => ['ciut','cyut'],
);

my %id2hy;
my %id2jy;
for (keys %hy2id) {
    my $l = ref($hy2id{$_}) eq 'ARRAY' ? $hy2id{$_} : [$hy2id{$_}];
    for my $id (@$l) {
        if (exists $id2hy{$id}) {
            $id2hy{$id} = [$id2hy{$id}] unless ref($id2hy{$id}) eq 'ARRAY';
            push @{ $id2hy{$id} }, $_;
        } else {
            $id2hy{$id} = $_;
        }
    }
}
#use Data::Dumper; print Dumper \%id2hy;
for (keys %jy2id) {
    my $l = ref($jy2id{$_}) eq 'ARRAY' ? $jy2id{$_} : [$jy2id{$_}];
    for my $id (@$l) {
        if (exists $id2jy{$id}) {
            $id2jy{$id} = [$id2jy{$id}] unless ref($id2jy{$id}) eq 'ARRAY';
            push @{ $id2jy{$id} }, $_;
        } else {
            $id2jy{$id} = $_;
        }
    }
}
#use Data::Dumper; print Dumper \%id2jy;

my $hy_re = join("|", sort { length($b) <=> length($a) } keys %hy2id); $hy_re = qr/(?:$hy_re)/;
my $jy_re = join("|", sort { length($b) <=> length($a) } keys %jy2id); $jy_re = qr/(?:$jy_re)/;
my $idmand_re = join("|", sort { length($b) <=> length($a) } keys %id2hy); $idmand_re = qr/(?:$idmand_re)/;
my $idcant_re = join("|", sort { length($b) <=> length($a) } keys %id2jy); $idcant_re = qr/(?:$idcant_re)/;
my %all = (%hy2id, %jy2id, %id2hy, %id2jy);
my $all_re = join("|", sort { length($b) <=> length($a) } keys %all); $all_re = qr/(?:$all_re)/;

sub new {
    my ($class, %opts) = @_;
    bless {}, $class;
}

sub hanyu2id {
    my ($self, $text, $opts) = @_;
    if (!defined($opts)) { $opts = {} }
    my $sub1 = sub {
        my $t = shift;
        $t =~ s/($hy_re)([12345]?)/
            (ref($hy2id{$1}) ? $hy2id{$1}[0] : $hy2id{$1}) .
                ($opts->{remove_tones} ? "" : $2)/eg;
        $t;
    };
    $text =~ s/\b((?:$hy_re[12345]?)+)\b/$sub1->($1)/eg;
    $text;
}

sub jyutping2id {
    my ($self, $text, $opts) = @_;
    if (!defined($opts)) { $opts = {} }
    my $sub1 = sub {
        my $t = shift;
        $t =~ s/($jy_re)([123456]?)/
            (ref($jy2id{$1}) ? $jy2id{$1}[0] : $jy2id{$1}) .
                (!$opts->{remove_tones} && $2 ? $2 : "")/eg;
        $t;
    };
    $text =~ s/\b((?:$jy_re[123456]?)+)\b/$sub1->($1)/eg;
    $text;
}

sub id2hanyu {
    my ($self, $text, $opts) = @_;
    if (!defined($opts)) { $opts = {} }
    my $sub2 = sub {
        my $t = shift;
        if ($opts->{list_all}) {
            $t =~ s/($idmand_re)([12345]?)/
                (ref($id2hy{$1}) ? "(".join("|", sort(@{ $id2hy{$1} })).")" : $id2hy{$1}) .
                    (!$opts->{remove_tones} && $2 ? $2 : "")/eg;
        } else {
            $t =~ s/($idmand_re)([12345]?)/
                (ref($id2hy{$1}) ? die("ambiguous") : $id2hy{$1}) .
                    (!$opts->{remove_tones} && $2 ? $2 : "")/eg;
        }
        $t;
    };
    eval {
        $text =~ s/\b((?:$idmand_re[12345]?)+)\b/$sub2->($1)/eg;
    };
    $@ ? undef : $text;
}

sub id2jyutping {
    my ($self, $text, $opts) = @_;
    if (!defined($opts)) { $opts = {} }
    my $sub2 = sub {
        my $t = shift;
        if ($opts->{list_all}) {
            $t =~ s/($idcant_re)([123456]?)/
                (ref($id2jy{$1}) ? "(".join("|", sort(@{ $id2jy{$1} })).")" : $id2jy{$1}) .
                    ($opts->{remove_tones} ? "" : $2)/eg;
        } else {
            $t =~ s/($idcant_re)([123456]?)/
                (ref($id2jy{$1}) ? die("ambiguous") : $id2jy{$1}) .
                    ($opts->{remove_tones} ? "" : $2)/eg;
        }
        $t;
    };
    eval {
        $text =~ s/\b((?:$idcant_re[123456]?)+)\b/$sub2->($1)/eg;
    };
    $@ ? undef : $text;
}

sub detect {
    my ($self, $text) = @_;
    my $n_hy = 0;
    my $n_jy = 0;
    my $n_idmand = 0;
    my $n_idcant = 0;
    my $n_all = 0;

    my $sub_all = sub {
        my $t = shift;
        $n_all++    while $t =~ /\b$all_re[123456]?\b/g;
        $t;
    };
    my $sub_hy = sub {
        my $t = shift;
        $n_hy++     while $t =~ /\b$hy_re[12345]?\b/g;
        $t;
    };
    my $sub_jy = sub {
        my $t = shift;
        $n_jy++     while $t =~ /\b$jy_re[123456]?\b/g;
        #print "[jy:$1]" while $t =~ /\b($jy_re[123456]?)\b/g;
        $t;
    };
    my $sub_idmand = sub {
        my $t = shift;
        $n_idmand++ while $t =~ /\b$idmand_re[12345]?\b/g;
        #print "[idmand:$1]" while $t =~ /\b($idmand_re[12345]?)\b/g;
        $t;
    };
    my $sub_idcant = sub {
        my $t = shift;
        $n_idcant++ while $t =~ /\b$idcant_re[123456]?\b/g;
        $t;
    };

    my @res;
    $text =~ s/\b((?:$all_re[123456]?){1})\b/$sub_all->($1)/eg;
    $text =~ s/\b((?:$hy_re[12345]?){1})\b/$sub_hy->($1)/eg;
    $text =~ s/\b((?:$jy_re[123456]?){1})\b/$sub_jy->($1)/eg;
    $text =~ s/\b((?:$idmand_re[12345]?){1})\b/$sub_idmand->($1)/eg;
    $text =~ s/\b((?:$idcant_re[123456]?){1})\b/$sub_idcant->($1)/eg;

    #print "DEBUG: all=$n_all, hy=$n_hy, jy=$n_jy, idmand=$n_idmand, idcant=$n_idcant\n";

    return @res unless $n_all;
    push @res, "hanyu"        if $n_hy/$n_all     >= 0.9;
    push @res, "jyutping"     if $n_jy/$n_all     >= 0.9;
    push @res, "id-mandarin"  if $n_idmand/$n_all >= 0.9;
    push @res, "id-cantonese" if $n_idcant/$n_all >= 0.9;
    @res;
}

sub list_hanyu {
    my ($self) = @_;
    sort keys %hy2id;
}

sub list_jyutping {
    my ($self) = @_;
    sort keys %jy2id;
}

sub list_id_mandarin {
    my ($self) = @_;
    sort keys %id2hy;
}

sub list_id_cantonese {
    my ($self) = @_;
    sort keys %id2jy;
}

1;
# ABSTRACT: Convert between various Chinese pinyin system and Indonesian transliteration

__END__

=pod

=head1 NAME

Lingua::ZH::PinyinConvert::ID - Convert between various Chinese pinyin system and Indonesian transliteration

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    use Lingua::ZH::PinyinConvert::ID;

    my $conv = Lingua::ZH::PinyinConvert::ID;

    # convert Hanyu pinyin to Indonesian transliteration

    my $id = $conv->hanyu2id("zhongwen"); # "cungwen"
       $id = $conv->hanyu2id("zhong1 wen2"); # "cung1 wen2"
       $id = $conv->hanyu2id("zhong1 wen2", {remove_tones=>1}); # "cung wen"

    # convert Jyutping (cantonese) to Indonesian transliteration

    my $id = $conv->jyutping2id("zungman"); # "cungman"

    # convert Indonesian transliteration to Hanyu pinyin, if
    # possible. if ambiguous, then will return undef.

    my $hanyu = $conv->id2hanyu("i sheng"); # "yi sheng"
       $hanyu = $conv->id2hanyu("ce"); # undef, ambiguous between ze/zhe/zhi/zi
       $hanyu = $conv->id2hanyu("ce", {list_all=>1}); "(ze|zhe|zhi|zi)"

    # convert Indonesian transliteration to Jyutping.
    my $jyutping = $conv->id2jyutping("ying man"); # "jing man"

    # detect pinyin or Indonesian transliteration in text. return a
    # list of 0 or more elements, each element being "hanyu",
    # "jyutping", "id-mandarin", or "id-cantonese".
    print join ", ", $conv->detect("I love You"); # ""
    print join ", ", $conv->detect("wo de xin");  # "hanyu"
    print join ", ", $conv->detect("wo te sin");  # "jyutping", "id-mandarin", "id-cantonese"

=head1 DESCRIPTION

This module converts between various Chinese pinyin systems and
Indonesian transliteration. Currently these pinyin systems are
supported: Hanyu Pinyin (Mandarin) and Jyutping (Cantonese).

Indonesian transliteration is admittedly non-standardized and
inaccurate, and more and more people are learning Hanyu Pinyin each
day, but it is still useful for those who are unfamiliar with Pinyin
systems. You can still encounter Indonesian transliteration in some
places, e.g. Karaoke video subtitles or old textbooks.

=head1 METHODS

=head2 new(%opts)

Create a new instance. Currently there are no known options.

=head2 hanyu2id($text[, $opts])

Convert Hanyu pinyin to Indonesian transliteration. Pinyins are
expected to be written in lowercase. Unknown characters will just be
returned as-is.

C<$opts> is an optional hahref containing options. Known options:

=over

=item * remove_tones => BOOL

If true, tone numbers will be removed.

=back

=head2 jyutping2id($text[, $opts])

Convert Jyutping to Indonesian transliteration. Pinyins are expected
to be written in lowercase. Unknown characters will just be returned
as-is.

C<$opts> is an optional hahref containing options. Known options:

=over

=item * remove_tones => BOOL

If true, tone numbers will be removed.

=back

=head2 id2hanyu($text[, $opts])

Convert Indonesian transliteration to Hanyu pinyin. Pinyins are
expected to be written in lowercase. Since Indonesian transliteration
can be ambiguous (e.g. Mandarin sounds 'ze', 'zhe', 'zhi', 'zi' are
usually all transliterated as 'ce'), conversion is not always
possible. When this is the case, undef is returned.

C<$opts> is an optional hahref containing options. Known options:

=over

=item * list_all => BOOL

If true, then when conversion is ambiguous, instead of returning
undef, all alternatives are returneed.

=item * remove_tones => BOOL

If true, tone numbers will be removed.

=back

=head2 id2jyutping($text[, $opts])

Convert Indonesian transliteration to Jyutping. Pinyins are expected
to be written in lowercase. Since Indonesian transliteration can be
ambiguous (e.g. Cantonese sounds 'kwik' and 'gwik' are sometimes all
transliterated as 'kwik'), conversion is not always possible. When
this is the case, undef is returned.

C<$opts> is an optional hahref containing options. Known options:

=over

=item * list_all => BOOL

If true, then when conversion is ambiguous, instead of returning
undef, all alternatives are returneed.

=item * remove_tones => BOOL

If true, tone numbers will be removed.

=back

=head2 detect($text)

Detect pinyin or Indonesian transliteration in text. Pinyins are
expected to be written in lowercase B<and separated into
words>. Return a list of 0 or more elements, each element being
"hanyu", "cantonese", "id-mandarin", or "id-cantonese".

=head2 list_hanyu()

Return all Hanyu pinyin syllables.

=head2 list_jyutping()

Return all Jyutping syllables.

=head2 list_id_mandarin()

Return all Indonesian transliteration syllables for Mandarin.

=head2 list_id_cantonese()

Return all Indonesian transliteration syllables for Cantonese.

=head1 SEE ALSO

L<Lingua::ZH::PinyinConvert>

L<Lingua::Han::PinYin>

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
