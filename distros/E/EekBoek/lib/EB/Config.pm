#! perl --			-*- coding: utf-8 -*-

use utf8;

# Config.pm -- Configuration files.
# Author          : Johan Vromans
# Created On      : Fri Jan 20 17:57:13 2006
# Last Modified By: Johan Vromans
# Last Modified On: Fri Mar 18 20:31:19 2011
# Update Count    : 251
# Status          : Unknown, Use with caution!

package main;

our $cfg;
our $dbh;

package EB::Config;

use strict;
use warnings;
use Carp;
use File::Spec;

sub init_config {
    my ($pkg, $opts) = @_;
    my $app;

    Carp::croak("Internal error -- missing package arg for __PACKAGE__\n")
	unless $app = delete $opts->{app};

    $app = lc($app);

    return if $::cfg && $app && $::cfg->{app} eq lc($app);

    # Pre-parse @ARGV for "-f configfile".
    my $extraconf = $opts->{config};
    my $skipconfig = $opts->{nostdconf};

    # Resolve extraconf to a file name. It must exist.
    if ( $extraconf ) {
	if ( -d $extraconf ) {
	    my $f = File::Spec->catfile( $extraconf,
					 EB::Config::Handler::std_config($app) );
	    if ( -e $f ) {
		$extraconf = $f;
	    }
	    else {
		$extraconf = File::Spec->catfile($extraconf,
						 EB::Config::Handler::std_config_alt($app));
	    }
	}
	die("$extraconf: $!\n") unless -f $extraconf;
    }

    # Build the list of config files.
    my @cfgs;
    if ( !$skipconfig ) {
	@cfgs = ( File::Spec->catfile( "etc", $app,
				       EB::Config::Handler::std_config($app) ),
		  EB::Config::Handler::user_dir
		    ( $app, EB::Config::Handler::std_config($app) ),
		);
	unless ( $extraconf ) {
	    push(@cfgs, EB::Config::Handler::std_config($app));
	    $cfgs[-1] = EB::Config::Handler::std_config_alt($app) unless -e $cfgs[-1];
	}
    }
    push(@cfgs, $extraconf) if $extraconf;

    # Load configs.
    my $cfg = EB::Config::Handler->new($app);
    for my $file ( @cfgs ) {
	next unless -s $file;
	$cfg->load($file);
    }

    if ( $opts->{define} ) {
	while ( my ($k, $v) = each( %{ $opts->{define} } ) ) {
	    if ( $k =~ /^(\w+(?:::\w+)*)::?(\w+)/ ) {
		$cfg->newval($1, $2, $v);
	    }
	    else {
		warn("define error: \"$k\" = \"$v\"\n");
	    }
	}
    }

    $ENV{EB_LANG} = $cfg->val('locale','lang',
                              $ENV{EB_LANG}||$ENV{LANG}||
                              ($^O =~ /^(ms)?win/i ? "nl_NL.utf8" : "nl_NL"));

    $cfg->_plug(qw(locale       lang         EB_LANG));
    $ENV{LANG} = $cfg->val(qw(locale lang));

    $cfg->_plug(qw(database     name         EB_DB_NAME));

    if ( my $db = $cfg->val(qw(database name), undef) ) {
	$db =~ s/^eekboek_//;	# legacy
	$cfg->newval(qw(database     name), $db);
	$ENV{EB_DB_NAME} = $db;
    }

    $cfg->_plug(qw(database     host         EB_DB_HOST));
    $cfg->_plug(qw(database     port         EB_DB_PORT));
    $cfg->_plug(qw(database     user         EB_DB_USER));
    $cfg->_plug(qw(database     password     EB_DB_PASSWORD));

    $cfg->_plug(qw(csv          separator    EB_CSV_SEPARATOR));

    $cfg->_plug(qw(internal     now          EB_SQL_NOW));

    $cfg->_plug("internal sql", qw(trace     EB_SQL_TRACE));
    $cfg->_plug("internal sql", qw(prepstats EB_SQL_PREP_STATS));
    $cfg->_plug("internal sql", qw(replayout EB_SQL_REP_LAYOUT));

    if ( $cfg->val(__PACKAGE__, "showfiles", 0) ) {
	warn("Config files:\n  ",
	     join( "\n  ", $cfg->files ),  "\n");
    }

    if ( $cfg->val(__PACKAGE__, "dumpcfg", 0) ) {
	use Data::Dumper;
	warn(Dumper($cfg));
    }
    $::cfg = $cfg;
}

sub import {
    my ($self, $app) = @_;
    return unless defined $app;
    die("PROGRAM ERROR: EB::Config cannot import anything");
}

package EB::Config::Handler;

# Very simple inifile handler (read-only).

sub _key {
    my ($section, $parameter) = @_;
    $section.'::'.$parameter;
}

sub val {
    my ($self, $section, $parameter, $default) = @_;
    my $res;
    $res = $self->{data}->{ _key($section, $parameter) };
    $res = $default unless defined $res;
    Carp::cluck("=> missing config: \"" . _key($section, $parameter) . "\"\n")
      unless defined $res || @_ > 3;
    $res;
}

sub newval {
    my ($self, $section, $parameter, $value) = @_;
    $self->{data}->{ _key($section, $parameter) } = $value;
}

sub setval {
    my ($self, $section, $parameter, $value) = @_;
    my $key = _key( $section, $parameter );
    Carp::cluck("=> missing config: \"$key\"\n")
      unless exists $self->{data}->{ $key };
    $self->{data}->{ $key } = $value;
}

sub _plug {
    my ($self, $section, $parameter, $env) = @_;
    $self->newval($section, $parameter, $ENV{$env})
      if $ENV{$env} && !$self->val($section, $parameter, undef);
}

sub files {
    my ($self) = @_;
    return $self->{files}->[-1] unless wantarray;
    return @{ $self->{files} };
}

sub file {
    goto &files;		# for convenience
}

sub set_file {
    my ( $self, $file ) = @_;
    if ( $self->{files}->[0] eq '<empty>' ) {
	$self->{files} = [];
    }
    push( @{ $self->{files} }, $file );
}

sub app {
    my ($self) = @_;
    $self->{app};
}

sub new {
    my ($package, $app, $file) = @_;
    my $self = bless {}, $package;
    $self->{files} = [ '<empty>' ];
    $self->{data} = {};
    $self->{app} = $app;
    $self->load($file) if defined $file;
    return $self;
}

sub load {
    my ($self, $file) = @_;

    open( my $fd, "<:encoding(utf-8)", $file )
      or Carp::croak("Error opening config $file: $!\n");

    $self->set_file($file);

    my $section = "global";
    my $fail;
    while ( <$fd> ) {
	chomp;
	next unless /\S/;
	next if /^[#;]/;
	if ( /^\s*\[\s*(.*?)\s*\]\s*$/ ) {
	    $section = lc $1;
	    next;
	}
	if ( /^\s*(.*?)\s*=\s*(.*?)\s*$/ ) {
	    $self->{data}->{ _key($section, lc($1)) } = $2;
	    next;
	}
	Carp::cluck("Error in config $file, line $.:\n$_\n");
	$fail++;
    }
    Carp::croak("Error processing config $file, aborted\n")
	if $fail;

    $self;
}

sub printconf {
    my ( $self, $list ) = @_;
    return unless @$list > 0;
    foreach my $conf ( @$list ) {
	unless ( $conf =~ /^(.+?):([^:]+)/ ) {
	    print STDOUT ("<error $conf>\n");
	    next;
	}
	my ($sec, $conf) = ($1, $2);
	$sec =~ s/:+$//;
	my $val = $self->val($sec, $conf, undef);
	print STDOUT ($val) if defined $val;
	print STDOUT ("\n");
    }
}

sub user_dir {
    my ( $app, $item ) = @_;
    {
	local $SIG{__WARN__};
	local $SIG{__DIE__};
	eval { $app = $app->app };
    }

    if ( $^O =~ /^mswin/i ) {
	my $f = File::Spec->catpath( $ENV{HOMEDRIVE}, $ENV{HOMEPATH},
				     File::Spec->catfile( $app, $item ));

	return $f;
    }
    File::Spec->catfile( glob("~"),
			 "." . lc( $app),
			 defined($item) ? $item : (),
		       );
}

sub std_config {
    my ( $app ) = @_;
    {
	local $SIG{__WARN__};
	local $SIG{__DIE__};
	eval { $app = $app->app };
    }
    lc($app) . ".conf";
}

sub std_config_alt {
    "." . &std_config;
}

1;
