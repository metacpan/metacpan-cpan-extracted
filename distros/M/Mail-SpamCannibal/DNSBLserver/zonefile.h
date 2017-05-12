/* zonefile.h	*/
u_int32_t ratelimit(int run);
void initlb();
void tabout(char * bp, char * name, char * type);
void add_A_rec(char * bp, char * name, u_int32_t * ip);
void ishift();
void precrd(FILE * fd, char * bp, char * name, u_int32_t resp, char * txt);
void oflush(FILE * fd, char * bp);
void oprint(FILE * fd, char * bp, u_char new, char * pre);
void iload(u_char * iptr, u_int32_t * A_resp, char * txt);
void iprint(FILE * fd, char * bp);
int zonefile(FILE * fd);

