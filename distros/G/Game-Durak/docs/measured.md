# Game::Durak, measured

Numbers, not estimates. Every figure on this page names the command that
produced it and the day it was run, so anybody can produce it again.

## The length of a deal

    perl -Ilib bin/soak --deals 2000 --seed-prefix durak-soak

25 September 2026, Game::Durak 0.01, phase 04, random legal play on both
seats, 2000 deals, 5 seconds.

| | min | median | p95 | max | mean |
|---|---|---|---|---|---|
| moves a deal | 42 | 79 | 114 | 156 | 81.0 |
| moves a seat | 17 | 40 | 57 | 81 | 40.5 |
| bouts a deal | 15 | 30 | 42 | 57 | 30.3 |
| cards the durak held | 2 | 8 | 14 | 24 | 7.7 |

A move here is a move a person makes. The positions the engine resolves
itself, a defender who cannot beat and an attacker with nothing to throw, are
not moves and are not counted, which is the number a consumer's per move
deadline actually has to live with.

No deal ran past 600 moves, and none had to be stopped.

## How deals ended

    draw 6, fool 1994

Six drawn deals in two thousand, **0.3 per cent**. That is why the drawn deal
is proved by a written position in F<t/14-draw.t> rather than by a sweep: 300
deals of random play produced none at all, and a test that waited for one
would pass by not looking.

## The seat that opens

The holder of the lowest trump opens, which is decided by the cards and not
by the seat. Over 1994 decided deals the opener was the fool **984 times,
49.3 per cent, two sigma 2.2 per cent**.

So there is no measurable advantage either way in the opening, under random
play. Random play is a weak instrument for this: it measures the deal rather
than the game, and the bot ladder repeats the measurement.

## The exchange

The trump six could be exchanged in **1753 of 2000 deals** (88 per cent), and
a random player took it in 1234. It is not a rare rule: any measurement of
the bot has to include a rung that decides about it.

## The bot ladder

    perl -Ilib bin/ladder --deals 2000 --seed-prefix durak-ladder

25 September 2026, phase 05. Every pair of rungs, 2000 deals each, half with
the seats the other way round so that the opening cannot be mistaken for
strength.

| pair | the weaker rung was the fool | two sigma | cards held when losing | drawn |
|---|---|---|---|---|
| 1 v 2 | 97.8 per cent | 2.2 | 10.5 against 4.3 | 44 |
| 1 v 3 | 98.3 per cent | 2.2 | 10.1 against 4.1 | 4 |
| 2 v 3 | 52.9 per cent | 2.3 | 5.9 against 5.8 | 71 |

**All three rungs separate**, and the third one only just: rung 2 loses 52.9
per cent against rung 3, an interval of 50.6 to 55.2 that excludes an even
split by half a point.

**Four hundred deals would have said the opposite.** At 400 the same pair
measured 47.1 per cent with a two sigma interval of 5.1, which includes 50,
and four different settings of rung 3's two thresholds all measured between
46.7 and 48.7. The plan's marks were written at 400 deals; they need 2000.

**The senior instrument does not separate rungs 2 and 3 at all**: 5.9 cards
against 5.8. It separates rung 1 from both by a factor of two and a half. A
rung that loses differently is visible in the cards it is left holding; a
rung that loses slightly less often is not.

### What the measurement threw out of rung 3

Rung 3 was written with four judgements and ships with two.

| judgement | effect on rung 3's fool rate | kept |
|---|---|---|
| take rather than spend a high trump early | 58.4 with, 67.2 without | yes |
| attack out of a pair | 47.1 with, 48.0 without | yes |
| hold back the good cards unless the other seat is short | 58.4 with, 48.0 without | **no** |
| never open with a trump while the talon has cards | 58.4 either way | **no** |

Holding back cost ten points. In durak a card thrown into a bout that is
beaten off is a card gone, and shedding is the whole game, so a bot that
keeps its good cards keeps its cards.

Refusing to open with a trump changed nothing whatsoever: the cost function
already sorts every trump behind every plain card, so the rule never once
chose differently. Dead, and removed rather than kept as decoration.

## What is not measured yet

- The length distributions under the ladder rather than random play.
- Wall clock for a whole game through a consumer (phase 09 declares the
  limits from that).
