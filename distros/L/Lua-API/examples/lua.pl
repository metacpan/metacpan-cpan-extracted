#! /usr/bin/env perl

# This is a (mostly) direct translation of the lua.c driver from the
# Lua 5.1.4 distribution.  It has not been truly Perlyfied.

use strict;
use warnings;

use Lua::API;
use IO::Handle;

my $globalL;

my $progname = 'lua';

main();


##############################################################
# lua.c uses a few non-public things defined in luaconf.h
# they're emulated here.

sub LUA_QL { return "'" . shift() . "'" };

sub lua_stdin_is_tty { 1; }

{
    package Lua::API::State;
    use Term::ReadLine;

    my $term;

    INIT { $term = Term::ReadLine->new( 'lua' ); }

    sub readline {

	my ( $L, $b, $prompt ) = @_;

	my $line = $term->readline( $prompt );

	if ( defined $line )
	{
	    $$b = $line;
	    return 1;
	}

	return 0;
    }

    sub saveline {

	my ( $L, $idx ) = @_;

	if ( $L->strlen($idx) > 0 ) # non-empty line
	{
	    $term->addhistory( $L->tostring($idx) );
	}

    }

    sub freeline { }

    sub assert {}
}

##############################################################


sub lstop  {

    my ( $L, $ar) = @_;

    $L->sethook( undef, 0, 0);

    $L->error( "interrupted!");

}


sub laction {

    $SIG{'INT'} = 'DEFAULT';	     # if another SIGINT happens before lstop,
                                     # terminate process (default action)
    $globalL->sethook( lstop, Lua::API::MASKCALL | Lua::API::MASKRET | Lua::API::MASKCOUNT, 1);
}


sub print_usage {

    print STDERR
      "usage: $0 [options] [script [args]].\n",
	"Available options are:\n" .
	  "  -e stat  execute string " . LUA_QL("stat") . "\n" .
	  "  -l name  require library " . LUA_QL("name") . "\n" .
	  "  -i       enter interactive mode after executing " . LUA_QL("script") . "\n" .
	  "  -v       show version information\n" .
	  "  --       stop handling options\n" .
	  "  -        execute stdin and stop handling options\n"
	  ;

}


sub l_message  {

    my ( $pname, $msg) = @_;

    print STDERR "$pname: "
      if defined $pname;

    print STDERR "$msg\n";
}


sub  report {
    my ( $L, $status) = @_;

    if ($status && !$L->isnil(-1))
    {
	my $msg = $L->tostring(-1);
	$msg = "(error object is not a string)"
	  if ! defined $msg;
	l_message( $progname, $msg);
	$L->pop( 1);
    }
  return $status;
}


sub traceback  {

    my ( $L ) = @_;

    return 1
      if (! $L->isstring(1));	# 'message' not a string? keep it intact

    $L->getfield( Lua::API::GLOBALSINDEX, "debug");

    if (! $L->istable(-1))
    {
	$L->pop( 1);
	return 1;
    }

    $L->getfield(-1, "traceback");

    if (! $L->isfunction( -1))
    {
	$L->pop(2);
	return 1;
    }

    $L->pushvalue(1);		# pass error message
    $L->pushinteger(2);	# skip this function and traceback
    $L->call( 2, 1);		# call debug.traceback
    return 1;
}


sub  docall {
    my ( $L, $narg, $clear ) = @_;

    my $base = $L->gettop() - $narg;   # function index
    $L->pushcfunction( \&traceback );  # push traceback function
    $L->insert( $base);                # put it under chunk and args

    $SIG{'INT'} = \&laction;

    my $status = $L->pcall( $narg, ($clear ? 0 : Lua::API::MULTRET), $base);
    $SIG{'INT'} = 'DEFAULT';
    $L->remove( $base);                # remove traceback function

    # force a complete garbage collection in case of errors
    $L->gc( Lua::API::GCCOLLECT, 0)
      if $status != 0;
    return $status;
}


sub print_version {
  l_message(undef, Lua::API::RELEASE . "  " . Lua::API::COPYRIGHT);
}


sub getargs {

    my ($L, $argv, $n) = @_;

    my $narg = @$argv - ($n + 1);	# number of arguments to the script

    $L->checkstack( $narg + 3, "too many arguments to script");

    $L->pushstring( $argv->[$_]) for ( $n+1 .. @$argv-1 );

    $L->createtable( $narg, $n+1);

    for my $i ( 0..@$argv-1)
    {
	$L->pushstring( $argv->[$i]);
	$L->rawseti( -2, $i - $n);
    }
    return $narg;
}


sub dofile {
    my ($L, $name) = @_;

    my $status = $L->loadfile( $name) || docall( $L, 0, 1);
    return report( $L, $status );
}


sub dostring {
    my ( $L, $s, $name) = @_;

    my $status = $L->loadbuffer( $s, length($s), $name) || docall( $L, 0, 1);

    return report( $L, $status );
}


sub  dolibrary {
    my ( $L, $name) = @_;

    $L->getglobal( "require");
    $L->pushstring( $name);
    return report( $L, docall( $L, 1, 1));
}


sub get_prompt {
    my ( $L, $firstline) = @_;

    $L->getfield( Lua::API::GLOBALSINDEX, $firstline ? "_PROMPT" : "_PROMPT2");
    my $p = $L->tostring( -1);
    $p = ($firstline ? '> ' : '>> ')
      if ! defined $p;
    $L->pop( 1);  # remove global
    return $p;
}


sub incomplete {
    my ( $L, $status) = @_;

  if ( $status == Lua::API::ERRSYNTAX) 
  {
      my $lmsg;
      my $msg = $L->tolstring( -1, \$lmsg);

      my $eof = LUA_QL("<eof>");
      if ( $msg =~ /$eof$/ )
      {
	  $L->pop( 1);
	  return 1;
      }
  }
  return 0;  # else...
}


sub pushline {
    my ($L, $firstline) = @_;

    my $b;

    my $prmt = get_prompt( $L, $firstline);

    return 0  # no input
      if $L->readline( \$b, $prmt) == 0;

    chomp $b;
    my $l = length( $b );

    if ( $firstline && substr($b, 0, 1 ) eq '=')  # first line starts with `=' ?
    {
	$L->pushfstring( "return %s", $b+1);  # change it to `return'
    }
    else
    {
	$L->pushstring( $b );
    }
    $L->freeline( $b );

    return 1;
}


sub loadline {
    my ( $L ) = @_;
    $L->settop( 0);

    return -1			# no input
      if ! pushline( $L, 1 );

    my $status;

    for (;;)
    {				# repeat until gets a complete line
	$status = $L->loadbuffer( $L->tostring( 1), $L->strlen( 1), "=stdin");

	last if !incomplete( $L, $status ); # cannot try to add lines?
	return -1
	  if !pushline( $L, 0);	# no more input?

	$L->pushliteral( "\n"); # add a new line...
	$L->insert( -2);	# ...between the two lines
	$L->concat( 3);		# join them
    }
    $L->saveline( 1);
    $L->remove( 1);		# remove line
    return $status;
}


sub dotty { 
    my ( $L ) = @_;

    my $oldprogname = $progname;
    $progname = undef;

    my $status;

    while (( $status = loadline( $L )) != -1)
    {
	$status = docall( $L, 0, 0)	if $status == 0; 
	report( $L, $status);
	if ($status == 0 && $L->gettop > 0)
	{			# any result to print?
	    $L->getglobal( "print");
	    $L->insert( 1);
	    if ($L->pcall( $L->gettop-1, 0, 0) != 0)
	    {
		l_message($progname, 
			  $L->pushfstring("error calling " . LUA_QL("print") ." (%s)",
					  $L->tostring( -1)));
	    }

	}
    }
    $L->settop(0);		# clear stack
    print STDOUT "\n";
    STDOUT->flush;
    $progname = $oldprogname;

    return;
}


sub handle_script {

    my ( $L, $argv, $n)  = @_;

    my $narg = getargs( $L, $argv, $n); # collect arguments

    $L->setglobal( "arg");
    my $fname = $argv->[$n];

    if ( $fname eq '-' && $argv->[$n-1] ne "--")
    {
	$fname = undef;		# stdin
    }

    my $status = $L->loadfile( $fname);

    $L->insert( -($narg+1));

    if ( $status == 0 )
    {
	$ status = docall( $L, $narg, 0);
    }
    else
    {
	$L->pop( $narg);
    }
    return report( $L, $status);
}


sub collectargs {
    my ( $argv, $pi, $pv, $pe) = @_;

    for ( my $i = 0 ; $i < @$argv ; $i++ )
    {

	if ( substr( $argv->[$i], 0, 1 ) ne '-' ) # not an option?
	{  return $i; }

	my $opt = substr( $argv->[$i], 1, 1 );

	if ( $opt eq '-' )
	{
	    return -1 if length( $argv->[$i] ) != 2;
	    return ( @$argv > $i+1 ? $i+1 : 0);
	}

	elsif ( ! defined $opt )
	{
	    return $i;
	}

	elsif ( $opt eq 'i' )
	{
	    return -1 if length( $argv->[$i] ) != 2;
	    $$pi = 1;
	    $$pv = 1;
	}

	elsif ( $opt eq 'v' )
	{
	    return -1 if length( $argv->[$i] ) != 2;
	    $$pv = 1;
	}

	elsif ( $opt eq 'e' || $opt eq 'l' )
	{
	    $$pe = 1 if $opt eq 'e';

	    if ( length($argv->[$i]) == 2)
	    {
		$i++;
		return -1 if @$argv == $i;
	    }
	}
	else
	{
	    return -1;		# invalid option
	}
    }
    return 0;
}


sub runargs {
    my ( $L, $argv, $n ) = @_;

    for (my $i = 0; $i < $n; $i++)
    {
	next if ( ! defined $argv->[$i] );

	$L->assert( $argv->[$i] =~ /^-/ );

	if ( $argv->[$i] =~ /^-e/ )
	{
	    my $chunk = substr( $argv->[$i], 2 );
	    $chunk = $argv->[++$i] if length($chunk) == 0;

	    $L->assert( length($chunk) );

	    if (dostring( $L, $chunk, "=(command line)") != 0)
	      { return 1; }
	}

	elsif ( $argv->[$i] =~ /^-l/ )
	{
	    my $filename = substr( $argv->[$i], 2 );
	    $filename = $argv->[++$i] if length($filename) == 0;

	    $L->assert( length($filename) );

	    if (dolibrary( $L, $filename))
	      { return 1; }		# stop if file fails
	}
    }
    return 0;
}


sub handle_luainit  {

    my ( $L ) = @_;

    if ( ! defined $ENV{LUA_INIT} ) # status OK
    {
	return 0;
    }
    elsif ( $ENV{LUA_INIT} =~ /^@/ )
    {
	return dofile( $L, substr($ENV{LUA_INIT}, 1) );
    }
    else
    {
	return dostring( $L, $ENV{LUA_INIT}, "=" . 'LUA_INIT');
    }
}


sub pmain {
    my ( $L )  = @_;

    my $s = $L->touserdata(1);

    my $argv = $s->{argv};

    my ( $has_i, $has_v, $has_e );

    $globalL = $L;

    $progname = $0;
    if ( @$argv && length($argv->[0]))
    {
	$L->gc( Lua::API::GCSTOP, 0); # stop collector during initialization
    }

    $L->openlibs;		# open libraries
    $L->gc( Lua::API::GCRESTART, 0);
    $s->{status} = handle_luainit( $L );

    return 0 if $s->{status} != 0;

    my $script = collectargs( $argv, \$has_i, \$has_v, \$has_e);

    if ($script < 0)
    {				# invalid args?
	print_usage();
	$s->{status} = 1;
	return 0;
    }

    print_version() if $has_v;

    $s->{status} = runargs( $L, $argv, ($script > 0) ? $script : scalar @$argv);

    return 0 if $s->{status} != 0;

    if ($script)
    {
	$s->{status} = handle_script( $L, $argv, $script);
    }

    return 0 if $s->{status} != 0;

    if ($has_i)
    {
	dotty( $L );
    }
    elsif ( $script == 0 && !$has_e && !$has_v)
    {
	if ( lua_stdin_is_tty() )
	{
	    print_version();
	    dotty($L);
	}
	else
	{
	    dofile( $L );		# executes stdin as a file
	}
    }
    return 0;
}


sub  main  {


  my $L = Lua::API::State->open();  # create state

  if (! defined $L ) {
    l_message($0, "cannot create state: not enough memory");
    return 1;
  }

  my %s = ( argc => scalar @ARGV,
	    argv => \@ARGV );

  my $status = $L->cpcall( \&pmain, \%s);

  report( $L, $status);

#  $L->close;

  return ($status || $s{status}) ? 1 : 0 ;
}

