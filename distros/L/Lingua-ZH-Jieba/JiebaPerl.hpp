#include <cppjieba/Jieba.hpp> 
#include <cppjieba/KeywordExtractor.hpp> 

using namespace std;

// a wrapper on Jieba
namespace perljieba {

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

            vector<string> _cut_all(const string& sentence) {
                vector<string> words;
                jieba_.CutAll(sentence, words);
                return words;
            }

            vector<string> _cut_for_search(const string& sentence, bool hmm = true) {
                vector<string> words;
                jieba_.CutForSearch(sentence, words, hmm);
                return words;
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
            cppjieba::Jieba jieba_;

            string dict_path_;
            string model_path_;
            string user_dict_path_;
            string idf_path_;
            string stop_word_path_;
    };
}
