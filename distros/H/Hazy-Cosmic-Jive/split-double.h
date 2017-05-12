
typedef struct split_double {
    long long unsigned fraction : 52;
    unsigned exp : 11;
    unsigned sign : 1;
}
split_double_t;

