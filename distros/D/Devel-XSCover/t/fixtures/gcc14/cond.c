int fn (int a, int b, int c)
{
    if (a && (b || c))
        return 1;
    return a > 0 ? 2 : 3;
}
