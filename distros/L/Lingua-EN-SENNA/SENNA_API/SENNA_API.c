// Standard C libraries
#include <stdio.h>
#include <string.h>
#include <ctype.h>

// Senna POS tagger
#include "SENNA_utils.h"
#include "SENNA_Hash.h"
#include "SENNA_Tokenizer.h"
#include "SENNA_POS.h"
#include "SENNA_CHK.h"
#include "SENNA_NER.h"
#include "SENNA_VBS.h"
#include "SENNA_PT0.h"
#include "SENNA_SRL.h"
#include "SENNA_PSG.h"
// Senna API
#include "SENNA_API.h"

void* SENNA_new(char* opt_path) {
  /* Initialize SENNA toolkit components: */
  SENNA_fields* SENNA_object = malloc(sizeof(SENNA_fields));
  /* SENNA inputs */
  SENNA_object->word_hash = SENNA_Hash_new(opt_path, "hash/words.lst");
  SENNA_object->caps_hash = SENNA_Hash_new(opt_path, "hash/caps.lst");
  SENNA_object->suff_hash = SENNA_Hash_new(opt_path, "hash/suffix.lst");
  SENNA_object->gazt_hash = SENNA_Hash_new(opt_path, "hash/gazetteer.lst");

  SENNA_object->gazl_hash = SENNA_Hash_new_with_admissible_keys(opt_path, "hash/ner.loc.lst", "data/ner.loc.dat");
  SENNA_object->gazm_hash = SENNA_Hash_new_with_admissible_keys(opt_path, "hash/ner.msc.lst", "data/ner.msc.dat");
  SENNA_object->gazo_hash = SENNA_Hash_new_with_admissible_keys(opt_path, "hash/ner.org.lst", "data/ner.org.dat");
  SENNA_object->gazp_hash = SENNA_Hash_new_with_admissible_keys(opt_path, "hash/ner.per.lst", "data/ner.per.dat");

  /* SENNA labels */
  SENNA_object->pos_hash = SENNA_Hash_new(opt_path, "hash/pos.lst");
  SENNA_object->chk_hash = SENNA_Hash_new(opt_path, "hash/chk.lst");
  SENNA_object->pt0_hash = SENNA_Hash_new(opt_path, "hash/pt0.lst");
  SENNA_object->ner_hash = SENNA_Hash_new(opt_path, "hash/ner.lst");
  SENNA_object->vbs_hash = SENNA_Hash_new(opt_path, "hash/vbs.lst");
  SENNA_object->srl_hash = SENNA_Hash_new(opt_path, "hash/srl.lst");
  SENNA_object->psg_left_hash = SENNA_Hash_new(opt_path, "hash/psg-left.lst");
  SENNA_object->psg_right_hash = SENNA_Hash_new(opt_path, "hash/psg-right.lst");

  SENNA_object->tokenizer = SENNA_Tokenizer_new(
    SENNA_object->word_hash,
    SENNA_object->caps_hash,
    SENNA_object->suff_hash,
    SENNA_object->gazt_hash,
    SENNA_object->gazl_hash,
    SENNA_object->gazm_hash,
    SENNA_object->gazo_hash,
    SENNA_object->gazp_hash,
    1); // TODO: The 1 is a parameter, change back to a parametric "is it tokenized?"
  
  SENNA_object->pos = SENNA_POS_new(opt_path, "data/pos.dat");
  SENNA_object->chk = SENNA_CHK_new(opt_path, "data/chk.dat");
  SENNA_object->pt0 = SENNA_PT0_new(opt_path, "data/pt0.dat");
  SENNA_object->ner = SENNA_NER_new(opt_path, "data/ner.dat");
  SENNA_object->vbs = SENNA_VBS_new(opt_path, "data/vbs.dat");
  SENNA_object->srl = SENNA_SRL_new(opt_path, "data/srl.dat");
  SENNA_object->psg = SENNA_PSG_new(opt_path, "data/psg.dat");

  return (void*)SENNA_object;
}

void DESTROY(SENNA_fields* SENNA_object) {
  SENNA_Tokenizer_free(SENNA_object->tokenizer);

  SENNA_POS_free(SENNA_object->pos);
  SENNA_CHK_free(SENNA_object->chk);
  SENNA_PT0_free(SENNA_object->pt0);
  SENNA_NER_free(SENNA_object->ner);
  SENNA_VBS_free(SENNA_object->vbs);
  SENNA_SRL_free(SENNA_object->srl);
  SENNA_PSG_free(SENNA_object->psg);

  SENNA_Hash_free(SENNA_object->word_hash);
  SENNA_Hash_free(SENNA_object->caps_hash);
  SENNA_Hash_free(SENNA_object->suff_hash);
  SENNA_Hash_free(SENNA_object->gazt_hash);

  SENNA_Hash_free(SENNA_object->gazl_hash);
  SENNA_Hash_free(SENNA_object->gazm_hash);
  SENNA_Hash_free(SENNA_object->gazo_hash);
  SENNA_Hash_free(SENNA_object->gazp_hash);

  SENNA_Hash_free(SENNA_object->pos_hash);
  SENNA_Hash_free(SENNA_object->chk_hash);
  SENNA_Hash_free(SENNA_object->pt0_hash);
  SENNA_Hash_free(SENNA_object->ner_hash);
  SENNA_Hash_free(SENNA_object->vbs_hash);
  SENNA_Hash_free(SENNA_object->srl_hash);
  SENNA_Hash_free(SENNA_object->psg_left_hash);
  SENNA_Hash_free(SENNA_object->psg_right_hash);

  free((void*)SENNA_object);
}


SENNA_Tokens* SENNA_Tokenize_sentence(SENNA_fields* SENNA_object, char* sentence) {
     SENNA_Tokens* tokens = SENNA_Tokenizer_tokenize(SENNA_object->tokenizer, sentence);
     return tokens;
}