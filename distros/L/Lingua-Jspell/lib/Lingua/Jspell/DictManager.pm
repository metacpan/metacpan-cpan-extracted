package Lingua::Jspell::DictManager;

use 5.006;
use strict;
use warnings;
use Data::Dumper;
use File::Copy;
use YAML 'LoadFile';
use File::Spec::Functions;
use Lingua::Jspell;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( &toword &install_dic );

our $VERSION = '1.96';

# Preloaded methods go here.


sub install_dic{
  my %opt =(yaml => undef, name=>undef); ## irr => "name.irr"
  if(ref($_[0]) eq "HASH") {%opt = (%opt , %{shift(@_)}) } ;
  my ($aff,@dic)=@_;
  my $cpaff=1;
  if($aff =~ /^from:(.*)/){
     $aff = catfile($Lingua::Jspell::JSPELLLIB,"$1.aff") ; $cpaff=0;}
  my $ya;
  open(F,">__$$.dic") or die("Error 1: $!\n");
  for (@dic){open(G, $_) or die("Error 2($_): $!\n");
      print F <G>;
      close G;
  }
  close F;
  $ya = LoadFile($opt{yaml}) if $opt{yaml};
  my $name = $opt{name} || $ya->{META}{IDS}[0] || $dic[0];

  if($opt{hash}){ copy($opt{hash}, "__$$.hash"); }
  else { system ("jbuild __$$.dic $aff __$$.hash"); }

  if($opt{irr}){
    copy($opt{irr},catfile($Lingua::Jspell::JSPELLLIB,$opt{irr}))
       or warn ("Error 3: $!");
  }
  copy("__$$.hash",catfile($Lingua::Jspell::JSPELLLIB,"$name.hash"))
    or warn ("Error 4: $!");
  if($cpaff){
    copy($aff,       catfile($Lingua::Jspell::JSPELLLIB,"$name.aff"))
       or warn ("Error 5: $!");
  }
  if ($opt{yaml}){
     copy($opt{yaml},       catfile($Lingua::Jspell::JSPELLLIB,"$name.yaml"))
       or warn ("Error 6: $!");
     for(@{$ya->{META}{IDS}}){
        copy("__$$.hash",catfile($Lingua::Jspell::JSPELLLIB,"$_.hash"))
           or warn ("Error 7: $!");
     }
  }
  unlink("__$$.dic","__$$.hash","__$$.dic.cnt","__$$.dic.stat");
}

sub init{
  my $file = shift;
  my $self = { filename => $file };
  open F, $file or die "Cannot open file '$file': $!\n";
  while(<F>) {
    $self->{   shortcut}{$1} = $2 if (m!^#([^/]+)/([^/]+)/!);
    $self->{revshortcut}{$2} = $1 if (m!^#([^/]+)/([^/]+)/!);
  }
  close F;
  copy($file,"$file.old") or die("$! cant create $file.old\n");
  return bless($self);
}

sub toword{ _data2line(@_) }

sub modeach_word{
  my %opt =(rawfea => 0);
  my $dic = shift;
  if(ref($_[0]) eq "HASH") {%opt = (%opt , %{shift(@_)}) } ;
  my $func = shift;
  open DIC, $dic->{filename} or die("cannot open file");
  open NDIC, ">$dic->{filename}.new" or die("cannot create file $!");
  while(<DIC>) {
    if (m!^#! or m!^\s*$!){ print NDIC $_ ; next }

    chomp;
    my ($word,$class,$flags,@r) = split '/', $_;
    my @flags = ($flags)?split(//, $flags):();
    if(not $opt{rawfea}){
      my @atts;
      if ($class =~ /^\$/){ @atts = (special => $class)}
      else {
       $class =~ s/#([A-Za-z][A-Za-z0-9]*)/$dic->{shortcut}{$1} || ""/ge if $class;
       @atts = ($class)?split(/[,=]/, $class):();
      }
      my %atts;
      if (@atts % 2) {
        %atts = ();
      } else {
        %atts = @atts;
      }
      print NDIC $func->($word,\%atts,\@flags,@r) || $_;
    }
    else {
      print NDIC $func->($word,$class,\@flags,@r) || $_;
    }
    print NDIC "\n";
  }
  close DIC;
  close NDIC;
  copy("$dic->{filename}.new",$dic->{filename});
}


sub foreach_word {
  my %opt =(type => "struct");
  my $dic = shift;
  if(ref($_[0]) eq "HASH") {%opt = (%opt , %{shift(@_)}) } ;
  my $func = shift;
  open DIC, $dic->{filename} or die("cannot open file");
  while(<DIC>) {
    next if m!^#!;
    next if m!^\s*$!;
    chomp;
    my ($word,$class,$flags,@r) = split '/', $_;
    if($opt{type} eq "struct"){
      $class =~ s/#([A-Za-z][A-Za-z0-9]*)/$dic->{shortcut}{$1} || ""/ge if $class;
      my @flags = ($flags)?split(//, $flags):();
      my @atts = ($class)?split(/[,=]/, $class):();
      my %atts;
      if (@atts % 2) {
        %atts = ();
      } else {
        %atts = @atts;
      }

      $func->($word,\%atts,\@flags,@r); }
    elsif( $opt{type} eq "raw"){ $func->($_); }
  }
  close DIC;
}

sub for_this_cat_I_want_only_these_flags {
  my $dic = shift;
  my $cat = shift;
  $cat =~ s/#//g;
  my $flags = shift;
  my %flags;
  @flags{split //,$flags}=1;

  foreach_word($dic, sub {
		 my ($w,$a,$f) = @_;
		 my %fs = %flags;
		 my $ct = $cat;

		 my $this_cat = $a->{CAT} || "unknown";
		 if ($this_cat eq $ct) {
		   my $fl;
		   for $fl(@$f) {
		     unless (exists($fs{$fl})) {
		       print "$w from category '$cat' uses flag '$fl'\n";
		     }
		   }
		 }
	       });
}

sub for_this_cat_I_dont_want_these_flags {
  my $dic = shift;
  my $cat = shift;
  $cat =~ s/#//g;
  my $flags = shift;
  my %flags;
  @flags{split //,$flags}=1;

  foreach_word($dic, sub {
		 my ($w,$a,$f) = @_;
		 my %fs = %flags;
		 my $ct = $cat;

		 my $this_cat = $a->{CAT} || "unknown";
		 if ($this_cat eq $ct) {
		   my $fl;
		   for $fl(@$f) {
		     if (exists($fs{$fl})) {
		       print "$w from category '$cat' uses flag '$fl'\n";
		     }
		   }
		 }
	       });
}


sub not_categorized {
    my $dic = shift;

    open DIC, $dic->{filename} or die("Cannot open file");
    while(<DIC>) {
	chomp;
	next if /^#/;
	next if /^\s*$/;

	m{^([^/]+)/};
	my $word = $1;
	my $cat = $';
	next unless ($cat =~ m!^/!);
	print "word '$word' doesn't have a categorie\n";
    }
    close DIC;
}

sub extra_words {
  my $dic = shift;

  my %from;
  my ($r,$word,$fea,$fea1,$t);
  my $jdic = Lingua::Jspell->new("port");


  open DIC, $dic->{filename} or die("Cannot open file");
  while(<DIC>) {
    chomp;
    next if /^#/;
    next if /^\s*$/;

    m{^([^/]+)/};
    $word = $1;
    my @rads = $jdic->rad($word);
    if (@rads > 1) {
      print STDERR "." if rand > 0.99;
      for $r (@rads) {
	next if ($r eq $word);

	# for the fea from $word, get the rad==$r
	for $fea ($jdic->fea($word)) {
	  if ($fea->{rad} eq $word) {
	    for $fea1 (fea($r)) {
	      if (_same_cat($fea1->{CAT},$fea->{CAT})) {
		$from{$r} = {word=>$word, orig=>$fea1, dest=>$fea};
	      }
	    }
	  }
	}

	# $from{$r} = {word=>$word};
      }
    }
  }
  close DIC;

  for (keys %from) {
    if ($from{$from{$_}{word}}{word}) {
      print "# warning: multiple dependence\n";
      print "# \t$_ => $from{$_}{word} => $from{$from{$_}{word}}{word}\n";
      delete($from{$_});
    } else {
      print "# from $_ you can get $from{$_}{word}\n";
      print "delete_word('$from{$_}{word}')\n";
    }
  }
}

sub _same_cat {
  my ($a,$b) = @_;
  if (defined($a) && defined($b)) {
    return ($a eq $b);
  } else {
    return 0;
  }
}

# Each element should be a reference to an associative array like this:
#
# { word => 'word', flags => 'zbr', CAT => 'np', G=>'f' }
sub add_word {
	my $dict = shift;

	$dict->_add_full_line(map {
				my $word = $_->{word};
				my $flags = $_->{flags};
				my $comment = $_->{comment} || "";
				delete($_->{word});
				delete($_->{flags});
				delete($_->{comment});
				my %hash = %$_;
				my $info = join(",",map {"$_=$hash{$_}"} keys %hash);
				"$word/$info/$flags/$comment"
				 } @_);
}

sub _add_full_line {
	my $dict = shift;
    my %saw =();
    @saw{@_} = ();
	my @v;

	open DIC, $dict->{filename} or die("cannot open dictionary file");
	open NDIC, ">$dict->{filename}.new" or die("cannot open new dictionary file");
	while (<DIC>) {
		push @v,$_ and next if (/^#/);
        chomp;
		$saw{$_} = 1;
	}
	
	print NDIC join "", @v;
	print NDIC "\n\n";
	print NDIC map {/./ ? ("$_\n"):()} sort keys %saw;
	close DIC;
	close NDIC;
    copy("$dict->{filename}.new",$dict->{filename});
}

sub delete_word {
	my $dict = shift;
	my $pal=shift;
	my $t;

	open DIC, $dict->{filename} or die("cannot open dictionary file");
	open NDIC, ">$dict->{filename}.new" or die("cannot open new dictionary file");

	while (<DIC>) {
		$t = $1 if /^(.+?)\//;
		print NDIC unless ($t=~/^$pal$/);
	}
	close DIC;
	close NDIC;
    copy("$dict->{filename}.new",$dict->{filename});
}

sub add_flag {
	my $dic = shift;
	my $flag = shift;
	my %words;
	@words{@_} = 1;
	
  	$dic -> foreach_word( sub {
		 my ($w,$a,$f) = @_;
		 my %fs;
		 @fs{@$f}=1; 
		 if ($words{$w}) {
			@fs{split //, $flag}=1;;
			print _data2line($w,$a,join("",keys %fs));
		 }
		 print _data2line($w,$a,$f);
		
				});

}
#$pal=shift;
#($ac,$flag)=(shift=~/([\+\-])(.)/);
#
#while (<>) {
	#print $_ and next if ($_=~/^#/ || $_ eq "\n");
	#$_=~s#\n#/\n# unless ($_=~/.*\/.*\/.*\//);
	#($a,$b,$c,$d)=($_=~/^(.+?)\/(.*?)\/(.*?)\/(.*)/);
	#$c=~s#$flag##g if ($a=~/^$pal$/);
	#$c.=$flag if ($a=~/^$pal$/ && $ac eq "+");
	#print "$a/$b/$c/$d\n";
#}

sub _data2line { my ($word,$atts,$flags,@r) = @_;
  if(ref $atts){
     return "$word/". join(",",map { "$_=$atts->{$_}" } keys %$atts).
                 "/". join("",grep {/./} @$flags).
                 "/". join("/",@r);
  } else {
     return "$word/". $atts .
                 "/". join("",grep {/./} @$flags).
                 "/". join("/",@r);
  }
}


=head1 NAME

Lingua::Jspell::DictManager - a perl module for processing jspell dictionaries

=head1 SYNOPSIS

 use Lingua::Jspell::DictManager;

 $dict = init("dictionary file");

 $dict->foreach_word( \&func );

 $dict->for_this_cat_I_want_only_these_flags('nc', 'fp');

 $dict->add_flag("p","linha","carro",...);

 $dict->add_word({word=>'word',flags=>'zbr',CAT=>'np',G=>'f'},...)

 remflag("f.dic","p","linha","carro",...);

=head1 DESCRIPTION

=head2 C<init>

This function returns a new dictionary object to be used in future
methods. It requires a string with the dictionary file name.

=head2 C<install_dic>

 install_dic({name=>"teste"} ,"t.aff", "t.dic")
 install_dic({name=>"t"} ,"from:port", "t1.dic", "t2.dic")
 install_dic({yaml=>"t.yaml"} ,"from:port", "t1.dic", "t2.dic")
 install_dic({yaml=>"t.yaml",irr=>"f.irr"} ,"from:port", "t1.dic")

C<from:lang> is used to reuse the affix table from language C<lang> (the
file lang.aff is imported from the jspell library directory. (see jspell-dic
-dir)

  name  -- name of the dictionary
  yaml  -- yaml file with metadata
  irr   -- file with irregular terms

=head2 C<foreach_word>

This method processes all words from the dictionary using the function
passed as argument. This function is called with three arguments: the
word, a reference to an associative array with the category
information and a reference to a list of rules identifiers.

=head2 C<modeach_word>

This method processes all words from the dictionary using the function
passed as argument. This function is called with three arguments: the
word, a reference to an associative array with the category
information and a reference to a list of rules identifiers.

If the option C<< rawfea =>1 >> is selected, modeach_word receives a string 
instead of a hash reference.

 modeach_word({rawfea=>1}, sub { my($w,$cat,$flags,@com)=@_; ... })

Use the function C<toword($word,$fea,$flag,$coms)> to rebuild a new value;
if "" is return, the previous value is kept.

=head2 C<for_this_cat_I_want_only_these_flags>

This method receives a gramatical category and a string with flags. It
will print warning messages for each entry with that category and with
a flag not described in the flags string.

=head2 C<for_this_cat_I_dont_want_these_flags>

Works like the previous method, but will print warnings if any
category uses one of the specificed flags.

=head2 C<not_categorized>

This method returns a report for the entries without a category
definition.

=head2 C<extra_words>

This method tries to find redundant entries on the dictionary,
producing an ouput file to be executed and delete the redundancy.

=head2 C<add_word>

Add (one or more) word to the dictionary

 $dict->add_word({word=>'word',flags=>'zbr',CAT=>'np',G=>'f'},...)

=head2 C<delete_word>

Deletes the word passed as argument.

=head2 C<add_flag>

Adds the flags in the first argument to all words passed.

=head2 C<toword>

to format Word, features, flags and commants to jspell-dict format.
This functions is tically used em C<modeach_word>.

=head1 AUTHOR

 Alberto Simoes, E<lt>albie@alfarrabio.di.uminho.ptE<gt>

 J.Joao Almeida, E<lt>jj@di.uminho.ptE<gt>

=head1 SEE ALSO

 Lingua::Jspell(3), jspell(1)

=head1 COPYRIGHT & LICENSE

Copyright 2007-2009 Projecto Natura

This program is free software; licensed under GPL.

=cut

1;

__END__
