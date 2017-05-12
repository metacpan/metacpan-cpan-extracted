use strict;
use warnings;

use constant {
    KS_ARCH_ARM     => 1,
    KS_ARCH_ARM64   => 2,
    KS_ARCH_MIPS    => 3,
    KS_ARCH_X86     => 4,
    KS_ARCH_PPC     => 5,
    KS_ARCH_SPARC   => 6,
    KS_ARCH_SYSTEMZ => 7,
    KS_ARCH_HEXAGON => 8,
    KS_ARCH_MAX     => 9
};

use constant {
    KS_MODE_LITTLE_ENDIAN => 0,
    KS_MODE_BIG_ENDIAN    => 1 << 30,
    KS_MODE_ARM           => 1 << 0,
    KS_MODE_THUMB         => 1 << 4,
    KS_MODE_V8            => 1 << 6,
    KS_MODE_MICRO         => 1 << 4,
    KS_MODE_MIPS3         => 1 << 5,
    KS_MODE_MIPS32R6      => 1 << 6,
    KS_MODE_MIPS32        => 1 << 2,
    KS_MODE_MIPS64        => 1 << 3,
    KS_MODE_16            => 1 << 1,
    KS_MODE_32            => 1 << 2,
    KS_MODE_64            => 1 << 3,
    KS_MODE_PPC32         => 1 << 2,
    KS_MODE_PPC64         => 1 << 3,
    KS_MODE_QPX           => 1 << 4,
    KS_MODE_SPARC32       => 1 << 2,
    KS_MODE_SPARC64       => 1 << 3,
    KS_MODE_V9            => 1 << 4
};


use constant {
    KS_ERR_ASM                            => 128,
    KS_ERR_ASM_ARCH                       => 512,
};

use constant {
    KS_ERR_OK                             => 0,
    KS_ERR_NOMEM                          => 1,
    KS_ERR_ARCH                           => 2,
    KS_ERR_HANDLE                         => 3,
    KS_ERR_MODE                           => 4,
    KS_ERR_VERSION                        => 5,
    KS_ERR_OPT_INVALID                    => 6,
    KS_ERR_ASM_EXPR_TOKEN                 => KS_ERR_ASM,
    KS_ERR_ASM_DIRECTIVE_VALUE_RANGE      => KS_ERR_ASM+1,
    KS_ERR_ASM_DIRECTIVE_ID               => KS_ERR_ASM+2,
    KS_ERR_ASM_DIRECTIVE_TOKEN            => KS_ERR_ASM+3,
    KS_ERR_ASM_DIRECTIVE_STR              => KS_ERR_ASM+4,
    KS_ERR_ASM_DIRECTIVE_COMMA            => KS_ERR_ASM+5,
    KS_ERR_ASM_DIRECTIVE_RELOC_NAME       => KS_ERR_ASM+6,
    KS_ERR_ASM_DIRECTIVE_RELOC_TOKEN      => KS_ERR_ASM+7,
    KS_ERR_ASM_DIRECTIVE_FPOINT           => KS_ERR_ASM+8,
    KS_ERR_ASM_DIRECTIVE_UNKNOWN          => KS_ERR_ASM+9,
    KS_ERR_ASM_DIRECTIVE_EQU              => KS_ERR_ASM+10,
    KS_ERR_ASM_DIRECTIVE_INVALID          => KS_ERR_ASM+11,
    KS_ERR_ASM_VARIANT_INVALID            => KS_ERR_ASM+12,
    KS_ERR_ASM_EXPR_BRACKET               => KS_ERR_ASM+13,
    KS_ERR_ASM_SYMBOL_MODIFIER            => KS_ERR_ASM+14,
    KS_ERR_ASM_SYMBOL_REDEFINED           => KS_ERR_ASM+15,
    KS_ERR_ASM_SYMBOL_MISSING             => KS_ERR_ASM+16,
    KS_ERR_ASM_RPAREN                     => KS_ERR_ASM+17,
    KS_ERR_ASM_STAT_TOKEN                 => KS_ERR_ASM+18,
    KS_ERR_ASM_UNSUPPORTED                => KS_ERR_ASM+19,
    KS_ERR_ASM_MACRO_TOKEN                => KS_ERR_ASM+20,
    KS_ERR_ASM_MACRO_PAREN                => KS_ERR_ASM+21,
    KS_ERR_ASM_MACRO_EQU                  => KS_ERR_ASM+22,
    KS_ERR_ASM_MACRO_ARGS                 => KS_ERR_ASM+23,
    KS_ERR_ASM_MACRO_LEVELS_EXCEED        => KS_ERR_ASM+24,
    KS_ERR_ASM_MACRO_STR                  => KS_ERR_ASM+25,
    KS_ERR_ASM_MACRO_INVALID              => KS_ERR_ASM+26,
    KS_ERR_ASM_ESC_BACKSLASH              => KS_ERR_ASM+27,
    KS_ERR_ASM_ESC_OCTAL                  => KS_ERR_ASM+28,
    KS_ERR_ASM_ESC_SEQUENCE               => KS_ERR_ASM+29,
    KS_ERR_ASM_ESC_STR                    => KS_ERR_ASM+30,
    KS_ERR_ASM_TOKEN_INVALID              => KS_ERR_ASM+31,
    KS_ERR_ASM_INSN_UNSUPPORTED           => KS_ERR_ASM+32,
    KS_ERR_ASM_FIXUP_INVALID              => KS_ERR_ASM+33,
    KS_ERR_ASM_LABEL_INVALID              => KS_ERR_ASM+34,
    KS_ERR_ASM_FRAGMENT_INVALID           => KS_ERR_ASM+35,
    KS_ERR_ASM_INVALIDOPERAND             => KS_ERR_ASM_ARCH,
    KS_ERR_ASM_MISSINGFEATURE             => KS_ERR_ASM_ARCH+1,
    KS_ERR_ASM_MNEMONICFAIL               => KS_ERR_ASM_ARCH+2
};

use constant {
	KS_OPT_SYNTAX => 1
};

use constant {
	KS_OPT_SYNTAX_INTEL => 1 << 0,
	KS_OPT_SYNTAX_ATT   => 1 << 1,
	KS_OPT_SYNTAX_NASM  => 1 << 2,
	KS_OPT_SYNTAX_MASM  => 1 << 3,
	KS_OPT_SYNTAX_GAS   => 1 << 4
};

1;
