#!perl
use strict;
use warnings FATAL => 'all';
use Test::More tests => 12;
use Test::Differences;
use Clone qw/clone/;

BEGIN {
    push(@INC, 'inc');
    use_ok( 'MarpaX::Languages::C::Scan' ) || print "Bail out!\n";
}

$ENV{MARPAX_LANGUAGES_C_AST_T_SCAN} = 1;
my $filename = File::Spec->catfile('inc', 'scan.c');
my $c = MarpaX::Languages::C::Scan->new(filename => $filename);

my_eq_or_diff($c->defines_no_args,
              {
               'MACRO_NO_ARGS_01' => [ 'MACRO_NO_ARGS_01', '', '' ],
               'MACRO_NO_ARGS_02' => [ 'MACRO_NO_ARGS_02 something', 'something', '' ]
              },
              'defines_no_args');
my_eq_or_diff($c->defines_args,
              {
               'MACRO_NO_ARGS_04' =>
               [
                "MACRO_NO_ARGS_04 (b,    c) something(b) + else(c) \\\ncontinued",
                [
                 'b',
                 'c'
                ],
                "something(b) + else(c) \\\ncontinued",
                ''
               ],
               'MACRO_NO_ARGS_03' =>
               [
                'MACRO_NO_ARGS_03(a)',
                [
                 'a'
                ],
                '',
                ''
               ]
              },
              'defines_args');
ok(defined($c->includes), 'includes');
my_eq_or_diff($c->parsed_fdecls,
              [
               [
                'int',
                'func1',
                [
                 [
                  'int',
                  'x1',
                  undef,
                  'int x1',
                  ''
                 ],
                 [
                  'double',
                  'x2',
                  undef,
                  'double *x2',
                  ''
                 ],
                 [
                  'float',
                  'f1',
                  undef,
                  'float *( f1)(int x11, double x12)',
                  '',
                 ]
                ],
                'int func1(int x1, double *x2,           float *( f1)(int x11, double x12))',
                undef
               ],
               [
                'int',
                'func2',
                [
             [
              'int',
              'x1',
              undef,
              'int x1',
              ''
             ],
             [
              'double',
              'x2',
              undef,
              'double *x2',
              ''
             ],
             [
              'float',
              'f1',
              undef,
              'float *(*f1)(int x11, double x12)',
              '',
             ]
            ],
            'int func2(int x1, double *x2, float *(*f1)(int x11, double x12))',
            undef
           ],
           [
            'int',
            'func3',
            [
             [
              'int',
              'ANON0',
              undef,
              'int',
              ''
             ],
             [
              'double',
              'ANON1',
              undef,
              'double *',
              ''
             ],
             [
              'float',
              'ANON2',
              undef,
              'float *(* )(int , double )',
              ''
             ]
            ],
            'int func3(int , double * , float *(* )(int , double ))',
            undef
           ],
           [
            'int',
            'func4',
            [
             [
              'int',
              'ANON3',
              undef,
              'int',
              ''
             ],
             [
              'double',
              'ANON4',
              undef,
              'double *',
              ''
             ],
             [
              'float',
              'ANON5',
              undef,
              'float *(* )(int , double )',
              ''
             ]
            ],
            'int func4(int , double * , float *(* )(int , double ))',
            undef
           ]
          ],
          'parsed_fdecls');
my_eq_or_diff($c->typedef_hash,
{
    'myStructType1_t'  => [ 'struct myStruct1 {int x;}',   '' ],
    'myStructType1p_t' => [ 'struct myStruct1 {int x;} *', '' ],

    'myEnumType2_t'  => [ 'enum {X21 = 0, X22}',   '' ],
    'myEnumType2p_t' => [ 'enum {X21 = 0, X22} *', '' ],

    'myStructType2_t'  => [ 'struct {int x;}',   '' ],
    'myStructType2p_t' => [ 'struct {int x;} *', '' ],

    'myInt_type' => [ 'int', '' ],

    'myEnumType1_t'  => [ 'enum myEnum1_e {X11 = 0, X12}',   '' ],
    'myEnumType1p_t' => [ 'enum myEnum1_e {X11 = 0, X12} *', '' ],

    'myOpaqueStruct_t'  => [ 'struct opaqueStruct',   '' ],
    'myOpaqueStructp_t' => [ 'struct opaqueStruct *', '' ],
},
    'typedef_hash');
my_eq_or_diff($c->typedefs_maybe,
    [
     'myInt_type',
     'myEnumType1_t',
     'myEnumType1p_t',
     'myEnumType2_t',
     'myEnumType2p_t',
     'myStructType1_t',
     'myStructType1p_t',
     'myStructType2_t',
     'myStructType2p_t',
     'myOpaqueStruct_t',
     'myOpaqueStructp_t'
    ],
    'typedefs_maybe');
my_eq_or_diff($c->vdecls,
    [
     'extern int vint1;',
     'extern double * vdouble2p;'
    ],
    'vdecls');
my_eq_or_diff($c->vdecl_hash,
{
 'vdouble2p' => [ 'double * ', '' ],
 'vint1'     => [ 'int', '' ]
},
  'vdecl_hash');
my_eq_or_diff($c->typedef_structs,
{
 'myStructType2_t' => [
                       [ 'int', '', 'x' ]
                      ],
 'myStructType1_t' => [
                       [ 'int', '', 'x' ]
                      ],
 'myStructType1p_t' => [
                        [ 'int', '', 'x' ]
                       ],
 'myStructType2p_t' => [
                        [ 'int', '', 'x' ]
                       ],
 'myEnumType1_t' => undef,
 'myEnumType1p_t' => undef,
 'myInt_type' => undef,
 'myEnumType2p_t' => undef,
 'myEnumType2_t' => undef,
 'myOpaqueStruct_t' => [],
 'myOpaqueStructp_t' => [],
}, 'typedef_structs');
my_eq_or_diff($c->typedef_texts,
    [
     'int myInt_type;',
     'enum myEnum1_e {X11 = 0, X12} myEnumType1_t, *myEnumType1p_t;',
     'enum {X21 = 0, X22} myEnumType2_t, *myEnumType2p_t;',
     'struct myStruct1 {int x;} myStructType1_t, *myStructType1p_t;',
     'struct {int x;} myStructType2_t, *myStructType2p_t;',
     'struct opaqueStruct myOpaqueStruct_t, *myOpaqueStructp_t;'
    ] , 'typedef_texts');
my_eq_or_diff($c->fdecls,
    [
     'int func1(int x1, double *x2, float *( f1)(int x11, double x12))',
     'int func2(int x1, double *x2, float *(*f1)(int x11, double x12))',
     'int func3(int , double * , float *(* )(int , double ))',
     'int func4(int , double * , float *(* )(int , double ))'
    ] , 'fdecls');

#
# This is something that end user should never do, but here I have to deal with the
# case of different cpp's on different platforms having different behaviour with space
#
sub my_eq_or_diff {
  my $got = inplace(clone(shift));
  my $wanted = inplace(clone(shift));
  eq_or_diff($got, $wanted);
}

#
# In-place change of data. This is simplified by the fact that we KNOW we have
# only hashes or arrays, with low stack footprint.
#
sub inplace {
  my $ref = shift;

  if (ref($ref) eq 'HASH') {
    map {inplace(ref($ref->{$_}) ? $ref->{$_} : \$ref->{$_})} keys %{$ref};
  } elsif (ref($ref) eq 'ARRAY') {
    map {inplace(ref($_) ? $_ : \$_)} @{$ref};
  } elsif (ref($ref) eq 'SCALAR') {
    my $orig = ${$ref};
    if (defined($orig)) {
      ${$ref} =~ s/^\s*//;
      ${$ref} =~ s/\s*$//;
      ${$ref} =~ s/\s+/ /g;
      # if (${$ref} ne $orig) {
      #   warn "\"$orig\" changed to \"${$ref}\"";
      # }
    }
  } else {
    die "Oups..." . ref($ref);
  }
}
