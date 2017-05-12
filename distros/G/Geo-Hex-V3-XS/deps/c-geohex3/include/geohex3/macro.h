#ifndef GEOHEX3_MACRO_H
#define GEOHEX3_MACRO_H

#define GEOHEX3_MACRO_CAT_l(x, y) x##y
#define GEOHEX3_MACRO_CAT(x, y) GEOHEX3_MACRO_CAT_l(x, y)

/* gen: perl -E 'say "#define GEOHEX3_MACRO_BOOL_$_(entity, separator) entity separator GEOHEX3_MACRO_JOIN_${\$_-1}(entity, separator)" for 1..255' */
#define GEOHEX3_MACRO_BOOL(condition) GEOHEX3_MACRO_CAT(GEOHEX3_MACRO_BOOL_, condition)
#define GEOHEX3_MACRO_BOOL_0   0
#define GEOHEX3_MACRO_BOOL_1   1
#define GEOHEX3_MACRO_BOOL_2   1
#define GEOHEX3_MACRO_BOOL_3   1
#define GEOHEX3_MACRO_BOOL_4   1
#define GEOHEX3_MACRO_BOOL_5   1
#define GEOHEX3_MACRO_BOOL_6   1
#define GEOHEX3_MACRO_BOOL_7   1
#define GEOHEX3_MACRO_BOOL_8   1
#define GEOHEX3_MACRO_BOOL_9   1
#define GEOHEX3_MACRO_BOOL_10  1
#define GEOHEX3_MACRO_BOOL_11  1
#define GEOHEX3_MACRO_BOOL_12  1
#define GEOHEX3_MACRO_BOOL_13  1
#define GEOHEX3_MACRO_BOOL_14  1
#define GEOHEX3_MACRO_BOOL_15  1
#define GEOHEX3_MACRO_BOOL_16  1
#define GEOHEX3_MACRO_BOOL_17  1
#define GEOHEX3_MACRO_BOOL_18  1
#define GEOHEX3_MACRO_BOOL_19  1
#define GEOHEX3_MACRO_BOOL_20  1
#define GEOHEX3_MACRO_BOOL_21  1
#define GEOHEX3_MACRO_BOOL_22  1
#define GEOHEX3_MACRO_BOOL_23  1
#define GEOHEX3_MACRO_BOOL_24  1
#define GEOHEX3_MACRO_BOOL_25  1
#define GEOHEX3_MACRO_BOOL_26  1
#define GEOHEX3_MACRO_BOOL_27  1
#define GEOHEX3_MACRO_BOOL_28  1
#define GEOHEX3_MACRO_BOOL_29  1
#define GEOHEX3_MACRO_BOOL_30  1
#define GEOHEX3_MACRO_BOOL_31  1
#define GEOHEX3_MACRO_BOOL_32  1
#define GEOHEX3_MACRO_BOOL_33  1
#define GEOHEX3_MACRO_BOOL_34  1
#define GEOHEX3_MACRO_BOOL_35  1
#define GEOHEX3_MACRO_BOOL_36  1
#define GEOHEX3_MACRO_BOOL_37  1
#define GEOHEX3_MACRO_BOOL_38  1
#define GEOHEX3_MACRO_BOOL_39  1
#define GEOHEX3_MACRO_BOOL_40  1
#define GEOHEX3_MACRO_BOOL_41  1
#define GEOHEX3_MACRO_BOOL_42  1
#define GEOHEX3_MACRO_BOOL_43  1
#define GEOHEX3_MACRO_BOOL_44  1
#define GEOHEX3_MACRO_BOOL_45  1
#define GEOHEX3_MACRO_BOOL_46  1
#define GEOHEX3_MACRO_BOOL_47  1
#define GEOHEX3_MACRO_BOOL_48  1
#define GEOHEX3_MACRO_BOOL_49  1
#define GEOHEX3_MACRO_BOOL_50  1
#define GEOHEX3_MACRO_BOOL_51  1
#define GEOHEX3_MACRO_BOOL_52  1
#define GEOHEX3_MACRO_BOOL_53  1
#define GEOHEX3_MACRO_BOOL_54  1
#define GEOHEX3_MACRO_BOOL_55  1
#define GEOHEX3_MACRO_BOOL_56  1
#define GEOHEX3_MACRO_BOOL_57  1
#define GEOHEX3_MACRO_BOOL_58  1
#define GEOHEX3_MACRO_BOOL_59  1
#define GEOHEX3_MACRO_BOOL_60  1
#define GEOHEX3_MACRO_BOOL_61  1
#define GEOHEX3_MACRO_BOOL_62  1
#define GEOHEX3_MACRO_BOOL_63  1
#define GEOHEX3_MACRO_BOOL_64  1
#define GEOHEX3_MACRO_BOOL_65  1
#define GEOHEX3_MACRO_BOOL_66  1
#define GEOHEX3_MACRO_BOOL_67  1
#define GEOHEX3_MACRO_BOOL_68  1
#define GEOHEX3_MACRO_BOOL_69  1
#define GEOHEX3_MACRO_BOOL_70  1
#define GEOHEX3_MACRO_BOOL_71  1
#define GEOHEX3_MACRO_BOOL_72  1
#define GEOHEX3_MACRO_BOOL_73  1
#define GEOHEX3_MACRO_BOOL_74  1
#define GEOHEX3_MACRO_BOOL_75  1
#define GEOHEX3_MACRO_BOOL_76  1
#define GEOHEX3_MACRO_BOOL_77  1
#define GEOHEX3_MACRO_BOOL_78  1
#define GEOHEX3_MACRO_BOOL_79  1
#define GEOHEX3_MACRO_BOOL_80  1
#define GEOHEX3_MACRO_BOOL_81  1
#define GEOHEX3_MACRO_BOOL_82  1
#define GEOHEX3_MACRO_BOOL_83  1
#define GEOHEX3_MACRO_BOOL_84  1
#define GEOHEX3_MACRO_BOOL_85  1
#define GEOHEX3_MACRO_BOOL_86  1
#define GEOHEX3_MACRO_BOOL_87  1
#define GEOHEX3_MACRO_BOOL_88  1
#define GEOHEX3_MACRO_BOOL_89  1
#define GEOHEX3_MACRO_BOOL_90  1
#define GEOHEX3_MACRO_BOOL_91  1
#define GEOHEX3_MACRO_BOOL_92  1
#define GEOHEX3_MACRO_BOOL_93  1
#define GEOHEX3_MACRO_BOOL_94  1
#define GEOHEX3_MACRO_BOOL_95  1
#define GEOHEX3_MACRO_BOOL_96  1
#define GEOHEX3_MACRO_BOOL_97  1
#define GEOHEX3_MACRO_BOOL_98  1
#define GEOHEX3_MACRO_BOOL_99  1
#define GEOHEX3_MACRO_BOOL_100 1
#define GEOHEX3_MACRO_BOOL_101 1
#define GEOHEX3_MACRO_BOOL_102 1
#define GEOHEX3_MACRO_BOOL_103 1
#define GEOHEX3_MACRO_BOOL_104 1
#define GEOHEX3_MACRO_BOOL_105 1
#define GEOHEX3_MACRO_BOOL_106 1
#define GEOHEX3_MACRO_BOOL_107 1
#define GEOHEX3_MACRO_BOOL_108 1
#define GEOHEX3_MACRO_BOOL_109 1
#define GEOHEX3_MACRO_BOOL_110 1
#define GEOHEX3_MACRO_BOOL_111 1
#define GEOHEX3_MACRO_BOOL_112 1
#define GEOHEX3_MACRO_BOOL_113 1
#define GEOHEX3_MACRO_BOOL_114 1
#define GEOHEX3_MACRO_BOOL_115 1
#define GEOHEX3_MACRO_BOOL_116 1
#define GEOHEX3_MACRO_BOOL_117 1
#define GEOHEX3_MACRO_BOOL_118 1
#define GEOHEX3_MACRO_BOOL_119 1
#define GEOHEX3_MACRO_BOOL_120 1
#define GEOHEX3_MACRO_BOOL_121 1
#define GEOHEX3_MACRO_BOOL_122 1
#define GEOHEX3_MACRO_BOOL_123 1
#define GEOHEX3_MACRO_BOOL_124 1
#define GEOHEX3_MACRO_BOOL_125 1
#define GEOHEX3_MACRO_BOOL_126 1
#define GEOHEX3_MACRO_BOOL_127 1
#define GEOHEX3_MACRO_BOOL_128 1
#define GEOHEX3_MACRO_BOOL_129 1
#define GEOHEX3_MACRO_BOOL_130 1
#define GEOHEX3_MACRO_BOOL_131 1
#define GEOHEX3_MACRO_BOOL_132 1
#define GEOHEX3_MACRO_BOOL_133 1
#define GEOHEX3_MACRO_BOOL_134 1
#define GEOHEX3_MACRO_BOOL_135 1
#define GEOHEX3_MACRO_BOOL_136 1
#define GEOHEX3_MACRO_BOOL_137 1
#define GEOHEX3_MACRO_BOOL_138 1
#define GEOHEX3_MACRO_BOOL_139 1
#define GEOHEX3_MACRO_BOOL_140 1
#define GEOHEX3_MACRO_BOOL_141 1
#define GEOHEX3_MACRO_BOOL_142 1
#define GEOHEX3_MACRO_BOOL_143 1
#define GEOHEX3_MACRO_BOOL_144 1
#define GEOHEX3_MACRO_BOOL_145 1
#define GEOHEX3_MACRO_BOOL_146 1
#define GEOHEX3_MACRO_BOOL_147 1
#define GEOHEX3_MACRO_BOOL_148 1
#define GEOHEX3_MACRO_BOOL_149 1
#define GEOHEX3_MACRO_BOOL_150 1
#define GEOHEX3_MACRO_BOOL_151 1
#define GEOHEX3_MACRO_BOOL_152 1
#define GEOHEX3_MACRO_BOOL_153 1
#define GEOHEX3_MACRO_BOOL_154 1
#define GEOHEX3_MACRO_BOOL_155 1
#define GEOHEX3_MACRO_BOOL_156 1
#define GEOHEX3_MACRO_BOOL_157 1
#define GEOHEX3_MACRO_BOOL_158 1
#define GEOHEX3_MACRO_BOOL_159 1
#define GEOHEX3_MACRO_BOOL_160 1
#define GEOHEX3_MACRO_BOOL_161 1
#define GEOHEX3_MACRO_BOOL_162 1
#define GEOHEX3_MACRO_BOOL_163 1
#define GEOHEX3_MACRO_BOOL_164 1
#define GEOHEX3_MACRO_BOOL_165 1
#define GEOHEX3_MACRO_BOOL_166 1
#define GEOHEX3_MACRO_BOOL_167 1
#define GEOHEX3_MACRO_BOOL_168 1
#define GEOHEX3_MACRO_BOOL_169 1
#define GEOHEX3_MACRO_BOOL_170 1
#define GEOHEX3_MACRO_BOOL_171 1
#define GEOHEX3_MACRO_BOOL_172 1
#define GEOHEX3_MACRO_BOOL_173 1
#define GEOHEX3_MACRO_BOOL_174 1
#define GEOHEX3_MACRO_BOOL_175 1
#define GEOHEX3_MACRO_BOOL_176 1
#define GEOHEX3_MACRO_BOOL_177 1
#define GEOHEX3_MACRO_BOOL_178 1
#define GEOHEX3_MACRO_BOOL_179 1
#define GEOHEX3_MACRO_BOOL_180 1
#define GEOHEX3_MACRO_BOOL_181 1
#define GEOHEX3_MACRO_BOOL_182 1
#define GEOHEX3_MACRO_BOOL_183 1
#define GEOHEX3_MACRO_BOOL_184 1
#define GEOHEX3_MACRO_BOOL_185 1
#define GEOHEX3_MACRO_BOOL_186 1
#define GEOHEX3_MACRO_BOOL_187 1
#define GEOHEX3_MACRO_BOOL_188 1
#define GEOHEX3_MACRO_BOOL_189 1
#define GEOHEX3_MACRO_BOOL_190 1
#define GEOHEX3_MACRO_BOOL_191 1
#define GEOHEX3_MACRO_BOOL_192 1
#define GEOHEX3_MACRO_BOOL_193 1
#define GEOHEX3_MACRO_BOOL_194 1
#define GEOHEX3_MACRO_BOOL_195 1
#define GEOHEX3_MACRO_BOOL_196 1
#define GEOHEX3_MACRO_BOOL_197 1
#define GEOHEX3_MACRO_BOOL_198 1
#define GEOHEX3_MACRO_BOOL_199 1
#define GEOHEX3_MACRO_BOOL_200 1
#define GEOHEX3_MACRO_BOOL_201 1
#define GEOHEX3_MACRO_BOOL_202 1
#define GEOHEX3_MACRO_BOOL_203 1
#define GEOHEX3_MACRO_BOOL_204 1
#define GEOHEX3_MACRO_BOOL_205 1
#define GEOHEX3_MACRO_BOOL_206 1
#define GEOHEX3_MACRO_BOOL_207 1
#define GEOHEX3_MACRO_BOOL_208 1
#define GEOHEX3_MACRO_BOOL_209 1
#define GEOHEX3_MACRO_BOOL_210 1
#define GEOHEX3_MACRO_BOOL_211 1
#define GEOHEX3_MACRO_BOOL_212 1
#define GEOHEX3_MACRO_BOOL_213 1
#define GEOHEX3_MACRO_BOOL_214 1
#define GEOHEX3_MACRO_BOOL_215 1
#define GEOHEX3_MACRO_BOOL_216 1
#define GEOHEX3_MACRO_BOOL_217 1
#define GEOHEX3_MACRO_BOOL_218 1
#define GEOHEX3_MACRO_BOOL_219 1
#define GEOHEX3_MACRO_BOOL_220 1
#define GEOHEX3_MACRO_BOOL_221 1
#define GEOHEX3_MACRO_BOOL_222 1
#define GEOHEX3_MACRO_BOOL_223 1
#define GEOHEX3_MACRO_BOOL_224 1
#define GEOHEX3_MACRO_BOOL_225 1
#define GEOHEX3_MACRO_BOOL_226 1
#define GEOHEX3_MACRO_BOOL_227 1
#define GEOHEX3_MACRO_BOOL_228 1
#define GEOHEX3_MACRO_BOOL_229 1
#define GEOHEX3_MACRO_BOOL_230 1
#define GEOHEX3_MACRO_BOOL_231 1
#define GEOHEX3_MACRO_BOOL_232 1
#define GEOHEX3_MACRO_BOOL_233 1
#define GEOHEX3_MACRO_BOOL_234 1
#define GEOHEX3_MACRO_BOOL_235 1
#define GEOHEX3_MACRO_BOOL_236 1
#define GEOHEX3_MACRO_BOOL_237 1
#define GEOHEX3_MACRO_BOOL_238 1
#define GEOHEX3_MACRO_BOOL_239 1
#define GEOHEX3_MACRO_BOOL_240 1
#define GEOHEX3_MACRO_BOOL_241 1
#define GEOHEX3_MACRO_BOOL_242 1
#define GEOHEX3_MACRO_BOOL_243 1
#define GEOHEX3_MACRO_BOOL_244 1
#define GEOHEX3_MACRO_BOOL_245 1
#define GEOHEX3_MACRO_BOOL_246 1
#define GEOHEX3_MACRO_BOOL_247 1
#define GEOHEX3_MACRO_BOOL_248 1
#define GEOHEX3_MACRO_BOOL_249 1
#define GEOHEX3_MACRO_BOOL_250 1
#define GEOHEX3_MACRO_BOOL_251 1
#define GEOHEX3_MACRO_BOOL_252 1
#define GEOHEX3_MACRO_BOOL_253 1
#define GEOHEX3_MACRO_BOOL_254 1
#define GEOHEX3_MACRO_BOOL_255 1

#define GEOHEX3_MACRO_IF(condition, true, false) GEOHEX3_MACRO_IF_l(condition, true, false)
#define GEOHEX3_MACRO_IF_l(condition, true, false) GEOHEX3_MACRO_CAT(GEOHEX3_MACRO_IF_, GEOHEX3_MACRO_BOOL(condition))(true, false)
#define GEOHEX3_MACRO_IF_1(true, false) true
#define GEOHEX3_MACRO_IF_0(true, false) false

/* gen: perl -E 'say "#define GEOHEX3_MACRO_JOIN_$_(entity, separator) entity separator GEOHEX3_MACRO_JOIN_${\$_-1}(entity, separator)" for 2..255' */
#define GEOHEX3_MACRO_JOIN(entity, separator, count) GEOHEX3_MACRO_CAT(GEOHEX3_MACRO_JOIN_, count)(entity, separator)
#define GEOHEX3_MACRO_JOIN_0(entity, separator)
#define GEOHEX3_MACRO_JOIN_1(entity, separator)   entity
#define GEOHEX3_MACRO_JOIN_2(entity, separator)   entity separator GEOHEX3_MACRO_JOIN_1(entity, separator)
#define GEOHEX3_MACRO_JOIN_3(entity, separator)   entity separator GEOHEX3_MACRO_JOIN_2(entity, separator)
#define GEOHEX3_MACRO_JOIN_4(entity, separator)   entity separator GEOHEX3_MACRO_JOIN_3(entity, separator)
#define GEOHEX3_MACRO_JOIN_5(entity, separator)   entity separator GEOHEX3_MACRO_JOIN_4(entity, separator)
#define GEOHEX3_MACRO_JOIN_6(entity, separator)   entity separator GEOHEX3_MACRO_JOIN_5(entity, separator)
#define GEOHEX3_MACRO_JOIN_7(entity, separator)   entity separator GEOHEX3_MACRO_JOIN_6(entity, separator)
#define GEOHEX3_MACRO_JOIN_8(entity, separator)   entity separator GEOHEX3_MACRO_JOIN_7(entity, separator)
#define GEOHEX3_MACRO_JOIN_9(entity, separator)   entity separator GEOHEX3_MACRO_JOIN_8(entity, separator)
#define GEOHEX3_MACRO_JOIN_10(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_9(entity, separator)
#define GEOHEX3_MACRO_JOIN_11(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_10(entity, separator)
#define GEOHEX3_MACRO_JOIN_12(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_11(entity, separator)
#define GEOHEX3_MACRO_JOIN_13(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_12(entity, separator)
#define GEOHEX3_MACRO_JOIN_14(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_13(entity, separator)
#define GEOHEX3_MACRO_JOIN_15(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_14(entity, separator)
#define GEOHEX3_MACRO_JOIN_16(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_15(entity, separator)
#define GEOHEX3_MACRO_JOIN_17(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_16(entity, separator)
#define GEOHEX3_MACRO_JOIN_18(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_17(entity, separator)
#define GEOHEX3_MACRO_JOIN_19(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_18(entity, separator)
#define GEOHEX3_MACRO_JOIN_20(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_19(entity, separator)
#define GEOHEX3_MACRO_JOIN_21(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_20(entity, separator)
#define GEOHEX3_MACRO_JOIN_22(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_21(entity, separator)
#define GEOHEX3_MACRO_JOIN_23(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_22(entity, separator)
#define GEOHEX3_MACRO_JOIN_24(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_23(entity, separator)
#define GEOHEX3_MACRO_JOIN_25(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_24(entity, separator)
#define GEOHEX3_MACRO_JOIN_26(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_25(entity, separator)
#define GEOHEX3_MACRO_JOIN_27(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_26(entity, separator)
#define GEOHEX3_MACRO_JOIN_28(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_27(entity, separator)
#define GEOHEX3_MACRO_JOIN_29(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_28(entity, separator)
#define GEOHEX3_MACRO_JOIN_30(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_29(entity, separator)
#define GEOHEX3_MACRO_JOIN_31(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_30(entity, separator)
#define GEOHEX3_MACRO_JOIN_32(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_31(entity, separator)
#define GEOHEX3_MACRO_JOIN_33(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_32(entity, separator)
#define GEOHEX3_MACRO_JOIN_34(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_33(entity, separator)
#define GEOHEX3_MACRO_JOIN_35(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_34(entity, separator)
#define GEOHEX3_MACRO_JOIN_36(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_35(entity, separator)
#define GEOHEX3_MACRO_JOIN_37(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_36(entity, separator)
#define GEOHEX3_MACRO_JOIN_38(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_37(entity, separator)
#define GEOHEX3_MACRO_JOIN_39(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_38(entity, separator)
#define GEOHEX3_MACRO_JOIN_40(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_39(entity, separator)
#define GEOHEX3_MACRO_JOIN_41(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_40(entity, separator)
#define GEOHEX3_MACRO_JOIN_42(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_41(entity, separator)
#define GEOHEX3_MACRO_JOIN_43(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_42(entity, separator)
#define GEOHEX3_MACRO_JOIN_44(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_43(entity, separator)
#define GEOHEX3_MACRO_JOIN_45(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_44(entity, separator)
#define GEOHEX3_MACRO_JOIN_46(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_45(entity, separator)
#define GEOHEX3_MACRO_JOIN_47(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_46(entity, separator)
#define GEOHEX3_MACRO_JOIN_48(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_47(entity, separator)
#define GEOHEX3_MACRO_JOIN_49(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_48(entity, separator)
#define GEOHEX3_MACRO_JOIN_50(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_49(entity, separator)
#define GEOHEX3_MACRO_JOIN_51(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_50(entity, separator)
#define GEOHEX3_MACRO_JOIN_52(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_51(entity, separator)
#define GEOHEX3_MACRO_JOIN_53(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_52(entity, separator)
#define GEOHEX3_MACRO_JOIN_54(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_53(entity, separator)
#define GEOHEX3_MACRO_JOIN_55(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_54(entity, separator)
#define GEOHEX3_MACRO_JOIN_56(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_55(entity, separator)
#define GEOHEX3_MACRO_JOIN_57(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_56(entity, separator)
#define GEOHEX3_MACRO_JOIN_58(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_57(entity, separator)
#define GEOHEX3_MACRO_JOIN_59(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_58(entity, separator)
#define GEOHEX3_MACRO_JOIN_60(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_59(entity, separator)
#define GEOHEX3_MACRO_JOIN_61(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_60(entity, separator)
#define GEOHEX3_MACRO_JOIN_62(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_61(entity, separator)
#define GEOHEX3_MACRO_JOIN_63(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_62(entity, separator)
#define GEOHEX3_MACRO_JOIN_64(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_63(entity, separator)
#define GEOHEX3_MACRO_JOIN_65(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_64(entity, separator)
#define GEOHEX3_MACRO_JOIN_66(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_65(entity, separator)
#define GEOHEX3_MACRO_JOIN_67(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_66(entity, separator)
#define GEOHEX3_MACRO_JOIN_68(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_67(entity, separator)
#define GEOHEX3_MACRO_JOIN_69(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_68(entity, separator)
#define GEOHEX3_MACRO_JOIN_70(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_69(entity, separator)
#define GEOHEX3_MACRO_JOIN_71(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_70(entity, separator)
#define GEOHEX3_MACRO_JOIN_72(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_71(entity, separator)
#define GEOHEX3_MACRO_JOIN_73(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_72(entity, separator)
#define GEOHEX3_MACRO_JOIN_74(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_73(entity, separator)
#define GEOHEX3_MACRO_JOIN_75(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_74(entity, separator)
#define GEOHEX3_MACRO_JOIN_76(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_75(entity, separator)
#define GEOHEX3_MACRO_JOIN_77(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_76(entity, separator)
#define GEOHEX3_MACRO_JOIN_78(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_77(entity, separator)
#define GEOHEX3_MACRO_JOIN_79(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_78(entity, separator)
#define GEOHEX3_MACRO_JOIN_80(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_79(entity, separator)
#define GEOHEX3_MACRO_JOIN_81(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_80(entity, separator)
#define GEOHEX3_MACRO_JOIN_82(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_81(entity, separator)
#define GEOHEX3_MACRO_JOIN_83(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_82(entity, separator)
#define GEOHEX3_MACRO_JOIN_84(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_83(entity, separator)
#define GEOHEX3_MACRO_JOIN_85(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_84(entity, separator)
#define GEOHEX3_MACRO_JOIN_86(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_85(entity, separator)
#define GEOHEX3_MACRO_JOIN_87(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_86(entity, separator)
#define GEOHEX3_MACRO_JOIN_88(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_87(entity, separator)
#define GEOHEX3_MACRO_JOIN_89(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_88(entity, separator)
#define GEOHEX3_MACRO_JOIN_90(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_89(entity, separator)
#define GEOHEX3_MACRO_JOIN_91(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_90(entity, separator)
#define GEOHEX3_MACRO_JOIN_92(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_91(entity, separator)
#define GEOHEX3_MACRO_JOIN_93(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_92(entity, separator)
#define GEOHEX3_MACRO_JOIN_94(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_93(entity, separator)
#define GEOHEX3_MACRO_JOIN_95(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_94(entity, separator)
#define GEOHEX3_MACRO_JOIN_96(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_95(entity, separator)
#define GEOHEX3_MACRO_JOIN_97(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_96(entity, separator)
#define GEOHEX3_MACRO_JOIN_98(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_97(entity, separator)
#define GEOHEX3_MACRO_JOIN_99(entity, separator)  entity separator GEOHEX3_MACRO_JOIN_98(entity, separator)
#define GEOHEX3_MACRO_JOIN_100(entity, separator) entity separator GEOHEX3_MACRO_JOIN_99(entity, separator)
#define GEOHEX3_MACRO_JOIN_101(entity, separator) entity separator GEOHEX3_MACRO_JOIN_100(entity, separator)
#define GEOHEX3_MACRO_JOIN_102(entity, separator) entity separator GEOHEX3_MACRO_JOIN_101(entity, separator)
#define GEOHEX3_MACRO_JOIN_103(entity, separator) entity separator GEOHEX3_MACRO_JOIN_102(entity, separator)
#define GEOHEX3_MACRO_JOIN_104(entity, separator) entity separator GEOHEX3_MACRO_JOIN_103(entity, separator)
#define GEOHEX3_MACRO_JOIN_105(entity, separator) entity separator GEOHEX3_MACRO_JOIN_104(entity, separator)
#define GEOHEX3_MACRO_JOIN_106(entity, separator) entity separator GEOHEX3_MACRO_JOIN_105(entity, separator)
#define GEOHEX3_MACRO_JOIN_107(entity, separator) entity separator GEOHEX3_MACRO_JOIN_106(entity, separator)
#define GEOHEX3_MACRO_JOIN_108(entity, separator) entity separator GEOHEX3_MACRO_JOIN_107(entity, separator)
#define GEOHEX3_MACRO_JOIN_109(entity, separator) entity separator GEOHEX3_MACRO_JOIN_108(entity, separator)
#define GEOHEX3_MACRO_JOIN_110(entity, separator) entity separator GEOHEX3_MACRO_JOIN_109(entity, separator)
#define GEOHEX3_MACRO_JOIN_111(entity, separator) entity separator GEOHEX3_MACRO_JOIN_110(entity, separator)
#define GEOHEX3_MACRO_JOIN_112(entity, separator) entity separator GEOHEX3_MACRO_JOIN_111(entity, separator)
#define GEOHEX3_MACRO_JOIN_113(entity, separator) entity separator GEOHEX3_MACRO_JOIN_112(entity, separator)
#define GEOHEX3_MACRO_JOIN_114(entity, separator) entity separator GEOHEX3_MACRO_JOIN_113(entity, separator)
#define GEOHEX3_MACRO_JOIN_115(entity, separator) entity separator GEOHEX3_MACRO_JOIN_114(entity, separator)
#define GEOHEX3_MACRO_JOIN_116(entity, separator) entity separator GEOHEX3_MACRO_JOIN_115(entity, separator)
#define GEOHEX3_MACRO_JOIN_117(entity, separator) entity separator GEOHEX3_MACRO_JOIN_116(entity, separator)
#define GEOHEX3_MACRO_JOIN_118(entity, separator) entity separator GEOHEX3_MACRO_JOIN_117(entity, separator)
#define GEOHEX3_MACRO_JOIN_119(entity, separator) entity separator GEOHEX3_MACRO_JOIN_118(entity, separator)
#define GEOHEX3_MACRO_JOIN_120(entity, separator) entity separator GEOHEX3_MACRO_JOIN_119(entity, separator)
#define GEOHEX3_MACRO_JOIN_121(entity, separator) entity separator GEOHEX3_MACRO_JOIN_120(entity, separator)
#define GEOHEX3_MACRO_JOIN_122(entity, separator) entity separator GEOHEX3_MACRO_JOIN_121(entity, separator)
#define GEOHEX3_MACRO_JOIN_123(entity, separator) entity separator GEOHEX3_MACRO_JOIN_122(entity, separator)
#define GEOHEX3_MACRO_JOIN_124(entity, separator) entity separator GEOHEX3_MACRO_JOIN_123(entity, separator)
#define GEOHEX3_MACRO_JOIN_125(entity, separator) entity separator GEOHEX3_MACRO_JOIN_124(entity, separator)
#define GEOHEX3_MACRO_JOIN_126(entity, separator) entity separator GEOHEX3_MACRO_JOIN_125(entity, separator)
#define GEOHEX3_MACRO_JOIN_127(entity, separator) entity separator GEOHEX3_MACRO_JOIN_126(entity, separator)
#define GEOHEX3_MACRO_JOIN_128(entity, separator) entity separator GEOHEX3_MACRO_JOIN_127(entity, separator)
#define GEOHEX3_MACRO_JOIN_129(entity, separator) entity separator GEOHEX3_MACRO_JOIN_128(entity, separator)
#define GEOHEX3_MACRO_JOIN_130(entity, separator) entity separator GEOHEX3_MACRO_JOIN_129(entity, separator)
#define GEOHEX3_MACRO_JOIN_131(entity, separator) entity separator GEOHEX3_MACRO_JOIN_130(entity, separator)
#define GEOHEX3_MACRO_JOIN_132(entity, separator) entity separator GEOHEX3_MACRO_JOIN_131(entity, separator)
#define GEOHEX3_MACRO_JOIN_133(entity, separator) entity separator GEOHEX3_MACRO_JOIN_132(entity, separator)
#define GEOHEX3_MACRO_JOIN_134(entity, separator) entity separator GEOHEX3_MACRO_JOIN_133(entity, separator)
#define GEOHEX3_MACRO_JOIN_135(entity, separator) entity separator GEOHEX3_MACRO_JOIN_134(entity, separator)
#define GEOHEX3_MACRO_JOIN_136(entity, separator) entity separator GEOHEX3_MACRO_JOIN_135(entity, separator)
#define GEOHEX3_MACRO_JOIN_137(entity, separator) entity separator GEOHEX3_MACRO_JOIN_136(entity, separator)
#define GEOHEX3_MACRO_JOIN_138(entity, separator) entity separator GEOHEX3_MACRO_JOIN_137(entity, separator)
#define GEOHEX3_MACRO_JOIN_139(entity, separator) entity separator GEOHEX3_MACRO_JOIN_138(entity, separator)
#define GEOHEX3_MACRO_JOIN_140(entity, separator) entity separator GEOHEX3_MACRO_JOIN_139(entity, separator)
#define GEOHEX3_MACRO_JOIN_141(entity, separator) entity separator GEOHEX3_MACRO_JOIN_140(entity, separator)
#define GEOHEX3_MACRO_JOIN_142(entity, separator) entity separator GEOHEX3_MACRO_JOIN_141(entity, separator)
#define GEOHEX3_MACRO_JOIN_143(entity, separator) entity separator GEOHEX3_MACRO_JOIN_142(entity, separator)
#define GEOHEX3_MACRO_JOIN_144(entity, separator) entity separator GEOHEX3_MACRO_JOIN_143(entity, separator)
#define GEOHEX3_MACRO_JOIN_145(entity, separator) entity separator GEOHEX3_MACRO_JOIN_144(entity, separator)
#define GEOHEX3_MACRO_JOIN_146(entity, separator) entity separator GEOHEX3_MACRO_JOIN_145(entity, separator)
#define GEOHEX3_MACRO_JOIN_147(entity, separator) entity separator GEOHEX3_MACRO_JOIN_146(entity, separator)
#define GEOHEX3_MACRO_JOIN_148(entity, separator) entity separator GEOHEX3_MACRO_JOIN_147(entity, separator)
#define GEOHEX3_MACRO_JOIN_149(entity, separator) entity separator GEOHEX3_MACRO_JOIN_148(entity, separator)
#define GEOHEX3_MACRO_JOIN_150(entity, separator) entity separator GEOHEX3_MACRO_JOIN_149(entity, separator)
#define GEOHEX3_MACRO_JOIN_151(entity, separator) entity separator GEOHEX3_MACRO_JOIN_150(entity, separator)
#define GEOHEX3_MACRO_JOIN_152(entity, separator) entity separator GEOHEX3_MACRO_JOIN_151(entity, separator)
#define GEOHEX3_MACRO_JOIN_153(entity, separator) entity separator GEOHEX3_MACRO_JOIN_152(entity, separator)
#define GEOHEX3_MACRO_JOIN_154(entity, separator) entity separator GEOHEX3_MACRO_JOIN_153(entity, separator)
#define GEOHEX3_MACRO_JOIN_155(entity, separator) entity separator GEOHEX3_MACRO_JOIN_154(entity, separator)
#define GEOHEX3_MACRO_JOIN_156(entity, separator) entity separator GEOHEX3_MACRO_JOIN_155(entity, separator)
#define GEOHEX3_MACRO_JOIN_157(entity, separator) entity separator GEOHEX3_MACRO_JOIN_156(entity, separator)
#define GEOHEX3_MACRO_JOIN_158(entity, separator) entity separator GEOHEX3_MACRO_JOIN_157(entity, separator)
#define GEOHEX3_MACRO_JOIN_159(entity, separator) entity separator GEOHEX3_MACRO_JOIN_158(entity, separator)
#define GEOHEX3_MACRO_JOIN_160(entity, separator) entity separator GEOHEX3_MACRO_JOIN_159(entity, separator)
#define GEOHEX3_MACRO_JOIN_161(entity, separator) entity separator GEOHEX3_MACRO_JOIN_160(entity, separator)
#define GEOHEX3_MACRO_JOIN_162(entity, separator) entity separator GEOHEX3_MACRO_JOIN_161(entity, separator)
#define GEOHEX3_MACRO_JOIN_163(entity, separator) entity separator GEOHEX3_MACRO_JOIN_162(entity, separator)
#define GEOHEX3_MACRO_JOIN_164(entity, separator) entity separator GEOHEX3_MACRO_JOIN_163(entity, separator)
#define GEOHEX3_MACRO_JOIN_165(entity, separator) entity separator GEOHEX3_MACRO_JOIN_164(entity, separator)
#define GEOHEX3_MACRO_JOIN_166(entity, separator) entity separator GEOHEX3_MACRO_JOIN_165(entity, separator)
#define GEOHEX3_MACRO_JOIN_167(entity, separator) entity separator GEOHEX3_MACRO_JOIN_166(entity, separator)
#define GEOHEX3_MACRO_JOIN_168(entity, separator) entity separator GEOHEX3_MACRO_JOIN_167(entity, separator)
#define GEOHEX3_MACRO_JOIN_169(entity, separator) entity separator GEOHEX3_MACRO_JOIN_168(entity, separator)
#define GEOHEX3_MACRO_JOIN_170(entity, separator) entity separator GEOHEX3_MACRO_JOIN_169(entity, separator)
#define GEOHEX3_MACRO_JOIN_171(entity, separator) entity separator GEOHEX3_MACRO_JOIN_170(entity, separator)
#define GEOHEX3_MACRO_JOIN_172(entity, separator) entity separator GEOHEX3_MACRO_JOIN_171(entity, separator)
#define GEOHEX3_MACRO_JOIN_173(entity, separator) entity separator GEOHEX3_MACRO_JOIN_172(entity, separator)
#define GEOHEX3_MACRO_JOIN_174(entity, separator) entity separator GEOHEX3_MACRO_JOIN_173(entity, separator)
#define GEOHEX3_MACRO_JOIN_175(entity, separator) entity separator GEOHEX3_MACRO_JOIN_174(entity, separator)
#define GEOHEX3_MACRO_JOIN_176(entity, separator) entity separator GEOHEX3_MACRO_JOIN_175(entity, separator)
#define GEOHEX3_MACRO_JOIN_177(entity, separator) entity separator GEOHEX3_MACRO_JOIN_176(entity, separator)
#define GEOHEX3_MACRO_JOIN_178(entity, separator) entity separator GEOHEX3_MACRO_JOIN_177(entity, separator)
#define GEOHEX3_MACRO_JOIN_179(entity, separator) entity separator GEOHEX3_MACRO_JOIN_178(entity, separator)
#define GEOHEX3_MACRO_JOIN_180(entity, separator) entity separator GEOHEX3_MACRO_JOIN_179(entity, separator)
#define GEOHEX3_MACRO_JOIN_181(entity, separator) entity separator GEOHEX3_MACRO_JOIN_180(entity, separator)
#define GEOHEX3_MACRO_JOIN_182(entity, separator) entity separator GEOHEX3_MACRO_JOIN_181(entity, separator)
#define GEOHEX3_MACRO_JOIN_183(entity, separator) entity separator GEOHEX3_MACRO_JOIN_182(entity, separator)
#define GEOHEX3_MACRO_JOIN_184(entity, separator) entity separator GEOHEX3_MACRO_JOIN_183(entity, separator)
#define GEOHEX3_MACRO_JOIN_185(entity, separator) entity separator GEOHEX3_MACRO_JOIN_184(entity, separator)
#define GEOHEX3_MACRO_JOIN_186(entity, separator) entity separator GEOHEX3_MACRO_JOIN_185(entity, separator)
#define GEOHEX3_MACRO_JOIN_187(entity, separator) entity separator GEOHEX3_MACRO_JOIN_186(entity, separator)
#define GEOHEX3_MACRO_JOIN_188(entity, separator) entity separator GEOHEX3_MACRO_JOIN_187(entity, separator)
#define GEOHEX3_MACRO_JOIN_189(entity, separator) entity separator GEOHEX3_MACRO_JOIN_188(entity, separator)
#define GEOHEX3_MACRO_JOIN_190(entity, separator) entity separator GEOHEX3_MACRO_JOIN_189(entity, separator)
#define GEOHEX3_MACRO_JOIN_191(entity, separator) entity separator GEOHEX3_MACRO_JOIN_190(entity, separator)
#define GEOHEX3_MACRO_JOIN_192(entity, separator) entity separator GEOHEX3_MACRO_JOIN_191(entity, separator)
#define GEOHEX3_MACRO_JOIN_193(entity, separator) entity separator GEOHEX3_MACRO_JOIN_192(entity, separator)
#define GEOHEX3_MACRO_JOIN_194(entity, separator) entity separator GEOHEX3_MACRO_JOIN_193(entity, separator)
#define GEOHEX3_MACRO_JOIN_195(entity, separator) entity separator GEOHEX3_MACRO_JOIN_194(entity, separator)
#define GEOHEX3_MACRO_JOIN_196(entity, separator) entity separator GEOHEX3_MACRO_JOIN_195(entity, separator)
#define GEOHEX3_MACRO_JOIN_197(entity, separator) entity separator GEOHEX3_MACRO_JOIN_196(entity, separator)
#define GEOHEX3_MACRO_JOIN_198(entity, separator) entity separator GEOHEX3_MACRO_JOIN_197(entity, separator)
#define GEOHEX3_MACRO_JOIN_199(entity, separator) entity separator GEOHEX3_MACRO_JOIN_198(entity, separator)
#define GEOHEX3_MACRO_JOIN_200(entity, separator) entity separator GEOHEX3_MACRO_JOIN_199(entity, separator)
#define GEOHEX3_MACRO_JOIN_201(entity, separator) entity separator GEOHEX3_MACRO_JOIN_200(entity, separator)
#define GEOHEX3_MACRO_JOIN_202(entity, separator) entity separator GEOHEX3_MACRO_JOIN_201(entity, separator)
#define GEOHEX3_MACRO_JOIN_203(entity, separator) entity separator GEOHEX3_MACRO_JOIN_202(entity, separator)
#define GEOHEX3_MACRO_JOIN_204(entity, separator) entity separator GEOHEX3_MACRO_JOIN_203(entity, separator)
#define GEOHEX3_MACRO_JOIN_205(entity, separator) entity separator GEOHEX3_MACRO_JOIN_204(entity, separator)
#define GEOHEX3_MACRO_JOIN_206(entity, separator) entity separator GEOHEX3_MACRO_JOIN_205(entity, separator)
#define GEOHEX3_MACRO_JOIN_207(entity, separator) entity separator GEOHEX3_MACRO_JOIN_206(entity, separator)
#define GEOHEX3_MACRO_JOIN_208(entity, separator) entity separator GEOHEX3_MACRO_JOIN_207(entity, separator)
#define GEOHEX3_MACRO_JOIN_209(entity, separator) entity separator GEOHEX3_MACRO_JOIN_208(entity, separator)
#define GEOHEX3_MACRO_JOIN_210(entity, separator) entity separator GEOHEX3_MACRO_JOIN_209(entity, separator)
#define GEOHEX3_MACRO_JOIN_211(entity, separator) entity separator GEOHEX3_MACRO_JOIN_210(entity, separator)
#define GEOHEX3_MACRO_JOIN_212(entity, separator) entity separator GEOHEX3_MACRO_JOIN_211(entity, separator)
#define GEOHEX3_MACRO_JOIN_213(entity, separator) entity separator GEOHEX3_MACRO_JOIN_212(entity, separator)
#define GEOHEX3_MACRO_JOIN_214(entity, separator) entity separator GEOHEX3_MACRO_JOIN_213(entity, separator)
#define GEOHEX3_MACRO_JOIN_215(entity, separator) entity separator GEOHEX3_MACRO_JOIN_214(entity, separator)
#define GEOHEX3_MACRO_JOIN_216(entity, separator) entity separator GEOHEX3_MACRO_JOIN_215(entity, separator)
#define GEOHEX3_MACRO_JOIN_217(entity, separator) entity separator GEOHEX3_MACRO_JOIN_216(entity, separator)
#define GEOHEX3_MACRO_JOIN_218(entity, separator) entity separator GEOHEX3_MACRO_JOIN_217(entity, separator)
#define GEOHEX3_MACRO_JOIN_219(entity, separator) entity separator GEOHEX3_MACRO_JOIN_218(entity, separator)
#define GEOHEX3_MACRO_JOIN_220(entity, separator) entity separator GEOHEX3_MACRO_JOIN_219(entity, separator)
#define GEOHEX3_MACRO_JOIN_221(entity, separator) entity separator GEOHEX3_MACRO_JOIN_220(entity, separator)
#define GEOHEX3_MACRO_JOIN_222(entity, separator) entity separator GEOHEX3_MACRO_JOIN_221(entity, separator)
#define GEOHEX3_MACRO_JOIN_223(entity, separator) entity separator GEOHEX3_MACRO_JOIN_222(entity, separator)
#define GEOHEX3_MACRO_JOIN_224(entity, separator) entity separator GEOHEX3_MACRO_JOIN_223(entity, separator)
#define GEOHEX3_MACRO_JOIN_225(entity, separator) entity separator GEOHEX3_MACRO_JOIN_224(entity, separator)
#define GEOHEX3_MACRO_JOIN_226(entity, separator) entity separator GEOHEX3_MACRO_JOIN_225(entity, separator)
#define GEOHEX3_MACRO_JOIN_227(entity, separator) entity separator GEOHEX3_MACRO_JOIN_226(entity, separator)
#define GEOHEX3_MACRO_JOIN_228(entity, separator) entity separator GEOHEX3_MACRO_JOIN_227(entity, separator)
#define GEOHEX3_MACRO_JOIN_229(entity, separator) entity separator GEOHEX3_MACRO_JOIN_228(entity, separator)
#define GEOHEX3_MACRO_JOIN_230(entity, separator) entity separator GEOHEX3_MACRO_JOIN_229(entity, separator)
#define GEOHEX3_MACRO_JOIN_231(entity, separator) entity separator GEOHEX3_MACRO_JOIN_230(entity, separator)
#define GEOHEX3_MACRO_JOIN_232(entity, separator) entity separator GEOHEX3_MACRO_JOIN_231(entity, separator)
#define GEOHEX3_MACRO_JOIN_233(entity, separator) entity separator GEOHEX3_MACRO_JOIN_232(entity, separator)
#define GEOHEX3_MACRO_JOIN_234(entity, separator) entity separator GEOHEX3_MACRO_JOIN_233(entity, separator)
#define GEOHEX3_MACRO_JOIN_235(entity, separator) entity separator GEOHEX3_MACRO_JOIN_234(entity, separator)
#define GEOHEX3_MACRO_JOIN_236(entity, separator) entity separator GEOHEX3_MACRO_JOIN_235(entity, separator)
#define GEOHEX3_MACRO_JOIN_237(entity, separator) entity separator GEOHEX3_MACRO_JOIN_236(entity, separator)
#define GEOHEX3_MACRO_JOIN_238(entity, separator) entity separator GEOHEX3_MACRO_JOIN_237(entity, separator)
#define GEOHEX3_MACRO_JOIN_239(entity, separator) entity separator GEOHEX3_MACRO_JOIN_238(entity, separator)
#define GEOHEX3_MACRO_JOIN_240(entity, separator) entity separator GEOHEX3_MACRO_JOIN_239(entity, separator)
#define GEOHEX3_MACRO_JOIN_241(entity, separator) entity separator GEOHEX3_MACRO_JOIN_240(entity, separator)
#define GEOHEX3_MACRO_JOIN_242(entity, separator) entity separator GEOHEX3_MACRO_JOIN_241(entity, separator)
#define GEOHEX3_MACRO_JOIN_243(entity, separator) entity separator GEOHEX3_MACRO_JOIN_242(entity, separator)
#define GEOHEX3_MACRO_JOIN_244(entity, separator) entity separator GEOHEX3_MACRO_JOIN_243(entity, separator)
#define GEOHEX3_MACRO_JOIN_245(entity, separator) entity separator GEOHEX3_MACRO_JOIN_244(entity, separator)
#define GEOHEX3_MACRO_JOIN_246(entity, separator) entity separator GEOHEX3_MACRO_JOIN_245(entity, separator)
#define GEOHEX3_MACRO_JOIN_247(entity, separator) entity separator GEOHEX3_MACRO_JOIN_246(entity, separator)
#define GEOHEX3_MACRO_JOIN_248(entity, separator) entity separator GEOHEX3_MACRO_JOIN_247(entity, separator)
#define GEOHEX3_MACRO_JOIN_249(entity, separator) entity separator GEOHEX3_MACRO_JOIN_248(entity, separator)
#define GEOHEX3_MACRO_JOIN_250(entity, separator) entity separator GEOHEX3_MACRO_JOIN_249(entity, separator)
#define GEOHEX3_MACRO_JOIN_251(entity, separator) entity separator GEOHEX3_MACRO_JOIN_250(entity, separator)
#define GEOHEX3_MACRO_JOIN_252(entity, separator) entity separator GEOHEX3_MACRO_JOIN_251(entity, separator)
#define GEOHEX3_MACRO_JOIN_253(entity, separator) entity separator GEOHEX3_MACRO_JOIN_252(entity, separator)
#define GEOHEX3_MACRO_JOIN_254(entity, separator) entity separator GEOHEX3_MACRO_JOIN_253(entity, separator)
#define GEOHEX3_MACRO_JOIN_255(entity, separator) entity separator GEOHEX3_MACRO_JOIN_254(entity, separator)

// pow
#define GEOHEX3_MACRO_POW_0(a, b) (1)
#define GEOHEX3_MACRO_POW_X(a, b) (GEOHEX3_MACRO_JOIN(a, *, b))
#define GEOHEX3_MACRO_POW(a, b)   GEOHEX3_MACRO_CAT(GEOHEX3_MACRO_POW_, GEOHEX3_MACRO_IF(b, X, 0))((a), b)

#endif
