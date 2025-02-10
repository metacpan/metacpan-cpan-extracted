use Test::More; # -*- mode: cperl -*-

use lib qw(lib ../lib);

use GitHub::Actions;
use Test::Output;

sub setting_debug {
  debug('FOO');
}

stdout_is(\&setting_debug,"::debug::FOO\n", "Sets output with empty value" );

sub setting_error {
  error('FOO');
}

stdout_is(\&setting_error,"::error::FOO\n", "Sets error with FOO value" );

sub setting_warning {
  warning('FOO');
}

stdout_is(\&setting_warning,"::warning::FOO\n", "Sets warning with FOO value" );

sub setting_error_on_file_no_title {
  error_on_file('FOO', 'foo.pl', 1 );
}
stdout_is(\&setting_error_on_file_no_title,"::error file=foo.pl,line=1,title=ERROR::FOO\n", "Sets error with FOO value" );

sub setting_error_on_file {
  error_on_file('FOO', 'foo.pl', 1, "ERROR" );
}
stdout_is(\&setting_error_on_file,"::error file=foo.pl,line=1,title=ERROR::FOO\n", "Sets error with FOO value" );

sub setting_error_on_file_with_col {
  error_on_file('FOO', 'foo.pl', 1, "ERROR",1 );
}
stdout_is(\&setting_error_on_file_with_col,"::error file=foo.pl,line=1,title=ERROR::FOO,col=1\n", "Sets error with FOO value" );

sub setting_warning_on_file {
  warning_on_file('FOO', 'foo.pl', 1,"WARNING",1 );
}
stdout_is(\&setting_warning_on_file,"::warning file=foo.pl,line=1,title=WARNING::FOO,col=1\n", "Sets warning with FOO value" );

sub setting_warning_on_file_nolines {
  warning_on_file('FOO', 'foo.pl');
}
stdout_is(\&setting_warning_on_file_nolines,"::warning file=foo.pl,title=WARNING::FOO\n", "Sets warning on file" );

sub setting_group {
  start_group( "foo");
  warning("bar");
  end_group;
}
stdout_is(\&setting_group,"::group::foo\n::warning::bar\n::endgroup::\n", "Opens and closes a group" );

eval{ error_on_file( "Won't work" ) };
like( $@, qr/Need/, "error_on_file fails without file" );

done_testing;
