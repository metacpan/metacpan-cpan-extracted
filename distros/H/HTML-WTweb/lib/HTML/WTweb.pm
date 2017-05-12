package HTML::WTweb;

# WAYCALL TOOL web
# 20043112
# Gm Gamboni
#


use strict;
use vars qw($VERSION);
$VERSION = 0.01;

sub new{
	my $self = shift;
	my $class = ref($self) || $self;

 	my %VARS = ();	
	
	my $this = {}; 
	
	$this->{DEBUG} = 0; # 0 debug off != 0 debug on 
	$this->{HTMLDIR};
	$this->{HYPER_PTR};
	$this->{F_POS};	



	bless $this, $class;
	return $this;
}


sub processhtml{
	my $this   = shift;
	my %params = @_;
	
 	my $fname = $params{'FileName'};
	my $prhdr = $params{'Header'};
	if($fname){
		delete ($params{'FileName'});	
		}else{
			die "No filename Given\n";
	}
	if($prhdr){
		print "Content-Type: text/html\n\n";
		delete($params{'Header'});
	}
	$this->{F_POS} = $this->fileseek($fname);
	my $alen = $this->{HYPER_PTR};
	my $acpy = @$alen[$this->{F_POS}];
	my $ac;
	my @ary;
	foreach my $lc(@$acpy){ push(@ary, $lc)};
	shift(@ary);
	foreach $ac(@ary){
		while((my $key, my $value) = each(%params)){
			$ac =~ s/$key/$value/g;
		}
		print $ac;
	}
}

sub fileseek{
  	my $this = shift;		
	my $fts  = shift;	
	my $cnt = 0;
	my $alen = $this->{HYPER_PTR};
	foreach my $ar(@$alen){
		return $cnt if(@$ar[0] =~ /$fts/);
		$cnt++
	}		
	return -1;
}

sub sethtmldir{
	my $this= shift;
	my $dir = shift;
	
	# Debug - expression validate input
		
	$this->{HTMLDIR} = $dir;
	return 1;
}

sub fileload{
	my $this = shift;
	my @filenames = @_;
	return -1 unless @filenames;
	my($cnt,@HYPER);
	foreach my $file(@filenames){
		open(FH, "<$this->{HTMLDIR}/$file")or return 0;
		my @lines = <FH>;
		close FH;
		unshift(@lines, $file);
		$HYPER[$cnt] = \@lines,
		$cnt++; 
	}
	$this->{HYPER_PTR}= \@HYPER;
	return 1;
}

# NOT IMPLEMENTED YET #

sub prv_parse{
	my @line = @_;
	print "INIT--------------------\n";	
	foreach my $l(@line){
		print "$l";
		if($l =~ /(_\w+_)/){
			print "Var: $1\n";
		}
	}
	print "END--------------------\n";
}



1;
__END__

=head1 NAME

HTML::WTweb - A simply and relatively efficient HTML template system.

=head1 SYNOPSIS

       use HTML::WTweb;
       my $WT = HTML::WTweb->new();
       $WT->sethtmldir("./html");
       $WT->fileload("test1.html","test2.html");
       $WT->processhtml(FileName => "test1.html",
                        Header => 1,
                        -title => "hello universe",
                        -ptag  => "citzens of the sky");
       my @planets = ("venus", "mars", "jupiter");
       foreach my $p(@planets){
                               $WT->processhtml(FileName => "test2.html",
                                                -planet => $p);
       }
       undef $WT;

Where test1.html and test2.html are something like this:
       
       <head>
       <title>-title</title>
       </head>
       <p>here are the -ptag</p>

and
       <p>I came here from -planet</p>		

Methods:

sethtmldir: sets the directory where html template files are placed.

fileload: load one or more template from htmldir.
 
processhtml: operate the parsing, substitutions and output to stdout of the given template. 


I suggest you to use CGI module instead my poor "Header" switch to print out canonical header if you also need to retrieve form parameters from a previous post.

The directory where html templates are stored should be ./html, I haven't tried to put them elsewhere

/usr/local/apache/myweb       <- perl code

/usr/local/apache/myweb/html  <- html templates

=head1 DESCRIPTION

This module must be interpretated as a preliminary release of a more complete package suite.
Using WTweb make easy to detach the crummy html tags from the beauty of perl, in a simply and synthetic way.
It won't be the top of efficiency, but it's simply and intended to reliate headache arised from the tedious web applications.
It may also used as generic text-template system.

=head1 AUTHOR

Gian Maria Gamboni <gmg@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005 Gian Maria Gamboni - All Rights Reserved
This code is free software and you may redistribuite or modify it under the same terms as Perl itself.
