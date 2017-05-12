package Geo::Address::Mail::Standardizer::USPS;
use Moose;

with 'Geo::Address::Mail::Standardizer';

our $VERSION = '0.03';

use Geo::Address::Mail::Standardizer::Results;

# Defined in C2 - "Secondary Unit Designators"
my %range_designators = (
    APT  => qr/(?:^|\b)AP(?:T|ARTMENT)\.?(?:\b|$)/i,
    BLDG => qr/(?:^|\b)B(?:UI)?LD(?:IN)?G\.?(?:\b|$)/i,
    DEPT => qr/(?:^|\b)DEP(?:ARTMEN)?T\.?(?:\b|$)/i,
    FL   => qr/(?:^|\b)FL(?:OOR)?\.?(?:\b|$)/i,
    HNGR => qr/(?:^|\b)HA?NGE?R\.?(?:\b|$)/i,
    KEY  => qr/(?:^|\b)KEY\.?(?:\b|$)/i,
    LOT  => qr/(?:^|\b)LOT\.?(?:\b|$)/i,
    PIER => qr/(?:^|\b)PIER\.?(?:\b|$)/i,
    RM   => qr/(?:^|\b)R(?:OO)?M\.?(?:\b|$)/i,
    SLIP => qr/(?:^|\b)SLIP\.?(?:\b|$)/i,
    SPC  => qr/(?:^|\b)SPA?CE?\.?(?:\b|$)/i,
    STOP => qr/(?:^|\b)STOP\.?(?:\b|$)/i,
    STE  => qr/(?:^|\b)S(?:UI)?TE\.?(?:\b|$)/i,
    TRLR => qr/(?:^|\b)TR(?:AI)?LE?R\.?(?:\b|$)/i,
    UNIT => qr/(?:^|\b)UNIT\.?(?:\b|$)/i,
);

# Defined in C2 - "Secondary Unit Designators", does not require secondary
# RANGE to follow.
my %designators = (
    BSMT => qr/(?:^|\b)BA?SE?M(?:EN)?T\.?(?:\b|$)/i,
    FRNT => qr/(?:^|\b)FRO?NT\.?(?:\b|$)/i,
    LBBY => qr/(?:^|\b)LO?BBY\.?(?:\b|$)/i,
    LOWR => qr/(?:^|\b)LOWE?R\.?(?:\b|$)/i,
    OFC  => qr/(?:^|\b)OF(?:FI)?CE?\.?(?:\b|$)/i,
    PH   => qr/(?:^|\b)P(?:ENT)?H(?:OUSE)?\.?(?:\b|$)/i,
    REAR => qr/(?:^|\b)REAR\.?(?:\b|$)/i,
    SIDE => qr/(?:^|\b)SIDE\.?(?:\b|$)/i,
    UPPR => qr/(?:^|\b)UPPE?R\.?(?:\b|$)/i,
);

# Defined in C1 - "Street Suffix Abbreviations"
my %street_suffix_abbrev = (
    ALY  => qr/(?:^|\b)AL+E*Y?\.?(?:\b|$)/i,
    ANX  => qr/(?:^|\b)AN+E*X\.?(?:\b|$)/i,
    ARC  => qr/(?:^|\b)ARC(?:ADE)?\.?(?:\b|$)/i,
    AVE  => qr/(?:^|\b)AVE?(?:N(?:U(?:E)?)?)?\.?(?:\b|$)/i,
    BYU  => qr/(?:^|\b)(?:BYU|BA?YO*[OU])\.?(?:\b|$)/i,
    BCH  => qr/(?:^|\b)B(?:EA)?CH\.?(?:\b|$)/i,
    BND  => qr/(?:^|\b)BE?ND\.?(?:\b|$)/i,
    BLF  => qr/(?:^|\b)BLU?F+[^S]*\.?(?:\b|$)/i,
    BLFS => qr/(?:^|\b)BLU?F+S\.?(?:\b|$)/i,
    BTM  => qr/(?:^|\b)B(?:O?T+O?M|OT)\.?(?:\b|$)/i,
    BLVD => qr/(?:^|\b)B(?:(?:OU)?LE?V(?:AR)?D|OULV?)\.?(?:\b|$)/i,
    BR   => qr/(?:^|\b)BR(?:(?:A?NCH)|\.?)(?:\b|$)/i,
    BRG  => qr/(?:^|\b)BRI?D?GE?\.?(?:\b|$)/i,
    BRK  => qr/(?:^|\b)BRO*K[^S]*\.?(?:\b|$)/i,
    BRKS => qr/(?:^|\b)BRO*KS\.?(?:\b|$)/i,
    BG   => qr/(?:^|\b)B(?:UR)?G[^S]*\.?(?:\b|$)/i,
    BGS  => qr/(?:^|\b)B(?:UR)?GS\.?(?:\b|$)/i,
    BYP  => qr/(?:^|\b)BYP(?:A?S*)?\.?(?:\b|$)/i,
    CP   => qr/(?:^|\b)CA?M?P[^E]*\.?(?:\b|$)/i,
    CYN  => qr/(?:^|\b)CA?N?YO?N\.?(?:\b|$)/i,
    CPE  => qr/(?:^|\b)CA?PE\.?(?:\b|$)/i,
    CSWY => qr/(?:^|\b)C(?:AU)?SE?WA?Y\.?(?:\b|$)/i,
    CTR  => qr/(?:^|\b)C(?:E?N?TE?RE?|ENT)[^S]*\.?(?:\b|$)/i,
    CTRS => qr/(?:^|\b)C(?:E?N?TE?RE?|ENT)S\.?(?:\b|$)/i,
    CIR  => qr/(?:^|\b)C(?:RCLE?|IRC?L?E?)[^S]*\.?(?:\b|$)/i,
    CIRS => qr/(?:^|\b)C(?:RCLE?|IRC?L?E?)S\.?(?:\b|$)/i,
    CLF  => qr/(?:^|\b)CLI?F+[^S]*\.?(?:\b|$)/i,
    CLFS => qr/(?:^|\b)CLI?F+S\.?(?:\b|$)/i,
    CLB  => qr/(?:^|\b)CLU?B\.?(?:\b|$)/i,
    CMN  => qr/(?:^|\b)CO?M+O?N\.?(?:\b|$)/i,
    COR  => qr/(?:^|\b)COR(?:NER)?[^S]*\.?(?:\b|$)/i,
    CORS => qr/(?:^|\b)COR(?:NER)?S\.?(?:\b|$)/i,
    CRSE => qr/(?:^|\b)C(?:OU)?RSE\.?(?:\b|$)/i,
    CT   => qr/(?:^|\b)C(?:OU)?R?T[^RS]*\.?(?:\b|$)/i,
    CTS  => qr/(?:^|\b)C(?:OU)?R?TS\.?(?:\b|$)/i,
    CV   => qr/(?:^|\b)CO?VE?[^S]*\.?(?:\b|$)/i,
    CVS  => qr/(?:^|\b)CO?VE?S\.?(?:\b|$)/i,
    CRK  => qr/(?:^|\b)C(?:RE*K|[RK])\.?(?:\b|$)/i,
    CRES => qr/(?:^|\b)CR(?:ES?C?E?(?:NT)?|SC?E?NT|R[ES])\.?(?:\b|$)/i,
    CRST => qr/(?:^|\b)CRE?ST\.?(?:\b|$)/i,
    XING => qr/(?:^|\b)(?:CRO?S+I?NG|XING)\.?(?:\b|$)/i,
    XRD  => qr/(?:^|\b)(?:CRO?S+R(?:OA)?D|XR(?:OA)?D)\.?(?:\b|$)/i,
    CURV => qr/(?:^|\b)CURVE?\.?(?:\b|$)/i,
    DL   => qr/(?:^|\b)DA?LE?\.?(?:\b|$)/i,
    DM   => qr/(?:^|\b)DA?M\.?(?:\b|$)/i,
    DV   => qr/(?:^|\b)DI?V(?:I?DE?)?\.?(?:\b|$)/i,
    DR   => qr/(?:^|\b)DR(?:I?VE?)?[^S]*\.?(?:\b|$)/i,
    DRS  => qr/(?:^|\b)DR(?:I?VE?)?S\.?(?:\b|$)/i,
    EST  => qr/(?:^|\b)EST(?:ATE)?[^S]*\.?(?:\b|$)/i,
    ESTS => qr/(?:^|\b)EST(?:ATE)?S\.?(?:\b|$)/i,
    EXPY => qr/(?:^|\b)EXP(?:R(?:ES+(?:WAY)?)?|[WY])?\.?(?:\b|$)/i,
    EXT  => qr/(?:^|\b)EXT(?:E?N(?:S(?:IO)?N)?)?[^S]*\.?(?:\b|$)/i,
    EXTS => qr/(?:^|\b)EXT(?:E?N(?:S(?:IO)?N)?)?S\.?(?:\b|$)/i,
    FALL => qr/(?:^|\b)FALL[^S]*\.?(?:\b|$)/i,
    FLS  => qr/(?:^|\b)FA?L+S\.?(?:\b|$)/i,
    FRY  => qr/(?:^|\b)FE?R+Y\.?(?:\b|$)/i,
    FLD  => qr/(?:^|\b)F(?:IE)?LD[^S]*\.?(?:\b|$)/i,
    FLDS => qr/(?:^|\b)F(?:IE)?LDS\.?(?:\b|$)/i,
    FLT  => qr/(?:^|\b)FLA?T[^S]*\.?(?:\b|$)/i,
    FLTS => qr/(?:^|\b)FLA?TS\.?(?:\b|$)/i,
    FRD  => qr/(?:^|\b)FO?RD[^S]*\.?(?:\b|$)/i,
    FRDS => qr/(?:^|\b)FO?RDS\.?(?:\b|$)/i,
    FRST => qr/(?:^|\b)FO?RE?STS?\.?(?:\b|$)/i,
    FRG  => qr/(?:^|\b)FO?RGE?[^S]*\.?(?:\b|$)/i,
    FRGS => qr/(?:^|\b)FO?RGE?S\.?(?:\b|$)/i,
    FRK  => qr/(?:^|\b)FO?RK[^S]*\.?(?:\b|$)/i,
    FRKS => qr/(?:^|\b)FO?RKS\.?(?:\b|$)/i,
    FT   => qr/(?:^|\b)FO?R?T[^S]*\.?(?:\b|$)/i,
    FWY  => qr/(?:^|\b)F(?:RE*)?WA?Y\.?(?:\b|$)/i,
    GDN  => qr/(?:^|\b)G(?:A?R)?DE?N[^S]*\.?(?:\b|$)/i,
    GDNS => qr/(?:^|\b)G(?:A?R)?DE?NS\.?(?:\b|$)/i,
    GTWY => qr/(?:^|\b)GA?TE?WA?Y\.?(?:\b|$)/i,
    GLN  => qr/(?:^|\b)GLE?N[^S]*\.?(?:\b|$)/i,
    GLNS => qr/(?:^|\b)GLE?NS\.?(?:\b|$)/i,
    GRN  => qr/(?:^|\b)GRE*N[^S]*\.?(?:\b|$)/i,
    GRNS => qr/(?:^|\b)GRE*NS\.?(?:\b|$)/i,
    GRV  => qr/(?:^|\b)GRO?VE?[^S]*\.?(?:\b|$)/i,
    GRVS => qr/(?:^|\b)GRO?VE?S\.?(?:\b|$)/i,
    HBR  => qr/(?:^|\b)H(?:(?:A?R)?BO?R|ARB)[^S]*\.?(?:\b|$)/i,
    HBRS => qr/(?:^|\b)H(?:A?R)?BO?RS\.?(?:\b|$)/i,
    HVN  => qr/(?:^|\b)HA?VE?N\.?(?:\b|$)/i,
    HTS  => qr/(?:^|\b)H(?:(?:EI)?GH?)?TS?\.?(?:\b|$)/i,
    HWY  => qr/(?:^|\b)HI?(?:GH?)?WA?Y\.?(?:\b|$)/i,
    HL   => qr/(?:^|\b)HI?L+[^A-Z]*\.?(?:\b|$)/i,
    HLS  => qr/(?:^|\b)HI?L+S\.?(?:\b|$)/i,
    HOLW => qr/(?:^|\b)HO?L+O?WS?\.?(?:\b|$)/i,
    INLT => qr/(?:^|\b)INLE?T\.?(?:\b|$)/i,
    IS   => qr/(?:^|\b)IS(?:LA?ND)?[^A-Z]*\.?(?:\b|$)/i,
    ISS  => qr/(?:^|\b)IS(?:LA?ND)?S\.?(?:\b|$)/i,
    ISLE => qr/(?:^|\b)ISLES?\.?(?:\b|$)/i,
    JCT  => qr/(?:^|\b)JU?CT(?:(?:IO)?N)?[^S]*\.?(?:\b|$)/i,
    JCTS => qr/(?:^|\b)JU?CT(?:(?:IO)?N)?S\.?(?:\b|$)/i,
    KY   => qr/(?:^|\b)KE?Y[^S]*\.?(?:\b|$)/i,
    KYS  => qr/(?:^|\b)KE?YS\.?(?:\b|$)/i,
    KNL  => qr/(?:^|\b)KNO?L+[^S]*\.?(?:\b|$)/i,
    KNLS => qr/(?:^|\b)KNO?L+S\.?(?:\b|$)/i,
    LK   => qr/(?:^|\b)LA?KE?[^S]*\.?(?:\b|$)/i,
    LKS  => qr/(?:^|\b)LA?KE?S\.?(?:\b|$)/i,
    LAND => qr/(?:^|\b)LAND[^A-Z]*\.?(?:\b|$)/i,
    LNDG => qr/(?:^|\b)LA?ND(?:I?N)?G\.?(?:\b|$)/i,
    LN   => qr/(?:^|\b)L(?:A?NES?|[AN])\.?(?:\b|$)/i,
    LGT  => qr/(?:^|\b)LI?GH?T\.?(?:\b|$)/i,
    LGTS => qr/(?:^|\b)LI?GH?TS\.?(?:\b|$)/i,
    LF   => qr/(?:^|\b)L(?:OA)?F\.?(?:\b|$)/i,
    LCK  => qr/(?:^|\b)LO?CK[^S]*\.?(?:\b|$)/i,
    LCKS => qr/(?:^|\b)LO?CKS\.?(?:\b|$)/i,
    LDG  => qr/(?:^|\b)LO?DGE?\.?(?:\b|$)/i,
    LOOP => qr/(?:^|\b)LOOPS?\.?(?:\b|$)/i,
    MALL => qr/(?:^|\b)MALL\.?(?:\b|$)/i,
    MNR  => qr/(?:^|\b)MA?NO?R[^S]*\.?(?:\b|$)/i,
    MNRS => qr/(?:^|\b)MA?NO?RS\.?(?:\b|$)/i,
    MDW  => qr/(?:^|\b)M(?:EA?)?DO?W[^S]*\.?(?:\b|$)/i,
    MDWS => qr/(?:^|\b)M(?:EA?)?DO?WS\.?(?:\b|$)/i,
    MEWS => qr/(?:^|\b)MEWS\.?(?:\b|$)/i,
    ML   => qr/(?:^|\b)MI?L+[^S]*\.?(?:\b|$)/i,
    MLS  => qr/(?:^|\b)MI?L+S\.?(?:\b|$)/i,
    MSN  => qr/(?:^|\b)MI?S+(?:IO)?N\.?(?:\b|$)/i,
    MTWY => qr/(?:^|\b)MO?T(?:OR)?WA?Y\.?(?:\b|$)/i,
    MT   => qr/(?:^|\b)M(?:OU)?N?T[^A-Z]*\.?(?:\b|$)/i,
    MTN  => qr/(?:^|\b)M(?:OU)?N?T(?:AI?|I)?N[^S]*\.?(?:\b|$)/i,
    MTNS => qr/(?:^|\b)M(?:OU)?N?T(?:AI?|I)?NS\.?(?:\b|$)/i,
    NCK  => qr/(?:^|\b)NE?CK\.?(?:\b|$)/i,
    ORCH => qr/(?:^|\b)ORCH(?:A?RD)?\.?(?:\b|$)/i,
    OVAL => qr/(?:^|\b)OVA?L\.?(?:\b|$)/i,
    OPAS => qr/(?:^|\b)O(?:VER)?PAS+\.?(?:\b|$)/i,
    PARK => qr/(?:^|\b)PA?R?K[^A-RT-Z]*\.?(?:\b|$)/i,
    PKWY => qr/(?:^|\b)PA?R?KW?A?YS?\.?(?:\b|$)/i,
    PASS => qr/(?:^|\b)PASS[^A-Z]*\.?(?:\b|$)/i,
    PSGE => qr/(?:^|\b)PA?S+A?GE\.?(?:\b|$)/i,
    PATH => qr/(?:^|\b)PATHS?\.?(?:\b|$)/i,
    PIKE => qr/(?:^|\b)PIKES?\.?(?:\b|$)/i,
    PNE  => qr/(?:^|\b)PI?NE[^S]*\.?(?:\b|$)/i,
    PNES => qr/(?:^|\b)PI?NES\.?(?:\b|$)/i,
    PL   => qr/(?:^|\b)PL(?:ACE)?[^A-Z]*\.?(?:\b|$)/i,
    PLN  => qr/(?:^|\b)PL(?:AI)?N[^ES]*\.?(?:\b|$)/i,
    PLNS => qr/(?:^|\b)PL(?:AI)?NE?S\.?(?:\b|$)/i,
    PLZ  => qr/(?:^|\b)PLA?ZA?\.?(?:\b|$)/i,
    PT   => qr/(?:^|\b)P(?:OI)?N?T[^S]*\.?(?:\b|$)/i,
    PTS  => qr/(?:^|\b)P(?:OI)?N?TS\.?(?:\b|$)/i,
    PRT  => qr/(?:^|\b)PO?RT[^S]*\.?(?:\b|$)/i,
    PRTS => qr/(?:^|\b)PO?RTS\.?(?:\b|$)/i,
    PR   => qr/(?:^|\b)PR(?:(?:AI?)?R(?:IE)?|[^KT]?)?\.?(?:\b|$)/i,
    RADL => qr/(?:^|\b)RAD(?:I[AE]?)?L?\.?(?:\b|$)/i,
    RAMP => qr/(?:^|\b)RAMP\.?(?:\b|$)/i,
    RNCH => qr/(?:^|\b)RA?NCH(?:E?S)?\.?(?:\b|$)/i,
    RPD  => qr/(?:^|\b)RA?PI?D[^S]*\.?(?:\b|$)/i,
    RPDS => qr/(?:^|\b)RA?PI?DS\.?(?:\b|$)/i,
    RST  => qr/(?:^|\b)RE?ST\.?(?:\b|$)/i,
    RDG  => qr/(?:^|\b)RI?DGE?[^S]*\.?(?:\b|$)/i,
    RDGS => qr/(?:^|\b)RI?DGE?S\.?(?:\b|$)/i,
    RIV  => qr/(?:^|\b)RI?VE?R?\.?(?:\b|$)/i,
    RD   => qr/(?:^|\b)R(?:OA)?D[^A-Z]*\.?(?:\b|$)(?:\b|$)/i,
    RDS  => qr/(?:^|\b)R(?:OA)?DS\.?(?:\b|$)/i,
    RTE  => qr/(?:^|\b)R(?:OU)?TE\.?(?:\b|$)/i,
    ROW  => qr/(?:^|\b)ROW\.?(?:\b|$)/i,
    RUE  => qr/(?:^|\b)RUE\.?(?:\b|$)/i,
    RUN  => qr/(?:^|\b)RUN\.?(?:\b|$)/i,
    SHL  => qr/(?:^|\b)SH(?:OA)?L[^S]*\.?(?:\b|$)/i,
    SHLS => qr/(?:^|\b)SH(?:OA)?LS\.?(?:\b|$)/i,
    SHR  => qr/(?:^|\b)SH(?:OA?)?RE?[^S]*\.?(?:\b|$)/i,
    SHRS => qr/(?:^|\b)SH(?:OA?)?RE?S\.?(?:\b|$)/i,
    SKWY => qr/(?:^|\b)SKY?W?A?YS?\.?(?:\b|$)/i,
    SPG  => qr/(?:^|\b)SP(?:RI?)?N?G[^S]*\.?(?:\b|$)/i,
    SPGS => qr/(?:^|\b)SP(?:RI?)?N?GS\.?(?:\b|$)/i,
    SPUR => qr/(?:^|\b)SPURS?\.?(?:\b|$)/i,
    SQ   => qr/(?:^|\b)SQU?A?R?E?[^S]*\.?(?:\b|$)/i,
    SQS  => qr/(?:^|\b)SQU?A?R?E?S\.?(?:\b|$)/i,
    STA  => qr/(?:^|\b)ST(?:N|AT?(?:IO)?N?)\.?(?:\b|$)/i,
    STRA => qr/(?:^|\b)STR(?:VN|AV?E?N?U?E?)\.?(?:\b|$)/i,
    STRM => qr/(?:^|\b)STRE?A?ME?\.?(?:\b|$)/i,
    ST   => qr/(?:^|\b)ST(?:\.|R(?:EE)?T?\.?)?(?:\b|$)/i,
    STS  => qr/(?:^|\b)STR?E*T?S\.?(?:\b|$)/i,
    SMT  => qr/(?:^|\b)SU?M+I?T+\.?(?:\b|$)/i,
    TER  => qr/(?:^|\b)TER(?:R(?:ACE)?)?\.?(?:\b|$)/i,
    TRWY => qr/(?:^|\b)TH?R(?:OUGH)?WA?Y\.?(?:\b|$)/i,
    TRCE => qr/(?:^|\b)TRA?CES?\.?(?:\b|$)/i,
    TRAK => qr/(?:^|\b)TRA?C?KS?\.?(?:\b|$)/i,
    TRFY => qr/(?:^|\b)TRA?F(?:FICWA)?Y\.?(?:\b|$)/i,
    TRL  => qr/(?:^|\b)TR(?:(?:AI)?LS?\.?|\.?)(?:\b|$)/i,
    TUNL => qr/(?:^|\b)TUNN?E?LS?\.?(?:\b|$)/i,
    TPKE => qr/(?:^|\b)T(?:U?RN?)?PI?KE?\.?(?:\b|$)/i,
    UPAS => qr/(?:^|\b)U(?:NDER)?PA?SS?\.?(?:\b|$)/i,
    UN   => qr/(?:^|\b)U(?:NIO)?N[^IS]*\.?(?:\b|$)/i,
    UNS  => qr/(?:^|\b)U(?:NIO)?NS\.?(?:\b|$)/i,
    VLY  => qr/(?:^|\b)VA?LL?E?Y[^S]*\.?(?:\b|$)/i,
    VLYS => qr/(?:^|\b)VA?LL?E?YS\.?(?:\b|$)/i,
    VIA  => qr/(?:^|\b)V(?:IA)?(?:DU?CT)?\.?(?:\b|$)/i,
    VW   => qr/(?:^|\b)V(?:IE)?W[^S]?\.?(?:\b|$)/i,
    VWS  => qr/(?:^|\b)V(?:IE)?WS\.?(?:\b|$)/i,
    VLG  => qr/(?:^|\b)V(?:LG|ILL(?:I?AGE?)?)[^ES]?\.?(?:\b|$)/i,
    VLGS => qr/(?:^|\b)V(?:LG|ILL(?:I?AGE?)?)[^E]?S\.?(?:\b|$)/i,
    VL   => qr/(?:^|\b)V(?:L[^GLY]*|I?LL?E)\.?(?:\b|$)/i,
    VIS  => qr/(?:^|\b)VI?S(?:TA?)?\.?(?:\b|$)/i,
    WALK => qr/(?:^|\b)WALKS?\.?(?:\b|$)/i,
    WALL => qr/(?:^|\b)WALL\.?(?:\b|$)/i,
    WAY  => qr/(?:^|\b)WA?Y[^S]*\.?(?:\b|$)/i,
    WAYS => qr/(?:^|\b)WA?YS\.?(?:\b|$)/i,
    WL   => qr/(?:^|\b)WE?LL?[^S]*\.?(?:\b|$)/i,
    WLS  => qr/(?:^|\b)WE?LL?S\.?(?:\b|$)/i,
);

# Defined in B - "Two-Letter State and Possession Abbreviations"
my %state_province_abbrev = (
        AL =>  qr/(?:^|\b)AL(?:A(?:\.|BAMA)?)?\.?(?:\b|$)/i,
        AK =>  qr/(?:^|\b)A(?:K|LAS(?:KA?)?)\.?(?:\b|$)/i,
        AS =>  qr/(?:^|\b)
            A(?:M(?:ER(?:ICAN)?)?)?\.?
            \s*
            S(?:AM(?:OA)?)?\.?
            |A\.?\s*S\.?
            (?:\b|$)/ix,
        AZ =>  qr/(?:^|\b)A(?:Z\.?|RI(?:\.|Z(?:\.|ONA)?)?)(?:\b|$)/i,
        AR =>  qr/(?:^|\b)AR(?:\.|K(?:\.|ANSAS))(?:\b|$)/i,
        CA =>  qr/(?:^|\b)CA(?:\.|L(?:\.|IF(?:\.|ORNIA)?))(?:\b|$)/i,
        CO =>  qr/(?:^|\b)CO(?:\.|L(?:\.|O(?:\.|RADO)?)?)(?:\b|$)/i,
        CT =>  qr/(?:^|\b)C(?:T\.?|ONN(?:\.|ECTICUT)?)(?:\b|$)/i,
        DE =>  qr/(?:^|\b)DE(?:\.|L(?:\.|EWARE)?)(?:\b|$)/i,
        DC =>  qr/(?:^|\b)
            D(?:\.|IST(?:\.|RICT)?)?
            \s*
            (?:O[.F]?)?
            \s*
            C(?:\.|OL(?:\.|UM(?:\.|BIA)?)?)?
            (?:\b|$)/ix,
        FM =>  qr/(?:^|\b)
            F(?:\.|ED(?:\.|ERATED)?)?
            \s*
            (?:S(?:T(?:ATES?)?)?\.?)?
            \s*
            (?:O[.F]?)?
            \s*
            M(?:IC(?:RO(?:NESIA)?)?)?\.?
            (?:\b|$)/ix,
        FL =>  qr/(?:^|\b)F(?:L(?:ORID?)?A?)\.?(?:\b|$)/i,
        GA =>  qr/(?:^|\b)G(?:EORGI)?A\.?(?:\b|$)/i,
        GU =>  qr/(?:^|\b)GU(?:\.|AM)?(?:\b|$)/i,
        HI =>  qr/(?:^|\b)H(?:AWAI)?I\.?(?:\b|$)/i,
        ID =>  qr/(?:^|\b)ID(?:\.|AHO)?(?:\b|$)/i,
        IL =>  qr/(?:^|\b)IL(?:\.|L(?:\.|INOIS)?)?(?:\b|$)/i,
        IN =>  qr/(?:^|\b)IN(?:D(?:\.|IANA)?)?\.?(?:\b|$)/i,
        IA =>  qr/(?:^|\b)I(?:OW)?A\.?(?:\b|$)/i,
        KS =>  qr/(?:^|\b)K(?:AN)?(?:SA)?(?:S)?\.?(?:\b|$)/i,
        KY =>  qr/(?:^|\b)K(?:EN)?(?:TUCK)?(?:Y)?\.?(?:\b|$)/i,
        LA =>  qr/(?:^|\b)L(?:OUIS)?(?:IAN)?A?\.?(?:\b|$)/i,
        ME =>  qr/(?:^|\b)M(?:AIN)?E\.?(?:\b|$)/i,
        MH =>  qr/(?:^|\b)(?:MARSH(?:ALL?)?\.?\s*IS(?:LANDS?)?|MH)\.?(?:\b|$)/i,
        MD =>  qr/(?:^|\b)M(?:ARYLA?N)?D\.?(?:\b|$)/i,
        MA =>  qr/(?:^|\b)MA(?:SS(?:\.|ACHUSETTS)?)?\.?(?:\b|$)/i,
        MI =>  qr/(?:^|\b)MI(?:CH(?:IGAN)?)?\.?(?:\b|$)/i,
        MN =>  qr/(?:^|\b)M(?:IN)?N(?:ESOTA)?\.?(?:\b|$)/i,
        MS =>  qr/(?:^|\b)M(?:IS)?S(?:ISSIPPI)?\.?(?:\b|$)/i,
        MO =>  qr/(?:^|\b)M(?:ISS)?O(?:URI)?\.?(?:\b|$)/i,
        MT =>  qr/(?:^|\b)M(?:ON)?T(?:ANA)?\.?(?:\b|$)/i,
        NE =>  qr/(?:^|\b)NEB?(?:R(?:ASKA)?)?\.?(?:\b|$)/i,
        NV =>  qr/(?:^|\b)NE?V(?:ADA)?\.?(?:\b|$)/i,
        NH =>  qr/(?:^|\b)N(?:EW)?\.?\s*H(?:AMPS?(?:HIRE)?)?\.?(?:\b|$)/i,
        NJ =>  qr/(?:^|\b)N(?:EW)?\.?\s*J(?:ERS?(?:EY)?)?\.?(?:\b|$)/i,
        NM =>  qr/(?:^|\b)N(?:EW)?\.?\s*M(?:EX(?:ICO)?)?\.?(?:\b|$)/i,
        NY =>  qr/(?:^|\b)N(?:EW)?\.?\s*Y(?:ORK)?\.?(?:\b|$)/i,
        NC =>  qr/(?:^|\b)N(?:OR)?(?:TH)?\.?\s*C(?:AR(?:OLINA?)?)?\.?(?:\b|$)/i,
        ND =>  qr/(?:^|\b)N(?:OR)?(?:TH)?\.?\s*D(?:AK(?:OTA)?)?\.?(?:\b|$)/i,
        MP =>  qr/(?:^|\b)
            (?:N(?:OR)?(?:TH(?:ERN)?)?\.?
                \s*
                MARI?(?:ANA)?\.?
                \s*
                I(?:S(?:LANDS?)?)?\.?
            |MP\.?)
            (?:\b|$)/ix,
        OH =>  qr/(?:^|\b)OH(?:IO)?\.?(?:\b|$)/i,
        OK =>  qr/(?:^|\b)OK(?:LA(?:\.|HOMA)?)?\.?(?:\b|$)/i,
        OR =>  qr/(?:^|\b)OR(?:E(?:G(?:ON)?)?)?\.?(?:\b|$)/i,
        PA =>  qr/(?:^|\b)P(?:ENNS?(?:YLVANIA)?|A)\.?(?:\b|$)/i,
        PW =>  qr/(?:^|\b)P(?:AL(?:AU)?|W)\.?(?:\b|$)/i,
        PR =>  qr/(?:^|\b)PU?(?:ER(?:T(?:O)?)?)?\.?\s*RI?(?:CO)?\.?(?:\b|$)/i,
        RI =>  qr/(?:^|\b)R(?:H(?:ODE)?)?\.?\s*I(?:S(?:LAND)?)?\.?(?:\b|$)/i,
        SC =>  qr/(?:^|\b)S(?:OU)?(?:TH)?\.?\s*C(?:AR(?:OLINA?)?)?\.?(?:\b|$)/i,
        SD =>  qr/(?:^|\b)S(?:OU)?(?:TH)?\.?\s*D(?:AK(?:OTA)?)?\.?(?:\b|$)/i,
        TN =>  qr/(?:^|\b)TE?N(?:N(?:ESSEE)?)?\.?(?:\b|$)/i,
        TX =>  qr/(?:^|\b)TE?X(?:AS)?\.?(?:\b|$)/i,
        UT =>  qr/(?:^|\b)UT(?:AH)?\.?(?:\b|$)/i, 
        VT =>  qr/(?:^|\b)V(?:ER(?:MO?N?)?T?|T)\.?(?:\b|$)/i,
        VI =>  qr/(?:^|\b)V(?:IRGIN)?\.?\s*I(?:S(?:LANDS?)?)?\.?(?:\b|$)/i,
        VA =>  qr/(?:^|\b)V(?:IR(?:GINIA)?|A)\.?(?:\b|$)/i,
        WA =>  qr/(?:^|\b)WA(?:SH(?:INGTON)?)?\.?(?:\b|$)/i,
        WV =>  qr/(?:^|\b)W(?:EST)?\.?\s*V(?:IR(?:G(?:INIA)?)?|A)?\.?(?:\b|$)/i,
        WI =>  qr/(?:^|\b)WI(?:S(?:CONS?(?:IN)?)?)?\.?(?:\b|$)/i,
        WY =>  qr/(?:^|\b)WYO?(?:MING)?\.?(?:\b|$)/i,
        AE =>  qr/(?:^|\b)
            A(?:RM(?:(?:E|[\'\`])?D)?)?\.?
            \s*
            (?:F(?:OR(?:CES?)?)?\.?)?
            \s*
            (?:AF(?:R(?:ICA)?)?|
                CA(?:N(?:ADA)?)?|
                E(?:U(?:R(?:OPE)?)?)?|
                M(?:ID(?:DLE)?)?\.?\s*E(?:A?ST)?)\.?
            (?:\b|$)/ix,
        AA =>  qr/(?:^|\b)
            A(?:RM(?:(?:E|[\'\`])?D)?)?\.?
            \s*
            (?:F(?:OR(?:CES?)?)?\.?)?
            \s
            *A(?:M(?:ER(?:ICA)?)?)?\.?
            (?:\b|$)/ix,
        AP =>  qr/(?:^|\b)
            A(?:RM(?:(?:E|[\'\`])?D)?)?\.?
            \s*
            (?:F(?:OR(?:CES?)?)?\.?)?
            \s* P(?:\.|AC(?:\.|IFIC)?)?\.?
            (?:\b|$)/ix,
    );

sub standardize {
    my ($self, $address) = @_;

    my $newaddr = $address->clone;
    my $results = Geo::Address::Mail::Standardizer::Results->new(
        standardized_address => $newaddr );

    $self->_uppercase($newaddr, $results);
    $self->_remove_punctuation($newaddr, $results);
    $self->_replace_designators($newaddr, $results);
    $self->_replace_state_abbreviations($newaddr, $results);

    return $results;
}

# Make everything uppercase 212
sub _uppercase {
    my ($self, $addr, $results) = @_;

    # We won't mark anything as changed here because I personally don't think
    # the user cares if uppercasing is the only change.
    my @fields = qw(company name street street2 city state state country);
    foreach my $field (@fields) {
        $addr->$field(uc($addr->$field)) if defined($addr->$field);
    }
}

# Remove punctuation, none is really needed.  222
sub _remove_punctuation {
    my ($self, $addr, $results) = @_;

    my @fields = qw(company name street street2 city state state country);
    foreach my $field (@fields) {
        my $val = $addr->$field;
        next unless defined($val);

        if($val ne $addr->$field) {
            $results->set_changed($field, $val);
            $addr->$field($val);
        }
    }
}

# Replace Secondary Address Unit Designators, 213
# Uses Designators from 213.1, Appendix C1, and Appendix C2
sub _replace_designators {
    my ($self, $addr, $results) = @_;

    my @fields = qw(street street2);
    foreach my $field (@fields) {
        my $val = $addr->$field;
        next unless defined($val);

        foreach my $rd ( sort { $a cmp $b } keys(%range_designators) ) {
            if ( $val =~ $range_designators{$rd} ) {
                $val =~ s/$range_designators{$rd}/$rd/gi;
                $results->set_changed( $field, $val );
                $addr->$field($val);
            }
        }

        foreach my $d ( sort { $a cmp $b } keys(%designators) ) {
            if ( $val =~ $designators{$d} ) {
                $val =~ s/$designators{$d}/$d/gi;
                $results->set_changed( $field, $val );
                $addr->$field($val);
            }
        }

        foreach my $sd ( sort { $a cmp $b } keys(%street_suffix_abbrev) ) {
            if ( $val =~ $street_suffix_abbrev{$sd} ) {
                $val =~ s/$street_suffix_abbrev{$sd}/$sd/gi;
                $results->set_changed($field, $val);
                $addr->$field($val);
            }
        }
    }
}

# Replace State/Province/Possession Abbreviations
# Uses Abbreviations from Appendix B
sub _replace_state_abbreviations {
    my ($self, $addr, $results) = @_;

    my @fields = qw(state);
    foreach my $field (@fields) {
        my $val = $addr->$field;
        next unless defined($val);

        foreach my $st (sort{ $a cmp $b }keys(%state_province_abbrev)) {
            if($val =~ $state_province_abbrev{$st}) {
                $val =~ s/$state_province_abbrev{$st}/$st/gi;
                $results->set_changed($field, $val);
                $addr->$field($val);
            }
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;

=head1 NAME

Geo::Address::Mail::Standardizer::USPS - Offline implementation of USPS Postal Addressing Standards

=head1 SYNOPSIS

This module provides an offline implementation of the USPS Publication 28 - 
Postal Addressing Standards as defined by
L<http://pe.usps.com/text/pub28/welcome.htm>.

    my $std = Geo::Address::Mail::Standardizer::USPS->new;

    my $address = Geo::Address::Mail::US->new(
        name => 'Test Testerson',
        street => '123 Test Street',
        street2 => 'Apartment #2',
        city => 'Testville',
        state => 'TN',
        postal_code => '12345'
    );

    my $res = $std->standardize($address);
    my $corr = $res->standardized_address;

=head1 WARNING

This module is not a complete implementation of USPS Publication 28.  It
intends to be, but that will probably take a while.  In the meantime it
may be useful for testing or for pseudo-standardizaton.

=head1 USPS Postal Address Standards Implemented

This module currently handles the following sections from Publication 28:

=over 5

=item I<212 Format>

L<http://pe.usps.com/text/pub28/pub28c2_002.htm>

=item I<213.1 Common Designators>

L<http://pe.usps.com/text/pub28/pub28c2_003.htm>

Also, Appendix C1

L<http://pe.usps.com/text/pub28/pub28apc_002.html>

Also, Appendix C2

L<http://pe.usps.com/text/pub28/pub28apc_003.htm#ep538629>

=item I<222 Punctuation>

Punctuation is removed from all fields except C<postal_code>.  Note that
this isn't really kosher when using address ranges...

L<http://pe.usps.com/text/pub28/pub28c2_007.htm>

=back

=item I<211 Standardized Delivery Address Line and Last Line>

The C<state> field values are translated to their abbreviated form, as 
given in Appendix B.

L<http://pe.usps.com/text/pub28/pub28apb.htm>

=back

=item I<225.1 Overseas Locations>

Overseas military addresses translate the C<state> field as given in 
Appendix B.

L<http://pe.usps.com/text/pub28/pub28c2_010.htm>

=back

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

Albert Croft

=head1 COPYRIGHT & LICENSE

Copyright 2010 Cory G Watson.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

