#define __TWEPC_APP_C__
#include "twepl_parse.c"

int main(int argc, char **argv, char **envp){

      TWEPL_CONFIG  cfg;
  enum TWEPL_STATE  ret;
              FILE *fo;
              char *ec = NULL;
              char *in = NULL;
              char *on = NULL;
               int  i;

  if(argc < 1){
    fprintf(stderr, EPC_APPNAME ": invalid arguments..\n");
    exit(1);
  }

  for(i=1; i<argc; i++){
    if(strcmp(argv[i], "-v") == 0 || strcmp(argv[i], "-V") == 0){
      printf("%s",(char*)EPP_VERSION);
      return 0;
    } else if(strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--help") == 0){
      printf("%s", (char*)EPP_OPTIONS);
      printf("%s", (char*)EPP_VERSION);
      return 0;
    } else if(strcmp(argv[i], "-o") == 0 && i != argc){
      on = argv[++i];
    } else if(access(argv[i], F_OK) != -1){
      in = argv[i];
    }
  }

  if(in == NULL){
    fprintf(stderr, EPC_APPNAME ": couldn't found input file.\n");
    return 1;
  }

  cfg.ParserFlag = OPT_TAG_ALL;
  cfg.SendLength = 0;
  cfg.MyApplePie = 0;

  ret = twepl_file(in , &ec, cfg.ParserFlag);

  if(ret != TWEPL_OKEY_NOERR){
      fprintf(stderr, EPC_APPNAME ": parse error.\n");
      return 1;
  }

  if(on != NULL){
    if((fo = fopen(on,"wb")) == NULL){
      fprintf(stderr, EPC_APPNAME ": cauldn't open output file.\n");
      free(ec);
      return 1;
    }
  } else{
    fo = stdout;
  }

  fprintf(fo, "%s", ec);
  free(ec);

  if(fo != NULL){
    fclose(fo);
  }

  return 0;

}
