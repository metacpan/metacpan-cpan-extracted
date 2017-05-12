
.include "main.pir"

.sub _main2
	# this will at some point do the stuff we repeat for restart/restore
	_rtn1516()
.end

#.macro z_get_global (RESULT, GLOBAL_NUM)
#	.loadw_indexed(.RESULT, 770, .GLOBAL_NUM)
#.endm
#
#.macro z_set_global (VALUE, GLOBAL_NUM)
#	.storew_indexed(.VALUE, 770, .GLOBAL_NUM)
#.endm

#############################################

.sub _set_machine_info
	$P0 = new .PerlInt
	$P1 = new PerlString
	$P0 = 66
	global "abbrev_table_address" = $P0
	$P0 = 6
	global "attribute_bytes" = $P0
	$P0 = 1509
	global "dictionary_address" = $P0
	$P0 = 9
	global "encoded_word_length" = $P0
	$P0 = 54600
	global "file_checksum" = $P0
	$P0 = 1992
	global "file_length" = $P0
	$P0 = 1517
	global "first_instruction_address" = $P0
	$P0 = 770
	global "global_variable_address" = $P0
	$P0 = 65535
	global "max_objects" = $P0
	$P0 = 63
	global "max_properties" = $P0
	$P0 = 14
	global "object_bytes" = $P0
	$P0 = 266
	global "object_table_address" = $P0
	$P0 = 4
	global "packed_multiplier" = $P0
	$P0 = 1516
	global "paged_memory_address" = $P0
	$P0 = 2
	global "pointer_size" = $P0
	$P0 = 1
	global "release_number" = $P0
	$P0 = 0
	global "routines_offset" = $P0
	$P1 = "040901"
	global "serial_code" = $P1
	$P0 = 1507
	global "static_memory_address" = $P0
	$P0 = 0
	global "strings_offset" = $P0
	$P0 = 5
	global "version" = $P0
.end

.sub _rtn1516
	.local int result
	.local pmc memory
	memory = global "_Z_Memory"
	L1517:	$I100 = _rtn1524()
	.storew_indexed($I100, 770, 239)
	L1522:	end
.end

.sub _rtn1524
	.param int local0
	.param int local1
	.local int result
	.local pmc memory
	memory = global "_Z_Memory"
	L1525:	local0 = 1 + 2
	L1529:	.signed_word(local0)
	print local0
	L1532:	$S0 = chr 32
	print $S0
	L1535:	local0 = 1 + -3
	L1541:	.signed_word(local0)
	print local0
	L1544:	$S0 = chr 32
	print $S0
	L1547:	local0 = -1 + -2
	L1554:	.signed_word(local0)
	print local0
	L1557:	$S0 = chr 32
	print $S0
	L1560:	local0 = 32767 + 2
	L1566:	.signed_word(local0)
	print local0
	L1569:	$S0 = chr 32
	print $S0
	L1572:	.signed_word(local0)
	local0 = local0 + 2
	L1576:	.signed_word(local0)
	print local0
	L1579:	$S0 = chr 32
	print $S0
	L1582:	local0 = 3 - 2
	L1586:	.signed_word(local0)
	print local0
	L1589:	$S0 = chr 32
	print $S0
	L1592:	local0 = 3 * 4
	L1596:	.signed_word(local0)
	print local0
	L1599:	$S0 = chr 32
	print $S0
	L1602:	print "\n"
	L1603:	$I100 = 25 + 22
	.storew_indexed($I100, 770, 0)
	L1607:	.loadw_indexed($I100, 770, 0)
	.signed_word($I100)
	print $I100
	L1610:	$S0 = chr 32
	print $S0
	L1613:	local0 = 3
	L1616:	.signed_word(local0)
	$I100 = 25 + local0
	.storew_indexed($I100, 770, 0)
	L1620:	.loadw_indexed($I100, 770, 0)
	.signed_word($I100)
	print $I100
	L1623:	$S0 = chr 32
	print $S0
	L1626:	$I100 = 36 + 1
	save $I100
	L1630:	restore $I100
	.signed_word($I100)
	print $I100
	L1633:	$S0 = chr 32
	print $S0
	L1636:	.loadw_indexed($I101, 770, 0)
	.signed_word($I101)
	.signed_word(local0)
	$I100 = $I101 + local0
	save $I100
	L1640:	restore $I100
	.signed_word($I100)
	print $I100
	L1643:	$S0 = chr 32
	print $S0
	L1646:	save 20
	L1649:	save 21
	L1652:	save 22
	L1655:	restore $I101
	restore $I102
	.signed_word($I101)
	.signed_word($I102)
	$I100 = $I101 + $I102
	save $I100
	L1659:	restore $I100
	.signed_word($I100)
	print $I100
	L1662:	$S0 = chr 32
	print $S0
	L1665:	restore local0
	L1668:	.signed_word(local0)
	print local0
	L1671:	$S0 = chr 32
	print $S0
	L1674:	$I100 = 1 - 3
	save $I100
	L1678:	restore $I100
	.signed_word($I100)
	print $I100
	L1681:	$S0 = chr 32
	print $S0
	L1684:	print "\n"
	L1685:	local1 = local0
	L1688:	.signed_word(local1)
	print local1
	L1691:	$S0 = chr 32
	print $S0
	L1694:	.storeb_indexed(1, 1250, 2)
	L1700:	.storeb_indexed(5, 1250, 3)
	L1706:	local1 = 1
	L1709:	.loadw_indexed(local0, 1250, local1)
	L1715:	.signed_word(local0)
	print local0
	L1718:	$S0 = chr 32
	print $S0
	L1721:	.storew_indexed(519, 1250, 2)
	L1728:	.loadb_indexed(local0, 1250, 4)
	L1734:	.signed_word(local0)
	print local0
	L1737:	$S0 = chr 32
	print $S0
	L1740:	.loadb_indexed(local1, 1250, 5)
	L1746:	.signed_word(local1)
	print local1
	L1749:	$S0 = chr 32
	print $S0
	L1752:	save 17
	L1755:	save 18
	L1758:	save 19
	L1761:	restore local0
	L1764:	.signed_word(local0)
	print local0
	L1767:	$S0 = chr 32
	print $S0
	L1770:	print " aha "
	L1775:	local0 = 65 + 3
	L1779:	$S0 = chr local0
	print $S0
	L1782:	print "\n"
	L1783:	local0 = 3 | 6
	L1787:	.signed_word(local0)
	print local0
	L1790:	local0 = 3 & 7
	L1794:	.signed_word(local0)
	print local0
	L1797:	goto L1803
	L1800:	print 0
	L1803:	if 1 == 0 goto L1809
	L1806:	print 1
	L1809:	unless 1 == 0 goto L1815
	L1812:	print 1
	L1815:	.signed_word(local0)
	if local0 > 1 goto L1822
	L1819:	print 0
	L1822:	.signed_word(local0)
	unless local0 > 1 goto L1829
	L1826:	print 1
	L1829:	.signed_word(local0)
	if local0 < 1 goto L1836
	L1833:	print 1
	L1836:	.signed_word(local0)
	unless local0 < 1 goto L1843
	L1840:	print 0
	L1843:	print "\n"
	L1844:	_rtn1880(3)
	L1849:	local1 = _rtn1880(3)
	L1855:	_rtn1880(3, 4, 5, 6, 7, 8)
	L1866:	local1 = _rtn1880(3, 4, 5, 6, 7, 8)
	L1878:	end
.end

.sub _rtn1880
	.param int local0
	.param int local1
	.param int local2
	.param int local3
	.param int local4
	.param int local5
	.param int local6
	.local int local7
	.local int local8
	.local int local9
	.local int local10
	.local int result
	.local pmc memory
	memory = global "_Z_Memory"
	L1881:	.signed_word(local0)
	print local0
	L1884:	.signed_word(local3)
	print local3
	L1887:	local1 = local2
	L1890:	local4 = local5
	L1893:	local6 = local7
	L1896:	local8 = local9
	L1899:	local10 = 1
	L1902:	$S0 = chr 32
	print $S0
	L1905:	.pcc_begin_return
	.return 7
	.pcc_end_return
.end

.sub _read_memory
	$P0 = new .Array
	$P0 = 2048
	global "_Z_Memory" = $P0
	#         Address    0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
	_mem_add(0x000000, " 05 00 00 01 05 ec 05 ed 05 e5 01 0a 03 02 05 e3")
	_mem_add(0x000010, " 00 00 30 34 30 39 30 31 00 42 01 f2 d5 48 00 50")
	_mem_add(0x000020, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 05 e2")
	_mem_add(0x000030, " 00 00 00 00 00 00 01 02 00 00 00 00 36 2e 33 30")
	_mem_add(0x000040, " 80 00 00 20 00 20 00 20 00 20 00 20 00 20 00 20")
	_mem_add(0x000050, " 00 20 00 20 00 20 00 20 00 20 00 20 00 20 00 20")
	_mem_add(0x000060, " 00 20 00 20 00 20 00 20 00 20 00 20 00 20 00 20")
	_mem_add(0x000070, " 00 20 00 20 00 20 00 20 00 20 00 20 00 20 00 20")
	_mem_add(0x000080, " 00 20 00 20 00 20 00 20 00 20 00 20 00 20 00 20")
	_mem_add(0x000090, " 00 20 00 20 00 20 00 20 00 20 00 20 00 20 00 20")
	_mem_add(0x0000a0, " 00 20 00 20 00 20 00 20 00 20 00 20 00 20 00 20")
	_mem_add(0x0000b0, " 00 20 00 20 00 20 00 20 00 20 00 20 00 20 00 20")
	_mem_add(0x0000c0, " 00 20 00 20 00 20 00 20 00 20 00 20 00 20 00 20")
	_mem_add(0x0000d0, " 00 20 00 20 00 20 00 20 00 20 00 20 00 20 00 20")
	_mem_add(0x0000e0, " 00 20 00 20 00 20 00 20 00 20 00 20 00 20 00 20")
	_mem_add(0x0000f0, " 00 20 00 20 00 20 00 20 00 20 00 20 00 20 00 20")
	_mem_add(0x000100, " 00 20 00 03 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000110, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000120, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000130, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000140, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000150, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000160, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000170, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000180, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000190, " 00 00 00 00 01 c0 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x0001a0, " 00 00 01 d0 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x0001b0, " 01 e2 00 00 00 00 00 00 00 00 00 00 00 00 01 f4")
	_mem_add(0x0001c0, " 02 11 11 9b 18 00 00 00 00 00 00 00 42 00 01 00")
	_mem_add(0x0001d0, " 03 12 87 3d 48 e4 a5 00 00 00 00 00 00 00 42 00")
	_mem_add(0x0001e0, " 02 00 03 12 f4 6b 2e cd 45 00 00 00 00 00 00 00")
	_mem_add(0x0001f0, " 42 00 03 00 03 13 19 5d d3 b0 a5 00 00 00 00 00")
	_mem_add(0x000200, " 00 00 42 00 04 00 00 01 00 02 00 03 00 04 00 00")
	_mem_add(0x000210, " 00 48 01 e3 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000220, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000230, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000240, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000250, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000260, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000270, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000280, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000290, " 01 e4 01 e5 01 e7 01 e9 01 eb 01 ec 01 ed 01 ee")
	_mem_add(0x0002a0, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x0002b0, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x0002c0, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x0002d0, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x0002e0, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x0002f0, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000300, " 01 f1 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000310, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000320, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000330, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000340, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000350, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000360, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000370, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000380, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000390, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x0003a0, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x0003b0, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x0003c0, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x0003d0, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x0003e0, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x0003f0, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000400, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000410, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000420, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000430, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000440, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000450, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000460, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000470, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000480, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000490, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x0004a0, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x0004b0, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x0004c0, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x0004d0, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x0004e0, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x0004f0, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000500, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000510, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000520, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000530, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000540, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000550, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000560, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000570, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000580, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x000590, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x0005a0, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x0005b0, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x0005c0, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x0005d0, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x0005e0, " 00 00 00 00 00 03 2e 2c 22 09 00 00 00 e0 3f 01")
	_mem_add(0x0005f0, " 7d ff ba 00 02 14 01 02 01 e6 bf 01 e5 7f 20 d4")
	_mem_add(0x000600, " 4f 01 ff fd 01 e6 bf 01 e5 7f 20 d4 0f ff ff ff")
	_mem_add(0x000610, " fe 01 e6 bf 01 e5 7f 20 d4 1f 7f ff 02 01 e6 bf")
	_mem_add(0x000620, " 01 e5 7f 20 54 01 02 01 e6 bf 01 e5 7f 20 15 03")
	_mem_add(0x000630, " 02 01 e6 bf 01 e5 7f 20 16 03 04 01 e6 bf 01 e5")
	_mem_add(0x000640, " 7f 20 bb 14 19 16 10 e6 bf 10 e5 7f 20 0d 01 03")
	_mem_add(0x000650, " 34 19 01 10 e6 bf 10 e5 7f 20 14 24 01 00 e6 bf")
	_mem_add(0x000660, " 00 e5 7f 20 74 10 01 00 e6 bf 00 e5 7f 20 e8 7f")
	_mem_add(0x000670, " 14 e8 7f 15 e8 7f 16 74 00 00 00 e6 bf 00 e5 7f")
	_mem_add(0x000680, " 20 e9 7f 01 e6 bf 01 e5 7f 20 15 01 03 00 e6 bf")
	_mem_add(0x000690, " 00 e5 7f 20 bb 2d 02 01 e6 bf 02 e5 7f 20 e2 17")
	_mem_add(0x0006a0, " 04 e2 02 01 e2 17 04 e2 03 05 0d 02 01 cf 2f 04")
	_mem_add(0x0006b0, " e2 02 01 e6 bf 01 e5 7f 20 e1 13 04 e2 02 02 07")
	_mem_add(0x0006c0, " d0 1f 04 e2 04 01 e6 bf 01 e5 7f 20 d0 1f 04 e2")
	_mem_add(0x0006d0, " 05 02 e6 bf 02 e5 7f 20 e8 7f 11 e8 7f 12 e8 7f")
	_mem_add(0x0006e0, " 13 e9 7f 01 e6 bf 01 e5 7f 20 b2 00 cd 98 05 14")
	_mem_add(0x0006f0, " 41 03 01 e5 bf 01 bb 08 03 06 01 e6 bf 01 09 03")
	_mem_add(0x000700, " 07 01 e6 bf 01 8c 00 05 e6 7f 00 90 01 c5 e6 7f")
	_mem_add(0x000710, " 01 90 01 45 e6 7f 01 43 01 01 c5 e6 7f 00 43 01")
	_mem_add(0x000720, " 01 45 e6 7f 01 42 01 01 c5 e6 7f 01 42 01 01 45")
	_mem_add(0x000730, " e6 7f 00 bb da 1f 01 d6 03 d9 1f 01 d6 03 02 fa")
	_mem_add(0x000740, " 15 57 01 d6 03 04 05 06 07 08 ec 15 57 01 d6 03")
	_mem_add(0x000750, " 04 05 06 07 08 02 ba 00 0b e6 bf 01 e6 bf 04 2d")
	_mem_add(0x000760, " 02 03 2d 05 06 2d 07 08 2d 09 0a 0d 0b 01 e5 7f")
	_mem_add(0x000770, " 20 9b 07 00 02 b1 00 00 14 c1 73 53 42 74 72 60")
	_mem_add(0x000780, " 1b 39 5d c7 6b 2a 14 c1 f8 a5 00 00 4c d2 a8 a5")
	_mem_add(0x000790, " 22 ea 9b 2a 5d 48 5d 46 e5 45 00 00 25 58 66 f4")
	_mem_add(0x0007a0, " f8 a5 00 00 5d 52 19 d3 ba 6c 00 00 22 95 f8 a5")
	_mem_add(0x0007b0, " 20 d1 c4 a5 56 ee cf 25 56 ee 4f 25 5b 34 16 c6")
	_mem_add(0x0007c0, " 5e e6 f8 a5 9a f7 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x0007d0, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x0007e0, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
	_mem_add(0x0007f0, " 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00")
.end
