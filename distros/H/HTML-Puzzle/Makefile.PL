use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
###########################################
# install_checker, contrib by Boris Zentner

use vars qw( %Requirements %Recommended %Example $packageName );

$packageName = 'HTML::Puzzle';

# version is the minimum version required to run

%Requirements = (
  'DBI'  => { version => 1.20 },
  'HTML::Template::Extension'  => { version => 0.11 },
  'FileHandle',
  'Data::Dumper',
);


#%Recommended = (
#  'Apache::DBI' => { comment => '(*strongly* recommended if you use DBI)' },
#  'MIME::Types' =>
#  { comment => '(needed if you want to serve static files from View/Default directory)' },
#  'XML::LibXML'  => { version => 0.92 },
#  'XML::LibXSLT' => { version => 1.04, comment => '(needed if you want to use XSLT tranformations)' },
#);
#
%Example = (
  'DBD::mysql'       => {},
);

#insert _name and _installed_version into the hash(s)
sub init {
  my $mods_ref = shift;
  for ( keys %$mods_ref ) {
    $mods_ref->{$_}{_name} = $_;
    eval {
      no strict "refs";
      ( my $fname = $_ ) =~ s!::!/!g;
      require "${fname}.pm";

      my $version = "$_" . "::VERSION";
      if ( defined $$version ){
        $mods_ref->{$_}{_installed_version} = $$version;
      } else {
        # module installed, but no $VERSION var
        $mods_ref->{$_}{_installed_version} = 0;
      }
    };
    if($@){
      unless($@ =~ m!^Can't locate \S+ in \@INC!){
        # assume module can't be loaded outside of mod_perl (e.g. Apache::DBI)
        $mods_ref->{$_}{_installed_version} = 0;
      }
    }
  }
}

sub show_versions {
  my @hrefs = @_;
  my @res   = ();
  my $len   = 0;
  for my $href (@hrefs) {
    for (keys %$href) {
      if ( defined( $href->{$_}{_installed_version} ) ) {
        $len = length if length > $len;
        push @res, $href->{$_};
      }
    }
  }

  if (@res) {
    for ( sort { $a->{_name} cmp $b->{_name} } @res ) {
      printf "  %-${len}s %6s %s\n", $_->{_name}, $_->{_installed_version}, $_->{comment} || '';
    }
  }
}

sub check_mods {
  my $title_install = shift;
  my $title_update  = shift;
  my @install       = ();
  my @update        = ();
  my $ilen = 0;
  my $ulen = 0;

  for my $href (@_) {
    for ( keys %$href ) {
      if ( !defined $href->{$_}{_installed_version} ) {
        $ilen = length if ( length > $ilen );
        push @install, $href->{$_};
      }
      elsif ( defined $href->{$_}{_installed_version} && defined $href->{$_}{version}
        && $href->{$_}{_installed_version} < $href->{$_}{version} )
      {
        $ulen = length if ( length > $ulen );
        push @update, $href->{$_};
      }
    }
  }

  if (@install) {
    print "$title_install\n";
    for ( sort { $a->{_name} cmp $b->{_name} } @install ) {
      printf "  %-${ilen}s %s\n", $_->{_name}, $_->{comment} || '';
    }
    exit;
  }

  if (@update) {
    print "$title_update\n";
    for ( sort { $a->{_name} cmp $b->{_name} } @update ) {
      printf "  %-${ulen}s (%s) to at least %s %s\n", $_->{_name}, $_->{_installed_version},
        $_->{version}, $_->{comment} || '';
    }
    exit;
  }
}

init($_) for ( \%Requirements, \%Recommended, \%Example );
my $update = 'Please update the following module(s):';
check_mods( "You need to install the following module(s) to run $packageName", $update,
    \%Requirements );
check_mods( "You should install the following module(s) to run $packageName:", $update,
    \%Recommended );
check_mods( "You need to install the following module(s) to run the $packageName examples:",
    $update, \%Example );
    
my @dbInfo 	= &_prompt_db_info;
my @fld		= qw/driver host port db user pw/;

open(F,">t/dbInfo.pl") or die "Unable to open t/dbInfo.pl";
for (my $i=0;$i<scalar(@fld);$i++) {
	print F qq/sub $fld[$i] { return '$dbInfo[$i]' }\n/;
}
print F "\n\n#return true value\n1;";
close(F);
    
sub _prompt_db_info {
	my @ret;
	my $questions=<<EOF;
Enter the DBD driver name [mysql]
Enter the database hostname [localhost]
Enter database port number [3128]
Enter database name [test]
Enter an userid which can manage tables [root]
Enter password
EOF
	my @q 		= split(/\n/,$questions);
	foreach (@q) {
		my $hidden 	= 1 if (/password/i);
		my $default = '';
		if (/.+\[(.+?)\]$/) { $default = $1 }
		push @ret,&_ask_for_prompt($_,$default,$hidden);
	}
	return @ret;
}


sub _ask_for_prompt {
	my ($question,$default)  	= (shift,shift);
	my $hidden					= shift || 0;
	print $question . ': ';
	system "stty -echo" if ($hidden);
	chomp(my $word = <STDIN>);
	if ($hidden) {print "\n"; system "stty echo";}
	return $word || $default;	
}

# end install_checker
###################################


WriteMakefile(
    'NAME'		=> $packageName,
    'AUTHOR'		=> 'Emiliano Bruni <bruni\@micso.it>',
    'VERSION_FROM'	=> 'Puzzle.pm', # finds $VERSION
#    'PREREQ_PM'		=> {
#    					Class::MethodMaker 	=> 0,
#    					URI::Escape 		=> 0,
#    					HTML::Entities 		=> 0,
#    					URI			=> 0,
#    					}, # e.g., Module::Name => 1.1
#   'PMLIBDIRS'		=> ['Encode','Decode','Ris','Ric','Gestpay'],

);

