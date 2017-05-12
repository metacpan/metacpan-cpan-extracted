
/* This file was generated automatically by the Snowball to ANSI C compiler */

#include "../runtime/header.h"

//static int r_R1(struct SN_env * z);
static int r_mark_regions(struct SN_env * z);
static int r_step5(struct SN_env * z);
static int r_step4(struct SN_env * z);
static int r_step3(struct SN_env * z);
static int r_step2(struct SN_env * z);
static int r_step1_noun(struct SN_env * z);
#ifdef __cplusplus
extern "C" {
#endif
extern int lithuanian_UTF_8_stem(struct SN_env * z);
#ifdef __cplusplus
}
#endif
#ifdef __cplusplus
extern "C" {
#endif


extern struct SN_env * lithuanian_UTF_8_create_env(void);
extern void lithuanian_UTF_8_close_env(struct SN_env * z);


#ifdef __cplusplus
}
#endif
static const symbol s_0_0[3] = { 't', 'a', 's' };
static const symbol s_0_1[3] = { 't', 'i', 's' };

static const struct among a_0[2] =
{
/*  0 */ { 3, s_0_0, -1, 1, 0},
/*  1 */ { 3, s_0_1, -1, 1, 0}
};

static const symbol s_1_0[1] = { 'a' };
static const symbol s_1_1[2] = { 'i', 'a' };
static const symbol s_1_2[4] = { 'u', 'o', 'j', 'a' };
static const symbol s_1_3[1] = { 'e' };
static const symbol s_1_4[3] = { 'o', 'j', 'e' };
static const symbol s_1_5[4] = { 'i', 'o', 'j', 'e' };
static const symbol s_1_6[4] = { 't', 'o', 'j', 'e' };
static const symbol s_1_7[3] = { 'y', 'j', 'e' };
static const symbol s_1_8[4] = { 0xC4, 0x97, 'j', 'e' };
static const symbol s_1_9[4] = { 'i', 'a', 'm', 'e' };
static const symbol s_1_10[5] = { 'a', 'j', 'a', 'm', 'e' };
static const symbol s_1_11[3] = { 'o', 's', 'e' };
static const symbol s_1_12[4] = { 'i', 'o', 's', 'e' };
static const symbol s_1_13[4] = { 'u', 'o', 's', 'e' };
static const symbol s_1_14[5] = { 'i', 'u', 'o', 's', 'e' };
static const symbol s_1_15[8] = { 'u', 'o', 's', 'i', 'u', 'o', 's', 'e' };
static const symbol s_1_16[3] = { 'y', 's', 'e' };
static const symbol s_1_17[4] = { 0xC4, 0x97, 's', 'e' };
static const symbol s_1_18[1] = { 'i' };
static const symbol s_1_19[2] = { 'a', 'i' };
static const symbol s_1_20[3] = { 'i', 'a', 'i' };
static const symbol s_1_21[2] = { 'e', 'i' };
static const symbol s_1_22[4] = { 'i', 'e', 'j', 'i' };
static const symbol s_1_23[3] = { 'o', 'j', 'i' };
static const symbol s_1_24[4] = { 'i', 'o', 'j', 'i' };
static const symbol s_1_25[4] = { 'u', 'o', 'j', 'i' };
static const symbol s_1_26[3] = { 'a', 's', 'i' };
static const symbol s_1_27[4] = { 'i', 'a', 's', 'i' };
static const symbol s_1_28[5] = { 'a', 'm', 'a', 's', 'i' };
static const symbol s_1_29[3] = { 'o', 's', 'i' };
static const symbol s_1_30[7] = { 0xC4, 0x97, 'j', 'a', 'u', 's', 'i' };
static const symbol s_1_31[2] = { 't', 'i' };
static const symbol s_1_32[4] = { 'a', 'n', 't', 'i' };
static const symbol s_1_33[5] = { 'i', 'a', 'n', 't', 'i' };
static const symbol s_1_34[4] = { 'i', 'n', 't', 'i' };
static const symbol s_1_35[3] = { 'y', 't', 'i' };
static const symbol s_1_36[2] = { 'u', 'i' };
static const symbol s_1_37[3] = { 'i', 'u', 'i' };
static const symbol s_1_38[2] = { 'o', 'j' };
static const symbol s_1_39[3] = { 'i', 'a', 'm' };
static const symbol s_1_40[4] = { 'a', 'j', 'a', 'm' };
static const symbol s_1_41[5] = { 'i', 'a', 'j', 'a', 'm' };
static const symbol s_1_42[2] = { 'o', 'm' };
static const symbol s_1_43[5] = { 'o', 's', 'i', 'o', 'm' };
static const symbol s_1_44[1] = { 'o' };
static const symbol s_1_45[2] = { 'i', 'o' };
static const symbol s_1_46[3] = { 'o', 'j', 'o' };
static const symbol s_1_47[3] = { 'i', 'm', 'o' };
static const symbol s_1_48[2] = { 'u', 'o' };
static const symbol s_1_49[1] = { 's' };
static const symbol s_1_50[2] = { 'a', 's' };
static const symbol s_1_51[3] = { 'i', 'a', 's' };
static const symbol s_1_52[4] = { 'u', 'm', 'a', 's' };
static const symbol s_1_53[2] = { 'e', 's' };
static const symbol s_1_54[3] = { 'i', 'e', 's' };
static const symbol s_1_55[2] = { 'i', 's' };
static const symbol s_1_56[3] = { 'a', 'i', 's' };
static const symbol s_1_57[4] = { 'i', 'a', 'i', 's' };
static const symbol s_1_58[7] = { 'a', 'i', 's', 'i', 'a', 'i', 's' };
static const symbol s_1_59[4] = { 'o', 'm', 'i', 's' };
static const symbol s_1_60[5] = { 'i', 'o', 'm', 'i', 's' };
static const symbol s_1_61[5] = { 0xC4, 0x97, 'm', 'i', 's' };
static const symbol s_1_62[4] = { 'a', 's', 'i', 's' };
static const symbol s_1_63[4] = { 'u', 's', 'i', 's' };
static const symbol s_1_64[3] = { 'a', 'm', 's' };
static const symbol s_1_65[4] = { 'i', 'a', 'm', 's' };
static const symbol s_1_66[4] = { 'i', 'e', 'm', 's' };
static const symbol s_1_67[7] = { 'i', 'e', 's', 'i', 'e', 'm', 's' };
static const symbol s_1_68[3] = { 'o', 'm', 's' };
static const symbol s_1_69[6] = { 'o', 's', 'i', 'o', 'm', 's' };
static const symbol s_1_70[4] = { 0xC4, 0x97, 'm', 's' };
static const symbol s_1_71[3] = { 'e', 'n', 's' };
static const symbol s_1_72[2] = { 'o', 's' };
static const symbol s_1_73[3] = { 'i', 'o', 's' };
static const symbol s_1_74[5] = { 'o', 's', 'i', 'o', 's' };
static const symbol s_1_75[5] = { 'u', 's', 'i', 'o', 's' };
static const symbol s_1_76[3] = { 'u', 'o', 's' };
static const symbol s_1_77[3] = { 'e', 'r', 's' };
static const symbol s_1_78[2] = { 'u', 's' };
static const symbol s_1_79[3] = { 'a', 'u', 's' };
static const symbol s_1_80[4] = { 'i', 'a', 'u', 's' };
static const symbol s_1_81[3] = { 'i', 'u', 's' };
static const symbol s_1_82[6] = { 'u', 'o', 's', 'i', 'u', 's' };
static const symbol s_1_83[5] = { 'u', 's', 'i', 'u', 's' };
static const symbol s_1_84[2] = { 'y', 's' };
static const symbol s_1_85[3] = { 0xC4, 0x85, 's' };
static const symbol s_1_86[4] = { 'i', 0xC4, 0x85, 's' };
static const symbol s_1_87[3] = { 0xC4, 0x97, 's' };
static const symbol s_1_88[5] = { 'a', 'm', 0xC4, 0x97, 's' };
static const symbol s_1_89[3] = { 0xC4, 0x99, 's' };
static const symbol s_1_90[3] = { 0xC5, 0xAB, 's' };
static const symbol s_1_91[3] = { 'a', 'n', 't' };
static const symbol s_1_92[4] = { 'i', 'a', 'n', 't' };
static const symbol s_1_93[1] = { 'u' };
static const symbol s_1_94[3] = { 'i', 'a', 'u' };
static const symbol s_1_95[2] = { 'i', 'u' };
static const symbol s_1_96[4] = { 'u', 'o', 'j', 'u' };
static const symbol s_1_97[3] = { 'u', 'm', 'u' };
static const symbol s_1_98[2] = { 0xC4, 0x85 };
static const symbol s_1_99[3] = { 'i', 0xC4, 0x85 };
static const symbol s_1_100[5] = { 0xC4, 0x85, 'j', 0xC4, 0x85 };
static const symbol s_1_101[2] = { 0xC4, 0x97 };
static const symbol s_1_102[2] = { 0xC4, 0x99 };
static const symbol s_1_103[2] = { 0xC4, 0xAF };
static const symbol s_1_104[5] = { 0xC4, 0x85, 'j', 0xC4, 0xAF };
static const symbol s_1_105[2] = { 0xC5, 0xB3 };
static const symbol s_1_106[3] = { 'i', 0xC5, 0xB3 };
static const symbol s_1_107[6] = { 't', 0xC5, 0xB3, 'j', 0xC5, 0xB3 };

static const struct among a_1[108] =
{
/*  0 */ { 1, s_1_0, -1, 1, 0},
/*  1 */ { 2, s_1_1, 0, 1, 0},
/*  2 */ { 4, s_1_2, 0, 1, 0},
/*  3 */ { 1, s_1_3, -1, 1, 0},
/*  4 */ { 3, s_1_4, 3, 1, 0},
/*  5 */ { 4, s_1_5, 4, 1, 0},
/*  6 */ { 4, s_1_6, 4, 1, 0},
/*  7 */ { 3, s_1_7, 3, 1, 0},
/*  8 */ { 4, s_1_8, 3, 1, 0},
/*  9 */ { 4, s_1_9, 3, 1, 0},
/* 10 */ { 5, s_1_10, 3, 1, 0},
/* 11 */ { 3, s_1_11, 3, 1, 0},
/* 12 */ { 4, s_1_12, 11, 1, 0},
/* 13 */ { 4, s_1_13, 11, 1, 0},
/* 14 */ { 5, s_1_14, 13, 1, 0},
/* 15 */ { 8, s_1_15, 14, 1, 0},
/* 16 */ { 3, s_1_16, 3, 1, 0},
/* 17 */ { 4, s_1_17, 3, 1, 0},
/* 18 */ { 1, s_1_18, -1, 1, 0},
/* 19 */ { 2, s_1_19, 18, 1, 0},
/* 20 */ { 3, s_1_20, 19, 1, 0},
/* 21 */ { 2, s_1_21, 18, 1, 0},
/* 22 */ { 4, s_1_22, 18, 1, 0},
/* 23 */ { 3, s_1_23, 18, 1, 0},
/* 24 */ { 4, s_1_24, 23, 1, 0},
/* 25 */ { 4, s_1_25, 23, 1, 0},
/* 26 */ { 3, s_1_26, 18, 1, 0},
/* 27 */ { 4, s_1_27, 26, 1, 0},
/* 28 */ { 5, s_1_28, 26, 1, 0},
/* 29 */ { 3, s_1_29, 18, 1, 0},
/* 30 */ { 7, s_1_30, 18, 1, 0},
/* 31 */ { 2, s_1_31, 18, 1, 0},
/* 32 */ { 4, s_1_32, 31, 1, 0},
/* 33 */ { 5, s_1_33, 32, 1, 0},
/* 34 */ { 4, s_1_34, 31, 1, 0},
/* 35 */ { 3, s_1_35, 31, 1, 0},
/* 36 */ { 2, s_1_36, 18, 1, 0},
/* 37 */ { 3, s_1_37, 36, 1, 0},
/* 38 */ { 2, s_1_38, -1, 1, 0},
/* 39 */ { 3, s_1_39, -1, 1, 0},
/* 40 */ { 4, s_1_40, -1, 1, 0},
/* 41 */ { 5, s_1_41, 40, 1, 0},
/* 42 */ { 2, s_1_42, -1, 1, 0},
/* 43 */ { 5, s_1_43, 42, 1, 0},
/* 44 */ { 1, s_1_44, -1, 1, 0},
/* 45 */ { 2, s_1_45, 44, 1, 0},
/* 46 */ { 3, s_1_46, 44, 1, 0},
/* 47 */ { 3, s_1_47, 44, 1, 0},
/* 48 */ { 2, s_1_48, 44, 1, 0},
/* 49 */ { 1, s_1_49, -1, 1, 0},
/* 50 */ { 2, s_1_50, 49, 1, 0},
/* 51 */ { 3, s_1_51, 50, 1, 0},
/* 52 */ { 4, s_1_52, 50, 1, 0},
/* 53 */ { 2, s_1_53, 49, 1, 0},
/* 54 */ { 3, s_1_54, 53, 1, 0},
/* 55 */ { 2, s_1_55, 49, 1, 0},
/* 56 */ { 3, s_1_56, 55, 1, 0},
/* 57 */ { 4, s_1_57, 56, 1, 0},
/* 58 */ { 7, s_1_58, 57, 1, 0},
/* 59 */ { 4, s_1_59, 55, 1, 0},
/* 60 */ { 5, s_1_60, 59, 1, 0},
/* 61 */ { 5, s_1_61, 55, 1, 0},
/* 62 */ { 4, s_1_62, 55, 1, 0},
/* 63 */ { 4, s_1_63, 55, 1, 0},
/* 64 */ { 3, s_1_64, 49, 1, 0},
/* 65 */ { 4, s_1_65, 64, 1, 0},
/* 66 */ { 4, s_1_66, 49, 1, 0},
/* 67 */ { 7, s_1_67, 66, 1, 0},
/* 68 */ { 3, s_1_68, 49, 1, 0},
/* 69 */ { 6, s_1_69, 68, 1, 0},
/* 70 */ { 4, s_1_70, 49, 1, 0},
/* 71 */ { 3, s_1_71, 49, 1, 0},
/* 72 */ { 2, s_1_72, 49, 1, 0},
/* 73 */ { 3, s_1_73, 72, 1, 0},
/* 74 */ { 5, s_1_74, 73, 1, 0},
/* 75 */ { 5, s_1_75, 73, 1, 0},
/* 76 */ { 3, s_1_76, 72, 1, 0},
/* 77 */ { 3, s_1_77, 49, 1, 0},
/* 78 */ { 2, s_1_78, 49, 1, 0},
/* 79 */ { 3, s_1_79, 78, 1, 0},
/* 80 */ { 4, s_1_80, 79, 1, 0},
/* 81 */ { 3, s_1_81, 78, 1, 0},
/* 82 */ { 6, s_1_82, 81, 1, 0},
/* 83 */ { 5, s_1_83, 81, 1, 0},
/* 84 */ { 2, s_1_84, 49, 1, 0},
/* 85 */ { 3, s_1_85, 49, 1, 0},
/* 86 */ { 4, s_1_86, 85, 1, 0},
/* 87 */ { 3, s_1_87, 49, 1, 0},
/* 88 */ { 5, s_1_88, 87, 1, 0},
/* 89 */ { 3, s_1_89, 49, 1, 0},
/* 90 */ { 3, s_1_90, 49, 1, 0},
/* 91 */ { 3, s_1_91, -1, 1, 0},
/* 92 */ { 4, s_1_92, 91, 1, 0},
/* 93 */ { 1, s_1_93, -1, 1, 0},
/* 94 */ { 3, s_1_94, 93, 1, 0},
/* 95 */ { 2, s_1_95, 93, 1, 0},
/* 96 */ { 4, s_1_96, 93, 1, 0},
/* 97 */ { 3, s_1_97, 93, 1, 0},
/* 98 */ { 2, s_1_98, -1, 1, 0},
/* 99 */ { 3, s_1_99, 98, 1, 0},
/*100 */ { 5, s_1_100, 98, 1, 0},
/*101 */ { 2, s_1_101, -1, 1, 0},
/*102 */ { 2, s_1_102, -1, 1, 0},
/*103 */ { 2, s_1_103, -1, 1, 0},
/*104 */ { 5, s_1_104, 103, 1, 0},
/*105 */ { 2, s_1_105, -1, 1, 0},
/*106 */ { 3, s_1_106, 105, 1, 0},
/*107 */ { 6, s_1_107, 105, 1, 0}
};

static const symbol s_2_0[2] = { 0xC4, 0x8D };
static const symbol s_2_1[3] = { 'd', 0xC5, 0xBE };

static const struct among a_2[2] =
{
/*  0 */ { 2, s_2_0, -1, 1, 0},
/*  1 */ { 3, s_2_1, -1, 2, 0}
};

static const symbol s_3_0[2] = { 'i', 'a' };
static const symbol s_3_1[2] = { 'y', 'b' };
static const symbol s_3_2[4] = { 'e', 'n', 'y', 'b' };
static const symbol s_3_3[2] = { 'i', 'j' };
static const symbol s_3_4[2] = { 'o', 'j' };
static const symbol s_3_5[3] = { 't', 'o', 'j' };
static const symbol s_3_6[3] = { 'u', 'o', 'j' };
static const symbol s_3_7[4] = { 'i', 'u', 'o', 'j' };
static const symbol s_3_8[3] = { 'a', 'u', 'j' };
static const symbol s_3_9[3] = { 0xC4, 0x97, 'j' };
static const symbol s_3_10[2] = { 'i', 'k' };
static const symbol s_3_11[5] = { 'i', 'n', 'i', 'n', 'k' };
static const symbol s_3_12[3] = { 't', 'o', 'k' };
static const symbol s_3_13[2] = { 'u', 'k' };
static const symbol s_3_14[3] = { 'i', 'u', 'k' };
static const symbol s_3_15[3] = { 't', 'u', 'k' };
static const symbol s_3_16[2] = { 'y', 'k' };
static const symbol s_3_17[4] = { 'i', 0xC5, 0xA1, 'k' };
static const symbol s_3_18[2] = { 'e', 'l' };
static const symbol s_3_19[3] = { 'e', 'k', 'l' };
static const symbol s_3_20[3] = { 'i', 'k', 'l' };
static const symbol s_3_21[3] = { 'y', 'k', 'l' };
static const symbol s_3_22[3] = { 'u', 'o', 'l' };
static const symbol s_3_23[3] = { 'i', 'u', 'l' };
static const symbol s_3_24[3] = { 0xC4, 0x97, 'l' };
static const symbol s_3_25[3] = { 'd', 'a', 'm' };
static const symbol s_3_26[3] = { 'i', 'a', 'm' };
static const symbol s_3_27[3] = { 'j', 'i', 'm' };
static const symbol s_3_28[4] = { 'o', 'j', 'i', 'm' };
static const symbol s_3_29[5] = { 0xC4, 0x97, 'j', 'i', 'm' };
static const symbol s_3_30[2] = { 'o', 'm' };
static const symbol s_3_31[2] = { 's', 'm' };
static const symbol s_3_32[2] = { 'u', 'm' };
static const symbol s_3_33[2] = { 'y', 'm' };
static const symbol s_3_34[3] = { 'i', 'z', 'm' };
static const symbol s_3_35[3] = { 'i', 'e', 'n' };
static const symbol s_3_36[5] = { 'u', 'o', 'm', 'e', 'n' };
static const symbol s_3_37[3] = { 's', 'e', 'n' };
static const symbol s_3_38[2] = { 'i', 'n' };
static const symbol s_3_39[3] = { 'a', 'i', 'n' };
static const symbol s_3_40[3] = { 'e', 's', 'n' };
static const symbol s_3_41[3] = { 't', 'y', 'n' };
static const symbol s_3_42[3] = { 0xC4, 0x97, 'n' };
static const symbol s_3_43[5] = { 'o', 'k', 0xC5, 0xA1, 'n' };
static const symbol s_3_44[3] = { 0xC5, 0xAB, 'n' };
static const symbol s_3_45[2] = { 'u', 'o' };
static const symbol s_3_46[3] = { 'i', 'u', 'o' };
static const symbol s_3_47[4] = { 'i', 'm', 'a', 's' };
static const symbol s_3_48[3] = { 't', 'a', 's' };
static const symbol s_3_49[2] = { 'e', 's' };
static const symbol s_3_50[3] = { 'u', 'o', 's' };
static const symbol s_3_51[4] = { 'i', 'a', 'u', 's' };
static const symbol s_3_52[4] = { 'a', 'v', 'u', 's' };
static const symbol s_3_53[3] = { 0xC4, 0x97, 's' };
static const symbol s_3_54[3] = { 'a', 'n', 't' };
static const symbol s_3_55[4] = { 'i', 'a', 'n', 't' };
static const symbol s_3_56[3] = { 'i', 'n', 't' };
static const symbol s_3_57[3] = { 'y', 's', 't' };
static const symbol s_3_58[2] = { 'y', 't' };
static const symbol s_3_59[4] = { 'u', 'l', 'y', 't' };
static const symbol s_3_60[3] = { 0xC4, 0x97, 't' };
static const symbol s_3_61[3] = { 'i', 'a', 'u' };
static const symbol s_3_62[2] = { 'a', 'v' };
static const symbol s_3_63[3] = { 'd', 'a', 'v' };
static const symbol s_3_64[3] = { 'i', 'a', 'v' };
static const symbol s_3_65[3] = { 'e', 'i', 'v' };
static const symbol s_3_66[3] = { 'a', 't', 'v' };
static const symbol s_3_67[3] = { 't', 'u', 'v' };
static const symbol s_3_68[3] = { 0xC4, 0x97, 'z' };
static const symbol s_3_69[3] = { 'o', 0xC4, 0x8D };
static const symbol s_3_70[4] = { 0xC5, 0xA1, 0xC4, 0x97 };
static const symbol s_3_71[3] = { 'u', 0xC5, 0xBE };

static const struct among a_3[72] =
{
/*  0 */ { 2, s_3_0, -1, 1, 0},
/*  1 */ { 2, s_3_1, -1, 1, 0},
/*  2 */ { 4, s_3_2, 1, 1, 0},
/*  3 */ { 2, s_3_3, -1, 1, 0},
/*  4 */ { 2, s_3_4, -1, 1, 0},
/*  5 */ { 3, s_3_5, 4, 1, 0},
/*  6 */ { 3, s_3_6, 4, 1, 0},
/*  7 */ { 4, s_3_7, 6, 1, 0},
/*  8 */ { 3, s_3_8, -1, 1, 0},
/*  9 */ { 3, s_3_9, -1, 1, 0},
/* 10 */ { 2, s_3_10, -1, 1, 0},
/* 11 */ { 5, s_3_11, -1, 1, 0},
/* 12 */ { 3, s_3_12, -1, 1, 0},
/* 13 */ { 2, s_3_13, -1, 1, 0},
/* 14 */ { 3, s_3_14, 13, 1, 0},
/* 15 */ { 3, s_3_15, 13, 1, 0},
/* 16 */ { 2, s_3_16, -1, 1, 0},
/* 17 */ { 4, s_3_17, -1, 1, 0},
/* 18 */ { 2, s_3_18, -1, 1, 0},
/* 19 */ { 3, s_3_19, -1, 1, 0},
/* 20 */ { 3, s_3_20, -1, 1, 0},
/* 21 */ { 3, s_3_21, -1, 1, 0},
/* 22 */ { 3, s_3_22, -1, 1, 0},
/* 23 */ { 3, s_3_23, -1, 1, 0},
/* 24 */ { 3, s_3_24, -1, 1, 0},
/* 25 */ { 3, s_3_25, -1, 1, 0},
/* 26 */ { 3, s_3_26, -1, 1, 0},
/* 27 */ { 3, s_3_27, -1, 1, 0},
/* 28 */ { 4, s_3_28, 27, 1, 0},
/* 29 */ { 5, s_3_29, 27, 1, 0},
/* 30 */ { 2, s_3_30, -1, 1, 0},
/* 31 */ { 2, s_3_31, -1, 1, 0},
/* 32 */ { 2, s_3_32, -1, 1, 0},
/* 33 */ { 2, s_3_33, -1, 1, 0},
/* 34 */ { 3, s_3_34, -1, 1, 0},
/* 35 */ { 3, s_3_35, -1, 1, 0},
/* 36 */ { 5, s_3_36, -1, 1, 0},
/* 37 */ { 3, s_3_37, -1, 1, 0},
/* 38 */ { 2, s_3_38, -1, 1, 0},
/* 39 */ { 3, s_3_39, 38, 1, 0},
/* 40 */ { 3, s_3_40, -1, 1, 0},
/* 41 */ { 3, s_3_41, -1, 1, 0},
/* 42 */ { 3, s_3_42, -1, 1, 0},
/* 43 */ { 5, s_3_43, -1, 1, 0},
/* 44 */ { 3, s_3_44, -1, 1, 0},
/* 45 */ { 2, s_3_45, -1, 1, 0},
/* 46 */ { 3, s_3_46, 45, 1, 0},
/* 47 */ { 4, s_3_47, -1, 1, 0},
/* 48 */ { 3, s_3_48, -1, 1, 0},
/* 49 */ { 2, s_3_49, -1, 1, 0},
/* 50 */ { 3, s_3_50, -1, 1, 0},
/* 51 */ { 4, s_3_51, -1, 1, 0},
/* 52 */ { 4, s_3_52, -1, 1, 0},
/* 53 */ { 3, s_3_53, -1, 1, 0},
/* 54 */ { 3, s_3_54, -1, 1, 0},
/* 55 */ { 4, s_3_55, 54, 1, 0},
/* 56 */ { 3, s_3_56, -1, 1, 0},
/* 57 */ { 3, s_3_57, -1, 1, 0},
/* 58 */ { 2, s_3_58, -1, 1, 0},
/* 59 */ { 4, s_3_59, 58, 1, 0},
/* 60 */ { 3, s_3_60, -1, 1, 0},
/* 61 */ { 3, s_3_61, -1, 1, 0},
/* 62 */ { 2, s_3_62, -1, 1, 0},
/* 63 */ { 3, s_3_63, 62, 1, 0},
/* 64 */ { 3, s_3_64, 62, 1, 0},
/* 65 */ { 3, s_3_65, -1, 1, 0},
/* 66 */ { 3, s_3_66, -1, 1, 0},
/* 67 */ { 3, s_3_67, -1, 1, 0},
/* 68 */ { 3, s_3_68, -1, 1, 0},
/* 69 */ { 3, s_3_69, -1, 1, 0},
/* 70 */ { 4, s_3_70, -1, 1, 0},
/* 71 */ { 3, s_3_71, -1, 1, 0}
};

static const symbol s_4_0[4] = { 'i', 'a', 'n', 't' };
static const symbol s_4_1[7] = { 'i', 0xC5, 0xAB, 'k', 0xC5, 0xA1, 't' };

static const struct among a_4[2] =
{
/*  0 */ { 4, s_4_0, -1, 1, 0},
/*  1 */ { 7, s_4_1, -1, 1, 0}
};

static const unsigned char g_v[] = { 17, 65, 16, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 0, 64, 1, 0, 64, 0, 0, 0, 0, 0, 0, 0, 4, 4 };

static const symbol s_0[] = { 't' };
static const symbol s_1[] = { 't' };
static const symbol s_2[] = { 'd' };

static int r_mark_regions(struct SN_env * z) {
    z->I[0] = z->l;
    z->I[1] = z->l;
    {   int c1 = z->c; /* do, line 113 */
        {    /* gopast */ /* grouping v, line 114 */
            int ret = out_grouping_U(z, g_v, 97, 371, 1);
            if (ret < 0) goto lab0;
            z->c += ret;
        }
        {    /* gopast */ /* non v, line 114 */
            int ret = in_grouping_U(z, g_v, 97, 371, 1);
            if (ret < 0) goto lab0;
            z->c += ret;
        }
        z->I[0] = z->c; /* setmark p1, line 114 */
        {    /* gopast */ /* non v, line 115 */
            int ret = in_grouping_U(z, g_v, 97, 371, 1);
            if (ret < 0) goto lab0;
            z->c += ret;
        }
        z->I[1] = z->c; /* setmark p2, line 115 */
    lab0:
        z->c = c1;
    }
    return 1;
}

/*static int r_R1(struct SN_env * z) {
    if (!(z->I[0] <= z->c)) return 0;
    return 1;
}*/

static int r_step1_noun(struct SN_env * z) {
    int among_var;
    z->ket = z->c; /* [, line 134 */
    if (z->c - 2 <= z->lb || z->p[z->c - 1] != 115) return 0;
    among_var = find_among_b(z, a_0, 2); /* substring, line 134 */
    if (!(among_var)) return 0;
    z->bra = z->c; /* ], line 134 */
    switch(among_var) {
        case 0: return 0;
        case 1:
            {   int ret = slice_from_s(z, 1, s_0); /* <-, line 138 */
                if (ret < 0) return ret;
            }
            z->B[0] = 1; /* set PRE, line 138 */
            break;
    }
    return 1;
}

static int r_step2(struct SN_env * z) {
    int among_var;
    {   int m1 = z->l - z->c; (void)m1; /* not, line 146 */
        if (!(z->B[0])) goto lab0; /* Boolean test PRE, line 146 */
        return 0;
    lab0:
        z->c = z->l - m1;
    }
    z->ket = z->c; /* [, line 147 */
    among_var = find_among_b(z, a_1, 108); /* substring, line 147 */
    if (!(among_var)) return 0;
    z->bra = z->c; /* ], line 147 */
    switch(among_var) {
        case 0: return 0;
        case 1:
            z->B[1] = 1; /* set FOUND, line 167 */
            {   int ret = slice_del(z); /* delete, line 167 */
                if (ret < 0) return ret;
            }
            break;
    }
    return 1;
}

static int r_step3(struct SN_env * z) {
    int among_var;
    if (!(z->B[1])) return 0; /* Boolean test FOUND, line 175 */
    z->ket = z->c; /* [, line 176 */
    if (z->c - 1 <= z->lb || (z->p[z->c - 1] != 141 && z->p[z->c - 1] != 190)) return 0;
    among_var = find_among_b(z, a_2, 2); /* substring, line 176 */
    if (!(among_var)) return 0;
    z->bra = z->c; /* ], line 176 */
    switch(among_var) {
        case 0: return 0;
        case 1:
            {   int ret = slice_from_s(z, 1, s_1); /* <-, line 178 */
                if (ret < 0) return ret;
            }
            z->B[2] = 1; /* set CHANGE, line 178 */
            break;
        case 2:
            {   int ret = slice_from_s(z, 1, s_2); /* <-, line 179 */
                if (ret < 0) return ret;
            }
            z->B[2] = 1; /* set CHANGE, line 179 */
            break;
    }
    return 1;
}

static int r_step4(struct SN_env * z) {
    int among_var;
    {   int m1 = z->l - z->c; (void)m1; /* and, line 187 */
        {   int m2 = z->l - z->c; (void)m2; /* or, line 187 */
            if (!(z->B[1])) goto lab1; /* Boolean test FOUND, line 187 */
            goto lab0;
        lab1:
            z->c = z->l - m2;
            if (!(z->B[0])) return 0; /* Boolean test PRE, line 187 */
        }
    lab0:
        z->c = z->l - m1;
        {   int m3 = z->l - z->c; (void)m3; /* not, line 187 */
            if (!(z->B[2])) goto lab2; /* Boolean test CHANGE, line 187 */
            return 0;
        lab2:
            z->c = z->l - m3;
        }
    }
    {   int i; for (i = 3; i > 0; i--) /* loop, line 187 */
        {               z->ket = z->c; /* [, line 189 */
        }
    }
    among_var = find_among_b(z, a_3, 72); /* substring, line 189 */
    if (!(among_var)) return 0;
    z->bra = z->c; /* ], line 189 */
    switch(among_var) {
        case 0: return 0;
        case 1:
            {   int ret = slice_del(z); /* delete, line 201 */
                if (ret < 0) return ret;
            }
            break;
    }
    return 1;
}

static int r_step5(struct SN_env * z) {
    int among_var;
    if (!(z->B[2])) return 0; /* Boolean test CHANGE, line 209 */
    z->ket = z->c; /* [, line 210 */
    if (z->c - 3 <= z->lb || z->p[z->c - 1] != 116) return 0;
    among_var = find_among_b(z, a_4, 2); /* substring, line 210 */
    if (!(among_var)) return 0;
    z->bra = z->c; /* ], line 210 */
    switch(among_var) {
        case 0: return 0;
        case 1:
            {   int ret = slice_del(z); /* delete, line 213 */
                if (ret < 0) return ret;
            }
            break;
    }
    return 1;
}

extern int lithuanian_UTF_8_stem(struct SN_env * z) {
    z->B[0] = 0; /* unset PRE, line 223 */
    z->B[1] = 0; /* unset FOUND, line 224 */
    z->B[2] = 0; /* unset CHANGE, line 225 */
    {   int c1 = z->c; /* do, line 226 */
        {   int ret = r_mark_regions(z);
            if (ret == 0) goto lab0; /* call mark_regions, line 226 */
            if (ret < 0) return ret;
        }
    lab0:
        z->c = c1;
    }
    z->lb = z->c; z->c = z->l; /* backwards, line 227 */

    {   int m2 = z->l - z->c; (void)m2; /* do, line 229 */
        {   int ret = r_step1_noun(z);
            if (ret == 0) goto lab1; /* call step1_noun, line 229 */
            if (ret < 0) return ret;
        }
    lab1:
        z->c = z->l - m2;
    }
    {   int m3 = z->l - z->c; (void)m3; /* do, line 230 */
        {   int ret = r_step2(z);
            if (ret == 0) goto lab2; /* call step2, line 230 */
            if (ret < 0) return ret;
        }
    lab2:
        z->c = z->l - m3;
    }
    {   int m4 = z->l - z->c; (void)m4; /* do, line 231 */
        {   int ret = r_step3(z);
            if (ret == 0) goto lab3; /* call step3, line 231 */
            if (ret < 0) return ret;
        }
    lab3:
        z->c = z->l - m4;
    }
    {   int m5 = z->l - z->c; (void)m5; /* do, line 232 */
        {   int ret = r_step4(z);
            if (ret == 0) goto lab4; /* call step4, line 232 */
            if (ret < 0) return ret;
        }
    lab4:
        z->c = z->l - m5;
    }
    {   int m6 = z->l - z->c; (void)m6; /* do, line 233 */
        {   int ret = r_step5(z);
            if (ret == 0) goto lab5; /* call step5, line 233 */
            if (ret < 0) return ret;
        }
    lab5:
        z->c = z->l - m6;
    }
    {   int m7 = z->l - z->c; (void)m7; /* do, line 234 */
        {   int ret = r_step3(z);
            if (ret == 0) goto lab6; /* call step3, line 234 */
            if (ret < 0) return ret;
        }
    lab6:
        z->c = z->l - m7;
    }
    z->c = z->lb;
    return 1;
}

extern struct SN_env * lithuanian_UTF_8_create_env(void) { return SN_create_env(0, 2, 3); }

extern void lithuanian_UTF_8_close_env(struct SN_env * z) { SN_close_env(z, 0); }

