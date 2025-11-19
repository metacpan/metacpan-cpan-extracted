// clang-format off
#ifndef __pepperenums_h__
#define __pepperenums_h__


/* the operation codes */
typedef enum
{
    /* open for transactioning after successful configuration */
    pepOperation_Open = 1,

    /* close */
    pepOperation_Close = 2,

    /* recovery operation in restart in case of a crash while a transaction was processed */
    pepOperation_Recovery = 3,

    /* transaction operation  */
    pepOperation_Transaction = 4,

    /* end of day a.k.a. settlement  */
    pepOperation_Settlement = 5,

    /* a utility function  */
    pepOperation_Utility = 6,

    /* an auxiliary function  */
    pepOperation_Auxiliary = 7,

    /*
     * a download license function
     * keep it here because it is not related to any instance but to the library itself
     * It is defined to be able to use the input/output options properly
     */
    pepOperation_DownloadLicense = 100
}
PEPOperation;

/* the state of the chili instance */
typedef enum
{
    pepState_INVALID                        = 0,

    pepState_Created                        = 1,

    pepState_Configuring                    = 2,
    pepState_ConfigureDone                  = 3,

    pepState_PreparingRecovery              = 4,
    pepState_PrepareRecoveryDone            = 5,
    pepState_StartingRecovery               = 6,
    pepState_StartRecoveryDone              = 7,
    pepState_ExecutingRecovery              = 8,
    pepState_ExecuteRecoveryDone            = 9,
    pepState_FinalizingRecovery             = 10,
    pepState_FinalizeRecoveryDone           = 11,

    pepState_PreparingOpen                  = 12,
    pepState_PrepareOpenDone                = 13,
    pepState_StartingOpen                   = 14,
    pepState_StartOpenDone                  = 15,
    pepState_ExecutingOpen                  = 16,
    pepState_ExecuteOpenDone                = 17,
    pepState_FinalizingOpen                 = 18,
    pepState_FinalizeOpenDone               = 19,

    pepState_PreparingTransaction           = 20,
    pepState_PrepareTransactionDone         = 21,
    pepState_StartingTransaction            = 22, 
    pepState_StartTransactionDone           = 23,
    pepState_ExecutingTransaction           = 24,
    pepState_ExecuteTransactionDone         = 25,
    pepState_FinalizingTransaction          = 26,
    pepState_FinalizeTransactionDone        = 27,

    pepState_PreparingSettlement            = 28,
    pepState_PrepareSettlementDone          = 29,
    pepState_StartingSettlement             = 30,
    pepState_StartSettlementDone            = 31,
    pepState_ExecutingSettlement            = 32,
    pepState_ExecuteSettlementDone          = 33,
    pepState_FinalizingSettlement           = 34,
    pepState_FinalizeSettlementDone         = 35,

    pepState_PreparingClose                 = 36,
    pepState_PrepareCloseDone               = 37,
    pepState_StartingClose                  = 38,
    pepState_StartCloseDone                 = 39,
    pepState_ExecutingClose                 = 40,
    pepState_ExecuteCloseDone               = 41,
    pepState_FinalizingClose                = 42,
    pepState_FinalizeCloseDone              = 43,

    pepState_Unavailable                    = 44,

    pepState_Auxiliary                      = 45,
    pepState_AuxiliaryDone                  = 46
}
PEPState;

/* pepUtility functions */
typedef enum
{
    //dh the invalid value
    pepUtilityCode_INVALID = 0,


    pepUtilityCode_GetState = 1
}
PEPUtilityCode;

/* pepAuxiliary functions */
typedef enum
{
    //dh the invalid value
    pepAuxiliaryCode_INVALID = 0,

    /* use the terminal as printer */
    pepAuxiliaryCode_PrintData = 1,

    /* perform diagnosis of the terminal */
    pepAuxiliaryCode_Diagnosis = 2,

    /* perform initialization of the terminal */
    pepAuxiliaryCode_Initialization = 3,

    /* gets terminal status */
    pepAuxiliaryCode_StatusEnquiry = 4,

    /* Reset terminal */
    pepAuxiliaryCode_ResetTerminal = 5,

    /* instruct terminal to send offline transactions */
    pepAuxiliaryCode_SendOfflineTransactions  = 100,

    /* display menu on the terminal screen */
    pepAuxiliaryCode_DisplayMenu = 901,

    /* display text on the terminal screen */
    pepAuxiliaryCode_DisplayText = 902,

    /* display text on the terminal screen and waits for user response */
    pepAuxiliaryCode_DisplayTextAndGetResponse = 903,

    /* display image(s) and awaits for the user input - key or graphical input */
    pepAuxiliaryCode_DisplayImageWithInput = 904,

    /* display image(s) and awaits for the user input - key or graphical input */
    pepAuxiliaryCode_DisplayImage = 905,

    /* aborts ongoing terminal's operation. the success is not guaranteed */
    pepAuxiliaryCode_AbortOperation = 999,

    /* get customer details */
    pepAuxiliaryCode_GetCustomerDetails = 1001
}
PEPAuxiliaryCode;

/* the event type values */
typedef enum
{
    /* an output event */
    pepCallbackEvent_Output = 1,

    /* an input event */
    pepCallbackEvent_Input = 2
}
PEPCallbackEvent;


/* the event type values */
typedef enum
{
    /* ==== SECTION OUTPUT OPTION VALUES ==== */

    /* an intermediate status event occured */
    pepCallbackOption_IntermediateStatus = 1,

    /* loyalty information callback is not any more supported in new pepper. Such information is returned in the output option list */

    /* ticket callback is not any more supported in new pepper. Such information is returned in the output option list */

    /* an asynchronous operation has finished */
    pepCallbackOption_OperationFinished = 8,

    /* an intermediate ticket event has occured */
    pepCallbackOption_IntermediateTicket = 16,

    /* taxfree output callback is not any more supported in new pepper. Such information is returned in the output option list */

    /* ==== SECTION INPUT OPTION VALUES ==== */

    /* request for a selection list */
    pepCallbackOption_SelectionList = 0x10000,

    /* request for a numerical input */
    pepCallbackOption_NumericalInput = 0x20000,

    /* request for an alphanumerical input */
    pepCallbackOption_AlphanumericalInput = 0x40000,

    /* request for a complex input */
    pepCallbackOption_ComplexInput = 0x80000

    /* request for additional data is not any more supported in new pepper. Such information must be contained in the input option list */
}
PEPCallbackOption;


/* the possible transaction types */
typedef enum
{
    /* ==== SECTION GOODS PAYMENT (1x) ==== */

    /* payment of goods */
    pepTransactionType_GoodsPayment = 11,

    /* reversal of payment of goods */
    pepTransactionType_VoidGoodsPayment = 12,

    /* payment of goods with tip line */
    pepTransactionType_GoodsPaymentWithTip = 13,



    /* ==== SECTION CASH ADVANCE (2x) ==== */

    /* cash advance */
    pepTransactionType_CashAdvance = 21,

    /* reversal of cash advance */
    pepTransactionType_VoidCashAdvance = 22,



    /* ==== SECTION REFERRAL (3x) ==== */

    /* referral (voice auth) */
    pepTransactionType_Referral = 31,



    /* ==== SECTION CREDIT (4x) ==== */

    /* credit (payment from merchant to customer) */
    pepTransactionType_Credit = 41,

    /* reversal of credit (payment from merchant to customer) */
    pepTransactionType_VoidCredit = 42,



    /* ==== SECTION RESERVATION (5x) ==== */

    /* reserve a specific amount on a credit card */
    pepTransactionType_Reservation = 51,

    /* increment an already existing reservation by a specific amount */
    pepTransactionType_IncrementReservation = 52,

    /* book a reservation */
    pepTransactionType_BookReservation = 53,

    /* void a previously booked reservation */
    pepTransactionType_VoidReservation = 54,

    /* decrement an laready existing reservation by a specifi amount. Some terminals will also do automatic booking. */
    pepTransactionType_DecrementReservation = 55,


    /* ==== SECTION VOUCHER CARDS (7x) ==== */

    /* retrieve the current balance on a voucher card */
    pepTransactionType_CardBalance = 71,

    /* active a new voucher card */
    pepTransactionType_CardActivation = 72,

    /* reversal active of a new voucher card */
    pepTransactionType_VoidCardActivation = 73,



    /* ==== SECTION CARD DATA (8x) ==== */

    /* retrieve the card data */
    pepTransactionType_ReadCardData = 81,


    /* ==== SECTION EFT IMPLEMENTATION SPECIFIC STUFF (19x) ==== */

    /* special transaction type, needed in Paylife Austria */
    pepTransactionType_LaterDemandedCardData = 191,

    /* special transaction type */
    pepTransactionType_RequestCoverCard = 192,

    /* Special upload of prepaid cards (CH) */
    pepTransactionType_TopUp = 193,

    /* reversal of special upload of prepaid cards (CH) */
    pepTransactionType_VoidTopUp = 194,

    /* Special upload of prepaid cards (CH) */
    pepTransactionType_Eload = 195,


    /* ==== SECTION SEPCIAL FUNCTIONS (20x) ==== */

    /* retrieve the last receipt again */
    pepTransactionType_RepeatLastReceipt = 201,

    /* retrieve the whole result data of the last transaction again */
    pepTransactionType_RepeatLastTransactionData = 202,

    /* needed for certification cycle in some implementations */
    pepTransactionType_AutoTest = 203,

    /* taxfree ticket generation and printing */
    pepTransactionType_TaxFree = 204,

    /* cash authorization */
    pepTransactionType_CashAuthorization = 205,

    /* ... there is more to be added ... */
}
PEPTransactionType;



/* the possible ticket types */
typedef enum
{
    /* ==== SECTION CLIENT TICKETS (1x) ==== */

    /* a client ticket */
    pepTicketType_Client = 11,

    /* ==== SECTION MERCHANT TICKETS (2x) ==== */

    /* a merchant ticket */
    pepTicketType_Merchant = 21,

    /* ==== SECTION SETTLEMENT TICKETS (3x) ==== */

    /* a settlement ticket */
    pepTicketType_Settlement = 31,

    /* ==== SECTION CONFIG/INIT/OPEN/CLOSE (4x) ==== */

    /* a settlement ticket */
    pepTicketType_Open           = 41,
    pepTicketType_Close          = 42,
    pepTicketType_Configuration  = 43,
    pepTicketType_Initialization = 44,

    /* ==== OTHER (6x) ==== */

    pepTicketType_Intermediate   = 61,

    /* ==== SECTION VARIOUS (10x) ==== */

    /* various ticket types needed in some special option values */
    pepTicketType_Default        = 101,
    pepTicketType_Journal        = 102,
    pepTicketType_Reconciliation = 103,
    pepTicketType_Blocked        = 104,
    pepTicketType_Submission     = 105,
    pepTicketType_Transmission   = 106,
    pepTicketType_Reversal       = 107,
    pepTicketType_Log            = 108,
    pepTicketType_TaxFree        = 109,
    pepTicketType_Administration = 110
}
    PEPTicketType;

/* the possible line types in tickets */
typedef enum
{
    /* a text ticket line */
    pepTicketLineType_Text = 1,

    /* a text ticket line */
    pepTicketLineType_Barcode = 2
}
PEPTicketLineType;


/* the possible line alignments in tickets */
typedef enum
{
    /* left aligned text */
    pepTicketLineAlignment_Left = 1,

    /* right aligned text */
    pepTicketLineAlignment_Right = 2,

    /* centered text */
    pepTicketLineAlignment_Center = 3,
}
PEPTicketLineAlignment;


/* the possible line styles in tickets */
typedef enum
{
    /* normal text */
    pepTicketLineStyle_Normal = 1,

    /* italic text */
    pepTicketLineStyle_Italic = 2,

    /* bold text */
    pepTicketLineStyle_Bold = 3,
}
PEPTicketLineStyle;


/* the possible line height in tickets */
typedef enum
{
    /* normal height */
    pepTicketLineHeight_Normal = 1,

    /* double height */
    pepTicketLineHeight_Double = 2,

    /* half height */
    pepTicketLineHeight_Half = 3,
}
PEPTicketLineHeight;


/* the possible line width in tickets */
typedef enum
{
    /* normal height */
    pepTicketLineWidth_Normal = 1,

    /* double height */
    pepTicketLineWidth_Double = 2,

    /* half height */
    pepTicketLineWidth_Half = 3,
}
PEPTicketLineWidth;


typedef enum
{
    pepBaudRate_110    = 110,
    pepBaudRate_300    = 300,
    pepBaudRate_600    = 600,
    pepBaudRate_1200   = 1200,
    pepBaudRate_2400   = 2400,
    pepBaudRate_4800   = 4800,
    pepBaudRate_9600   = 9600,
    pepBaudRate_14400  = 14400,
    pepBaudRate_19200  = 19200,
    pepBaudRate_38400  = 38400,
    pepBaudRate_57600  = 57600,
    pepBaudRate_115200 = 115200,
    pepBaudRate_128000 = 128000,
    pepBaudRate_256000 = 256000
}
PEPBaudRate;


typedef enum
{
    //None - the value of char 'N'
    pepParity_None  = 78,

    //Even - the value of char 'E'
    pepParity_Even  = 69,

    //Odd - the value of char 'O'
    pepParity_Odd   = 79,

    //Mark - the value of char 'M'
    pepParity_Mark  = 77,

    //Space - the value of char 'S'
    pepParity_Space = 83
}
PEPParity;


typedef enum
{
    pepDataBits_7 = 7,
    pepDataBits_8 = 8,
}
PEPDataBits;


typedef enum
{
    /* the following definition is the same as windows uses for ONESTOPBIT, TWOSTOPBITS, ... */
    pepStopBits_1     = 0,
    pepStopBits_1dot5 = 1,
    pepStopBits_2     = 2
}
PEPStopBits;


typedef enum
{
    pepEcho_Default  = 1,
    pepEcho_On       = 2,
    pepEcho_Off      = 3,
    pepEcho_Asterisk = 4
}
PEPEcho;


typedef enum
{
    pepJournalHandling_None                     = 1,
    pepJournalHandling_ByPos                    = 2,
    pepJournalHandling_OneFilePerDay            = 3,
    pepJournalHandling_DeleteAfterSettlement    = 4,
    pepJournalHandling_Delete                   = 5,
    pepJournalHandling_Prepare                  = 6
}
PEPJournalHandling;


typedef enum
{
    pepPaymentMode_Default                              = 1,
    pepPaymentMode_Elv                                  = 2,
    pepPaymentMode_Tippable                             = 3,
    pepPaymentMode_Geldkarte                            = 4,
    pepPaymentMode_OnlineNoPin                          = 5,
    pepPaymentMode_Pin                                  = 6,
    pepPaymentMode_Signature                            = 7,
    pepPaymentMode_Epurse                               = 8,
    pepPaymentMode_Debit                                = 9,
    pepPaymentMode_Credit                               = 10,
    pepPaymentMode_GiftCard                             = 11,
    pepPaymentMode_Universal                            = 12,
    pepPaymentMode_Ecc                                  = 13,
    pepPaymentMode_OverTender                           = 14,
    pepPaymentMode_MediaSwap                            = 15,
    pepPaymentMode_Cup                                  = 16,
    pepPaymentMode_TerminalDecisionIncludingGeldkarte   = 17,
    pepPaymentMode_TerminalDecisionExcludingGeldkarte   = 18,
    pepPaymentMode_GirocardPin                          = 19,
    pepPaymentMode_Prasentcard							= 20,
    pepPaymentMode_Alipay                               = 21,
    pepPaymentMode_Wechatpay                            = 22,
    pepPaymentMode_Lsapipay                             = 23,
    pepPaymentMode_Instalment                           = 24,
    pepPaymentMode_MailOrderTelephoneOrder              = 25,
    pepPaymentMode_Card                                 = 26,
    pepPaymentMode_Cash                                 = 27,
    pepPaymentMode_Points                               = 28,
    pepPaymentMode_Wallets                              = 29,
    pepPaymentMode_UpiSale                              = 30,
    pepPaymentMode_UpiBharatQr                          = 31,
    pepPaymentMode_Googlepay                            = 32,
    pepPaymentMode_Amazonpay                            = 33,
    pepPaymentMode_Applepay                             = 34
}
PEPPaymentMode;


typedef enum
{
    //! void takes place only on terminal
    pepVoidPaymentMode_Terminal                         = 1,

    //! void takes place only on backend
    pepVoidPaymentMode_Backend                          = 2,
    
    //! void takes place on terminal with fallback to backend (if on terminal unsuccessful)
    pepVoidPaymentMode_Both                             = 3
}
PEPVoidPaymentMode;


typedef enum
{
    pepProtocolVersion_Eps42_1         = 1,
    pepProtocolVersion_Eps42_2         = 2,

    pepProtocolVersion_It_12           = 12,
    pepProtocolVersion_It_14           = 14,
    pepProtocolVersion_It_17           = 17,

    pepProtocolVersion_PointSe_4_2     = 42,
    pepProtocolVersion_PointSe_4_3     = 43,
    pepProtocolVersion_PointSe_4_4     = 44,

    pepProtocolVersion_Es_0            = 0,
    pepProtocolVersion_Es_1            = 1,
    pepProtocolVersion_Es_2            = 2,

    pepProtocolVersion_Vic_1079        = 1079,
    pepProtocolVersion_Vic_10711       = 10711,
    pepProtocolVersion_Vic_10713       = 10713,

    pepProtocolVersion_Thales_Thales   = 101,
    pepProtocolVersion_Thales_Hypercom = 102,
    pepProtocolVersion_Thales_Zvt      = 103,
    pepProtocolVersion_Thales_Esai     = 104
}
PEPProtocolVersion;


typedef enum
{
    pepReadCardDataFrom_MagStripe = 1,
    pepReadCardDataFrom_Chip      = 2,
    pepReadCardDataFrom_Both      = 3
}
PEPReadCardDataFrom;


typedef enum
{
    pepRechargeType_Easy  = 1,
    pepRechargeType_Prima = 2
}
PEPRechargeType;


typedef enum
{
    pepStatusHoldCard_Default = 0,
    pepStatusHoldCard_Jsm     = 2,
    pepStatusHoldCard_Chip    = 3

}
PEPStatusHoldCard;


typedef enum
{
    //! tickets are printed on POS (not on EFT device)
    pepTicketPrintingMode_Pos = 0,

    //! tickets are printed on EFT device (not on POS)
    pepTicketPrintingMode_Eft = 1,

    //! EFT device prints client receipt only, rest is printed on POS
    pepTicketPrintingMode_ClientOnlyOnEft = 2,

    //! no ticket at all is generated or printed
    pepTicketPrintingMode_None = 3,

    //! tickets are printed on terminal AND on ecr
    pepTicketPrintingMode_EcrAndTerminal = 4
}
PEPTicketPrintingMode;


typedef enum
{
    //! merchant ticket will be printed first
    pepTicketPrintingOrder_MerchantFirst = 0,

    //! client ticket will be printed first
    pepTicketPrintingOrder_ClientFirst = 1,
}
PEPTicketPrintingOrder;

typedef enum
{
    pepTicketRepetition_Default         = 1,
    pepTicketRepetition_Merchant        = 2,
    pepTicketRepetition_Customer        = 3,
    pepTicketRepetition_Journal         = 4,
    pepTicketRepetition_EndOfDay        = 5,
    pepTicketRepetition_Reconciliation  = 6,
    pepTicketRepetition_BlockedTickets  = 7,
    pepTicketRepetition_Submission      = 8,
    pepTicketRepetition_Transmission    = 9,
    pepTicketRepetition_Reversal        = 10,
    pepTicketRepetition_Log             = 11,
    pepTicketRepetition_Initalization   = 12,
    pepTicketRepetition_Configuration   = 13

}
PEPTicketRepetition;


typedef enum
{
    pepTinaMode_Activate   = 1,
    pepTinaMode_Deactivate = 2,
    pepTinaMode_Query      = 3
}
PEPTinaMode;


/**
* @brief an enum defining the currencies
*/
typedef enum
{
    //! United Arab Emirates dirham
    pepCurrency_UAEDirham                       = 784,  // AED

    //! Afghan afghani
    pepCurrency_AfghanAfghani                   = 971,  // AFN

    //! Alban lek
    pepCurrency_AlbanLek                        = 8,    // ALL

    //! Armenian dram
    pepCurrency_ArmenianDram                    = 51,   // AMD

    //! Netherlands Antillean guilder
    pepCurrency_NetherlandsAntilleanGuilder     = 532,  // ANG

    //! Angolan kwanza
    pepCurrency_Angolankwanza                   = 973,  // AOA

    //! Argentine peso
    pepCurrency_ArgentinePeso                   = 32,   // ARS

    //! Australian dollar
    pepCurrency_AustralianDollar                = 36,   // AUD

    //! Aruban florin
    pepCurrency_ArubanFlorin                    = 533,  // AWG

    //! Azerbaijani manat
    pepCurrency_AzerbaijaniManat                = 944,  // AZN

    //! Bosnia and Herzegovina Convertible mark
    pepCurrency_BhConvertibleMark               = 977,  // BAM

    //! Barbados dollar
    pepCurrency_BarbadosDollar                  = 52,   // BBD

    //! Bangladesian taka
    pepCurrency_BangladesianTaka                = 50,   // BDT

    //! Bulgarian lev
    pepCurrency_BulgarianLev                    = 975,  // BGN

    //! Bahraini dinar
    pepCurrency_BahrainiDinar                   = 48,   // BHD

    //! Burundi franc
    pepCurrency_BurundiFranc                    = 108,  // BIF

    //! Bermudian dollar
    pepCurrency_BermudianDollar                 = 60,   // BMD

    //! Brunei dollar
    pepCurrency_BruneiDollar                    = 96,   // BND

    //! Bolivian boliviano
    pepCurrency_BolivianBoliviano               = 68,   // BOB

    //! Bolivian Mvdol
    pepCurrency_BolivianMvdol                   = 984,  // BOV

    //! Brazilian real
    pepCurrency_BrazilianReal                   = 986,  // BRL

    //! Bahamian dollar
    pepCurrency_BahamianDollar                  = 44,   // BSD

    //! Bhutanese ngultrum
    pepCurrency_BhutaneseNgultrum               = 64,   // BTN

    //! Botswanian pula
    pepCurrency_BotswanianPula                  = 72,   // BWP

    //! Belarussian ruble
    pepCurrency_BelarussianRuble                = 974,  // BYR

    //! Belize dollar
    pepCurrency_BelizeDollar                    = 84,   // BZD

    //! Canadian dollar
    pepCurrency_CanadianDollar                  = 124,  // CAD

    //! Congolese franc
    pepCurrency_CongoleseFranc                  = 976,  // CDF

    //! WIR euro (swiss complementary currency)
    pepCurrency_WirEuro                         = 947,  // CHE

    //! Official Swiss franc
    pepCurrency_SwissFranc                      = 756,  // CHF

    //! WIR francs (swiss complementary currency    )
    pepCurrency_WirFranc                        = 948,  // CHW

    //! Chilean Unidades de fomento
    pepCurrency_ChileanUnidadesDeFomento        = 990,  // CLF

    //! Chilean peso
    pepCurrency_ChileanPeso                     = 152,  // CLP

    //! Chiese Yuan renminbi
    pepCurrency_ChieseYuanRenminbi              = 156,  // CNY

    //! Colombian peso
    pepCurrency_ColombianPeso                   = 170,  // COP

    //! Colombian Unidad de Valor Real
    pepCurrency_ColombianUnidadDeValorReal      = 970,  // COU

    //! Costa Rican colon
    pepCurrency_CostaRicanColon                 = 188,  // CRC

    //! Cuban peso convertible
    pepCurrency_CubanPesoConvertible            = 931,  // CUC

    //! Cuban peso
    pepCurrency_CubanPeso                       = 192,  // CUP

    //! Cape Verde escudo
    pepCurrency_CapeVerdeEscudo                 = 132,  // CVE

    //! Czech koruna
    pepCurrency_CzechKoruna                     = 203,  // CZK

    //! Djiboutian franc
    pepCurrency_DjiboutinFranc                  = 262,  // DJF

    //! Danish krone
    pepCurrency_DanishKrone                     = 208,  // DKK

    //! Dominican peso
    pepCurrency_DominicanPeso                   = 214,  // DOP

    //! Algerian dinar
    pepCurrency_AlgerianDinar                   = 12,   // DZD

    //! Egyptian pound
    pepCurrency_EgyptianPound                   = 818,  // EGP

    //! Eritrean nakfa
    pepCurrency_EritreanNakfa                   = 232,  // ERN

    //! Ethiopian birr
    pepCurrency_EthiopianBirr                   = 230,  // ETB

    //! Euro
    pepCurrency_Euro                            = 978,  // EUR

    //! Fiji Dollar
    pepCurrency_FijiDollar                      = 242,  // FJD

    //! Falkland Islands pound
    pepCurrency_FalklandIslandsPound            = 238,  // FKP

    //! British sound sterling
    pepCurrency_BritishPound                    = 826,  // GBP

    //! Georgian lari
    pepCurrency_GeorgianLari                    = 981,  // GEL

    //! Ghanaian cedi
    pepCurrency_GhanaianCedi                    = 936,  // GHS

    //! Gibraltar pound
    pepCurrency_GibraltarPound                  = 292,  // GIP

    //! Gambian dalasi
    pepCurrency_GambianDalasi                   = 270,  // GMD

    //! Guinean franc
    pepCurrency_GuineanFranc                    = 324,  // GNF

    //! Guatemalan quetzal
    pepCurrency_GuatemalanQuetzal               = 320,  // GTQ

    //! Guyanese dollar
    pepCurrency_GuyaneseDollar                  = 328,  // GYD

    //! Hong Kong dollar
    pepCurrency_HongKongDollar                  = 344,  // HKD

    //! Honduran lempira
    pepCurrency_HonduranLempira                 = 340,  // HNL

    //! Croatian kuna
    pepCurrency_CroatianKuna                    = 191,  // HRK

    //! Haitian gourde
    pepCurrency_HaitianGourde                   = 332,  // HTG

    //! Hungarian forint
    pepCurrency_HungarianForint                 = 348,  // HUF

    //! Indonesian rupiah
    pepCurrency_IndonesianRupiah                = 360,  // IDR

    //! Israeli new shekel
    pepCurrency_IsraeliNewShekel                = 376,  // ILS

    //! Indian rupee
    pepCurrency_IndianRupee                     = 356,  // INR

    //! Iraqi dinar
    pepCurrency_IraqiDinar                      = 368,  // IQD

    //! Iranian rial
    pepCurrency_IranianRial                     = 364,  // IRR

    //! Icelandic krona
    pepCurrency_IcelandicKrona                  = 352,  // ISK

    //! Jamaican dollar
    pepCurrency_JamaicanDollar                  = 388,  // JMD

    //! Jordanian dinar
    pepCurrency_JordanianDinar                  = 400,  // JOD

    //! Japanese yen
    pepCurrency_JapaneseYen                     = 392,  // JPY

    //! Kenyan shilling
    pepCurrency_KenyanShilling                  = 404,  // KES

    //! Kyrgyzstani som
    pepCurrency_KyrgyzstaniSom                  = 417,  // KGS

    //! Cambodian riel
    pepCurrency_CambodianRiel                   = 116,  // KHR

    //! Comoro franc
    pepCurrency_ComoroFranc                     = 174,  // KMF

    //! North Korean won
    pepCurrency_NorthKoreanWon                  = 408,  // KPW

    //! South Korean won
    pepCurrency_SouthKoreanWon                  = 410,  // KRW

    //! Kuwaiti dinar
    pepCurrency_KuwaitiDinar                    = 414,  // KWD

    //! Cayman Islands dollar
    pepCurrency_CaymanIslandsDollar             = 136,  // KYD

    //! Kazakhstani tenge
    pepCurrency_KazakhstaniTenge                = 398,  // KZT

    //! Lao kip
    pepCurrency_LaoKip                          = 418,  // LAK

    //! Lebanese pound
    pepCurrency_LebanesePound                   = 422,  // LBP

    //! Sri Lankan rupee
    pepCurrency_SriLankanRupee                  = 144,  // LKR

    //! Liberian dollar
    pepCurrency_LiberianDollar                  = 430,  // LRD

    //! Lesotho loti
    pepCurrency_LesothoLoti                     = 426,  // LSL

    //! Lithuanian litas
    pepCurrency_LithuanianLitas                 = 440,  // LTL

    //! Latvian lats
    pepCurrency_LatvianLats                     = 428,  // LVL

    //! Libyan dinar
    pepCurrency_LibyanDinar                     = 434,  // LYD

    //! Moroccan dirham
    pepCurrency_MoroccanDirham                  = 504,  // MAD

    //! Moldovan leu
    pepCurrency_MoldovanLeu                     = 498,  // MDL

    //! Malagasy ariary (Madagascar)
    pepCurrency_MalagasyAriary                  = 969,  // MGA

    //! Macedonian denar
    pepCurrency_MacedonianDenar                 = 807,  // MKD

    //! Myanma kyat
    pepCurrency_MyanmaKyat                      = 104,  // MMK

    //! Mongolian tugrik
    pepCurrency_MongolianTugrik                 = 496,  // MNT

    //! Macanese pataca (Macau)
    pepCurrency_MacanesePataca                  = 446,  // MOP

    //! Mauritanian ouguiya
    pepCurrency_MauritanianOuguiya              = 478,  // MRO

    //! Mauritian rupee
    pepCurrency_MauritianRupee                  = 480,  // MUR

    //! Maldivian rufiyaa
    pepCurrency_MaldivianRufiyaa                = 462,  // MVR

    //! Malawian kwacha
    pepCurrency_MalawianKwacha                  = 454,  // MWK

    //! Mexican peso
    pepCurrency_MexicanPeso                     = 484,  // MXN

    //! Mexican Unidad de Inversion
    pepCurrency_MexicanUnidadDeInversion        = 979,  // MXV

    //! Malaysian ringgit
    pepCurrency_MalaysianRinggit                = 458,  // MYR

    //!Mozambican metical
    pepCurrency_MozambicanMetical               = 943,  // MZN

    //! Namibian dollar
    pepCurrency_NamibianDollar                  = 516,  // NAD

    //! Nigerian naira
    pepCurrency_NigerianNaira                   = 566,  // NGN

    //! Nicaraguan cordoba
    pepCurrency_NicaraguanCordoba               = 558,  // NIO

    //! Norwegian krone
    pepCurrency_NorwegianKrone                  = 578,  // NOK

    //! Nepalese rupee
    pepCurrency_NepaleseRupee                   = 524,  // NPR

    //! New Zealand dollar
    pepCurrency_NewZealandDollar                = 554,  // NZD

    //! Omani rial
    pepCurrency_OmaniRial                       = 512,  // OMR

    //! Panamanian balboa
    pepCurrency_PanamanianBalboa                = 590,  // PAB

    //! Peruvian nuevo sol
    pepCurrency_PeruvianNuevoSol                = 604,  // PEN

    //! Papua New Guinean kina
    pepCurrency_PapuaNewGuineanKina             = 598,  // PGK

    //! Philippine peso
    pepCurrency_PhilippinePeso                  = 608,  // PHP

    //! Pakistani rupee
    pepCurrency_PakistaniRupee                  = 586,  // PKR

    //! Polish zloty
    pepCurrency_PolishZloty                     = 985,  // PLN

    //! Paraguayan guarani
    pepCurrency_ParaguayanGuarani               = 600,  // PYG

    //! Qatari riyal
    pepCurrency_QatariRiyal                     = 634,  // QAR

    //! Romanian new leu
    pepCurrency_RomanianNewLeu                  = 946,  // RON

    //! Serbian dinar
    pepCurrency_SerbianDinar                    = 941,  // RSD

    //! Russian ruble
    pepCurrency_RussianRuble                    = 643,  // RUB

    //! Rwandan franc
    pepCurrency_RwandanFranc                    = 646,  // RWF

    //! Saudi riyal
    pepCurrency_SaudiRiyal                      = 682,  // SAR

    //! Solomon Islands dollar
    pepCurrency_SolomonIslandsDollar            = 90,   // SBD

    //! Seychelles rupee
    pepCurrency_SeychellesRupee                 = 690,  // SCR

    //! Sudanese pound
    pepCurrency_SudanesePound                   = 938,  // SDG

    //! Swedish krona
    pepCurrency_SwedishKrona                    = 752,  // SKK

    //! Singapore dollar
    pepCurrency_Singaporedollar                 = 702,  // SGD

    //! Saint Helena pound
    pepCurrency_SaintHelenaPound                = 654,  // SHP

    //! Slovenian tolar
    pepCurrency_SlovenianTolar                  = 705,  // SIT

    //! Sierra Leonean leone
    pepCurrency_SierraLeoneanLeone              = 694,  // SLL

    //! Somali shilling
    pepCurrency_SomaliShilling                  = 706,  // SOS

    //! Surinamese dollar
    pepCurrency_SurinameseDollar                = 968,  // SRD

    //! South Sudanese pound
    pepCurrency_SouthSudanesePound              = 728,  // SSP

    //! S?o Tom� and Principe dobra
    pepCurrency_SaoTomeAndPrincipeDobra         = 678,  // STD

    //! Salvadoran colon
    pepCurrency_SalvadoranColon                 = 222,  // SVC

    //! Syrian pound
    pepCurrency_SyrianPound                     = 760,  // SYP

    //! Swazi lilangeni
    pepCurrency_SwaziLilangeni                  = 748,  // SZL

    //! Thai baht
    pepCurrency_ThaiBaht                        = 764,  // THB

    //! Tajikistani somoni
    pepCurrency_TajikistaniSomoni               = 972,  // TJS

    //! Turkmenistani manat
    pepCurrency_TurkmenistaniManat              = 934,  // TMT

    //! Tunisian dinar
    pepCurrency_TunisianDinar                   = 788,  // TND

    //! Tongan paanga
    pepCurrency_TonganPaanga                    = 776,  // TOP

    //! Turkish lira
    pepCurrency_TurkishLira                     = 949,  // TRY

    //! Trinidad and Tobago dollar
    pepCurrency_TrinidadandTobagoDollar         = 780,  // TTD

    //! New Taiwan dollar
    pepCurrency_NewTaiwanDollar                 = 901,  // TWD

    //! Tanzanian shilling
    pepCurrency_TanzanianShilling               = 834,  // TZS

    //! Ukrainian hryvnia
    pepCurrency_UkrainianHryvnia                = 980,  // UAH

    //! Ugandan shilling
    pepCurrency_UgandanShilling                 = 800,  // UGX

    //! US dollar
    pepCurrency_UsDollar                        = 840,  // USD

    //! United States dollar (next day) (funds code)
    pepCurrency_UnitedStatesDollarNextDay       = 997,  // USN

    //! United States dollar (SAME day) (funds code)
    pepCurrency_UnitedStatesDollarSameDay       = 998,  // USS

    //! Uruguay Peso en Unidades Indexadas
    pepCurrency_UruguayPesoEnUnidadesIndexadas  = 940,  // UYI

    //! Uruguayan peso
    pepCurrency_UruguayanPeso                   = 858,  // UYU

    //! Uzbekistan som
    pepCurrency_UzbekistanSom                   = 860,  // UZS

    //! Venezuelan bolivar
    pepCurrency_VenezuelanBolivar               = 937,  // VEF

    //! Vietnamese dong
    pepCurrency_VietnameseDong                  = 704,  // VND

    //! Vanuatu vatu
    pepCurrency_VanuatuVatu                     = 548,  // VUV

    //! Samoan tala
    pepCurrency_SamoanTala                      = 882,  // WST

    //! CFA franc BEAC
    pepCurrency_CfaFrancBeac                    = 950,  // XAF

    //! Silver
    pepCurrency_Silver                          = 961,  // XAG

    //! Gold
    pepCurrency_Gold                            = 959,  // XAU

    //! European Composite Unit
    pepCurrency_EuropeanCompositeUnit           = 955,  // XBA

    //! European Monetary Unit
    pepCurrency_EuropeanMonetaryUnit            = 956,  // XBB

    //! European Unit of Account 9
    pepCurrency_EuropeanUnitOfAccount9          = 957,  // XBC

    //! European Unit of Account 17
    pepCurrency_EuropeanUnitOfAccount17         = 958,  // XBD

    //! East Caribbean dollar
    pepCurrency_EastCaribbeanDollar             = 951,  // XCD

    //! Special drawing rights
    pepCurrency_SpecialDrawingRights            = 960,  // XDR

    //! CFA franc BCEAO
    pepCurrency_CfaFrancBceao                   = 952,  // XOF

    //! Palladium
    pepCurrency_Palladium                       = 964,  // XPD

    //! CFP franc
    pepCurrency_CfpFranc                        = 953,  // XPF

    //! Platinum
    pepCurrency_Platinum                        = 962,  // XPT

    //! Yemeni rial
    pepCurrency_Yemenirial                      = 886,  // YER

    //! South African rand
    pepCurrency_SouthAfricanrand                = 710,  // ZAR

    //! Zambian kwacha
    pepCurrency_ZambianKwacha                   = 894,  // ZMK

    //! Zimbabwe dollar
    pepCurrency_ZimbabweDollar	                = 932   // ZWL
}
PEPCurrency;


/**
* @brief an enum defining the currency sub unit width (e.g. 1 EUR == 100 Ct -> Sub unit width for EUR is 2, YEN has no sub units -> Sub unit width for YEN is 0)
*/
typedef enum
{
    //! Sub unit width 0.
    pepCurrencyExponent_0 = 0,

    //! Sub unit width 2. The usual value for most currencies.
    pepCurrencyExponent_2 = 2,

    //! Sub unit width 3.
    pepCurrencyExponent_3 = 3,

    //! Sub unit width 4.
    pepCurrencyExponent_4 = 4,
}
PEPCurrencyExponent;


/**
* @brief an enum defining the credential data source telling what the card data was read with
*/
typedef enum
{
    //ms data source is read with magnetic stripe
    pepCredentialDataSource_MagneticStripe = 1,

    //ms data source is read with chip
    pepCredentialDataSource_Chip           = 2,

    //ms data source is read manually
    pepCredentialDataSource_Manual         = 3,

    //ms data source is read with barcode
    pepCredentialDataSource_Barcode        = 4,

    //ms data source is read with nfc
    pepCredentialDataSource_Nfc            = 5,

    //ms data source is read with mail order or telephone order
    pepCredentialDataSource_MoTo           = 6
}
PEPCredentialDataSource;



/**
* @brief an enum defining the authorization type
*/
typedef enum
{
    //ms online authorization
    pepAuthorizationType_Online  = 1,

    //ms offline authorization
    pepAuthorizationType_Offline = 2
}
PEPAuthorizationType;



/**
* @brief an enum defining the authentification type
*/
typedef enum
{
    //ms without authentification
    pepAuthentificationType_None = 0,

    //ms authentified via signature
    pepAuthentificationType_Signature = 1,

    //ms authentified via PIN
    pepAuthentificationType_Pin = 2,

    //ms This is a mobile payment
    pepAuthentificationType_Mobile = 3,

    //cc both pin and signature
    pepAuthentificationType_PinWithSignature = 4,

    //cc other
    pepAuthentificationType_Other = 5,

    //cc when the client presents his ID
    pepAuthentificationType_Identification = 6,

    //cc when the client presents his ID and sign the ticket
    pepAuthentificationType_SignatureAndIdentification = 7,

    //mp invalid
    pepAuthentificationType_INVALID = 8,

    //mp unknown
    pepAuthentificationType_Unknown = 9
}
PEPAuthentificationType;


// Track presence
typedef enum
{
    //! track not available, "normal"
    pepTrackPresence_TrackNotAvailable = 0,

    //! track entered manually
    pepTrackPresence_TrackManual = 1,

    //! track entered in ISO2 format
    pepTrackPresence_TrackIso2 = 2,

    //! track entered with barcode
    pepTrackPresence_TrackBarcode = 3,

    //! track entered in ISO any format
    pepTrackPresence_TrackIsoAny = 4,

    //! track triggered to be keyed in on terminal
    pepTrackPresence_TrackKeyInOnTerminal = 5,

    //! raw track presence
    pepTrackPresence_TrackRaw = 9
}
PEPTrackPresence;


typedef enum
{
    pepCaseHandling_Keep    = 1,
    pepCaseHandling_ToUpper = 2,
    pepCaseHandling_ToLower = 3
}
PEPCaseHandling;


//VoucherType for VIC Implementation
typedef enum
{
    pepVicVoucherType_LunchPass			= 1,
    pepVicVoucherType_EcoPass			= 2,
    pepVicVoucherType_CadeauPass			= 3,
    pepVicVoucherType_SportCulturePass	= 4,
    pepVicVoucherType_BookPass			= 5,
    pepVicVoucherType_TransportPass		= 6
}
PEPVicVoucherType;

#endif /* __pepperenums_h__ */
// clang-format on
