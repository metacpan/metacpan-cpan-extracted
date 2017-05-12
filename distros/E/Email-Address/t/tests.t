use Test::More;
use strict;
use warnings;

# This is a corpus of addresses to test.  Each element of @list is a pair of
# input and expected output.  The input is a string that will be given to
# Email::Address, with "-- ATAT --" replaced with the encircled a.
#
# The output is a list of formatted addresses we expect to extract from the
# string.

my @list = (
  [
    '',
    []
  ],
  [
    '"\'\'\'advocacy-- ATAT --p.example.org \' \' \'" <advocacy-- ATAT --p.example.org>',
    [
      [
        '\'\'\'advocacy-- ATAT --p.example.org \' \' \'',
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"\'\'advocacy-- ATAT --p.example.org \' \'" <advocacy-- ATAT --p.example.org>',
    [
      [
        '\'\'advocacy-- ATAT --p.example.org \' \'',
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"\'. Jerry a\'" <JerryPanshen-- ATAT --aol.example.aero>',
    [
      [
        '\'. Jerry a\'',
        'JerryPanshen-- ATAT --aol.example.aero',
        undef
      ]
    ]
  ],
  [
    '"\'Adam Turoff\'" <adam.turoff-- ATAT --s.example.net>, advocacy-- ATAT --p.example.org',
    [
      [
        '\'Adam Turoff\'',
        'adam.turoff-- ATAT --s.example.net',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"\'Andy Lester\'" <andy-- ATAT --pet.example.com>, "\'Gabor Szabo\'" <gabor-- ATAT --trt.example.biz>, advocacy-- ATAT --p.example.org',
    [
      [
        '\'Andy Lester\'',
        'andy-- ATAT --pet.example.com',
        undef
      ],
      [
        '\'Gabor Szabo\'',
        'gabor-- ATAT --trt.example.biz',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"\'Ask Bjoern Hansen\'" <ask-- ATAT --p.example.org>, <advocacy-- ATAT --p.example.org>',
    [
      [
        '\'Ask Bjoern Hansen\'',
        'ask-- ATAT --p.example.org',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"\'Chris Nandor\'" <pudge-- ATAT --x.example.com> , "\'David E. Wheeler\'" <David-- ATAT --whl.example.net>',
    [
      [
        '\'Chris Nandor\'',
        'pudge-- ATAT --x.example.com',
        undef
      ],
      [
        '\'David E. Wheeler\'',
        'David-- ATAT --whl.example.net',
        undef
      ]
    ]
  ],
  [
    '"\'Chris Nandor\'" <pudge-- ATAT --x.example.com> , "\'Elaine -HFB- Ashton\'" <elaine-- ATAT --chaos.example.edu>',
    [
      [
        '\'Chris Nandor\'',
        'pudge-- ATAT --x.example.com',
        undef
      ],
      [
        '\'Elaine -HFB- Ashton\'',
        'elaine-- ATAT --chaos.example.edu',
        undef
      ]
    ]
  ],
  [
    '"\'Chris Nandor\'" <pudge-- ATAT --x.example.com> , "\'Jon Orwant\'" <orwant-- ATAT --media.mit.edu>, <chip-- ATAT --valinux.com> , <tidbit-- ATAT --sri.net>, <advocacy-- ATAT --p.example.org>',
    [
      [
        '\'Chris Nandor\'',
        'pudge-- ATAT --x.example.com',
        undef
      ],
      [
        '\'Jon Orwant\'',
        'orwant-- ATAT --media.mit.edu',
        undef
      ],
      [
        undef,
        'chip-- ATAT --valinux.com',
        undef
      ],
      [
        undef,
        'tidbit-- ATAT --sri.net',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"\'Chris Nandor\'" <pudge-- ATAT --x.example.com>, <advocacy-- ATAT --p.example.org>, <perl5-porters-- ATAT --p.example.org>',
    [
      [
        '\'Chris Nandor\'',
        'pudge-- ATAT --x.example.com',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ],
      [
        undef,
        'perl5-porters-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"\'Chris Nandor\'" <pudge-- ATAT --x.example.com>, advocacy-- ATAT --p.example.org',
    [
      [
        '\'Chris Nandor\'',
        'pudge-- ATAT --x.example.com',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"\'Chris Nandor\'" <pudge-- ATAT --x.example.com>, advocacy-- ATAT --p.example.org, perl5-porters-- ATAT --p.example.org',
    [
      [
        '\'Chris Nandor\'',
        'pudge-- ATAT --x.example.com',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ],
      [
        undef,
        'perl5-porters-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"\'David H. Adler \'" <dha-- ATAT --panix.com>, "\'advocacy-- ATAT --p.example.org \'" <advocacy-- ATAT --p.example.org>',
    [
      [
        '\'David H. Adler \'',
        'dha-- ATAT --panix.com',
        undef
      ],
      [
        '\'advocacy-- ATAT --p.example.org \'',
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"\'Doucette, Bob\'" <BDoucette-- ATAT --tesent.com>, \'Rich Bowen\' <rbowen-- ATAT --rc.example.com>',
    [
      [
        '\'Doucette, Bob\'',
        'BDoucette-- ATAT --tesent.com',
        undef
      ],
      [
        '\'Rich Bowen\'',
        'rbowen-- ATAT --rc.example.com',
        undef
      ]
    ]
  ],
  [
    '"\'Elaine -HFB- Ashton \'" <elaine-- ATAT --chaos.example.edu>, "Turoff, Adam" <adam.turoff-- ATAT --s.example.net>',
    [
      [
        '\'Elaine -HFB- Ashton \'',
        'elaine-- ATAT --chaos.example.edu',
        undef
      ],
      [
        'Turoff, Adam',
        'adam.turoff-- ATAT --s.example.net',
        undef
      ]
    ]
  ],
  [
    '"\'Elaine -HFB- Ashton\'" <elaine-- ATAT --chaos.example.edu>',
    [
      [
        '\'Elaine -HFB- Ashton\'',
        'elaine-- ATAT --chaos.example.edu',
        undef
      ]
    ]
  ],
  [
    '"\'Elaine -HFB- Ashton\'" <elaine-- ATAT --chaos.example.edu> , "\'Larry Wall\'" <larry-- ATAT --wall.org>',
    [
      [
        '\'Elaine -HFB- Ashton\'',
        'elaine-- ATAT --chaos.example.edu',
        undef
      ],
      [
        '\'Larry Wall\'',
        'larry-- ATAT --wall.org',
        undef
      ]
    ]
  ],
  [
    '"\'Elaine -HFB- Ashton\'" <elaine-- ATAT --chaos.example.edu> , "\'Larry Wall\'" <larry-- ATAT --wall.org> , "\'Jon Orwant\'" <orwant-- ATAT --media.mit.edu>, <chip-- ATAT --valinux.com> , <tidbit-- ATAT --sri.net>, <advocacy-- ATAT --p.example.org>',
    [
      [
        '\'Elaine -HFB- Ashton\'',
        'elaine-- ATAT --chaos.example.edu',
        undef
      ],
      [
        '\'Larry Wall\'',
        'larry-- ATAT --wall.org',
        undef
      ],
      [
        '\'Jon Orwant\'',
        'orwant-- ATAT --media.mit.edu',
        undef
      ],
      [
        undef,
        'chip-- ATAT --valinux.com',
        undef
      ],
      [
        undef,
        'tidbit-- ATAT --sri.net',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"\'Elaine -HFB- Ashton\'" <elaine-- ATAT --chaos.example.edu>, "\'Larry Wall\'" <larry-- ATAT --wall.org>, "\'Jon Orwant\'" <orwant-- ATAT --media.mit.edu>, <chip-- ATAT --valinux.com>, <tidbit-- ATAT --sri.net>, <advocacy-- ATAT --p.example.org>',
    [
      [
        '\'Elaine -HFB- Ashton\'',
        'elaine-- ATAT --chaos.example.edu',
        undef
      ],
      [
        '\'Larry Wall\'',
        'larry-- ATAT --wall.org',
        undef
      ],
      [
        '\'Jon Orwant\'',
        'orwant-- ATAT --media.mit.edu',
        undef
      ],
      [
        undef,
        'chip-- ATAT --valinux.com',
        undef
      ],
      [
        undef,
        'tidbit-- ATAT --sri.net',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"\'Elaine -HFB- Ashton\'" <elaine-- ATAT --chaos.example.edu>, <advocacy-- ATAT --p.example.org>',
    [
      [
        '\'Elaine -HFB- Ashton\'',
        'elaine-- ATAT --chaos.example.edu',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"\'John Porter\'" <jdporter-- ATAT --min.net>, "\'advocacy-- ATAT --p.example.org\'" <advocacy-- ATAT --p.example.org>',
    [
      [
        '\'John Porter\'',
        'jdporter-- ATAT --min.net',
        undef
      ],
      [
        '\'advocacy-- ATAT --p.example.org\'',
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"\'Larry Wall\'" <larry-- ATAT --wall.org> , "\'Jon Orwant\'" <orwant-- ATAT --media.mit.edu>, <chip-- ATAT --valinux.com> , <tidbit-- ATAT --sri.net>, <advocacy-- ATAT --p.example.org>',
    [
      [
        '\'Larry Wall\'',
        'larry-- ATAT --wall.org',
        undef
      ],
      [
        '\'Jon Orwant\'',
        'orwant-- ATAT --media.mit.edu',
        undef
      ],
      [
        undef,
        'chip-- ATAT --valinux.com',
        undef
      ],
      [
        undef,
        'tidbit-- ATAT --sri.net',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"\'Madeline Schnapp \'" <madeline-- ATAT --oreilly.com>, "\'advocacy-- ATAT --p.example.org \'" <advocacy-- ATAT --p.example.org>',
    [
      [
        '\'Madeline Schnapp \'',
        'madeline-- ATAT --oreilly.com',
        undef
      ],
      [
        '\'advocacy-- ATAT --p.example.org \'',
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"\'Mark Mielke\'" <markm-- ATAT --nortelnetworks.com>',
    [
      [
        '\'Mark Mielke\'',
        'markm-- ATAT --nortelnetworks.com',
        undef
      ]
    ]
  ],
  [
    '"\'Pamela Carter\'" <pcarter150-- ATAT --comcast.net>, <advocacy-- ATAT --p.example.org>',
    [
      [
        '\'Pamela Carter\'',
        'pcarter150-- ATAT --comcast.net',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"\'Shlomi Fish\'" <shlomif-- ATAT --vipe.technion.ac.il>',
    [
      [
        '\'Shlomi Fish\'',
        'shlomif-- ATAT --vipe.technion.ac.il',
        undef
      ]
    ]
  ],
  [
    '"\'Steve Lane\'" <sml-- ATAT --zfx.com>, "\'Chris Nandor\'" <pudge-- ATAT --x.example.com>, advocacy-- ATAT --p.example.org, perl5-porters-- ATAT --p.example.org',
    [
      [
        '\'Steve Lane\'',
        'sml-- ATAT --zfx.com',
        undef
      ],
      [
        '\'Chris Nandor\'',
        'pudge-- ATAT --x.example.com',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ],
      [
        undef,
        'perl5-porters-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"\'Tom Christiansen\'" <tchrist-- ATAT --chthon.perl.com>, Horsley Tom <Tom.Horsley-- ATAT --ccur.com>, "\'Steve Lane\'" <sml-- ATAT --zfx.com>, advocacy-- ATAT --p.example.org, perl5-porters-- ATAT --p.example.org',
    [
      [
        '\'Tom Christiansen\'',
        'tchrist-- ATAT --chthon.perl.com',
        undef
      ],
      [
        'Horsley Tom',
        'Tom.Horsley-- ATAT --ccur.com',
        undef
      ],
      [
        '\'Steve Lane\'',
        'sml-- ATAT --zfx.com',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ],
      [
        undef,
        'perl5-porters-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"\'abigail-- ATAT --foad.example.biz\'" <abigail-- ATAT --foad.example.biz>,	 "Michael R. Wolf"<MichaelRunningWolf-- ATAT --att.net>',
    [
      [
        '\'abigail-- ATAT --foad.example.biz\'',
        'abigail-- ATAT --foad.example.biz',
        undef
      ],
      [
        'Michael R. Wolf',
        'MichaelRunningWolf-- ATAT --att.net',
        undef
      ]
    ]
  ],
  [
    '"\'abigail-- ATAT --foad.example.biz\'" <abigail-- ATAT --foad.example.biz>, Michael G Schwern <schwern-- ATAT --x.example.com>',
    [
      [
        '\'abigail-- ATAT --foad.example.biz\'',
        'abigail-- ATAT --foad.example.biz',
        undef
      ],
      [
        'Michael G Schwern',
        'schwern-- ATAT --x.example.com',
        undef
      ]
    ]
  ],
  [
    '"\'abigail-- ATAT --foad.example.biz\'" <abigail-- ATAT --foad.example.biz>, Michael G Schwern <schwern-- ATAT --x.example.com>, Nicholas Clark <nick-- ATAT --c.example.org>, Piers Cawley <pdcawley-- ATAT --bofh.org.uk>, advocacy-- ATAT --p.example.org',
    [
      [
        '\'abigail-- ATAT --foad.example.biz\'',
        'abigail-- ATAT --foad.example.biz',
        undef
      ],
      [
        'Michael G Schwern',
        'schwern-- ATAT --x.example.com',
        undef
      ],
      [
        'Nicholas Clark',
        'nick-- ATAT --c.example.org',
        undef
      ],
      [
        'Piers Cawley',
        'pdcawley-- ATAT --bofh.org.uk',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"\'advocacy-- ATAT --p.example.org \'" <advocacy-- ATAT --p.example.org>',
    [
      [
        '\'advocacy-- ATAT --p.example.org \'',
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"\'advocacy-- ATAT --p.example.org \'" <advocacy-- ATAT --p.example.org>, "Turoff, Adam" <adam.turoff-- ATAT --s.example.net>',
    [
      [
        '\'advocacy-- ATAT --p.example.org \'',
        'advocacy-- ATAT --p.example.org',
        undef
      ],
      [
        'Turoff, Adam',
        'adam.turoff-- ATAT --s.example.net',
        undef
      ]
    ]
  ],
  [
    '"\'advocacy-- ATAT --p.example.org\'" <advocacy-- ATAT --p.example.org>',
    [
      [
        '\'advocacy-- ATAT --p.example.org\'',
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"\'bwarnock-- ATAT --capita.com\'" <bwarnock-- ATAT --capita.com>, advocacy-- ATAT --p.example.org',
    [
      [
        '\'bwarnock-- ATAT --capita.com\'',
        'bwarnock-- ATAT --capita.com',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"\'duff-- ATAT --x.example.com\'" <duff-- ATAT --x.example.com>',
    [
      [
        '\'duff-- ATAT --x.example.com\'',
        'duff-- ATAT --x.example.com',
        undef
      ]
    ]
  ],
  [
    '"\'london-list-- ATAT --happyfunball.pm.org\'" <london-list-- ATAT --happyfunball.pm.org>',
    [
      [
        '\'london-list-- ATAT --happyfunball.pm.org\'',
        'london-list-- ATAT --happyfunball.pm.org',
        undef
      ]
    ]
  ],
  [
    '"\'perl-hackers-- ATAT --stlouis.pm.org\'" <perl-hackers-- ATAT --stlouis.pm.org>',
    [
      [
        '\'perl-hackers-- ATAT --stlouis.pm.org\'',
        'perl-hackers-- ATAT --stlouis.pm.org',
        undef
      ]
    ]
  ],
  [
    '"\'perl-hackers-- ATAT --stlouis.pm.org\'" <perl-hackers-- ATAT --stlouis.pm.org>, advocacy-- ATAT --p.example.org, marsneedswomen-- ATAT --happyfunball.pm.org',
    [
      [
        '\'perl-hackers-- ATAT --stlouis.pm.org\'',
        'perl-hackers-- ATAT --stlouis.pm.org',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ],
      [
        undef,
        'marsneedswomen-- ATAT --happyfunball.pm.org',
        undef
      ]
    ]
  ],
  [
    '"<advocacy-- ATAT --p.example.org>" <advocacy-- ATAT --p.example.org>',
    [
      [
        '<advocacy-- ATAT --p.example.org>',
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"Adam Turoff" <adam.turoff-- ATAT --s.example.net>, "Elaine -HFB- Ashton" <elaine-- ATAT --chaos.example.edu>',
    [
      [
        'Adam Turoff',
        'adam.turoff-- ATAT --s.example.net',
        undef
      ],
      [
        'Elaine -HFB- Ashton',
        'elaine-- ATAT --chaos.example.edu',
        undef
      ]
    ]
  ],
  [
    '"Adam Turoff" <adam.turoff-- ATAT --s.example.net>, "Elaine -HFB- Ashton" <elaine-- ATAT --chaos.example.edu>, "Brent Michalski" <brent-- ATAT --perlguy.net>, "Madeline Schnapp" <madeline-- ATAT --oreilly.com>, <advocacy-- ATAT --p.example.org>, <betsy-- ATAT --oreilly.com>',
    [
      [
        'Adam Turoff',
        'adam.turoff-- ATAT --s.example.net',
        undef
      ],
      [
        'Elaine -HFB- Ashton',
        'elaine-- ATAT --chaos.example.edu',
        undef
      ],
      [
        'Brent Michalski',
        'brent-- ATAT --perlguy.net',
        undef
      ],
      [
        'Madeline Schnapp',
        'madeline-- ATAT --oreilly.com',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ],
      [
        undef,
        'betsy-- ATAT --oreilly.com',
        undef
      ]
    ]
  ],
  [
    '"Adam Turoff" <adam.turoff-- ATAT --s.example.net>, "Paul Prescod" <paul-- ATAT --co.example.va>',
    [
      [
        'Adam Turoff',
        'adam.turoff-- ATAT --s.example.net',
        undef
      ],
      [
        'Paul Prescod',
        'paul-- ATAT --co.example.va',
        undef
      ]
    ]
  ],
  [
    '"Alan Olsen" <alan-- ATAT --svr.example.museum>, "Rich Bowen" <rbowen-- ATAT --rc.example.com>',
    [
      [
        'Alan Olsen',
        'alan-- ATAT --svr.example.museum',
        undef
      ],
      [
        'Rich Bowen',
        'rbowen-- ATAT --rc.example.com',
        undef
      ]
    ]
  ],
  [
    '"Andreas J. Koenig" <andreas.koenig-- ATAT --example.net>',
    [
      [
        'Andreas J. Koenig',
        'andreas.koenig-- ATAT --example.net',
        undef
      ]
    ]
  ],
  [
    '"Andreas J. Koenig" <andreas.koenig-- ATAT --example.net>, advocacy-- ATAT --p.example.org',
    [
      [
        'Andreas J. Koenig',
        'andreas.koenig-- ATAT --example.net',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"Andreas J. Koenig" <andreas.koenig-- ATAT --example.net>, advocacy-- ATAT --p.example.org, regn-- ATAT --ExamPle.com',
    [
      [
        'Andreas J. Koenig',
        'andreas.koenig-- ATAT --example.net',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ],
      [
        undef,
        'regn-- ATAT --ExamPle.com',
        undef
      ]
    ]
  ],
  [
    '"Andy Wardley" <abw-- ATAT --cre.canon.co.uk>',
    [
      [
        'Andy Wardley',
        'abw-- ATAT --cre.canon.co.uk',
        undef
      ]
    ]
  ],
  [
    '"Bas A. Schulte" <bschulte-- ATAT --zeelandnet.nl>',
    [
      [
        'Bas A. Schulte',
        'bschulte-- ATAT --zeelandnet.nl',
        undef
      ]
    ]
  ],
  [
    '"Bas A.Schulte" <bschulte-- ATAT --zeelandnet.nl>',
    [
      [
        'Bas A.Schulte',
        'bschulte-- ATAT --zeelandnet.nl',
        undef
      ]
    ]
  ],
  [
    '"Betsy Waliszewski" <betsy-- ATAT --oreilly.com>, "perl-advocacy" <advocacy-- ATAT --p.example.org>',
    [
      [
        'Betsy Waliszewski',
        'betsy-- ATAT --oreilly.com',
        undef
      ],
      [
        'perl-advocacy',
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"Bradley M. Kuhn" <bkuhn-- ATAT --ebb.org>',
    [
      [
        'Bradley M. Kuhn',
        'bkuhn-- ATAT --ebb.org',
        undef
      ]
    ]
  ],
  [
    '"Brammer, Phil" <PBRA01-- ATAT --CONAGRAFROZEN.COM>',
    [
      [
        'Brammer, Phil',
        'PBRA01-- ATAT --CONAGRAFROZEN.COM',
        undef
      ]
    ]
  ],
  [
    '"Brent Michalski" <brent-- ATAT --perlguy.net>, "Madeline Schnapp" <madeline-- ATAT --oreilly.com>, <advocacy-- ATAT --p.example.org>, <betsy-- ATAT --oreilly.com>',
    [
      [
        'Brent Michalski',
        'brent-- ATAT --perlguy.net',
        undef
      ],
      [
        'Madeline Schnapp',
        'madeline-- ATAT --oreilly.com',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ],
      [
        undef,
        'betsy-- ATAT --oreilly.com',
        undef
      ]
    ]
  ],
  [
    '"Brian Wilson" <bwilson-- ATAT --songline.com>',
    [
      [
        'Brian Wilson',
        'bwilson-- ATAT --songline.com',
        undef
      ]
    ]
  ],
  [
    '"Calvin Lee" <bodyshock911-- ATAT --hotmail.com>, <advocacy-- ATAT --p.example.org>',
    [
      [
        'Calvin Lee',
        'bodyshock911-- ATAT --hotmail.com',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"Calvin Lee" <bodyshock911-- ATAT --hotmail.com>, advocacy-- ATAT --p.example.org',
    [
      [
        'Calvin Lee',
        'bodyshock911-- ATAT --hotmail.com',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"Chip Salzenberg" <chip-- ATAT --valinux.com>',
    [
      [
        'Chip Salzenberg',
        'chip-- ATAT --valinux.com',
        undef
      ]
    ]
  ],
  [
    '"Chip Salzenberg" <chip-- ATAT --valinux.com>, "Elaine -HFB- Ashton" <elaine-- ATAT --chaos.example.edu>',
    [
      [
        'Chip Salzenberg',
        'chip-- ATAT --valinux.com',
        undef
      ],
      [
        'Elaine -HFB- Ashton',
        'elaine-- ATAT --chaos.example.edu',
        undef
      ]
    ]
  ],
  [
    '"Chris Devers" <cdevers-- ATAT --boston.com>, "Uri Guttman" <uri-- ATAT --stemsystems.com>',
    [
      [
        'Chris Devers',
        'cdevers-- ATAT --boston.com',
        undef
      ],
      [
        'Uri Guttman',
        'uri-- ATAT --stemsystems.com',
        undef
      ]
    ]
  ],
  [
    '"Chris Nandor" <pudge-- ATAT --x.example.com>',
    [
      [
        'Chris Nandor',
        'pudge-- ATAT --x.example.com',
        undef
      ]
    ]
  ],
  [
    '"Chris Nandor" <pudge-- ATAT --x.example.com>, "Nathan Torkington" <gnat-- ATAT --frii.com>, "Peter Scott" <Peter-- ATAT --PSDT.com>',
    [
      [
        'Chris Nandor',
        'pudge-- ATAT --x.example.com',
        undef
      ],
      [
        'Nathan Torkington',
        'gnat-- ATAT --frii.com',
        undef
      ],
      [
        'Peter Scott',
        'Peter-- ATAT --PSDT.com',
        undef
      ]
    ]
  ],
  [
    '"Chris Nandor" <pudge-- ATAT --x.example.com>, "Nathan Torkington" <gnat-- ATAT --frii.com>, <advocacy-- ATAT --p.example.org>, "Peter Scott" <Peter-- ATAT --PSDT.com>',
    [
      [
        'Chris Nandor',
        'pudge-- ATAT --x.example.com',
        undef
      ],
      [
        'Nathan Torkington',
        'gnat-- ATAT --frii.com',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ],
      [
        'Peter Scott',
        'Peter-- ATAT --PSDT.com',
        undef
      ]
    ]
  ],
  [
    '"Clinton A. Pierce" <clintp-- ATAT --geeksalad.org>',
    [
      [
        'Clinton A. Pierce',
        'clintp-- ATAT --geeksalad.org',
        undef
      ]
    ]
  ],
  [
    '"Clinton A. Pierce" <clintp-- ATAT --geeksalad.org>, madeline-- ATAT --oreilly.com, pudge-- ATAT --x.example.com, advocacy-- ATAT --p.example.org',
    [
      [
        'Clinton A. Pierce',
        'clintp-- ATAT --geeksalad.org',
        undef
      ],
      [
        undef,
        'madeline-- ATAT --oreilly.com',
        undef
      ],
      [
        undef,
        'pudge-- ATAT --x.example.com',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"Curtis Poe" <cp-- ATAT --onsitetech.com>, <advocacy-- ATAT --p.example.org>',
    [
      [
        'Curtis Poe',
        'cp-- ATAT --onsitetech.com',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"Curtis Poe" <cp-- ATAT --onsitetech.com>, advocacy-- ATAT --p.example.org',
    [
      [
        'Curtis Poe',
        'cp-- ATAT --onsitetech.com',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"Dave Cross" <dave-- ATAT --dave.org.uk>',
    [
      [
        'Dave Cross',
        'dave-- ATAT --dave.org.uk',
        undef
      ]
    ]
  ],
  [
    '"David E. Wheeler" <David-- ATAT --Wheeler.net>',
    [
      [
        'David E. Wheeler',
        'David-- ATAT --Wheeler.net',
        undef
      ]
    ]
  ],
  [
    '"David E. Wheeler" <David-- ATAT --Wheeler.net>, "\'Larry Wall\'" <larry-- ATAT --wall.org>, "\'Jon Orwant\'" <orwant-- ATAT --media.mit.edu>, chip-- ATAT --valinux.com, tidbit-- ATAT --sri.net, advocacy-- ATAT --p.example.org',
    [
      [
        'David E. Wheeler',
        'David-- ATAT --Wheeler.net',
        undef
      ],
      [
        '\'Larry Wall\'',
        'larry-- ATAT --wall.org',
        undef
      ],
      [
        '\'Jon Orwant\'',
        'orwant-- ATAT --media.mit.edu',
        undef
      ],
      [
        undef,
        'chip-- ATAT --valinux.com',
        undef
      ],
      [
        undef,
        'tidbit-- ATAT --sri.net',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"David E. Wheeler" <David-- ATAT --Wheeler.net>, \'Elaine -HFB- Ashton\' <elaine-- ATAT --chaos.example.edu>, \'Larry Wall\' <larry-- ATAT --wall.org>, \'Jon Orwant\' <orwant-- ATAT --media.mit.edu>, tidbit-- ATAT --sri.net, advocacy-- ATAT --p.example.org',
    [
      [
        'David E. Wheeler',
        'David-- ATAT --Wheeler.net',
        undef
      ],
      [
        '\'Elaine -HFB- Ashton\'',
        'elaine-- ATAT --chaos.example.edu',
        undef
      ],
      [
        '\'Larry Wall\'',
        'larry-- ATAT --wall.org',
        undef
      ],
      [
        '\'Jon Orwant\'',
        'orwant-- ATAT --media.mit.edu',
        undef
      ],
      [
        undef,
        'tidbit-- ATAT --sri.net',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"David Grove" <pete-- ATAT --petes-place.com>',
    [
      [
        'David Grove',
        'pete-- ATAT --petes-place.com',
        undef
      ]
    ]
  ],
  [
    '"David Grove" <pete-- ATAT --petes-place.com>, <advocacy-- ATAT --p.example.org>',
    [
      [
        'David Grove',
        'pete-- ATAT --petes-place.com',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"David H. Adler" <dha-- ATAT --panix.com>',
    [
      [
        'David H. Adler',
        'dha-- ATAT --panix.com',
        undef
      ]
    ]
  ],
  [
    '"David H. Adler" <dha-- ATAT --panix.com>, <advocacy-- ATAT --p.example.org>, <simon-- ATAT --brecon.co.uk>',
    [
      [
        'David H. Adler',
        'dha-- ATAT --panix.com',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ],
      [
        undef,
        'simon-- ATAT --brecon.co.uk',
        undef
      ]
    ]
  ],
  [
    '"David H. Adler" <dha-- ATAT --panix.com>, advocacy-- ATAT --p.example.org',
    [
      [
        'David H. Adler',
        'dha-- ATAT --panix.com',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"David H. Adler" <dha-- ATAT --panix.com>, advocacy-- ATAT --p.example.org, perl5-porters-- ATAT --p.example.org',
    [
      [
        'David H. Adler',
        'dha-- ATAT --panix.com',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ],
      [
        undef,
        'perl5-porters-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"David H. Adler" <dha-- ATAT --panix.com>,advocacy-- ATAT --p.example.org',
    [
      [
        'David H. Adler',
        'dha-- ATAT --panix.com',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"Edwards, Darryl" <Darryl.Edwards-- ATAT --adc.com>',
    [
      [
        'Edwards, Darryl',
        'Darryl.Edwards-- ATAT --adc.com',
        undef
      ]
    ]
  ],
  [
    '"Elaine -HFB- Ashton" <elaine-- ATAT --chaos.example.edu>',
    [
      [
        'Elaine -HFB- Ashton',
        'elaine-- ATAT --chaos.example.edu',
        undef
      ]
    ]
  ],
  [
    '"Elaine -HFB- Ashton" <elaine-- ATAT --chaos.example.edu>, "Brent Michalski" <brent-- ATAT --perlguy.net>',
    [
      [
        'Elaine -HFB- Ashton',
        'elaine-- ATAT --chaos.example.edu',
        undef
      ],
      [
        'Brent Michalski',
        'brent-- ATAT --perlguy.net',
        undef
      ]
    ]
  ],
  [
    '"Elaine -HFB- Ashton" <elaine-- ATAT --chaos.example.edu>, "Frank Schmuck, CFO" <fschmuck-- ATAT --l.example.org>',
    [
      [
        'Elaine -HFB- Ashton',
        'elaine-- ATAT --chaos.example.edu',
        undef
      ],
      [
        'Frank Schmuck, CFO',
        'fschmuck-- ATAT --l.example.org',
        undef
      ]
    ]
  ],
  [
    '"Elaine -HFB- Ashton" <elaine-- ATAT --chaos.example.edu>, "Peter Scott" <Peter-- ATAT --PSDT.com>',
    [
      [
        'Elaine -HFB- Ashton',
        'elaine-- ATAT --chaos.example.edu',
        undef
      ],
      [
        'Peter Scott',
        'Peter-- ATAT --PSDT.com',
        undef
      ]
    ]
  ],
  [
    '"Elaine -HFB- Ashton" <elaine-- ATAT --chaos.example.edu>, "Tom Christiansen" <tchrist-- ATAT --chthon.perl.com>, <Ben_Tilly-- ATAT --trepp.com>, "David H. Adler" <dha-- ATAT --panix.com>, <advocacy-- ATAT --p.example.org>',
    [
      [
        'Elaine -HFB- Ashton',
        'elaine-- ATAT --chaos.example.edu',
        undef
      ],
      [
        'Tom Christiansen',
        'tchrist-- ATAT --chthon.perl.com',
        undef
      ],
      [
        undef,
        'Ben_Tilly-- ATAT --trepp.com',
        undef
      ],
      [
        'David H. Adler',
        'dha-- ATAT --panix.com',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"Elaine -HFB- Ashton" <elaine-- ATAT --chaos.example.edu>, "brian d foy" <tidbit-- ATAT --sri.net>, <advocacy-- ATAT --p.example.org>',
    [
      [
        'Elaine -HFB- Ashton',
        'elaine-- ATAT --chaos.example.edu',
        undef
      ],
      [
        'brian d foy',
        'tidbit-- ATAT --sri.net',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"Elaine -HFB- Ashton" <elaine-- ATAT --chaos.example.edu>, <advocacy-- ATAT --p.example.org>',
    [
      [
        'Elaine -HFB- Ashton',
        'elaine-- ATAT --chaos.example.edu',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"Frank Schmuck, CFO" <fschmuck-- ATAT --l.example.org>',
    [
      [
        'Frank Schmuck, CFO',
        'fschmuck-- ATAT --l.example.org',
        undef
      ]
    ]
  ],
  [
    '"Frank Schmuck, CFO" <fschmuck-- ATAT --l.example.org>, "\'abigail-- ATAT --foad.example.biz\'" <abigail-- ATAT --foad.example.biz>, Michael G Schwern <schwern-- ATAT --x.example.com>,  Nicholas Clark <nick-- ATAT --c.example.org>, advocacy-- ATAT --p.example.org',
    [
      [
        'Frank Schmuck, CFO',
        'fschmuck-- ATAT --l.example.org',
        undef
      ],
      [
        '\'abigail-- ATAT --foad.example.biz\'',
        'abigail-- ATAT --foad.example.biz',
        undef
      ],
      [
        'Michael G Schwern',
        'schwern-- ATAT --x.example.com',
        undef
      ],
      [
        'Nicholas Clark',
        'nick-- ATAT --c.example.org',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"G. Wade Johnson" <gwadej-- ATAT --normal.example.coop>',
    [
      [
        'G. Wade Johnson',
        'gwadej-- ATAT --normal.example.coop',
        undef
      ]
    ]
  ],
  [
    '"Gabor Szabo" <gabor-- ATAT --trt.example.biz>',
    [
      [
        'Gabor Szabo',
        'gabor-- ATAT --trt.example.biz',
        undef
      ]
    ]
  ],
  [
    '"Greg Norris (humble visionary genius)" <nextrightmove-- ATAT --bang.example.net>, <advocacy-- ATAT --p.example.org>',
    [
      [
        'Greg Norris',
        'nextrightmove-- ATAT --bang.example.net',
        '(humble visionary genius)'
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"Greg Norris \\(humble visionary genius\\)" <nextrightmove-- ATAT --bang.example.net>',
    [
      [
        'Greg Norris (humble visionary genius)',
        'nextrightmove-- ATAT --bang.example.net',
        undef
      ]
    ]
  ],
  [
    '"Greg Norris humble visionary genius\\"" <nextrightmove-- ATAT --bang.example.net>',
    [
      [
        'Greg Norris humble visionary genius"',
        'nextrightmove-- ATAT --bang.example.net',
        undef
      ]
    ]
  ],
  [
    '"Helton, Brandon" <bhelton-- ATAT --h.h.example.com>, perl6-language-- ATAT --p.example.org, advocacy-- ATAT --p.example.org',
    [
      [
        'Helton, Brandon',
        'bhelton-- ATAT --h.h.example.com',
        undef
      ],
      [
        undef,
        'perl6-language-- ATAT --p.example.org',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    '"Jan Dubois" <jand-- ATAT --ExamPle.com>',
    [
      [
        'Jan Dubois',
        'jand-- ATAT --ExamPle.com',
        undef
      ]
    ]
  ],
  [
    '"Jason W. May" <jasonmay-- ATAT --example.name>',
    [
      [
        'Jason W. May',
        'jasonmay-- ATAT --example.name',
        undef
      ]
    ]
  ],
  [
    '"Jason W. May" <jmay-- ATAT --x.example.com>',
    [
      [
        'Jason W. May',
        'jmay-- ATAT --x.example.com',
        undef
      ]
    ]
  ],
  [
    '"Jason W. May" <jmay-- ATAT --x.example.com>, <advocacy-- ATAT --p.example.org>',
    [
      [
        'Jason W. May',
        'jmay-- ATAT --x.example.com',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    'Jason W. May <jmay-- ATAT --x.example.com>',
    [
      [
        'Jason W. May',
        'jmay-- ATAT --x.example.com',
        undef
      ]
    ]
  ],
  [
    '"Jason W. May" <jmay-- ATAT --x.example.com>, advocacy-- ATAT --p.example.org',
    [
      [
        'Jason W. May',
        'jmay-- ATAT --x.example.com',
        undef
      ],
      [
        undef,
        'advocacy-- ATAT --p.example.org',
        undef
      ]
    ]
  ],
  [
    'admin+=E6=96=B0=E5=8A=A0=E5=9D=A1_Weblog@test.sxt.example.info',
    [
      [
        undef,
        'admin+=E6=96=B0=E5=8A=A0=E5=9D=A1_Weblog-- ATAT --test.sxt.example.info',
        undef,
      ],
    ],
  ],
  [
    q{"<fake-- ATAT --bogus.biz>" <real-- ATAT --actual.mil>},
    [
      [
        '<fake-- ATAT --bogus.biz>',
        'real-- ATAT --actual.mil',
        undef,
      ],
    ],
  ],
);

my $tests = 1;
$tests += @list;

plan tests => $tests;

use_ok 'Email::Address';

for my $i (0 .. $#list) {
  local $_ = $list[$i];

  subtest "test case $i" => sub {
    $_->[0] =~ s/-- ATAT --/@/g;
    my @addrs = Email::Address->parse($_->[0]);
    my $count = @{ $_->[1] };

    my @tests =
      map { Email::Address->new(map { $_ ? do {s/-- ATAT --/@/g; $_} : $_ } @$_) }
      @{$_->[1]};

    unless ( is(@addrs, $count, "got expected result count") ) {
        diag "addresses actually received:";
        diag "  - " . $_->format for @addrs;
        return;
    }

    for (0 .. $#addrs) {
        my $addr = $addrs[$_];
        my $spec = $list[$i][1][$_];

        my $test = Email::Address->new(@$spec);

        subtest "parse results" => sub {
            is($addr->phrase, $spec->[0], "phrase");
        };

        subtest "round trip comparison" => sub {
            is($addr->format,    $test->format, "format: " . $test->format);
            is($addr->as_string, $test->format, "format: " . $test->format);
            is("$addr",          $test->format, "stringify: $addr");
            is($addr->name,      $test->name,   "name: " . $test->name);
        };
    }
  }
}
