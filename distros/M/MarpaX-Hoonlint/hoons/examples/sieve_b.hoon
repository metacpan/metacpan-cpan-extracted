|=  thru=@                                              ::  1
^-  (list @)                                            ::  2
=/  field=(set @)  (sy (gulf 2 thru))                   ::  3
=<  abet:main                                           ::  4
|%                                                      ::  5
++  abet                                                ::  6
  (sort ~(tap in field) lth)                            ::  7
::                                                      ::  8
++  main                                                ::  9
  =/  factor=@  2                                       ::  10
  |-  ^+  ..main                                        ::  11
  ?:  (gth (mul factor factor) thru)                    ::  12
    ..main                                              ::  13
  $(factor +(factor), ..main (reap factor))             ::  14
::                                                      ::  15
++  reap                                                ::  16
  |=  factor=@                                          ::  17
  =/  count=@  (mul 2 factor)                           ::  18
  |-  ^+  ..reap                                        ::  19
  ?:  (gth count thru)                                  ::  20
    ..reap                                              ::  21
  %=  $                                                 ::  22
    count  (add count factor)                           ::  23
    field  (~(del in field) count)                      ::  24
  ==                                                    ::  25
--                                                      ::  26
