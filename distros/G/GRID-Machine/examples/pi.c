#include <stdio.h>
#include <stdlib.h>

main(int argc, char **argv) {
  int id, N, np, i;
  double sum, left;

  if (argc != 4) { 
    printf("Usage:\n%s id N np\n",argv[0]);
    exit(1); 
  }
  id = atoi(argv[1]);
  N = atoi(argv[2]);
  np = atoi(argv[3]);
  for(i=id, sum = 0; i<N; i+=np) {
    double x = (i + 0.5)/N;
    sum += 4 / (1 + x*x);
  }
  sum /= N;
  printf("%lf\n", sum);
  exit(0);
}
