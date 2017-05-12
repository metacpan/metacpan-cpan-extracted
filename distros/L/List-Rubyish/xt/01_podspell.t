use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');
__DATA__
Kazuhiro Osawa
yappo <at> shibuya <döt> pl
List::Rubyish

#     Hatena
#     Ito
#     Junya
#     Kentaro
#     Kondo
#     Kuribayashi
#     Naoya
#     Uniquifies
#     concat
#     dup
#     kan
#     kentaro
#     lopnor
#     refernce
#     shoud
#     tokuhirom
#     uniq
naoya
#     Tateno
#     Yuichi
#     hatena
