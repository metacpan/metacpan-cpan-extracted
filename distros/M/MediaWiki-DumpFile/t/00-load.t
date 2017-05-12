use Test::More tests => 2;

BEGIN {
    use_ok( 'MediaWiki::DumpFile' );
    use_ok(' MediaWiki::DumpFile::Compat');
}

diag( "Testing MediaWiki::DumpFile $MediaWiki::DumpFile::VERSION, Perl $], $^X" );
