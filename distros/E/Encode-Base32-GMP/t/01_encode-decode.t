use Test::Base;
use Encode::Base32::GMP;

plan tests => 16 * blocks;

run {
  my $block = shift;
  is encode_base32($block->base10), $block->crockford;
  is encode_base32($block->base10,'crockford'), $block->crockford;
  is encode_base32($block->base10,'rfc4648'), $block->rfc4648;
  is encode_base32($block->base10,'zbase32'), $block->zbase32;
  is encode_base32($block->base10,'base32hex'), $block->base32hex;
  is encode_base32($block->base10,'gmp'), $block->gmp;
  is int decode_base32($block->crockford), $block->base10;
  is int decode_base32($block->crockford,'crockford'), $block->base10;
  is int decode_base32($block->rfc4648,'rfc4648'), $block->base10;
  is int decode_base32($block->zbase32,'zbase32'), $block->base10;
  is int decode_base32($block->base32hex,'base32hex'), $block->base10;
  is int decode_base32($block->gmp,'gmp'), $block->base10;
  is Encode::Base32::GMP::base32_from_to( $block->crockford, 'crockford', 'rfc4648' ), $block->rfc4648;
  is Encode::Base32::GMP::base32_from_to( $block->crockford, 'crockford', 'zbase32' ), $block->zbase32;
  is Encode::Base32::GMP::base32_from_to( $block->crockford, 'crockford', 'base32hex' ), $block->base32hex;
  is Encode::Base32::GMP::base32_from_to( $block->crockford, 'crockford', 'gmp' ), $block->gmp;
};

__DATA__
===
--- base10: 0
--- crockford: 0
--- rfc4648: A
--- zbase32: Y
--- base32hex: 0
--- gmp: 0

===
--- base10: 1
--- crockford: 1
--- rfc4648: B
--- zbase32: B
--- base32hex: 1
--- gmp: 1

===
--- base10: 2
--- crockford: 2
--- rfc4648: C
--- zbase32: N
--- base32hex: 2
--- gmp: 2

===
--- base10: 3
--- crockford: 3
--- rfc4648: D
--- zbase32: D
--- base32hex: 3
--- gmp: 3

===
--- base10: 4
--- crockford: 4
--- rfc4648: E
--- zbase32: R
--- base32hex: 4
--- gmp: 4

===
--- base10: 5
--- crockford: 5
--- rfc4648: F
--- zbase32: F
--- base32hex: 5
--- gmp: 5

===
--- base10: 6
--- crockford: 6
--- rfc4648: G
--- zbase32: G
--- base32hex: 6
--- gmp: 6

===
--- base10: 7
--- crockford: 7
--- rfc4648: H
--- zbase32: 8
--- base32hex: 7
--- gmp: 7

===
--- base10: 8
--- crockford: 8
--- rfc4648: I
--- zbase32: E
--- base32hex: 8
--- gmp: 8

===
--- base10: 9
--- crockford: 9
--- rfc4648: J
--- zbase32: J
--- base32hex: 9
--- gmp: 9

===
--- base10: 10
--- crockford: A
--- rfc4648: K
--- zbase32: K
--- base32hex: A
--- gmp: A

===
--- base10: 11
--- crockford: B
--- rfc4648: L
--- zbase32: M
--- base32hex: B
--- gmp: B

===
--- base10: 12
--- crockford: C
--- rfc4648: M
--- zbase32: C
--- base32hex: C
--- gmp: C

===
--- base10: 13
--- crockford: D
--- rfc4648: N
--- zbase32: P
--- base32hex: D
--- gmp: D

===
--- base10: 14
--- crockford: E
--- rfc4648: O
--- zbase32: Q
--- base32hex: E
--- gmp: E

===
--- base10: 15
--- crockford: F
--- rfc4648: P
--- zbase32: X
--- base32hex: F
--- gmp: F

===
--- base10: 16
--- crockford: G
--- rfc4648: Q
--- zbase32: O
--- base32hex: G
--- gmp: G

===
--- base10: 17
--- crockford: H
--- rfc4648: R
--- zbase32: T
--- base32hex: H
--- gmp: H

===
--- base10: 18
--- crockford: J
--- rfc4648: S
--- zbase32: 1
--- base32hex: I
--- gmp: I

===
--- base10: 19
--- crockford: K
--- rfc4648: T
--- zbase32: U
--- base32hex: J
--- gmp: J

===
--- base10: 20
--- crockford: M
--- rfc4648: U
--- zbase32: W
--- base32hex: K
--- gmp: K

===
--- base10: 21
--- crockford: N
--- rfc4648: V
--- zbase32: I
--- base32hex: L
--- gmp: L

===
--- base10: 22
--- crockford: P
--- rfc4648: W
--- zbase32: S
--- base32hex: M
--- gmp: M

===
--- base10: 23
--- crockford: Q
--- rfc4648: X
--- zbase32: Z
--- base32hex: N
--- gmp: N

===
--- base10: 24
--- crockford: R
--- rfc4648: Y
--- zbase32: A
--- base32hex: O
--- gmp: O

===
--- base10: 25
--- crockford: S
--- rfc4648: Z
--- zbase32: 3
--- base32hex: P
--- gmp: P

===
--- base10: 26
--- crockford: T
--- rfc4648: 2
--- zbase32: 4
--- base32hex: Q
--- gmp: Q

===
--- base10: 27
--- crockford: V
--- rfc4648: 3
--- zbase32: 5
--- base32hex: R
--- gmp: R

===
--- base10: 28
--- crockford: W
--- rfc4648: 4
--- zbase32: H
--- base32hex: S
--- gmp: S

===
--- base10: 29
--- crockford: X
--- rfc4648: 5
--- zbase32: 7
--- base32hex: T
--- gmp: T

===
--- base10: 30
--- crockford: Y
--- rfc4648: 6
--- zbase32: 6
--- base32hex: U
--- gmp: U

===
--- base10: 31
--- crockford: Z
--- rfc4648: 7
--- zbase32: 9
--- base32hex: V
--- gmp: V

===
--- base10: 32
--- crockford: 10
--- rfc4648: BA
--- zbase32: BY
--- base32hex: 10
--- gmp: 10

===
--- base10: 33
--- crockford: 11
--- rfc4648: BB
--- zbase32: BB
--- base32hex: 11
--- gmp: 11

===
--- base10: 34
--- crockford: 12
--- rfc4648: BC
--- zbase32: BN
--- base32hex: 12
--- gmp: 12

===
--- base10: 35
--- crockford: 13
--- rfc4648: BD
--- zbase32: BD
--- base32hex: 13
--- gmp: 13

===
--- base10: 36
--- crockford: 14
--- rfc4648: BE
--- zbase32: BR
--- base32hex: 14
--- gmp: 14

===
--- base10: 37
--- crockford: 15
--- rfc4648: BF
--- zbase32: BF
--- base32hex: 15
--- gmp: 15

===
--- base10: 38
--- crockford: 16
--- rfc4648: BG
--- zbase32: BG
--- base32hex: 16
--- gmp: 16

===
--- base10: 39
--- crockford: 17
--- rfc4648: BH
--- zbase32: B8
--- base32hex: 17
--- gmp: 17

===
--- base10: 40
--- crockford: 18
--- rfc4648: BI
--- zbase32: BE
--- base32hex: 18
--- gmp: 18

===
--- base10: 41
--- crockford: 19
--- rfc4648: BJ
--- zbase32: BJ
--- base32hex: 19
--- gmp: 19

===
--- base10: 42
--- crockford: 1A
--- rfc4648: BK
--- zbase32: BK
--- base32hex: 1A
--- gmp: 1A

===
--- base10: 43
--- crockford: 1B
--- rfc4648: BL
--- zbase32: BM
--- base32hex: 1B
--- gmp: 1B

===
--- base10: 44
--- crockford: 1C
--- rfc4648: BM
--- zbase32: BC
--- base32hex: 1C
--- gmp: 1C

===
--- base10: 45
--- crockford: 1D
--- rfc4648: BN
--- zbase32: BP
--- base32hex: 1D
--- gmp: 1D

===
--- base10: 46
--- crockford: 1E
--- rfc4648: BO
--- zbase32: BQ
--- base32hex: 1E
--- gmp: 1E

===
--- base10: 47
--- crockford: 1F
--- rfc4648: BP
--- zbase32: BX
--- base32hex: 1F
--- gmp: 1F

===
--- base10: 48
--- crockford: 1G
--- rfc4648: BQ
--- zbase32: BO
--- base32hex: 1G
--- gmp: 1G

===
--- base10: 49
--- crockford: 1H
--- rfc4648: BR
--- zbase32: BT
--- base32hex: 1H
--- gmp: 1H

===
--- base10: 50
--- crockford: 1J
--- rfc4648: BS
--- zbase32: B1
--- base32hex: 1I
--- gmp: 1I

===
--- base10: 51
--- crockford: 1K
--- rfc4648: BT
--- zbase32: BU
--- base32hex: 1J
--- gmp: 1J

===
--- base10: 52
--- crockford: 1M
--- rfc4648: BU
--- zbase32: BW
--- base32hex: 1K
--- gmp: 1K

===
--- base10: 53
--- crockford: 1N
--- rfc4648: BV
--- zbase32: BI
--- base32hex: 1L
--- gmp: 1L

===
--- base10: 54
--- crockford: 1P
--- rfc4648: BW
--- zbase32: BS
--- base32hex: 1M
--- gmp: 1M

===
--- base10: 55
--- crockford: 1Q
--- rfc4648: BX
--- zbase32: BZ
--- base32hex: 1N
--- gmp: 1N

===
--- base10: 56
--- crockford: 1R
--- rfc4648: BY
--- zbase32: BA
--- base32hex: 1O
--- gmp: 1O

===
--- base10: 57
--- crockford: 1S
--- rfc4648: BZ
--- zbase32: B3
--- base32hex: 1P
--- gmp: 1P

===
--- base10: 58
--- crockford: 1T
--- rfc4648: B2
--- zbase32: B4
--- base32hex: 1Q
--- gmp: 1Q

===
--- base10: 59
--- crockford: 1V
--- rfc4648: B3
--- zbase32: B5
--- base32hex: 1R
--- gmp: 1R

===
--- base10: 60
--- crockford: 1W
--- rfc4648: B4
--- zbase32: BH
--- base32hex: 1S
--- gmp: 1S

===
--- base10: 61
--- crockford: 1X
--- rfc4648: B5
--- zbase32: B7
--- base32hex: 1T
--- gmp: 1T

===
--- base10: 62
--- crockford: 1Y
--- rfc4648: B6
--- zbase32: B6
--- base32hex: 1U
--- gmp: 1U

===
--- base10: 63
--- crockford: 1Z
--- rfc4648: B7
--- zbase32: B9
--- base32hex: 1V
--- gmp: 1V

===
--- base10: 64
--- crockford: 20
--- rfc4648: CA
--- zbase32: NY
--- base32hex: 20
--- gmp: 20

===
--- base10: 65
--- crockford: 21
--- rfc4648: CB
--- zbase32: NB
--- base32hex: 21
--- gmp: 21

===
--- base10: 66
--- crockford: 22
--- rfc4648: CC
--- zbase32: NN
--- base32hex: 22
--- gmp: 22

===
--- base10: 67
--- crockford: 23
--- rfc4648: CD
--- zbase32: ND
--- base32hex: 23
--- gmp: 23

===
--- base10: 68
--- crockford: 24
--- rfc4648: CE
--- zbase32: NR
--- base32hex: 24
--- gmp: 24

===
--- base10: 69
--- crockford: 25
--- rfc4648: CF
--- zbase32: NF
--- base32hex: 25
--- gmp: 25

===
--- base10: 70
--- crockford: 26
--- rfc4648: CG
--- zbase32: NG
--- base32hex: 26
--- gmp: 26

===
--- base10: 71
--- crockford: 27
--- rfc4648: CH
--- zbase32: N8
--- base32hex: 27
--- gmp: 27

===
--- base10: 72
--- crockford: 28
--- rfc4648: CI
--- zbase32: NE
--- base32hex: 28
--- gmp: 28

===
--- base10: 73
--- crockford: 29
--- rfc4648: CJ
--- zbase32: NJ
--- base32hex: 29
--- gmp: 29

===
--- base10: 74
--- crockford: 2A
--- rfc4648: CK
--- zbase32: NK
--- base32hex: 2A
--- gmp: 2A

===
--- base10: 75
--- crockford: 2B
--- rfc4648: CL
--- zbase32: NM
--- base32hex: 2B
--- gmp: 2B

===
--- base10: 76
--- crockford: 2C
--- rfc4648: CM
--- zbase32: NC
--- base32hex: 2C
--- gmp: 2C

===
--- base10: 77
--- crockford: 2D
--- rfc4648: CN
--- zbase32: NP
--- base32hex: 2D
--- gmp: 2D

===
--- base10: 78
--- crockford: 2E
--- rfc4648: CO
--- zbase32: NQ
--- base32hex: 2E
--- gmp: 2E

===
--- base10: 79
--- crockford: 2F
--- rfc4648: CP
--- zbase32: NX
--- base32hex: 2F
--- gmp: 2F

===
--- base10: 80
--- crockford: 2G
--- rfc4648: CQ
--- zbase32: NO
--- base32hex: 2G
--- gmp: 2G

===
--- base10: 81
--- crockford: 2H
--- rfc4648: CR
--- zbase32: NT
--- base32hex: 2H
--- gmp: 2H

===
--- base10: 82
--- crockford: 2J
--- rfc4648: CS
--- zbase32: N1
--- base32hex: 2I
--- gmp: 2I

===
--- base10: 83
--- crockford: 2K
--- rfc4648: CT
--- zbase32: NU
--- base32hex: 2J
--- gmp: 2J

===
--- base10: 84
--- crockford: 2M
--- rfc4648: CU
--- zbase32: NW
--- base32hex: 2K
--- gmp: 2K

===
--- base10: 85
--- crockford: 2N
--- rfc4648: CV
--- zbase32: NI
--- base32hex: 2L
--- gmp: 2L

===
--- base10: 86
--- crockford: 2P
--- rfc4648: CW
--- zbase32: NS
--- base32hex: 2M
--- gmp: 2M

===
--- base10: 87
--- crockford: 2Q
--- rfc4648: CX
--- zbase32: NZ
--- base32hex: 2N
--- gmp: 2N

===
--- base10: 88
--- crockford: 2R
--- rfc4648: CY
--- zbase32: NA
--- base32hex: 2O
--- gmp: 2O

===
--- base10: 89
--- crockford: 2S
--- rfc4648: CZ
--- zbase32: N3
--- base32hex: 2P
--- gmp: 2P

===
--- base10: 90
--- crockford: 2T
--- rfc4648: C2
--- zbase32: N4
--- base32hex: 2Q
--- gmp: 2Q

===
--- base10: 91
--- crockford: 2V
--- rfc4648: C3
--- zbase32: N5
--- base32hex: 2R
--- gmp: 2R

===
--- base10: 92
--- crockford: 2W
--- rfc4648: C4
--- zbase32: NH
--- base32hex: 2S
--- gmp: 2S

===
--- base10: 93
--- crockford: 2X
--- rfc4648: C5
--- zbase32: N7
--- base32hex: 2T
--- gmp: 2T

===
--- base10: 94
--- crockford: 2Y
--- rfc4648: C6
--- zbase32: N6
--- base32hex: 2U
--- gmp: 2U

===
--- base10: 95
--- crockford: 2Z
--- rfc4648: C7
--- zbase32: N9
--- base32hex: 2V
--- gmp: 2V

===
--- base10: 96
--- crockford: 30
--- rfc4648: DA
--- zbase32: DY
--- base32hex: 30
--- gmp: 30

===
--- base10: 97
--- crockford: 31
--- rfc4648: DB
--- zbase32: DB
--- base32hex: 31
--- gmp: 31

===
--- base10: 98
--- crockford: 32
--- rfc4648: DC
--- zbase32: DN
--- base32hex: 32
--- gmp: 32

===
--- base10: 99
--- crockford: 33
--- rfc4648: DD
--- zbase32: DD
--- base32hex: 33
--- gmp: 33

===
--- base10: 100
--- crockford: 34
--- rfc4648: DE
--- zbase32: DR
--- base32hex: 34
--- gmp: 34
