#! perl --			-*- coding: utf-8 -*-

use utf8;

# Author          : Johan Vromans
# Created On      : Sat Oct  8 16:40:43 2005
# Last Modified By: Johan Vromans
# Last Modified On: Tue Jan 31 12:02:01 2017
# Update Count    : 178
# Status          : Unknown, Use with caution!

package main;

our $cfg;
our $dbh;

package EB::Report::GenBase;

use strict;
use EB;

use IO::File;
use EB::Format;
use File::Glob ( $] >= 5.016 ? ":bsd_glob" : ":glob" );

sub new {
    my ($class, $opts) = @_;
    $class = ref($class) || $class;
    my $self = { %$opts };
    bless $self => $class;
}

# API.
sub _oops   { warn("?Package ".ref($_[0])." did not implement '$_[1]' method\n") }
sub start   { shift->_oops('start')   }
sub outline { shift->_oops('outline') }
sub finish  { shift->_oops('finish')  }

# Class methods

sub backend {
    my (undef, $self, $opts) = @_;

    my %extmap = ( txt => "text", htm => "html" );

    my $gen;

    # Short options, like --html.
    for ( qw(html csv text) ) {
	$gen = $_ if $opts->{$_};
    }

    # Override by explicit --gen-XXX option(s).
    foreach ( keys(%$opts) ) {
	next unless /^gen-(.*)$/;
	$gen = $1;
    }

    # Override by explicit --generate option(s).
    $gen = $opts->{generate} if $opts->{generate};

    # Infer from filename extension.
    my $t;
    if ( !defined($gen) && ($t = $opts->{output}) && $t =~ /\.([^.]+)$/ ) {
	my $ext = lc($1);
	$ext = $extmap{$ext} || $ext;
	$gen = $ext;
    }

    # Fallback to text.
    $gen ||= "text";

    # Build class and package name. Last chance to override...
    my $class = $opts->{backend} || (ref($self)||$self) . "::" . ucfirst($gen);
    my $pkg = $class;
    $pkg =~ s;::;/;g;;
    $pkg .= ".pm";

    # Try to load backend. Gives user the opportunity to override.
    eval {
	local $SIG{__WARN__};
	local $SIG{__DIE__};
	require $pkg;
    } unless $ENV{AUTOMATED_TESTING};
    if ( ! _loaded($class) ) {
	my $err = $@;
	if ( $err =~ /^can't locate /i ) {
	    $err = _T("De uitvoer-backend kon niet worden gevonden");
	}
	die("?".__x("Uitvoer in de vorm {gen} is niet mogelijk: {reason}",
		    gen => $gen, reason => $err)."\n");
    }
    my $be = $class->new($opts);

    # Handle output redirection.
    if ( $opts->{output} && $opts->{output} ne '-' ) {
	$be->{fh} = IO::File->new($opts->{output}, "w")
	  or die("?".__x("Fout tijdens aanmaken {file}: {err}",
			 file => $opts->{output}, err => $!)."\n");
    }
    elsif ( fileno(STDOUT) > 0 ) {
	# Normal file.
	$be->{fh} = IO::File->new_from_fd(fileno(STDOUT), "w");
    }
    else {
	# In-memory.
	$be->{fh} = bless \*STDOUT , 'IO::Handle';
    }
    binmode($be->{fh}, ":encoding(utf8)");

    # Handle pagesize.
    $be->{fh}->format_lines_per_page($be->{page} = defined($opts->{page}) ? $opts->{page} : 999999);

    # Get real (or fake) current date, and adjust periode end if needed.
    $be->{now} = iso8601date();
    if ( my $t = $cfg->val(qw(internal now), 0) ) {
	$be->{now} = $t if $be->{now} gt $t;
    }

    # Date/Per.
    if ( $opts->{per} ) {
	die(_T("--per sluit --periode uit")."\n") if $opts->{periode};
	die(_T("--per sluit --boekjaar uit")."\n") if defined $opts->{boekjaar};
	$be->{periode} = [ $be->{per_begin} = $dbh->adm("begin"),
			   $be->{per_end}   = $opts->{per} ];
	$be->{periodex} = 1;
    }
    elsif ( $opts->{periode} ) {
	die(_T("--periode sluit --boekjaar uit")."\n") if defined $opts->{boekjaar};
	$be->{periode}   = $opts->{periode};
	$be->{per_begin} = $opts->{periode}->[0];
	$be->{per_end}   = $opts->{periode}->[1];
	$be->{periodex}  = 2;
    }
    elsif ( defined($opts->{boekjaar}) || defined($opts->{d_boekjaar}) ) {
	my $bky = $opts->{boekjaar};
	$bky = $opts->{d_boekjaar} unless defined $bky;
	my $rr = $dbh->do("SELECT bky_begin, bky_end".
			  " FROM Boekjaren".
			  " WHERE bky_code = ?", $bky);
	die("?",__x("Onbekend boekjaar: {bky}", bky => $bky)."\n"), return unless $rr;
	my ($begin, $end) = @$rr;
	$be->{periode}  = [ $be->{per_begin} = $begin,
			    $be->{per_end}   = $end ];
	$be->{periodex} = 3;
	$be->{boekjaar} = $bky;
    }
    else {
	$be->{periode}  = [ $be->{per_begin} = $dbh->adm("begin"),
			    $be->{per_end}   = $dbh->adm("end") ];
	$be->{periodex} = 0;
    }

    if ( $be->{per_end} gt $be->{now} ) {
	warn("!".__x("Datum {per} valt na de huidige datum {now}",
		     per => datefmt_full($be->{per_end}),
		     now => datefmt_full($be->{now}))."\n")
	  if 0;
	$be->{periode}->[1] = $be->{per_end} = $be->{now}
	  if 0;
    }

    # Sanity.
    my $opendate = $dbh->do("SELECT min(bky_begin) FROM Boekjaren WHERE NOT bky_code = ?",
			    BKY_PREVIOUS)->[0];

    if ( $be->{per_begin} gt $be->{now} ) {
	die("?".__x("Periode begint {from}, dit is na de huidige datum {now}",
		    from  => datefmt_full($be->{per_begin}),
		    now   => datefmt_full($be->{now}))."\n");
    }
    if ( $be->{per_begin} lt $opendate ) {
	die("?".__x("Datum {per} valt vóór het begin van de administratie {begin}",
		    per   => datefmt_full($be->{per_begin}),
		    begin => datefmt_full($opendate))."\n");
    }
    if ( $be->{per_end} lt $opendate ) {
	die("?".__x("Datum {per} valt vóór het begin van de administratie {begin}",
		    per   => datefmt_full($be->{per_end}),
		    begin => datefmt_full($opendate))."\n");
    }

    $be->{_cssdir} = $cfg->val(qw(html cssdir), undef);
    $be->{_cssdir} =~ s;/*$;/; if defined $be->{_cssdir};
    $be->{_style} = $opts->{style} if $opts->{style};
    $be->{_title0} = $opts->{title} if $opts->{title};

    # Return instance.
    $be;
}

my %bec;

sub backend_options {
    my (undef, $self, $opts) = @_;

    my $package = ref($self) || $self;
    my $pkg = $package;
    $pkg =~ s;::;/;g;;
    return @{$bec{$pkg}} if $bec{$pkg};

    # Some standard backends may be included in the coding ...
    my %be;
    foreach my $std ( qw(text html csv) ) {
	$be{$std} = 1 if _loaded($package . "::" . ucfirst($std));
    }

    #### FIXME: options dest is uncontrollable!!!!
    #### DO NOT TRANSLATE UNTIL FIXED !!!!

    my @opts = ( __xt("cmo:report:output")."=s",
		 __xt("cmo:report:page")."=i" );

    if ( $Cava::Packager::PACKAGED ) {
	$be{wxhtml}++;
	unless ( $be{wxhtml} ) {
	    # Ignored, but forces the packager to include these modules.
	    require EB::Report::BTWAangifte::Wxhtml;
	    require EB::Report::Balres::Wxhtml;
	    require EB::Report::Debcrd::Wxhtml;
	    require EB::Report::Grootboek::Wxhtml;
	    require EB::Report::Journal::Wxhtml;
	    require EB::Report::Open::Wxhtml;
	    require EB::Report::Proof::Wxhtml;
	}
    }
    else {
	# Find files.
	foreach my $lib ( @INC ) {
	    my @files = glob("$lib/$pkg/*.pm");
	    next unless @files;
	    # warn("=> be_opt: found ", scalar(@files), " files in $lib/$pkg\n");
	    foreach ( @files ) {
		next unless m;/([^/]+)\.pm$;;
		# Actually, we should check whether the class implements the
		# GenBase API, but we can't do that without preloading all
		# backends.
		$be{lc($1)}++;
	    }
	}
    }

    # Short --XXX for known backends.
    foreach ( qw(html csv text) ) {
	push(@opts, $_) if $be{$_};
    }
    push(@opts,
	 __xt("cmo:report:style")."=s",
	 __xt("cmo:report:title|titel")."=s") if $be{html};

    # Explicit --gen-XXX for all backends.
    push(@opts, map { +"gen-$_"} keys %be);
    # Cache.
    $bec{$pkg} = [@opts];

    @opts;			# better be list context
}

# Helper.

sub _loaded {
    my $class = shift;
    no strict "refs";
    %{$class . "::"} ? 1 : 0;
}
1;
