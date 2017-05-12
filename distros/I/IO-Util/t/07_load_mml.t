#!perl -w
; use strict
; use warnings
; use Data::Dumper
; use Test::More tests => 23

; use IO::Util qw(load_mml)

; my $str1 = << 'EOS'
<opt>
  ignored text
  <a>01</a>
  ignored text
  <a>02</a>
  <b>   ignored text
    <c>05</c>
  </b>
  <a attribute="ignored">03</a>  <ignored_element/>
  <a>04</a>
  <d></d>
  <e>06 <ignored_element></e>
</opt>
EOS

# defaults
; my $r1 = load_mml \$str1, strict=>0

# ; warn Dumper $r1

; is_deeply $r1
          , { a => [ '01'
                   , '02'
                   , '03'
                   , '04'
                   ]
            , b => { c => '05'
                   }
            , d => ''
            , e => '06 <ignored_element>'
            }


# keep_root option
; my $r2 = load_mml \$str1, keep_root=>1, strict=>0
                    
# ; warn Dumper $r2


; is_deeply $r2
          , { opt => { a => [ '01'
                            , '02'
                            , '03'
                            , '04'
                            ]
                     , b => { c => '05'
                            }
                     , d => ''
                     , e => '06 <ignored_element>'
                     }
            }
            

# strict option
; my $str2 = << 'EOS'
<opt>
  <a>01</a>
  <a>02</a>
  <b>
    <c>05</c>
  </b>
</opt>
EOS

; my $r3 = load_mml \$str2

#; warn Dumper $r3

; is_deeply $r3
          , { a => [ '01'
                   , '02'
                   ]
            , b => { c => '05'
                   }
            }

; eval{ load_mml \ '<opt>garbage<a>01</a></opt>' }  #'
; ok $@

; eval{ load_mml \'<opt><a attr="garbage">01</a></opt>' }  #'
; ok $@

; eval{ load_mml \'<opt><a>01<element attr="b"\></a></opt>' }   #'
; ok $@

# data_filter option
; my $str3 = << 'EOS'
<opt>
<a>
  abc
</a>
<b>
  def
  ghi
</b>
<c>
  <d>d</d>
  <e>e</e>
</c>
<f>f</f>
</opt>
EOS
; my $r4 =  load_mml \$str3
#; warn Dumper $r4

; is $$r4{a}, "\n  abc\n"

; my $r5 =  load_mml \$str3,  filter => {qr/./=>'ONE_LINE'}

#; warn Dumper $r5

; is $$r5{a}, '   abc '


; my $r6 = load_mml \$str3,  filter => {qr/./=>\&IO::Util::TRIM_BLANKS}
#; warn Dumper $r6
; is $$r6{b}, "def\nghi"

; my $r7 = load_mml \$str3,  filter => {qr/./=>\&trim_and_one_line}

#; warn Dumper $r7
; sub trim_and_one_line
   { IO::Util::TRIM_BLANKS()
   ; IO::Util::ONE_LINE()
   }
   
; is $$r7{b}, "def ghi"

; my $r8 = load_mml \$str3,  filter => { qr/./ => sub{ trim_and_one_line()
                                                     ; uc
                                                     }
                                       }
#; warn Dumper $r8
; is $$r8{b}, "DEF GHI"


# element_handler option
# change options

; my $r9 = load_mml \$str3, filter => { qr/d|e/ => sub{uc} }
#; warn Dumper $r9
; is $$r9{c}{d}, "D"
; is $$r9{c}{e}, "E"
; is $$r9{f}, "f"

; my $r10 = load_mml \$str3, handler => { c => \&c_struct_change }

# structure change
; sub c_struct_change
   { my $str = IO::Util::parse_mml(@_)
   ; [ sort values %$str ]
   }
#; warn Dumper $r10


; is_deeply $$r10{c}, [ 'd', 'e' ]


# skip element
; my $r11 = load_mml \$str3 , handler => {c=>sub{}}

#; warn Dumper $r11

; ok not defined $$r11{c}
   
# object creation
; my $r12 = load_mml \$str3, handler => {c=>\&c_obj}

; sub c_obj
   { my $str = IO::Util::parse_mml(@_)
   ; bless $str, 'My::Class'
   }
   
#; warn Dumper $r12
; isa_ok $$r12{c}, 'My::Class'

# matrix with folding
; my $str4 = << 'EOS'
<opt>

  <a>
    <b>01</b>
    <b>02</b>
  </a>
  <a>
    <b>03</b>
    <b>04</b>
  </a>
  
</opt>
EOS

; my $r13 = load_mml \$str4, handler => { a => \&a_struct_change }

                    
; sub a_struct_change
   { my $str = IO::Util::parse_mml(@_)
   # folding 'b'
   ; $$str{b}
   }

#; warn Dumper $r13

; is_deeply $r13
          , { a => [ [ '01'
                     , '02'
                     ]
                   , [ '03'
                     , '04'
                     ]
                   ]
            }


# escape/unescape
; my $str5 = << 'EOS'
<opt>

  <a>\<b\>01\</b\></a>
  <b>\<b\>01\</b\></b>
  <c>\<b\>\\\</b\></c>
  
</opt>
EOS

; my $r14 = load_mml \$str5

#; warn Dumper $r14

; is_deeply $r14
          , { a => '<b>01</b>'
            , b => '<b>01</b>'
            , c => '<b>\</b>'
            }


# comments

; my $str6 = << 'EOS'
<opt>
   <a>01</a>
<!--   <b>
02</b>  -->

</opt>
EOS

; my $r15 = load_mml \$str6

#; warn Dumper $r15
; is $$r15{a}, '01'
; is $$r15{b}, undef




; my $str7 = << 'EOS'
<opt>
  <a_b>01</a_b>
  <a>02</a>
</opt>
EOS

; my $r16 = load_mml \$str7

#; warn Dumper $r3

; is_deeply $r16
          , { a_b => '01'
            , a => '02'
            }
            
            
; my $str8 = << 'EOS'
<opt>
<a>
01
02
03
</a>
</opt>
EOS

; my $r17 = load_mml \$str8
            , handler => { a => 'SPLIT_LINES' }
            , filter  => { a => 'TRIM_BLANKS' }


; is_deeply $r17
          , { a => ['01', '02', '03' ] }
