#!perl
package File::Glob::Windows;
use strict;
use warnings;
use utf8;
use Encode;
use DirHandle;
use Exporter;
use Carp;
use 5.005;

our $VERSION="0.1.5";

our @ISA = qw(Exporter);
our @EXPORT = qw( glob );
our @EXPORT_OK = qw( glob getCodePage getCodePage_A getCodePage_B getCodePage_POSIX);

##############################################
# find native encoding

sub getCodePage_A{
	eval "require Win32::TieRegistry"; $@ and return;
	my $key = Win32::TieRegistry->new('HKEY_LOCAL_MACHINE/SYSTEM/CurrentControlSet/Control/Nls/CodePage',{Delimiter=>"/"}) or return;
	for('Default','ACP','OEMCP'){
		my $v = $key->GetValue($_);
		return "cp$v" if defined($v) and $v=~/(\d+)/;
	}
	return;
}
sub getCodePage_B{
	eval "require Win32::API"; $@ and return;
	my $f=Win32::API->new("Kernel32", "GetACP", '', 'N') or return;
	my $v= $f->Call; $v and return "cp$v";
	return;
}

sub getCodePage_POSIX {
        require POSIX;
        my $v = POSIX::setlocale( &POSIX::LC_CTYPE );
    #~ LC_TYPE returns
    #~    English_United States.1252
    #~ which matches ...Control/Nls/CodePage
    #~    (default)=(value  not set)
    #~     ACP=1252
    #~     OEMCP=437
        return "cp$1" if defined($v) and $v=~/(\d+)$/;
        return;
}


sub getCodePage{
	for( \&getCodePage_B,\&getCodePage_A,\&getCodePage_POSIX ){
		my $cp = eval{ &$_ };
		next if $@;
		$cp and return $cp;
	}
	return;
}

##############################################

# public options
our $encoding = getCodePage();
our $sorttype = 0;
our $nocase   = 1;


our %alpha;
our %glob_sortfunc=(
	1=>sub{                       $a->[2] cmp $b->[2] }, # name order
	2=>sub{$b->[0] <=> $a->[0] or $a->[2] cmp $b->[2] }, # directory and name
	3=>sub{$a->[0] <=> $b->[0] or $a->[2] cmp $b->[2] }, # fine and name
	4=>sub{                       $b->[2] cmp $a->[2] }, # name desc
);

sub glob{
	my($path)=@_;
	# check input
	(not defined $path or $path eq '') and croak "path is not specified";
	# check encoding
	my $enc = Encode::find_encoding($encoding);
	ref($enc) or croak "encoding is not specified";

	my $sortfunc = $glob_sortfunc{$sorttype};

	# read volume and root
	utf8::is_utf8($path) or $path = Encode::decode($enc,$path);
	my $top='';
	$path =~s!^([^:]+:|\\\\[^\\]+)!! and $top .=$1;
	$path =~s!^([\\/]+)!! and $top .='\\';
	$top= Encode::encode($enc,$top);
	($path eq '') and return ($top);

	# split path and convert wildcard to regex
	my @node;
	my $re1 = Encode::encode($enc,'.*?');
	my $re2 = Encode::encode($enc,'.');
	if($nocase and not %alpha){ $alpha{$_}=1 for 'A'..'Z','a'..'z';}
	for my $t (split m![\\/]+!,$path){
		next if $t eq '';
		if( not $t =~ /[*?]/ ){ push @node,Encode::encode($enc,$t); next; }
		my $r='';
		if($nocase){
			for(split /([*?A-Za-z])/,$t){
				next if $_ eq '';
				   if($_ eq '*'  ){ $r.=$re1 }
				elsif($_ eq '?'  ){ $r.=$re2 }
				elsif($alpha{$_} ){ $r.=Encode::encode($enc,'['.uc($_).lc($_).']') }
				else{ $r .= quotemeta(Encode::encode($enc,$_)) }
			}
		}else{
			for(split /([*?])/,$t){
				next if $_ eq '';
				   if($_ eq '*'  ){ $r.=$re1 }
				elsif($_ eq '?'  ){ $r.=$re2 }
				else{ $r .= quotemeta(Encode::encode($enc,$_)) }
			}
		}
		utf8::is_utf8($r) and die "bad implement. pattern is_utf8 !!\n";
		push @node,qr/^$r$/;
	}

	# directory search
	my @result;
	my @stack=([0,'']);
	while(@stack){
		my($level,$prefix)=@{shift @stack};
		if($level==-1){ push @result,$prefix; next; }
		my($replace,$separator,$parent,$spec) = (0,'\\',$top.$prefix,$node[$level++]);
		if($parent eq '' ){ ($parent,$replace)=('.',1); }
		elsif(length($top) and not length($prefix) ){ $separator =''; }

		my @list;
		if(ref $spec){
			my $d = new DirHandle($parent) or next;
			while(defined( $_=$d->read )){
				next if not $_ =~ $spec;
				my $path = ($replace?$_:"$parent$separator$_");
				   if($level==@node){ push @list,[-1,$path,$_]; }
				elsif(-d $path){ push @list,[$level,($replace?$_:"$prefix$separator$_"),$_]; }
			}
			$sortfunc and @list = sort $sortfunc @list;
			pop @$_ for @list;
			splice @stack,0,0,@list;
		}else{
			my $path = ($replace?$spec:"$parent$separator$spec");
			next if not -e $path;
			   if($level==@node){ push @result,$path; }
			elsif(-d _){ unshift @stack,[$level,($replace?$spec:"$prefix$separator$spec")]; }
		}
	}
	return @result;
}

1;

__END__

=head1 NAME

File::Glob::Windows - glob routine for Windows environment.

=head1 SYNOPSIS

  use File::Glob::Windows;
  
  @list = glob($path);
  
  {
      local $File::Glob::Windows::encoding = getCodePage();
      local $File::Glob::Windows::sorttype = 0;
      local $File::Glob::Windows::nocase   = 1;
      @list = glob($path);
  }

=head1 DESCRIPTION

This glob routines works correctly on Windows environment.

=over

=item

Recognize system's current codepage such as 'cp932',
It's multibyte character contains '\\' and '/' and '*' and '?' in second byte.


=item

Correctly handles current drive and currend cirectory.
MS-DOS derived environments has current directory for each drive. 
current working directory means current directory on current drive.
'G:' means 'G:.' , not 'G:\'.

=item

It differs from perlglob.exe, this glob can include the wild-card specification also in the middle part of path.

=back

=head1 INSTALL

 perl Makefile.PL
 nmake
 nmake test
 nmake install

Notice: If you have no B<make>, and also your OS is 32bit Windows, automatically old B<nmake.exe> is downloaded from site of Microsoft, 
http://download.microsoft.com/download/vc15/Patch/1.52/W95/EN-US/Nmake15.exe or ftp://ftp.microsoft.com/Softlib/MSLFILES/Nmake15.exe
to same path of perl. You can check nmake install path by:

 perl -e "print $^X"

Notice: If your Windows OS is 64bit, you may get nmake.exe manually.
please find "Windows® Server 2003 SP1 Platform SDK" and also "PSDK-amd64.exe".

=head1 FUNCTIONS

=head2 glob( $path [,$enc [,\%options]);

This function returns array of path that matches to specified I<$path>.


Third argument is reference of hash that indicate glob option.

=head3 meta characters in path spec

 *   Match any string of characters
 ?   Match any single character

=head2 getCodePage()

This function detect current ANSI Codepage and returrns string such as "cpNNNNNN";

=head2 getCodePage_A(), getCodePage_B(),getCodePage_POSIX()

These functions are different implement to get current codepage.

=head1 OPTIONS

=head3 $File::Glob::Windows::encoding

Encoding of current codepage of OS.

=head3 $File::Glob::Windows::sorttype

=over 

=item

B<1>: sort by name.

=item

B<2>: sort by directory,name

=item

B<3>: sort by file,name

=item

B<4>: sort by name descent.

=item

B<other>: no sort

=back

=head3 $File::Glob::Windows::nocase

=over

=item

B<0>: case sensitive

=item

B<1>: ignore case

=back

default is 1.

=head1 SEE ALSO

perlglob, L<File::DosGlob>, L<File::Glob>

=head1 AUTHOR

tateisu <tateisu@gmail.com>

=cut
