use 5.007003;
use strict;
use ExtUtils::MakeMaker;
use File::Spec;
use File::Basename;

my $Name = 'InCharset';
my $ucmdir = shift;
if ($ucmdir =~ s/^UCMDIR=//o){
    opendir my $dh, $ucmdir or die "$ucmdir:$!";
    for my $ucm (sort grep /\.ucm$/o, readdir($dh)){
	mkInCharset(File::Spec->catdir($ucmdir, $ucm));
    }
}

my %inpm;
my $PM;
opendir my $dh, "$Name" or die "$Name:  $!";
for my $pm (sort grep /\.pm$/o, readdir($dh)){
    open my $fh, "$Name/$pm" or die "$Name/$pm:$!"; 
    $PM->{"$Name/$pm"} = "\$(INST_LIBDIR)/$Name/$pm";
    $pm =~ s/\.pm$//o;
    while(<$fh>){
	if (/^sub (\w+)/){
	    $inpm{$1} = "Encode\::$Name\::$pm";
	}
    }
}
$PM->{"$Name/Config.pm"} = "\$(INST_LIBDIR)/$Name/Config.pm";
$PM->{"$Name.pm"} = "\$(INST_LIBDIR)/$Name.pm";

open my $fh, ">$Name/Config.pm" or die ">$Name/Config.pm";
print $fh <<"EOT";
#
# This file is auto-generated; do not edit by hand!
#
package Encode\::$Name\::Config;
use strict;
our %InPM = (
EOT

for my $sub (sort keys %inpm){
    printf $fh qq(\t%-24s => "%s",\n), $sub, $inpm{$sub};
}

print $fh <<"EOT";
);
1;
EOT


WriteMakefile(
    'NAME'		=> "Encode\::$Name",
    'VERSION_FROM'	=> "$Name.pm", # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'PM'                => $PM,
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => "$Name.pm", # retrieve abstract from module
       AUTHOR     => '& <dankogai@dan.co.jp>') : ()),
);



sub mkInCharset{
    my $file = shift;
    my $modname = basename($file); 
    $modname =~ s/\.ucm$//o; $modname =~ s/\-/_/g;
    my $subname;
    my $count = 0;
    my %hex = ();
    $| = 1;
    open my $srcfh, $file or die "$file:$!";
    while(<$srcfh>){
	if (m/^<code_set_name>\s+"([^\"]+)"/o){
	    $subname =  ucfirst($1);
	    $subname =~ s/\b([a-z])/uc($1)/gie;
	    $subname =~ s/-raw$//io;
	    $subname =~ /Adobe|Mac|Next|Johab|Symbol|Dingbats|Roman/io 
		or $subname = uc($subname);
	    $subname =~ s/SHIFTJIS/Shift_JIS/o;
	    $subname =~ s/-/_/g; 
	    $subname = 'In' . $subname;
	    print "Making $modname => $subname...";
	    next;
	}
	m/^<U([0-9A-Za-z]+)>/o or next;
	$subname or die "Can't find code_set_name for $file!";
	$hex{hex($1)}++; $count++;
    }
    my @range; 
    my $start = -1;  my $oldord = -1;
    for my $ord (sort { $a <=> $b } keys %hex){
	if ($start < 0){
	    $start = $oldord = $ord;
	    next;
	}
	unless ($oldord + 1 == $ord){
	    my $range = $start == $oldord ? 
		sprintf("%X", $start) : 
		sprintf("%X\t%X", $start, $oldord);
	    push @range, $range;
	    $start = $ord;
	}
	$oldord = $ord;
    }
    my $range = $start == $oldord ? 
	sprintf("%X", $start) : 
	sprintf("%X\t%X", $start, $oldord);
    push @range, $range;
    printf "$count chars, %d ranges\n", scalar @range;
    -d "InCharset" or mkdir "InCharset", 0755 or die "InCharset:$!";
    my $dstfile = File::Spec->catdir("InCharset", "$modname.pm");
    open my $dstfh, ">$dstfile" or die "$!";
    print $dstfh
	join("\n" =>
	     qq/# This is auto-generated.  Do not edit by hand!/,
	     qq/package Encode::InCharset::$modname;/,
             q[our $VERSION = do {my @r = (q$Revision: 0.1 $ =~ /\d+/g);] .
	     q[ sprintf "%d."."%02d"x$#r, @r};],
	     qq/sub $subname\{/,
	     qq/\treturn <<\'END\';/,
	     @range,
	     qq/END/,
	     qq/\}/,
	     qq/1;/,
	     qq/__END__/,
	     ), "\n";
}
