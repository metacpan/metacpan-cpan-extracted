/* ns_func.h	*/
int munge_msg(int fd, size_t msglen, int is_tcp);
char * errIP();
u_int32_t * ns_response(u_char * keydbt_data);
int cmp_serial(u_int32_t s1, u_int32_t s2);
int not_numericIP(char * ip);
