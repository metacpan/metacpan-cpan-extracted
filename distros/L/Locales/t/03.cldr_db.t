use Test::More tests => 3;

use lib 'lib', '../lib';

BEGIN {
    use_ok('Locales');
}

diag("Sanity checking Locales $Locales::VERSION DB");

my $path = $INC{'Locales.pm'};
$path =~ s/\.pm$//;

my $language_path  = "$path/DB/Language";     # make me portable
my $territory_path = "$path/DB/Territory";    # make me portable

my @langs = sort( map { my $pm = $_; $pm =~ s{\.pm$}{}; $pm } _readdir($language_path) );
my @terrs = sort( map { my $pm = $_; $pm =~ s{\.pm$}{}; $pm } _readdir($territory_path) );
is_deeply( \@langs, \@terrs, 'DB/Language and DB/Territory contain the same locales' );

use Locales::DB::Language::en;
use Locales::DB::Territory::en;
my @en_lang_codes = sort( keys %Locales::DB::Language::en::code_to_name );
my @en_terr_codes = sort( keys %Locales::DB::Territory::en::code_to_name );

my %lang_lu;
@lang_lu{@en_lang_codes} = ();
ok( !( grep { !exists $lang_lu{$_} } @langs ), 'en codes contain available locales' );

sub _readdir {
    my ($dir) = @_;
    if ( opendir( my $dh, $dir ) ) {
        my @contents = grep !/^\.\.?$/, readdir($dh);
        closedir($dh);
        return @contents;
    }
    else {
        warn "Could not readdir '$dir': $!";
    }
}
