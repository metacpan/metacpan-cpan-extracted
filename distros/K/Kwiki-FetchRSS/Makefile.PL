use inc::Module::Install;

name('Kwiki-FetchRSS');
abstract('WAFL Plugin To Fetch an RSS Feed');
license('perl');
version_from('lib/Kwiki/FetchRSS.pm');

requires(
    'Cache::FileCache' => 0,
    'LWP::UserAgent' => 0,
    'XML::Feed' => 0,
    'Kwiki' => 0.38,
);

check_nmake();

&WriteAll();
