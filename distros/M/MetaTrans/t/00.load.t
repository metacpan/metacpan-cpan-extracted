use Test::More tests => 9;

BEGIN {
    use_ok('MetaTrans');
    use_ok('MetaTrans::Base');
    use_ok('MetaTrans::Languages');
    use_ok('MetaTrans::SeznamCz');
    use_ok('MetaTrans::SlovnikCz');
    use_ok('MetaTrans::SlovnikZcuCz');
    use_ok('MetaTrans::SmsCz');
    use_ok('MetaTrans::WordbookCz');
    use_ok('MetaTrans::UltralinguaNet');
}

diag("Testing MetaTrans $MetaTrans::VERSION");
