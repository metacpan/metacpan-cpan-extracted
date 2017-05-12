define x(a) {
  return (a*5.7);
}

scale = 5;
x(4);

define y(a,b) {
  blah[0] = a*7*b;
  blah[1] = a*6*b;
  return (blah[1]);
}
y(2,3)
quit;
