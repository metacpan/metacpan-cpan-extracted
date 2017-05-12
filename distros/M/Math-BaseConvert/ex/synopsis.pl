use Math::BaseConvert;

# CoNVert     63 from base-10 (decimal) to base- 2 (binary )
$binary_63  = cnv(     63, 10,  2 );
# CoNVert 111111 from base- 2 (binary ) to base-16 (hex    )
$hex_63     = cnv( 111111,  2, 16 );
# CoNVert     3F from base-16 (hex    ) to base-10 (decimal)
$decimal_63 = cnv(   '3F', 16, 10 );
print "63 dec->bin $binary_63 bin->hex $hex_63 hex->dec $decimal_63\n";

