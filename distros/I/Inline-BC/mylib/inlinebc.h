
void my_perl_bc_init(int);

void my_init_parse_stash(void);

void my_init_output(void);

void my_addto_parse_stash(char * str);

void my_addto_output(char ch);

char * my_current_stash(void);

char * my_current_output(void);

char * my_perl_bc_parse(char * str);

char * my_perl_bc_run(char * str);

