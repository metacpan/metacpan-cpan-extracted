=<  |=  feed/(list move)                                ::  1
    =|  game/game                                       ::  2
    |-  ^-  (list fact)                                 ::  3
    ?~  feed  ~                                         ::  4
    =^    this/(unit fact)                              ::  5
        game                                            ::  6
      (~(do go game) i.feed)                            ::  7
    =/  rest/(list fact)  $(feed t.feed)                ::  8
    ?~(this rest [u.this rest])                         ::  9
::                                                      ::  10
=>  |%                                                  ::  11
    ++  side  @                                         ::  12
    ++  spot  {x/@ y/@}                                 ::  13
    ++  fact  $%  {$tie $~}                             ::  14
                  {$win p/cord}                         ::  15
              ==                                        ::  16
    ++  move  $%  {$x p/spot}                           ::  17
                  {$o p/spot}                           ::  18
                  {$z $~}                               ::  19
              ==                                        ::  20
    ++  game  $:  w/?                                   ::  21
                  a/side                                ::  22
                  z/side                                ::  23
              ==                                        ::  24
    --                                                  ::  25
|%                                                      ::  26
++  bo                                                  ::  27
  |_  half/side                                         ::  28
  ++  bit  |=(a/@ =(1 (cut 0 [a 1] half)))              ::  29
  ++  off  |=(a/spot (add x.a (mul 3 y.a)))             ::  30
  ++  get  |=(a/spot (bit (off a)))                     ::  31
  ++  set  |=(a/spot (con half (bex (off a))))          ::  32
  ++  win  %+  lien                                     ::  33
             (rip 4 0wl04h0.4A0Aw.4A00s.0e070)          ::  34
           |=(a/@ =(a (dis a half)))                    ::  35
  --                                                    ::  36
++  go                                                  ::  37
  |_  game/game                                         ::  38
  ++  do                                                ::  39
    |=  act/move                                        ::  40
    ^-  {(unit fact) ^game}                             ::  41
    ?-  act                                             ::  42
      {$x *}  ?>(w.game ~(mo on p.act))                 ::  43
      {$o *}  ?<(w.game ~(mo on p.act))                 ::  44
      {$z *}  [~ nu]                                    ::  45
    ==                                                  ::  46
  ::                                                    ::  47
  ++  nu  ^+(game [& 0 0])                              ::  48
  ++  on                                                ::  49
    |_  here/spot                                       ::  50
    ++  is  ?|  (~(get bo a.game) here)                 ::  51
                (~(get bo z.game) here)                 ::  52
            ==                                          ::  53
    ++  mo  ^-  {(unit fact) ^game}                     ::  54
            ?<  is                                      ::  55
            =/  next/side  (~(set bo a.game) here)      ::  56
            ?:  ~(win bo next)                          ::  57
               [[~ %win ?:(w.game %x %o)] nu]           ::  58
            [~ game(w !w.game, a z.game, z next)]       ::  59
    --                                                  ::  60
  --                                                    ::  62
--                                                      ::  63
