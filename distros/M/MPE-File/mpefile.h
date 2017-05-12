extern void HPFOPEN(int parm_ct,
            int     *filenum,
            int     *status,
	    int parm0,	void *parmval0,
	    int parm1,	void *parmval1,
	    int parm2,	void *parmval2,
	    int parm3,	void *parmval3,
	    int parm4,	void *parmval4,
	    int parm5,	void *parmval5,
	    int parm6,	void *parmval6,
	    int parm7,	void *parmval7,
	    int parm8,	void *parmval8,
	    int parm9,	void *parmval9,
	    int parm10,	void *parmval10,
	    int parm11,	void *parmval11,
	    int parm12,	void *parmval12,
	    int parm13,	void *parmval13,
	    int parm14,	void *parmval14,
	    int parm15,	void *parmval15,
	    int parm16,	void *parmval16,
	    int parm17,	void *parmval17,
	    int parm18,	void *parmval18,
	    int parm19,	void *parmval19,
	    int parm20,	void *parmval20,
	    int parm21,	void *parmval21,
	    int parm22,	void *parmval22,
	    int parm23,	void *parmval23,
	    int parm24,	void *parmval24,
	    int parm25,	void *parmval25,
	    int parm26,	void *parmval26,
	    int parm27,	void *parmval27,
	    int parm28,	void *parmval28,
	    int parm29,	void *parmval29,
	    int parm30,	void *parmval30,
	    int parm31,	void *parmval31,
	    int parm32,	void *parmval32,
	    int parm33,	void *parmval33,
	    int parm34,	void *parmval34,
	    int parm35,	void *parmval35,
	    int parm36,	void *parmval36,
	    int parm37,	void *parmval37,
	    int parm38,	void *parmval38,
	    int parm39,	void *parmval39,
	    int parm40,	void *parmval40,
	    int parm41,	void *parmval41);

extern void HPERRMSG(int parm_ct,
                     int      displaycode,
                     int      depth,
                     int      errorproc,
                     int      errornum,
                     char    *buffer,
                     short   *buflength,
                     int     *status);

extern short FREAD(short    parm1,
                   longpointer parm2,
                   short    parm3);

extern void FWRITE(short     parm1,
                   longpointer  parm2,
                   short     parm3,
                   ushort    parm4 );

extern void FCHECK(short    parm1,	/* optional */
                   short   *parm2,	/* optional */
                   short   *parm3,	/* optional */
                   int     *parm4,	/* optional */
                   short   *parm5 );	/* optional */

extern void FCLOSE(short    parm1,
                   short    parm2,
                   short    parm3 );
extern void FLOCK(short    parm1,
                  ushort   parm2 );

extern void FPOINT(short    parm1,
                   int      parm2 );

extern void FCONTROL(short    parm1,
                     short    parm2,
		     longpointer parm3); /* ushort  ^parm3 ); */

extern void FDELETE(short    parm1,
                    int      parm2 );	/* default -1 */

extern void FDEVICECONTROL(short    parm1,
                           longpointer parm2,
                           short    parm3,
                           short    parm4,
                           ushort   parm5,
                           ushort   parm6,
                           ushort  *parm7 );

extern void FERRMSG(short   *parm1,
                    char    *parm2,
                    short   *parm3 );

extern void FFINDBYKEY(short    parm1,
                       longpointer parm2,
                       short    parm3,
                       short    parm4,
                       short    parm5 );

extern void FFILEINFO(short    parm1,
                      short    parm2,	/* optional */
                      void    *parm3,	/* optional */
                      short    parm4,	/* optional */
                      void    *parm5,	/* optional */
                      short    parm6,	/* optional */
                      void    *parm7,	/* optional */
                      short    parm8,	/* optional */
                      void    *parm9,	/* optional */
                      short    parm10,	/* optional */
                      void    *parm11 );	/* optional */
extern void FFINDN(short    parm1,
                   int      parm2,
                   short    parm3 );
extern void FGETINFO(short    parm1,
                     char    *parm2,	/* optional */
                     ushort  *parm3,	/* optional */
                     ushort  *parm4,	/* optional */
                     short   *parm5,	/* optional */
                     short   *parm6,	/* optional */
                     ushort  *parm7,	/* optional */
                     ushort  *parm8,	/* optional */
                     short   *parm9,	/* optional */
                     int     *parm10,	/* optional */
                     int     *parm11,	/* optional */
                     int     *parm12,	/* optional */
                     int     *parm13,	/* optional */
                     int     *parm14,	/* optional */
                     short   *parm15,	/* optional */
                     ushort  *parm16,	/* optional */
                     short   *parm17,	/* optional */
                     short   *parm18,	/* optional */
                     char    *parm19,	/* optional */
                     int     *parm20 );	/* optional */
extern void FGETKEYINFO(short    parm1,
                        char    *parm2,
                        char    *parm3 );
extern void FLOCK(short    parm1,
                  ushort   parm2 );
extern short FOPEN(char    *parm1,	/* optional */
                   ushort   parm2,	/* optional */
                   ushort   parm3,	/* optional */
                   short    parm4,	/* optional */
                   char    *parm5,	/* optional */
                   char    *parm6,	/* optional */
                   short    parm7,	/* optional */
                   short    parm8,	/* optional */
                   short    parm9,	/* optional */
                   int      parm10,	/* optional */
                   short    parm11,	/* optional */
                   short    parm12,	/* optional */
                   short    parm13 );	/* optional */
extern void FPOINT(short    parm1,
                   int      parm2 );
extern short FREAD(short    parm1,
                   longpointer parm2,
                   short    parm3 );
extern short FREADBYKEY(short    parm1,
                        longpointer parm2,
                        short    parm3,
                        longpointer parm4,
                        short    parm5 );
extern short FREADBACKWARD(short    parm1,
                           longpointer parm2,
                           short    parm3 );
extern short FREADC(short    parm1,
                    longpointer parm2,
                    short    parm3 );
extern void FREADDIR(short    parm1,
                     longpointer parm2,
                     short    parm3,
                     int      parm4 );
extern void FREADLABEL(short    parm1,
                       longpointer parm2,
                       short    parm3,	/* default 0x80 */
                       short    parm4 );	/* optional */
extern void FREADSEEK(short    parm1,
                      int      parm2 );
extern ushort FRELATE(short    parm1,
                      short    parm2 );
extern void FREMOVE(short    parm1 );
extern void FRENAME(short    parm1,
                    char    *parm2 );
extern void FSETMODE(short    parm1,
                     ushort   parm2 );
extern void FSPACE(short    parm1,
                   short    parm2 );
extern void FUNLOCK(short    parm1 );
extern void FUPDATE(short    parm1,
                    longpointer parm2,
                    short    parm3 );
extern void FWRITE(short    parm1,
                   longpointer parm2,
                   short    parm3,
                   ushort   parm4 );
extern void FWRITEDIR(short    parm1,
                      longpointer parm2,
                      short    parm3,
                      int      parm4 );
extern void FWRITELABEL(short    parm1,
                        longpointer parm2,
                        short    parm3,	/* default 0x80 */
                        short    parm4 );	/* optional */
extern short IODONTWAIT(short    parm1,	/* optional */
                        longpointer parm2,	/* optional */
                        short   *parm3,	/* optional */
                        ushort  *parm4 );	/* optional */
extern short IOWAIT(short    parm1,	/* optional */
                    longpointer parm2,	/* optional */
                    short   *parm3,	/* optional */
                    ushort  *parm4 );	/* optional */
extern void FLABELINFO(char    *parm1,
                       short    parm2,
                       short   *parm3,
                       char    *parm4,
                       char    *parm5,
                       char    *parm6 );
extern void PRINT(longpointer parm1,
                  short    parm2,
                  short    parm3 );
extern void PRINTOP(char *parm1,
                  short    parm2,
                  short     parm3 );
extern short PRINTOPREPLY(char    *parm1,
                          short    parm2,
                          short    parm3,
                          char    *parm4,
                          short    parm5 );
extern void PRINTFILEINFO(short    parm1 );
extern short READX(longpointer parm1,
                   short    parm2 );
extern int HPSELECT(int      parm1,
                    char    *parm2,	/* optional */
                    char    *parm3,	/* optional */
                    char    *parm4,	/* optional */
                    char    *parm5,	/* optional */
                    char    *parm6 );	/* optional */
extern void HPPIPE(int parm_ct,
                   int     *parm1,
                   int     *parm2,
                   char    *parm3 );	/* optional */
extern short READ(longpointer parm1,
                  short    parm2 );
