#!/bin/echo This is a perl module and should not be run

package Meta::Baseline::Lang::Perl;

use strict qw(vars refs subs);
use Meta::Utils::File::Path qw();
use Meta::Baseline::Aegis qw();
use Meta::Baseline::Cook qw();
use Meta::Baseline::Utils qw();
use Meta::Utils::Text::Lines qw();
use Meta::Utils::List qw();
use Meta::Utils::File::Remove qw();
use Meta::Utils::File::Move qw();
use Meta::Utils::File::Copy qw();
use Meta::Utils::File::File qw();
use Meta::Baseline::Lang qw();
use Template qw();
use Pod::Text qw();
use Pod::Html qw();
use Pod::Checker qw();
use Pod::LaTeX qw();
use Pod::Man qw();
use DB_File qw();
use Meta::Tool::Aegis qw();
use Meta::Utils::Output qw();
use Meta::Lang::Perl::Deps qw();
use Meta::Info::Author qw();
use Meta::Info::Authors qw();
use Meta::Lang::Perl::Perl qw();
use Meta::Utils::Env qw();
use Meta::Development::Module qw();
use Error qw(:try);
use Meta::Error::FileNotFound qw();

our($VERSION,@ISA);
$VERSION="0.63";
@ISA=qw(Meta::Baseline::Lang);

#sub env();
#sub c2chec($);
#sub check($$$);
#sub check_use($$$$$$);
#sub check_lint($$$$$$);
#sub check_doc($$$$$$);
#sub check_misc($$$$$$);
#sub check_mods($$$$$$);
#sub check_fl($$$$$$);
#sub check_pods($$$$$$);
#sub check_protos($$$$$$);
#sub c2deps($);
#sub get_pod($);
#sub check_list($$$);
#sub check_list_pl($$$);
#sub check_list_pm($$$);
#sub fix_runline($$$$$);
#sub docify($);

#sub c2objs($);
#sub c2manx($);
#sub c2nrfx($);
#sub c2html($);
#sub c2late($);
#sub c2txtx($);
#sub my_file($$);
#sub source_file($$);
#sub create_file($$);
#sub pod2code($);
#sub fix_pod($$$$$);
#sub fix_history($$$);
#sub fix_history_add($$$);
#sub fix_options($$$);
#sub fix_details($$$);
#sub fix_license($$$);
#sub fix_author($$$);
#sub fix_copyright($$$);
#sub fix_version($$$);
#sub fix_super($$$);
#sub fix_see($$$);
#sub fix_version_add($$$);
#sub TEST($);

#__DATA__

sub env() {
	my($vers)="5.005";
	my($plat)="linux";
	my($arch)="i386";
	my($lang)="perl5";
	my(%hash);
	my($path)="";
	my($perl)="";
	my($sear)=Meta::Baseline::Aegis::search_path_list();
	for(my($i)=0;$i<=$#$sear;$i++) {
		my($curr)=$sear->[$i];
		$path=Meta::Utils::File::Path::add_path($path,
			$curr."/perl/Meta/bin",":");
		$path=Meta::Utils::File::Path::add_path($path,
			$curr."/perl/Meta/bin/Baseline",":");
		$perl=Meta::Utils::File::Path::add_path($perl,
			$curr."/perl/lib/Meta",":");
		$perl=Meta::Utils::File::Path::add_path($perl,
			$curr."/perl/import/lib/".$lang."/".$arch."-".$plat."/".$vers,":");
		$perl=Meta::Utils::File::Path::add_path($perl,
			$curr."/perl/import/lib/".$lang,":");
		$perl=Meta::Utils::File::Path::add_path($perl,
			$curr."/perl/import/lib/".$lang."/site_perl/".$arch."-".$plat,":");
		$perl=Meta::Utils::File::Path::add_path($perl,
			$curr."/perl/import/lib/".$lang."/site_perl",":");
	}
	$hash{"PATH"}=$path;
	$hash{"PERL5LIB"}=$perl;
	return(\%hash);
}

sub c2chec($) {
	my($buil)=@_;
	my($resu)=check($buil->get_modu(),$buil->get_srcx(),$buil->get_path());
	if($resu) {
		Meta::Baseline::Utils::file_emblem($buil->get_targ());
	}
	return($resu);
}

sub check($$$) {
	my($modu,$srcx,$path)=@_;
	my($text);
	Meta::Utils::File::File::load($srcx,\$text);
	my($test)=Meta::Lang::Perl::Perl::is_test($srcx);
	my($module)=Meta::Lang::Perl::Perl::is_lib($srcx);
	my($resu)=1;
	my($cod0)=check_use($srcx,$path,$text,$test,$module,$modu);
	if(!$cod0) {
		$resu=0;
	}
#	my($cod1)=check_lint($srcx,$path,$text,$test,$module,$modu);
#	if(!$cod1) {
#		$resu=0;
#	}
	my($cod2)=check_doc($srcx,$path,$text,$test,$module,$modu);
	if(!$cod2) {
		$resu=0;
	}
	my($cod3)=check_misc($srcx,$path,$text,$test,$module,$modu);
	if(!$cod3) {
		$resu=0;
	}
	my($cod4)=check_mods($srcx,$path,$text,$test,$module,$modu);
	if(!$cod4) {
		$resu=0;
	}
	my($cod5)=check_fl($srcx,$path,$text,$test,$module,$modu);
	if(!$cod5) {
		$resu=0;
	}
	my($cod6)=check_pods($srcx,$path,$text,$test,$module,$modu);
	if(!$cod6) {
		$resu=0;
	}
	my($cod7)=check_protos($srcx,$path,$text,$test,$module,$modu);
	if(!$cod7) {
		$resu=0;
	}
	return($resu);
}

sub check_use($$$$$$) {
	my($perl,$path,$text,$test,$modu,$module)=@_;
	my(@lines)=split("\n",$text);
	my(%hash);
	for(my($i)=0;$i<=$#lines;$i++) {
		my($line)=$lines[$i];
		if($line=~/^use Meta::.* qw\(.*\);$/) {
			my($string)=($line=~/^use (.*) qw\(.*\);$/);
			if(!defined($string)) {
				throw Meta::Error::Simple("bad our use in [".$line."]");
			} else {
				$hash{$string}="defined our";
			}
		} else {
			if($line=~/^use .*;$/) {
				my($string,$qw)=($line=~/^use (.*) qw\(.*\);$/);
				#	if(!defined($string)) {
				#	throw Meta::Error::Simple("bad basic use in [".$line."]");
				#} else {
				#	$hash{$string}="defined basic";
				#}
				$hash{$string}="defined basic";
			} else {
				while(my($key,$val)=each(%hash)) {
					if($line=~/$key/) {
						$hash{$key}="used";
					}
				}
			}
		}
	}
	my($resu)=1;
	while(my($key,$val)=each(%hash)) {
		if($val eq "defined our") {
			Meta::Utils::Output::print("imported (internal) but not used [".$key."]\n");
			$resu=0;
		}
		if($val eq "defined basic") {
			if($key ne "strict" && $key ne "vars") {
				Meta::Utils::Output::print("imported (external) but not used [".$key."]\n");
				$resu=0;
			}
		}
	}
	return($resu);
}

sub check_lint($$$$$$) {
	my($perl,$path,$text,$test,$modu,$module)=@_;
	my($outt);
	my($ccod);
	if($modu) {
		$ccod=Meta::Utils::System::system_err_nodie(\$outt,"perl",["-MO=Lint","-Mstrict",$perl]);#-Mdiagnostics
	} else {
		$ccod=Meta::Utils::System::system_err_nodie(\$outt,"perl",["-MO=Lint","-Mstrict",$perl]);#-Mdiagnostics
	}
	if($ccod) {
#		Meta::Utils::Output::print("outt is [".$outt."]\n");
		my($obje)=Meta::Utils::Text::Lines->new();
		$obje->set_text($outt,"\n");
		$obje->remove_line($perl." syntax OK");
		$obje->remove_line("Undefined value assigned to typeglob at /local/tools/lib/perl5/5.6.0/i686-linux/B/Lint.pm line 291.");
		$obje->remove_line("defined(\@array) is deprecated at /local/tools/lib/perl5/site_perl/5.6.0/Expect.pm line 922.");
		$obje->remove_line("\t(Maybe you should just omit the defined()?)");
		my($fina)=$obje->get_text_fixed();
		if($fina eq "") {
				return(1);
		} else {
			Meta::Utils::Output::print($fina);
			return(0);
		}
	} else {
		Meta::Utils::Output::print($outt);
		return(0);
	}
}

sub check_doc($$$$$$) {
	my($perl,$path,$text,$test,$modu,$module)=@_;
	return(1);
}

sub check_misc($$$$$$) {
	my($perl,$path,$text,$test,$modu,$module)=@_;
	my(@array)=
	(
		"\\\ \\\n",
		"\\\n\\\n",
		"\\\n\\\ ",
		"\\\t\\\n",
		"\\\ \\\ ",
		"\\\r\\\n",
		"\\\ \\\;",
		"\\\(\\\ ",
		"\\\ \\\)",
		"\\\;\\\ ",
		"\\\ \\\;",
		"\\\=\\\ ",
		"\\\ \\\=",
		"\\\$\\\_",
		"\\\,\\\ ",
		"\\\ \\\,",
	);
	#if this is not a special file then STDOUT and STDERR mentioned are also an error.
	if($text!~m/SPECIAL STDERR FILE/) {
		push(@array,"STDOUT");
		push(@array,"STDERR");
	}
	#just get the code
	my($code)=pod2code($text);
	my($result)=1;
	my($size)=$#array+1;
	#search for illegal patterns
	for(my($i)=0;$i<$size;$i++) {
		my($curr)=$array[$i];
		if($code=~m/$curr/) {
			Meta::Utils::Output::print("[".$curr."] matched in text\n");
			$result=0;
		}
	}
	my(@must_array_pl)=
	(
		"__END__",
		"=head1 NAME",
		"=head1 COPYRIGHT",
		"=head1 LICENSE",
		"=head1 DETAILS",
		"=head1 SYNOPSIS",
		"=head1 DESCRIPTION",
		"=head1 OPTIONS",
		"=head1 BUGS",
		"=head1 AUTHOR",
		"=head1 HISTORY",
		"=head1 SEE ALSO",
		"=head1 TODO",
	);
	my(@must_array_pm)=
	(
		"__END__",
		"=head1 NAME",
		"=head1 COPYRIGHT",
		"=head1 LICENSE",
		"=head1 DETAILS",
		"=head1 SYNOPSIS",
		"=head1 DESCRIPTION",
		"=head1 FUNCTIONS",
		"=head1 FUNCTION DOCUMENTATION",
		"=head1 SUPER CLASSES",
		"=head1 BUGS",
		"=head1 AUTHOR",
		"=head1 HISTORY",
		"=head1 SEE ALSO",
		"=head1 TODO",
	);
	my($poin);
	if($modu) {
		$poin=\@must_array_pm;
	} else {
		$poin=\@must_array_pl;
	}
	#get the list of pod directives
	my($pod)=get_pod($text);
	if(!Meta::Utils::List::equa($poin,$pod)) {
		Meta::Utils::Output::print("problem with pod:\n");
		Meta::Utils::List::print(Meta::Utils::Output::get_file(),$pod);
		Meta::Utils::Output::print("pod expected:\n");
		Meta::Utils::List::print(Meta::Utils::Output::get_file(),$poin);
		$result=0;
	}
#	my($must_size)=$#must_array+1;
#	for(my($j)=0;$j<$must_size;$j++) {
#		my($curr)=$must_array[$j];
#		if($text!~$curr) {
#			Meta::Utils::Output::print("[".$curr."] not matched in text\n");
#			$result=0;
#		}
#	}

=begin COMMENT

	#this code is a regular checker behaviour which supresses messages in case
	#of good pods
	#these next line use the non OO interface and are commented
	my($checker)=Pod::Checker->new("-warnings"=>2);
	my($temp)=Meta::Utils::Utils::get_temp_file();
	my($cod2)=$checker->parse_from_file($perl,$temp);
	my($num_errors)=$checker->num_errors();
	if($num_errors>0) {
		my($text)=Meta::Utils::File::File::load($temp);
		Meta::Utils::Output::print($text);
		$result=0;
	}
	Meta::Utils::File::Remove::rm($temp);

	#this code is a non OO version of the checker
	my($temp)=Meta::Utils::Utils::get_temp_file();
	my($cod2)=Pod::Checker::podchecker($perl,$temp);
	#return code from parse_file file is no good
	#we check for errors using the API routine

=cut

	#this next piece of code is a real checker behaviour after my patch is applied
	my($checker)=Pod::Checker->new("-warnings"=>2);
	my($cod2)=$checker->parse_from_file($perl,Meta::Utils::Output::get_handle());
	my($num_errors)=$checker->num_errors();
	if($num_errors>0) {
		$result=0;
	}
	return($result);
}

sub check_mods($$$$$$) {
	my($perl,$path,$text,$test,$modu,$module)=@_;
#	if($text=~/STANDALONE SPECIAL FILE/) {
#		return(1);
#	}
	my($arra)=Meta::Lang::Perl::Perl::get_use_text($text);
	my(@must);
	if($modu) {
		push(@must,"strict");
#		push(@must,"Exporter");
#		push(@must,"vars");
	} else {
		if($test) {
			push(@must,"strict");
			push(@must,"Meta::Utils::System");
			push(@must,"Meta::Utils::Opts::Opts");
			push(@must,"Meta::Baseline::Test");
		} else {
			push(@must,"strict");
			push(@must,"Meta::Utils::System");
			push(@must,"Meta::Utils::Opts::Opts");
		}
	}
#	Meta::Utils::Output::print("arra is [".$arra."]\n");
#	Meta::Utils::Output::print("must is [".@must."]\n");
	if(Meta::Utils::List::is_prefix(\@must,$arra)) {
		return(1);
	} else {
		Meta::Utils::Output::print("usage does not comply with prefix\n");
		Meta::Utils::Output::print("your usage pattern:\n");
		Meta::Utils::List::print(Meta::Utils::Output::get_file(),$arra);
		Meta::Utils::Output::print("needed usage pattern:\n");
		Meta::Utils::List::print(Meta::Utils::Output::get_file(),\@must);
		return(0);
	}
}

sub check_fl($$$$$$) {
	my($perl,$path,$text,$test,$modu,$module)=@_;
	my(@line)=split('\n',$text);
	my($firs)=$line[0];
	my($chec);
	if($modu) {
		$chec="\#\!\/bin\/echo This is a perl module and should not be run";
	} else {
		$chec="\#\!\/usr\/bin\/env perl";
	}
	if($firs eq $chec) {
		return(1);
	} else {
		Meta::Utils::Output::print("found bad first line [".$firs."]\n");
		Meta::Utils::Output::print("first line should be [".$chec."]\n");
		return(0);
	}
}

sub check_pods($$$$$$) {
	my($perl,$path,$text,$test,$modu,$module)=@_;
	my($hash)=Meta::Lang::Perl::Perl::get_pods_new($text);
	my($resu)=1;
	# check NAME
	my($pod_name)=$hash->{"NAME"};
	my($matc);
	if($modu) {
		$matc=Meta::Lang::Perl::Perl::file_to_module($perl);
	} else {
		$matc=File::Basename::basename($perl);
	}
	if($pod_name!~/^$matc - .*\.\n$/) {
		Meta::Utils::Output::print("bad NAME pod found [".$pod_name."]\n");
		$resu=0;
	}
	# check LICENSE
	my($pod_lice)=$hash->{"LICENSE"};
	my($lice);
	Meta::Utils::File::File::load_deve("data/baseline/lice/lice.txt",\$lice);
	my($need_lice)=$lice."\n";
	if($pod_lice ne $need_lice) {
		Meta::Utils::Output::print("LICENSE pod found is [".$pod_lice."]\n");
		Meta::Utils::Output::print("and should be [".$need_lice."]\n");
		$resu=0;
	}
	# check COPYRIGHT
	my($au_module)=Meta::Development::Module->new_name("xmlx/author/author.xml");
	my($author_obje)=Meta::Info::Author->new_modu($au_module);
	my($pod_copy)=$hash->{"COPYRIGHT"};
	my($copy)=$author_obje->get_perl_copyright();
	my($need_copy)=$copy."\n";
	if($pod_copy ne $need_copy) {
		Meta::Utils::Output::print("COPYRIGHT pod found is [".$pod_copy."]\n");
		Meta::Utils::Output::print("and should be [".$need_copy."]\n");
		$resu=0;
	}
	# check AUTHOR
	my($pod_auth)=$hash->{"AUTHOR"};
	my($need_auth)=$author_obje->get_perl_source()."\n";
	if($pod_auth ne $need_auth) {
		Meta::Utils::Output::print("AUTHOR pod found is [".$pod_auth."]\n");
		Meta::Utils::Output::print("and should be [".$need_auth."]\n");
		$resu=0;
	}
	# build hash of SYNOPSIS
	my($syno)="\t".$hash->{"SYNOPSIS"};
	my($shor)=substr($syno,1,-1);
	my(@lines)=split("\n",$shor);
	for(my($i)=0;$i<=$#lines;$i++) {
		my($curr)=$lines[$i];
		if($curr!~/^\t.*$/) {
			Meta::Utils::Output::print("bad SYNOPSIS line [".$curr."]\n");
			$resu=0;
		}
	}
	# check FUNCTIONS
	my($expo)="\t".$hash->{"FUNCTIONS"};
	$expo=substr($expo,1,-1);
	my(@expo_line)=split("\n",$expo);
	for(my($i)=0;$i<=$#expo_line;$i++) {
		my($curr)=$expo_line[$i];
		if($curr!~/\t.*$/) {
			Meta::Utils::Output::print("bad FUNCTIONS line [".$curr."]\n");
			$resu=0;
		}
	}
	# get history stuff before checking things to do with history
	my($au_module)=Meta::Development::Module->new_name("xmlx/authors/authors.xml");
	my($authors)=Meta::Info::Authors->new_modu($au_module);
	my($hist_obje)=Meta::Tool::Aegis::history($module,$authors);
	# check DETAILS
	my($pod_deta)=$hash->{"DETAILS"};
	my($need_deta)="\tMANIFEST: ".File::Basename::basename($perl)."\n\tPROJECT: ".Meta::Baseline::Aegis::project()."\n\tVERSION: ".$hist_obje->perl_current()."\n\n";
	if($pod_deta ne $need_deta) {
		Meta::Utils::Output::print("DETAILS pod found is [".$pod_deta."]\n");
		Meta::Utils::Output::print("and should be [".$need_deta."]\n");
		$resu=0;
	}
	# check HISTORY
	my($pod_hist)=$hash->{"HISTORY"};
	my($need_hist)=$hist_obje->perl_pod()."\n";
	if($pod_hist ne $need_hist) {
		Meta::Utils::Output::print("HISTORY pod found is [".$pod_hist."]\n");
		Meta::Utils::Output::print("and should be [".$need_hist."]\n");
		$resu=0;
	}
	# check SEE ALSO
	my($pod_see)=$hash->{"SEE ALSO"};
	my($need_see)=Meta::Lang::Perl::Perl::get_file_pod_see($perl)."\n\n";
	if($pod_see ne $need_see) {
		Meta::Utils::Output::print("SEE ALSO pod found is [".$pod_see."]\n");
		Meta::Utils::Output::print("and should be [".$need_see."]\n");
		$resu=0;
	}
	if($modu) {
		# check the VERSION tag
		my($version)=$hist_obje->perl_current();
		if($text!~/\n\$VERSION=\"$version\";\n/) {
			Meta::Utils::Output::print("VERSION variable is wrong and should be [".$version."]\n");
			$resu=0;
		}
		# check the SUPER CLASSES tag
		my($pod_inherits)=$hash->{"SUPER CLASSES"};
		my($need_inherits)=Meta::Lang::Perl::Perl::get_file_pod_isa($perl)."\n\n";
		if($pod_inherits ne $need_inherits) {
			Meta::Utils::Output::print("SUPER CLASSES pod found is [".$pod_inherits."]\n");
			Meta::Utils::Output::print("and should be [".$need_inherits."]\n");
			$resu=0;
		}
	} else {
		# check the OPTIONS section
		my($pod_options)=$hash->{"OPTIONS"};
		my($need_options)=Meta::Utils::System::system_out_val($perl,["--pod"])."\n";
		if($pod_options ne $need_options) {
			Meta::Utils::Output::print("OPTIONS pod found is [".$pod_options."]\n");
			Meta::Utils::Output::print("and should be [".$need_options."]\n");
			$resu=0;
		}
	}
	return($resu);
}

sub check_protos($$$$$$) {
	my($perl,$path,$text,$test,$modu,$module)=@_;
	return(1);
}

sub c2deps($) {
	my($buil)=@_;
	my($deps)=Meta::Lang::Perl::Deps::c2deps($buil);
	if(defined($deps)) {
		Meta::Baseline::Cook::print_deps($deps,$buil->get_targ());
		return(1);
	} else {
		return(0);
	}
}

sub get_pod($) {
	my($text)=@_;
	my(@lines)=split('\n',$text);
	my($size)=$#lines+1;
	my(@arra);
	for(my($i)=0;$i<$size;$i++) {
		my($curr)=$lines[$i];
		if($curr=~/^=/) {
			if($curr ne "=begin COMMENT" && $curr ne "=over 4" && $curr ne "=cut" && $curr!~/^=item B/ && $curr ne "=back" && $curr ne "=head1 MAIN FUNCTION DOCUMENTATION") {
				push(@arra,$curr);
#				Meta::Utils::Output::print("pushing [".$curr."]\n");
			}
		}
		if($curr eq "__END__") {
			push(@arra,$curr);
		}
	}
	return(\@arra);
}

sub check_list($$$) {
	my($list,$verb,$stop)=@_;
	my($resu)=1;
	for(my($i)=0;$i<=$#$list;$i++) {
		my($file)=$list->[$i];
		if($verb) {
			Meta::Utils::Output::print("checking [".$file."]\n");
		}
		my($cres)=Meta::Utils::System::system("perl",["-wc",$file]);
		if($cres) {
			if($stop) {
				die("failed check of [".$file."]");
			}
		}
		$cres=Meta::Utils::Utils::bnot($cres);
		$resu=$resu && $cres;
	}
	return($resu);
}

sub check_list_pl($$$) {
	my($var1,$var2,$var3)=@_;
	check_list($var1,$var2,$var3);
}

sub check_list_pm($$$) {
	my($var1,$var2,$var3)=@_;
	check_list($var1,$var2,$var3);
}

sub fix_runline($$$$$) {
	my($demo,$verb,$line,$chec,$cstr)=@_;
	my($dirx)=Meta::Baseline::Aegis::development_directory();
	my($list)=Meta::Baseline::Aegis::change_files_list(1,1,0,1,1,1);
	$list=Meta::Utils::List::filter_prefix($list,$dirx."/perl/bin");
	$list=Meta::Utils::List::filter_suffix($list,".pl");
	my($resu)=1;
	for(my($i)=0;$i<=$#$list;$i++) {
		my($file)=$list->[$i];
		if($verb) {
			Meta::Utils::Output::print("replacing runline on file [".$file."]\n");
		}
		if(!$demo) {
			my(@arra);
			tie(@arra,"DB_File",$file,$DB_File::O_RDWR,0666,$DB_File::DB_RECNO) or throw Meta::Error::Simple("cannot tie [".$file."]");
			my($doit)=0;
			if($chec) {
				if($arra[0] eq $cstr) {
					$doit=1;
				} else {
					$doit=0;
					$resu=0;
				}
			} else {
				$doit=1;
			}
			if($doit) {
				$arra[0]=$line;
			}
			untie(@arra) || throw Meta::Error::Simple("cannot untie [".$file."]");
		}
	}
	return($resu);
}

sub docify($) {
	my($str)=@_;
	$str=lc $str;
	$str=~s/(\.\w+)/substr ($1,0,4)/ge;
	$str=~s/(\w+)/substr ($1,0,8)/ge;
	return($str);
}

sub c2objs($) {
	my($buil)=@_;
	Meta::Baseline::Utils::file_emblem($buil->get_targ());
	return(1);
}

sub c2manx($) {
	my($buil)=@_;
	#my($scod)=Meta::Utils::System::system_shell_nodie("pod2man ".$buil->get_srcx()." > ".$buil->get_targ());
	my($parser)=Pod::Man->new();
	my($scod)=$parser->parse_from_file($buil->get_srcx(),$buil->get_targ());
	return($scod);
}

sub c2nrfx($) {
	my($buil)=@_;
	Meta::Baseline::Utils::file_emblem($buil->get_targ());
	return(1);
}

sub c2html($) {
	my($buil)=@_;
	my($scod)=Pod::Html::pod2html(
		"--infile",$buil->get_srcx(),
		"--outfile",$buil->get_targ(),
		"--noindex",
		"--flush",
		"--norecurse",
		"--podroot","/",
		"--podpath",$buil->get_path()
	);
	my($fil0)="pod2htmd.x~~";
	my($fil1)="pod2htmi.x~~";
	try {
		Meta::Utils::File::Remove::rm($fil0);
		Meta::Utils::File::Remove::rm($fil1);
	}
	catch Meta::Error::FileNotFound with {
		# do nothing
	};
	return(1);
}

sub c2late($) {
	my($buil)=@_;
	my($parser)=Pod::LaTeX->new();
	my($scod)=$parser->parse_from_file($buil->get_srcx(),$buil->get_targ());
	return($scod);
#	my($file)=Meta::Utils::Utils::get_temp_file();
#	my($resu)=$file."\.tex";
#	Meta::Utils::File::Copy::copy($srcx,$file);
#	my($scod)=Meta::Utils::System::system_err_silent_nodie("pod2latex",[$file]);
#	if($scod) {
#		$scod=Meta::Utils::File::Move::mv_nodie($resu,$targ);
#		if($scod) {
#			Meta::Utils::File::Remove::rm($file);
#		} else {
#			Meta::Utils::Output::print("unable to move file [".$resu."] to [".$targ."]\n");
#			try {
#				Meta::Utils::File::Remove::rm($resu);
#			}
#			catch Meta::Error::FileNotFound with {
#				# do nothing
#			};
#		}
#	} else {
#		try {
#			Meta::Utils::File::Remove::rm($resu);
#		}
#		catch Meta::Error::FileNotFound with {
#			# do nothing
#		};
#	}
#	return($scod);
}

sub c2txtx($) {
	my($buil)=@_;
	my($parser)=Pod::Text->new();
	my($scod)=$parser->parse_from_file($buil->get_srcx(),$buil->get_targ());
	return($scod);
}

sub my_file($$) {
	my($self,$file)=@_;
#	Meta::Utils::Output::print("in here with file [".$file."]\n");
	if($file=~/^perl\/bin\/.*\.pl$/) {
		return(1);
	}
	if($file=~/^perl\/lib\/.*\.pm$/) {
		return(1);
	}
#	if($file=~/^perl\/.*\.MANIFEST$/) {
#		return(1);
#	}
	return(0);
}

sub source_file($$) {
	my($self,$file)=@_;
	my($ok)=0;
	if($file=~/^perl\/.*\.pl$/) {
		$ok=1;
	}
	if($file=~/^perl\/.*\.pm$/) {
		$ok=1;
	}
	if(!$ok) {
		throw Meta::Error::Simple("file [".$file."] is not a perl source file");
	}
}

sub create_file($$) {
	my($self,$file)=@_;
	my($tmpl);
	if($file=~/^perl\/.*\.pl$/) {
		$tmpl="aegi/tmpl/plxx.aegis";
	}
	if($file=~/^perl\/.*\.pm$/) {
		$tmpl="aegi/tmpl/pmxx.aegis";
	}
	my($dire)=File::Basename::dirname($file);
	my($base)=File::Basename::basename($file);
	my($modu)=Meta::Lang::Perl::Perl::file_to_module($file);
	my($lice);
	Meta::Utils::File::File::load_deve("data/baseline/lice/lice.txt",\$lice);
	my($module)=Meta::Development::Module->new_name("xmlx/author/author.xml");
	my($author)=Meta::Info::Author->new_modu($module);
	my($perl_copyright)=$author->get_perl_copyright();
	my($author_perl_source)=$author->get_perl_source();
	my($author_handle)=$author->get_handle();
	my($perl_init_history)="\t0.00 ".$author->get_initials()." ".Meta::Baseline::Aegis::change_description()."\n";
	my($vars)={
		"search_path",Meta::Baseline::Aegis::search_path(),
		"baseline",Meta::Baseline::Aegis::baseline(),
		"project",Meta::Baseline::Aegis::project(),
		"change",Meta::Baseline::Aegis::change(),
		"version",Meta::Baseline::Aegis::version(),
		"architecture",Meta::Baseline::Aegis::architecture(),
		"state",Meta::Baseline::Aegis::state(),
		"developer",Meta::Baseline::Aegis::developer(),
		"developer_list",Meta::Baseline::Aegis::developer_list(),
		"reviewer_list",Meta::Baseline::Aegis::reviewer_list(),
		"integrator_list",Meta::Baseline::Aegis::integrator_list(),
		"administrator_list",Meta::Baseline::Aegis::administrator_list(),
		"perl_copyright"=>$perl_copyright,
		"perl_license"=>$lice,
		"file_name"=>$file,
		"directroy"=>$dire,
		"base_name"=>$base,
		"module_name"=>$modu,
		"author_perl_source"=>$author_perl_source,
		"author_handle"=>$author_handle,
		"perl_init_history"=>$perl_init_history,
	};
	my($template)=Template->new(
		INCLUDE_PATH=>Meta::Baseline::Aegis::search_path(),
	);
	my($scod)=$template->process($tmpl,$vars,$file);
	if(!$scod) {
		throw Meta::Error::Simple("could not process template with error [".$template->error()."]");
	}
}

sub pod2code($) {
	my($text)=@_;
	my(@lines)=split('\n',$text);
	my(@code,@pode);
	my($state)="in_code";
	for(my($i)=0;$i<=$#lines;$i++) {
		my($curr)=$lines[$i];
#		Meta::Utils::Output::print("curr is [".$curr."] and state is [".$state."]\n");
		if($curr eq "=cut") {
#			Meta::Utils::Output::print("in here with curr [".$curr."]\n");
			if($state eq "in_code") {
				throw Meta::Error::Simple("cut in code?");
			} else {#in_pod
				$state="in_code";
			}
		} else {
			if($curr=~/^=/) {
				if($state eq "in_code") {
#					Meta::Utils::Output::print("changing\n");
					$state="in_pod";
				} else {#in_pod
					#pod in pod is ok.
				}
			} else {
				if($state eq "in_code") {
					push(@code,$curr);
				} else {#in_pod
					push(@pode,$curr);
				}
			}
		}
#		Meta::Utils::Output::print("end curr is [".$curr."] and state is [".$state."]\n");
	}
	return(join('\n',@code));#I can return pod here too
}

sub fix_pod($$$$$) {
	my($self,$curr,$need,$before_pod,$after_pod)=@_;
	my($text);
	Meta::Utils::File::File::load($curr,\$text);
	if($text=~m/\n=head1 $before_pod\n.*\n\n=head1 $after_pod\n/s) {
		#Meta::Utils::Output::print("doing [".$curr."]\n");
		my($new_string)="\n=head1 ".$before_pod."\n\n".$need."\n=head1 ".$after_pod."\n";
		$text=~s/\n=head1 $before_pod\n.*\n\n=head1 $after_pod\n/$new_string/s;
		Meta::Utils::File::File::save($curr,$text);
	} else {
		throw Meta::Error::Simple("cannot find POD tag [".$before_pod."] in [".$curr."]");
	}
}

sub fix_history($$$) {
	my($self,$modu,$curr)=@_;
	my($module)=Meta::Development::Module->new_name("xmlx/authors/authors.xml");
	my($authors)=Meta::Info::Authors->new_modu($module);
	my($need)=Meta::Tool::Aegis::history($modu,$authors)->perl_pod();
	my($before_pod)="HISTORY";
	my($after_pod)="SEE ALSO";
	fix_pod($self,$curr,$need,$before_pod,$after_pod);
}

sub fix_history_add($$$) {
	my($self,$modu,$curr)=@_;
	my($module)=Meta::Development::Module->new_name("xmlx/authors/authors.xml");
	my($authors)=Meta::Info::Authors->new_modu($module);
	my($need)=Meta::Tool::Aegis::history_add($modu,$authors)->perl_pod();
	my($before_pod)="HISTORY";
	my($after_pod)="SEE ALSO";
	fix_pod($self,$curr,$need,$before_pod,$after_pod);
}

sub fix_options($$$) {
	my($self,$modu,$curr)=@_;
	my($need)=Meta::Utils::System::system_out_val($curr,["--pod"]);
	my($before_pod)="OPTIONS";
	my($after_pod)="BUGS";
	fix_pod($self,$curr,$need,$before_pod,$after_pod);
}

sub fix_details($$$) {
	my($self,$modu,$curr)=@_;
	my($module)=Meta::Development::Module->new_name("xmlx/authors/authors.xml");
	my($authors)=Meta::Info::Authors->new_modu($module);
	my($hist_obje)=Meta::Tool::Aegis::history($modu,$authors);
	my($need)="\tMANIFEST: ".File::Basename::basename($curr)."\n\tPROJECT: ".Meta::Baseline::Aegis::project()."\n\tVERSION: ".$hist_obje->perl_current()."\n";
	my($before_pod)="DETAILS";
	my($after_pod)="SYNOPSIS";
	fix_pod($self,$curr,$need,$before_pod,$after_pod);
}

sub fix_details_add($$$) {
	my($self,$modu,$curr)=@_;
	my($module)=Meta::Development::Module->new_name("xmlx/authors/authors.xml");
	my($authors)=Meta::Info::Authors->new_modu($module);
	my($hist_obje)=Meta::Tool::Aegis::history_add($modu,$authors);
	my($need)="\tMANIFEST: ".File::Basename::basename($curr)."\n\tPROJECT: ".Meta::Baseline::Aegis::project()."\n\tVERSION: ".$hist_obje->perl_current()."\n";
	my($before_pod)="DETAILS";
	my($after_pod)="SYNOPSIS";
	fix_pod($self,$curr,$need,$before_pod,$after_pod);
}

sub fix_license($$$) {
	my($self,$modu,$curr)=@_;
	my($need);
	Meta::Utils::File::File::load(Meta::Baseline::Aegis::which("data/baseline/lice/lice.txt"),\$need);
	my($before_pod)="LICENSE";
	my($after_pod)="DETAILS";
	fix_pod($self,$curr,$need,$before_pod,$after_pod);
}

sub fix_author($$$) {
	my($self,$modu,$curr)=@_;
	my($module)=Meta::Development::Module->new_name("xmlx/author/author.xml");
	my($author)=Meta::Info::Author->new_modu($module);
	my($need)=$author->get_perl_source();
	my($before_pod)="AUTHOR";
	my($after_pod)="HISTORY";
	fix_pod($self,$curr,$need,$before_pod,$after_pod);
}

sub fix_copyright($$$) {
	my($self,$modu,$curr)=@_;
	my($module)=Meta::Development::Module->new_name("xmlx/author/author.xml");
	my($author)=Meta::Info::Author->new_modu($module);
	my($need)=$author->get_perl_copyright();
	my($before_pod)="COPYRIGHT";
	my($after_pod)="LICENSE";
	fix_pod($self,$curr,$need,$before_pod,$after_pod);
}

sub fix_version($$$) {
	my($self,$modu,$curr)=@_;
	my($module)=Meta::Development::Module->new_name("xmlx/authors/authors.xml");
	my($authors)=Meta::Info::Authors->new_modu($module);
	my($hist_obje)=Meta::Tool::Aegis::history($modu,$authors);
	my($version)=$hist_obje->perl_current();
	my($text);
	Meta::Utils::File::File::load($curr,\$text);
	if($text=~/\n\$VERSION=\"\d.\d\d\";\n/) {
		$text=~s/\n\$VERSION=\"\d.\d\d\";\n/\n\$VERSION=\"$version\";\n/s;
		Meta::Utils::File::File::save($curr,$text);
	} else {
		throw Meta::Error::Simple("unable to find VERSION variable");
	}
}

sub fix_super($$$) {
	my($self,$modu,$curr)=@_;
	my($need)=Meta::Lang::Perl::Perl::get_file_pod_isa($curr)."\n";
#	Meta::Utils::Output::print("need is [".$need."]\n");
	my($before_pod)="SUPER CLASSES";
	my($after_pod)="BUGS";
	fix_pod($self,$curr,$need,$before_pod,$after_pod);
}

sub fix_see($$$) {
	my($self,$modu,$curr)=@_;
	my($need)=Meta::Lang::Perl::Perl::get_file_pod_see($curr)."\n";
#	Meta::Utils::Output::print("need is [".$need."]\n");
	my($before_pod)="SEE ALSO";
	my($after_pod)="TODO";
	fix_pod($self,$curr,$need,$before_pod,$after_pod);
}

sub fix_version_add($$$) {
	my($self,$modu,$curr)=@_;
	my($module)=Meta::Development::Module->new_name("xmlx/authors/authors.xml");
	my($authors)=Meta::Info::Authors->new_modu($module);
	my($hist_obje)=Meta::Tool::Aegis::history_add($modu,$authors);
	my($version)=$hist_obje->perl_current();
	my($text);
	Meta::Utils::File::File::load($curr,\$text);
	if($text=~/\n\$VERSION=\"\d.\d\d\";\n/) {
		$text=~s/\n\$VERSION=\"\d.\d\d\";\n/\n\$VERSION=\"$version\";\n/s;
		Meta::Utils::File::File::save($curr,$text);
	} else {
		throw Meta::Error::Simple("unable to find VERSION variable");
	}
}

sub TEST($) {
	my($context)=@_;
	my($hash)=Meta::Baseline::Lang::Perl::env();
	Meta::Utils::Env::bash_cat($hash);
	return(1);
}

1;

__END__

=head1 NAME

Meta::Baseline::Lang::Perl - doing Perl specific stuff in the baseline.

=head1 COPYRIGHT

Copyright (C) 2001, 2002 Mark Veltzer;
All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111, USA.

=head1 DETAILS

	MANIFEST: Perl.pm
	PROJECT: meta
	VERSION: 0.63

=head1 SYNOPSIS

	package foo;
	use Meta::Baseline::Lang::Perl qw();
	my($resu)=Meta::Baseline::Lang::Perl::env();

=head1 DESCRIPTION

This package contains stuff specific to Perl in the baseline:
0. produce code to set Perl specific vars in the baseline.
1. check Perl files for correct Perl syntax in the baseline.
etc...

=head1 FUNCTIONS

	env()
	c2chec($)
	check($$$)
	check_use($$$$$$)
	check_lint($$$$$$)
	check_doc($$$$$$)
	check_misc($$$$$$)
	check_mods($$$$$$)
	check_fl($$$$$$)
	check_pods($$$$$$)
	check_protos($$$$$$)
	c2deps($)
	get_pod($)
	check_list($$$)
	check_list_pl($$$)
	check_list_pm($$$)
	fix_runline($$$$$)
	docify($)
	c2objs($)
	c2manx($)
	c2nrfx($)
	c2html($)
	c2late($)
	c2txtx($)
	my_file($$)
	source_file($$)
	create_file($$)
	pod2code($)
	fix_pod($$$$$)
	fix_history($$$)
	fix_history_add($$$)
	fix_options($$$)
	fix_details($$$)
	fix_details_add($$$)
	fix_license($$$)
	fix_author($$$)
	fix_copyright($$$)
	fix_version($$$)
	fix_super($$$)
	fix_version_add($$$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<env()>

This routine returns a wealth of information about the current running
perl. This includes the version, include path, compliation options and
other pieces of information. Why would you want this ? To get a proper
hash table interface to all the information instead of having to access
funny variable names to get it.

=item B<c2chec($)>

This routine checks a file for the following things:
	0. check the first line (#!/usr/bin/env perl).
	1. check every use actually used.
	2. check name of package with each part with capital.
	3. check use strict and diagnostics and exporter and loader.
	4. check documentation (check out the podchecker executable).
	5. check syntax by running the interpreter in syntax check mode.
	6. What about perl cc ? what does it do ?
	7. check for bad strings ";\n" "\t " two spaces etc..

=item B<check($$$)>

This method does the actual checking and returns the result.

=item B<check_use($$$$$$)>

This is my own module to check for "use module" which is not really in use.

=item B<check_lint($$$$$$)>

This one will run the B::Lint module and make sure that it comes up empty.
This one needs to be changed to catch the output of the command and process it.

=item B<check_doc($$$$$$)>

This method will check the documentation of an object.
This means that every method is documented and all the headers are there.
Currently it does nothing.

=item B<check_misc($$$$$$)>

This will check miscelleneous text features that we dont like in the baseline.

=item B<check_mods($$$$$$)>

This will check modules which must be used in different file types.

=item B<check_fl($$$$$$)>

This will check the first line of a perl script or module.

=item B<check_pods($$$$$$)>

This check will check the content of the pods.

=item B<check_protos($$$$$$)>

This check will check the prototypes of the pod.
It will check that each subroutine is documented according to the order of
declaration and code.

=item B<c2deps($)>

This will generate a dep file from a perl file.

=item B<get_pod($)>

This method returns all pod directives in a text.

=item B<check_list($$$)>

Check the syntax of a number of perl files.
Inputs are the list of files, be verbose or not and die or not on error.

=item B<check_list_pl($$$)>

Routine that calls check_list for all items

=item B<check_list_pm($$$)>

Routine that calls check_list for all items

=item B<fix_runline($$$$$)>

This routine changes the runline in all perl scripts in the baseline.
This script receives:
0. demo - whether to actually change or just demo.
1. verb - whether to be verbose or not.
2. line - which line to plant in all the perl scripts.
3. chec - whether to do a check that the current runline in the scripts is
	something.
4. cstr - what is the check string to check against.

=item B<docify($)>

This method is here because I needed it for the html conversion but eventualy
didnt use it. Try to use it in the future.

=item B<c2objs($)>

This methos will compile perl to bytecode.
This method returns an error code.
Currently this does nothing.

=item B<c2manx($)>

This method will generate manual pages from perl source files.
This method returns an error code.
The method is to use the Pod::Man module that knows how to
accoplish the task.

=item B<c2nrfx($)>

This method will convert perl source files into nroff output.

=item B<c2html($)>

This method will convert perl source files into html documentation.
This method returns an error code.

=item B<c2late($)>

This method will convert perl source files into latex documentation.
This method returns an error code.

=item B<c2txtx($)>

This method will convert perl source files into text documentation.
This method returns an error code.

=item B<my_file($$)>

This method will return true if the file received should be handled by this
module.

=item B<source_file($$)>

This method will return true if the file received is a source of this module.

=item B<create_file($$)>

This method will create a file template.

=item B<pod2code($)>

This method receives the text of a program and returns the code part of the
pod.

=item B<fix_pod($$$$$)>

Thie method replaces a pod content with something eles.

=item B<fix_history($$$)>

This will fix the =head1 HISTORY pod tag to reflect aegis history.

=item B<fix_history_add($$$)>

This will fix the =head1 HISTORY pod tag to reflect aegis history plus the current change.

=item B<fix_options($$$)>

This will fix the =head1 OPTIONS pod tag to reflect the actual command line usage of the
script.

=item B<fix_details($$$)>

This will fix the =head1 DETAILS pod tag to reflect current project details.

=item B<fix_details_add($$$)>

This will fix the =head1 DETAILS pod tag to reflect current project details plus the current change.

=item B<fix_license($$$)>

This will fix the LICENSE tag.

=item B<fix_author($$$)>

This will fix the AUTHOR tag.

=item B<fix_copyright($$$)>

This method fixes the COPYRIGHT tag.

=item B<fix_version($$$)>

This method fixes the $VERSION variable.

=item B<fix_super($$$)>

This method fixes the SUPPER tag.

=item B<fix_version_add($$$)>

This method fixes the $VERSION variable taking the current change into consideration.

=item B<TEST($)>

Test suite for this module.
This currently just runs the Env stuff and checks whats the output bash script.

=back

=head1 SUPER CLASSES

Meta::Baseline::Lang(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV initial code brought in
	0.01 MV Another change
	0.02 MV make quality checks on perl code
	0.03 MV more perl checks
	0.04 MV make Meta::Utils::Opts object oriented
	0.05 MV tests for Opts in every .pl
	0.06 MV fix up perl checks
	0.07 MV check that all uses have qw
	0.08 MV fix todo items look in pod documentation
	0.09 MV more on tests/more checks to perl
	0.10 MV more perl code quality
	0.11 MV silense all tests
	0.12 MV more quality testing
	0.13 MV more perl code quality
	0.14 MV more perl quality
	0.15 MV introduce docbook into the baseline
	0.16 MV fix up perl cooking a lot
	0.17 MV correct die usage
	0.18 MV fix expect.pl test
	0.19 MV more organization
	0.20 MV perl quality change
	0.21 MV perl code quality
	0.22 MV more perl quality
	0.23 MV chess and code quality
	0.24 MV more perl quality
	0.25 MV get basic Simul up and running
	0.26 MV make all papers papers
	0.27 MV perl documentation
	0.28 MV more perl quality
	0.29 MV perl qulity code
	0.30 MV more perl code quality
	0.31 MV more perl quality
	0.32 MV revision change
	0.33 MV revision for perl files and better sanity checks
	0.34 MV languages.pl test online
	0.35 MV history change
	0.36 MV web site and docbook style sheets
	0.37 MV fix up cook files
	0.38 MV enhance the perl subsystem
	0.39 MV perl 5.6.1 upgrade
	0.40 MV perl packaging
	0.41 MV BuildInfo object change
	0.42 MV more perl packaging
	0.43 MV perl packaging again
	0.44 MV PDMT
	0.45 MV md5 project
	0.46 MV database
	0.47 MV perl module versions in files
	0.48 MV movies and small fixes
	0.49 MV movie stuff
	0.50 MV graph visualization
	0.51 MV thumbnail user interface
	0.52 MV dbman package creation
	0.53 MV more thumbnail issues
	0.54 MV website construction
	0.55 MV web site automation
	0.56 MV SEE ALSO section fix
	0.57 MV put all tests in modules
	0.58 MV move tests to modules
	0.59 MV bring movie data
	0.60 MV finish papers
	0.61 MV teachers project
	0.62 MV more pdmt stuff
	0.63 MV md5 issues

=head1 SEE ALSO

DB_File(3), Error(3), Meta::Baseline::Aegis(3), Meta::Baseline::Cook(3), Meta::Baseline::Lang(3), Meta::Baseline::Utils(3), Meta::Development::Module(3), Meta::Error::FileNotFound(3), Meta::Info::Author(3), Meta::Info::Authors(3), Meta::Lang::Perl::Deps(3), Meta::Lang::Perl::Perl(3), Meta::Tool::Aegis(3), Meta::Utils::Env(3), Meta::Utils::File::Copy(3), Meta::Utils::File::File(3), Meta::Utils::File::Move(3), Meta::Utils::File::Path(3), Meta::Utils::File::Remove(3), Meta::Utils::List(3), Meta::Utils::Output(3), Meta::Utils::Text::Lines(3), Pod::Checker(3), Pod::Html(3), Pod::LaTeX(3), Pod::Man(3), Pod::Text(3), Template(3), strict(3)

=head1 TODO

-get a better version of the Pod::Text package (the current one sucks). take care of the return code to the os (it is always success now).

-remove the output file if any error occurs in the process.

-put all the conversion stuff in the perl.pm module and not here and just call it from here.

-use the B:: compiler to do what we do here and not my stupid script.

-nroff conversion currently does nothing. How do you convert pod to nroff ?

-the option causes the cache to be flushed before every activation. We use this module file by file so there should be no cache and so I dont realy think this is neccessary so I dropped it.

-On the other hand we do need to remove the cache once the pod2html is over and that is tougher since the Pod::Html module has no provisioning for that. We do this by hacking a bit and removing the cache ourselves by accessing the modules private variables which are the names of the cache files and removing them ourselves. I contancted Tom Christiasen about it and asked him for the feature.

-Another remark: The result of pod2html is undocumented but it seems that it does not return anything (I looked in the code). I asked for this feature too from Tom but its still not in. In the meantime this utility will always succeed...:)

-byte compilation currently does nothing. Do it.

-the docify routine here is also something from the html conversion.

-maybe a better check is not to activate the perl compiler but rather to do an eval on the file ?

-What about the location of this module ? are there so much location specific stuff to justify it being here ? Why is it in Meta::Baseline ? maybe it should be in Meta::Utils::Perl ?

-can we activate a perl compiler and precompile all the perl modules ?.

-c2html always returns 1 because the error code from the module seems to be no good. How can I take care of that ?

-pod2latex is used in a bad way. Why cant it just produce the output in the
	place I want it to ? change it...

-stopped using -MO=lint,all and -w in the lint processing because of errors-
	bring that back.

-maybe make a better implementation instead of using perldoc for displaying manual pages. Is there a perl class which is a pager that we could feed the output of Pod::Man to and thus do everything in Perl ?
