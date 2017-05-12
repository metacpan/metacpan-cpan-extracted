#
# perl2html.pl
#
# version 1.00, 9-25-03, michael@bizsystems.com
#
# Functions to replace the htmlify stuff removed from perl 5.8
# Lots of stuff borrowed from perl 5.6 ExtUtils
#
use vars qw(@patch_items @patch_rv);

=pod

=head2 * pf_html_check(\%writemakefileargs)

  input:	none
  returns:	true/false

If any of the vars

	HTMLLIBPODS
	HTMLSCRIPTPODS
	INSTALLHTMLSITELIBDIR
	INST_HTMLLIBDIR

appear in the WriteMakefile hash, MakeMaker is notified
not to warn about a 'non-makefile' variable.

Certain interal arrays are set so that the functions
below work properly.

=cut

sub pf_html_check {
  my $need_patch = 0;	# SET to "1" for DEBUG
  @patch_items = qw/
	HTMLLIBPODS
	HTMLSCRIPTPODS
	INSTALLHTMLSITELIBDIR
	INST_HTMLLIBDIR
  /;
  @patch_rv;
  foreach (@patch_items) {
    my $rv = 0;
    unless (exists 
	$ExtUtils::MakeMaker::Recognized_Att_Keys{$_} &&
	$ExtUtils::MakeMaker::Recognized_Att_Keys{$_}
       ) {
    $need_patch = 1;
    $ExtUtils::MakeMaker::Recognized_Att_Keys{$_} = 1;
    $rv = 1;
    }
    push @patch_rv, $rv;
  }
  print "Restoring POD2HTML conversion features\n"
	if $need_patch;
  $need_patch;
}

=head2 * print the results for pf_html_check

This is a debug function

=cut

sub pf_print_patch_rv {
  for(0..$#patch_items) {
    print "$patch_items[$_] => $patch_rv[$_]\n";
  }
}

=head2 * $list_text = pf_handy_list(\%writemakefileargs);

Returns a text string containing the Makefile text for 

  HTMLLIBPODS
  HTMLSCRIPTPODS

=cut

sub pf_handy_list {
  my($self) = shift;
  my $rv = '';
  my %rv;
  for(qw(HTMLLIBPODS HTMLSCRIPTPODS)) {
    if ($self->{$_}) {
      $rv .= "\n$_ = ".join(" \\\n\t", sort keys %{$self->{$_}});
    }
  }
  for(qw(INSTALLHTMLSITELIBDIR INST_HTMLLIBDIR)) {
    if ($self->{$_}) {
      $rv .= "\n$_ = $self->{$_}";
    }
  }
  $rv;
}

=head2 * $inherited = pf_psias($inherited);

Insert the HTML install stuff into pure_site_install

  psias === Pure_Site_Install_After_Script

=cut

sub pf_psias {	# pure_site_install_after_script
  my $inherited = shift;
#  $inherited =~ s/(\$\(INSTALLSCRIPT\))/$1 \\\n\t\t\$\(INST_HTMLLIBDIR\) \$\(INSTALLHTMLSITELIBDIR\)/g;
  $inherited =~ s/(pure_site_install\s+::.*\n.+\n.+\n.+\n.+\n.+\n.+\n.+\n)/$1\t\t\$\(INST_HTMLLIBDIR\) \$\(INSTALLHTMLSITELIBDIR\) \\\n/;
  $inherited;
}

=head2 * pf_htmlifypods(\%makefile_hash,$Config)

Defines targets and routines to translate the pods into HTML manpages
and put them into the INST_HTMLLIBDIR and INST_HTMLSCRIPTDIR
directories.

  input:	WriteMakefile hash,
		$Config from 'use Config'

  returns:	text for MY::xxx subroutine

=cut

sub pf_htmlifypods {
    my($self, $Config) = @_;
    return "\npf_htmlifypods : pure_all\n\t\@\$(NOOP)\n" unless
	%{$self->{HTMLLIBPODS}} || %{$self->{HTMLSCRIPTPODS}};
    my $pod2html_exe = $Config->{scriptdirexp} .'/pod2html';
    my(@m);
    push @m,
qq[POD2HTML_EXE = $pod2html_exe\n],
qq[POD2HTML = \$(PERL) -we 'use File::Basename; use File::Path qw(mkpath); %m=\@ARGV;for (keys %m){' \\\n],
q[-e 'next if -e $$m{$$_} && -M $$m{$$_} < -M $$_ && -M $$m{$$_} < -M "Makefile";' \\
-e 'print "Htmlifying $$m{$$_}\n";' \\
-e '$$dir = dirname($$m{$$_}); mkpath($$dir) unless -d $$dir;' \\
-e 'system(qq[$$^X ].q["-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" $(POD2HTML_EXE) ].qq[$$_>$$m{$$_}])==0 or warn "Couldn\\047t install $$m{$$_}\n";' \\
-e 'chmod(oct($(PERM_RW))), $$m{$$_} or warn "chmod $(PERM_RW) $$m{$$_}: $$!\n";}'
];
    push @m, "\npf_htmlifypods : pure_all ";
    push @m, join " \\\n\t", keys %{$self->{HTMLLIBPODS}}, keys %{$self->{HTMLSCRIPTPODS}};

    push(@m,"\n");
    if (%{$self->{HTMLLIBPODS}} || %{$self->{HTMLSCRIPTPODS}}) {
	push @m, "\t\@\$(POD2HTML) \\\n\t";
	push @m, join " \\\n\t", %{$self->{HTMLLIBPODS}}, %{$self->{HTMLSCRIPTPODS}};
    }
    join('', @m,"\n");
}
1;
