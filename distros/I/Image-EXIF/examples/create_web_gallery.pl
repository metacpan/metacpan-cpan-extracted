#!/usr/local/bin/perl -w
#
# author : sergey s prozhogin (ccpro@rrelaxo.org.ru)
# script creates web gallery. 
# for information start perl create_web_gallery.pl --help
#
# v 1.3 May-20-2004
#

use strict;

use CGI qw(:standard :html3 -no_xhtml);
use Getopt::Long;
use GD;
use Image::GD::Thumbnail;
use Image::EXIF;

use Data::Dumper;

sub main( $ );
sub init( $ );
sub copy_images( $$ );
sub create_pages( $$ );
sub create_index( $$ );
sub create_thumbnails( $$ );

my %opt;
print "create_web_galley.pl --help (v1.3): for help\n";
unless(GetOptions(\%opt, 
	'no_php', 'table_size=i', 'del_src', 'in_dir=s', 'out_dir=s',
	'mask=s', 'thumb_size=i', 'exif', 'd=s') || 
	exists($opt{help})){
	print qq^
	--no_php		- remove php section and create html
	--table_size size	- set number pictures in a table
	--del_src		- remove graphics files after handling
	--in_dir		- directory with graphics files
	--out_dir		- directory for result
	--mask	mask		- mask for graphic files
	--thumb_size size	- the size oh thumbnails
	--exif			- build EXIF section
	--d "description"	- Description for gallery\n^;

	exit();
}


my $cfg = {
	in_dir		=> '.',
	out_dir		=> '.',

	mask		=> '\.jpg',

	thumb_size	=> 180,

	table_size	=> 5,

	style		=> 'Font-Size: 8pt; Font-Family: verdana,Arial; Font-Weight: bold;',

	php_db_connect	=> '"dbname=db_name user=user_name"',
};

$cfg->{d} = undef;
$cfg->{$_} = $opt{$_} foreach(keys %opt);

init( $cfg );
main( $cfg );

sub main( $ )
{
	my $cfg = shift;

	opendir DIR, $cfg->{in_dir} or die "error open $cfg->{in_dir} directory\n";

	my @jpeg = sort grep { /$cfg->{mask}$/i && -f "$cfg->{in_dir}/$_" } readdir(DIR);
#	print "$_\n" readdir(DIR);

	closedir DIR;

	print "found:\n@jpeg\n";

	create_index( $cfg, \@jpeg );
	create_pages( $cfg, \@jpeg );
	copy_images( $cfg, \@jpeg );
	create_thumbnails( $cfg, \@jpeg );
}

sub init( $ )
{
	my $cfg = shift;

#	print "removed $cfg->{out_dir}\n";
#	system( "rm -R $cfg->{out_dir}");

	print "created $cfg->{out_dir}\n";
	mkdir("$cfg->{out_dir}/", 0755);
	mkdir("$cfg->{out_dir}/thumbnails", 0755);
	mkdir("$cfg->{out_dir}/pages", 0755);
	mkdir("$cfg->{out_dir}/images", 0755);
	
}

sub copy_images( $$ )
{
	my $cfg = shift;
	my $list = shift;

	my $command = exists($cfg->{del_src}) ? 'mv' : 'cp';

	foreach(@$list){
		system("$command $cfg->{in_dir}/$_ $cfg->{out_dir}/images/");
		print "image $_ copied\n";
	}
}

sub create_pages( $$ )    
{
	my $cfg = shift;
	my $list = shift;

	my @html;
	my $q = new CGI;

	my $style = $cfg->{style};
	my $ext = exists($cfg->{no_php}) ? 'html' : 'php';

	my $exif = new Image::EXIF;

	for( my $i=0; $i < @$list; $i ++ ){
		@html = ();
		open FH, ">$cfg->{out_dir}/pages/$list->[$i].$ext" or 
			die "can not create $cfg->{out_dir}/pages/$list->[$i].$ext\n";

		my @lines = split("\n", 
			start_html(
				-title=>($cfg->{d}||'')." $list->[$i]",
				-author=>'ccpro',
				-head => meta({
					'http-equiv' => 'Content-Type',
					'content'    => 'text/html',
					'charset' => 'windows-1251',
				}),
				-bgcolor=>'#ffffff',
				-script=>qq^
showing = false;

function toggleInfo() {
    if (showing == false) {
        if (document.all || document.getElementById)
            document.getElementById('imageinfo').style.visibility="visible";
// IE & Gecko
        else
            document.layers['imageinfo'].visibility="show"; // Netscape 4
        showing = true;
    } else {
        if (document.all || document.getElementById)
            document.getElementById('imageinfo').style.visibility="hidden";
// IE & Gecko
        else
            document.layers['imageinfo'].visibility="hide"; // Netscape 4
        showing = false;
    }
}
^
			)."\n"
		);
		if (exists($cfg->{exif})){
			print "EXIF table for $list->[$i]\n";

			$exif->file_name($list->[$i]);
			my $data = $exif->get_all_info();
			push @lines, 
				"<div id='imageinfo' style='position:absolute; left:73px; top:104px; z-index:1;background-color: #ccccCC; layer-background-color: #FFFFFF; width: 360px;height: 20px;visibility: hidden; border: 2px solid #000000;' border=0 cellpadding=2 cellspacing=0>\n".
					table(Tr([
						td({width=>115}, 'Image Generated:').
						td($data->{other}->{'Image Generated'})."\n",

						td({width=>115}, 'Camera Make:').
						td($data->{camera}->{'Equipment Make'})."\n",

						td({width=>115}, 'Camera Model:').
						td($data->{camera}->{'Camera Model'})."\n",

						td({width=>115}, 'Original Resolution:').
						td($data->{other}->{'Horizontal Resolution'}.' x '.$data->{other}->{'Vertical Resolution'})."\n",

						td({width=>115}, 'Original Size:').
						td($data->{image}->{'Image Width'}.' x '.$data->{image}->{'Image Height'})."\n",

						td({width=>115}, 'Flash:').
						td($data->{image}->{Flash})."\n",

						td({width=>115}, 'Focal Length:').
						td($data->{image}->{'Focal Length'})."\n",

						td({width=>115}, 'Exposure Time:').
						td($data->{image}->{'Exposure Time'})."\n",

						td({width=>115}, 'Aperture:').
						td($data->{image}->{'Lens Aperture'}||'')."\n",

						td({width=>115}, 'ISO Equivalent:').
						td($data->{image}->{'ISO Speed Rating'})."\n",

						td({width=>115}, 'Focus Distance:').
						td($data->{image}->{'Focus Distance'})."\n",

						td({width=>115}, 'Metering Mode:').
						td($data->{image}->{'Metering Mode'})."\n",

						td({width=>115}, 'Sensor Type:').
						td($data->{image}->{'Sensor Type'}||'')."\n",

						td({width=>115}, 'DPI:').
						td($data->{image}->{'Horizontal Resolution'}.' x '.$data->{image}->{'Vertical Resolution'})."\n",
					]))."\n".
				"</div>\n";
		}

		print FH join("\n", @lines)."\n";

		my $image_name = $list->[$i];
		$image_name =~ s/(.*)\..*/$1/;

		exists($cfg->{no_php})
		|| print FH qq^
		<?php
                if(\$dbh = pg_connect($cfg->{php_db_connect})){
			\$year = split('/', getenv('SCRIPT_NAME'));
                        \$num = ereg_replace(".JPG.PHP", "", "$image_name");
                        \$result = pg_query ( \$dbh,
                                "SELECT comment
                                 FROM photo_comments
                                 WHERE num='\$num' and year=\$year[2]");
                        if( \$result ){
                                \$res = pg_fetch_array(\$result);
                                pg_free_result (\$result);

                                echo "<td align=left cellspan=3 bgcolor='#dddddd'>\$res[0]</td>";
                        }
                        pg_close(\$dbh);
                }
		?>
		^;

		push @html, td({-align=>'center', -valign=>'center', -colspan=>3},'&nbsp;')."\n";
		my $str =
			td({-align=>'center', -valign=>'center'},
				font({-face=>'tacoma', -size=>'-1', -color=>'#000000'},
					a({-href=>'../index.html', -style=>$style}, 'index')
				)
			);

		if (exists($cfg->{exif})){
			$str .=
			td({-align=>'center', -valign=>'center'},
				'&nbsp;'.
				font({-face=>'tacoma', -size=>'-1', -color=>'#000000'},
					a({-href=>'javascript:toggleInfo()', -style=>$style}, 'exif')
				)
			);

		}

		if( $i > 0 ){
			$str = td({-align=>'center', -valign=>'center'},
				font({-face=>'tacoma', -size=>'-1', -color=>'#000000'},
					a({-href=>"./$list->[$i-1].$ext", -style=>$style},'prev').
					'&nbsp;&nbsp;'
				)
			).$str;
		}
		if( ($i+1) < @$list ){
			$str .= td({-align=>'center', -valign=>'center'},
				font({-face=>'tacoma', -size=>'-1', -color=>'#000000'},
					'&nbsp;&nbsp;'.
					a({-href=>"./$list->[$i+1].$ext", -style=>$style}, 'next')
				)
			)
		}
		push @html, $str;
#		push @html,
#			td({-align=>'center', -valign=>'center', -colspan=>3},
#				img({-src=>"../images/$list->[$i]"})
#			)."\n";

		print FH
			div({-align=>'center'}, $str.
#				table({-border=>0, -bgcolor=>'#ffffff'},
#					Tr(\@html)).br."\n".

				table({-border=>0, -cellpadding=>8, -cellspacing=>8},
					Tr([td({-align=>'center', -bgcolor=>'#EEEEEE'},
						($i+1) < @$list ?
							a({-href=>"./$list->[$i+1].$ext"}, 
								img({-src=>"../images/$list->[$i]"})
							)
							:
							a({-href=>'../'}, 
								img({-src=>"../images/$list->[$i]"})
							)
				)]))
			)."\n";

		print FH end_html()."\n";
		close FH;

		print "page $cfg->{out_dir}/pages/$list->[$i].$ext is created\n";
	}
}

sub create_index( $$ )    
{
	my $cfg = shift;
	my $list = shift;

	my @html;
	my $q = new CGI;

	my $style = $cfg->{style};
	my $ext = exists($cfg->{no_php}) ? 'html' : 'php';

	open INDEX, ">$cfg->{out_dir}/index.html" or die "can not open $cfg->{out_dir}/index.html\n";
	print INDEX
		start_html(
			-title=>$cfg->{d}||'Title',
			-author=>'ccpro',
			-head => meta({
				'http-equiv' => 'Content-Type',
				'content'    => 'text/html',
				'charset' => 'windows-1251',
			})
		)."\n";

	push @html,
		td({-align=>'left',-colspan=>$cfg->{table_size},-bgcolor=>'#ffffff'},
			br.$cfg->{d}||'Description'.br.br)."\n",

		td({-align=>'center',-colspan=>$cfg->{table_size},-bgcolor=>'#ffffff'},
			a({-href=>'/?photos=1', -style=>$style}, 'up')
		)."\n";

	my $size = $cfg->{table_size};

	for( my $i=0; $i< @$list; $i += $size ){
		my $str = "\t";
		for( my $j=0; $j < $size; $j++ ){
			$str .= defined($list->[$i+$j])?
				td({-align=>'center', -valign=>'middle', -bgcolor=>'#eeeeee'},
					CGI::center(
						a({-href=>"./pages/$list->[$i+$j].$ext"},
						img({
							-alt=>"./images/$list->[$i+$j]",
							-src=>"./thumbnails/$list->[$i+$j]",
							-border=>0
						}),
					)
					)
				):
				CGI::center(td('&nbsp;'));
		}
		push @html, $str."\n";
	}

	print INDEX CGI::center(table({ -border=>0,-width=>$cfg->{thumb_size}*$size+8*$size,
					-cellpadding=>8, -cellspacing=>8}, Tr(\@html)))."\n";
	print INDEX end_html()."\n";

	close INDEX;

	print "index.html is created\n";
}

sub create_thumbnails( $$ )
{
	my $cfg = shift;
	my $list = shift;

	foreach my $fname (@$list){

		open IN, "$cfg->{in_dir}/images/$fname"  or die "Could not open $fname.";
		my $srcImage = GD::Image->newFromJpeg(*IN);
		close IN;

		# Create the thumbnail from it, where the biggest side is 50 px
		my ($thumb, $x, $y) = Image::GD::Thumbnail::create($srcImage,$cfg->{thumb_size});

		# Save your thumbnail
		open OUT, ">$cfg->{out_dir}/thumbnails/$fname" or die "Could not save $fname\n";
		binmode OUT;
		print OUT $thumb->jpeg;
		close OUT;

		print "thumbnail $cfg->{out_dir}/thumbnail/$fname is created\n";
	}
}

