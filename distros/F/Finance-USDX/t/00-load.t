#!perl -T

use Test::More tests => 2;

use Finance::USDX;

like usdx(eurusd => 1,
          usdjpy => 1,
          gbpusd => 1,
          usdcad => 1,
          usdsek => 1,
          usdchf => 1,
         ) => qr/50\.143481/;

like usdx(eurusd => 1.2976,
          usdjpy => 79.846,
          gbpusd => 1.5947,
          usdcad => 0.9929,
          usdsek => 6.6491,
          usdchf => 0.9331,
         ) => qr/79\.95117401/;


