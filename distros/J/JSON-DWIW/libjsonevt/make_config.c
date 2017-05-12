
#ifdef __GNUC__
#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#endif

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <fcntl.h>

char *g_test_file = "test_config.c";
char *g_types[ ] = { "unsigned char", "unsigned short", "unsigned int", "unsigned long" };

static int
do_system_with_redirect(int argc, char *const argv[ ], FILE *stdout_redir, FILE *stderr_redir) {
    char **arg_list;
    int i = 0;
    pid_t pid;
    int status = 0;
    int rv;

    arg_list = (char **)malloc((argc + 1) * sizeof(char *));
    
    for (i = 0; i < argc; i++) {
        arg_list[i] = argv[i];
    }

    /* arg_list must be null-terminated */
    arg_list[argc] = NULL;

    fflush(NULL); /* flush all output streams */

    pid = fork();
    if (pid == -1) {
        /* error */
        return 1;
    }

    if (pid == 0) {
        /* child */
        
        if (stdout_redir) {
            close(1);
            fcntl(fileno(stdout_redir), F_DUPFD, 1);
        }

        if (stderr_redir) {
            close(2);
            fcntl(fileno(stdout_redir), F_DUPFD, 2);
        }

        rv = execvp(arg_list[0], arg_list);
        fprintf(stderr, "execvp failed with val %d\n", rv);
        exit(1);
    }
    else {
        /* parent */
        free(arg_list);
        waitpid(pid, &status, 0);
        if (WIFEXITED(status)) {
            /* called exit */

            return WEXITSTATUS(status);
        }
    }
    
    return 1;
}

static int
do_system_with_file_redirect(int argc, char *const argv[ ], const char *file) {
    int rv;
    FILE *fp = fopen(file, "a");
    
    if (! fp) {
        return 2;
    }

    rv = do_system_with_redirect(argc, argv, fp, fp);

    fclose(fp);

    return rv;
}

/*
static int
do_system(int argc, char *const argv[ ]) {
    return do_system_with_redirect(argc, argv, NULL, NULL);
}
*/

static void
print_head(FILE *fp) {
    fprintf(fp, "\n");
    fprintf(fp, "#ifndef JSONEVT_CONFIG_H\n");
    fprintf(fp, "#define JSONEVT_CONFIG_H\n");
    fprintf(fp, "\n");
}

static void
print_foot(FILE *fp) {
    fprintf(fp, "\n#endif /* JSONEVT_CONFIG_H */\n");
}

static FILE *
sync_header(FILE *cur_fp, const char *new_file) {
    FILE *fp = fopen(new_file, "w");
    char buf[1024];
    int amt_read;
    int amt_w = 0;

    fseek(cur_fp, 0, 0);
    while ( (amt_read = fread(buf, 1, 1024, cur_fp)) > 0 ) {
        amt_w = fwrite(buf, 1, amt_read, fp);
    }
    
    print_foot(fp);

    return fp;
}

static int
test_include(const char *include_file, int exec_argc, char **exec_argv) {
    FILE *fp = fopen(g_test_file, "w");

    if (! fp) {
        fprintf(stderr, "\ncouldn't open file %s for output!\n", g_test_file);
        exit(1);
    }

    fprintf(fp, "\n");
    fprintf(fp, "#include <%s>\n\n", include_file);

    fprintf(fp, "int\nmain(int argc, char **argv) {\n");
    fprintf(fp, "    return 0;\n");
    fprintf(fp, "}\n");

    fclose(fp);

    if (do_system_with_file_redirect(exec_argc, exec_argv, "config_output.txt")) {
        return 0;
    }

    return 1;
}

static int
test_func(const char *func_name, int exec_argc, char **exec_argv, char *test_exec) {
    FILE *fp = fopen(g_test_file, "w");
    

    if (! fp) {
        fprintf(stderr, "\ncouldn't open file %s for output!\n", g_test_file);
        exit(1);
    }

    fprintf(fp, "\n");
    fprintf(fp, "int %s();\n\n", func_name);
    fprintf(fp, "int\nmain(int argc, char **argv) {\n");
    fprintf(fp, "    %s();\n", func_name);
    fprintf(fp, "    return 0;\n");
    fprintf(fp, "}\n");

    fclose(fp);

    if (do_system_with_file_redirect(exec_argc, exec_argv, "config_output.txt")) {
        return 0;
    }

    if (do_system_with_file_redirect(1, &test_exec, "config_output.txt")) {
        return 0;
    }

    return 1;
}

static int
test_type(const char *type_name, int exec_argc, char **exec_argv, FILE *conf_fh) {
    FILE *fp = sync_header(conf_fh, g_test_file);

    if (! fp) {
        fprintf(stderr, "\ncouldn't open file %s for output!\n", g_test_file);
        exit(1);
    }

    fprintf(fp, "\n");
    fprintf(fp, "int\nmain(int argc, char **argv) {\n");
    fprintf(fp, "    %s blah;\n", type_name);
    fprintf(fp, "    return 0;\n");
    fprintf(fp, "}\n");

    fclose(fp);

    if (do_system_with_file_redirect(exec_argc, exec_argv, "config_output.txt")) {
        return 0;
    }

    return 1;
}


typedef struct {
    char *file;
    char *name;
} test_rec;

int
main(int argc, char **argv) {
    char *out_file = "jsonevt_config.h";
    char *name;
    char *file;
    char *test_exec;
    FILE *conf_fh;
    /* int rv; */
    int exec_argc;
    char **exec_argv;
    int i;
    int first_arg_count = 0;
    long unsigned int size = 0;

    test_rec header_list[ ] = {
        { "stdint.h", "STDINT_H" },
        { "inttypes.h", "INTTYPES_H" },
        { "sys/types.h", "SYS_TYPES_H" },
        { "sys/mman.h", "SYS_MMAN_H" },
        { "limits.h", "LIMITS_H" },
        {NULL}
    };

    test_rec func_list[ ] = {
        { "vsnprintf", "VSNPRINTF" },
        { "_vsnprintf", "_VSNPRINTF" },
        { "vasprintf", "VASPRINTF" },
        { "asprintf", "ASPRINTF" },
        { "my_dummy_func", "MY_DUMMY_FUNC" },
        {NULL}
    };

    test_rec type_list[ ] = {
        { "uint", "UINT" },
        {NULL}
    };

    test_rec *hp;

    if (argc < 4) {
        fprintf(stderr, "Usage: make_config <out_file> <test_exec> <compiler_cmd> <compiler_cmd> ...\n\n");
        return 1;
    }

    first_arg_count = 1;
    out_file = argv[1];
    first_arg_count++;
    test_exec = argv[2];
    first_arg_count++;

    exec_argc = argc - first_arg_count;

    exec_argv = (char **)malloc((exec_argc + 1) * sizeof(char *));
    for (i = 0; i < exec_argc; i++) {
        exec_argv[i] = argv[i + first_arg_count];
    }
    exec_argv[exec_argc] = "test_config.c";
    exec_argc++;

    conf_fh = fopen(out_file, "w+");
    if (! conf_fh) {
        fprintf(stderr, "\ncouldn't open %s for output!\n", out_file);
        return 1;
    }

    print_head(conf_fh);

    hp = header_list;
    while (hp && hp->file) {
        file = hp->file;
        name = hp->name;

        fprintf(conf_fh, "/* %s */\n", file);
        if (test_include(file, exec_argc, exec_argv)) {
            /* printf("%s ok\n", file); */
            
            fprintf(conf_fh, "#include <%s>\n", file);
            fprintf(conf_fh, "#ifndef HAVE_%s\n", name);
            fprintf(conf_fh, "#define HAVE_%s 1\n", name);
            fprintf(conf_fh, "#endif\n");
        }

        fprintf(conf_fh, "\n");

        hp++;
    }


    fprintf(conf_fh, "\n/* Functions */\n\n");
    hp = func_list;
    while (hp && hp->file) {
        file = hp->file;
        name = hp->name;

        fprintf(conf_fh, "/* %s */\n", file);
        if (test_func(file, exec_argc, exec_argv, test_exec)) {
            fprintf(conf_fh, "#ifndef HAVE_%s\n", name);
            fprintf(conf_fh, "#define HAVE_%s 1\n", name);
            fprintf(conf_fh, "#endif\n");            
        }
        else {
            fprintf(conf_fh, "/* #define HAVE_%s 1 */\n", name);
        }

        fprintf(conf_fh, "\n");


        hp++;
    }

    fprintf(conf_fh, "\n/* Types */\n\n");
    hp = type_list;
    while (hp && hp->file) {
        file = hp->file;
        name = hp->name;

        fprintf(conf_fh, "/* %s */\n", file);

        if (test_type(file, exec_argc, exec_argv, conf_fh)) {
            fprintf(conf_fh, "#ifndef HAVE_%s\n", name);
            fprintf(conf_fh, "#define HAVE_%s 1\n", name);
            fprintf(conf_fh, "#endif\n");
        }

        hp++;
    }

    /*
    size = sizeof(unsigned long);
    fprintf(conf_fh, "#define JSONEVT_ULONG_SIZE %lu\n", size);

    size = sizeof(unsigned int);
    fprintf(conf_fh, "#define JSONEVT_UINT_SIZE %lu\n", size);
    */

    print_foot(conf_fh);

    free(exec_argv);

    return 0;
}

