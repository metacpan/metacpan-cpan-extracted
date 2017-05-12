#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "SENNA_API.h"

#define UNUSED(x) (void)(x)
typedef void* Lingua__EN__SENNA;

MODULE = Lingua::EN::SENNA               PACKAGE = Lingua::EN::SENNA              

PROTOTYPES: ENABLE

Lingua::EN::SENNA
new(package)
  char* package
  CODE:
    UNUSED(package);
    STRLEN len;
    SV* SENNA_path = get_sv("Lingua::EN::SENNA::SENNA_path",0);
    char* value = SvPV(SENNA_path, len);
    RETVAL=SENNA_new(value);
  OUTPUT:
    RETVAL

void
DESTROY(SENNA_object)
  Lingua::EN::SENNA SENNA_object

AV*
tokenize(SENNA_object, sentences)
  Lingua::EN::SENNA SENNA_object
  AV* sentences
  CODE:
    int i, sz = av_len(sentences);
    STRLEN len;
    AV* tokenization_results = newAV();
    for (i=0; i<=sz; i++) {
      SV** sentence = av_fetch(sentences, i, 0);
      if (sentence != NULL) {
        AV* sentence_av;
        SENNA_Tokens* sentence_tokens = SENNA_Tokenize_sentence((SENNA_fields*)SENNA_object, SvPV(*sentence, len));
        sentence_av = newAV();
        int token_index;
        for (token_index=0; token_index < sentence_tokens->n; token_index++) {
          char* current_word = sentence_tokens->words[token_index];
          SV* word_sv = newSVpv(current_word,strlen(current_word));
          av_push(sentence_av,word_sv);
        }
        av_push(tokenization_results, newRV_inc((SV*)sentence_av));
      }
    }
    RETVAL = tokenization_results;
  OUTPUT:
    RETVAL



AV* pos_tag(Lingua_SENNA_object, sentences)
  Lingua::EN::SENNA Lingua_SENNA_object
  AV* sentences
  CODE:
    SENNA_fields* SENNA_object = (SENNA_fields*) Lingua_SENNA_object;
    int i, sz = av_len(sentences);
    STRLEN len;
    AV* pos_results = newAV();
    for (i=0; i<=sz; i++) {
      SV** sentence = av_fetch(sentences, i, 0);
      if (sentence != NULL) {
        AV* sentence_av;
        SENNA_Tokens* sentence_tokens = SENNA_Tokenize_sentence(SENNA_object,SvPV(*sentence,len));
        int *pos_labels = NULL;
        pos_labels = SENNA_POS_forward(SENNA_object->pos, sentence_tokens->word_idx, sentence_tokens->caps_idx, sentence_tokens->suff_idx, sentence_tokens->n);
        sentence_av = newAV();
        int token_index;
        for (token_index=0; token_index < sentence_tokens->n; token_index++) {
          char* current_word = sentence_tokens->words[token_index];
          HV* word_hv = newHV();
          SV* word_sv = newSVpv(current_word,strlen(current_word));
          const char* pos_label = SENNA_Hash_key(SENNA_object->pos_hash, pos_labels[token_index]);
          SV* pos_sv = newSVpv(pos_label,strlen(pos_label));
          hv_store(word_hv,"word",4,word_sv,0);
          hv_store(word_hv,"POS",3,pos_sv,0);
          av_push(sentence_av,newRV_inc((SV*)word_hv));
        }
        av_push(pos_results, newRV_inc((SV*)sentence_av));
      }
    }
    RETVAL = pos_results;
  OUTPUT:
    RETVAL

AV* analyze(Lingua_SENNA_object, sentences, options)
  Lingua::EN::SENNA Lingua_SENNA_object
  AV* sentences
  HV* options
  CODE:
    /* First, retrieve options */
    //char *opt_path = NULL;
    //int opt_verbose = 0;
    int opt_notokentags = 0;
    //int opt_offsettags = 0;
    //int opt_iobtags = 0;
    //int opt_brackettags = 0;
    //int opt_posvbs = 0;
    //int opt_usrtokens = 0;
    int opt_pos = 0;
    int opt_chk = 0;
    int opt_ner = 0;
    int opt_srl = 0;
    int opt_psg = 0;
    if hv_exists(options,"POS",3) { opt_pos = 1; }
    if hv_exists(options,"CHK",3) { opt_pos = 1; opt_chk = 1; }
    if hv_exists(options,"NER",3) { opt_pos = 1; opt_ner = 1; }
    if hv_exists(options,"SRL",3) { opt_pos = 1; opt_chk = 1; opt_srl = 1; }
    if hv_exists(options,"PSG",3) { opt_pos = 1; opt_chk = 1; opt_psg = 1; }

    /* Next, analyze sentences as requested */
    SENNA_fields* SENNA_object = (SENNA_fields*) Lingua_SENNA_object;
    int i, j, sz = av_len(sentences);
    STRLEN len;
    AV* results = newAV();
    for (i=0; i<=sz; i++) {
      SV** sentence = av_fetch(sentences, i, 0);
      if (sentence == NULL)
        continue;
      AV* sentence_av = newAV();
      SENNA_Tokens* sentence_tokens = SENNA_Tokenize_sentence(SENNA_object,SvPV(*sentence,len));
      if(sentence_tokens->n == 0)
        continue;
      int *pos_labels = NULL;
      int *chk_labels = NULL;
      int *pt0_labels = NULL;
      int *ner_labels = NULL;
      int *vbs_labels = NULL;
      int **srl_labels = NULL;
      int *psg_labels = NULL;
      int n_psg_level = 0;
      int is_psg_one_segment = 0;
      int vbs_hash_novb_idx = 22;
      int n_verbs = 0;

      if(opt_pos) 
        pos_labels = SENNA_POS_forward(SENNA_object->pos, sentence_tokens->word_idx, sentence_tokens->caps_idx, sentence_tokens->suff_idx, sentence_tokens->n);
      if(opt_chk)
        chk_labels = SENNA_CHK_forward(SENNA_object->chk, sentence_tokens->word_idx, sentence_tokens->caps_idx, pos_labels, sentence_tokens->n);
      if(opt_srl)
        pt0_labels = SENNA_PT0_forward(SENNA_object->pt0, sentence_tokens->word_idx, sentence_tokens->caps_idx, pos_labels, sentence_tokens->n);
      if(opt_ner)
        ner_labels = SENNA_NER_forward(SENNA_object->ner, sentence_tokens->word_idx, sentence_tokens->caps_idx, sentence_tokens->gazl_idx,
                                                          sentence_tokens->gazm_idx, sentence_tokens->gazo_idx, sentence_tokens->gazp_idx, sentence_tokens->n);
      if(opt_srl)
      {
        vbs_labels = SENNA_VBS_forward(SENNA_object->vbs, sentence_tokens->word_idx, sentence_tokens->caps_idx, pos_labels, sentence_tokens->n);
        n_verbs = 0;
        int vbs_token_index;
        for(vbs_token_index = 0; vbs_token_index < sentence_tokens->n; vbs_token_index++)
        {
          vbs_labels[vbs_token_index] = (vbs_labels[vbs_token_index] != vbs_hash_novb_idx);
          n_verbs += vbs_labels[vbs_token_index];
        }
        srl_labels = SENNA_SRL_forward(SENNA_object->srl, sentence_tokens->word_idx, sentence_tokens->caps_idx, pt0_labels, vbs_labels, sentence_tokens->n);
      }

      if(opt_psg)
      {
        SENNA_PSG_forward(SENNA_object->psg, sentence_tokens->word_idx, sentence_tokens->caps_idx, pos_labels, sentence_tokens->n, &psg_labels, &n_psg_level);

        /* check if top level takes the full sentence */
        {
          int *psg_top_labels = psg_labels + (n_psg_level-1)*sentence_tokens->n;

          if(sentence_tokens->n == 1)
            is_psg_one_segment = ((psg_top_labels[0]-1) % 4 == 3); /* S- ? */
          else
            is_psg_one_segment = ((psg_top_labels[0]-1) % 4 == 0) && ((psg_top_labels[sentence_tokens->n-1]-1) % 4 == 2); /* B- or E- ? */

          int psg_token_index;
          for(psg_token_index = 1; is_psg_one_segment && (psg_token_index < sentence_tokens->n-1); psg_token_index++)
          {
            if((psg_top_labels[psg_token_index]-1) % 4 != 1) /* I- ? */
              is_psg_one_segment = 0;
          }
        }
      }

      int token_index;
      for(token_index = 0; token_index < sentence_tokens->n; token_index++)
      {
        HV* word_hv = newHV();
        if(!opt_notokentags) {
          char* current_word = sentence_tokens->words[token_index];
          SV* word_sv = newSVpv(current_word,strlen(current_word));
          hv_store(word_hv,"word",4,word_sv,0);
        }
        if(opt_pos) {
          const char* pos_label = SENNA_Hash_key(SENNA_object->pos_hash, pos_labels[token_index]);
          SV* pos_sv = newSVpv(pos_label,strlen(pos_label));
          hv_store(word_hv,"POS",3,pos_sv,0);
        }
        if(opt_chk) {
          const char* chk_label = SENNA_Hash_key(SENNA_object->chk_hash, chk_labels[token_index]);
          SV* chk_sv = newSVpv(chk_label,strlen(chk_label));
          hv_store(word_hv,"CHK",3,chk_sv,0);
        }
        if(opt_ner) {
          const char* ner_label = SENNA_Hash_key(SENNA_object->ner_hash, ner_labels[token_index]);
          SV* ner_sv = newSVpv(ner_label,strlen(ner_label));
          hv_store(word_hv,"NER",3,ner_sv,0);
        }
        if(opt_srl) {
          AV* srl_av = newAV();
          char* srl_label = (vbs_labels[token_index] ? sentence_tokens->words[token_index] : "-");
          SV* srl_sv = newSVpv(srl_label,strlen(srl_label));
          av_push(srl_av,srl_sv);
          for(j = 0; j < n_verbs; j++) {
            const char* current_column = SENNA_Hash_key(SENNA_object->srl_hash, srl_labels[j][token_index]);
            srl_sv = newSVpv(current_column,strlen(current_column));
            av_push(srl_av,srl_sv);
          }
          hv_store(word_hv,"SRL",3,newRV_inc((SV*)srl_av),0);
        }
        if(opt_psg) /* last, can be long */
        {
          SV* psg_sv = newSVpv("",strlen(""));
          if(token_index == 0)
          {
            sv_catpv(psg_sv,"(S1");
            if(!is_psg_one_segment)
              sv_catpv(psg_sv,"(S");
          }
          for(j = n_psg_level-1; j >= 0; j--)
            sv_catpv(psg_sv,SENNA_Hash_key(SENNA_object->psg_left_hash, psg_labels[j*sentence_tokens->n+token_index]));
          sv_catpv(psg_sv,"*");
          for(j = 0; j < n_psg_level; j++)
            sv_catpv(psg_sv, SENNA_Hash_key(SENNA_object->psg_right_hash, psg_labels[j*sentence_tokens->n+token_index]));
          if(token_index == sentence_tokens->n-1)
          {
            if(!is_psg_one_segment)
              sv_catpv(psg_sv,")");
            sv_catpv(psg_sv,")");
          }
          hv_store(word_hv,"PSG",3,psg_sv,0);
        }
        /* Done with this word */
        av_push(sentence_av,newRV_inc((SV*)word_hv));
      }
      av_push(results, newRV_inc((SV*)sentence_av));
    }
    
    RETVAL = results;
  OUTPUT:
    RETVAL
