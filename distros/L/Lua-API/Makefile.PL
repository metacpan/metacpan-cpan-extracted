use inc::Module::Install;

name	'Lua-API';
all_from 'lib/Lua/API.pm';
license 'gpl3';

perl_version '5.008';

auto_license( holder => "Smithsonian Astrophysical Observatory" );
auto_manifest;

no_index directory => 'examples';

provides 'Lua::API'         => { file => 'lib/Lua/API.pm' };
provides 'Lua::API::State'  => { file => 'API.xs' };
provides 'Lua::API::Buffer' => { file => 'API.xs' };
provides 'Lua::API::Debug'  => { file => 'API.xs' };

author_requires 'Module::Install::XSUtil';
author_requires 'Module::Install::AutoLicense';
author_requires 'Module::Install::AutoManifest';
author_requires 'Module::Install::CheckLib';
author_requires 'ExtUtils::Constant';
author_requires 'Template';
author_requires 'File::Slurp';
author_requires 'YAML';
author_requires 'IO::File';

configure_requires 'ExtUtils::PkgConfig';

test_requires 'Test::Class';
test_requires 'Test::Most';
test_requires 'Test::Compile';

my %pkg_info = find_lua();

use_ppport;

cc_warnings;
cc_src_paths '.';
cc_libs $pkg_info{libs}
  if defined $pkg_info{libs};
cc_include_paths $pkg_info{cflags}
  if defined $pkg_info{cflags};


if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(LUA_ENVIRONINDEX LUA_ERRERR LUA_ERRFILE LUA_ERRMEM LUA_ERRRUN
                 LUA_ERRSYNTAX LUA_GCCOLLECT LUA_GCCOUNT LUA_GCCOUNTB
                 LUA_GCRESTART LUA_GCSETPAUSE LUA_GCSETSTEPMUL LUA_GCSTEP
                 LUA_GCSTOP LUA_GLOBALSINDEX LUA_HOOKCALL LUA_HOOKCOUNT
                 LUA_HOOKLINE LUA_HOOKRET LUA_HOOKTAILRET LUA_MASKCALL
                 LUA_MASKCOUNT LUA_MASKLINE LUA_MASKRET LUA_MINSTACK
                 LUA_MULTRET LUA_NOREF LUA_REFNIL LUA_REGISTRYINDEX
                 LUA_TBOOLEAN LUA_TFUNCTION LUA_TLIGHTUSERDATA LUA_TNIL
                 LUA_TNONE LUA_TNUMBER LUA_TSTRING LUA_TTABLE LUA_TTHREAD
                 LUA_TUSERDATA LUA_VERSION_NUM LUA_YIELD));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Lua::API',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );
  use File::Copy;
  use File::Spec;
  mkdir 'fallback';
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($file, $fallback ) or die "Can't copy $file to $fallback: $!";
  }
}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}

WriteAll;

sub find_lua {

    my $found_it = 0;

    my %pi = ( env_or_args( cflags => 'LUA_INC' ),
	       env_or_args( libs => 'LUA_LIBS' )
	     );

    # first check if the user explicitly specified LUA_INC or LUA_LIBS
    if ( grep { defined $pi{$_} } qw[ cflags libs ] )
    {
	# figure out what the name of the lua library actually is.
	# this is so bogus

	my $lib = 'lua';
	$lib = $1
	  if defined $pi{libs} && $pi{libs} =~ /-l(lua\S*)\b/;

	$found_it = eval{
	    local $Module::Install::AUTHOR = 0;
	    checklibs( lib => $lib,
		       header => 'lua.h',
		       defined $pi{libs}   ? (LIBS => $pi{libs})   : (),
		       defined $pi{cflags} ? (INC  => $pi{cflags}) : (),

		     );
	    1;
	};

	# add it to the list of libs if it isn't already there
	if ( $found_it && (! defined $pi{libs} || $pi{libs} !~ /-llua/ ) )
	{
	    $pi{libs} .=  ' -l' . $lib;
	}

    }

    # nope, try pkg-config if it's available
    if ( ! $found_it && eval { require ExtUtils::PkgConfig ; 1} )
    {
	my $lib;
	# try various flavors of lua
	for $lib ( qw[ lua5.1 lua ] )
	{
	    %pi = ExtUtils::PkgConfig->find( $lib );
	    last if keys %pi;
	}

	if ( keys %pi && $pi{modversion} =~ /^5/ )
	{
	    $found_it = eval {
		local $Module::Install::AUTHOR = 0;
		checklibs( lib => $lib,
			   header => 'lua.h',
			   LIBS => $pi{libs},
			   INC  => $pi{cflags},
			 );
		1;
		};
	}
    }

    # last chance. just try the standard locations
    unless ( $found_it )
    {
	for my $lib ( qw[ lua5.1 lua ] )
	{
	    $found_it = eval{
		local $Module::Install::AUTHOR = 0;
		checklibs( lib => $lib, header => 'lua.h');
		1;
	    };
	    last if $found_it;
	}
    }

    do { warn( "unable to find lua 5.1 library\n" ); exit 1; }
      unless $found_it;

    # force run of checklibs as author to get Devel::CheckLibs bundled
    checklibs( 1 ) if $Module::Install::AUTHOR;

    $_ =~ s/\s+$// foreach values %pi;
    $pi{cflags} =~ s/-I//g;

    return %pi;

}

sub env_or_args {

    my ( $name, $what ) = @_;

    foreach ( 0..@ARGV-1 )
    {
	if ( $ARGV[$_] =~ /$what=(.*)/ )
	{
	    delete $ARGV[$_];
	    return ( $name, $1 );
	}
     }

    return defined $ENV{$what} ? ( $name, $ENV{$what} ) : ();
}
