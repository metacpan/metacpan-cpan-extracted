
.sub _main
	_set_machine_info()
	_read_memory()
	_setup()
	_main2()
	end
.end

.sub _setup
	print "Setting up the Z-machine\n"
.end

.sub _global_var
	noop # for now
.end

#############################################
# Global macros
.macro signed_word (VAL) # changes 0..65535 -> 0..32767, -32768..-1
	if .VAL < 0x8000 goto .$LOOP
	.VAL -= 0x10000
	.local $LOOP:
.endm

.macro loadb_indexed (RESULT, ARR, BYTE_INDEX)
        $I0 = .ARR
	$I1 = .BYTE_INDEX
	$I0 += $I1
	$I0 &= 0xffff # in case 65535 is represented as -1
	.RESULT = memory[$I0]
.endm

.macro loadw_indexed (RESULT, ARR, WORD_INDEX)
        $I0 = .ARR
	$I1 = .WORD_INDEX
	$I1 *= 2
	$I0 += $I1
	$I0 &= 0xffff # index
	$I2 = memory[$I0]
	$I2 *= 0x100
	inc $I0
	$I3 = memory[$I0]
	$I2 += $I3
	.RESULT = $I2
.endm

.macro storeb_indexed (VALUE, ARR, BYTE_INDEX)
        $I0 = .ARR
	$I1 = .BYTE_INDEX
	$I0 += $I1
	$I0 &= 0xffff # in case 65535 is represented as -1
	$I2 = .VALUE
	$I2 &= 0xff
	memory[$I0] = $I2
.endm

.macro storew_indexed (VALUE, ARR, WORD_INDEX)
        $I0 = .ARR
	$I1 = .WORD_INDEX
	$I1 *= 2
	$I0 += $I1
	$I0 &= 0xffff # in case 65535 is represented as -1
	$I2 = .VALUE
	$I3 = $I2 >> 8
	memory[$I0] = $I3
	$I3 = $I2 % 0x100
	inc $I0
	memory[$I0] = $I3
.endm

#############################################

# Add 16 numbers to memory, from a string like " 01 a3 ..."
# Parrot has no 'hex'?
.macro get_hexnum
	$S1 = str[strpos]
	$I1 = ord $S1
	$I1 -= 48
	if $I1 < 10 goto .$LOOP
	$I1 -= 39
	.local $LOOP:
.endm
.sub _mem_add
	.param int mempos # where are we currently in memory?
	.param string str
	.local int val
	.local int strpos
	.local pmc mem
	.local int len

	strpos = 1 # skip first space
	mem = global "_Z_Memory"
	len = length str

	Lstart:
	.get_hexnum # sets $I1 to "tens" digit
	inc strpos
	val = $I1 * 0x10

	.get_hexnum
	val += $I1
	strpos += 2
	mem[mempos] = val
	inc mempos
	if strpos < len goto Lstart
	global "_Z_Memory" = mem
.end

