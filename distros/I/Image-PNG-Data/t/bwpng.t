use FindBin '$Bin';
use lib "$Bin";
use IPNGDT;

my @data = (
"abcd",
"efgh",
"ijkl",
"mnop",
"abcd",
"efgh",
"ijkl",
"mnop",
"abcd",
"efgh",
"ijkl",
"mnop",
"abcd",
"efgh",
"ijkl",
"mnop",
"abcd",
"efgh",
"ijkl",
"mnop",
"abcd",
"efgh",
"ijkl",
"mnop",
"abcd",
"efgh",
"ijkl",
"mnop",
"abcd",
"efgh",
"ijkl",
"mnop",
);

my $png = bwpng (\@data, block => 10);
$png->write_png_file ("$Bin/abc.png");

my $png_palette = bwpng (\@data, block => 30, fg => '4fe', bg => '77f');
$png_palette->write_png_file ("$Bin/abc-palette.png");


my $qr = <<EOF;
******* *  ** *******
*     *   * * *     *
* *** *       * *** *
* *** *   **  * *** *
* *** *  * *  * *** *
*     *  **** *     *
******* * * * *******
        *  **        
** ** *   *** *     *
*   **  ***    * *   
 * ****     * *    **
*    * * * * * ** ***
  **  *   ***   ** **
        * **  * **  *
*******  *****  ***  
*     *  * ** * **** 
* *** * *   *    * * 
* *** * * **   *  *  
* *** *     *** * ***
*     * **  * *   ***
******* * *  ****    
EOF
ok (1);
done_testing ();
