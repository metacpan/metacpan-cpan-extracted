#! perl --			-*- coding: utf-8 -*-

use utf8;

# Author          : Johan Vromans
# Created On      : Sun Jul 31 23:35:10 2005
# Last Modified By: Johan Vromans
# Last Modified On: Sat Aug  4 21:33:04 2012
# Update Count    : 438
# Status          : Unknown, Use with caution!

################ Common stuff ################

package main;

our $cfg;
our $app;
use EB::Wx::FakeApp;

package EB::Wx::Shell::Main;

use strict;
use warnings;

use EekBoek;
use EB;
use Getopt::Long 2.13;

################ The Process ################

my $app_dir;

use base qw(Wx::App);

use Wx qw[
	  wxBITMAP_TYPE_ANY
	  wxCONFIG_USE_LOCAL_FILE
	  wxDefaultPosition
	  wxDefaultSize
	  wxICON_ERROR
	  wxOK
       ];

sub OnInit {
    my( $self ) = shift;
    return 1;
}

################ Run ################

sub run {

    my ( $pkg, $opts ) = @_;
    $opts = {} unless defined $opts;

    binmode(STDOUT, ":encoding(utf8)");
    binmode(STDERR, ":encoding(utf8)");

    # Preliminary initialize config.
    EB->app_init( { app => $EekBoek::PACKAGE } );

    # Command line options.
    $opts =
      {
	#config,			# config file
	#nostdconf,			# skip standard configs
	#define,			# config overrides

	verbose	      => 0,		# verbose processing

	# Development options (not shown with -help).
	debug	     => 0,		# debugging
	trace	     => 0,		# trace (show process)
	test	     => 0,		# test mode.

	# Let supplied options override.
	%$opts,
      };

    # Process command line options.
    app_options($opts);

    # Post-processing.
    $opts->{trace} |= ($opts->{debug} || $opts->{test});

    # Initialize config.
    EB->app_init( { app => $EekBoek::PACKAGE, %$opts } );

    if ( $opts->{printconfig} ) {
	$cfg->printconf( \@ARGV );
	exit;
    }

    $app_dir = $cfg->user_dir;
    mkdir($app_dir) unless -d $app_dir;

    Wx::InitAllImageHandlers();

    #### WHAT THE ***** IS GOING ON HERE????
    #*Fcntl::O_NOINHERIT = sub() { 0 };
    #*Fcntl::O_EXLOCK = sub() { 0 };
    #*Fcntl::O_TEMPORARY = sub() { 0 };

    if ( ( defined($opts->{wizard}) ? $opts->{wizard} : 1 )
	 && !$opts->{config}
       ) {
	require EB::Wx::IniWiz;
	EB::Wx::IniWiz->run($opts); # sets $opts->{runeb}
	return unless $opts->{runeb};
	EB->app_init( { app => $EekBoek::PACKAGE, %$opts } );
    }

    my $app = EB::Wx::Shell::Main->new();
    $app->SetAppName($EekBoek::PACKAGE);
    $app->SetVendorName("Squirrel Consultancy");

    if ( $^O =~ /^mswin/i ) {
	Wx::ConfigBase::Get->SetPath("/ebwxshell");
    }
    else {
	Wx::ConfigBase::Set
	    (Wx::FileConfig->new
	     ( $app->GetAppName() ,
	       $app->GetVendorName() ,
	       $cfg->user_dir("ebwxshell"),
	       '',
	       wxCONFIG_USE_LOCAL_FILE,
	     ));
    }

    my $histfile = $cfg->user_dir("history");

    require EB::Wx::Shell::MainFrame;
    my $frame = EB::Wx::Shell::MainFrame->new
      (undef, undef, $EekBoek::PACKAGE,
       wxDefaultPosition, wxDefaultSize,
       undef,
       $EekBoek::PACKAGE);

    my $config = $opts->{config};
    unless ( $config ) {
	$config = $cfg->std_config;
	$config = $cfg->std_config_alt unless -f $config;
    }
    $frame->{_ebcfg} = $config if -e $config;
    $frame->FillHistory($histfile);
    $frame->GetPreferences;

    Wx::ConfigBase::Get->Write('general/appversion',  $EekBoek::VERSION);

    my $icon = Wx::Icon->new();
    $icon->CopyFromBitmap(Wx::Bitmap->new("eb.jpg", wxBITMAP_TYPE_ANY));
    $frame->SetIcon($icon);

    $app->SetTopWindow($frame);
    $frame->Show(1);
    $frame->RunCommand(undef);
    $app->MainLoop();
}

# Since Wx::Bitmap cannot be convinced to use a search path, we
# need a stronger method...
my $wxbitmapnew = \&Wx::Bitmap::new;
no warnings 'redefine';
*Wx::Bitmap::new = sub {
    # Only handle Wx::Bitmap->new(file, type) case.
    goto &$wxbitmapnew if @_ != 3 || -f $_[1];
    my ($self, @rest) = @_;
    $rest[0] = EB::findlib("Wx/icons/".File::Basename::basename($rest[0]));
    $wxbitmapnew->($self, @rest);
};
use warnings 'redefine';

################ Subroutines ################

sub app_options {
    my ( $opts ) = @_;

    # Filter psn arguments (Mac OSX).
    @ARGV = grep { ! /psn_\d_\d+/ } @ARGV;

    # Process options, if any.
    # Make sure defaults are set before returning!
    return unless @ARGV > 0;

    # Store valid & trap invalid option warnings
    my @optionerrors;
    local $SIG{__WARN__} = sub {
	my $warning = shift;
	push(@optionerrors, $warning);
    };

    Getopt::Long::Configure(qw(no_ignore_case));

    if ( !GetOptions( $opts,
		      'define|D=s%',
		      'nostdconf|X',
		      'config|f=s',
		      'admdir=s',
		      'open=s',
		      'wizard!',
		      'printconfig|P',
		      'ident',
		      'verbose',
		      'trace!',
		      'help|?',
		      'debug',
		    ) or $opts->{help} )
    {
	app_usage();
    }
    app_usage() if @ARGV && !$opts->{printconfig};
    app_ident() if $opts->{ident};
    return unless @optionerrors;
    my $d = Wx::MessageDialog->new ( undef,
				     join("\n", @optionerrors),
				     "Opstartregelfouten",
				     wxICON_ERROR|wxOK,
				     wxDefaultPosition );
    $d->ShowModal;
    $d->Destroy;
    CORE::exit(2);
}

sub app_ident {
    return;
    warn(__x("Dit is {pkg} [{name} {version}]",
	     pkg     => $EekBoek::PACKAGE,
	     name    => "WxShell",
	     version => $EekBoek::VERSION) . "\n");
}

sub app_usage {
    my ($exit) = @_;
    app_ident();
    warn _T(<<EndOfUsage);
Gebruik: {prog} [options] [file ...]

    --config=XXX -f     specificeer configuratiebestand
    --nostdconf -X      gebruik uitsluitend dit configuratiebestand
    --define=XXX -D     definieer configuratiesetting
    --printconfig -P	print config waarden
    --admdir=XXX	directory voor de config files
    --[no]wizard	gebruik de aanmaken/selectiewizard
    --help		deze hulpboodschap
    --ident		toon identificatie
    --verbose		geef meer uitgebreide information
EndOfUsage
    CORE::exit $exit if defined $exit && $exit != 0;
}

1;
