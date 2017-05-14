use Test::More tests => 2;
BEGIN { use_ok('Lua::API') };


my $fail = 0;
foreach my $constname (qw(
	ENVIRONINDEX ERRERR ERRMEM ERRRUN ERRSYNTAX
	GCCOLLECT GCCOUNT GCCOUNTB GCRESTART GCSETPAUSE
	GCSETSTEPMUL GCSTEP GCSTOP GLOBALSINDEX HOOKCALL
	HOOKCOUNT HOOKLINE HOOKRET HOOKTAILRET MASKCALL
	MASKCOUNT MASKLINE MASKRET MINSTACK MULTRET
	REGISTRYINDEX TBOOLEAN TFUNCTION TLIGHTUSERDATA
	TNIL TNONE TNUMBER TSTRING TTABLE TTHREAD
	TUSERDATA VERSION_NUM YIELD)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Lua::API macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }

}

ok( $fail == 0 , 'Constants' );
