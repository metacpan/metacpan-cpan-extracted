use Test::More;
use Test::Warn;

use File::Temp qw(tempdir);
use Filesys::DiskUsage qw(du);

plan skip_all => 'no chmod on Windows' if $^O =~ /win32/i;

plan tests => 2;


my $dir = tempdir( CLEANUP => 1 );
#diag $dir;

{
	open my $fh, '>', "$dir/readable" or die;
	print $fh "hello";
	close $fh;
}

{
	mkdir "$dir/sub";
	open my $fh, '>', "$dir/sub/unreadable" or die;
	print $fh "other";
	close $fh;
	chmod 0, "$dir/sub";
}

# osname=freebsd 'Zugriff verweigert' http://www.cpantesters.org/cpan/report/dbc94930-3822-11e4-8725-b85ce0bfc7aa
# osname=linux   'Keine Berechtigung' http://www.cpantesters.org/cpan/report/dcad14b0-3833-11e4-9f9e-a38de0bfc7aa

#my %oswarn = (
#	'en_US.UTF-8' => 'Permission denied',
##	'de' => 'Keine Berechtigung',
#);
#my $os_warn = '(' . join('|', values %oswarn) . ')';

my $du;
warning_like {$du =du( $dir )}
	qr{^could not open $dir/sub \(.+\)$},
	'warning for permission denied';
is $du, 5, 'size of one file';

diag "We run this again to see what are the various error messages in different locales. There will be a warning next line:";
diag '$ENV{LANG}: ' . $ENV{LANG};
du($dir);

