#include <cppjieba/Jieba.hpp> 
#include <cppjieba/KeywordExtractor.hpp> 
#include <iostream>

using namespace std;

// a wrapper on Jieba
namespace perljieba {

    class Word {
        public:
            string word;
            size_t offset;
            size_t length;

            Word() {};
            Word(const cppjieba::Word& w)
                : word(w.word), offset(w.unicode_offset), length(w.unicode_length) {
            }
    };

    class KeywordExtractor {
        public:
/*
            KeywordExtractor(const string& dict_path,
                    const string& model_path,
                    const string& user_dict_path, 
                    const string& idf_path, 
                    const string& stop_word_path)
                : extractor_(dict_path, model_path, user_dict_path, idf_path, stop_word_path)
            {
            }
*/
            KeywordExtractor(const cppjieba::DictTrie* dict_trie, 
                    const cppjieba::HMMModel* model,
                    const string& idf_path, 
                    const string& stop_word_path) 
                : extractor_(dict_trie, model, idf_path, stop_word_path)
            {
            }

            vector<pair<string,double> > _extract(const string& sentence, size_t top_n) {
                vector<pair<string,double> > words;
                extractor_.Extract(sentence, words, top_n);
                return words;
            }

        private:
            cppjieba::KeywordExtractor extractor_;
    };

    class Jieba {
        public:
            Jieba(const string& dict_path, 
                    const string& model_path,
                    const string& user_dict_path, 
                    const string& idf_path, 
                    const string& stop_word_path)
                : jieba_(dict_path, model_path, user_dict_path, idf_path, stop_word_path),
                  dict_path_(dict_path),
                  model_path_(model_path),
                  idf_path_(idf_path),
                  stop_word_path_(stop_word_path) {
            }

            vector<string> _cut(const string& sentence, bool hmm = true) {
                vector<string> words;
                jieba_.Cut(sentence, words, hmm);
                return words;
            }

            vector<perljieba::Word> _cut_ex(const string& sentence, bool hmm = true) {
                vector<cppjieba::Word> words;
                jieba_.Cut(sentence, words, hmm);

                std::cout << "HELLO" << std::endl;
            
                vector<perljieba::Word> rslt(words.size());
                _convert_word(words, rslt);
                return rslt;
            }

            vector<string> _cut_all(const string& sentence) {
                vector<string> words;
                jieba_.CutAll(sentence, words);
                return words;
            }

            vector<perljieba::Word> _cut_all_ex(const string& sentence) {
                vector<cppjieba::Word> words;
                jieba_.CutAll(sentence, words);

                vector<perljieba::Word> rslt(words.size());
                _convert_word(words, rslt);
                return rslt;
            }

            vector<string> _cut_for_search(const string& sentence, bool hmm = true) {
                vector<string> words;
                jieba_.CutForSearch(sentence, words, hmm);
                return words;
            }

            vector<perljieba::Word> _cut_for_search_ex(const string& sentence, bool hmm = true) {
                vector<cppjieba::Word> words;
                jieba_.CutForSearch(sentence, words, hmm);

                vector<perljieba::Word> rslt(words.size());
                _convert_word(words, rslt);
                return rslt;
            }
            
            bool insert_user_word(const string& word, const string& tag = "") {
                return jieba_.InsertUserWord(word, tag);
            }

            vector<pair<string, string> > _tag(const string& sentence) {
                vector<pair<string, string> > words;
                jieba_.Tag(sentence, words);
                return words;
            }

            KeywordExtractor extractor() {
                return KeywordExtractor(jieba_.GetDictTrie(),
                                        jieba_.GetHMMModel(),
                                        idf_path_,
                                        stop_word_path_);
            }

        private:
            void _convert_word(const vector<cppjieba::Word>& from, vector<perljieba::Word>& to) {
                for (size_t i = 0; i < from.size(); i++) {
                    to[i] = perljieba::Word(from[i]);
                }
            }
            
        private:
            cppjieba::Jieba jieba_;

            string dict_path_;
            string model_path_;
            string user_dict_path_;
            string idf_path_;
            string stop_word_path_;
    };
}
