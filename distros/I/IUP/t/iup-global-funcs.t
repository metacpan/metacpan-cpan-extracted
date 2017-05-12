#!perl

BEGIN {
  if (!$ENV{DISPLAY} && $^O ne 'MSWin32' && $^O ne 'cygwin') {
    print "1..0 # skip: no display available for GUI tests\n";
    exit;
  }
}

use Test::More;
use IUP ':all';
#use Data::Dumper;

like(IUP->Version, qr/^[0-9]+(\.[0-9]+)+$/, 'IUP->Version' );
like(IUP->VersionNumber, qr/^[0-9]+$/, 'IUP->VersionNumber' );

my $l = IUP->GetLanguage;
like($l, qr/^[A-Z]+$/, 'IUP->GetLanguage (1)');
IUP->SetLanguage('FRENCH');
is(IUP->GetLanguage, 'FRENCH', 'IUP->GetLanguage (2)');
IUP->SetLanguage($l);
is(IUP->GetLanguage, $l, 'IUP->GetLanguage (3)');

#is(IUP->Help('http://www.perl.org'), 1, 'IUP->Help');

#my ($rv2, $r, $g, $b) = IUP->GetColor(10, 10, 11, 12, 13);
#diag "RV=($rv2, $r, $g, $b)";

#my ($rv3, $filename) = IUP->GetFile('d:\*.pdf');
#diag "RV=($rv3, $filename)";

#my ($rv4, $a, $b, $c) = IUP->GetParam('DlgTitle', undef, "Integer: %i{Integer Tip}\nString: %s{String Tip}\nReal 1: %r\n", 666, 'b0', 8.8);
#diag "RV=($rv4, $a, $b, $c)";

sub aaa {
  $self = shift;
  $self->TITLE('XXXXXXXXXX');
  #warn "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" . Dumper(\@_); 
}

#my ($rv5, $pboolean0, $pinteger1, $preal2, $pinteger3, $preal4, $pangle5, $pstring6, $plist7, $pfile_name8, $pcolor9, $pstring10)= IUP->GetParam("Title", \&aaa,
#	"Boolean: %b[No,Yes]{Boolean Tip}\n".
#	"Integer: %i{Integer Tip}\n".
#	"Real 1: %r{Real Tip}\n".
#	"Sep1 %t\n".
#	"Integer: %i[0,255]{Integer Tip 2}\n".
#	"Real 2: %r[-1.5,1.5]{Real Tip 2}\n".
#	"Sep2 %t\n".
#	"Angle: %a[0,360]{Angle Tip}\n".
#	"String: %s{String Tip}\n".
#	"List: %l|item1|item2|item3|{List Tip}\n".
#	"File: %f[OPEN|*.bmp;*.jpg|CURRENT|NO|NO]{File Tip}\n".
#	"Color: %c{Color Tip}\n".
#	"Sep3 %t\n".
#	"Multiline: %m{Multiline Tip}\n",
#	1,3456,3.543,192,0.5,90,"string text",2,"test.jpg","255 0 128","second text\nsecond line");	
#diag "RV=($rv5, $pboolean0, $pinteger1, $preal2, $pinteger3, $preal4, $pangle5, $pstring6, $plist7, $pfile_name8, $pcolor9, $pstring10)";

my $d = IUP::Dialog->new(name=>'xxx', TITLE=>'aa,s=s,t"x"', BGCOLOR=>'0 0 0');

#my $marks = [ 0,0,0,0,1,1,0,0 ];
#my $options = [ "Blue", "Red", "Green", "Yellow", "Black", "White", "Gray", "Brown" ];	  
#my $rv6 = IUP->ListDialog(2, "Color selection", $options,0,16,5, $marks);
#diag "RV=".Dumper($rv6).Dumper($marks);

#my @rv7 = IUP->GetAllNames();
#diag "RV=".Dumper(\@rv7);

#my @rv8 = IUP->GetAllDialogs();
#diag "RV=".Dumper(\@rv8);

#my @rv9 = IUP->GetClassAttributes("button");
#diag "RV=".Dumper(\@rv9);

my $rv10 = $d->GetAttributes();
#diag "RV=".Dumper($rv10);

my $i = -1;
$i=IUP->GetByName('xxx')->ihandle;
#diag "IH=$i";
#diag "CL=".Dumper(IUP->GetByIhandle($i));

done_testing();
