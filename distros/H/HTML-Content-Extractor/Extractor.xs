#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "html.h"

#define M_ADD_TO_NEW_BUFF(nc) {if(++n >= lsize) {lsize += 128; new_buff = realloc(new_buff, sizeof(char) * lsize); memset(&new_buff[n], 0, 128);} new_buff[n] = nc;}

typedef htmltag_t * HTML__Content__Extractor;

void clean_text(struct tree_entity *entities, struct lbuffer *lbuff) {
    if(lbuff->i < 0)
        return;
    
    long lsize = lbuff->i + 128;
    char *new_buff = (char *)malloc(sizeof(char) * lsize);
    memset(new_buff, 0, lbuff->i + 1);
    
    long i = 0;
    for (i = 0; i <= lbuff->i; i++) {
        if(lbuff->buff[i] != ' ' && lbuff->buff[i] != '\t' && lbuff->buff[i] != '\n')
            break;
    }
    
    long n = -1, count, next_i;
    while (i <= lbuff->i) {
        count = 0;
        
        switch (lbuff->buff[i]) {
            case '\n':
                for (i = i; i <= lbuff->i; i++) {
                    count++;
                    
                    if(lbuff->buff[i] != '\n' && lbuff->buff[i] != ' ') {
                        i--;
                        break;
                    }
                    else if(count <= 2) {
                        M_ADD_TO_NEW_BUFF(lbuff->buff[i]);
                    }
                }
                
                break;
            case '\r':
                for (i = i; i <= lbuff->i; i++) {
                    count++;
                    
                    if(lbuff->buff[i] != ' ' && lbuff->buff[i] != '\r') {
                        i--;
                        break;
                    }
                    else if(count <= 1) {
                        M_ADD_TO_NEW_BUFF(' ');
                    }
                }
                
                break;
            case ' ':
                for (i = i; i <= lbuff->i; i++) {
                    count++;
                    
                    if(lbuff->buff[i] != ' ' && lbuff->buff[i] != '\t') {
                        i--;
                        break;
                    }
                    else if(count <= 1) {
                        M_ADD_TO_NEW_BUFF(' ');
                    }
                }
                
                break;
            case '\t':
                for (i = i; i <= lbuff->i; i++) {
                    count++;
                    
                    if(lbuff->buff[i] != ' ' && lbuff->buff[i] != '\t') {
                        i--;
                        break;
                    }
                    else if(count <= 1) {
                        M_ADD_TO_NEW_BUFF(' ');
                    }
                }
                
                break;
            case '&':
                next_i = i + 1;
                if(lbuff->buff[next_i] != '\0') {
                    if(lbuff->buff[next_i] == '#') {
                        char *lm = NULL;
                        int hex = lbuff->buff[next_i + 1] == 'x' || lbuff->buff[next_i + 1] == 'X';
                        
                        unsigned long cp = strtoul(&lbuff->buff[ (hex ? (next_i+2) : (next_i+1)) ], &lm, hex ? 16 : 10);
                        long end_pos = lm - &lbuff->buff[i];
                        
                        if(end_pos <= 2) {
                            M_ADD_TO_NEW_BUFF(lbuff->buff[i]);
                            break;
                        }
                        
                        if(*lm == ';') {
                            i += end_pos;
                        } else {
                            i += end_pos - 1;
                        }
                        
                        if(cp <= 0x007Ful)
                        {
                            if(n + 1 >= lsize) {
                                lsize += 128;
                                new_buff = (char*)realloc(new_buff, sizeof(char) * lsize);
                                memset(&new_buff[n + 1], 0, 128);
                            }
                            
                            new_buff[n + 1] = (unsigned char)cp;
                            n++;
                        }
                        else if(cp <= 0x07FFul)
                        {
                            if(n + 2 >= lsize) {
                                lsize += 128;
                                new_buff = (char*)realloc(new_buff, sizeof(char) * lsize);
                                memset(&new_buff[n + 1], 0, 128);
                            }
                            
                            new_buff[n + 2] = (unsigned char)((2 << 6) | (cp & 0x3F));
                            new_buff[n + 1] = (unsigned char)((6 << 5) | (cp >> 6));
                            n += 2;
                        }
                        else if(cp <= 0xFFFFul)
                        {
                            if(n + 3 >= lsize) {
                                lsize += 128;
                                new_buff = (char*)realloc(new_buff, sizeof(char) * lsize);
                                memset(&new_buff[n + 1], 0, 128);
                            }
                            
                            new_buff[n + 3] = (unsigned char)(( 2 << 6) | ( cp       & 0x3F));
                            new_buff[n + 2] = (unsigned char)(( 2 << 6) | ((cp >> 6) & 0x3F));
                            new_buff[n + 1] = (unsigned char)((14 << 4) |  (cp >> 12));
                            n += 3;
                            
                        }
                        else if(cp <= 0x10FFFFul)
                        {
                            if(n + 4 >= lsize) {
                                lsize += 128;
                                new_buff = (char*)realloc(new_buff, sizeof(char) * lsize);
                                memset(&new_buff[n + 1], 0, 128);
                            }
                            
                            new_buff[n + 4] = (unsigned char)(( 2 << 6) | ( cp        & 0x3F));
                            new_buff[n + 3] = (unsigned char)(( 2 << 6) | ((cp >>  6) & 0x3F));
                            new_buff[n + 2] = (unsigned char)(( 2 << 6) | ((cp >> 12) & 0x3F));
                            new_buff[n + 1] = (unsigned char)((30 << 3) |  (cp >> 18));
                            n += 4;
                        }
                    }
                    else {
                        struct tree_entity *entity = check_entity(entities, &lbuff->buff[next_i]);
                        if(entity) {
                            int m = -1;
                            while(entity->value[++m]) {
                                M_ADD_TO_NEW_BUFF(entity->value[m]);
                            }
                            
                            i += entity->level + 1;
                            
                            if(lbuff->buff[i + 1] != '\0' && lbuff->buff[i + 1] == ';')
                                i++;
                        } else {
                            M_ADD_TO_NEW_BUFF(lbuff->buff[i]);
                        }
                    }
                }
                
                break;
                
            default:
                M_ADD_TO_NEW_BUFF(lbuff->buff[i]);
                break;
        }
        
        i++;
    }
    
    for (i = n; i >= 0; i--) {
        if(new_buff[i] != ' ' && new_buff[i] != '\t' && new_buff[i] != '\n' && new_buff[i] != '\0') {
            new_buff[++n] = '\0';
            break;
        }
        
        n--;
    }
    
    free(lbuff->buff);
    lbuff->buff = new_buff;
    lbuff->i    = n;
}

void _add_to_lbuff(struct lbuffer *lbuff, char nc) {
    if(++lbuff->i == lbuff->buff_size) {
        lbuff->buff_size += 4096;
        lbuff->buff = (char *)realloc(lbuff->buff, sizeof(char) * lbuff->buff_size);
    }
    
    lbuff->buff[lbuff->i] = nc;
}

void get_text_without_element(struct tree_list *my_r, struct lbuffer *lbuff) {
    struct html_tree * tag = NULL;
    int element_p_id  = get_tag_id(my_r->tags, "p");
    int element_id_form = get_tag_id(my_r->tags, "form");
    
    long save_nco_pos = my_r->nco_pos;
    
    lbuff->buff = (char *)malloc(sizeof(char) * lbuff->buff_size);
    
    while ((tag = get_next_element_in_level(my_r))) {
        
        if(my_r->tags->type[ tag->tag_id ] == TYPE_TAG_SYS || tag->tag_id == element_id_form) {
            if(get_next_element_in_level_skip_curr(my_r) == NULL)
                break;
            
            get_prev_element_in_level(my_r);
            continue;
        }
        
        if(tag->my_id > 0) {
            if( find_stop_word_param(my_r->swords, &my_r->my[tag->my_id]) ) {
                if(get_next_element_in_level_skip_curr(my_r) == NULL)
                    break;
                
                get_prev_element_in_level(my_r);
                continue;
            }
        }
        
        if(my_r->tags->type[ tag->tag_id ] == TYPE_TAG_BLOCK || my_r->tags->type[ tag->tag_id ] == TYPE_TAG_ONE) {
            _add_to_lbuff(lbuff, '\n');
            
            if(tag->tag_id == element_p_id) {
                _add_to_lbuff(lbuff, '\n');
            }
            
            continue;
        }
        
        if(my_r->tags->type[ tag->tag_id ] != TYPE_TAG_TEXT) {
            continue;
        }
        
        long il; int semp = 0;
        for (il = tag->tag_body_start; il <= tag->tag_body_stop; il++) {
            if(semp == 0 && (my_r->html[il] == '\n' || my_r->html[il] == '\r')) {
                continue;
            }
            
            semp = 1;
            
            if(my_r->html[il] == '\n') {
                _add_to_lbuff(lbuff, '\r');
                continue;
            }
            
            _add_to_lbuff(lbuff, my_r->html[il]);
        }
    }
    
    _add_to_lbuff(lbuff, '\0');
    
    my_r->nco_pos = save_nco_pos;
}

void _get_text_with_element_cl(struct tree_list *my_r, struct lbuffer *lbuff, char **elements, int ei_size) {
    struct html_tree * tag = NULL;
    int element_p_id  = get_tag_id(my_r->tags, "p");
    int element_br_id  = get_tag_id(my_r->tags, "br");
    int element_id_form = get_tag_id(my_r->tags, "form");
    
    while ((tag = get_next_element_in_level(my_r))) {
        
        int is, it, ip = -1, in = -1;
        for (is = 0; is <= ei_size; is++) {
            it = -1;
            while (elements[is][++it]) {
                in = it + 1;
                if((my_r->tags->name[tag->tag_id][in] == '\0' && elements[is][in] != '\0') ||
                   (my_r->tags->name[tag->tag_id][in] != '\0' && elements[is][in] == '\0') ||
                   my_r->tags->name[tag->tag_id][it] != elements[is][it]
                   ) {
                    break;
                }
                else if(my_r->tags->name[tag->tag_id][in] == '\0' && elements[is][in] == '\0') {
                    ip = tag->tag_id;
                    break;
                }
            }
        }
        
        if(ip != -1) {
            long il;
            for (il = tag->tag_start; il < tag->tag_body_start; il++) {
                _add_to_lbuff(lbuff, my_r->html[il]);
            }
            
            long save_nco_pos = my_r->nco_pos;
            long save_cur_pos = my_r->cur_pos;
            my_r->nco_pos = tag->id;
            my_r->cur_pos = tag->id;
            
            _get_text_with_element_cl(my_r, lbuff, elements, ei_size);
            
            for (il = tag->tag_body_stop + 1; il <= tag->tag_stop; il++) {
                _add_to_lbuff(lbuff, my_r->html[il]);
            }
            
            my_r->nco_pos = save_nco_pos;
            my_r->cur_pos = save_cur_pos;
            
            if(get_next_element_in_level_skip_curr(my_r) == NULL)
                break;
            
            get_prev_element_in_level(my_r);
            
            //continue;
        }
        
        if(my_r->tags->type[ tag->tag_id ] == TYPE_TAG_SYS || tag->tag_id == element_id_form) {
            if(get_next_element_in_level_skip_curr(my_r) == NULL)
                break;
            
            get_prev_element_in_level(my_r);
            continue;
        }
        
        if(my_r->tags->type[ tag->tag_id ] == TYPE_TAG_BLOCK || my_r->tags->type[ tag->tag_id ] == TYPE_TAG_ONE) {
            if((tag->tag_id == element_br_id && ip != element_br_id) || (my_r->tags->type[ tag->tag_id ] == TYPE_TAG_BLOCK))
                _add_to_lbuff(lbuff, '\n');
            
            if(tag->tag_id == element_p_id && ip != element_p_id) {
                _add_to_lbuff(lbuff, '\n');
            }
            
            continue;
        }
        
        if(my_r->tags->type[ tag->tag_id ] != TYPE_TAG_TEXT) {
            continue;
        }
        
        long il;
        for (il = tag->tag_body_start; il <= tag->tag_body_stop; il++) {
            if(my_r->html[il] != '\n')
                _add_to_lbuff(lbuff, my_r->html[il]);
        }
    }
}

void get_text_with_element(struct tree_list *my_r, struct lbuffer *lbuff, char **elements, int ei_size) {
    long save_nco_pos = my_r->nco_pos;
    
    lbuff->buff = (char *)malloc(sizeof(char) * lbuff->buff_size);
    
    _get_text_with_element_cl(my_r, lbuff, elements, ei_size);
    _add_to_lbuff(lbuff, '\0');
    
    my_r->nco_pos = save_nco_pos;
}

void get_raw_text(struct tree_list *my_r, struct lbuffer *lbuff) {
    struct html_tree * tag = get_curr_element(my_r);
    
    lbuff->i = -1;
    lbuff->buff_size = (tag->tag_stop - tag->tag_start) + 2;
    lbuff->buff = (char *)malloc(sizeof(char) * lbuff->buff_size);
    
    long il;
    for (il = tag->tag_start; il <= tag->tag_stop; il++) {
        lbuff->buff[++lbuff->i] = my_r->html[il];
    }
    
    lbuff->buff[++lbuff->i] = '\0';
}

int _check_img_size(char *str) {
    int rv = 0;
    
    if(str){
        while ( *str ) {
            if(*str <= '9' && *str >= '0') {
                rv = (rv * 10) + (*str - '0');
            }
            else if(rv != 0) {
                rv = 0;
                break;
            }
            
            str++;
        }
    }
    
    return rv;
}

struct return_list * get_text_images_href(struct tree_list *my_r, struct return_list *return_list, int inc, struct mem_stop_words *stop_words, int min_width) {
    struct html_tree * tag = NULL;
    
    long save_nco_pos = my_r->nco_pos;
    
    if(return_list == NULL) {
        return_list = (struct return_list *)malloc(sizeof(struct return_list));
        
        return_list->count = sizeof(struct return_list) * 1024;
        return_list->real_count = -1;
        return_list->list = (struct mem_tag *)malloc(sizeof(struct mem_tag) * return_list->count);
    }
    
    while ((tag = get_next_element_in_level(my_r))) {
        if(my_r->tags->ai[ tag->tag_id ] == AI_IMG) {
            struct mem_params * param = find_param_by_key_in_element(&my_r->my[tag->my_id], "src");
            if(param == NULL)
                continue;
            
            if(tag->my_id > 0) {
                if( find_stop_word_param(stop_words, &my_r->my[tag->my_id]) )
                    continue;
            }
            
            struct mem_params * width = find_param_by_key_in_element(&my_r->my[tag->my_id], "width");
            if( width == NULL || min_width == 0 || (min_width > 0 && _check_img_size(width->value) >= min_width) ) {
                if(param->lvalue > -1) {
                    return_list->real_count++;
                    return_list->list[ return_list->real_count ] = my_r->my[tag->my_id];
                }
            }
        }
    }
    
    if(inc < 1) {
        struct html_tree *curr_pos = get_curr_element(my_r);
        get_prev_element_curr_level(my_r);
        get_text_images_href(my_r, return_list, ++inc, stop_words, min_width);
        set_position(my_r, curr_pos);
    }
    
    if(inc == 1) {
        my_r->nco_pos = save_nco_pos;
        get_next_element_curr_level(my_r);
        get_text_images_href(my_r, return_list, ++inc, stop_words, min_width);
    }
    
    my_r->nco_pos = save_nco_pos;
    
    return return_list;
}

struct html_tree * check_html(struct tree_list *my_r, struct max_element *max) {
    struct html_tree * tag;
    long i = -1;
    
    size_t istags= 26;
    int skip_tags[istags];
    skip_tags[0]  = get_tag_id(my_r->tags, "address");
    skip_tags[1]  = get_tag_id(my_r->tags, "applet");
    skip_tags[2]  = get_tag_id(my_r->tags, "audio");
    skip_tags[3]  = get_tag_id(my_r->tags, "video");
    skip_tags[4]  = get_tag_id(my_r->tags, "source");
    skip_tags[5]  = get_tag_id(my_r->tags, "track");
    skip_tags[6]  = get_tag_id(my_r->tags, "bgsound");
    skip_tags[7]  = get_tag_id(my_r->tags, "canvas");
    skip_tags[8]  = get_tag_id(my_r->tags, "datalist");
    skip_tags[9]  = get_tag_id(my_r->tags, "button");
    skip_tags[10] = get_tag_id(my_r->tags, "fieldset");
    skip_tags[11] = get_tag_id(my_r->tags, "legend");
    skip_tags[12] = get_tag_id(my_r->tags, "input");
    skip_tags[13] = get_tag_id(my_r->tags, "keygen");
    skip_tags[14] = get_tag_id(my_r->tags, "textarea");
    skip_tags[15] = get_tag_id(my_r->tags, "frameset");
    skip_tags[16] = get_tag_id(my_r->tags, "noframes");
    skip_tags[17] = get_tag_id(my_r->tags, "label");
    skip_tags[18] = get_tag_id(my_r->tags, "link");
    skip_tags[19] = get_tag_id(my_r->tags, "map");
    skip_tags[20] = get_tag_id(my_r->tags, "object");
    skip_tags[21] = get_tag_id(my_r->tags, "progress");
    skip_tags[22] = get_tag_id(my_r->tags, "time");
    skip_tags[23] = get_tag_id(my_r->tags, "xmp");
    skip_tags[24] = get_tag_id(my_r->tags, "footer");
    skip_tags[25] = get_tag_id(my_r->tags, "noindex");
    
    struct html_tree *curr_element = get_curr_element(my_r);
    
    if(curr_element->tag_id != get_tag_id(my_r->tags, "form"))
    {
        long count_words = curr_element->count_word;
        long count_link = curr_element->counts[AI_LINK];
        
        while((tag = get_child_n(my_r, ++i))) {
            count_link += tag->counts[AI_LINK];
            
            if(my_r->tags->ai[ tag->tag_id ] == AI_TEXT) {
                count_words += tag->count_word;
            }
        }
        
        if((count_words > 0 && count_link > 0 && ((count_words / count_link) > 1) && max->count_words < count_words) || (max->count_words < count_words && count_link == 0))
        {
            max->count_words = count_words;
            max->element = get_curr_element(my_r);
        }
    }
    
    int n = 0, t;
    i = -1;
    
    while((tag = get_child_n(my_r, ++i))) {
        if(my_r->tags->ai[ tag->tag_id ] == AI_LINK) {
            continue;
        }
        
        n = 0;
        for (t = 0; t < istags; t++) {
            if(tag->tag_id == skip_tags[t]) {
                n = 1;
                break;
            }
        }
        
        if (n == 1)
            continue;
        
        if(my_r->tags->family[tag->tag_id] == FAMILY_SELECT) {
            continue;
        }
        
        if(my_r->tags->type[tag->tag_id] == TYPE_TAG_ONE || my_r->tags->type[tag->tag_id] == TYPE_TAG_SIMPLE || my_r->tags->type[tag->tag_id] == TYPE_TAG_SYS) {
            continue;
        }
        
        if(my_r->tags->extra[tag->tag_id] == EXTRA_TAG_SIMPLE) {
            continue;
        }
        
        if(tag->my_id > 0) {
            if( find_stop_word_param(my_r->swords, &my_r->my[tag->my_id]) )
                continue;
        }
        
        set_position(my_r, tag);
        check_html(my_r, max);
        set_position(my_r, curr_element);
    }
    
    return max->element;
}

void check_html_with_all_text(struct tree_list *my_r, struct max_element_list *max_list) {
    struct html_tree * tag;
    long i = -1;
    long count_words = 0, count_link = 0;
    int element_id_form = get_tag_id(my_r->tags, "form");
    
    struct html_tree *curr_element = get_curr_element(my_r);
    
    while((tag = get_child_n(my_r, ++i))) {
        count_link += tag->counts[AI_LINK];
        
        if(my_r->tags->ai[ tag->tag_id ] == AI_TEXT) {
            count_words += tag->count_word;
        }
    }
    
    if((count_words > 0 && count_link > 0 && ((count_words / count_link) > 1)) || (count_words && count_link == 0))
    {
        max_list->lelements++;
        if(max_list->lelements >= max_list->lelements_size){
            max_list->lelements_size += 1024;
            max_list->elements = (struct max_element*)realloc(max_list->elements, max_list->lelements_size);
        }
        
        max_list->elements[max_list->lelements].element = curr_element;
        max_list->elements[max_list->lelements].count_words = count_words;
    }
    
    i = -1;
    while((tag = get_child_n(my_r, ++i))) {
        if(my_r->tags->ai[ tag->tag_id ] == AI_LINK) {
            continue;
        }
        
        // skip form
        if(tag->tag_id == element_id_form || my_r->tags->type[tag->tag_id] == TYPE_TAG_SIMPLE) {
            continue;
        }
        
        set_position(my_r, tag);
        check_html_with_all_text(my_r, max_list);
        set_position(my_r, curr_element);
    }
}

int init_tags(struct tags *tags) {
    if(tags->csize > -1)
        return -1;
    
    tags->csize = 2048;
    
    tags->name     = (char **)malloc(sizeof(char *) * tags->csize);
    
    tags->priority = (int *)malloc(sizeof(int) * tags->csize);
    tags->type     = (int *)malloc(sizeof(int) * tags->csize);
    tags->extra    = (int *)malloc(sizeof(int) * tags->csize);
    tags->ai       = (int *)malloc(sizeof(int) * tags->csize);
    tags->family   = (int *)malloc(sizeof(int) * tags->csize);
    tags->option   = (int *)malloc(sizeof(int) * tags->csize);
    
    tags->index.tag_id    = (long **)malloc(sizeof(long *) * tags->csize);
    tags->index.tag_count = (int *)malloc(sizeof(int) * tags->csize);
    tags->index.tag_csize = (int *)malloc(sizeof(int) * tags->csize);
    
    // default tags !!!NOT EDIT!!!
    // нулевой элемент для текста, то есть для элементов которые внутри тега
    add_tag_R(tags, ""      , 0, 0  , 0, TYPE_TAG_TEXT  , 0, OPTION_NULL, AI_NULL);
    // end default tags
    
    add_tag_R(tags, "!doctype", 8, 0, 0, TYPE_TAG_ONE, 0, OPTION_NULL, AI_NULL);
    
    add_tag_R(tags, "html", 4, 400, FAMILY_HTML, TYPE_TAG_BLOCK, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "head", 4, 200, FAMILY_HTML, TYPE_TAG_BLOCK, EXTRA_TAG_CLOSE_IF_SELF_FAMILY, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "body", 4, 200, FAMILY_HTML, TYPE_TAG_BLOCK, EXTRA_TAG_CLOSE_IF_SELF_FAMILY, OPTION_NULL, AI_NULL);
    
    add_tag_R(tags, "a", 1, 0, 0, TYPE_TAG_NORMAL, EXTRA_TAG_CLOSE_IF_SELF, OPTION_NULL, AI_LINK);
    add_tag_R(tags, "abbr", 4, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "acronym", 7, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "address", 7, 0, 0, TYPE_TAG_BLOCK, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "applet", 6, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "article", 7, 0, 0, TYPE_TAG_BLOCK, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "aside", 5, 0, 0, TYPE_TAG_BLOCK, 0, OPTION_NULL, AI_NULL);
    
    // ++ audio, video ++
    add_tag_R(tags, "audio", 5, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "video", 5, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "source", 6, 0, 0, TYPE_TAG_ONE, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "track", 5, 0, 0, TYPE_TAG_ONE, 0, OPTION_NULL, AI_NULL);
    // -- audio, video --
    
    add_tag_R(tags, "b", 1, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_TEXT);
    
    add_tag_R(tags, "base", 4, 0, 0, TYPE_TAG_ONE, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "basefont", 8, 0, 0, TYPE_TAG_ONE, 0, OPTION_NULL, AI_NULL);
    
    add_tag_R(tags, "bdi", 3, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "bdo", 3, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    
    add_tag_R(tags, "bgsound", 7, 0, 0, TYPE_TAG_ONE, 0, OPTION_NULL, AI_NULL);
    
    add_tag_R(tags, "big", 3, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "blink", 5, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "blockquote", 10, 0, 0, TYPE_TAG_BLOCK, 0, OPTION_NULL, AI_NULL);
    
    add_tag_R(tags, "br", 2, 0, 0, TYPE_TAG_ONE, 0, OPTION_NULL, AI_NULL);
    
    add_tag_R(tags, "canvas", 6, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "center", 6, 0, 0, TYPE_TAG_BLOCK, 0, OPTION_NULL, AI_TEXT);
    add_tag_R(tags, "cite", 4, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_TEXT);
    add_tag_R(tags, "code", 4, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_TEXT);
    add_tag_R(tags, "comment", 7, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_TEXT);
    
    // ++ datalist ++
    add_tag_R(tags, "datalist", 8, 20, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    //add_tag_R(tags, "option", 6, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    // -- datalist --
    
    add_tag_R(tags, "del", 3, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    
    // ++ details ++
    add_tag_R(tags, "details", 7, 0, 0, TYPE_TAG_BLOCK, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "summary", 7, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    // -- details --
    
    add_tag_R(tags, "dfn", 3, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    
    // ++ dir ++
    add_tag_R(tags, "dir", 3, 20, FAMILY_LIST, TYPE_TAG_BLOCK, 0, OPTION_NULL, AI_NULL); // out of test
    //add_tag_R(tags, "li", 2, 0, 0, TYPE_TAG_NORMAL, EXTRA_TAG_CLOSE_IF_SELF, OPTION_NULL, AI_NULL);
    // -- dir --
    
    add_tag_R(tags, "div", 3, 50, 0, TYPE_TAG_BLOCK, 0, OPTION_NULL, AI_NULL);
    
    // ++ dl ++
    add_tag_R(tags, "dl", 2, 20, 0, TYPE_TAG_BLOCK, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "dt", 2, 19, 0, TYPE_TAG_BLOCK, EXTRA_TAG_CLOSE_PRIORITY_FAMILY, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "dd", 2, 19, 0, TYPE_TAG_BLOCK, EXTRA_TAG_CLOSE_PRIORITY_FAMILY, OPTION_NULL, AI_NULL);
    // -- dl --
    
    add_tag_R(tags, "em", 2, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    
    add_tag_R(tags, "embed", 5, 0, 0, TYPE_TAG_ONE, 0, OPTION_NULL, AI_NULL);
    
    // ++ figure ++
    add_tag_R(tags, "figure", 6, 0, 0, TYPE_TAG_BLOCK, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "figcaption", 10, 0, 0, TYPE_TAG_BLOCK, 0, OPTION_NULL, AI_NULL);
    // -- figure --
    
    add_tag_R(tags, "font", 4, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "footer", 6, 0, 0, TYPE_TAG_BLOCK, 0, OPTION_NULL, AI_NULL);
    
    // ++ form ++
    add_tag_R(tags, "form", 4, 0, 0, TYPE_TAG_BLOCK, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "button", 6, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    
    // ++ form: fieldset ++
    add_tag_R(tags, "fieldset", 8, 0, 0, TYPE_TAG_BLOCK, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "legend", 6, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    // -- form: fieldset --
    
    // ++ form: select ++
    add_tag_R(tags, "select", 6, 20, FAMILY_SELECT, TYPE_TAG_NORMAL, EXTRA_TAG_CLOSE_PRIORITY, OPTION_CLEAN_TAGS, AI_NULL);
    add_tag_R(tags, "optgroup", 8, 19, FAMILY_SELECT, TYPE_TAG_NORMAL, EXTRA_TAG_CLOSE_PRIORITY, OPTION_CLEAN_TAGS_SAVE, AI_NULL);
    add_tag_R(tags, "option", 6, 18, FAMILY_SELECT, TYPE_TAG_NORMAL, EXTRA_TAG_CLOSE_PRIORITY, OPTION_CLEAN_TAGS_SAVE, AI_NULL);
    // -- form: select --
    
    add_tag_R(tags, "input", 5, 0, 0, TYPE_TAG_ONE, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "keygen", 6, 0, 0, TYPE_TAG_ONE, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "textarea", 8, 0, 0, TYPE_TAG_NORMAL, EXTRA_TAG_SIMPLE, OPTION_NULL, AI_NULL);
    // -- form --
    
    // ++ frameset ++
    add_tag_R(tags, "frameset", 8, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "frame", 5, 0, 0, TYPE_TAG_ONE, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "noframes", 8, 0, 0, TYPE_TAG_NORMAL, EXTRA_TAG_SIMPLE_TREE, OPTION_NULL, AI_NULL);
    // -- frameset --
    
    // ++ isindex ++ // hm, crazy tag
    add_tag_R(tags, "isindex", 7, 0, 0, TYPE_TAG_ONE, 0, OPTION_NULL, AI_NULL);
    // -- isindex --
    
    add_tag_R(tags, "h1", 2, 0, FAMILY_H, TYPE_TAG_BLOCK, EXTRA_TAG_CLOSE_IF_SELF_FAMILY, OPTION_NULL, AI_TEXT);
    add_tag_R(tags, "h2", 2, 0, FAMILY_H, TYPE_TAG_BLOCK, EXTRA_TAG_CLOSE_IF_SELF_FAMILY, OPTION_NULL, AI_TEXT);
    add_tag_R(tags, "h3", 2, 0, FAMILY_H, TYPE_TAG_BLOCK, EXTRA_TAG_CLOSE_IF_SELF_FAMILY, OPTION_NULL, AI_TEXT);
    add_tag_R(tags, "h4", 2, 0, FAMILY_H, TYPE_TAG_BLOCK, EXTRA_TAG_CLOSE_IF_SELF_FAMILY, OPTION_NULL, AI_TEXT);
    add_tag_R(tags, "h5", 2, 0, FAMILY_H, TYPE_TAG_BLOCK, EXTRA_TAG_CLOSE_IF_SELF_FAMILY, OPTION_NULL, AI_TEXT);
    add_tag_R(tags, "h6", 2, 0, FAMILY_H, TYPE_TAG_BLOCK, EXTRA_TAG_CLOSE_IF_SELF_FAMILY, OPTION_NULL, AI_TEXT);
    
    add_tag_R(tags, "header", 6, 0, 0, TYPE_TAG_BLOCK, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "hgroup", 6, 0, 0, TYPE_TAG_BLOCK, 0, OPTION_NULL, AI_NULL);
    
    add_tag_R(tags, "hr", 2, 0, 0, TYPE_TAG_BLOCK, EXTRA_TAG_CLOSE_NOW, OPTION_NULL, AI_NULL); // TYPE_TAG_ONE :)
    
    add_tag_R(tags, "i", 1, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_TEXT);
    
    add_tag_R(tags, "iframe", 6, 0, 0, TYPE_TAG_NORMAL, EXTRA_TAG_SIMPLE, OPTION_NULL, AI_NULL);
    
    add_tag_R(tags, "img", 3, 0, 0, TYPE_TAG_ONE, 0, OPTION_NULL, AI_IMG);
    
    add_tag_R(tags, "ins", 3, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "kbd", 3, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "label", 5, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    
    // ++ link ++
    add_tag_R(tags, "link", 4, 0, 0, TYPE_TAG_ONE, 0, OPTION_NULL, AI_NULL);
    // -- link --
    
    // ++ map ++
    add_tag_R(tags, "map", 3, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "area", 4, 0, 0, TYPE_TAG_ONE, 0, OPTION_NULL, AI_NULL);
    // -- map --
    
    add_tag_R(tags, "mark", 4, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "marquee", 7, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    
    // ++ menu ++
    add_tag_R(tags, "menu", 4, 20, FAMILY_LIST, TYPE_TAG_BLOCK, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "command", 7, 0, 0, TYPE_TAG_ONE, 0, OPTION_NULL, AI_NULL);
    //add_tag_R(tags, "li", 2, 0, 0, TYPE_TAG_NORMAL, EXTRA_TAG_CLOSE_IF_SELF, OPTION_NULL, AI_NULL);
    // -- menu --
    
    // ++ meta ++
    add_tag_R(tags, "meta", 4, 0, 0, TYPE_TAG_ONE, 0, OPTION_NULL, AI_NULL);
    // -- meta --
    
    add_tag_R(tags, "meter", 5, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "nav", 3, 0, 0, TYPE_TAG_BLOCK, 0, OPTION_NULL, AI_NULL);
    
    add_tag_R(tags, "nobr", 4, 0, 0, TYPE_TAG_NORMAL, EXTRA_TAG_CLOSE_IF_SELF, OPTION_NULL, AI_NULL);
    
    add_tag_R(tags, "noembed", 7, 0, 0, TYPE_TAG_NORMAL, EXTRA_TAG_SIMPLE, OPTION_NULL, AI_NULL);
    
    add_tag_R(tags, "noscript", 8, 0, 0, TYPE_TAG_SYS, EXTRA_TAG_SIMPLE, OPTION_NULL, AI_NULL);
    
    add_tag_R(tags, "object", 6, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    
    // ++ ol ++
    add_tag_R(tags, "ol", 2, 20, FAMILY_LIST, TYPE_TAG_BLOCK, 0, OPTION_NULL, AI_NULL);
    //add_tag_R(tags, "li", 2, 0, 0, TYPE_TAG_NORMAL, EXTRA_TAG_CLOSE_IF_SELF, OPTION_NULL, AI_NULL);
    // -- ol --
    
    add_tag_R(tags, "output", 6, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "p", 1, 30, 0, TYPE_TAG_BLOCK, EXTRA_TAG_CLOSE_IF_BLOCK, OPTION_NULL, AI_TEXT);
    
    add_tag_R(tags, "param", 5, 0, 0, TYPE_TAG_ONE, 0, OPTION_NULL, AI_NULL);
    
    //add_tag_R(tags, "plaintext", 9, 0, 0, TYPE_TAG_ONE, 0, OPTION_NULL, AI_NULL); // out of test -- ?????
    
    add_tag_R(tags, "pre", 3, 0, 0, TYPE_TAG_BLOCK, 0, OPTION_NULL, AI_TEXT);
    add_tag_R(tags, "progress", 8, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    
    add_tag_R(tags, "q", 1, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_TEXT);
    
    // ++ ruby ++
    add_tag_R(tags, "ruby", 4, 20, FAMILY_RUBY, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "rt", 2, 19, FAMILY_RUBY, TYPE_TAG_NORMAL, EXTRA_TAG_CLOSE_PRIORITY_FAMILY, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "rp", 2, 19, FAMILY_RUBY, TYPE_TAG_NORMAL, EXTRA_TAG_CLOSE_PRIORITY_FAMILY, OPTION_NULL, AI_NULL);
    // -- ruby --
    
    add_tag_R(tags, "s", 1, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_TEXT);
    add_tag_R(tags, "samp", 4, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    
    add_tag_R(tags, "script", 6, 0, 0, TYPE_TAG_SYS, EXTRA_TAG_SIMPLE, OPTION_NULL, AI_NULL);
    
    add_tag_R(tags, "section", 7, 0, 0, TYPE_TAG_BLOCK, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "small", 5, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_TEXT);
    add_tag_R(tags, "span", 4, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_TEXT);
    add_tag_R(tags, "strike", 6, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_TEXT);
    add_tag_R(tags, "strong", 6, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    
    // ++ style ++
    add_tag_R(tags, "style", 5, 0, 0, TYPE_TAG_SYS, EXTRA_TAG_SIMPLE, OPTION_NULL, AI_NULL);
    // -- style --
    
    add_tag_R(tags, "sub", 3, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "sup", 3, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    
    // ++ table ++
    add_tag_R(tags, "table"    , 5, 55, FAMILY_TABLE, TYPE_TAG_BLOCK , EXTRA_TAG_CLOSE_IF_SELF, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "caption"  , 7, 54, FAMILY_TABLE, TYPE_TAG_BLOCK , EXTRA_TAG_CLOSE_FAMILY_LIST, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "col"      , 3, 53, FAMILY_TABLE, TYPE_TAG_ONE   , EXTRA_TAG_CLOSE_FAMILY_LIST, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "colgroup" , 8, 54, FAMILY_TABLE, TYPE_TAG_NORMAL, EXTRA_TAG_CLOSE_FAMILY_LIST, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "tbody"    , 5, 54, FAMILY_TABLE, TYPE_TAG_BLOCK , EXTRA_TAG_CLOSE_FAMILY_LIST, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "tfoot"    , 5, 54, FAMILY_TABLE, TYPE_TAG_BLOCK , EXTRA_TAG_CLOSE_FAMILY_LIST, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "thead"    , 5, 54, FAMILY_TABLE, TYPE_TAG_BLOCK , EXTRA_TAG_CLOSE_FAMILY_LIST, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "tr"       , 2, 53, FAMILY_TABLE, TYPE_TAG_BLOCK , EXTRA_TAG_CLOSE_FAMILY_LIST, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "td"       , 2, 52, FAMILY_TABLE, TYPE_TAG_BLOCK , EXTRA_TAG_CLOSE_FAMILY_LIST, OPTION_NULL, AI_TEXT);
    add_tag_R(tags, "th"       , 2, 52, FAMILY_TABLE, TYPE_TAG_BLOCK , EXTRA_TAG_CLOSE_FAMILY_LIST, OPTION_NULL, AI_TEXT);
    // -- table --
    
    add_tag_R(tags, "time", 4, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    
    add_tag_R(tags, "title", 5, 0, 0, TYPE_TAG_NORMAL, EXTRA_TAG_SIMPLE_TREE, OPTION_NULL, AI_NULL);
    
    add_tag_R(tags, "tt", 2, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "u", 1, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    
    // ++ ul ++
    add_tag_R(tags, "ul", 2, 20, FAMILY_LIST, TYPE_TAG_BLOCK, 0, OPTION_NULL, AI_NULL);
    add_tag_R(tags, "li", 2, 19, FAMILY_LIST, TYPE_TAG_BLOCK, EXTRA_TAG_CLOSE_PRIORITY_FAMILY, OPTION_NULL, AI_TEXT);
    //add_tag_R(tags, "li", 2, 0, 0, TYPE_TAG_NORMAL, EXTRA_TAG_CLOSE_IF_SELF, OPTION_NULL, AI_NULL); -- orig
    // -- ul --
    
    add_tag_R(tags, "var", 3, 0, 0, TYPE_TAG_NORMAL, 0, OPTION_NULL, AI_NULL);
    
    add_tag_R(tags, "wbr", 3, 0, 0, TYPE_TAG_ONE, 0, OPTION_NULL, AI_NULL);
    
    add_tag_R(tags, "xmp", 3, 0, 0, TYPE_TAG_BLOCK, EXTRA_TAG_SIMPLE, OPTION_NULL, AI_NULL);
    
    return tags->csize;
}

int check_open_tag_family_tree(struct tags_family *tags_family, struct elements *tree_curr, long ti, int tag_id)
{
    int tf = -1; int is_true = 1;
    while (tags_family->tags[tag_id][++tf]) {
        if(tree_curr->tree[ tree_curr->index[ti] ].tag_id == tags_family->tags[tag_id][tf]) {
            is_true = 2; break;
        }
        
        if(is_true == 1 && tags_family->tags[ tags_family->tags[tag_id][tf] ] != 0) {
            is_true = check_open_tag_family_tree(tags_family, tree_curr, ti, tags_family->tags[tag_id][tf]);
            if(is_true == 2)
                break;
        }
    }
    
    return is_true;
}

int check_open_tag (struct tree_list *my_r, struct elements *tree_curr, long ti, int tag_id)
{
    struct tags *tags = my_r->tags;
    int res = 0;
    
    if(
       tags->option[ tree_curr->tree[ tree_curr->index[ti] ].tag_id ] == OPTION_CLEAN_TAGS &&
       tags->option[ tag_id ] != OPTION_CLEAN_TAGS_SAVE
       ){
        return OPTION_CLEAN_TAGS;
    }
    
    if(
       tags->extra[tag_id] == EXTRA_TAG_CLOSE_PRIORITY_FAMILY &&
       tags->extra[ tree_curr->tree[ tree_curr->index[ti] ].tag_id ] == EXTRA_TAG_CLOSE_IF_BLOCK
       ){
        long ir;
        for(ir = ti - 1; ir >= 1; ir--) {
            if(
               tags->family[ tree_curr->tree[ tree_curr->index[ir] ].tag_id ] == tags->family[ tag_id ] &&
               tags->priority[ tree_curr->tree[ tree_curr->index[ir] ].tag_id ] > tags->priority[ tag_id ]
               ){
                return 1;
            }
        }
    }
    
    if(
       tags->extra[tag_id] == EXTRA_TAG_CLOSE_PRIORITY_FAMILY &&
       tags->family[ tree_curr->tree[ tree_curr->index[ti] ].tag_id ] == tags->family[tag_id] &&
       tags->priority[ tree_curr->tree[ tree_curr->index[ti] ].tag_id ] > tags->priority[tag_id]
       ){
        return 2;
    }
    else if(
            tags->extra[tag_id] == EXTRA_TAG_CLOSE_PRIORITY_FAMILY &&
            tags->family[ tree_curr->tree[ tree_curr->index[ti] ].tag_id ] == tags->family[tag_id] &&
            tags->priority[ tree_curr->tree[ tree_curr->index[ti] ].tag_id ] == tags->priority[tag_id]
            ){
        long ir;
        for(ir = ti - 1; ir >= 1; ir--) {
            if(
               tags->family[ tree_curr->tree[ tree_curr->index[ir] ].tag_id ] == tags->family[ tag_id ] &&
               tags->priority[ tree_curr->tree[ tree_curr->index[ir] ].tag_id ] > tags->priority[ tag_id ]
               ){
                return 1;
            }
        }
    }
    
    if(tags->extra[ tree_curr->tree[ tree_curr->index[ti] ].tag_id ] == EXTRA_TAG_CLOSE_FAMILY_LIST && tags->extra[tag_id] == EXTRA_TAG_CLOSE_FAMILY_LIST) {
        struct tags_family *tags_family = my_r->tags_family;
        
        if(tag_id <= tags_family->itags && tags_family->tags[ tree_curr->tree[ tree_curr->ltree ].tag_id ] != 0){
            return check_open_tag_family_tree(tags_family, tree_curr, ti, tag_id);
        }
    }
    else if(
            //4) Закрываются только встречая себя:
            (tags->extra[ tree_curr->tree[ tree_curr->index[ti] ].tag_id ] == EXTRA_TAG_CLOSE_IF_SELF && tree_curr->tree[ tree_curr->index[ti] ].tag_id == tag_id) ||
            //5) Закрываются только при встрече блочных элементов:
            (tags->extra[ tree_curr->tree[ tree_curr->index[ti] ].tag_id ] == EXTRA_TAG_CLOSE_IF_BLOCK && tags->type[tag_id] == TYPE_TAG_BLOCK) ||
            (
             tags->extra[ tree_curr->tree[ tree_curr->index[ti] ].tag_id ] == EXTRA_TAG_CLOSE_IF_SELF_FAMILY &&
             tags->family[tag_id] == tags->family[ tree_curr->tree[ tree_curr->index[ti] ].tag_id ] &&
             tags->family[ tree_curr->tree[ tree_curr->index[ti] ].tag_id ] != 0
             ) ||
            (
             tags->extra[ tree_curr->tree[ tree_curr->index[ti] ].tag_id ] == EXTRA_TAG_CLOSE_IF_SELF_FAMILY &&
             tree_curr->tree[ tree_curr->index[ti] ].tag_id == tag_id
             ) ||
            (
             tags->extra[ tree_curr->tree[ tree_curr->index[ti] ].tag_id ] == EXTRA_TAG_CLOSE_PRIORITY &&
             tags->family[ tree_curr->tree[ tree_curr->index[ti] ].tag_id ] == tags->family[tag_id] &&
             tags->priority[ tree_curr->tree[ tree_curr->index[ti] ].tag_id ] <= tags->priority[tag_id]
             //EXTRA_TAG_CLOSE_PRIORITY
             )
            ) {
        return 1;
    }
    else if(
            tags->type[ tree_curr->tree[ tree_curr->index[ti] ].tag_id ] == TYPE_TAG_BLOCK &&
            tags->priority[ tree_curr->tree[ tree_curr->index[ti] ].tag_id ] != 0 && tags->priority[tag_id] != 0 &&
            tags->priority[ tree_curr->tree[ tree_curr->index[ti] ].tag_id ] >= tags->priority[tag_id]
            ){
        return 2;
    }
    
    return res;
}

void add_to_tree(struct tree_list *my_r, struct elements *tree_curr, long my_buff, long i, int tag_id) {
    struct tags *tags = my_r->tags;
    
    tree_curr->ltree++;
    
    if(tree_curr->is_base == 1) {
        tags->index.tag_count[tag_id]++;
        if(tags->index.tag_count[tag_id] >= tags->index.tag_csize[tag_id]) {
            tags->index.tag_csize[tag_id] += 128;
            tags->index.tag_id[tag_id] = (long *)realloc(tags->index.tag_id[tag_id], sizeof(long) * tags->index.tag_csize[tag_id]);
        }
        
        tags->index.tag_id[tag_id][ tags->index.tag_count[tag_id] ] = tree_curr->ltree;
    }
    
    if(tree_curr->ltree >= tree_curr->ltree_size) {
        tree_curr->ltree_size += 1024;
        tree_curr->tree = (struct html_tree *)realloc(tree_curr->tree, sizeof(struct html_tree) * tree_curr->ltree_size);
        
        if(tree_curr->is_base == 1)
            my_r->list = tree_curr->tree;
    }
    
    tree_curr->tree[tree_curr->ltree].id               = tree_curr->ltree;
    tree_curr->tree[tree_curr->ltree].tag_id           = tag_id;
    tree_curr->tree[tree_curr->ltree].my_id            = my_buff;
    tree_curr->tree[tree_curr->ltree].tag_body_start   = i;
    tree_curr->tree[tree_curr->ltree].tag_body_stop    = -1;
    tree_curr->tree[tree_curr->ltree].tag_stop         = -1;
    tree_curr->tree[tree_curr->ltree].count_element    = 0;
    tree_curr->tree[tree_curr->ltree].count_element_in = 0;
    tree_curr->tree[tree_curr->ltree].count_word       = 0;
    
    if(my_buff > -1) {
        tree_curr->tree[tree_curr->ltree].tag_start = my_r->my[my_buff].start_otag - 1;
    } else {
        tree_curr->tree[tree_curr->ltree].tag_start = -1;
    }
    
    memset(tree_curr->tree[tree_curr->ltree].counts, 0, AI_BUFF);
    memset(tree_curr->tree[tree_curr->ltree].counts_in, 0, AI_BUFF);
    
    tree_curr->lindex++;
    
    if(tree_curr->lindex >= tree_curr->lindex_size) {
        tree_curr->lindex_size += 1024;
        tree_curr->index = (long *)realloc(tree_curr->index, sizeof(long) * tree_curr->lindex_size);
    }
    
    tree_curr->index[tree_curr->lindex] = tree_curr->ltree;
    tree_curr->tree[ tree_curr->ltree ].inc = tree_curr->lindex;
    
    if(tree_curr->lindex > 0) {
        tree_curr->tree[ tree_curr->index[tree_curr->lindex - 1] ].count_element++;
        tree_curr->tree[ tree_curr->index[tree_curr->lindex - 1] ].count_element_in++;
        
        tree_curr->tree[ tree_curr->index[tree_curr->lindex - 1] ].counts[ tags->ai[ tree_curr->tree[ tree_curr->ltree ].tag_id ] ]++;
        tree_curr->tree[ tree_curr->index[tree_curr->lindex - 1] ].counts_in[ tags->ai[ tree_curr->tree[ tree_curr->ltree ].tag_id ] ]++;
    }
}

void add_tag_family(struct tags_family *tags_family, int tag_from, int tag_to) {
    
    if(tags_family->itags_size <= tag_from) {
        tags_family->itags_size += 1024;
        tags_family->tags = (int **)realloc(tags_family->tags, sizeof(int *) * tags_family->itags_size);
        memset(tags_family->tags[tags_family->itags_size - 1024], 0, 1024);
    }
    
    if(tags_family->itags < tag_from) {
        tags_family->itags = tag_from;
    }
    
    int i = -1;
    if(tags_family->tags[tag_from] != 0) {
        while (tags_family->tags[tag_from][++i]){}
        tags_family->tags[tag_from][i] = tag_to;
        tags_family->tags[tag_from][++i] = '\0';
    } else {
        tags_family->tags[tag_from] = (int*)malloc(sizeof(int) * 128);
        tags_family->tags[tag_from][++i] = tag_to;
        tags_family->tags[tag_from][++i] = '\0';
    }
    
    if(tags_family->irtags_size <= tag_to) {
        tags_family->irtags_size += 1024;
        tags_family->rtags = (int **)realloc(tags_family->rtags, sizeof(int *) * tags_family->irtags_size);
        memset(tags_family->rtags[tags_family->irtags_size - 1024], 0, 1024);
    }
    
    if(tags_family->irtags < tag_to) {
        tags_family->irtags = tag_to;
    }
    
    i = -1;
    if(tags_family->rtags[tag_to] != 0) {
        while (tags_family->rtags[tag_to][++i]){}
        tags_family->rtags[tag_to][i] = tag_from;
        tags_family->rtags[tag_to][++i] = '\0';
    } else {
        tags_family->rtags[tag_to] = (int*)malloc(sizeof(int) * 128);
        tags_family->rtags[tag_to][++i] = tag_from;
        tags_family->rtags[tag_to][++i] = '\0';
    }
}

struct tags_family * init_tags_family(struct tags *tags){
    struct tags_family *tags_family = (struct tags_family*)malloc(sizeof(struct tags_family));
    
    tags_family->itags = -1;
    tags_family->itags_size = 2048;
    tags_family->tags = (int **)malloc(sizeof(int *) * tags_family->itags_size);
    memset(tags_family->tags, 0, tags_family->itags_size);
    
    tags_family->irtags = -1;
    tags_family->irtags_size = 2048;
    tags_family->rtags = (int **)malloc(sizeof(int *) * tags_family->irtags_size);
    memset(tags_family->rtags, 0, tags_family->irtags_size);
    
    int tag_id_table = get_tag_id(tags, "table");
    int tag_id_tr = get_tag_id(tags, "tr");
    int tag_id_td = get_tag_id(tags, "td");
    int tag_id_th = get_tag_id(tags, "th");
    
    add_tag_family(tags_family, get_tag_id(tags, "tbody"), tag_id_table);
    add_tag_family(tags_family, get_tag_id(tags, "tfoot"), tag_id_table);
    add_tag_family(tags_family, get_tag_id(tags, "thead"), tag_id_table);
    
    add_tag_family(tags_family, get_tag_id(tags, "colgroup"), tag_id_table);
    
    add_tag_family(tags_family, tag_id_tr, get_tag_id(tags, "tbody"));
    add_tag_family(tags_family, tag_id_tr, get_tag_id(tags, "tfoot"));
    add_tag_family(tags_family, tag_id_tr, get_tag_id(tags, "thead"));
    
    add_tag_family(tags_family, tag_id_td, tag_id_tr);
    add_tag_family(tags_family, tag_id_th, tag_id_tr);
    
    add_tag_family(tags_family, get_tag_id(tags, "col"), get_tag_id(tags, "colgroup"));
    
    add_tag_family(tags_family, get_tag_id(tags, "base"), get_tag_id(tags, "head"));
    add_tag_family(tags_family, get_tag_id(tags, "basefont"), get_tag_id(tags, "head"));
    add_tag_family(tags_family, get_tag_id(tags, "noscript"), get_tag_id(tags, "head"));
    add_tag_family(tags_family, get_tag_id(tags, "script"), get_tag_id(tags, "head"));
    add_tag_family(tags_family, get_tag_id(tags, "meta"), get_tag_id(tags, "head"));
    add_tag_family(tags_family, get_tag_id(tags, "style"), get_tag_id(tags, "head"));
    add_tag_family(tags_family, get_tag_id(tags, "title"), get_tag_id(tags, "head"));
    add_tag_family(tags_family, get_tag_id(tags, "link"), get_tag_id(tags, "head"));
    
    return tags_family;
}

int check_family_exists(struct tags_family *tags_family, int from_id, int to_id) {
    if(tags_family->tags[from_id] == 0)
        return 0;
    
    int tf = -1; int is_true = 0;
    while (tags_family->tags[from_id][++tf]) {
        if(to_id == tags_family->tags[from_id][tf]) {
            is_true = 1; break;
        }
    }
    
    return is_true;
}

int check_struct_level_up(struct tree_list *my_r, struct elements *tree_curr, long my_buff, long i, int tag_id) {
    struct tags_family *tags_family = my_r->tags_family;
    
    long ir; long level = -1;
    for(ir = tree_curr->ltree - 1; ir >= 1; ir--) {
        if(tree_curr->tree[ir].inc < tree_curr->tree[ tree_curr->ltree ].inc && tree_curr->tree[ir].tag_stop == -1) {
            level = ir;
            break;
        }
    }
    
    if(tree_curr->tree[ tree_curr->ltree ].tag_id <= tags_family->itags &&
       tags_family->tags[ tree_curr->tree[ tree_curr->ltree ].tag_id ] != 0
       ){
        int tf = -1; int is_true = 0;
        while (tags_family->tags[ tree_curr->tree[ tree_curr->ltree ].tag_id ][++tf]) {
            if(tree_curr->tree[level].tag_id == tags_family->tags[ tree_curr->tree[ tree_curr->ltree ].tag_id ][tf]) {
                is_true = 1; break;
            }
        }
        
        if(is_true == 0) {
            tree_curr->tree[tree_curr->ltree].tag_id           = tags_family->tags[ tree_curr->tree[ tree_curr->ltree ].tag_id ][0];
            tree_curr->tree[tree_curr->ltree].my_id            = -1;
            tree_curr->tree[tree_curr->ltree].tag_body_start   = tree_curr->tree[tree_curr->ltree].tag_start;
            tree_curr->tree[tree_curr->ltree].count_element    = 0;
            tree_curr->tree[tree_curr->ltree].count_element_in = 0;
            
            check_struct_level_up(my_r, tree_curr, my_buff, i, tree_curr->tree[ tree_curr->ltree ].tag_id);
            add_to_tree(my_r, tree_curr, my_buff, i, tag_id);
        }
    }
    
    if(level == -1)
        return -1;
    
    return tree_curr->tree[level].inc;
}

void check_struct_level_down(struct tree_list *my_r, struct elements *tree_curr, long my_buff, long i, int tag_id) {
    struct tags_family *tags_family = my_r->tags_family;
    
    long ir; long level = -1;
    for(ir = tree_curr->ltree - 1; ir >= 1; ir--) {
        if(tree_curr->tree[ir].inc < tree_curr->tree[ tree_curr->ltree ].inc) {
            level = ir;
            break;
        }
    }
    
    if(
       my_r->tags->extra[ tree_curr->tree[level].tag_id ] == EXTRA_TAG_CLOSE_FAMILY_LIST &&
       tree_curr->tree[level].tag_id <= tags_family->irtags &&
       tags_family->rtags[ tree_curr->tree[level].tag_id ] != 0
       )
    {
        int tf = -1; int is_true = 0;
        while (tags_family->rtags[ tree_curr->tree[level].tag_id ][++tf]) {
            if(tag_id == tags_family->rtags[ tree_curr->tree[level].tag_id ][tf]) {
                is_true = 1; break;
            }
        }
        
        if(is_true == 0) {
            int res = check_open_tag(my_r, tree_curr, level, tags_family->rtags[ tree_curr->tree[level].tag_id ][0]);
            
            tree_curr->tree[tree_curr->ltree].tag_id           = tags_family->rtags[ tree_curr->tree[level].tag_id ][0];
            tree_curr->tree[tree_curr->ltree].my_id            = -1;
            tree_curr->tree[tree_curr->ltree].tag_body_start   = tree_curr->tree[tree_curr->ltree].tag_start;
            tree_curr->tree[tree_curr->ltree].count_element    = 0;
            tree_curr->tree[tree_curr->ltree].count_element_in = 0;
            tree_curr->tree[tree_curr->ltree].inc              -= res;
            
            check_struct_level_down(my_r, tree_curr, my_buff, i, tree_curr->tree[tree_curr->ltree].tag_id);
            
            add_to_tree(my_r, tree_curr, my_buff, i, tag_id);
        }
    }
}

int close_all_element_with_id(struct mem_tag *my, struct elements *tree_curr, long my_buff, long i) {
    int ti; int tag_ool = tree_curr->lindex;
    for(ti = tag_ool; ti >= 1; ti--) {
        if(tree_curr->tree[ tree_curr->index[ti] ].tag_body_stop != -1){
            continue;
        }
        
        if(tree_curr->tree[ tree_curr->index[ti] ].id < tree_curr->tree[ tree_curr->last_element_id ].id) {
            break;
        }
        
        tree_curr->tree[ tree_curr->index[ti] ].tag_body_stop = my[ my_buff ].start_otag - 2;
        tree_curr->tree[ tree_curr->index[ti] ].tag_stop = i - 1;
        
        tree_curr->lindex = tree_curr->tree[ tree_curr->index[ti] ].inc - 1;
        tree_curr->tree[ tree_curr->index[ti - 1] ].count_element_in += tree_curr->tree[ tree_curr->index[ti] ].count_element_in;
        
        int si;
        for(si = 0; si < AI_BUFF; si++) {
            tree_curr->tree[ tree_curr->index[ti - 1] ].counts_in[ si ] += tree_curr->tree[ tree_curr->index[ti] ].counts_in[ si ];
        }
        
        if(tree_curr->tree[ tree_curr->index[ti] ].id == tree_curr->last_element_id) {
            break;
        }
    }
    
    return ti;
}

int close_all_element_by_tag_id(struct mem_tag *my, struct elements *tree_curr, struct tags *tags, int tag_id, long my_buff, long i) {
    int ti; int tag_ool = tree_curr->lindex;
    for(ti = tag_ool; ti >= 1; ti--) {
        if(tree_curr->tree[ tree_curr->index[ti] ].tag_body_stop != -1){
            continue;
        }
        
        if(tags->priority[ tree_curr->tree[ tree_curr->index[ti] ].tag_id ] > tags->priority[ tag_id ]) {
            break;
        }
        
        if(my_buff > 0) {
            tree_curr->tree[ tree_curr->index[ti] ].tag_body_stop = my[ my_buff ].start_otag - 2;
            tree_curr->tree[ tree_curr->index[ti] ].tag_stop = i - 1;
        } else {
            tree_curr->tree[ tree_curr->index[ti] ].tag_stop = i - 1;
            tree_curr->tree[ tree_curr->index[ti] ].tag_body_stop = tree_curr->tree[ tree_curr->index[ti] ].tag_stop;
        }
        
        tree_curr->lindex = tree_curr->tree[ tree_curr->index[ti] ].inc - 1;
        tree_curr->tree[ tree_curr->index[ti - 1] ].count_element_in += tree_curr->tree[ tree_curr->index[ti] ].count_element_in;
        
        int si;
        for(si = 0; si < AI_BUFF; si++) {
            tree_curr->tree[ tree_curr->index[ti - 1] ].counts_in[ si ] += tree_curr->tree[ tree_curr->index[ti] ].counts_in[ si ];
        }
        
        if(tree_curr->tree[ tree_curr->index[ti] ].tag_id == tag_id) {
            break;
        }
    }
    
    return ti;
}

long close_this_jail(struct tree_list *my_r, struct tree_jail *tree_jail, struct elements *tree_curr, long i) {
    long ie, ei;
    
    // закрываем все не закрытые теги внутри изолированной обработки
    int ti; long ni = i - 2;
    for(ti = tree_jail->elements[tree_jail->curr_element].lindex; ti >= 1; ti--) {
        if(tree_jail->elements[tree_jail->curr_element].tree[ tree_jail->elements[tree_jail->curr_element].index[ti] ].tag_body_stop == -1){
            // сохраняем общее количество тегов
            tree_jail->elements[tree_jail->curr_element].tree[ tree_jail->elements[tree_jail->curr_element].index[ti - 1] ].count_element_in +=
            tree_jail->elements[tree_jail->curr_element].tree[ tree_jail->elements[tree_jail->curr_element].index[ti] ].count_element_in;
            
            int si;
            for(si = 0; si < AI_BUFF; si++) {
                tree_jail->elements[tree_jail->curr_element].tree[ tree_jail->elements[tree_jail->curr_element].index[ti - 1] ].counts_in[ si ] +=
                tree_jail->elements[tree_jail->curr_element].tree[ tree_jail->elements[tree_jail->curr_element].index[ti] ].counts_in[ si ];
            }
            
            tree_jail->elements[tree_jail->curr_element].tree[ tree_jail->elements[tree_jail->curr_element].index[ti] ].tag_body_stop = ni;
            tree_jail->elements[tree_jail->curr_element].tree[ tree_jail->elements[tree_jail->curr_element].index[ti] ].tag_stop = ni;
        }
    }
    
    ie = tree_jail->elements[tree_jail->curr_element].prev;
    
    // проверка будет ли входит в последний элемент родителя этот изолированный тег
    int tag_ool = tree_jail->elements[ie].lindex;
    for(ti = tag_ool; ti >= 1; ti--) {
        if(tree_jail->elements[ie].tree[ tree_jail->elements[ie].index[ti] ].tag_body_stop != -1){
            continue;
        }
        
        if(check_open_tag(my_r, &tree_jail->elements[ie], ti, tree_curr->tree[1].tag_id) == 1) {
            continue;
        }
        
        break;
    }
    
    // копируем статистику она архиважна для нас
    // мы типа уверены, что тут только один главный тег
    tree_jail->elements[ie].tree[ tree_jail->elements[ie].index[ti] ].count_element += 1;
    
    tree_jail->elements[ie].tree[ tree_jail->elements[ie].index[ti] ].count_element_in +=
    tree_jail->elements[tree_jail->curr_element].tree[1].count_element_in + 1;
    
    int si;
    for(si = 0; si < AI_BUFF; si++) {
        tree_jail->elements[ie].tree[ tree_jail->elements[ie].index[ti] ].counts_in[ si ] +=
        tree_jail->elements[tree_jail->curr_element].tree[1].counts_in[ si ];
    }
    
    if((tree_jail->elements[ie].ltree + tree_jail->elements[tree_jail->curr_element].ltree) >= tree_jail->elements[ie].ltree_size) {
        tree_jail->elements[ie].ltree_size += 1024 + tree_jail->elements[tree_jail->curr_element].ltree;
        tree_jail->elements[ie].tree = (struct html_tree *)realloc(tree_jail->elements[ie].tree, sizeof(struct html_tree) * tree_jail->elements[ie].ltree_size);
        
        if(tree_jail->elements[ie].is_base == 1)
            my_r->list = tree_jail->elements[ie].tree;
    }
    
    long last_max_id = tree_jail->elements[ie].ltree;
    int tag_id;
    // копирование всех изолированных тегов в родителя
    if(tree_jail->elements[ie].is_base == 1) {
        for(ei = 1; ei <= tree_jail->elements[tree_jail->curr_element].ltree; ei++) {
            tree_jail->elements[ie].ltree++;
            tree_jail->elements[ie].tree[tree_jail->elements[ie].ltree] = tree_jail->elements[tree_jail->curr_element].tree[ei];
            tree_jail->elements[ie].tree[tree_jail->elements[ie].ltree].inc += tree_jail->elements[ie].tree[ tree_jail->elements[ie].index[ti] ].inc;
            tree_jail->elements[ie].tree[tree_jail->elements[ie].ltree].id += last_max_id;
            
            tag_id = tree_jail->elements[ie].tree[tree_jail->elements[ie].ltree].tag_id;
            
            my_r->tags->index.tag_count[tag_id]++;
            if(my_r->tags->index.tag_count[tag_id] >= my_r->tags->index.tag_csize[tag_id]) {
                my_r->tags->index.tag_csize[tag_id] += 128;
                my_r->tags->index.tag_id[tag_id] = (long *)realloc(my_r->tags->index.tag_id[tag_id], sizeof(long) * my_r->tags->index.tag_csize[tag_id]);
            }
            
            my_r->tags->index.tag_id[tag_id][ my_r->tags->index.tag_count[tag_id] ] = tree_jail->elements[ie].tree[tree_jail->elements[ie].ltree].id;
        }
    } else {
        for(ei = 1; ei <= tree_jail->elements[tree_jail->curr_element].ltree; ei++) {
            tree_jail->elements[ie].ltree++;
            tree_jail->elements[ie].tree[tree_jail->elements[ie].ltree] = tree_jail->elements[tree_jail->curr_element].tree[ei];
            tree_jail->elements[ie].tree[tree_jail->elements[ie].ltree].inc += tree_jail->elements[ie].tree[ tree_jail->elements[ie].index[ti] ].inc;
            tree_jail->elements[ie].tree[tree_jail->elements[ie].ltree].id += last_max_id;
        }
    }
    
    return ie;
}

void html_tree(struct tree_list *my_r)
{
    char *html = my_r->html;
    struct tags *tags = my_r->tags;
    
    // инициализируем список тегов
    init_tags(tags);
    
    int tag_id_table = get_tag_id(tags, "table");
    int tag_id_td    = get_tag_id(tags, "td");
    int tag_id_th    = get_tag_id(tags, "th");
    
    int tag_id_html = get_tag_id(tags, "html");
    int tag_id_head = get_tag_id(tags, "head");
    int tag_id_body = get_tag_id(tags, "body");
    
    int tag_id_doctype = get_tag_id(tags, "!doctype");
    
    // ирнициализируем зависимости тегов
    struct tags_family *tags_family = init_tags_family(tags);
    my_r->tags_family = tags_family;
    
    // инициализируем временные буфер для тегов, там хранится их начало, окончание
    long my_buff = -1, my_real_buff = -1;
    long my_buff_size = 1024 * 10;
    struct mem_tag* my = (struct mem_tag *)malloc(sizeof(struct mem_tag) * my_buff_size);
    
    my_r->my = my;
    
    // инициализируем клетку для отдельных структур, таблицы и прочее
    // root находится в нулевом элементе клетки
    struct tree_jail tree_jail;
    tree_jail.lelements = 0;
    tree_jail.lelements_size = 1024;
    tree_jail.elements = (struct elements*)malloc(sizeof(struct elements) * tree_jail.lelements_size);
    
    tree_jail.curr_element = 0;
    
    struct elements *tree_curr;
    tree_curr = &tree_jail.elements[tree_jail.lelements];
    
    // заполняем информацию для root-а
    // это основной элемент, его власть непоколебима
    tree_curr->lindex = 0;
    tree_curr->lindex_size = 1024;
    tree_curr->index = (long *)malloc(sizeof(long) * tree_curr->lindex_size);
    
    tree_curr->ltree = 0;
    tree_curr->ltree_size = 1024 * 10;
    tree_curr->tree = (struct html_tree *)malloc(sizeof(struct html_tree) * tree_curr->ltree_size);
    
    tree_curr->count = -1;
    tree_curr->is_base = 1;
    
    tree_curr->tree[tree_curr->ltree].id               = 0;
    tree_curr->tree[tree_curr->ltree].tag_id           = -1;
    tree_curr->tree[tree_curr->ltree].my_id            = -1;
    tree_curr->tree[tree_curr->ltree].tag_body_start   = 0;
    tree_curr->tree[tree_curr->ltree].tag_body_stop    = -1;
    tree_curr->tree[tree_curr->ltree].tag_start        = 0;
    tree_curr->tree[tree_curr->ltree].tag_stop         = -1;
    tree_curr->tree[tree_curr->ltree].count_element    = 0;
    tree_curr->tree[tree_curr->ltree].count_element_in = 0;
    tree_curr->tree[tree_curr->ltree].count_word       = 0;
    
    memset(tree_curr->tree[tree_curr->ltree].counts, 0, AI_BUFF);
    memset(tree_curr->tree[tree_curr->ltree].counts_in, 0, AI_BUFF);
    
    tree_curr->index[tree_curr->lindex] = tree_curr->ltree;
    tree_curr->tree[tree_curr->ltree].inc = tree_curr->lindex;
    
    tree_curr->next = -1;
    tree_curr->prev = -1;
    tree_curr->last_element_id = -1;
    
    my_r->list = tree_jail.elements[0].tree;
    
    // инициализируем ременные данные для анализа html
    long i = 0, pos = 0, count_tag = 1;
    char nc; long next_tag = 0;
    long text_position = -1;
    
    int is_comment = 0, is_open_key = 0; int spl_word = 0;
    int body_is_open = 0, head_is_open = 0;
    
    while( (nc = html[i++]) ) {
        if(
           (nc == '>' && is_open_key == 1) &&
           (
            (my_buff != -1 && (my[my_buff].qo == '\0' || my[my_buff].qo == ' ')) ||
            (is_comment != 0)
            )
           )
        {
            if(is_comment != 0) {
                if(is_comment == 1 && html[i-2] == '-' && html[i-3] == '-') {
                    is_comment = 0;
                    is_open_key = 0;
                    pos = 0;
                }
                else if(is_comment == 2) {
                    is_comment = 0;
                    is_open_key = 0;
                    pos = 0;
                }
                
                continue;
            }
            
            is_open_key = 0;
            
            if(my_buff == -1)
                continue;
            
            // если пришел закрывающий тег
            if(html[ my[my_buff].start_otag ] == '/') {
                // если тег пустой и небыло данных об окончании
                if(my[my_buff].stop_otag == 0)
                    my[my_buff].stop_otag = i - 2;
                
                int tag_id = cmp_tags(tags, html, &my[my_buff], 1);
                
                if(tag_id == tag_id_head || tag_id == tag_id_body || tag_id == tag_id_html) {
                    pos      = 0;
                    next_tag = 0;
                    my_buff--;
                    continue;
                }
                
                if(tree_curr->next != -1 && tree_curr->last_element_id != -1) {
                    if(tags->family[tag_id] == FAMILY_TABLE) {
                        close_all_element_with_id(my, tree_curr, my_buff, i);
                        
                        tree_curr->last_element_id = -1;
                        
                        tree_jail.curr_element = tree_curr->next;
                        tree_curr->next = -1;
                        tree_curr = &tree_jail.elements[tree_jail.curr_element];
                    }
                }
                
                if(tree_curr->lindex > -1 && tag_id > -1) {
                    // проверяем открывался ли вообще пришедший тег
                    int ti; int is_open = 0;
                    for(ti = tree_curr->lindex; ti >= 1; ti--) {
                        if(tags->priority[ tree_curr->tree[ tree_curr->index[ti] ].tag_id ] > tags->priority[tag_id]){
                            break;
                        }
                        
                        if(tag_id == tree_curr->tree[ tree_curr->index[ti] ].tag_id && tree_curr->tree[ tree_curr->index[ti] ].tag_stop == -1) {
                            is_open = 1;
                            break;
                        }
                    }
                    
                    // проверка евляется ли тег "простым", то есть, тег съедал все внутри себя, а теперь пришло его закрытие
                    // для таких тегов закрытием считается самое первое попавшееся, не важно что было до этого (хоть он 9000+ раз открывался внутри)
                    if(tree_curr->ltree > 0) {
                        if(tags->extra[ tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].tag_id ] == EXTRA_TAG_SIMPLE &&
                           tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].tag_body_stop == -1 &&
                           tag_id != tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].tag_id
                           ) {
                            pos      = 0;
                            next_tag = 0;
                            my_buff--;
                            continue;
                        }
                    }
                    
                    // пришедший закрывающий тег открывался ранее и еще не был закрыт, ну что же, закроем его
                    if(is_open == 1) {
                        // если пришедший закрывающий тег не равен последнему то нужен анализ как закрыть предшественников
                        if(tag_id != tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].tag_id) {
                            int ti; long min_id = 0;
                            for(ti = tree_curr->lindex; ti >= 1; ti--) {
                                
                                // если пришедший закрывающий тег является простым, но внутри его строится структура
                                // такой так же закроется сразу же как пришло его закрытие, и не важно сколько ему подобных было открыто внутри его
                                if(tags->extra[tag_id] == EXTRA_TAG_SIMPLE_TREE && tree_curr->tree[ tree_curr->index[ti] ].tag_body_stop == -1) {
                                    if(min_id == 0) {
                                        int oi;
                                        for(oi = 1; oi <= tree_curr->lindex; oi++) {
                                            if(tree_curr->tree[ tree_curr->index[oi] ].tag_id == tag_id && tree_curr->tree[ tree_curr->index[oi] ].tag_stop == -1) {
                                                min_id = tree_curr->tree[ tree_curr->index[oi] ].id;
                                                break;
                                            }
                                        }
                                    }
                                    
                                    tree_curr->tree[ tree_curr->index[ti] ].tag_body_stop = my[ my_buff ].start_otag - 2;
                                    tree_curr->tree[ tree_curr->index[ti] ].tag_stop = i - 1;
                                    
                                    // сохраняем общее количество тегов
                                    tree_curr->tree[ tree_curr->index[ti - 1] ].count_element_in += tree_curr->tree[ tree_curr->index[ti] ].count_element_in;
                                    
                                    int si;
                                    for(si = 0; si < AI_BUFF; si++) {
                                        tree_curr->tree[ tree_curr->index[ti - 1] ].counts_in[ si ] += tree_curr->tree[ tree_curr->index[ti] ].counts_in[ si ];
                                    }
                                    
                                    if(min_id == tree_curr->tree[ tree_curr->index[ti] ].id)
                                        tree_curr->lindex--;
                                    break;
                                }
                                
                                // проверка на приоритет тегов
                                if(tags->priority[ tree_curr->tree[ tree_curr->index[ti] ].tag_id ] > tags->priority[tag_id]){
                                    break;
                                }
                                else
                                    if(tag_id == tree_curr->tree[ tree_curr->index[ti] ].tag_id && tree_curr->tree[ tree_curr->index[ti] ].tag_body_stop == -1) {
                                        tree_curr->tree[ tree_curr->index[ti] ].tag_body_stop = my[ my_buff ].start_otag - 2;
                                        tree_curr->tree[ tree_curr->index[ti] ].tag_stop = i - 1;
                                        
                                        // сохраняем общее количество тегов
                                        tree_curr->tree[ tree_curr->index[ti - 1] ].count_element_in += tree_curr->tree[ tree_curr->index[ti] ].count_element_in;
                                        
                                        int si;
                                        for(si = 0; si < AI_BUFF; si++) {
                                            tree_curr->tree[ tree_curr->index[ti - 1] ].counts_in[ si ] += tree_curr->tree[ tree_curr->index[ti] ].counts_in[ si ];
                                        }
                                        
                                        tree_curr->lindex--;
                                        break;
                                    }
                                    else if(tree_curr->tree[ tree_curr->index[ti] ].tag_body_stop == -1){
                                        tree_curr->tree[ tree_curr->index[ti] ].tag_body_stop = my[ my_buff ].start_otag - 2;
                                        tree_curr->tree[ tree_curr->index[ti] ].tag_stop = i - 1;
                                    }
                                
                                if(tags->priority[ tree_curr->tree[ tree_curr->index[ti] ].tag_id ] <= tags->priority[tag_id]) {
                                    tree_curr->tree[ tree_curr->index[ti] ].tag_body_stop = my[ my_buff ].start_otag - 2;
                                    tree_curr->tree[ tree_curr->index[ti] ].tag_stop = i - 1;
                                }
                                
                                // сохраняем общее количество тегов
                                tree_curr->tree[ tree_curr->index[ti - 1] ].count_element_in += tree_curr->tree[ tree_curr->index[ti] ].count_element_in;
                                
                                int si;
                                for(si = 0; si < AI_BUFF; si++) {
                                    tree_curr->tree[ tree_curr->index[ti - 1] ].counts_in[ si ] += tree_curr->tree[ tree_curr->index[ti] ].counts_in[ si ];
                                }
                                
                                // уменьшаем уровень дерева
                                tree_curr->lindex--;
                            }
                        } else {
                            tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].tag_body_stop = my[ my_buff ].start_otag - 2;
                            tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].tag_stop = i - 1;
                            
                            // сохраняем общее количество тегов
                            tree_curr->tree[ tree_curr->index[tree_curr->lindex - 1] ].count_element_in +=
                            tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].count_element_in;
                            
                            int si;
                            for(si = 0; si < AI_BUFF; si++) {
                                tree_curr->tree[ tree_curr->index[tree_curr->lindex - 1] ].counts_in[ si ] +=
                                tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].counts_in[ si ];
                            }
                            
                            // уменьшаем уровень дерева
                            tree_curr->lindex--;
                        }
                    }
                }
                
                // если мы в решетке, то есть идет изолированная обработка тега и он закрылся то переносим данные в родителя
                if(tree_curr->is_base == 0 && tree_curr->tree[1].tag_stop != -1) {
                    long ie = close_this_jail(my_r, &tree_jail, tree_curr, i);
                    
                    // устанавливаем как основной предыдущий элемент
                    tree_jail.curr_element = ie;
                    tree_curr = &tree_jail.elements[ie];
                }
                
                // если мы на время возвращались к родителю и тег ради которого возвращались закрылся то переходим на уровень выше
                //                if(tree_curr->last_element_id != -1 && tree_curr->tree[tree_curr->last_element_id].tag_stop != -1) {
                //                    tree_curr->last_element_id = -1;
                //
                //                    tree_jail.curr_element = tree_curr->next;
                //                    tree_curr->next = -1;
                //                    tree_curr = &tree_jail.elements[tree_jail.curr_element];
                //                }
                
                my_buff--;
            }
            else {
                // если тег сразу закрылся "<span>" то проверяем тут пропускать его или нет
                if(my[my_buff].stop_otag == 0) {
                    // если тег пустой и небыло данных об окончании
                    my[my_buff].stop_otag = i - 2;
                }
                
                int tag_id = cmp_tags(tags, html, &my[my_buff], 0);
                
                if(tag_id == tag_id_doctype) {
                    if(tree_curr->is_base == 1 && tree_curr->ltree == 0) {
                        add_to_tree(my_r, tree_curr, my_buff, i, tag_id_doctype);
                        
                        long si;
                        for(si = 2; si <= my_r->my[my_buff].lparams; si++) {
                            free(my_r->my[my_buff].params[si].key);
                            free(my_r->my[my_buff].params[si].value);
                        }
                        
                        if(my_r->my[my_buff].lparams > 1)
                            my_r->my[my_buff].lparams = 1;
                        
                        close_all_element_by_tag_id(my, tree_curr, tags, tag_id_doctype, my_buff, i);
                    }
                    
                    pos      = 0;
                    next_tag = 0;
                    continue;
                }
                
                if(tag_id == tag_id_html) {
                    struct html_tree *tag_html = get_element_by_tag_id(my_r, tag_id_html, 0);
                    
                    if(tag_html == NULL) {
                        add_to_tree(my_r, tree_curr, -1, i, tag_id_html);
                        tree_curr->tree[ tree_curr->ltree ].inc = 1;
                        tag_html = get_element_by_tag_id(my_r, tag_id_html, 0);
                    }
                    
                    if(tag_html->my_id == -1) {
                        tag_html->my_id = my_buff;
                    }
                    else {
                        if(my[my_buff].lparams > -1) {
                            long lp;
                            for(lp = 0; lp <= my[my_buff].lparams; lp++) {
                                my[tag_html->my_id].lparams++;
                                
                                if(my[tag_html->my_id].lparams >= my[tag_html->my_id].lparams_size) {
                                    my[tag_html->my_id].lparams_size += 256;
                                    my[tag_html->my_id].params = (struct mem_params *)realloc(my[tag_html->my_id].params, sizeof(struct mem_params) * my[tag_html->my_id].lparams_size);
                                }
                                
                                my[tag_html->my_id].params[my[tag_html->my_id].lparams] = my[my_buff].params[lp];
                            }
                            
                            my[my_buff].lparams = -1;
                        }
                    }
                    
                    pos      = 0;
                    next_tag = 0;
                    continue;
                }
                else if(tag_id == tag_id_head && head_is_open == 1) {
                    pos      = 0;
                    next_tag = 0;
                    continue;
                }
                else if(tag_id == tag_id_body && body_is_open == 1) {
                    struct html_tree *tag_html = get_element_by_tag_id(my_r, tag_id_body, 0);
                    
                    if(tag_html->my_id == -1) {
                        tag_html->my_id = my_buff;
                    }
                    else {
                        if(my[my_buff].lparams > -1) {
                            long lp;
                            for(lp = 0; lp <= my[my_buff].lparams; lp++) {
                                my[tag_html->my_id].lparams++;
                                
                                if(my[tag_html->my_id].lparams >= my[tag_html->my_id].lparams_size) {
                                    my[tag_html->my_id].lparams_size += 256;
                                    my[tag_html->my_id].params = (struct mem_params *)realloc(my[tag_html->my_id].params, sizeof(struct mem_params) * my[tag_html->my_id].lparams_size);
                                }
                                
                                my[tag_html->my_id].params[my[tag_html->my_id].lparams] = my[my_buff].params[lp];
                            }
                            
                            my[my_buff].lparams = -1;
                        }
                    }
                    
                    pos      = 0;
                    next_tag = 0;
                    continue;
                }
                
                int body_check = 1;
                
                if(head_is_open == 0) {
                    int is_in = check_family_exists(tags_family, tag_id, tag_id_head);
                    if(is_in == 1 && tag_id != tag_id_head) {
                        struct html_tree *tag_html = get_element_by_tag_id(my_r, tag_id_html, 0);
                        if(tag_html == NULL) {
                            add_to_tree(my_r, tree_curr, -1, 0, tag_id_html);
                        }
                        
                        struct html_tree *tag_head = get_element_by_tag_id(my_r, tag_id_head, 0);
                        if(tag_head == NULL) {
                            add_to_tree(my_r, tree_curr, -1, 0, tag_id_head);
                            tree_curr->tree[ tree_curr->ltree ].inc = 2;
                        }
                        
                        head_is_open = 1;
                        body_check   = 0;
                    }
                    else if(is_in == 0 && body_is_open == 0) {
                        struct html_tree *tag_html = get_element_by_tag_id(my_r, tag_id_html, 0);
                        if(tag_html == NULL) {
                            add_to_tree(my_r, tree_curr, -1, 0, tag_id_html);
                        }
                    }
                    
                    if(tag_id == tag_id_head) {
                        head_is_open = 1;
                        body_check   = 0;
                    }
                }
                
                if(body_is_open == 0 && body_check == 1) {
                    int is_in = check_family_exists(tags_family, tag_id, tag_id_head);
                    if(is_in == 0 && tag_id != tag_id_body) {
                        struct html_tree *tag_html = get_element_by_tag_id(my_r, tag_id_html, 0);
                        if(tag_html == NULL) {
                            add_to_tree(my_r, tree_curr, -1, 0, tag_id_html);
                        }
                        
                        struct html_tree *tag_head = get_element_by_tag_id(my_r, tag_id_head, 0);
                        if(tag_head == NULL) {
                            add_to_tree(my_r, tree_curr, -1, 0, tag_id_head);
                            tree_curr->tree[ tree_curr->ltree ].inc = 2;
                        }
                        
                        close_all_element_by_tag_id(my, tree_curr, tags, tag_id_head, my_buff, i);
                        add_to_tree(my_r, tree_curr, -1, 0, tag_id_body);
                        //tree_curr->tree[ tree_curr->ltree ].inc = 2;
                        
                        body_is_open = 1;
                    }
                    else if(is_in == 0) {
                        struct html_tree *tag_html = get_element_by_tag_id(my_r, tag_id_html, 0);
                        if(tag_html == NULL) {
                            add_to_tree(my_r, tree_curr, -1, 0, tag_id_html);
                        }
                        
                        struct html_tree *tag_head = get_element_by_tag_id(my_r, tag_id_head, 0);
                        if(tag_head == NULL) {
                            add_to_tree(my_r, tree_curr, -1, 0, tag_id_head);
                            tree_curr->tree[ tree_curr->ltree ].inc = 2;
                        }
                    }
                    
                    if(tag_id == tag_id_body) {
                        body_is_open = 1;
                    }
                }
                
                // TYPE_TAG_SIMPLE
                if(tree_curr->ltree > 0) {
                    if(
                       tags->extra[ tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].tag_id ] == EXTRA_TAG_SIMPLE &&
                       tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].tag_stop == -1
                       ){
                        pos      = 0;
                        next_tag = 0;
                        
                        continue;
                    }
                }
                
                if(tree_curr->next != -1 && tree_curr->last_element_id != -1) {
                    if(tags->family[tag_id] == FAMILY_TABLE) {
                        close_all_element_with_id(my, tree_curr, my_buff, i);
                        
                        tree_curr->last_element_id = -1;
                        
                        tree_jail.curr_element = tree_curr->next;
                        tree_curr->next = -1;
                        tree_curr = &tree_jail.elements[tree_jail.curr_element];
                    }
                }
                
                if(tree_curr->is_base == 0) {
                    // проверка на расположение пришедшего элемента, если он не внутри тега TD ил TH то переносим её на уровень ниже
                    if(tree_jail.family == FAMILY_TABLE) {
                        if(
                           tags->family[tag_id] != FAMILY_TABLE &&
                           tags->family[tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].tag_id] == FAMILY_TABLE &&
                           tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].tag_id != tag_id_td &&
                           tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].tag_id != tag_id_th
                           ){
                            long next_element = tree_jail.curr_element;
                            
                            tree_jail.curr_element = tree_curr->prev;
                            tree_curr = &tree_jail.elements[tree_jail.curr_element];
                            tree_curr->last_element_id = tree_curr->ltree + 1;
                            tree_curr->next = next_element;
                        }
                    }
                }
                
                // отлавливаем таблицу, если тег является таблицей то создаем новый изолированный уровень для ее обработки
                if(tag_id_table == tag_id) {
                    // проверка на расположение таблицы, если она не внутри тега TD ил TH то переносим её на уровень ниже
                    if(
                       tree_curr->is_base == 0 &&
                       tags->family[tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].tag_id] == FAMILY_TABLE &&
                       tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].tag_id != tag_id_td &&
                       tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].tag_id != tag_id_th
                       ) {
                        long ie = close_this_jail(my_r, &tree_jail, tree_curr, i);
                        
                        tree_jail.curr_element = ie;
                        tree_curr = &tree_jail.elements[ie];
                    }
                    
                    long prev_element = tree_jail.curr_element;
                    
                    tree_jail.lelements++;
                    tree_jail.family = FAMILY_TABLE;
                    
                    tree_jail.curr_element = tree_jail.lelements;
                    
                    if(tree_jail.lelements == tree_jail.lelements_size) {
                        tree_jail.lelements_size += 1024;
                        tree_jail.elements = (struct elements*)realloc(tree_jail.elements, tree_jail.lelements_size);
                    }
                    
                    tree_curr = &tree_jail.elements[tree_jail.lelements];
                    
                    // для каждой новой клетки создаем root эллемент
                    
                    tree_curr->lindex = 0;
                    tree_curr->ltree = 0;
                    
                    tree_curr->lindex_size = 1024;
                    tree_curr->index = (long *)malloc(sizeof(long) * tree_curr->lindex_size);
                    
                    tree_curr->ltree_size = 1024 * 10;
                    tree_curr->tree = (struct html_tree *)malloc(sizeof(struct html_tree) * tree_curr->ltree_size);
                    
                    tree_curr->count = -1;
                    tree_curr->is_base = 0;
                    
                    tree_curr->tree[tree_curr->ltree].id               = 0;
                    tree_curr->tree[tree_curr->ltree].tag_id           = -1;
                    tree_curr->tree[tree_curr->ltree].my_id            = -1;
                    tree_curr->tree[tree_curr->ltree].tag_body_start   = 0;
                    tree_curr->tree[tree_curr->ltree].tag_body_stop    = -1;
                    tree_curr->tree[tree_curr->ltree].tag_start        = 0;
                    tree_curr->tree[tree_curr->ltree].tag_stop         = -1;
                    tree_curr->tree[tree_curr->ltree].count_element    = 0;
                    tree_curr->tree[tree_curr->ltree].count_element_in = 0;
                    tree_curr->tree[tree_curr->ltree].count_word       = 0;
                    
                    memset(tree_curr->tree[tree_curr->ltree].counts, 0, AI_BUFF);
                    memset(tree_curr->tree[tree_curr->ltree].counts_in, 0, AI_BUFF);
                    
                    tree_curr->index[tree_curr->lindex] = tree_curr->ltree;
                    tree_curr->tree[tree_curr->ltree].inc = tree_curr->lindex;
                    
                    tree_curr->prev = prev_element;
                    tree_curr->next = -1;
                    tree_curr->last_element_id = -1;
                }
                
                // если пришел элемент таблицы, но таблица не была открыта то забираем из него текст, а элемент пропускаем
                if(tags->family[tag_id] == FAMILY_TABLE) {
                    if(tree_jail.curr_element == 0) {
                        pos      = 0;
                        next_tag = 0;
                        continue;
                    }
                }
                
                tree_curr->ltree++;
                
                if(tree_curr->is_base == 1) {
                    tags->index.tag_count[tag_id]++;
                    if(tags->index.tag_count[tag_id] >= tags->index.tag_csize[tag_id]) {
                        tags->index.tag_csize[tag_id] += 128;
                        tags->index.tag_id[tag_id] = (long *)realloc(tags->index.tag_id[tag_id], sizeof(long) * tags->index.tag_csize[tag_id]);
                    }
                    
                    tags->index.tag_id[tag_id][ tags->index.tag_count[tag_id] ] = tree_curr->ltree;
                }
                
                if(tree_curr->ltree >= tree_curr->ltree_size) {
                    tree_curr->ltree_size += 1024;
                    tree_curr->tree = (struct html_tree *)realloc(tree_curr->tree, sizeof(struct html_tree) * tree_curr->ltree_size);
                    
                    if(tree_curr->is_base == 1)
                        my_r->list = tree_curr->tree;
                }
                
                tree_curr->tree[tree_curr->ltree].id               = tree_curr->ltree;
                tree_curr->tree[tree_curr->ltree].tag_id           = tag_id;
                tree_curr->tree[tree_curr->ltree].my_id            = my_buff;
                tree_curr->tree[tree_curr->ltree].tag_body_start   = i;
                tree_curr->tree[tree_curr->ltree].tag_body_stop    = -1;
                tree_curr->tree[tree_curr->ltree].tag_start        = my[my_buff].start_otag - 1;
                tree_curr->tree[tree_curr->ltree].tag_stop         = -1;
                tree_curr->tree[tree_curr->ltree].count_element    = 0;
                tree_curr->tree[tree_curr->ltree].count_element_in = 0;
                tree_curr->tree[tree_curr->ltree].count_word       = 0;
                
                memset(tree_curr->tree[tree_curr->ltree].counts, 0, AI_BUFF);
                memset(tree_curr->tree[tree_curr->ltree].counts_in, 0, AI_BUFF);
                
                if(tree_curr->ltree > 0) {
                    int ti, res = 0; int tag_ool = tree_curr->lindex;
                    for(ti = tag_ool; ti >= 1; ti--) {
                        if(tree_curr->tree[ tree_curr->index[ti] ].tag_body_stop != -1){
                            continue;
                        }
                        
                        res = check_open_tag(my_r, tree_curr, ti, tag_id);
                        
                        if(res == 1 || (tags->option[tree_curr->tree[ tree_curr->index[ti] ].tag_id] == OPTION_CLEAN_TAGS && tags->option[tag_id] == OPTION_CLEAN_TAGS))
                        {
                            int ri; int tag_oole = tree_curr->lindex;
                            for(ri = tag_oole; ri > ti; ri--) {
                                if(tree_curr->tree[ tree_curr->index[ri] ].tag_body_stop != -1){
                                    continue;
                                }
                                // сохраняем общее количество тегов
                                tree_curr->tree[ tree_curr->index[ri - 1] ].count_element_in += tree_curr->tree[ tree_curr->index[ri] ].count_element_in;
                                
                                int si;
                                for(si = 0; si < AI_BUFF; si++) {
                                    tree_curr->tree[ tree_curr->index[ri - 1] ].counts_in[ si ] += tree_curr->tree[ tree_curr->index[ri] ].counts_in[ si ];
                                }
                                
                                tree_curr->tree[ tree_curr->index[ri] ].tag_body_stop = my[ my_buff ].start_otag - 2;
                                tree_curr->tree[ tree_curr->index[ri] ].tag_stop = i - 1;
                            }
                            
                            tree_curr->tree[ tree_curr->index[ti] ].tag_body_stop = my[ my_buff ].start_otag - 2;
                            tree_curr->tree[ tree_curr->index[ti] ].tag_stop = i - 1;
                            
                            tree_curr->lindex = tree_curr->tree[ tree_curr->index[ti] ].inc - 1;
                            
                            // сохраняем общее количество тегов
                            tree_curr->tree[ tree_curr->index[ti - 1] ].count_element_in += tree_curr->tree[ tree_curr->index[ti] ].count_element_in;
                            
                            int si;
                            for(si = 0; si < AI_BUFF; si++) {
                                tree_curr->tree[ tree_curr->index[ti - 1] ].counts_in[ si ] += tree_curr->tree[ tree_curr->index[ti] ].counts_in[ si ];
                            }
                        }
                        else if(res == 2) {
                            break;
                        }
                        
                        if(res > OPTION_NULL) {
                            break;
                        }
                    }
                    
                    if(res > OPTION_NULL) {
                        if(res == OPTION_CLEAN_TAGS) {
                            tree_curr->tree[tree_curr->ltree].id             = -1;
                            tree_curr->tree[tree_curr->ltree].tag_id         = -1;
                            tree_curr->tree[tree_curr->ltree].my_id          = -1;
                            tree_curr->tree[tree_curr->ltree].tag_body_start = -1;
                            tree_curr->tree[tree_curr->ltree].tag_start      = -1;
                            
                            if(tree_curr->is_base == 1)
                                tags->index.tag_count[tag_id]--;
                            
                            tree_curr->ltree--;
                            
                            pos      = 0;
                            next_tag = 0;
                            continue;
                        }
                    }
                }
                
                tree_curr->lindex++;
                
                if(tree_curr->lindex == tree_curr->lindex_size) {
                    tree_curr->lindex_size += 1024;
                    tree_curr->index = (long *)realloc(tree_curr->index, sizeof(long) * tree_curr->lindex_size);
                }
                
                tree_curr->index[tree_curr->lindex] = tree_curr->ltree;
                tree_curr->tree[ tree_curr->ltree ].inc = tree_curr->lindex;
                
                // собираем статистику для пред. эллементов
                if(tree_curr->lindex > 0) {
                    tree_curr->tree[ tree_curr->index[tree_curr->lindex - 1] ].count_element++;
                    tree_curr->tree[ tree_curr->index[tree_curr->lindex - 1] ].count_element_in++;
                    
                    tree_curr->tree[ tree_curr->index[tree_curr->lindex - 1] ].counts[ tags->ai[ tree_curr->tree[ tree_curr->ltree ].tag_id ] ]++;
                    tree_curr->tree[ tree_curr->index[tree_curr->lindex - 1] ].counts_in[ tags->ai[ tree_curr->tree[ tree_curr->ltree ].tag_id ] ]++;
                }
                
                // Одиночные теги, не требуют закрытия и потому мы закрываем их сразу
                if((tags->type[ tag_id ] == TYPE_TAG_ONE && tags->extra[ tag_id ] == 0) || tags->extra[ tag_id ] == EXTRA_TAG_CLOSE_NOW) {
                    tree_curr->tree[ tree_curr->ltree ].tag_body_stop = tree_curr->tree[ tree_curr->ltree ].tag_body_start;
                    tree_curr->tree[ tree_curr->ltree ].tag_stop = i - 1;
                    tree_curr->lindex--;
                }
                
                // если текущий тег евляется табличным (из семейства таблиц) то смотрим и востанавливаем его структуру
                if(tags->family[tag_id] == FAMILY_TABLE) {
                    if(tree_jail.curr_element != 0) {
                        check_struct_level_up(my_r, tree_curr, my_buff, i, tag_id);
                    }
                } else {
                    if(tree_jail.curr_element != 0) {
                        check_struct_level_down(my_r, tree_curr, my_buff, i, tag_id);
                    }
                }
                
                if(tree_curr->is_base == 0 && tree_curr->tree[1].tag_stop != -1) {
                    long ie = close_this_jail(my_r, &tree_jail, tree_curr, i);
                    
                    tree_jail.curr_element = ie;
                    tree_curr = &tree_jail.elements[ie];
                }
                
                // если текущая решетка была вызвана для добавления не нужных данных из последующей, и данные эти закрыты то возвращаемся к ней
                //                if(tree_curr->last_element_id != -1 && tree_curr->tree[tree_curr->last_element_id].tag_stop != -1) {
                //                    tree_curr->last_element_id = -1;
                //
                //                    tree_jail.curr_element = tree_curr->next;
                //                    tree_curr->next = -1;
                //
                //                    tree_curr = &tree_jail.elements[tree_jail.curr_element];
                //                }
            }
            
            pos      = 0;
            next_tag = 0;
            
            continue;
        }
        
        switch (pos) {
            case 0:
                if(nc == '<' && ((html[i] >= 'a' && html[i] <= 'z') || (html[i] >= 'A' && html[i] <= 'Z') || html[i] == '/' || html[i] == '!')) {
                    is_open_key = 1;
                    
                    if(tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].tag_id != -1 &&
                       tags->extra[ tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].tag_id ] == EXTRA_TAG_SIMPLE &&
                       tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].tag_stop == -1
                       ) {
                        if(html[i] == '!'){
                            if(html[i+1] == '-' && html[i+2] == '-') {
                                is_comment = 1;
                            } else {
                                is_comment = 2;
                            }
                            
                            pos = 6;
                            break;
                        }
                        
                        int tl = 0, is_on = 1; long tu = 0;
                        while (tags->name[ tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].tag_id ][++tl]) {
                            tu = tl + i + 1;
                            if(tags->name[ tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].tag_id ][tl] != html[tu]) {
                                is_on = 0;
                                break;
                            }
                            else if(html[tu] == '\0') {
                                is_on = 0;
                                break;
                            }
                        }
                        
                        if(is_on == 0) {
                            break;
                        }
                    }
                    
                    if(tree_curr->tree[ tree_curr->ltree ].tag_id == DEFAULT_TAG_ID && tree_curr->tree[ tree_curr->ltree ].tag_body_stop == -1) {
                        tree_curr->tree[ tree_curr->ltree ].tag_body_stop  = i - 2;
                        tree_curr->tree[ tree_curr->ltree ].tag_stop = tree_curr->tree[ tree_curr->ltree ].tag_body_stop;
                        
                        // если текущая решетка была вызвана для добавления не нужных данных из последующей, и данные эти закрыты то возвращаемся к ней
                        // это нужно для того, что бы правельно закрылся текстовый элемент (таг_ид 0) если он оказался между табличными тегами, но не в TD или TH
                        //                        if(tree_curr->last_element_id != -1 && tree_curr->tree[tree_curr->last_element_id].tag_stop != -1) {
                        //                            tree_curr->last_element_id = -1;
                        //
                        //                            tree_jail.curr_element = tree_curr->next;
                        //                            tree_curr->next = -1;
                        //
                        //                            tree_curr = &tree_jail.elements[tree_jail.curr_element];
                        //                        }
                    }
                    
                    text_position = -1;
                    
                    if(html[i] == '!'){
                        if(html[i+1] == '-' && html[i+2] == '-') {
                            is_comment = 1;
                        } else {
                            is_comment = 2;
                        }
                        
                        pos = 6;
                        break;
                    }
                    
                    my_buff++;
                    my_real_buff = my_buff;
                    
                    if(count_tag != my_buff) {
                        count_tag = my_buff;
                        
                        if(my_buff_size <= my_buff) {
                            my_buff_size += 1024;
                            my = (struct mem_tag *)realloc(my, sizeof(struct mem_tag) * my_buff_size);
                            my_r->my = my;
                        }
                        
                        my[my_buff].lparams_size = 256;
                        my[my_buff].params = (struct mem_params *)malloc(sizeof(struct mem_params) * my[my_buff].lparams_size);
                    }
                    
                    my[my_buff].stop_otag = 0;
                    
                    my[my_buff].qo = '\0';
                    my[my_buff].qol = 0;
                    
                    my[my_buff].lparams = -1;
                    
                    next_tag = 0;
                    
                    pos = 1;
                    my[my_buff].start_otag = i;
                    
                    spl_word = 0;
                }
                else {
                    if(text_position == -1)
                        text_position = i - 1;
                    
                    if(nc != ' ' && (nc < '\x09' || nc > '\x0D') && (tree_curr->tree[ tree_curr->ltree ].tag_id != DEFAULT_TAG_ID ||
                                                                     (tree_curr->tree[ tree_curr->ltree ].tag_id == DEFAULT_TAG_ID && tree_curr->tree[ tree_curr->ltree ].tag_body_stop != -1)
                                                                     )) {
                        int inc_offset = 0;
                        
                        // если у нас текстовый элемент и он находится не в TD или TH то переносим его в родителя
                        if(tree_curr->is_base == 0) {
                            if(tree_jail.family == FAMILY_TABLE) {
                                if(
                                   tags->family[tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].tag_id] == FAMILY_TABLE &&
                                   tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].tag_id != tag_id_td &&
                                   tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].tag_id != tag_id_th
                                   ){
                                    long next_element = tree_jail.curr_element;
                                    
                                    tree_jail.curr_element = tree_curr->prev;
                                    tree_curr = &tree_jail.elements[tree_jail.curr_element];
                                    tree_curr->last_element_id = tree_curr->ltree + 1;
                                    tree_curr->next = next_element;
                                    
                                    if(tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].tag_id != tag_id_td &&
                                       tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].tag_id != tag_id_th &&
                                       tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].tag_id != -1
                                       ){
                                        // проверка будет ли входит в последний элемент родителя этот изолированный тег
                                        int ti;
                                        int tag_ool = tree_jail.elements[tree_jail.curr_element].lindex;
                                        for(ti = tag_ool; ti >= 1; ti--) {
                                            if(tree_curr->tree[ tree_curr->index[ti] ].tag_body_stop != -1){
                                                continue;
                                            }
                                            
                                            if(check_open_tag(my_r, tree_curr, ti, tag_id_table) == 1) {
                                                continue;
                                            }
                                            
                                            break;
                                        }
                                        
                                        inc_offset = tree_jail.elements[tree_jail.curr_element].tree[ tree_jail.elements[tree_jail.curr_element].index[ti] ].inc + 1;
                                    }
                                }
                            }
                        }
                        
                        if(body_is_open == 0 && tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].tag_id == tag_id_head) {
                            close_all_element_by_tag_id(my, tree_curr, tags, tag_id_head, my_buff, i);
                            add_to_tree(my_r, tree_curr, -1, 0, tag_id_body);
                            
                            body_is_open = 1;
                        }
                        
                        tree_curr->ltree++;
                        
                        if(tree_curr->ltree >= tree_curr->ltree_size) {
                            tree_curr->ltree_size += 1024;
                            tree_curr->tree = (struct html_tree *)realloc(tree_curr->tree, sizeof(struct html_tree) * tree_curr->ltree_size);
                            
                            if(tree_curr->is_base == 1)
                                my_r->list = tree_curr->tree;
                        }
                        
                        tree_curr->tree[tree_curr->ltree].id     = tree_curr->ltree;
                        
                        tree_curr->tree[tree_curr->ltree].tag_id = DEFAULT_TAG_ID;
                        tree_curr->tree[tree_curr->ltree].my_id  = -1;
                        
                        tree_curr->tree[tree_curr->ltree].tag_body_start = text_position;
                        tree_curr->tree[tree_curr->ltree].tag_body_stop  = -1;
                        
                        tree_curr->tree[tree_curr->ltree].tag_start = tree_curr->tree[ tree_curr->ltree ].tag_body_start;
                        tree_curr->tree[tree_curr->ltree].tag_stop  = -1;
                        
                        tree_curr->tree[tree_curr->ltree].count_element    = 0;
                        tree_curr->tree[tree_curr->ltree].count_element_in = 0;
                        tree_curr->tree[tree_curr->ltree].count_word       = 0;
                        
                        if(inc_offset == 0) {
                            tree_curr->tree[ tree_curr->ltree ].inc = tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].inc + 1;
                        }
                        else {
                            tree_curr->tree[ tree_curr->ltree ].inc = inc_offset;
                        }
                        
                        memset(tree_curr->tree[ tree_curr->ltree ].counts, 0, AI_BUFF);
                        memset(tree_curr->tree[ tree_curr->ltree ].counts_in, 0, AI_BUFF);
                    }
                    
                    if(spl_word == 0 && nc != ' ' && nc != '\n' && nc != '\t') {
                        tree_curr->tree[ tree_curr->index[tree_curr->lindex] ].count_word++;
                        spl_word = 1;
                    }
                    else if(nc == ' ' || nc == '\n' || nc == '\t'){
                        spl_word = 0;
                    }
                }
                
                break;
                
            case 1:
                if(nc == ' ' || nc == '\t' || nc == '\n' || (my[my_buff].start_otag != i-1 && nc == '/')) {
                    my[my_buff].stop_otag = i - 2;
                    
                    // это закрывающий тег?
                    if(html[ my[my_buff].start_otag ] == '/') {
                        pos = 6;
                        break;
                    }
                    
                    pos = 2;
                }
                
                break;
                
            case 2:
                if(nc == '/')
                    break;
                
                if( (nc != ' ' && nc != '\t' && nc != '\n' && nc != '=') || (nc == '=' && next_tag != my[my_buff].lparams) ) {
                    if(next_tag != my[my_buff].lparams) {
                        my[my_buff].lparams++;
                        
                        if(my[my_buff].lparams >= my[my_buff].lparams_size) {
                            my[my_buff].lparams_size += 256;
                            my[my_buff].params = (struct mem_params *)realloc(my[my_buff].params, sizeof(struct mem_params) * my[my_buff].lparams_size);
                        }
                        
                        my[my_buff].params[my[my_buff].lparams].lkey_size = 1024;
                        my[my_buff].params[my[my_buff].lparams].lvalue_size = 1024;
                        my[my_buff].params[my[my_buff].lparams].lkey   = 0;
                        my[my_buff].params[my[my_buff].lparams].lvalue = 0;
                        
                        my[my_buff].params[my[my_buff].lparams].key   = (char *)malloc(sizeof(char) * my[my_buff].params[my[my_buff].lparams].lkey_size);
                        my[my_buff].params[my[my_buff].lparams].value = (char *)malloc(sizeof(char) * my[my_buff].params[my[my_buff].lparams].lvalue_size);
                    }
                    
                    if( my[my_buff].params[my[my_buff].lparams].lkey >= my[my_buff].params[my[my_buff].lparams].lkey_size ) {
                        my[my_buff].params[my[my_buff].lparams].lkey_size += 1024;
                        my[my_buff].params[my[my_buff].lparams].key = (char *)realloc(my[my_buff].params[my[my_buff].lparams].key, my[my_buff].params[my[my_buff].lparams].lkey_size * sizeof(char));
                    }
                    
                    my[my_buff].params[my[my_buff].lparams].key[ my[my_buff].params[my[my_buff].lparams].lkey++ ] = tolower(nc);
                    break;
                }
                else if(next_tag == my[my_buff].lparams && my[my_buff].params[my[my_buff].lparams].lkey != 0) {
                    if( my[my_buff].params[my[my_buff].lparams].lkey >= my[my_buff].params[my[my_buff].lparams].lkey_size ) {
                        my[my_buff].params[my[my_buff].lparams].lkey_size += 1024;
                        my[my_buff].params[my[my_buff].lparams].key = (char *)realloc(my[my_buff].params[my[my_buff].lparams].key, my[my_buff].params[my[my_buff].lparams].lkey_size * sizeof(char));
                    }
                    
                    my[my_buff].params[my[my_buff].lparams].key[ my[my_buff].params[my[my_buff].lparams].lkey++ ] = '\0';
                    pos = 3;
                }
                
            case 3:
                if(nc == ' ' || nc == '\t' || nc == '\n' || nc == '/') {
                    break;
                }
                else if( nc == '=' ) {
                    pos = 4;
                } else {
                    i--;
                    
                    if(next_tag == my[my_buff].lparams){
                        my[my_buff].params[my[my_buff].lparams].value[0] = '\0';
                        next_tag++;
                    }
                    
                    my[my_buff].qo = '\0';
                    my[my_buff].qol = 0;
                    
                    pos = 2;
                }
                break;
                
            case 4:
                if(my[my_buff].qo == '\0' && (nc == ' ' || nc == '\t' || nc == '\n')) {
                    break;
                }
                else if(my[my_buff].qo == '\0' && (nc != ' ' && nc != '\t' && nc != '\n' && nc != '"' && nc != '\'')) {
                    my[my_buff].qo = ' ';
                }
                
                // memset(buf, 0, sizeof(buf));
                if(my[my_buff].qo == '\0') {
                    if(nc == '"') {
                        my[my_buff].qo = '"';
                    }
                    else if(nc == '\'') {
                        my[my_buff].qo = '\'';
                    }
                } else {
                    if( my[my_buff].params[my[my_buff].lparams].lvalue >= my[my_buff].params[my[my_buff].lparams].lvalue_size ) {
                        my[my_buff].params[my[my_buff].lparams].lvalue_size += 1024;
                        my[my_buff].params[my[my_buff].lparams].value = (char *)realloc(my[my_buff].params[my[my_buff].lparams].value, my[my_buff].params[my[my_buff].lparams].lvalue_size * sizeof(char));
                    }
                    
                    if((my[my_buff].qo == ' ' && (nc == ' ' || nc == '\t' || nc == '\n')) || (nc == my[my_buff].qo && (my[my_buff].qol % 2) == 0)) {
                        
                        pos = 2;
                        my[my_buff].params[my[my_buff].lparams].value[my[my_buff].params[my[my_buff].lparams].lvalue++] = '\0';
                        my[my_buff].qo = '\0';
                        my[my_buff].qol = 0;
                        
                        next_tag++;
                        break;
                    } else {
                        my[my_buff].params[my[my_buff].lparams].value[my[my_buff].params[my[my_buff].lparams].lvalue++] = nc;
                    }
                    
                    if(nc == '\\') {
                        my[my_buff].qol++;
                    } else {
                        my[my_buff].qol = 0;
                    }
                }
                
                break;
                
            case 5:
                if(my[my_buff].qo == '\0' && (nc == ' ' || nc == '\t' || nc == '\n')) {
                    break;
                }
                else if(my[my_buff].qo == '\0' && (nc != ' ' && nc != '\t' && nc != '\n' && nc != '"' && nc != '\'')) {
                    my[my_buff].qo = ' ';
                }
                
                if(my[my_buff].qo == '\0') {
                    if(nc == '"') {
                        my[my_buff].qo = '"';
                    }
                    else if(nc == '\'') {
                        my[my_buff].qo = '\'';
                    }
                } else {
                    if((my[my_buff].qo == ' ' && (nc == ' ' || nc == '\t' || nc == '\n')) || (nc == my[my_buff].qo && (my[my_buff].qol % 2) == 0)) {
                        my[my_buff].qo = '\0';
                        my[my_buff].qol = 0;
                    }
                    
                    if(nc == '\\') {
                        my[my_buff].qol++;
                    } else {
                        my[my_buff].qol = 0;
                    }
                }
                
                break;
            case 6:
                break;
            default:
                break;
        }
    }
    
    while(1) {
        if(tree_curr->next != -1) {
            tree_jail.curr_element = tree_curr->next;
            tree_curr = &tree_jail.elements[tree_jail.curr_element];
            continue;
        }
        
        break;
    }
    
    if(tree_curr->is_base == 0) {
        while(1){
            long ie = close_this_jail(my_r, &tree_jail, tree_curr, i);
            
            tree_jail.curr_element = ie;
            tree_curr = &tree_jail.elements[ie];
            
            if(tree_curr->is_base == 1)
                break;
        }
    }
    
    int ti; long ni = i - 2;
    for(ti = tree_jail.elements[0].lindex; ti >= 0; ti--) {
        if(tree_jail.elements[0].tree[ tree_jail.elements[0].index[ti] ].tag_body_stop == -1){
            tree_jail.elements[0].tree[ tree_jail.elements[0].index[ti] ].tag_body_stop = ni;
            tree_jail.elements[0].tree[ tree_jail.elements[0].index[ti] ].tag_stop = ni;
            
            if(ti > 0) {
                // сохраняем общее количество тегов
                tree_curr->tree[ tree_curr->index[ti - 1] ].count_element_in += tree_curr->tree[ tree_curr->index[ti] ].count_element_in;
                
                int si;
                for(si = 0; si < AI_BUFF; si++) {
                    tree_curr->tree[ tree_curr->index[ti - 1] ].counts_in[ si ] += tree_curr->tree[ tree_curr->index[ti] ].counts_in[ si ];
                }
            }
        }
    }
    
    long tl;
    for(tl = tree_curr->ltree; tl >= 0; tl--) {
        if(tree_curr->tree[tl].tag_body_stop != -1)
            break;
        
        tree_curr->tree[tl].tag_body_stop = ni;
        tree_curr->tree[tl].tag_stop = ni;
    }
    
    my_r->count            = tree_jail.elements[0].ltree;
    my_r->real_count       = tree_jail.elements[0].ltree;
    my_r->my_count         = my_buff;
    my_r->my_real_count    = my_real_buff;
    my_r->cur_pos          = 0;
    my_r->nco_pos          = 0;
    
    tree_curr = NULL;
    
    free(tree_jail.elements[0].index);
    
    for(tl = 1; tl <= tree_jail.lelements; tl++) {
        free(tree_jail.elements[tl].tree);
        free(tree_jail.elements[tl].index);
    }
    
    free(tree_jail.elements);
}

int check_tags_alloc(struct tags *tags) {
    if(tags->count >= tags->csize) {
        tags->csize += 1024;
        
        tags->name     = (char **)realloc(tags->name, sizeof(char*) * tags->csize);
        tags->priority = (int *)realloc(tags->priority, sizeof(int) * tags->csize);
        tags->type     = (int *)realloc(tags->type, sizeof(int) * tags->csize);
        tags->extra    = (int *)realloc(tags->extra, sizeof(int) * tags->csize);
        tags->ai       = (int *)realloc(tags->ai, sizeof(int) * tags->csize);
        tags->family   = (int *)realloc(tags->family, sizeof(int) * tags->csize);
        tags->option   = (int *)realloc(tags->option, sizeof(int) * tags->csize);
        
        tags->index.tag_id    = (long **)realloc(tags->index.tag_id, sizeof(long *) * tags->csize);
        tags->index.tag_count = (int *)realloc(tags->index.tag_count, tags->csize * sizeof(int));
        tags->index.tag_csize = (int *)realloc(tags->index.tag_csize, tags->csize * sizeof(int));
    }
    
    return tags->csize;
}

// +++++++++++
// функции добавления тегов в список, присваивает им id
// +++++++++++++++++++++++++++++++++
int add_tag(struct tags *tags, char *html, struct mem_tag *my) {
    long pr = my->stop_otag - my->start_otag + 1;
    
    if( pr <= 0 )
        return -1;
    
    tags->count++;
    
    check_tags_alloc(tags);
    
    tags->name[ tags->count ] = (char *)malloc(sizeof(char) * (pr + 1));
    
    tags->index.tag_count[tags->count] = -1;
    tags->index.tag_csize[tags->count] = 256;
    tags->index.tag_id[tags->count] = (long *)malloc(sizeof(long) * tags->index.tag_csize[tags->count]);
    
    long i, t = 0;
    for(i = my->start_otag; i <= my->stop_otag; i++ ) {
        tags->name[ tags->count ][t++] = tolower(html[i]);
    }
    tags->name[ tags->count ][t]  = '\0';
    
    tags->priority[ tags->count ] = 0;
    tags->type[ tags->count ]     = TYPE_TAG_NORMAL;
    tags->extra[ tags->count ]    = 0;
    tags->ai[ tags->count ]       = AI_NULL;
    tags->family[ tags->count ]   = 0;
    tags->option[ tags->count ]   = OPTION_NULL;
    
    return tags->count;
}

int add_tag_R(struct tags *tags, char *tagname, size_t size, int priority, int family, int type, int extra, int option, int ai) {
    tags->count++;
    
    check_tags_alloc(tags);
    
    tags->name[ tags->count ] = (char *)malloc(sizeof(char) * size + 1);
    
    tags->index.tag_count[tags->count] = -1;
    tags->index.tag_csize[tags->count] = 256;
    tags->index.tag_id[tags->count] = (long *)malloc(sizeof(long) * tags->index.tag_csize[tags->count]);
    
    size_t i;
    for(i = 0; i <= size; i++ ) {
        tags->name[ tags->count ][i] = tolower(tagname[i]);
    }
    
    tags->priority[ tags->count ] = priority;
    tags->type[ tags->count ]     = type;
    tags->extra[ tags->count ]    = extra;
    tags->ai[ tags->count ]       = ai;
    tags->family[ tags->count ]   = family;
    tags->option[ tags->count ]   = option;
    
    return tags->count;
}

int set_tag_family(struct tags *tags, char *tagname, int value) {
    int tag_id = get_tag_id(tags, tagname);
    if(tag_id > -1)
        tags->family[tag_id] = value;
    return tag_id;
}

int set_tag_extra(struct tags *tags, char *tagname, int value) {
    int tag_id = get_tag_id(tags, tagname);
    if(tag_id > -1)
        tags->extra[tag_id] = value;
    return tag_id;
}

int set_tag_option(struct tags *tags, char *tagname, int value) {
    int tag_id = get_tag_id(tags, tagname);
    if(tag_id > -1)
        tags->option[tag_id] = value;
    return tag_id;
}

int set_tag_priority(struct tags *tags, char *tagname, int value) {
    int tag_id = get_tag_id(tags, tagname);
    if(tag_id > -1)
        tags->priority[tag_id] = value;
    return tag_id;
}

int set_tag_type(struct tags *tags, char *tagname, int value) {
    int tag_id = get_tag_id(tags, tagname);
    if(tag_id > -1)
        tags->type[tag_id] = value;
    return tag_id;
}

int set_tag_ai(struct tags *tags, char *tagname, int value) {
    int tag_id = get_tag_id(tags, tagname);
    if(tag_id > -1)
        tags->ai[tag_id] = value;
    return tag_id;
}

// +++++++++++
// разнообразные функции сравнения тегов
// +++++++++++++++++++++++++++++++++
int cmp_tags(struct tags *tags, char *html, struct mem_tag *my, int offset) {
    int m1;
    int is_cg = -1;
    
    for(m1 = 0; m1 <= tags->count; m1++ ) {
        int m2 = -1;// char m;
        
        while( tags->name[m1][++m2] ) {
            long p = my->start_otag + offset + m2;
            
            if(tolower(html[p]) != tags->name[m1][m2]) {
                break;
            }
            else if(my->stop_otag == p && tags->name[m1][m2+1] == '\0') {
                is_cg = m1;
                break;
            }
        }
        
        if(is_cg != -1) {
            break;
        }
    }
    
    if(is_cg == -1 && offset == 0) {
        is_cg = add_tag(tags, html, my);
    }
    
    return is_cg;
}

// +++++++++++
// вспомогательные функции
// +++++++++++++++++++++++++++++++++
int get_tag_id(struct tags *tags, char *tagname) {
    int m1;
    int is_cg = -1;
    
    for(m1 = 0; m1 <= tags->count; m1++ ) {
        int m2 = -1;
        
        while( tags->name[m1][++m2] ) {
            if(tolower(tagname[m2]) != tags->name[m1][m2]) {
                break;
            }
            else if(tags->name[m1][m2+1] == '\0' && tagname[m2+1] == '\0') {
                is_cg = m1;
                break;
            }
        }
        
        if(is_cg != -1) {
            break;
        }
    }
    
    return is_cg;
}

long set_position(struct tree_list *my_r, struct html_tree *element) {
    if(element == NULL)
        return -1;
    
    my_r->nco_pos = element->id;
    my_r->cur_pos = element->id;
    return my_r->cur_pos;
}

long get_element_body_size(struct tree_list *my_r, struct html_tree *element) {
    if(element == NULL) {
        return my_r->list[ my_r->cur_pos ].tag_body_stop - my_r->list[ my_r->cur_pos ].tag_body_start;
    }
    
    return element->tag_body_stop - element->tag_body_start;
}

char * get_element_body(struct tree_list *my_r, struct html_tree *element) {
    if(element == NULL) {
        return &my_r->html[ my_r->list[ my_r->cur_pos ].tag_body_start ];
    }
    
    return &my_r->html[element->tag_body_start];
}

struct html_tree * get_curr_element(struct tree_list *my_r) {
    return &my_r->list[my_r->cur_pos];
}

struct html_tree * get_element_by_name(struct tree_list *my_r, char *tagname, long position) {
    int tag_id = get_tag_id(my_r->tags, tagname);
    
    if(tag_id == -1 || my_r->tags->index.tag_count[tag_id] == -1 || position < 0 || my_r->tags->index.tag_count[tag_id] < position)
        return NULL;
    
    return &my_r->list[ my_r->tags->index.tag_id[tag_id][position] ];
}

struct html_tree * get_element_by_tag_id(struct tree_list *my_r, int tag_id, long position) {
    if(tag_id == -1 || my_r->tags->index.tag_count[tag_id] == -1 || position < 0 || my_r->tags->index.tag_count[tag_id] < position)
        return NULL;
    
    return &my_r->list[ my_r->tags->index.tag_id[tag_id][position] ];
}

struct html_tree * get_element_by_name_in_child(struct tree_list *my_r, char *tagname, long position) {
    int tag_id = get_tag_id(my_r->tags, tagname);
    
    if(tag_id == -1 || my_r->tags->index.tag_count[tag_id] == -1 || position < 0 || my_r->tags->index.tag_count[tag_id] < position)
        return NULL;
    
    long i; long cpos = -1; long il = 0;
    for(i = 0; i <= my_r->tags->index.tag_count[tag_id]; i++) {
        if(my_r->cur_pos < my_r->tags->index.tag_id[tag_id][i]) {
            if(il == position) {
                cpos = i;
                break;
            }
            il++;
        }
    }
    
    if(cpos == -1)
        return NULL;
    
    long level = -1;
    for(i = my_r->cur_pos + 1; i <= my_r->count; i++) {
        if(my_r->list[i].inc <= my_r->list[ my_r->cur_pos ].inc) {
            break;
        }
        
        if(my_r->tags->index.tag_id[tag_id][cpos] == i) {
            level = i;
            break;
        }
    }
    
    if(level == -1)
        return NULL;
    return &my_r->list[level];
}

struct html_tree * get_element_by_name_in_level(struct tree_list *my_r, char *tagname, long position) {
    int tag_id = get_tag_id(my_r->tags, tagname);
    
    if(tag_id == -1 || my_r->tags->index.tag_count[tag_id] == -1 || position < 0 || my_r->tags->index.tag_count[tag_id] < position)
        return NULL;
    
    struct html_tree * curr_element = get_curr_element(my_r);
    
    long i; long cpos = -1; long il = 0;
    int i_level = my_r->list[ my_r->cur_pos ].inc + 1;
    
    long max_id = -1;
    struct html_tree * max_element = get_next_element_skip_curr(my_r);
    
    if(max_element != NULL) {
        max_id = max_element->id;
        set_position(my_r, curr_element);
    }
    
    for(i = 0; i <= my_r->tags->index.tag_count[tag_id]; i++) {
        if(my_r->cur_pos < my_r->tags->index.tag_id[tag_id][i] &&
           i_level == my_r->list[ my_r->tags->index.tag_id[tag_id][i] ].inc &&
           (max_id == -1 || (max_id > my_r->tags->index.tag_id[tag_id][i]))
           ) {
            if(il == position) {
                cpos = i;
                break;
            }
            il++;
        }
    }
    
    if(cpos == -1)
        return NULL;
    return &my_r->list[ my_r->tags->index.tag_id[tag_id][cpos] ];
}

int get_count_element_by_name(struct tree_list *my_r, char *tagname) {
    int tag_id = get_tag_id(my_r->tags, tagname);
    
    if(tag_id == -1)
        return 0;
    
    return my_r->tags->index.tag_count[tag_id] + 1;
}

int get_real_count_element_by_name(struct tree_list *my_r, char *tagname) {
    int tag_id = get_tag_id(my_r->tags, tagname);
    
    if(tag_id == -1)
        return -1;
    
    return my_r->tags->index.tag_count[tag_id];
}

struct html_tree * get_next_element_in_level(struct tree_list *my_r) {
    if(my_r->count > my_r->nco_pos && my_r->list[ my_r->nco_pos + 1 ].inc > my_r->list[ my_r->cur_pos ].inc) {
        my_r->nco_pos++;
        return &my_r->list[my_r->nco_pos];
    }
    
    return NULL;
}

struct html_tree * get_prev_element_in_level(struct tree_list *my_r) {
    if(my_r->nco_pos > 0 && my_r->list[ my_r->nco_pos - 1 ].inc > my_r->list[ my_r->cur_pos ].inc) {
        my_r->nco_pos--;
        return &my_r->list[my_r->nco_pos];
    }
    
    return NULL;
}

struct html_tree * get_next_element_in_level_skip_curr(struct tree_list *my_r) {
    long i; long level = -1;
    for(i = my_r->nco_pos + 1; i <= my_r->count; i++) {
        if(my_r->list[i].inc <= my_r->list[ my_r->cur_pos ].inc) {
            break;
        }
        else if(my_r->list[i].inc <= my_r->list[ my_r->nco_pos ].inc) {
            level = i;
            break;
        }
    }
    
    if(level == -1)
        return NULL;
    
    my_r->nco_pos = level;
    return &my_r->list[level];
}

struct html_tree * get_parent_in_level(struct tree_list *my_r, int set_pos) {
    
    long i; long level = -1;
    for(i = my_r->nco_pos - 1; i >= my_r->cur_pos; i--) {
        if(my_r->list[i].inc < my_r->list[ my_r->nco_pos ].inc) {
            level = i;
            break;
        }
    }
    
    if(level == -1)
        return NULL;
    
    if(set_pos == 1)
        my_r->nco_pos = level;
    
    return &my_r->list[level];
}

struct html_tree * get_next_element(struct tree_list *my_r) {
    if(my_r->count > my_r->cur_pos) {
        my_r->cur_pos++;
        my_r->nco_pos = my_r->cur_pos;
        return &my_r->list[my_r->cur_pos];
    }
    
    return NULL;
}

struct html_tree * get_prev_element(struct tree_list *my_r) {
    if(my_r->cur_pos > 0) {
        my_r->cur_pos--;
        my_r->nco_pos = my_r->cur_pos;
        return &my_r->list[my_r->cur_pos];
    }
    
    return NULL;
}

struct html_tree * get_next_element_skip_curr(struct tree_list *my_r) {
    long i; long level = -1;
    for(i = my_r->cur_pos + 1; i <= my_r->count; i++) {
        if(my_r->list[i].inc <= my_r->list[ my_r->cur_pos ].inc) {
            level = i;
            break;
        }
    }
    
    if(level == -1)
        return NULL;
    
    my_r->nco_pos = level;
    my_r->cur_pos = level;
    return &my_r->list[level];
}

struct html_tree * get_next_element_curr_level(struct tree_list *my_r) {
    long i; long level = -1;
    for(i = my_r->cur_pos + 1; i <= my_r->count; i++) {
        if(my_r->list[i].inc == my_r->list[ my_r->cur_pos ].inc) {
            level = i;
            break;
        }
        else if(my_r->list[i].inc < my_r->list[ my_r->cur_pos ].inc) {
            break;
        }
    }
    
    if(level == -1)
        return NULL;
    
    my_r->nco_pos = level;
    my_r->cur_pos = level;
    return &my_r->list[level];
}

struct html_tree * get_prev_element_curr_level(struct tree_list *my_r) {
    
    long i; long level = -1;
    for(i = my_r->cur_pos - 1; i >= 0; i--) {
        if(my_r->list[i].inc == my_r->list[ my_r->cur_pos ].inc) {
            level = i;
            break;
        }
        else if(my_r->list[i].inc < my_r->list[ my_r->cur_pos ].inc) {
            break;
        }
    }
    
    if(level == -1)
        return NULL;
    
    my_r->nco_pos = level;
    my_r->cur_pos = level;
    return &my_r->list[level];
}

struct html_tree * get_child(struct tree_list *my_r, long pos) {
    
    long level = -1;
    int next_level = my_r->list[ my_r->cur_pos ].inc + 1;
    
    long i;
    for(i = my_r->cur_pos + 1; i <= my_r->count; i++) {
        if(my_r->list[i].inc == next_level) {
            pos--;
            if(pos == -1) {
                level = i;
                break;
            }
        }
        else if(my_r->list[i].inc <= my_r->list[ my_r->cur_pos ].inc) {
            break;
        }
    }
    
    if(level == -1)
        return NULL;
    
    my_r->nco_pos = level;
    my_r->cur_pos = level;
    return &my_r->list[level];
}

struct html_tree * get_child_n(struct tree_list *my_r, long pos) {
    
    long level = -1;
    int next_level = my_r->list[ my_r->cur_pos ].inc + 1;
    
    long i;
    for(i = my_r->cur_pos + 1; i <= my_r->count; i++) {
        if(my_r->list[i].inc == next_level) {
            pos--;
            if(pos == -1) {
                level = i;
                break;
            }
        }
        else if(my_r->list[i].inc <= my_r->list[ my_r->cur_pos ].inc) {
            break;
        }
    }
    
    if(level == -1)
        return NULL;
    
    return &my_r->list[level];
}

struct html_tree * get_parent(struct tree_list *my_r) {
    
    long i; long level = -1;
    for(i = my_r->cur_pos - 1; i >= 0; i--) {
        if(my_r->list[i].inc < my_r->list[ my_r->cur_pos ].inc) {
            level = i;
            break;
        }
    }
    
    if(level == -1)
        return NULL;
    
    my_r->nco_pos = level;
    my_r->cur_pos = level;
    return &my_r->list[level];
}

struct html_tree * get_child_by_tree(struct tree_list *my_r, struct html_tree *html_tree) {
    
    long i; long level = -1;
    for(i = html_tree->id + 1; i <= my_r->count; i++) {
        if(my_r->list[i].inc > html_tree->inc) {
            level = i;
            break;
        }
        else if(my_r->list[i].inc <= html_tree->inc) {
            break;
        }
    }
    
    if(level == -1)
        return NULL;
    return &my_r->list[level];
}

int get_count_to_next_element_in_level(struct tree_list *my_r, struct html_tree *tag) {
    long i; int count = 0;
    for(i = tag->id + 1; i <= my_r->count; i++) {
        count++;
        
        if(my_r->list[i].inc <= my_r->list[ tag->id ].inc) {
            break;
        }
        else if(my_r->list[i].inc <= my_r->list[ tag->id ].inc) {
            break;
        }
    }
    
    return count;
}

/////////////
// работа с элементами и их параметрами
///////////////////
struct mem_params * find_param_by_key_in_element(struct mem_tag *my, char *key) {
    long p;
    struct mem_params *np = NULL;
    
    if (my->params == NULL)
        return np;
    
    for (p = 0; p <= my->lparams; p++) {
        long k;
        for (k = 0; k <= my->params[p].lkey; k++) {
            if(my->params[p].key[k] != key[k] || ((my->params[p].key[k] != '\0' && key[k] == '\0') || (my->params[p].key[k] == '\0' && key[k] != '\0'))) {
                break;
            }
            else if(my->params[p].key[k] == '\0' && key[k] == '\0') {
                np = &my->params[p];
                break;
            }
        }
    }
    
    return np;
}

/////////////
// функции зачисток
///////////////////
void clean_tree(struct tree_list * my_r) {
    int di;
    for(di = 0; di <= my_r->my_real_count; di++) {
        int si;
        
        for(si = 0; si <= my_r->my[di].lparams; si++) {
            free(my_r->my[di].params[si].key);
            free(my_r->my[di].params[si].value);
        }
        
        free(my_r->my[di].params);
    }
    
    my_r->my_count      = -1;
    my_r->my_real_count = -1;
    
    my_r->count         = -1;
    my_r->real_count    = -1;
    
    my_r->cur_pos       = 0;
    my_r->nco_pos       = 0;
    
    if(my_r->my != NULL) {
        free(my_r->my);
        my_r->my = NULL;
    }
    
    if(my_r->tags != NULL) {
        for(di = 0; di <= my_r->tags->count; di++) {
            free(my_r->tags->index.tag_id[di]);
            free(my_r->tags->name[di]);
        }
        
        free(my_r->tags->index.tag_count);
        free(my_r->tags->index.tag_csize);
        free(my_r->tags->index.tag_id);
        free(my_r->tags->name);
        free(my_r->tags->priority);
        free(my_r->tags->type);
        free(my_r->tags->extra);
        free(my_r->tags->ai);
        free(my_r->tags->family);
        free(my_r->tags->option);
        
        my_r->tags->name     = NULL;
        my_r->tags->priority = NULL;
        my_r->tags->type     = NULL;
        my_r->tags->extra    = NULL;
        my_r->tags->ai       = NULL;
        my_r->tags->family   = NULL;
        my_r->tags->option   = NULL;
    }
    
    if(my_r->swords != NULL)
        free(my_r->swords);
    
    if(my_r->tags_family != NULL) {
        long ld;
        for(ld = 0; ld <= my_r->tags_family->irtags; ld++) {
            if(my_r->tags_family->rtags[ld] == 0)
                continue;
            
            free(my_r->tags_family->rtags[ld]);
        }
        
        for(ld = 0; ld <= my_r->tags_family->itags; ld++) {
            if(my_r->tags_family->tags[ld] == 0)
                continue;
            
            free(my_r->tags_family->tags[ld]);
        }
        
        free(my_r->tags_family->rtags);
        free(my_r->tags_family->tags);
        
        my_r->tags_family->rtags = NULL;
        my_r->tags_family->tags  = NULL;
        
        free(my_r->tags_family);
        my_r->tags_family = NULL;
    }
    
    if(my_r->list != NULL) {
        free(my_r->list);
        my_r->list = NULL;
    }
}

//////////////
// HTML Entities
/////////////////////
struct tree_entity * create_entity_tree(void) {
    struct tree_entity *entities = (struct tree_entity *)malloc(sizeof(struct tree_entity) * 128);
    
    int i;
    for(i = 0; i < 128; i++) {
        entities[i].count = -1;
        entities[i].next  = NULL;
        entities[i].value[0] = '\0';
        entities[i].level = 0;
    }
    
    add_entity(entities, "AElig", "Æ");
    add_entity(entities, "Aacute", "Á");
    add_entity(entities, "Acirc", "Â");
    add_entity(entities, "Agrave", "À");
    add_entity(entities, "Alpha", "Α");
    add_entity(entities, "Aring", "Å");
    add_entity(entities, "Atilde", "Ã");
    add_entity(entities, "Auml", "Ä");
    add_entity(entities, "Beta", "Β");
    add_entity(entities, "Ccedil", "Ç");
    add_entity(entities, "Chi", "Χ");
    add_entity(entities, "Dagger", "‡");
    add_entity(entities, "Delta", "Δ");
    add_entity(entities, "ETH", "Ð");
    add_entity(entities, "Eacute", "É");
    add_entity(entities, "Ecirc", "Ê");
    add_entity(entities, "Egrave", "È");
    add_entity(entities, "Epsilon", "Ε");
    add_entity(entities, "Eta", "Η");
    add_entity(entities, "Euml", "Ë");
    add_entity(entities, "Gamma", "Γ");
    add_entity(entities, "Iacute", "Í");
    add_entity(entities, "Icirc", "Î");
    add_entity(entities, "Igrave", "Ì");
    add_entity(entities, "Iota", "Ι");
    add_entity(entities, "Iuml", "Ï");
    add_entity(entities, "Kappa", "Κ");
    add_entity(entities, "Lambda", "Λ");
    add_entity(entities, "Mu", "Μ");
    add_entity(entities, "Ntilde", "Ñ");
    add_entity(entities, "Nu", "Ν");
    add_entity(entities, "OElig", "Œ");
    add_entity(entities, "Oacute", "Ó");
    add_entity(entities, "Ocirc", "Ô");
    add_entity(entities, "Ograve", "Ò");
    add_entity(entities, "Omega", "Ω");
    add_entity(entities, "Omicron", "Ο");
    add_entity(entities, "Oslash", "Ø");
    add_entity(entities, "Otilde", "Õ");
    add_entity(entities, "Ouml", "Ö");
    add_entity(entities, "Phi", "Φ");
    add_entity(entities, "Pi", "Π");
    add_entity(entities, "Prime", "″");
    add_entity(entities, "Psi", "Ψ");
    add_entity(entities, "Rho", "Ρ");
    add_entity(entities, "Scaron", "Š");
    add_entity(entities, "Sigma", "Σ");
    add_entity(entities, "THORN", "Þ");
    add_entity(entities, "Tau", "Τ");
    add_entity(entities, "Theta", "Θ");
    add_entity(entities, "Uacute", "Ú");
    add_entity(entities, "Ucirc", "Û");
    add_entity(entities, "Ugrave", "Ù");
    add_entity(entities, "Upsilon", "Υ");
    add_entity(entities, "Uuml", "Ü");
    add_entity(entities, "Xi", "Ξ");
    add_entity(entities, "Yacute", "Ý");
    add_entity(entities, "Yuml", "Ÿ");
    add_entity(entities, "Zeta", "Ζ");
    add_entity(entities, "aacute", "á");
    add_entity(entities, "acirc", "â");
    add_entity(entities, "acute", "´");
    add_entity(entities, "aelig", "æ");
    add_entity(entities, "agrave", "à");
    add_entity(entities, "alefsym", "ℵ");
    add_entity(entities, "alpha", "α");
    add_entity(entities, "amp", "&");
    add_entity(entities, "and", "∧");
    add_entity(entities, "ang", "∠");
    add_entity(entities, "apos", "'");
    add_entity(entities, "aring", "å");
    add_entity(entities, "asymp", "≈");
    add_entity(entities, "atilde", "ã");
    add_entity(entities, "auml", "ä");
    add_entity(entities, "bdquo", "„");
    add_entity(entities, "beta", "β");
    add_entity(entities, "brvbar", "¦");
    add_entity(entities, "bull", "•");
    add_entity(entities, "cap", "∩");
    add_entity(entities, "ccedil", "ç");
    add_entity(entities, "cedil", "¸");
    add_entity(entities, "cent", "¢");
    add_entity(entities, "chi", "χ");
    add_entity(entities, "circ", "ˆ");
    add_entity(entities, "clubs", "♣");
    add_entity(entities, "cong", "≅");
    add_entity(entities, "copy", "©");
    add_entity(entities, "crarr", "↵");
    add_entity(entities, "cup", "∪");
    add_entity(entities, "curren", "¤");
    add_entity(entities, "dArr", "⇓");
    add_entity(entities, "dagger", "†");
    add_entity(entities, "darr", "↓");
    add_entity(entities, "deg", "°");
    add_entity(entities, "delta", "δ");
    add_entity(entities, "diams", "♦");
    add_entity(entities, "divide", "÷");
    add_entity(entities, "eacute", "é");
    add_entity(entities, "ecirc", "ê");
    add_entity(entities, "egrave", "è");
    add_entity(entities, "empty", "∅");
    add_entity(entities, "emsp", " ");
    add_entity(entities, "ensp", " ");
    add_entity(entities, "epsilon", "ε");
    add_entity(entities, "equiv", "≡");
    add_entity(entities, "eta", "η");
    add_entity(entities, "eth", "ð");
    add_entity(entities, "euml", "ë");
    add_entity(entities, "euro", "€");
    add_entity(entities, "exist", "∃");
    add_entity(entities, "fnof", "ƒ");
    add_entity(entities, "forall", "∀");
    add_entity(entities, "frac12", "½");
    add_entity(entities, "frac14", "¼");
    add_entity(entities, "frac34", "¾");
    add_entity(entities, "frasl", "⁄");
    add_entity(entities, "gamma", "γ");
    add_entity(entities, "ge", "≥");
    add_entity(entities, "gt", ">");
    add_entity(entities, "hArr", "⇔");
    add_entity(entities, "harr", "↔");
    add_entity(entities, "hearts", "♥");
    add_entity(entities, "hellip", "…");
    add_entity(entities, "iacute", "í");
    add_entity(entities, "icirc", "î");
    add_entity(entities, "iexcl", "¡");
    add_entity(entities, "igrave", "ì");
    add_entity(entities, "image", "ℑ");
    add_entity(entities, "infin", "∞");
    add_entity(entities, "int", "∫");
    add_entity(entities, "iota", "ι");
    add_entity(entities, "iquest", "¿");
    add_entity(entities, "isin", "∈");
    add_entity(entities, "iuml", "ï");
    add_entity(entities, "kappa", "κ");
    add_entity(entities, "lArr", "⇐");
    add_entity(entities, "lambda", "λ");
    add_entity(entities, "lang", "〈");
    add_entity(entities, "laquo", "«");
    add_entity(entities, "larr", "←");
    add_entity(entities, "lceil", "⌈");
    add_entity(entities, "ldquo", "“");
    add_entity(entities, "le", "≤");
    add_entity(entities, "lfloor", "⌊");
    add_entity(entities, "lowast", "∗");
    add_entity(entities, "loz", "◊");
    add_entity(entities, "lrm", "\xE2\x80\x8E");
    add_entity(entities, "lsaquo", "‹");
    add_entity(entities, "lsquo", "‘");
    add_entity(entities, "lt", "<");
    add_entity(entities, "macr", "¯");
    add_entity(entities, "mdash", "—");
    add_entity(entities, "micro", "µ");
    add_entity(entities, "middot", "·");
    add_entity(entities, "minus", "−");
    add_entity(entities, "mu", "μ");
    add_entity(entities, "nabla", "∇");
    add_entity(entities, "nbsp", " ");
    add_entity(entities, "ndash", "–");
    add_entity(entities, "ne", "≠");
    add_entity(entities, "ni", "∋");
    add_entity(entities, "not", "¬");
    add_entity(entities, "notin", "∉");
    add_entity(entities, "nsub", "⊄");
    add_entity(entities, "ntilde", "ñ");
    add_entity(entities, "nu", "ν");
    add_entity(entities, "oacute", "ó");
    add_entity(entities, "ocirc", "ô");
    add_entity(entities, "oelig", "œ");
    add_entity(entities, "ograve", "ò");
    add_entity(entities, "oline", "‾");
    add_entity(entities, "omega", "ω");
    add_entity(entities, "omicron", "ο");
    add_entity(entities, "oplus", "⊕");
    add_entity(entities, "or", "∨");
    add_entity(entities, "ordf", "ª");
    add_entity(entities, "ordm", "º");
    add_entity(entities, "oslash", "ø");
    add_entity(entities, "otilde", "õ");
    add_entity(entities, "otimes", "⊗");
    add_entity(entities, "ouml", "ö");
    add_entity(entities, "para", "¶");
    add_entity(entities, "part", "∂");
    add_entity(entities, "permil", "‰");
    add_entity(entities, "perp", "⊥");
    add_entity(entities, "phi", "φ");
    add_entity(entities, "pi", "π");
    add_entity(entities, "piv", "ϖ");
    add_entity(entities, "plusmn", "±");
    add_entity(entities, "pound", "£");
    add_entity(entities, "prime", "′");
    add_entity(entities, "prod", "∏");
    add_entity(entities, "prop", "∝");
    add_entity(entities, "psi", "ψ");
    add_entity(entities, "quot", "\"");
    add_entity(entities, "rArr", "⇒");
    add_entity(entities, "radic", "√");
    add_entity(entities, "rang", "〉");
    add_entity(entities, "raquo", "»");
    add_entity(entities, "rarr", "→");
    add_entity(entities, "rceil", "⌉");
    add_entity(entities, "rdquo", "”");
    add_entity(entities, "real", "ℜ");
    add_entity(entities, "reg", "®");
    add_entity(entities, "rfloor", "⌋");
    add_entity(entities, "rho", "ρ");
    add_entity(entities, "rlm", "\xE2\x80\x8F");
    add_entity(entities, "rsaquo", "›");
    add_entity(entities, "rsquo", "’");
    add_entity(entities, "sbquo", "‚");
    add_entity(entities, "scaron", "š");
    add_entity(entities, "sdot", "⋅");
    add_entity(entities, "sect", "§");
    add_entity(entities, "shy", "\xC2\xAD");
    add_entity(entities, "sigma", "σ");
    add_entity(entities, "sigmaf", "ς");
    add_entity(entities, "sim", "∼");
    add_entity(entities, "spades", "♠");
    add_entity(entities, "sub", "⊂");
    add_entity(entities, "sube", "⊆");
    add_entity(entities, "sum", "∑");
    add_entity(entities, "sup", "⊃");
    add_entity(entities, "sup1", "¹");
    add_entity(entities, "sup2", "²");
    add_entity(entities, "sup3", "³");
    add_entity(entities, "supe", "⊇");
    add_entity(entities, "szlig", "ß");
    add_entity(entities, "tau", "τ");
    add_entity(entities, "there4", "∴");
    add_entity(entities, "theta", "θ");
    add_entity(entities, "thetasym", "ϑ");
    add_entity(entities, "thinsp", " ");
    add_entity(entities, "thorn", "þ");
    add_entity(entities, "tilde", "˜");
    add_entity(entities, "times", "×");
    add_entity(entities, "trade", "™");
    add_entity(entities, "uArr", "⇑");
    add_entity(entities, "uacute", "ú");
    add_entity(entities, "uarr", "↑");
    add_entity(entities, "ucirc", "û");
    add_entity(entities, "ugrave", "ù");
    add_entity(entities, "uml", "¨");
    add_entity(entities, "upsih", "ϒ");
    add_entity(entities, "upsilon", "υ");
    add_entity(entities, "uuml", "ü");
    add_entity(entities, "weierp", "℘");
    add_entity(entities, "xi", "ξ");
    add_entity(entities, "yacute", "ý");
    add_entity(entities, "yen", "¥");
    add_entity(entities, "yuml", "ÿ");
    add_entity(entities, "zeta", "ζ");
    add_entity(entities, "zwj", "\xE2\x80\x8D");
    add_entity(entities, "zwnj", "\xE2\x80\x8C");
    
    return entities;
}

void _add_entity(struct tree_entity *entities, unsigned char *key, char *value, int i) {
    if(entities[key[i]].next == NULL) {
        entities[key[i]].next = (struct tree_entity *)malloc(sizeof(struct tree_entity) * 128);
        
        int k;
        for(k = 0; k < 128; k++) {
            entities[key[i]].next[k].count = -1;
            entities[key[i]].next[k].next  = NULL;
            entities[key[i]].next[k].value[0] = '\0';
            entities[key[i]].next[k].level = 0;
        }
    }
    
    int next_i = i + 1;
    if(key[next_i] == '\0') {
        int m = -1;
        while (value[++m]) {
            entities[ key[i] ].value[m] = value[m];
        }
        
        entities[ key[i] ].value[m] = '\0';
        entities[ key[i] ].level = i;
        entities[ key[i] ].count++;
    } else {
        _add_entity(entities[ key[i] ].next, key, value, i + 1);
    }
}

void add_entity(struct tree_entity *entities, char *key, char *value) {
    _add_entity(entities, (unsigned char*)key, value, 0);
}

struct tree_entity * _check_entity(struct tree_entity *entities, unsigned char *name, int i) {
    if(name[i] == '\0' || name[i] > 127)
        return NULL;
    
    int next_i = i + 1;
    if(name[next_i] == '\0' || name[next_i] > 127) {
        if(entities[name[i]].count != -1) {
            return &entities[name[i]];
        }
        return NULL;
    }
    
    if(entities[name[i]].next == NULL || entities[name[i]].next[name[next_i]].next == NULL) {
        if(entities[name[i]].count != -1) {
            return &entities[name[i]];
        }
        else {
            return NULL;
        }
    }
    
    return _check_entity(entities[name[i]].next, name, i + 1);
}

struct tree_entity * check_entity(struct tree_entity *entities, char *name) {
    return _check_entity(entities, (unsigned char*)name, 0);
}

void clean_tree_entity(struct tree_entity *entities) {
    int i;
    for(i = 0; i < 128; i++) {
        if(entities[i].next != NULL) {
            clean_tree_entity(entities[i].next);
            free(entities[i].next);
        }
    }
}

struct mem_stop_words * add_stop_word_params(struct mem_stop_words *swords, char *key, size_t ksize, char *value, size_t vsize)
{
    if(swords == NULL) {
        swords = malloc(sizeof(struct mem_stop_words));
        
        swords->params_size = sizeof(struct mem_params) * 1024;
        swords->lparams = -1;
        swords->mem_params = malloc(swords->params_size);
    }
    
    swords->lparams++;
    
    if(swords->lparams >= swords->params_size) {
        swords->params_size += sizeof(struct mem_params) * 1024;
        swords->mem_params = realloc(swords->mem_params, swords->params_size);
    }
    
    swords->mem_params[swords->lparams].key = malloc(sizeof(char) * ksize + 1);
    swords->mem_params[swords->lparams].lkey = (int)ksize;
    swords->mem_params[swords->lparams].lkey_size = (int)ksize;
    strncpy(swords->mem_params[swords->lparams].key, key, ksize);
    
    swords->mem_params[swords->lparams].value = malloc(sizeof(char) * vsize + 1);
    swords->mem_params[swords->lparams].lvalue = (int)vsize;
    swords->mem_params[swords->lparams].lvalue_size = (int)vsize;
    strncpy(swords->mem_params[swords->lparams].value, value, vsize);
    
    return swords;
}

void * clean_stop_word_params(struct mem_stop_words *swords) {
    if (swords == NULL || swords->mem_params == NULL)
        return NULL;
    
    int si;
    
    for(si = 0; si <= swords->lparams; si++) {
        free(swords->mem_params[si].key);
        free(swords->mem_params[si].value);
    }
    
    free(swords->mem_params);
    swords->mem_params = NULL;
    swords->lparams = -1;
    swords->params_size = 0;
    
    free(swords);
    
    return NULL;
}

int compare_param_by_nt(struct mem_params *curp, char *value, size_t size_value)
{
    if (curp == NULL
        || (value[0] == '^' && curp->lvalue < (size_value - 1))
        || (value[0] != '^' && curp->lvalue < size_value))
        return 0;
    
    long i, t = 0;
    
    if(value[0] == '^') {
        t = 1;
        for(i = 1; i < size_value; i++) {
            if (value[i] != curp->value[i-1]) {
                t = 0;
                break;
            }
        }
        
        i = t == 0 ? -1 : size_value;
    }
    else {
        for(i = 0; i < size_value; i++) {
            if (t > curp->lvalue) {
                break;
            }
            else if (value[i] != curp->value[t]) {
                i = -1;
            }
            
            t++;
        }
    }
    
    return i == size_value;
}

int find_stop_word_param(struct mem_stop_words *swords, struct mem_tag *mtag) {
    int cm = 0;
    
    if (swords == NULL || mtag == NULL)
        return cm;
    
    long cw;
    for (cw = 0; cw <= swords->lparams; cw++) {
        struct mem_params *curp = find_param_by_key_in_element(mtag, swords->mem_params[cw].key);
        int resc = compare_param_by_nt(curp, swords->mem_params[cw].value, swords->mem_params[cw].lvalue);
        
        if(resc == 1) {
            cm = 1;
            break;
        }
    }
    
    return cm;
}

void * clean_return_list(struct return_list *return_list) {
    if (return_list == NULL)
        return NULL;
    
    free(return_list->list);
    return_list->list = NULL;
    free(return_list);
    
    return NULL;
}






HV * get_element_property_by_my(htmltag_t *my_r, struct mem_tag *mem_tag, int is_utf8) {
    SV **ha;
    HV *hash = newHV();
    
    HV *hash_prop = newHV();
    if(mem_tag != NULL) {
        long si;
        for(si = 0; si <= mem_tag->lparams; si++) {
            if(mem_tag->params[si].lvalue > 0) {
                SV *nm = newSVpv(mem_tag->params[si].value, mem_tag->params[si].lvalue - 1);
                
                if(is_utf8) {
                   SvUTF8_on(nm);
                }
                ha = hv_store(hash_prop, mem_tag->params[si].key, mem_tag->params[si].lkey - 1, nm, 0);
            } else {
                ha = hv_store(hash_prop, mem_tag->params[si].key, mem_tag->params[si].lkey - 1, &PL_sv_undef, 0);
            }
        }
        
        ha = hv_store(hash, "prop"  , 4, newRV_noinc((SV*)hash_prop), 0);
        ha = hv_store(hash, "start" , 5, newSViv(mem_tag->start_otag), 0);
        ha = hv_store(hash, "stop"  , 4, newSViv(mem_tag->stop_otag) , 0);
    }
    
    return hash;
}

HV * get_element_property_by_id(htmltag_t *my_r, long id, int is_utf8) {
    long my_id = my_r->list[id].my_id;
    
    SV **ha;
    HV *hash = newHV();
    
    ha = hv_store(hash, "name", 4, newSVpv(my_r->tags->name[my_r->list[id].tag_id], 0), 0);
    
    HV *hash_prop = newHV();
    if(my_id != -1) {
        long si;
        for(si = 0; si <= my_r->my[my_id].lparams; si++) {
            if(my_r->my[my_id].params[si].lvalue > 0) {
                SV *nm = newSVpv(my_r->my[my_id].params[si].value, my_r->my[my_id].params[si].lvalue - 1);
                
                if(is_utf8) {
                   SvUTF8_on(nm);
                }
                ha = hv_store(hash_prop, my_r->my[my_id].params[si].key, my_r->my[my_id].params[si].lkey - 1, nm, 0);
            } else {
                ha = hv_store(hash_prop, my_r->my[my_id].params[si].key, my_r->my[my_id].params[si].lkey - 1, &PL_sv_undef, 0);
            }
        }
    }
    
    ha = hv_store(hash, "id"    , 2, newSViv(my_r->list[id].id) , 0);
    ha = hv_store(hash, "tag_id", 6, newSViv(my_r->list[id].tag_id) , 0);
    
    ha = hv_store(hash, "prop"  , 4, newRV_noinc((SV*)hash_prop), 0);
    ha = hv_store(hash, "level" , 5, newSViv(my_r->list[id].inc), 0);
    
    ha = hv_store(hash, "start" , 5, newSViv(my_r->list[id].tag_start), 0);
    ha = hv_store(hash, "stop"  , 4, newSViv(my_r->list[id].tag_stop) , 0);
    
    ha = hv_store(hash, "bstart", 6, newSViv(my_r->list[id].tag_body_start), 0);
    ha = hv_store(hash, "bstop" , 5, newSViv(my_r->list[id].tag_body_stop) , 0);
    
    return hash;
}

HV * get_element_property_deftag_by_id(htmltag_t *my_r, long id, char *name) {
    long my_id = my_r->list[id].my_id;
    
    SV **ha;
    HV *hash = newHV();
    
    ha = hv_store(hash, "name", 4, newSVpv(name, 0), 0);
    
    ha = hv_store(hash, "id"    , 2, newSViv(my_r->list[id].id) , 0);
    ha = hv_store(hash, "tag_id", 6, newSViv(my_r->list[id].tag_id) , 0);
    
    ha = hv_store(hash, "prop"  , 4, &PL_sv_undef, 0);
    ha = hv_store(hash, "level" , 5, newSViv(my_r->list[id].inc), 0);
    
    ha = hv_store(hash, "start" , 5, newSViv(my_r->list[id].tag_start), 0);
    ha = hv_store(hash, "stop"  , 4, newSViv(my_r->list[id].tag_stop) , 0);
    
    ha = hv_store(hash, "bstart", 6, newSViv(my_r->list[id].tag_body_start), 0);
    ha = hv_store(hash, "bstop" , 5, newSViv(my_r->list[id].tag_body_stop) , 0);
    
    return hash;
}

MODULE = HTML::Content::Extractor  PACKAGE = HTML::Content::Extractor

PROTOTYPES: DISABLE

HTML::Content::Extractor
new(char * class, ...)
    CODE:
        htmltag_t *my_r = malloc(sizeof(htmltag_t));
        
        my_r->entities    = create_entity_tree();
        my_r->tags        = NULL;
        my_r->list        = NULL;
        my_r->my          = NULL;
        my_r->swords      = NULL;
        my_r->tags_family = NULL;
        
        my_r->my_count      = -1;
        my_r->my_real_count = -1;
        
        RETVAL = my_r;
    OUTPUT:
        RETVAL

void
analyze(my_r, html, hashref = &PL_sv_undef)
    HTML::Content::Extractor my_r;
    char *html;
    SV *hashref;
    
    CODE:
        //setbuf(stdout, NULL);
        
        HV * myhash;
        HE * entry;
        STRLEN retlen;
        I32 len;
        
        char * key;
        SV * hashval;
        char *value;
        
        AV* arrayh;
        char **elements;
        int elem_size = -1;
        
        my_r->swords = clean_stop_word_params(my_r->swords);
        clean_tree(my_r);
        
        if(my_r->tags)
            free(my_r->tags);
        
        struct tags *tags = malloc(sizeof(struct tags));
        tags->count = -1;
        tags->csize = -1;
        my_r->tags = tags;
        
        my_r->html = html;
        html_tree(my_r);
        
        if(SvROK(hashref)) {
            myhash = (HV *)SvRV(hashref);
            (void)hv_iterinit(myhash);
            while ((entry = hv_iternext(myhash)))  {
                key = hv_iterkey(entry,&len);
                hashval = hv_iterval(myhash,entry);
                
                if(SvROK(hashval) && SvTYPE(SvRV(hashval)) == SVt_PVAV) {
                    arrayh = (AV*)SvRV(hashval);
                    
                    elem_size = av_len(arrayh);
                    
                    char *tmp;
                    int i;
                    STRLEN len_s;
                    for (i = 0; i <= elem_size; i++) {
                        SV** elem = av_fetch(arrayh, i, 0);
                        char *nml = (char *)SvPV(*elem, len_s);
                        if(elem != NULL)
                            my_r->swords = add_stop_word_params(my_r->swords, key, (size_t)len, nml, (size_t)len_s);
                    }
                }
                else {
                    value = SvPV(hashval,retlen);
                    my_r->swords = add_stop_word_params(my_r->swords, key, (size_t)len, value, (size_t)retlen);
                }
            }
        }
        
        struct max_element my_max = {0, NULL};
        struct html_tree * max_element = check_html(my_r, &my_max);
        set_position(my_r, max_element);

SV*
get_main_text(my_r, is_utf8 = 1)
    HTML::Content::Extractor my_r;
    int is_utf8;
    
    CODE:
        if(my_r->list == NULL || my_r->my == NULL || my_r->tags == NULL) {
            RETVAL = newSVsv(&PL_sv_undef);
        }
        else {
            struct lbuffer main_buff = {-1, 1024 * 1024, NULL};
            get_text_without_element(my_r, &main_buff);
            clean_text(my_r->entities, &main_buff);
            
            if(main_buff.i < 0) {
                RETVAL = newSVsv(&PL_sv_undef);
            } else {
                if(is_utf8) {
                    SV *nm = newSVpv(main_buff.buff, main_buff.i);
                    SvUTF8_on(nm);
                    RETVAL = nm;
                } else {
                    RETVAL = newSVpv(main_buff.buff, main_buff.i);
                }
            }
            
            free(main_buff.buff);
        }
    OUTPUT:
        RETVAL

SV*
get_main_text_with_elements(my_r, is_utf8 = 1, elements_ref = &PL_sv_undef)
    HTML::Content::Extractor my_r;
    int is_utf8;
    SV* elements_ref;
    
    CODE:
        AV* array;
        char **elements;
        int elem_size = -1;
        
        if(SvROK(elements_ref)) {
            array = (AV*)SvRV(elements_ref);
            
            elem_size = av_len(array);
            elements = (char **)malloc(sizeof(char *) * elem_size + 1);
            
            char *tmp;
            int i;
            STRLEN len_s;
            for (i = 0; i <= elem_size; i++) {
                //SV *elem = av_shift(array);
                SV** elem = av_fetch(array, i, 0);
                if(elem != NULL) {
                    elements[i] = (char *)SvPV(*elem, len_s);
                }
            }
        }
        
        if(my_r->list == NULL || my_r->my == NULL || my_r->tags == NULL) {
            RETVAL = newSVsv(&PL_sv_undef);
        }
        else {
            struct lbuffer main_buff = {-1, 1024 * 1024, NULL};
            get_text_with_element(my_r, &main_buff, elements, elem_size);
            
            if(main_buff.i < 0) {
                RETVAL = newSVsv(&PL_sv_undef);
            } else {
                if(is_utf8) {
                    SV *nm = newSVpv(main_buff.buff, main_buff.i);
                    SvUTF8_on(nm);
                    RETVAL = nm;
                } else {
                    RETVAL = newSVpv(main_buff.buff, main_buff.i);
                }
            }
            
            free(main_buff.buff);
            if(elem_size > -1) {
                free(elements);
            }
        }
    OUTPUT:
        RETVAL

SV*
get_raw_text(my_r, is_utf8 = 1)
    HTML::Content::Extractor my_r;
    int is_utf8;
    
    CODE:
        if(my_r->list == NULL || my_r->my == NULL || my_r->tags == NULL) {
            RETVAL = newSVsv(&PL_sv_undef);
        }
        else {
            struct lbuffer main_buff = {-1, 1024 * 1024, NULL};
            get_raw_text(my_r, &main_buff);
            
            if(main_buff.i < 0) {
                RETVAL = newSVsv(&PL_sv_undef);
            } else {
                if(is_utf8) {
                    SV *nm = newSVpv(main_buff.buff, main_buff.i);
                    SvUTF8_on(nm);
                    RETVAL = nm;
                } else {
                    RETVAL = newSVpv(main_buff.buff, main_buff.i);
                }
            }
            
            free(main_buff.buff);
        }
    OUTPUT:
        RETVAL

SV*
get_main_images(my_r, is_utf8 = 1, hashref = &PL_sv_undef, min_width = 100)
    HTML::Content::Extractor my_r;
    int is_utf8;
    SV *hashref;
    int min_width;
    
    CODE:
        //setbuf(stdout, NULL);
        AV* array = newAV();
        
        HV * myhash;
        HE * entry;
        STRLEN retlen;
        I32 len;
        
        char * key;
        SV * hashval;
        char *value;
        
        AV* arrayh;
        char **elements;
        int elem_size = -1;
        
        struct mem_stop_words *img_stop = NULL;
        
        if(SvROK(hashref)) {
            myhash = (HV *)SvRV(hashref);
            (void)hv_iterinit(myhash);
            while ((entry = hv_iternext(myhash)))  {
                key = hv_iterkey(entry,&len);
                hashval = hv_iterval(myhash,entry);
                
                if(SvROK(hashval) && SvTYPE(SvRV(hashval)) == SVt_PVAV) {
                    arrayh = (AV*)SvRV(hashval);
                    
                    elem_size = av_len(arrayh);
                    
                    char *tmp;
                    int i;
                    STRLEN len_s;
                    for (i = 0; i <= elem_size; i++) {
                        SV** elem = av_fetch(arrayh, i, 0);
                        char *nml = (char *)SvPV(*elem, len_s);
                        if(elem != NULL)
                            img_stop = add_stop_word_params(img_stop, key, (size_t)len, nml, (size_t)len_s);
                    }
                }
                else {
                    value = SvPV(hashval,retlen);
                    img_stop = add_stop_word_params(img_stop, key, (size_t)len, value, (size_t)retlen);
                    //printf("-gg------ %s(%ld), %s(%ld)\n", key, (size_t)len, value, (size_t)retlen);
                }
            }
        }
        
        if(my_r->list == NULL || my_r->my == NULL || my_r->tags == NULL) {
            RETVAL = newRV_noinc((SV*)array);
        }
        else {
            struct return_list *return_list = NULL;
            return_list = get_text_images_href(my_r, return_list, 0, img_stop, min_width);
            
            if(return_list->count < 0) {
                RETVAL = newRV_noinc((SV*)array);
            } else {
                if(is_utf8) {
                    long i;
                    for (i = 0; i <= return_list->real_count; i++) {
                        av_push(array, newRV_noinc((SV*)get_element_property_by_my(my_r, &return_list->list[i], 1)));
                        
                        //for (p = 0; p <= return_list->list[i].lparams; p++) {
                        //    printf("%s=%s\n", return_list->list[i].params[p].key, return_list->list[i].params[p].value);
                        //}
                    }
                    
                    RETVAL = newRV_noinc((SV*)array);
                } else {
                    long i;
                    for (i = 0; i <= return_list->real_count; i++) {
                        av_push(array, newRV_noinc((SV*)get_element_property_by_my(my_r, &return_list->list[i], 0)));
                    }
                    
                    RETVAL = newRV_noinc((SV*)array);
                }
            }
            
            img_stop = clean_stop_word_params(img_stop);
            
            return_list = clean_return_list(return_list);
        }
    OUTPUT:
        RETVAL

SV*
build_tree(my_r, html)
    HTML::Content::Extractor my_r;
    char *html;
    
    CODE:
        //setbuf(stdout, NULL);
        
        clean_tree(my_r);
        
        if(my_r->tags)
            free(my_r->tags);
        
        struct tags *tags = malloc(sizeof(struct tags));
        tags->count = -1;
        tags->csize = -1;
        my_r->tags = tags;
        
        my_r->html = html;
        html_tree(my_r);
        
        RETVAL = newSViv(1);
        
    OUTPUT:
        RETVAL

SV*
get_tree(my_r, inc_words_tag = 1)
    HTML::Content::Extractor my_r;
    int inc_words_tag;
    
    CODE:
        //setbuf(stdout, NULL);
        AV* array = newAV();
        
        long mi;
        for (mi = 1; mi <= my_r->count; ++mi) {
            long my_id = my_r->list[mi].my_id;
            
            if(my_r->list[mi].tag_id == DEFAULT_TAG_ID) {
                if( inc_words_tag > 0 )
                    av_push(array, newRV_noinc((SV*)get_element_property_deftag_by_id(my_r, mi, " ")));
                
                continue;
            }
            
            av_push(array, newRV_noinc((SV*)get_element_property_by_id(my_r, mi, inc_words_tag)));
        }
        
        RETVAL = newRV_noinc((SV*)array);
        
    OUTPUT:
        RETVAL

SV*
get_tree_by_element_id(my_r, id, inc_words_tag = 1)
    HTML::Content::Extractor my_r;
    long id;
    int inc_words_tag;
    
    CODE:
        if(id > my_r->count || id < 0) {
            RETVAL = &PL_sv_undef;
        }
        else {
            AV* array = newAV();
            
            int level = my_r->list[id].inc;
            
            long mi;
            for (mi = id + 1; mi <= my_r->count; ++mi) {
                if(my_r->list[mi].inc <= level)
                    break;
                
                long my_id = my_r->list[mi].my_id;
                
                if(my_r->list[mi].tag_id == DEFAULT_TAG_ID) {
                    if( inc_words_tag > 0 )
                        av_push(array, newRV_noinc((SV*)get_element_property_deftag_by_id(my_r, mi, " ")));
                    
                    continue;
                }
                
                av_push(array, newRV_noinc((SV*)get_element_property_by_id(my_r, mi, 1)));
            }
            
            RETVAL = newRV_noinc((SV*)array);
        }
        
    OUTPUT:
        RETVAL

SV*
get_element_by_name_in_child(my_r, name, pos = 0)
    HTML::Content::Extractor my_r;
    char *name;
    long pos;
    
    CODE:
        struct html_tree *element = get_element_by_name_in_child(my_r, name, pos);
        if(element != NULL) {
            RETVAL = newRV_noinc((SV*)get_element_property_by_id(my_r, element->id, 1));
        }
        else {
            RETVAL = &PL_sv_undef;
        }
        
    OUTPUT:
        RETVAL

SV*
get_element_by_name_in_level(my_r, name, pos = 0)
    HTML::Content::Extractor my_r;
    char *name;
    long pos;
    
    CODE:
        struct html_tree *element = get_element_by_name_in_level(my_r, name, pos);
        if(element != NULL) {
            RETVAL = newRV_noinc((SV*)get_element_property_by_id(my_r, element->id, 1));
        }
        else {
            RETVAL = &PL_sv_undef;
        }
        
    OUTPUT:
        RETVAL


SV*
get_element_by_name(my_r, name, pos = 0)
    HTML::Content::Extractor my_r;
    char *name;
    long pos;
    
    CODE:
        struct html_tree *element = get_element_by_name(my_r, name, pos);
        if(element != NULL) {
            RETVAL = newRV_noinc((SV*)get_element_property_by_id(my_r, element->id, 1));
        }
        else {
            RETVAL = &PL_sv_undef;
        }
        
    OUTPUT:
        RETVAL

SV*
get_stat_by_element_id(my_r, id)
    HTML::Content::Extractor my_r;
    long id;
    
    CODE:
        SV **ha;
        HV *hash = newHV();
        
        ha = hv_store(hash, "count", 5, newSViv(my_r->list[id].count_element), 0);
        ha = hv_store(hash, "all", 3, newSViv(my_r->list[id].count_element_in), 0);
        ha = hv_store(hash, "words", 5, newSViv(my_r->list[id].count_word), 0);
        
        ha = hv_store(hash, "AI_TEXT", 7, newSViv(my_r->list[id].counts[AI_TEXT]), 0);
        ha = hv_store(hash, "AI_LINK", 7, newSViv(my_r->list[id].counts[AI_LINK]), 0);
        ha = hv_store(hash, "AI_IMG" , 6, newSViv(my_r->list[id].counts[AI_IMG]) , 0);
        
        ha = hv_store(hash, "all_AI_LINK", 11, newSViv(my_r->list[id].counts_in[AI_TEXT]), 0);
        ha = hv_store(hash, "all_AI_LINK", 11, newSViv(my_r->list[id].counts_in[AI_LINK]), 0);
        ha = hv_store(hash, "all_AI_IMG" , 10, newSViv(my_r->list[id].counts_in[AI_IMG]) , 0);
        
        RETVAL = newRV_noinc((SV*)hash);
    OUTPUT:
        RETVAL

SV*
get_tag_info_by_name(my_r, tag_name)
    HTML::Content::Extractor my_r;
    char *tag_name;
    
    CODE:
        SV **ha;
        HV *hash = newHV();
        
        int tag_id = get_tag_id(my_r->tags, tag_name);
        
        ha = hv_store(hash, "priority", 8, newSViv(my_r->tags->priority[tag_id]), 0);
        ha = hv_store(hash, "type", 4, newSViv(my_r->tags->type[tag_id]), 0);
        ha = hv_store(hash, "extra", 5, newSViv(my_r->tags->extra[tag_id]), 0);
        ha = hv_store(hash, "ai", 2, newSViv(my_r->tags->ai[tag_id]), 0);
        ha = hv_store(hash, "family", 6, newSViv(my_r->tags->family[tag_id]), 0);
        ha = hv_store(hash, "option" , 6, newSViv(my_r->tags->option[tag_id]) , 0);
        
        RETVAL = newRV_noinc((SV*)hash);
    OUTPUT:
        RETVAL


SV*
get_child(my_r, pos)
    HTML::Content::Extractor my_r;
    long pos;
    
    CODE:
        struct html_tree *element = get_child(my_r, pos);
        if(element != NULL) {
            RETVAL = newRV_noinc((SV*)get_element_property_by_id(my_r, element->id, 1));
        }
        else {
            RETVAL = &PL_sv_undef;
        }
        
    OUTPUT:
        RETVAL

SV*
get_parent(my_r)
    HTML::Content::Extractor my_r;
    
    CODE:
        struct html_tree *element = get_parent(my_r);
        if(element != NULL) {
            RETVAL = newRV_noinc((SV*)get_element_property_by_id(my_r, element->id, 1));
        }
        else {
            RETVAL = &PL_sv_undef;
        }
        
    OUTPUT:
        RETVAL

SV*
get_curr_element(my_r)
    HTML::Content::Extractor my_r;
    
    CODE:
        struct html_tree *element = get_curr_element(my_r);
        if(element != NULL) {
            RETVAL = newRV_noinc((SV*)get_element_property_by_id(my_r, element->id, 1));
        }
        else {
            RETVAL = &PL_sv_undef;
        }
        
    OUTPUT:
        RETVAL

SV*
get_prev_element(my_r)
    HTML::Content::Extractor my_r;
    
    CODE:
        struct html_tree *element = get_prev_element(my_r);
        if(element != NULL) {
            RETVAL = newRV_noinc((SV*)get_element_property_by_id(my_r, element->id, 1));
        }
        else {
            RETVAL = &PL_sv_undef;
        }
        
    OUTPUT:
        RETVAL

SV*
get_next_element_curr_level(my_r)
    HTML::Content::Extractor my_r;
    
    CODE:
        struct html_tree *element = get_next_element_curr_level(my_r);
        if(element != NULL) {
            RETVAL = newRV_noinc((SV*)get_element_property_by_id(my_r, element->id, 1));
        }
        else {
            RETVAL = &PL_sv_undef;
        }
        
    OUTPUT:
        RETVAL

SV*
get_prev_element_curr_level(my_r)
    HTML::Content::Extractor my_r;
    
    CODE:
        struct html_tree *element = get_prev_element_curr_level(my_r);
        if(element != NULL) {
            RETVAL = newRV_noinc((SV*)get_element_property_by_id(my_r, element->id, 1));
        }
        else {
            RETVAL = &PL_sv_undef;
        }
        
    OUTPUT:
        RETVAL

SV*
set_position(my_r, hashref)
    HTML::Content::Extractor my_r;
    SV *hashref;
    
    CODE:
        HV *myhash = (HV *)SvRV(hashref);
        SV **svp = hv_fetch(myhash, "id", 2, 0);
        int el_id = SvNV(*svp);
        
        if(set_position(my_r, &my_r->list[el_id]) != -1) {
            RETVAL = newRV_noinc((SV*)get_element_property_by_id(my_r, el_id, 1));
        }
        else {
            RETVAL = &PL_sv_undef;
        }
        
    OUTPUT:
        RETVAL

SV*
check_html_with_all_text(my_r)
    HTML::Content::Extractor my_r;
    
    CODE:
        struct max_element_list max_list = {-1, 1024};
        max_list.elements = (struct max_element *)malloc(sizeof(struct max_element) * max_list.lelements_size);
        
        check_html_with_all_text(my_r, &max_list);
        
        AV* array = newAV();
        SV **ha;
        
        long i;
        for (i = 0; i <= max_list.lelements; i++) {
            set_position(my_r, max_list.elements[i].element);
            
            struct lbuffer main_buff = {-1, 1024 * 1024, NULL};
            get_text_without_element(my_r, &main_buff);
            clean_text(my_r->entities, &main_buff);
            
            HV *hash = newHV();
            
            ha = hv_store(hash, "text", 4, newSVpv(main_buff.buff, 0), 0);
            ha = hv_store(hash, "element", 7, newRV_noinc((SV*)get_element_property_by_id(my_r, max_list.elements[i].element->id, 1)), 0);
            
            av_push(array, newRV_noinc((SV*)hash));
            
            free(main_buff.buff);
        }
        
        free(max_list.elements);
        
        RETVAL = newRV_noinc((SV*)array);
        
    OUTPUT:
        RETVAL

SV*
set_tag_ai(my_r, tagname, value)
    HTML::Content::Extractor my_r;
    char *tagname;
    int value;
    
    CODE:
        RETVAL = newSViv( set_tag_ai(my_r->tags, tagname, value) );
    OUTPUT:
        RETVAL

SV*
set_tag_type(my_r, tagname, value)
    HTML::Content::Extractor my_r;
    char *tagname;
    int value;
    
    CODE:
        RETVAL = newSViv( set_tag_type(my_r->tags, tagname, value) );
    OUTPUT:
        RETVAL

SV*
set_tag_extra(my_r, tagname, value)
    HTML::Content::Extractor my_r;
    char *tagname;
    int value;
    
    CODE:
        RETVAL = newSViv( set_tag_extra(my_r->tags, tagname, value) );
    OUTPUT:
        RETVAL

SV*
set_tag_family(my_r, tagname, value)
    HTML::Content::Extractor my_r;
    char *tagname;
    int value;
    
    CODE:
        RETVAL = newSViv( set_tag_family(my_r->tags, tagname, value) );
    OUTPUT:
        RETVAL

SV*
set_tag_option(my_r, tagname, value)
    HTML::Content::Extractor my_r;
    char *tagname;
    int value;
    
    CODE:
        RETVAL = newSViv( set_tag_option(my_r->tags, tagname, value) );
    OUTPUT:
        RETVAL

SV*
set_tag_priority(my_r, tagname, value)
    HTML::Content::Extractor my_r;
    char *tagname;
    int value;
    
    CODE:
        RETVAL = newSViv( set_tag_priority(my_r->tags, tagname, value) );
    OUTPUT:
        RETVAL


SV*
AI_NULL()
    CODE:
        RETVAL = newSViv(AI_NULL);
    OUTPUT:
        RETVAL

SV*
AI_TEXT()
    CODE:
        RETVAL = newSViv(AI_TEXT);
    OUTPUT:
        RETVAL

SV*
AI_LINK()
    CODE:
        RETVAL = newSViv(AI_LINK);
    OUTPUT:
        RETVAL

SV*
AI_IMG()
    CODE:
        RETVAL = newSViv(AI_IMG);
    OUTPUT:
        RETVAL


SV*
TYPE_TAG_NORMAL()
    CODE:
        RETVAL = newSViv(TYPE_TAG_NORMAL);
    OUTPUT:
        RETVAL

SV*
TYPE_TAG_BLOCK()
    CODE:
        RETVAL = newSViv(TYPE_TAG_BLOCK);
    OUTPUT:
        RETVAL

SV*
TYPE_TAG_INLINE()
    CODE:
        RETVAL = newSViv(TYPE_TAG_INLINE);
    OUTPUT:
        RETVAL

SV*
TYPE_TAG_SIMPLE()
    CODE:
        RETVAL = newSViv(TYPE_TAG_SIMPLE);
    OUTPUT:
        RETVAL

SV*
TYPE_TAG_SIMPLE_TREE()
    CODE:
        RETVAL = newSViv(TYPE_TAG_SIMPLE_TREE);
    OUTPUT:
        RETVAL

SV*
TYPE_TAG_ONE()
    CODE:
        RETVAL = newSViv(TYPE_TAG_ONE);
    OUTPUT:
        RETVAL

SV*
TYPE_TAG_TEXT()
    CODE:
        RETVAL = newSViv(TYPE_TAG_TEXT);
    OUTPUT:
        RETVAL

SV*
TYPE_TAG_SYS()
    CODE:
        RETVAL = newSViv(TYPE_TAG_SYS);
    OUTPUT:
        RETVAL


SV*
DEFAULT_TAG_ID()
    CODE:
        RETVAL = newSViv(DEFAULT_TAG_ID);
    OUTPUT:
        RETVAL


SV*
EXTRA_TAG_CLOSE_IF_BLOCK()
    CODE:
        RETVAL = newSViv(EXTRA_TAG_CLOSE_IF_BLOCK);
    OUTPUT:
        RETVAL

SV*
EXTRA_TAG_CLOSE_IF_SELF()
    CODE:
        RETVAL = newSViv(EXTRA_TAG_CLOSE_IF_SELF);
    OUTPUT:
        RETVAL

SV*
EXTRA_TAG_CLOSE_IF_SELF_FAMILY()
    CODE:
        RETVAL = newSViv(EXTRA_TAG_CLOSE_IF_SELF_FAMILY);
    OUTPUT:
        RETVAL

SV*
EXTRA_TAG_CLOSE_NOW()
    CODE:
        RETVAL = newSViv(EXTRA_TAG_CLOSE_NOW);
    OUTPUT:
        RETVAL

SV*
EXTRA_TAG_SIMPLE()
    CODE:
        RETVAL = newSViv(EXTRA_TAG_SIMPLE);
    OUTPUT:
        RETVAL

SV*
EXTRA_TAG_SIMPLE_TREE()
    CODE:
        RETVAL = newSViv(EXTRA_TAG_SIMPLE_TREE);
    OUTPUT:
        RETVAL

SV*
EXTRA_TAG_CLOSE_PRIORITY()
    CODE:
        RETVAL = newSViv(EXTRA_TAG_CLOSE_PRIORITY);
    OUTPUT:
        RETVAL

SV*
EXTRA_TAG_CLOSE_FAMILY_LIST()
    CODE:
        RETVAL = newSViv(EXTRA_TAG_CLOSE_FAMILY_LIST);
    OUTPUT:
        RETVAL

SV*
EXTRA_TAG_CLOSE_PRIORITY_FAMILY()
    CODE:
        RETVAL = newSViv(EXTRA_TAG_CLOSE_PRIORITY_FAMILY);
    OUTPUT:
        RETVAL


SV*
FAMILY_H()
    CODE:
        RETVAL = newSViv(FAMILY_H);
    OUTPUT:
        RETVAL

SV*
FAMILY_TABLE()
    CODE:
        RETVAL = newSViv(FAMILY_TABLE);
    OUTPUT:
        RETVAL

SV*
FAMILY_LIST()
    CODE:
        RETVAL = newSViv(FAMILY_LIST);
    OUTPUT:
        RETVAL

SV*
FAMILY_RUBY()
    CODE:
        RETVAL = newSViv(FAMILY_RUBY);
    OUTPUT:
        RETVAL

SV*
FAMILY_SELECT()
    CODE:
        RETVAL = newSViv(FAMILY_SELECT);
    OUTPUT:
        RETVAL

SV*
FAMILY_HTML()
    CODE:
        RETVAL = newSViv(FAMILY_HTML);
    OUTPUT:
        RETVAL


SV*
OPTION_NULL()
    CODE:
        RETVAL = newSViv(OPTION_NULL);
    OUTPUT:
        RETVAL

SV*
OPTION_CLEAN_TAGS()
    CODE:
        RETVAL = newSViv(OPTION_CLEAN_TAGS);
    OUTPUT:
        RETVAL

SV*
OPTION_CLEAN_TAGS_SAVE()
    CODE:
        RETVAL = newSViv(OPTION_CLEAN_TAGS_SAVE);
    OUTPUT:
        RETVAL


void
DESTROY(my_r)
    HTML::Content::Extractor my_r;
    
    CODE:
        my_r->swords = clean_stop_word_params(my_r->swords);
        
        clean_tree_entity(my_r->entities);
        if(my_r->entities)
            free(my_r->entities);
        
        if(my_r) {
            clean_tree(my_r);
            
            if(my_r->tags)
                free(my_r->tags);
            
            free(my_r);
        }
