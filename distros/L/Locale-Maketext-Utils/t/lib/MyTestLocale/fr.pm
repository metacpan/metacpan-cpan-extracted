package MyTestLocale::fr;

use MyTestLocale;
@MyTestLocale::fr::ISA = qw(MyTestLocale);

%MyTestLocale::fr::Lexicon = (
    'Hello World' => 'Bonjour Monde',
);

1;
