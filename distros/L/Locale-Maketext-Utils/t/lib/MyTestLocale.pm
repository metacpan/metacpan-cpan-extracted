package MyTestLocale;

use Locale::Maketext::Utils;
@MyTestLocale::ISA = qw(Locale::Maketext::Utils);

$MyTestLocale::VERSION  = '0.1';
$MyTestLocale::Onesided = 1;         # main class only
$MyTestLocale::Encoding = 'utf-8';
%MyTestLocale::Lexicon  = ();

__PACKAGE__->make_alias( [qw(en en_us i_default)], 1 );

1;
