# based on Makefile.PL from HTML::Mason

use ExtUtils::MakeMaker;
require 5.004;
require './makeconfig.pl';

#--- Installation check

sub chk_version2
{
 my($pkg,$wanted,$msg) = @_;

 local($|) = 1;
 print "Checking for $pkg" . (($wanted > 0.01) ? " v$wanted..." : "...");

 eval { my $p; ($p = $pkg . ".pm") =~ s#::#/#g; require $p; };

 my $vstr = ${"${pkg}::VERSION"} ? "found v" . ${"${pkg}::VERSION"}
				 : "not found";
 my $vnum = ${"${pkg}::VERSION"} || 0;

 print $vnum >= $wanted ? "ok\n" : "failed " . $vstr . "\n";

 if (($vnum < $wanted) && ($msg)) {
  print "             $msg\n\n";
 }

 $vnum >= $wanted;
}

my %prereqs = (
  Apache::Constants => [ 0.01, 'Apache::Constants comes with mod_perl (perl.apache.org)' ],
  Apache::Cookie    => [ 0.01, 'Apache::Cookie can be found on CPAN (search.cpan.org)' ],
  Apache::Session   => [ 1.53, 'Apache::Session can be found on CPAN (search.cpan.org)' ],
  Apache::Request   => [ 0.01, 'Apache::Request comes with mod_perl (perl.apache.org)' ],
  Apache::Util      => [ 0.01, 'Apache::Util comes with mod_perl (perl.apache.org)' ],
  Apache::File      => [ 0.01, 'Apache::File comes with mod_perl (perl.apache.org)' ],
  HTML::Mason       => [ 1.00, 'HTML::Mason can be obtained from www.masonhq.com' ],
  HTML::Parser      => [ 0.01, 'HTML::Parser can be found on CPAN (search.cpan.org)' ],
  HTML::Tagset      => [ 0.01, 'HTML::Tagset can be found on CPAN (search.cpan.org)' ],
  Image::Magick     => [ 5.28, 'Photo albums require Image::Magick; Image::Magick can be found on CPAN (search.cpan.org)'],
  Digest::MD5       => [ 0.01, 'Digest::MD5 can be found on CPAN (search.cpan.org)' ],
  MD5               => [ 0.01, 'MD5 can be found on CPAN (search.cpan.org)' ],
  MIME::Base64      => [ 0.01, 'MIME::Base64 can be found on CPAN (search.cpan.org)' ],
  Storable          => [ 0.01, 'Storable can be found on CPAN (search.cpan.org)' ],
  Data::Dumper      => [ 0.01, 'Data::Dumper can be found on CPAN (search.cpan.org)' ] 
);

my %simple_prereqs;

foreach (sort keys %prereqs) {
  chk_version2($_ => ${$prereqs{$_}}[0], ${$prereqs{$_}}[1]);

  $simple_prereq{$_} = ${$prereqs{$_}}[0];
}

my $rconf = make_config();

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'HTML::Bricks',
    'VERSION_FROM' => 'lib/HTML/Bricks.pm', # finds $VERSION
    'PREREQ_PM'    => \%simple_prereqs,
    'AUTHOR'       => 'Peter McDermott <peter@pmcdermott.com>',
    'ABSTRACT'     => 'DHTML Layout tool that enables users to build web pages without writing code',
    clean => {
	'FILES'    => 'lib/HTML/Bricks/Config.pm',
    }
);

package MY;

sub MY::install {
  package MY;
  my $self = shift;

  my $install = $self->SUPER::install(@_);

  $install =~ s/(install :: .*)$/$1 bricks_root_install www_root_install install_fin_msg/m;
  $install .= <<INSTALL;

bricks_root_install:
	\@echo Installing files in bricks_root to $$rconf{bricks_root}
	\@\$(MKPATH) $$rconf{bricks_root}
	\@\$(CP) -r bricks_root/* $$rconf{bricks_root}
	\@chown $$rconf{www_user} $$rconf{bricks_root}/data
	\@chgrp $$rconf{www_group} $$rconf{bricks_root}/data
	\@chown $$rconf{www_user} $$rconf{bricks_root}/data/*
	\@chgrp $$rconf{www_group} $$rconf{bricks_root}/data/*
	\@chown $$rconf{www_user} $$rconf{bricks_root}/data/weblog/*
	\@chgrp $$rconf{www_group} $$rconf{bricks_root}/data/weblog/*
	\@chown $$rconf{www_user} $$rconf{bricks_root}/data/weblog/bricks\\ blog/*
	\@chgrp $$rconf{www_group} $$rconf{bricks_root}/data/weblog/bricks\\ blog/*
	\@chown $$rconf{www_user} $$rconf{bricks_root}/user
	\@chgrp $$rconf{www_group} $$rconf{bricks_root}/user
	\@chown $$rconf{www_user} $$rconf{bricks_root}/user/bricks_welcome.mc
	\@chgrp $$rconf{www_group} $$rconf{bricks_root}/user/bricks_welcome.mc

www_root_install:
	\@echo Installing files in www_root to $$rconf{document_root}
	\@\$(CP) -r www_root/bricks* $$rconf{document_root}
	\@\$(CP) www_root/*jpg www_root/*.css $$rconf{document_root}
	\@\$(TEST_F) $rconf{document_root}/index.html || \$(CP) www_root/index.html $$rconf{document_root}

install_fin_msg:
	\@echo 
	\@echo Congratulations, you have successfully installed Bricks Site Builder.
	\@echo 
	\@echo You must now modify your apache configuration file as per the instructions
	\@echo in INSTALL.
	\@echo 

pack_bricks:
	\@echo Copying $$rconf{bricks_root} back to bricks_root
	\@\$(CP) -r $$rconf{bricks_root}/ bricks_root
	\@echo Copying \$(INSTALLSITELIB)/HTML/Bricks.pm to lib/HTML/Bricks.pm
	\@\$(CP) \$(INSTALLSITELIB)/HTML/Bricks.pm lib/HTML/Bricks.pm
	\@echo Copying \$(INSTALLSITELIB)/HTML/Bricks/ to lib/HTML/Bricks
	\@\$(CP) -r \$(INSTALLSITELIB)/HTML/Bricks/ lib/HTML/Bricks

INSTALL

  return $install;
}

sub test
{
    my $self = shift;

    my $test = $self->SUPER::test(@_);

    $test =~ s/(runtests \@ARGV;)/\$\$ENV{MASON_VERBOSE}=\$(TEST_VERBOSE); $1/;

    return $test;
}

sub libscan
{
    my $self = shift;
    my $file = shift;

    return $file =~ /makeconfig\.pl/ ? 0 : $self->SUPER::libscan($file);
}
