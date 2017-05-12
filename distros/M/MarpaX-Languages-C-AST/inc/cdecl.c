char x, *y, (*z)[5], zz[10][11], (*zzz)[13][14], *zzz2[13][14];
typedef struct myStruct {
  long long int (*fp)(char (*((*f)(char arg1, long arg2, float (*(*(*(arg3)[5])[6]))))));
} myStruct_t;

/* From http://www.geeksforgeeks.org/complicated-declarations-in-c/ */
void (*bsd_signal(int, void (*)(int)))(int);
int (*fp) ();
int (*daytab)[13];
void (*f[10]) (int, int);
char (*(*x())[]) ();
char (*(*x[3])())[5];
int *(*(*arr[5])()) ();
void (*bsd_signal(int sig, void (*func)(int)))(int);

/* From http://stackoverflow.com/questions/1448849/how-to-understand-complicated-function-declarations */
int **(*f)(int**,int**(*)(int **,int **));

/* From http://ieng9.ucsd.edu/~cs30x/rt_lt.rule.html */
int (*(*fun_one)(char *,double))[9][20];
int i;
int *p;
int a[];
int f();
int **pp;
int (*pa)[];
int (*pf)();
int *ap[];
int aa[][];
int af[]();
int *fp();
int fa()[];
int ***ppp;
int (**ppa)[];
int (**ppf)();
int *(*pap)[];
int (*paa)[][];
int *(*pfp)();
int **app[];
int (*apa[])[];
int (*apf[])();
int *aap[][];
int aaa[][][];
int *afp[]();
int **fpp();
int (*fpa())[];
int (*fpf())();
int *fap()[];

/* From http://www.programminglogic.com/interpreting-complex-c-declarations/ */
float * (* (*ptr)(int))(double **,char c);
unsigned **( * (*ptr) [5] ) (char const *,int *);
