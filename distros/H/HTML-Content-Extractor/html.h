//
//  Created by Alexander Borisov on 10.01.13.
//  Copyright (c) 2013 Alexander Borisov. All rights reserved.
//

#include <stdio.h>
#include <ctype.h>
#include <math.h>
#include <stdlib.h>
#include <memory.h>
# if !defined( WIN32 )
#   include <unistd.h>
# endif

#define TYPE_TAG_IS_OPEN   100
#define TYPE_TAG_IS_CLOSE  200
#define TYPE_TAG_IS_SIMPLE 1

#define TYPE_TAG_NORMAL 10
#define TYPE_TAG_BLOCK  21
#define TYPE_TAG_INLINE 32
#define TYPE_TAG_SIMPLE 43
#define TYPE_TAG_SIMPLE_TREE 54
#define TYPE_TAG_ONE    65
#define TYPE_TAG_TEXT   76
#define TYPE_TAG_SYS    87

#define TYPE_TAG_CLOSE_BY_FAMILY  76

#define DEFAULT_TAG_ID  0

#define EXTRA_TAG_CLOSE_IF_BLOCK 1
#define EXTRA_TAG_CLOSE_IF_SELF  2
#define EXTRA_TAG_CLOSE_IF_SELF_FAMILY  3
#define EXTRA_TAG_CLOSE_NOW  4
#define EXTRA_TAG_SIMPLE  5
#define EXTRA_TAG_SIMPLE_TREE 6
#define EXTRA_TAG_CLOSE_PRIORITY 7
#define EXTRA_TAG_CLOSE_FAMILY_LIST 8
#define EXTRA_TAG_CLOSE_PRIORITY_FAMILY 9

#define FAMILY_H     1
#define FAMILY_TABLE 2
#define FAMILY_LIST  3
#define FAMILY_RUBY  4
#define FAMILY_SELECT 5
#define FAMILY_HTML   6

#define AI_BUFF 4
#define AI_NULL 0
#define AI_TEXT 1
#define AI_LINK 2
#define AI_IMG  3

#define OPTION_NULL 100
#define OPTION_CLEAN_TAGS 101
#define OPTION_CLEAN_TAGS_SAVE 102

struct mem_params {
    char *key;
    int  lkey;
    int  lkey_size;
    char *value;
    int  lvalue;
    int  lvalue_size;
};

struct mem_stop_words {
    struct mem_params *mem_params;
    long lparams;
    size_t params_size;
};

struct mem_tag {
    char qo;
    int qol;
    
    long start_otag;
    long stop_otag;
    
    int type;
    int tag_id;
    
    long lparams;
    long lparams_size;
    struct mem_params *params;
};

struct return_list {
    long count;
    long real_count;
    struct mem_tag *list;
};

struct tags_index {
    long **tag_id;
    int *tag_count;
    int *tag_csize;
};

struct tags {
    int count;
    int csize;
    char **name;
    int *priority;
    int *type;
    int *extra;
    int *ai;
    int *family;
    int *option;
    struct tags_index index;
};

struct html_tree {
    long id;
    
    long tag_body_start;
    long tag_body_stop;
    long tag_start;
    long tag_stop;
    
    int tag_id;
    int inc;
    long my_id;
    int count_element;
    int count_element_in;
    int counts[AI_BUFF];
    int counts_in[AI_BUFF];
    int count_word;
};

struct tree_list {
    long count;
    long real_count;
    struct html_tree *list;
    
    struct mem_tag *my;
    long my_count;
    long my_real_count;
    
    long cur_pos;
    long nco_pos;
    char *html;
    struct tags *tags;
    struct tree_entity *entities;
    struct tags_family *tags_family;
    struct mem_stop_words *swords;
};

struct max_element {
    long count_words;
    struct html_tree *element;
};

struct max_element_list {
    long lelements;
    long lelements_size;
    struct max_element *elements;
};

struct lbuffer {
    long i;
    size_t buff_size;
    char *buff;
};

struct mlist {
    long i;
    size_t buff_size;
    char **buff;
};

struct tree_entity {
    int count;
    struct tree_entity *next;
    char value[5];
    int level;
};

struct elements {
    long *index;
    int lindex;
    long lindex_size;
    
    struct html_tree *tree;
    long ltree;
    long ltree_size;
    
    int count;
    int is_base;
    
    long next;
    long prev;
    long last_element_id;
};

struct tree_jail {
    struct elements *elements;
    long lelements;
    long lelements_size;
    int family;
    long curr_element;
};

struct tags_family {
    int **tags;
    int itags;
    int itags_size;
    int **rtags;
    int irtags;
    int irtags_size;
};

typedef struct tree_list my_tree_list;

int add_tag_R(struct tags *, char *, size_t, int, int, int, int, int, int);
int add_tag(struct tags *, char *, struct mem_tag *);

int set_tag_ai(struct tags *, char *, int);
int set_tag_type(struct tags *, char *, int);
int set_tag_extra(struct tags *, char *, int);
int set_tag_family(struct tags *, char *, int);
int set_tag_option(struct tags *, char *, int);
int set_tag_priority(struct tags *, char *, int);

int init_tags(struct tags *);
int check_tags_alloc(struct tags *);

void html_tree(struct tree_list *);

int get_tag_id(struct tags *, char *);

// если потомка или родителя нет то возвращает NULL, указатель в структуре остается на том же уровне
// перемещает указатель в структуре на потомка и возвращает его
struct html_tree * get_child(struct tree_list *, long);
// все, что с _n на конце не устанавливает блобальную позицию
struct html_tree * get_child_n(struct tree_list *, long);
// перемещает указатель на родителя и возвращает его
struct html_tree * get_parent(struct tree_list *);

// вернет текущий элемент
struct html_tree * get_curr_element(struct tree_list *);

// если на тек. уровне больше нет элементов то возвращает NULL, указатель в структуре остается на том же уровне
// перемещает указатель на следующий элемент этого же уровня и возвращает его
struct html_tree * get_next_element_curr_level(struct tree_list *);
// перемещает указатель на предыдущий элемент этого же уровня и возвращает его
struct html_tree * get_prev_element_curr_level(struct tree_list *);

// возвращает указатель на следующий эелемент в тек. уровне без учера внутрених уровней
struct html_tree * get_next_element_in_level(struct tree_list *);
// возвращает указатель на предыдущий эелемент в тек. уровне без учера внутрених уровней
struct html_tree * get_prev_element_in_level(struct tree_list *);
// возвращает указатель на следующий элемент пропуская текущий и все его вложения, в текущем уровне
struct html_tree * get_next_element_in_level_skip_curr(struct tree_list *);
// возвращает указатель на родителя
struct html_tree * get_parent_in_level(struct tree_list *, int);

// перемещает указатель на следующий элемент пропуская текущий и все его вложения
struct html_tree * get_next_element_skip_curr(struct tree_list *);

// перемещает указатель на следующий элемент вне зависимости от вложений и возвращает его
struct html_tree * get_next_element(struct tree_list *);
// перемещает указатель на предыдущий элемент вне зависимости от вложений и возвращает его
struct html_tree * get_prev_element(struct tree_list *);

// ищет указанный элемент со смещением long
struct html_tree * get_element_by_name(struct tree_list *, char *, long);
// ищет указанный элемент в подчиненных элементах со смещением long
struct html_tree * get_element_by_name_in_child(struct tree_list *, char *, long);
struct html_tree * get_element_by_name_in_level(struct tree_list *, char *, long);
struct html_tree * get_element_by_tag_id(struct tree_list *, int, long);

// отдает количество тегов по имени тега, счет идет с 1
int get_count_element_by_name(struct tree_list *, char *);
// отдает реальное количество тегов по имени тега, счет идет с 0
int get_real_count_element_by_name(struct tree_list *, char *);

// перемещает указатель на позицию переданного элемента, возвращяет номер позиции, если не удалось то -1
long set_position(struct tree_list *, struct html_tree *);

// возвращает размер тела элемента, если html_tree указан как NULL то вернет размер текущего элемента
// ни каких проходов или еще чего тут нет, работает молниеносно, код определения размера до безумия прост:
// return element->tag_body_stop - element->tag_body_start;
long get_element_body_size(struct tree_list *, struct html_tree *);
// возвращает указатель на char из основного html текста с указанного элемента (html_tree) или если он NULL то с текущего
// важно помнить, что \0 в конце не ожидается так как вернется указатель с начала тела элемента,
// а по оканчании продолжается html документ
// по-этому, чтобы узнать размер используем get_element_body_size
char * get_element_body(struct tree_list *, struct html_tree *);

// работа с элементами и их параметрами

// поиск параметра по ключу в переданном элементе
struct mem_params * find_param_by_key_in_element(struct mem_tag *, char *);

struct html_tree * check_html(struct tree_list *, struct max_element *);
void check_html_with_all_text(struct tree_list *, struct max_element_list *);

void get_raw_text(struct tree_list *, struct lbuffer *);
void get_text_without_element(struct tree_list *, struct lbuffer *);
void get_text_with_element(struct tree_list *, struct lbuffer *, char **, int);
struct return_list * get_text_images_href(struct tree_list *, struct return_list *, int, struct mem_stop_words *, int);

void clean_text(struct tree_entity *, struct lbuffer *);

int cmp_tags(struct tags *, char *, struct mem_tag *, int);

void clean_tree(struct tree_list *);

// html entities
struct tree_entity * create_entity_tree(void);
void clean_tree_entity(struct tree_entity *);

struct tree_entity * check_entity(struct tree_entity *, char *);
void add_entity(struct tree_entity *, char *, char *);

int get_count_to_next_element_in_level(struct tree_list *, struct html_tree *);

struct mem_stop_words * add_stop_word_params(struct mem_stop_words *, char *, size_t , char *, size_t);
void * clean_stop_word_params(struct mem_stop_words *);
int find_stop_word_param(struct mem_stop_words *, struct mem_tag *);

int compare_param_by_nt(struct mem_params *, char *, size_t );
void * clean_return_list(struct return_list *);


typedef struct tree_list htmltag_t;
