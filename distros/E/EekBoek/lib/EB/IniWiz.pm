#! perl --			-*- coding: utf-8 -*-

use utf8;

package main;

use strict;
use warnings;

use EekBoek;
use EB;

our $cfg;

package EB::IniWiz;

use EB;
use EB::Tools::MiniAdm;
use File::Basename;
use Encode;
use File::Glob ( $] >= 5.016 ? ":bsd_glob" : ":glob" );

my @adm_dirs;
my @adm_names;
my $default = _T("--standaard--");

sub getadm {			# STATIC
    my ( $pkg, $opts ) = @_;
    chdir($opts->{admdir});
    my %h;
    $h{$_} = 1 foreach glob( "*/" . $cfg->std_config );
    $h{$_} = 1 foreach glob( "*/" . $cfg->std_config_alt );
    my @files = keys(%h);
    foreach ( sort @files ) {
	push( @adm_dirs, dirname($_) );
    }

    my $ret = -1;

    if ( @adm_dirs ) {

	print STDERR (__x("Beschikbare administraties in {dir}:",
			  dir => $opts->{admdir}), "\n\n");
	for ( my $i = 0; $i < @adm_dirs; $i++ ) {
	    my $desc = $adm_dirs[$i];
	    if ( open( my $fd, '<:utf8', $adm_dirs[$i]."/opening.eb" ) ) {
		while ( <$fd> ) {
		    next unless /adm_naam\s+"(.+)"/;
		    $desc = $1;
		    last;
		}
		close($fd);
	    }
	    printf STDERR ("%3d: %s\n", $i+1, $desc);
	    push( @adm_names, $desc );
	}
	print STDERR ("\n");
	while ( 1 ) {
	    print STDERR (_T("Uw keuze"),
			  " <1",
			  @adm_dirs > 1 ? "..".scalar(@adm_dirs) : "",
			  _T(", of N om een nieuwe administratie aan te maken>"),
			  ": " );
	    my $ans = <STDIN>;
	    $ans = '', print STDERR "\n" unless defined $ans;
	    return unless $ans;
	    chomp($ans);
	    return -1 if lc($ans) eq 'n';
	    next unless $ans =~ /^\d+$/;
	    next unless $ans && $ans <= @adm_dirs;
	    $ret = $ans;
	    chdir( $adm_dirs[ $ret-1 ] ) || die("chdir");
	    last;
	}
    }
    return $ret;

}

sub run {
    my ( $self, $opts ) = @_;
    my $admdir = $opts->{admdir} || $cfg->val(qw(general admdir), $cfg->user_dir("admdir"));
    $admdir =~ s/\$([A-Z_]+)/$ENV{$1}/ge;
    mkdir($admdir) unless -d $admdir;
    die("No admdir $admdir: $!") unless -d $admdir;
    $opts->{admdir} = $admdir;

    my $ret = EB::IniWiz->getadm($opts);

    if ( defined $ret ) {
	$ret = EB::IniWiz->runwizard($opts) if $ret < 0;
	$opts->{runeb} = $ret >= 0;
    }
}

sub find_db_drivers {
    my %drivers;

    if ( $Cava::Packager::PACKAGED ) {
	# Trust packager.
	unless ( $Cava::Packager::PACKAGED ) {
	    # Ignored, but force packaging.
	    require EB::DB::Postgres;
	    require EB::DB::Sqlite;
	}
	return
	  { sqlite   => "SQLite",
	    postgres => "PostgreSQL",
	  };
    }

    foreach my $lib ( @INC ) {
	next unless -d "$lib/EB/DB";
	foreach my $drv ( glob("$lib/EB/DB/*.pm") ) {
	    open( my $fd, "<", $drv ) or next;
	    while ( <$fd> ) {
		if ( /sub\s+type\s*{\s*\"([^\"]+)\"\s*;?\s*}/ ) {
		    my $s = $1;
		    my $t = substr($drv,length("$lib/EB/DB/"));
		    $t =~ s/\.pm$//;
		    $drivers{lc($t)} ||= $s;
		    last;
		}
	    }
	    close($fd);
	}
    }
    \%drivers;
}

sub findchoice {
    my ( $choice, $choices ) = @_;
    $choice = lc($choice);
    my $i = 0;
    while ( $i < @$choices ) {
	return $i if lc($choices->[$i]) eq $choice;
	$i++;
    }
    return;
}

sub runwizard {
    my ( $self ) = @_;

    my $year = 1900 + (localtime(time))[5];

    my $dir = dirname( findlib( "templates.txt", "templates" ) );
    my @ebz = map { [ $_, "" ] } glob( "$dir/*.ebz" );
    my @ebz_desc = ( _T("Lege administratie") );

    my $i = 0;
    my $dp = quotemeta( _T("Omschrijving").": " );
    foreach my $ebz ( @ebz ) {
	require Archive::Zip;
	my $zip = Archive::Zip->new();
	next unless $zip->read($ebz->[0]) == 0;
	my $desc = $zip->zipfileComment;
	if ( $desc =~ /flags:\s*(.*)/i ) {
	    $ebz->[1] = $1;
	}
	if ( $desc =~ /^$dp\s*(.*)$/m ) {
	    $desc = $1;
	}
	elsif ( $desc =~ /export van (.*) aangemaakt door eekboek/i ) {
	    $desc = _T($1);
	}
	else {
	    $desc = $1 if $ebz->[0] =~ m/([^\\\/]+)\.ebz$/i;
	}
	$desc =~ s/[\n\r]+$//; # can't happen? think again...
	push( @ebz_desc, $desc);
	$i++;
    }
    unshift (@ebz, undef );	# skeleton

    # Enumerate DB drivers.
    my $drivers = find_db_drivers();
    my @db_drivers;
    foreach ( sort keys %$drivers ) {
	push( @db_drivers, $_ );
    }
    my $db_default = findchoice( "sqlite", \@db_drivers );

    my @btw = ( _T("Maand"), _T("Kwartaal"), _T("Jaar") );
    my @noyes = ( _T("Nee"), _T("Ja") );

    my $answers = {
		   admname    => _T("Mijn eerste EekBoek"),
		   begindate  => $year,
		   admbtw     => 1,
		   btwperiod  => findchoice( _T("Kwartaal"), \@btw ),
		   template   => findchoice( _T("EekBoek Voorbeeldadministratie"), \@ebz_desc ),
		   dbdriver   => $db_default,
		   dbcreate   => 1,
		  };

    $answers->{dbhost}     = $ENV{EB_DB_HOST} || $default;
    $answers->{dbport}     = $ENV{EB_DB_PORT} || $default;
    $answers->{dbuser}     = $ENV{EB_DB_USER} || $default;
    $answers->{dbpassword} = $ENV{EB_DB_PASSWORD} || "";

    $answers->{dbcr_config}   = 1;
    $answers->{dbcr_admin}    = 1;
    $answers->{dbcr_database} = 1;

    my $queries;
    $queries    = [
		   { code => "admname",
		     text => _T(<<EOD),
Geef een unieke naam voor de nieuwe administratie. Deze wordt gebruikt
voor rapporten en dergelijke.
EOD
		     type => "string",
		     prompt => _T("Naam"),
		     post => sub {
			 my $c = shift;
			 foreach ( @adm_names ) {
			     next unless lc($_) eq lc($c);
			     warn(_T("Er bestaat al een administratie met deze naam.")."\n");
			     return;
			 }
			 $c = lc($c);
			 $c =~ s/\W+/_/g;
			 $c .= "_" . $answers->{begindate},
			   $answers->{admcode} = $c;
			 return 1;
		     },
		   },
		   { code => "begindate",
		     text => _T(<<EOD),
Geef het boekjaar voor deze administratie. De administratie
begint op 1 januari van het opgegeven jaar.
EOD
		     prompt => _T("Begindatum"),
		     type => "int",
		     range => [ $year-20, $year+10 ],
		     post => sub {
			 my $c = shift;
			 return unless $answers->{admcode};
			 $answers->{admcode} =~ s/_\d\d\d\d$/_$c/;
			 return 1;
		     },
		   },
		   { code => "admcode",
		     text => _T(<<EOD),
Geef een unieke code voor de administratie. Deze wordt gebruikt als
interne naam voor de database en administratiefolders.
De standaardwaarde is afgeleid van de administratienaam en de begindatum.
EOD
		     type => "string",
		     prompt => _T("Code"),
		     pre => sub {
			 return if $answers->{admcode};
			 my $c = $answers->{admname};
			 $c = lc($c);
			 $c =~ s/\W+/_/g;
			 $c .= "_" . $answers->{begindate},
			   $answers->{admcode} = $c;
			 return 1;
		     },
		     post => sub {
			 my $c = shift;
			 foreach ( @adm_dirs ) {
			     next unless lc($_) eq lc($c);
			     warn(__x("Er bestaat al een administratie met code \"{code}\"", code => $c)."\n");
			     return;
			 }
			 return 1;
		     },
		   },
		   { code => "template",
		     text => _T(<<EOD),
U kunt een van de meegeleverde sjablonen gebruiken voor uw
administratie.
EOD
		     type => "choice",
		     prompt => _T("Sjabloon"),
		     choices => \@ebz_desc,
		     post => sub {
			 my $c = shift;
			 if ( $c == 0 ) {
			     $queries->[4]->{skip} = 0;
			     $queries->[5]->{skip} = 0;
			 }
			 elsif ( $ebz[$c]->[1] =~ /\B-btw\b/i ) {
			     $answers->{admbtw} = 0;
			     $queries->[4]->{skip} = 1;
			     $queries->[5]->{skip} = 1;
			 }
			 else {
			     $answers->{admbtw} = 1;
			     $queries->[4]->{skip} = 1;
			     $queries->[5]->{skip} = 0;
			 }
			 return 1;
		     },
		   },
		   { code => "admbtw",
		     prompt => _T("Moet BTW worden toegepast in deze administratie"),
		     type => "bool",
		     post => sub {
			 my $c = shift;
			 $queries->[5]->{skip} = !$c;
			 return 1;
		     },
		   },
		   { code => "btwperiod",
		     prompt => _T("Aangifteperiode voor de BTW"),
		     type => "choice",
		     choices => \@btw,
		   },
		   { code => "dbdriver",
		     text => _T(<<EOD),
Kies het type database dat u wilt gebruiken voor deze
administratie.
EOD
		     type => "choice",
		     prompt => _T("Database"),
		     choices => \@db_drivers,
		     post => sub {
			 my $c = shift;
			 $queries->[$_]->{skip} = $c == $db_default
			   for ( 7 .. 10 );
			 return 1;
		     }
		   },
		   { code => "dbhost",
		     prompt => _T("Database server host, indien niet lokaal"),
		     type => "string",
		     skip => 1,
		   },
		   { code => "dbport",
		     prompt => _T("Database server netwerk poort, indien niet standaard"),
		     type => "int",
		     skip => 1,
		   },
		   { code => "dbuser",
		     prompt => _T("Usernaam voor de database"),
		     type => "string",
		     skip => 1,
		   },
		   { code => "dbpassword",
		     prompt => _T("Password voor de database user"),
		     type => "string",
		     skip => 1,
		   },
		   { code => "dbcr_config",
		     prompt => _T("Moet het configuratiebestand worden aangemaakt"),
		     type => "bool",
		   },
		   { code => "dbcr_admin",
		     prompt => _T("Moeten de administratiebestanden worden aangemaakt"),
		     type => "bool",
		   },
		   { code => "dbcr_database",
		     prompt => _T("Moet de database worden aangemaakt"),
		     type => "bool",
		   },
		   { code => "dbcreate",
		     text => _T("Gereed om de bestanden aan te maken."),
		     prompt => _T("Doorgaan"),
		     type => "bool",
		   },
		  ];

  QL:
    for ( my $i = 0; $i < @$queries; $i++ ) {
	$i = 0 if $i < 0;
	my $q = $queries->[$i];
	next if $q->{skip};
	my $code = $q->{code};
	print STDERR ( "\n" );
	print STDERR ( $q->{text}, "\n" ) if $q->{text};

      QQ:
	while ( 1 ) {

	    $q->{pre}->() if $q->{pre};

	    if ( $q->{choices} ) {
		for ( my $i = 0; $i < @{ $q->{choices} }; $i++ ) {
		    printf STDERR ( "%3d: %s\n",
				    $i+1, $q->{choices}->[$i] );
		}
		print STDERR ("\n");
		$q->{range} = [ 1, scalar(@{ $q->{choices} }) ];
	    }

	    print STDERR ( $q->{prompt} );
	    print STDERR ( " <", $q->{range}->[0], "..",
			   $q->{range}->[1], ">" )
	      if $q->{range};
	    print STDERR ( " [",
			   $q->{type} eq 'choice'
			   ? $answers->{$code}+1
			   : $q->{type} eq 'bool'
			     ? $noyes[$answers->{$code}]
			     : $answers->{$code},
			   "]" )
	      if defined $answers->{$code};
	    print STDERR ( ": " );

	    my $a = decode_utf8( scalar <STDIN> );
	    $a = "-\n" unless defined $a;
	    chomp($a);
	    if ( $a eq '-' ) {
		while ( $i > 0 ) {
		    $i--;
		    redo QL unless $queries->[$i]->{skip};
		}
	    }

	    if ( $q->{type} eq 'string' ) {
		if ( $a eq '' ) {
		    $a = $answers->{$code};
		}
	    }

	    elsif ( $q->{type} eq 'bool' ) {
		if ( $a eq '' ) {
		    $a = $answers->{$code};
		}
		elsif ( $a =~ /^(ja?|ne?e?)$/i ) {
		    $a = $a =~ /^j/i ? 1 : 0;
		}
		#### FIXME
		elsif ( $a =~ /^(ye?s?|no?)$/i ) {
		    $a = $a =~ /^y/i ? 1 : 0;
		}
		else {
		    warn( _T("Antwoordt 'ja' of 'nee' a.u.b.") );
		    redo QQ;
		}
	    }

	    elsif ( $q->{type} eq 'int' || $q->{type} eq 'choice' ) {
		if ( $a eq '' ) {
		    $a = $answers->{$code};
		    $a++ if $q->{type} eq 'choice';
		}
		elsif ( $a !~ /^\d+$/
			or
			$q->{range}
			&& ( $a < $q->{range}->[0]
			     || $a > $q->{range}->[1] ) ) {
		    if ( $q->{range} ) {
			warn(__x("Ongeldig antwoord, het moet een getal tussen {first} en {last} zijn",
				 first => $q->{range}->[0],
				 last => $q->{range}->[1]) . "\n");
		    }
		    else {
			warn(_T("Ongeldig antwoord, het moet een getal zijn")."\n");
		    }
		    redo QQ;
		}
		$a-- if $q->{type} eq 'choice';
	    }

	    else {
		die("PROGRAM ERROR: Unhandled request type: ", $q->{type}, "\n");
	    }

	    if ( $q->{post} ) {
		redo QQ unless $q->{post}->($a, $answers->{$code});
	    }
	    $answers->{$code} = $a;
	    last QQ if defined $answers->{$code};
	}
    }

    return -1 unless $answers->{dbcreate};

    my %opts;

    $opts{lang} = $ENV{EB_LANG} || $ENV{LANG};
    $opts{lang} =~ s/\..*//;	# strip .utf8

    $opts{adm_naam} = $answers->{admname};
    $opts{adm_code} = $answers->{admcode};
    $opts{adm_begindatum} = $answers->{begindate};

    $opts{db_naam} = $answers->{admcode};
    $opts{db_driver} = $db_drivers[$answers->{dbdriver}];
    unless ( $answers->{dbdriver} == $db_default ) {
	$opts{db_host} = $answers->{dbhost}
	  if $answers->{dbhost} && $answers->{dbhost} ne $default;
	$opts{db_port} = $answers->{dbport}
	  if $answers->{dbport} && $answers->{dbport} ne $default;
	$opts{db_user} = $answers->{dbuser}
	  if $answers->{dbuser} && $answers->{dbuser} ne $default;
	$opts{db_password} = $answers->{dbpassword}
	  if $answers->{dbpassword} && $answers->{dbpassword} ne "";
    }
    $opts{"has_$_"} = 1
	foreach qw(debiteuren crediteuren kas bank);
    $opts{has_btw} = $answers->{admbtw};

    $opts{"create_$_"} = $answers->{dbcr_admin}
	foreach qw(schema relaties opening mutaties);
    $opts{"create_$_"} = $answers->{"dbcr_$_"}
	foreach qw(config database);

    $opts{adm_btwperiode} = @btw[ $answers->{btwperiod} ]
	if $opts{has_btw};

    $opts{template} = $ebz[ $answers->{template} ]->[0];

    if ( $opts{adm_code} ) {
	mkdir($opts{adm_code}) unless -d $opts{adm_code};
	chdir($opts{adm_code}) or die("chdir($opts{adm_code}): $!\n");;
    }

    EB::Tools::MiniAdm->sanitize(\%opts);

# warn Dumper \%opts;

    my @req = qw(config schema relaties opening mutaties database);
    my $req = @req;

    foreach my $c ( @req ) {
	if ( $c eq "database" ) {
	    next unless $opts{create_database};
	    $req--;
	    my $ret;
	    undef $cfg;
	    EB->app_init( { app => $EekBoek::PACKAGE, %opts } );
	    require EB::Main;
	    local @ARGV = qw( --init );
	    $ret = EB::Main->run;
	    die(_T("Er is een probleem opgetreden. Raadplaag uw systeembeheerder.")."\n")
	      if $ret;

	}
	else {
	    $req--;
	    my $m = "generate_". $c;
	    EB::Tools::MiniAdm->$m(\%opts);
	}
    }

    if ( $req ) {
	print STDERR ("\n", _T("De gewenste bestanden zijn aangemaakt."),
		      "\n\n");
	return -1;
    }

    print STDERR ("\n", _T("De gewenste bestanden zijn aangemaakt."),
		  " ", _T("U kunt meteen aan de slag.")."\n\n");

    return 0;
}

1;
