use strict;
package Envy::Import;
use Symbol;
use Sys::Hostname;
use File::Basename;
use vars qw($CSH);

$CSH = '/bin/csh';

# I do not fully agree with the implementation of cache_shell_script
# (contributed by Tony Parent).  Once I have time to study it
# thoroughly, I may decide to change or reorganize things. XXX

sub Envy::DB::cache_shell_script { # PRIVATE
    my($o,$csh_name,$parent) = @_;
    my($host) = hostname();
    my($home_envy) = $o->{env}{HOME}."/.envy";
    my($tmpname) = "$home_envy/.".&basename($csh_name);
    
    foreach my $top (grep(s/,1$//,split(/:/,$o->{env}{&STATE}))){
	$tmpname .= "_$top";
    }
    
    $tmpname .= "_$host.env";
    
    my($uptime) = ((-x "/bin/uptime") ? `/bin/uptime` =~ /up\s+(\d+)/ : 100);
    
    my $dh    = gensym;
    if(opendir($dh,$home_envy)){
	my $dirent;
	while($dirent = readdir($dh)){
	    if ($dirent =~ /^\..*_$host.env/ and
		-M "$home_envy/$dirent" > $uptime) {
		# file is older then the time the machine has been
		# up so remove it.
		# this should keep things cleaned out to a certain extent.
		unlink("$home_envy/$dirent");
	    }
	}
    }
    
    if (-f $tmpname and -M $tmpname == -M $csh_name) {
	return &basename($tmpname,(".env"));
    }
    
    if (! -r $csh_name) {
	$o->e("Cannot read file '$csh_name'");
	return;
    }
    
    my $fh    = gensym;
    my $envyF = gensym;
    my @file;
    
    if(! -d $home_envy){
	mkdir(0755,$home_envy);
    }
    
    if(! open($envyF,">$tmpname")){
	$o->e("Cannot create temporary envy file.");
	return;
    }
    
    print $envyF "#" ."="x75 ."\n";
    print $envyF "# Dummy Envy generated for $host and \n";
    print $envyF "# $csh_name\n";
    print $envyF "#" ."="x75 ."\n\n";
    
    foreach my $top (grep(s/,1$//,split(/:/,$o->{env}{&STATE}))){
	next if($top eq $parent);
	print $envyF "require $top\n";
    }
    
    
    if(open($fh,"$CSH -fc 'source $csh_name;printenv'|")){
	@file = grep(!/^ENVY_/,<$fh>);
	close $fh;
    }else{
	$o->e("Cannot parse file '$csh_name'");
	return;
    }
    chomp(@file);
    foreach my $line (@file){
	my($var,$val) = $line =~ /^([^=]+)=(.*)/;
	next if($var eq "_");
	if(! defined $o->{env}{$var}){
	    # not defined, so just set it and go on
	    print $envyF "$var=$val\n";
	}else{
	    # OK, it's already defined, has it changed?
	    if($val ne $o->{env}{$var}){
		# OK, it's changed.
		if($o->{env}{$var} =~ $val){
		    # it's been added to.
		    my($pre,$post) = ($`,$');
		    if($pre){
			foreach my $p (reverse split(/:/,$pre)){
			    print $envyF "$val+=$p\n";
			}
		    }
		    if($post){
			foreach my $p (split(/:/,$post)){
			    print $envyF "$val=+$p\n";
			}
		    }
		}else{
		    # completely different
		    print $envyF "$var=$val\n";
		}
	    }
	}
    }
    close($envyF);
    
    $o->search_envy_path();
    &basename($tmpname,(".env"));
}

1;
