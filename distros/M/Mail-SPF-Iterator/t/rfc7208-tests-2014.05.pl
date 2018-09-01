[
  {
    'zonedata' => {
      'example.com' => [
        'TIMEOUT'
      ],
      'a.example.net' => [
        {
          'SPF' => 'v=spf1 -all exp=exp.example.net'
        }
      ],
      'exp.example.net' => [
        {
          'TXT' => '%{l}'
        }
      ],
      'hosed2.example.com' => [
        {
          'SPF' => "v=spf1 \x{80}a:example.net -all"
        }
      ],
      'example.net' => [
        {
          'SPF' => 'v=spf1 -all exp=exp.example.net'
        }
      ],
      'hosed.example.com' => [
        {
          'SPF' => "v=spf1 a:\x{ef}\x{bb}\x{bf}garbage.example.net -all"
        }
      ],
      'nothosed.example.com' => [
        {
          'SPF' => 'v=spf1 a:example.net -all'
        },
        {
          'SPF' => "\x{96}"
        }
      ],
      'a12345678901234567890123456789012345678901234567890123456789012.example.com' => [
        {
          'SPF' => 'v=spf1 -all'
        }
      ],
      'hosed3.example.com' => [
        {
          'SPF' => "v=spf1 a:example.net \x{96}all"
        }
      ]
    },
    'tests' => {
      'non-ascii-policy' => {
        'mailfrom' => 'foobar@hosed.example.com',
        'host' => '1.2.3.4',
        'helo' => 'hosed',
        'result' => 'permerror',
        'spec' => '3.1/1',
        'description' => 'SPF policies are restricted to 7-bit ascii.'
      },
      'non-ascii-result' => {
        'description' => 'SPF policies are restricted to 7-bit ascii.',
        'spec' => '3.1/1',
        'host' => '1.2.3.4',
        'helo' => 'hosed',
        'comment' => 'Checking yet another code path for non-ascii chars.',
        'mailfrom' => 'foobar@hosed3.example.com',
        'result' => 'permerror'
      },
      'toolonglabel' => {
        'result' => 'none',
        'comment' => 'For initial processing, a long label results in None, not TempError',
        'mailfrom' => 'lyme.eater@A123456789012345678901234567890123456789012345678901234567890123.example.com',
        'helo' => 'mail.example.net',
        'host' => '1.2.3.5',
        'spec' => '4.3/1',
        'description' => 'DNS labels limited to 63 chars.'
      },
      'longlabel' => {
        'result' => 'fail',
        'mailfrom' => 'lyme.eater@A12345678901234567890123456789012345678901234567890123456789012.example.com',
        'host' => '1.2.3.5',
        'helo' => 'mail.example.net',
        'spec' => '4.3/1',
        'description' => 'DNS labels limited to 63 chars.'
      },
      'helo-domain-literal' => {
        'mailfrom' => '',
        'helo' => '[1.2.3.5]',
        'host' => '1.2.3.5',
        'result' => 'none',
        'spec' => '4.3/1'
      },
      'nolocalpart' => {
        'result' => 'fail',
        'mailfrom' => '@example.net',
        'explanation' => 'postmaster',
        'helo' => 'mail.example.net',
        'host' => '1.2.3.4',
        'spec' => '4.3/2'
      },
      'helo-not-fqdn' => {
        'spec' => '4.3/1',
        'helo' => 'A2345678',
        'host' => '1.2.3.5',
        'mailfrom' => '',
        'result' => 'none'
      },
      'non-ascii-non-spf' => {
        'mailfrom' => 'foobar@nothosed.example.com',
        'host' => '1.2.3.4',
        'explanation' => 'DEFAULT',
        'result' => 'fail',
        'spec' => '4.5/1',
        'comment' => 'Non-SPF related TXT records are none of our business.',
        'helo' => 'hosed',
        'description' => 'Non-ascii content in non-SPF related records.'
      },
      'domain-literal' => {
        'spec' => '4.3/1',
        'helo' => 'OEMCOMPUTER',
        'host' => '1.2.3.5',
        'mailfrom' => 'foo@[1.2.3.5]',
        'result' => 'none'
      },
      'emptylabel' => {
        'result' => 'none',
        'host' => '1.2.3.5',
        'helo' => 'mail.example.net',
        'mailfrom' => 'lyme.eater@A...example.com',
        'spec' => '4.3/1'
      },
      'non-ascii-mech' => {
        'description' => 'SPF policies are restricted to 7-bit ascii.',
        'spec' => '3.1/1',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'hosed',
        'mailfrom' => 'foobar@hosed2.example.com',
        'comment' => 'Checking a possibly different code path for non-ascii chars.'
      }
    },
    'description' => 'Initial processing'
  },
  {
    'description' => 'Record lookup',
    'zonedata' => {
      'alltimeout.example.net' => [
        'TIMEOUT'
      ],
      'nospftxttimeout.example.net' => [
        {
          'SPF' => 'v=spf3 !a:yahoo.com -all'
        },
        {
          'TXT' => 'NONE'
        },
        'TIMEOUT'
      ],
      'txttimeout.example.net' => [
        {
          'SPF' => 'v=spf1 -all'
        },
        {
          'TXT' => 'NONE'
        },
        'TIMEOUT'
      ],
      'both.example.net' => [
        {
          'TXT' => 'v=spf1 -all'
        },
        {
          'SPF' => 'v=spf1 -all'
        }
      ],
      'spfonly.example.net' => [
        {
          'SPF' => 'v=spf1 -all'
        },
        {
          'TXT' => 'NONE'
        }
      ],
      'txtonly.example.net' => [
        {
          'TXT' => 'v=spf1 -all'
        }
      ],
      'spftimeout.example.net' => [
        {
          'TXT' => 'v=spf1 -all'
        },
        'TIMEOUT'
      ]
    },
    'tests' => {
      'spftimeout' => {
        'helo' => 'mail.example.net',
        'host' => '1.2.3.4',
        'mailfrom' => 'foo@spftimeout.example.net',
        'comment' => 'This actually happens for a popular braindead DNS server.',
        'result' => 'fail',
        'description' => 'TXT record present, but SPF lookup times out. Result is temperror if checking SPF records only.  Fortunately, we don\'t do type SPF anymore.',
        'spec' => '4.4/1'
      },
      'alltimeout' => {
        'description' => 'Both TXT and SPF queries time out',
        'spec' => '4.4/2',
        'result' => 'temperror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.net',
        'mailfrom' => 'foo@alltimeout.example.net'
      },
      'txtonly' => {
        'spec' => '4.4/1',
        'description' => 'Result is none if checking SPF records only (which you should not be doing).',
        'mailfrom' => 'foo@txtonly.example.net',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.net',
        'result' => 'fail'
      },
      'spfonly' => {
        'spec' => '4.4/1',
        'description' => 'Result is none if checking TXT records only.',
        'result' => 'none',
        'mailfrom' => 'foo@spfonly.example.net',
        'helo' => 'mail.example.net',
        'host' => '1.2.3.4'
      },
      'both' => {
        'host' => '1.2.3.4',
        'helo' => 'mail.example.net',
        'mailfrom' => 'foo@both.example.net',
        'result' => 'fail',
        'spec' => '4.4/1'
      },
      'nospftxttimeout' => {
        'result' => 'temperror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.net',
        'comment' => 'Because TXT records is where v=spf1 records will likely be, returning temperror will try again later.  A timeout due to a braindead server is unlikely in the case of TXT, as opposed to the newer SPF RR.',
        'mailfrom' => 'foo@nospftxttimeout.example.net',
        'spec' => '4.4/1',
        'description' => 'No SPF record present, and TXT lookup times out. If only TXT records are checked, result is temperror.'
      },
      'txttimeout' => {
        'helo' => 'mail.example.net',
        'host' => '1.2.3.4',
        'mailfrom' => 'foo@txttimeout.example.net',
        'result' => 'temperror',
        'description' => 'SPF record present, but TXT lookup times out. If only TXT records are checked, result is temperror.',
        'spec' => '4.4/1'
      }
    }
  },
  {
    'zonedata' => {
      'example2.com' => [
        {
          'SPF' => [
            'v=spf1',
            'mx'
          ]
        }
      ],
      'example3.com' => [
        {
          'SPF' => 'v=spf10'
        },
        {
          'SPF' => 'v=spf1 mx'
        },
        {
          'MX' => [
            '0',
            'mail.example1.com'
          ]
        }
      ],
      'example6.com' => [
        {
          'SPF' => 'v=spf1 -all'
        },
        {
          'SPF' => 'V=sPf1 +all'
        }
      ],
      'example8.com' => [
        {
          'SPF' => 'V=spf1 -all'
        },
        {
          'SPF' => 'v=spf1 -all'
        },
        {
          'TXT' => 'v=spf1 +all'
        }
      ],
      'example4.com' => [
        {
          'SPF' => 'v=spf1 +all'
        },
        {
          'TXT' => 'v=spf1 -all'
        }
      ],
      'example7.com' => [
        {
          'SPF' => 'v=spf1 -all'
        },
        {
          'SPF' => 'v=spf1 -all'
        }
      ],
      'example1.com' => [
        {
          'SPF' => 'v=spf1'
        }
      ],
      'example9.com' => [
        {
          'SPF' => 'v=SpF1 ~all'
        }
      ],
      'example5.com' => [
        {
          'SPF' => 'v=spf1 +all'
        },
        {
          'TXT' => 'v=spf1 -all'
        },
        {
          'TXT' => 'v=spf1 +all'
        }
      ],
      'mail.example1.com' => [
        {
          'A' => '1.2.3.4'
        }
      ]
    },
    'tests' => {
      'multitxt2' => {
        'mailfrom' => 'foo@example6.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example1.com',
        'result' => 'permerror',
        'description' => 'Multiple records is a permerror, v=spf1 is case insensitive',
        'spec' => '4.5/6'
      },
      'nospace1' => {
        'result' => 'none',
        'mailfrom' => 'foo@example2.com',
        'helo' => 'mail.example1.com',
        'host' => '1.2.3.4',
        'description' => 'Version must be terminated by space or end of record.  TXT pieces are joined without intervening spaces.',
        'spec' => '4.5/4'
      },
      'multitxt1' => {
        'spec' => '4.5/5',
        'description' => 'Implementations should give permerror/unknown because of the conflicting TXT records.',
        'mailfrom' => 'foo@example5.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example1.com',
        'result' => 'permerror'
      },
      'case-insensitive' => {
        'mailfrom' => 'foo@example9.com',
        'helo' => 'mail.example1.com',
        'host' => '1.2.3.4',
        'result' => 'softfail',
        'spec' => '4.5/6',
        'description' => 'v=spf1 is case insensitive'
      },
      'empty' => {
        'result' => 'neutral',
        'mailfrom' => 'foo@example1.com',
        'host' => '1.2.3.4',
        'helo' => 'mail1.example1.com',
        'description' => 'Empty SPF record.',
        'spec' => '4.5/4'
      },
      'spfoverride' => {
        'host' => '1.2.3.4',
        'helo' => 'mail.example1.com',
        'mailfrom' => 'foo@example4.com',
        'result' => 'fail',
        'description' => 'SPF records no longer used.',
        'spec' => '4.5/5'
      },
      'multispf2' => {
        'result' => 'pass',
        'host' => '1.2.3.4',
        'helo' => 'mail.example1.com',
        'mailfrom' => 'foo@example8.com',
        'spec' => '4.5/6',
        'description' => 'Ignoring SPF-type records will give pass because there is a (single) TXT record.'
      },
      'nospf' => {
        'helo' => 'mail.example1.com',
        'host' => '1.2.3.4',
        'mailfrom' => 'foo@mail.example1.com',
        'result' => 'none',
        'spec' => '4.5/7'
      },
      'multispf1' => {
        'description' => 'Multiple records is a permerror, even when they are identical. However, this situation cannot be reliably reproduced with live DNS since cache and resolvers are allowed to combine identical records.',
        'spec' => '4.5/6',
        'helo' => 'mail.example1.com',
        'host' => '1.2.3.4',
        'mailfrom' => 'foo@example7.com',
        'result' => [
          'permerror',
          'fail'
        ]
      },
      'nospace2' => {
        'result' => 'pass',
        'helo' => 'mail.example1.com',
        'host' => '1.2.3.4',
        'mailfrom' => 'foo@example3.com',
        'spec' => '4.5/4'
      }
    },
    'description' => 'Selecting records'
  },
  {
    'description' => 'Record evaluation',
    'zonedata' => {
      't3.example.com' => [
        {
          'SPF' => 'v=spf1 moo.cow/far_out=man:dog/cat ip4:1.2.3.4 -all'
        }
      ],
      't8.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.2.3.4 redirect:t2.example.com'
        }
      ],
      'mail.example.com' => [
        {
          'A' => '1.2.3.4'
        }
      ],
      't11.example.com' => [
        {
          'SPF' => 'v=spf1 a:a123456789012345678901234567890123456789012345678901234567890123.example.com -all'
        }
      ],
      't12.example.com' => [
        {
          'SPF' => 'v=spf1 a:%{H}.bar -all'
        }
      ],
      't2.example.com' => [
        {
          'SPF' => 'v=spf1 moo.cow-far_out=man:dog/cat ip4:1.2.3.4 -all'
        }
      ],
      't7.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.2.3.4'
        }
      ],
      't6.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.2.3.4 redirect=t2.example.com'
        }
      ],
      't10.example.com' => [
        {
          'SPF' => 'v=spf1 a:mail.example...com -all'
        }
      ],
      't4.example.com' => [
        {
          'SPF' => 'v=spf1 moo.cow:far_out=man:dog/cat ip4:1.2.3.4 -all'
        }
      ],
      't9.example.com' => [
        {
          'SPF' => 'v=spf1 a:foo-bar -all'
        }
      ],
      't1.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.2.3.4 -all moo'
        }
      ],
      't5.example.com' => [
        {
          'SPF' => 'v=spf1 redirect=t5.example.com ~all'
        }
      ]
    },
    'tests' => {
      'redirect-is-modifier' => {
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'mailfrom' => 'foo@t8.example.com',
        'description' => 'Invalid mechanism.  Redirect is a modifier.',
        'spec' => '4.6.1/4'
      },
      'invalid-domain-long-via-macro' => {
        'result' => [
          'fail',
          'permerror'
        ],
        'comment' => 'A domain label longer than 63 characters that results from macro expansion in a mechanism target-name is valid domain-spec syntax (and is not even subject to syntax checking after macro expansion), even though a DNS query cannot be composed from it.  The spec being unclear about it, this could either be considered a syntax error, or, by analogy to 4.3/1 and 5/10/3, the mechanism could be treated as a no-match.  RFC 7208 failed to agree on which result to use, and declares the situation undefined.  The preferred test result is therefore a matter of opinion.',
        'mailfrom' => 'foo@t12.example.com',
        'host' => '1.2.3.4',
        'helo' => '%%%%%%%%%%%%%%%%%%%%%%',
        'spec' => '4.3/1, 4.8/5, 5/10/3',
        'description' => 'target-name that is a valid domain-spec per RFC 4408 and RFC 7208 but an invalid domain name per RFC 1035 (long label) must be treated as non-existent.'
      },
      'redirect-after-mechanisms1' => {
        'mailfrom' => 'foo@t5.example.com',
        'comment' => 'The redirect in this example would violate processing limits, except that it is never used because of the all mechanism.',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'result' => 'softfail',
        'spec' => '4.6.3',
        'description' => 'The "redirect" modifier has an effect after all the mechanisms.'
      },
      'modifier-charset-bad2' => {
        'spec' => '4.6.1/4',
        'description' => '\'=\' character immediately after the name and before any ":" or "/"',
        'mailfrom' => 'foo@t4.example.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'result' => 'permerror'
      },
      'default-result' => {
        'result' => 'neutral',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.5',
        'mailfrom' => 'foo@t7.example.com',
        'description' => 'Default result is neutral.',
        'spec' => '4.7/1'
      },
      'invalid-domain-long' => {
        'description' => 'target-name that is a valid domain-spec per RFC 4408 and RFC 7208 but an invalid domain name per RFC 1035 (long label) must be treated as non-existent.',
        'spec' => '4.3/1, 4.8/5, 5/10/3',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'comment' => 'A domain label longer than 63 characters in a mechanism target-name is valid domain-spec syntax (perhaps formed from a macro expansion), even though a DNS query cannot be composed from it.  The spec being unclear about it, this could either be considered a syntax error, or, by analogy to 4.3/1 and 5/10/3, the mechanism could be treated as a no-match.  RFC 7208 failed to agree on which result to use, and declares the situation undefined.  The preferred test result is therefore a matter of opinion.',
        'mailfrom' => 'foo@t11.example.com',
        'result' => [
          'fail',
          'permerror'
        ]
      },
      'modifier-charset-bad1' => {
        'spec' => '4.6.1/4',
        'description' => '\'=\' character immediately after the name and before any ":" or "/"',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'mailfrom' => 'foo@t3.example.com',
        'result' => 'permerror'
      },
      'detect-errors-anywhere' => {
        'spec' => '4.6',
        'description' => 'Any syntax errors anywhere in the record MUST be detected.',
        'result' => 'permerror',
        'mailfrom' => 'foo@t1.example.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'modifier-charset-good' => {
        'result' => 'pass',
        'mailfrom' => 'foo@t2.example.com',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'spec' => '4.6.1/2',
        'description' => 'name = ALPHA *( ALPHA / DIGIT / "-" / "_" / "." )'
      },
      'invalid-domain-empty-label' => {
        'spec' => '4.3/1, 4.8/5, 5/10/3',
        'description' => 'target-name that is a valid domain-spec per RFC 4408 and RFC 7208 but an invalid domain name per RFC 1035 (empty label) should be treated as non-existent.',
        'comment' => 'An empty domain label, i.e. two successive dots, in a mechanism target-name is valid domain-spec syntax (perhaps formed from a macro expansion), even though a DNS query cannot be composed from it.  The spec being unclear about it, this could either be considered a syntax error, or, by analogy to 4.3/1 and 5/10/3, the mechanism could be treated as a no-match.  RFC 7208 failed to agree on which result to use, and declares the situation undefined.  The preferred test result is therefore a matter of opinion.',
        'mailfrom' => 'foo@t10.example.com',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'result' => [
          'fail',
          'permerror'
        ]
      },
      'invalid-domain' => {
        'result' => 'permerror',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'mailfrom' => 'foo@t9.example.com',
        'spec' => '7.1/2',
        'description' => 'Domain-spec must end in macro-expand or valid toplabel.'
      },
      'redirect-after-mechanisms2' => {
        'mailfrom' => 'foo@t6.example.com',
        'host' => '1.2.3.5',
        'helo' => 'mail.example.com',
        'result' => 'fail',
        'spec' => '4.6.3',
        'description' => 'The "redirect" modifier has an effect after all the mechanisms.'
      }
    }
  },
  {
    'description' => 'ALL mechanism syntax',
    'tests' => {
      'all-neutral' => {
        'mailfrom' => 'foo@e4.example.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'result' => 'neutral',
        'spec' => '5.1/1',
        'description' => 'all              = "all"
'
      },
      'all-cidr' => {
        'spec' => '5.1/1',
        'description' => 'all              = "all"
',
        'result' => 'permerror',
        'mailfrom' => 'foo@e3.example.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'all-dot' => {
        'comment' => 'At least one implementation got this wrong',
        'mailfrom' => 'foo@e1.example.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'result' => 'permerror',
        'spec' => '5.1/1',
        'description' => 'all              = "all"
'
      },
      'all-arg' => {
        'description' => 'all              = "all"
',
        'spec' => '5.1/1',
        'result' => 'permerror',
        'comment' => 'At least one implementation got this wrong',
        'mailfrom' => 'foo@e2.example.com',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4'
      },
      'all-double' => {
        'spec' => '5.1/1',
        'description' => 'all              = "all"
',
        'result' => 'pass',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'mailfrom' => 'foo@e5.example.com'
      }
    },
    'zonedata' => {
      'e5.example.com' => [
        {
          'SPF' => 'v=spf1 all -all'
        }
      ],
      'e2.example.com' => [
        {
          'SPF' => 'v=spf1 -all:foobar'
        }
      ],
      'e4.example.com' => [
        {
          'SPF' => 'v=spf1 ?all'
        }
      ],
      'e1.example.com' => [
        {
          'SPF' => 'v=spf1 -all.'
        }
      ],
      'e3.example.com' => [
        {
          'SPF' => 'v=spf1 -all/8'
        }
      ],
      'mail.example.com' => [
        {
          'A' => '1.2.3.4'
        }
      ]
    }
  },
  {
    'tests' => {
      'ptr-match-target' => {
        'result' => 'pass',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'mailfrom' => 'foo@e2.example.com',
        'description' => 'Check all validated domain names to see if they end in the <target-name> domain.',
        'spec' => '5.5/5'
      },
      'ptr-match-implicit' => {
        'result' => 'pass',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'mailfrom' => 'foo@e3.example.com',
        'description' => 'Check all validated domain names to see if they end in the <target-name> domain.',
        'spec' => '5.5/5'
      },
      'ptr-match-ip6' => {
        'mailfrom' => 'foo@e3.example.com',
        'helo' => 'mail.example.com',
        'host' => 'CAFE:BABE::1',
        'result' => 'pass',
        'description' => 'Check all validated domain names to see if they end in the <target-name> domain.',
        'spec' => '5.5/5'
      },
      'ptr-nomatch-invalid' => {
        'result' => 'fail',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'mailfrom' => 'foo@e4.example.com',
        'comment' => 'This PTR record does not validate',
        'spec' => '5.5/5',
        'description' => 'Check all validated domain names to see if they end in the <target-name> domain.'
      },
      'ptr-cidr' => {
        'spec' => '5.5/2',
        'description' => 'PTR              = "ptr"    [ ":" domain-spec ]',
        'mailfrom' => 'foo@e1.example.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'result' => 'permerror'
      },
      'ptr-empty-domain' => {
        'spec' => '5.5/2',
        'description' => 'domain-spec cannot be empty.',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'mailfrom' => 'foo@e5.example.com',
        'result' => 'permerror'
      }
    },
    'zonedata' => {
      '4.3.2.1.in-addr.arpa' => [
        {
          'PTR' => 'e3.example.com'
        },
        {
          'PTR' => 'e4.example.com'
        },
        {
          'PTR' => 'mail.example.com'
        }
      ],
      'e2.example.com' => [
        {
          'SPF' => 'v=spf1 ptr:example.com -all'
        }
      ],
      'e3.example.com' => [
        {
          'SPF' => 'v=spf1 ptr -all'
        },
        {
          'A' => '1.2.3.4'
        },
        {
          'AAAA' => 'CAFE:BABE::1'
        }
      ],
      'mail.example.com' => [
        {
          'A' => '1.2.3.4'
        }
      ],
      'e5.example.com' => [
        {
          'SPF' => 'v=spf1 ptr:'
        }
      ],
      '1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.E.B.A.B.E.F.A.C.ip6.arpa' => [
        {
          'PTR' => 'e3.example.com'
        }
      ],
      'e4.example.com' => [
        {
          'SPF' => 'v=spf1 ptr -all'
        }
      ],
      'e1.example.com' => [
        {
          'SPF' => 'v=spf1 ptr/0 -all'
        }
      ]
    },
    'description' => 'PTR mechanism syntax'
  },
  {
    'zonedata' => {
      'e2b.example.com' => [
        {
          'A' => '1.1.1.1'
        },
        {
          'SPF' => 'v=spf1 a//0 -all'
        }
      ],
      'e3.example.com' => [
        {
          'SPF' => 'v=spf1 a:foo.example.com '
        }
      ],
      'e14.example.com' => [
        {
          'SPF' => 'v=spf1 a:foo.example.xn--zckzah -all'
        }
      ],
      'mail.example.com' => [
        {
          'A' => '1.2.3.4'
        }
      ],
      'e5a.example.com' => [
        {
          'SPF' => 'v=spf1 a:museum'
        }
      ],
      'e12.example.com' => [
        {
          'SPF' => 'v=spf1 a:example.-com'
        }
      ],
      'foo.example.com' => [
        {
          'A' => '1.1.1.1'
        },
        {
          'A' => '1.2.3.5'
        }
      ],
      'ipv6.example.com' => [
        {
          'AAAA' => '1234::1'
        },
        {
          'A' => '1.1.1.1'
        },
        {
          'SPF' => 'v=spf1 a -all'
        }
      ],
      'e6.example.com' => [
        {
          'SPF' => 'v=spf1 a//33 -all'
        }
      ],
      'e1.example.com' => [
        {
          'SPF' => 'v=spf1 a/0 -all'
        }
      ],
      'e8b.example.com' => [
        {
          'A' => '1.2.3.5'
        },
        {
          'AAAA' => '2001:db8:1234::dead:beef'
        },
        {
          'SPF' => 'v=spf1 a//64 -all'
        }
      ],
      'e8a.example.com' => [
        {
          'A' => '1.2.3.5'
        },
        {
          'AAAA' => '2001:db8:1234::dead:beef'
        },
        {
          'SPF' => 'v=spf1 a/24 -all'
        }
      ],
      'e5.example.com' => [
        {
          'SPF' => 'v=spf1 a:abc.123'
        }
      ],
      'e5b.example.com' => [
        {
          'SPF' => 'v=spf1 a:museum.'
        }
      ],
      'e8e.example.com' => [
        {
          'A' => '1.2.3.5'
        },
        {
          'AAAA' => '2001:db8:1234::dead:beef'
        },
        {
          'SPF' => 'v=spf1 a/24/64 -all'
        }
      ],
      'e13.example.com' => [
        {
          'SPF' => 'v=spf1 a:'
        }
      ],
      'e2a.example.com' => [
        {
          'AAAA' => '1234::1'
        },
        {
          'SPF' => 'v=spf1 a//0 -all'
        }
      ],
      'e10.example.com' => [
        {
          'SPF' => 'v=spf1 a:foo.example.com/24'
        }
      ],
      'e2.example.com' => [
        {
          'A' => '1.1.1.1'
        },
        {
          'AAAA' => '1234::2'
        },
        {
          'SPF' => 'v=spf1 a/0 -all'
        }
      ],
      'foo.example.xn--zckzah' => [
        {
          'A' => '1.2.3.4'
        }
      ],
      'e7.example.com' => [
        {
          'SPF' => 'v=spf1 a//129 -all'
        }
      ],
      'e6a.example.com' => [
        {
          'SPF' => 'v=spf1 a/33 -all'
        }
      ],
      'e4.example.com' => [
        {
          'SPF' => 'v=spf1 a:111.222.33.44'
        }
      ],
      'e11.example.com' => [
        {
          'SPF' => 'v=spf1 a:foo:bar/baz.example.com'
        }
      ],
      'e9.example.com' => [
        {
          'SPF' => 'v=spf1 a:example.com:8080'
        }
      ],
      'e8.example.com' => [
        {
          'A' => '1.2.3.5'
        },
        {
          'AAAA' => '2001:db8:1234::dead:beef'
        },
        {
          'SPF' => 'v=spf1 a/24//64 -all'
        }
      ],
      'foo:bar/baz.example.com' => [
        {
          'A' => '1.2.3.4'
        }
      ]
    },
    'tests' => {
      'a-only-toplabel-trailing-dot' => {
        'spec' => '7.1/2',
        'description' => 'domain-spec may not consist of only a toplabel.',
        'result' => 'permerror',
        'mailfrom' => 'foo@e5b.example.com',
        'comment' => '"A trailing dot doesn\'t help."',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4'
      },
      'a-cidr6' => {
        'result' => 'fail',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'mailfrom' => 'foo@e6.example.com',
        'spec' => '5.3/2',
        'description' => 'A                = "a"      [ ":" domain-spec ] [ dual-cidr-length ]
dual-cidr-length = [ ip4-cidr-length ] [ "/" ip6-cidr-length ]
'
      },
      'a-cidr4-0-ip6' => {
        'spec' => '5.3/3',
        'description' => 'Matches if any A records are present in DNS.',
        'mailfrom' => 'foo@e2.example.com',
        'helo' => 'mail.example.com',
        'host' => '1234::1',
        'result' => 'fail'
      },
      'a-only-toplabel' => {
        'mailfrom' => 'foo@e5a.example.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'result' => 'permerror',
        'spec' => '7.1/2',
        'description' => 'domain-spec may not consist of only a toplabel.'
      },
      'a-ip6-dualstack' => {
        'description' => 'Simple IP6 Address match with dual stack.',
        'spec' => '5.3/3',
        'result' => 'pass',
        'host' => '1234::1',
        'helo' => 'mail.example.com',
        'mailfrom' => 'foo@ipv6.example.com'
      },
      'a-cidr6-0-ip4mapped' => {
        'spec' => '5.3/3',
        'description' => 'Would match if any AAAA records are present in DNS, but not for an IP4 connection.',
        'host' => '::FFFF:1.2.3.4',
        'helo' => 'mail.example.com',
        'mailfrom' => 'foo@e2a.example.com',
        'result' => 'fail'
      },
      'a-cidr6-0-ip6' => {
        'spec' => '5.3/3',
        'description' => 'Matches if any AAAA records are present in DNS.',
        'host' => '1234::1',
        'helo' => 'mail.example.com',
        'mailfrom' => 'foo@e2a.example.com',
        'result' => 'pass'
      },
      'a-dual-cidr-ip6-default' => {
        'result' => 'fail',
        'host' => '2001:db8:1234::cafe:babe',
        'helo' => 'mail.example.com',
        'mailfrom' => 'foo@e8a.example.com',
        'spec' => '5.3/2',
        'description' => 'A                = "a"      [ ":" domain-spec ] [ dual-cidr-length ]
dual-cidr-length = [ ip4-cidr-length ] [ "/" ip6-cidr-length ]
'
      },
      'a-null' => {
        'description' => 'Null octets not allowed in toplabel',
        'spec' => '7.1/2',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.5',
        'mailfrom' => 'foo@e3.example.com',
        'result' => 'permerror'
      },
      'a-multi-ip2' => {
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'mailfrom' => 'foo@e10.example.com',
        'result' => 'pass',
        'description' => 'A matches any returned IP.',
        'spec' => '5.3/3'
      },
      'a-bad-domain' => {
        'spec' => '7.1/2',
        'description' => 'domain-spec must pass basic syntax checks; a \':\' may appear in domain-spec, but not in top-label',
        'mailfrom' => 'foo@e9.example.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'result' => 'permerror'
      },
      'a-numeric-toplabel' => {
        'description' => 'toplabel may not be all numeric',
        'spec' => '7.1/2',
        'mailfrom' => 'foo@e5.example.com',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'result' => 'permerror'
      },
      'a-dash-in-toplabel' => {
        'description' => 'toplabel may contain dashes',
        'spec' => '7.1/2',
        'result' => 'pass',
        'mailfrom' => 'foo@e14.example.com',
        'comment' => 'Going from the "toplabel" grammar definition, an implementation using regular expressions in incrementally parsing SPF records might erroneously try to match a TLD such as ".xn--zckzah" (cf. IDN TLDs!) to \'( *alphanum ALPHA *alphanum )\' first before trying the alternative \'( 1*alphanum "-" *( alphanum / "-" ) alphanum )\', essentially causing a non-greedy, and thus, incomplete match.  Make sure a greedy match is performed!',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4'
      },
      'a-bad-cidr4' => {
        'mailfrom' => 'foo@e6a.example.com',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'result' => 'permerror',
        'description' => 'A                = "a"      [ ":" domain-spec ] [ dual-cidr-length ]
dual-cidr-length = [ ip4-cidr-length ] [ "/" ip6-cidr-length ]
',
        'spec' => '5.3/2'
      },
      'a-nxdomain' => {
        'spec' => '5.3/3',
        'description' => 'If no ips are returned, A mechanism does not match, even with /0.',
        'mailfrom' => 'foo@e1.example.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'result' => 'fail'
      },
      'a-bad-cidr6' => {
        'mailfrom' => 'foo@e7.example.com',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'result' => 'permerror',
        'spec' => '5.3/2',
        'description' => 'A                = "a"      [ ":" domain-spec ] [ dual-cidr-length ]
dual-cidr-length = [ ip4-cidr-length ] [ "/" ip6-cidr-length ]
'
      },
      'a-multi-ip1' => {
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'mailfrom' => 'foo@e10.example.com',
        'result' => 'pass',
        'description' => 'A matches any returned IP.',
        'spec' => '5.3/3'
      },
      'a-dual-cidr-ip4-err' => {
        'spec' => '5.3/2',
        'description' => 'A                = "a"      [ ":" domain-spec ] [ dual-cidr-length ]
dual-cidr-length = [ ip4-cidr-length ] [ "/" ip6-cidr-length ]
',
        'result' => 'permerror',
        'mailfrom' => 'foo@e8e.example.com',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4'
      },
      'a-cidr6-0-ip4' => {
        'description' => 'Would match if any AAAA records are present in DNS, but not for an IP4 connection.',
        'spec' => '5.3/3',
        'mailfrom' => 'foo@e2a.example.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'result' => 'fail'
      },
      'a-empty-domain' => {
        'mailfrom' => 'foo@e13.example.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'result' => 'permerror',
        'spec' => '5.3/2',
        'description' => 'domain-spec cannot be empty.'
      },
      'a-colon-domain-ip4mapped' => {
        'spec' => '7.1/2',
        'description' => 'domain-spec may contain any visible char except %',
        'helo' => 'mail.example.com',
        'host' => '::FFFF:1.2.3.4',
        'mailfrom' => 'foo@e11.example.com',
        'result' => 'pass'
      },
      'a-bad-toplabel' => {
        'spec' => '7.1/2',
        'description' => 'toplabel may not begin with a dash',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'mailfrom' => 'foo@e12.example.com',
        'result' => 'permerror'
      },
      'a-cidr6-0-nxdomain' => {
        'description' => 'No match if no AAAA records are present in DNS.',
        'spec' => '5.3/3',
        'result' => 'fail',
        'helo' => 'mail.example.com',
        'host' => '1234::1',
        'mailfrom' => 'foo@e2b.example.com'
      },
      'a-colon-domain' => {
        'mailfrom' => 'foo@e11.example.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'result' => 'pass',
        'spec' => '7.1/2',
        'description' => 'domain-spec may contain any visible char except %'
      },
      'a-numeric' => {
        'description' => 'toplabel may not be all numeric',
        'spec' => '7.1/2',
        'result' => 'permerror',
        'mailfrom' => 'foo@e4.example.com',
        'comment' => 'A common publishing mistake is using ip4 addresses with A mechanism. This should receive special diagnostic attention in the permerror.',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4'
      },
      'a-dual-cidr-ip6-match' => {
        'result' => 'pass',
        'mailfrom' => 'foo@e8.example.com',
        'helo' => 'mail.example.com',
        'host' => '2001:db8:1234::cafe:babe',
        'description' => 'A                = "a"      [ ":" domain-spec ] [ dual-cidr-length ]
dual-cidr-length = [ ip4-cidr-length ] [ "/" ip6-cidr-length ]
',
        'spec' => '5.3/2'
      },
      'a-dual-cidr-ip4-default' => {
        'spec' => '5.3/2',
        'description' => 'A                = "a"      [ ":" domain-spec ] [ dual-cidr-length ]
dual-cidr-length = [ ip4-cidr-length ] [ "/" ip6-cidr-length ]
',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'mailfrom' => 'foo@e8b.example.com',
        'result' => 'fail'
      },
      'a-cidr4-0' => {
        'spec' => '5.3/3',
        'description' => 'Matches if any A records are present in DNS.',
        'mailfrom' => 'foo@e2.example.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'result' => 'pass'
      },
      'a-dual-cidr-ip4-match' => {
        'result' => 'pass',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'mailfrom' => 'foo@e8.example.com',
        'description' => 'A                = "a"      [ ":" domain-spec ] [ dual-cidr-length ]
dual-cidr-length = [ ip4-cidr-length ] [ "/" ip6-cidr-length ]
',
        'spec' => '5.3/2'
      }
    },
    'description' => 'A mechanism syntax'
  },
  {
    'tests' => {
      'include-softfail' => {
        'description' => 'recursive check_host() result of softfail causes include to not match.',
        'spec' => '5.2/9',
        'result' => 'pass',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'mailfrom' => 'foo@e2.example.com'
      },
      'include-empty-domain' => {
        'result' => 'permerror',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'mailfrom' => 'foo@e8.example.com',
        'spec' => '5.2/1',
        'description' => 'domain-spec cannot be empty.'
      },
      'include-cidr' => {
        'description' => 'include          = "include"  ":" domain-spec',
        'spec' => '5.2/1',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'mailfrom' => 'foo@e9.example.com',
        'result' => 'permerror'
      },
      'include-fail' => {
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'mailfrom' => 'foo@e1.example.com',
        'result' => 'softfail',
        'spec' => '5.2/9',
        'description' => 'recursive check_host() result of fail causes include to not match.'
      },
      'include-permerror' => {
        'mailfrom' => 'foo@e5.example.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'result' => 'permerror',
        'description' => 'recursive check_host() result of permerror causes include to permerror',
        'spec' => '5.2/9'
      },
      'include-syntax-error' => {
        'mailfrom' => 'foo@e6.example.com',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'result' => 'permerror',
        'spec' => '5.2/1',
        'description' => 'include          = "include"  ":" domain-spec'
      },
      'include-neutral' => {
        'result' => 'fail',
        'mailfrom' => 'foo@e3.example.com',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'description' => 'recursive check_host() result of neutral causes include to not match.',
        'spec' => '5.2/9'
      },
      'include-none' => {
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'mailfrom' => 'foo@e7.example.com',
        'result' => 'permerror',
        'spec' => '5.2/9',
        'description' => 'recursive check_host() result of none causes include to permerror'
      },
      'include-temperror' => {
        'result' => 'temperror',
        'mailfrom' => 'foo@e4.example.com',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'description' => 'recursive check_host() result of temperror causes include to temperror',
        'spec' => '5.2/9'
      }
    },
    'zonedata' => {
      'erehwon.example.com' => [
        {
          'TXT' => 'v=spfl am not an SPF record'
        }
      ],
      'e9.example.com' => [
        {
          'SPF' => 'v=spf1 include:ip5.example.com/24 -all'
        }
      ],
      'e5.example.com' => [
        {
          'SPF' => 'v=spf1 include:e6.example.com -all'
        }
      ],
      'e8.example.com' => [
        {
          'SPF' => 'v=spf1 include: -all'
        }
      ],
      'ip5.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.2.3.5 -all'
        }
      ],
      'ip8.example.com' => [
        'TIMEOUT'
      ],
      'e7.example.com' => [
        {
          'SPF' => 'v=spf1 include:erehwon.example.com -all'
        }
      ],
      'e6.example.com' => [
        {
          'SPF' => 'v=spf1 include +all'
        }
      ],
      'e4.example.com' => [
        {
          'SPF' => 'v=spf1 include:ip8.example.com -all'
        }
      ],
      'ip7.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.2.3.7 ?all'
        }
      ],
      'e1.example.com' => [
        {
          'SPF' => 'v=spf1 include:ip5.example.com ~all'
        }
      ],
      'ip6.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.2.3.6 ~all'
        }
      ],
      'e2.example.com' => [
        {
          'SPF' => 'v=spf1 include:ip6.example.com all'
        }
      ],
      'mail.example.com' => [
        {
          'A' => '1.2.3.4'
        }
      ],
      'e3.example.com' => [
        {
          'SPF' => 'v=spf1 include:ip7.example.com -all'
        }
      ]
    },
    'description' => 'Include mechanism semantics and syntax'
  },
  {
    'description' => 'MX mechanism syntax',
    'zonedata' => {
      'e13.example.com' => [
        {
          'SPF' => 'v=spf1 mx: -all'
        }
      ],
      'e5.example.com' => [
        {
          'SPF' => 'v=spf1 mx:abc.123'
        }
      ],
      'e1.example.com' => [
        {
          'SPF' => 'v=spf1 mx/0 -all'
        },
        {
          'MX' => [
            '0',
            'e1.example.com'
          ]
        }
      ],
      'foo1.example.com' => [
        {
          'A' => '1.1.1.1'
        },
        {
          'A' => '1.2.3.5'
        }
      ],
      'e6.example.com' => [
        {
          'SPF' => 'v=spf1 mx//33 -all'
        }
      ],
      'foo.example.com' => [
        {
          'MX' => [
            '0',
            'foo1.example.com'
          ]
        }
      ],
      'e12.example.com' => [
        {
          'SPF' => 'v=spf1 mx:example.-com'
        }
      ],
      'e3.example.com' => [
        {
          'SPF' => 'v=spf1 mx:foo.example.com '
        }
      ],
      'mail.example.com' => [
        {
          'A' => '1.2.3.4'
        },
        {
          'MX' => [
            '0',
            ''
          ]
        },
        {
          'SPF' => 'v=spf1 mx'
        }
      ],
      'e2b.example.com' => [
        {
          'A' => '1.1.1.1'
        },
        {
          'MX' => [
            '0',
            'e2b.example.com'
          ]
        },
        {
          'SPF' => 'v=spf1 mx//0 -all'
        }
      ],
      'foo:bar/baz.example.com' => [
        {
          'MX' => [
            '0',
            'foo:bar/baz.example.com'
          ]
        },
        {
          'A' => '1.2.3.4'
        }
      ],
      'e9.example.com' => [
        {
          'SPF' => 'v=spf1 mx:example.com:8080'
        }
      ],
      'e11.example.com' => [
        {
          'SPF' => 'v=spf1 mx:foo:bar/baz.example.com'
        }
      ],
      'e4.example.com' => [
        {
          'SPF' => 'v=spf1 mx'
        },
        {
          'A' => '1.2.3.4'
        }
      ],
      'e7.example.com' => [
        {
          'SPF' => 'v=spf1 mx//129 -all'
        }
      ],
      'e6a.example.com' => [
        {
          'SPF' => 'v=spf1 mx/33 -all'
        }
      ],
      'e10.example.com' => [
        {
          'SPF' => 'v=spf1 mx:foo.example.com/24'
        }
      ],
      'e2.example.com' => [
        {
          'A' => '1.1.1.1'
        },
        {
          'AAAA' => '1234::2'
        },
        {
          'MX' => [
            '0',
            'e2.example.com'
          ]
        },
        {
          'SPF' => 'v=spf1 mx/0 -all'
        }
      ],
      'e2a.example.com' => [
        {
          'AAAA' => '1234::1'
        },
        {
          'MX' => [
            '0',
            'e2a.example.com'
          ]
        },
        {
          'SPF' => 'v=spf1 mx//0 -all'
        }
      ]
    },
    'tests' => {
      'mx-cidr4-0-ip6' => {
        'spec' => '5.4/3',
        'description' => 'Matches if any A records for any MX records are present in DNS.',
        'mailfrom' => 'foo@e2.example.com',
        'host' => '1234::1',
        'helo' => 'mail.example.com',
        'result' => 'fail'
      },
      'mx-bad-cidr6' => {
        'description' => 'MX                = "mx"      [ ":" domain-spec ] [ dual-cidr-length ]
dual-cidr-length = [ ip4-cidr-length ] [ "/" ip6-cidr-length ]
',
        'spec' => '5.4/2',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'mailfrom' => 'foo@e7.example.com',
        'result' => 'permerror'
      },
      'mx-bad-cidr4' => {
        'result' => 'permerror',
        'mailfrom' => 'foo@e6a.example.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'description' => 'MX                = "mx"      [ ":" domain-spec ] [ dual-cidr-length ]
dual-cidr-length = [ ip4-cidr-length ] [ "/" ip6-cidr-length ]
',
        'spec' => '5.4/2'
      },
      'mx-cidr6-0-ip4mapped' => {
        'description' => 'Would match if any AAAA records for MX records are present in DNS, but not for an IP4 connection.',
        'spec' => '5.4/3',
        'result' => 'fail',
        'mailfrom' => 'foo@e2a.example.com',
        'helo' => 'mail.example.com',
        'host' => '::FFFF:1.2.3.4'
      },
      'mx-implicit' => {
        'description' => 'If the target name has no MX records, check_host() MUST NOT pretend the target is its single MX, and MUST NOT default to an A lookup on the target-name directly.',
        'spec' => '5.4/4',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'mailfrom' => 'foo@e4.example.com',
        'result' => 'neutral'
      },
      'mx-colon-domain-ip4mapped' => {
        'mailfrom' => 'foo@e11.example.com',
        'host' => '::FFFF:1.2.3.4',
        'helo' => 'mail.example.com',
        'result' => 'pass',
        'spec' => '7.1/2',
        'description' => 'Domain-spec may contain any visible char except %'
      },
      'mx-numeric-top-label' => {
        'mailfrom' => 'foo@e5.example.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'result' => 'permerror',
        'spec' => '7.1/2',
        'description' => 'Top-label may not be all numeric'
      },
      'mx-cidr6-0-ip4' => {
        'spec' => '5.4/3',
        'description' => 'Would match if any AAAA records for MX records are present in DNS, but not for an IP4 connection.',
        'result' => 'fail',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'mailfrom' => 'foo@e2a.example.com'
      },
      'mx-empty' => {
        'spec' => '5.4/3',
        'description' => 'test null MX',
        'comment' => 'Some implementations have had trouble with null MX',
        'mailfrom' => '',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'result' => 'neutral'
      },
      'mx-colon-domain' => {
        'result' => 'pass',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'mailfrom' => 'foo@e11.example.com',
        'spec' => '7.1/2',
        'description' => 'Domain-spec may contain any visible char except %'
      },
      'mx-empty-domain' => {
        'spec' => '5.2/1',
        'description' => 'domain-spec cannot be empty.',
        'result' => 'permerror',
        'mailfrom' => 'foo@e13.example.com',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4'
      },
      'mx-null' => {
        'helo' => 'mail.example.com',
        'host' => '1.2.3.5',
        'mailfrom' => 'foo@e3.example.com',
        'result' => 'permerror',
        'spec' => '7.1/2',
        'description' => 'Null not allowed in top-label.'
      },
      'mx-cidr4-0' => {
        'spec' => '5.4/3',
        'description' => 'Matches if any A records for any MX records are present in DNS.',
        'result' => 'pass',
        'mailfrom' => 'foo@e2.example.com',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4'
      },
      'mx-cidr6' => {
        'spec' => '5.4/2',
        'description' => 'MX                = "mx"      [ ":" domain-spec ] [ dual-cidr-length ]
dual-cidr-length = [ ip4-cidr-length ] [ "/" ip6-cidr-length ]
',
        'result' => 'fail',
        'mailfrom' => 'foo@e6.example.com',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4'
      },
      'mx-cidr6-0-nxdomain' => {
        'description' => 'No match if no AAAA records for any MX records are present in DNS.',
        'spec' => '5.4/3',
        'mailfrom' => 'foo@e2b.example.com',
        'host' => '1234::1',
        'helo' => 'mail.example.com',
        'result' => 'fail'
      },
      'mx-multi-ip1' => {
        'spec' => '5.4/3',
        'description' => 'MX matches any returned IP.',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'mailfrom' => 'foo@e10.example.com',
        'result' => 'pass'
      },
      'mx-cidr6-0-ip6' => {
        'spec' => '5.3/3',
        'description' => 'Matches if any AAAA records for any MX records are present in DNS.',
        'host' => '1234::1',
        'helo' => 'mail.example.com',
        'mailfrom' => 'foo@e2a.example.com',
        'result' => 'pass'
      },
      'mx-bad-domain' => {
        'spec' => '7.1/2',
        'description' => 'domain-spec must pass basic syntax checks',
        'result' => 'permerror',
        'mailfrom' => 'foo@e9.example.com',
        'comment' => 'A \':\' may appear in domain-spec, but not in top-label.',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4'
      },
      'mx-multi-ip2' => {
        'description' => 'MX matches any returned IP.',
        'spec' => '5.4/3',
        'result' => 'pass',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'mailfrom' => 'foo@e10.example.com'
      },
      'mx-nxdomain' => {
        'spec' => '5.4/3',
        'description' => 'If no ips are returned, MX mechanism does not match, even with /0.',
        'mailfrom' => 'foo@e1.example.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'result' => 'fail'
      },
      'mx-bad-toplab' => {
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'mailfrom' => 'foo@e12.example.com',
        'spec' => '7.1/2',
        'description' => 'Toplabel may not begin with -'
      }
    }
  },
  {
    'zonedata' => {
      'e3.example.com' => [
        {
          'SPF' => 'v=spf1 exists:mail.example.com/24'
        }
      ],
      'mail.example.com' => [
        {
          'A' => '1.2.3.4'
        }
      ],
      'err.example.com' => [
        'TIMEOUT'
      ],
      'e2.example.com' => [
        {
          'SPF' => 'v=spf1 exists'
        }
      ],
      'e4.example.com' => [
        {
          'SPF' => 'v=spf1 exists:mail.example.com'
        }
      ],
      'e6.example.com' => [
        {
          'SPF' => 'v=spf1 exists:err.example.com -all'
        }
      ],
      'e1.example.com' => [
        {
          'SPF' => 'v=spf1 exists:'
        }
      ],
      'mail6.example.com' => [
        {
          'AAAA' => 'CAFE:BABE::4'
        }
      ],
      'e5.example.com' => [
        {
          'SPF' => 'v=spf1 exists:mail6.example.com -all'
        }
      ]
    },
    'tests' => {
      'exists-ip6only' => {
        'mailfrom' => 'foo@e5.example.com',
        'host' => 'CAFE:BABE::3',
        'helo' => 'mail.example.com',
        'result' => 'fail',
        'spec' => '5.7/3',
        'description' => 'The lookup type is A even when the connection is ip6'
      },
      'exists-cidr' => {
        'spec' => '5.7/2',
        'description' => 'exists           = "exists"   ":" domain-spec',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'mailfrom' => 'foo@e3.example.com',
        'result' => 'permerror'
      },
      'exists-ip4' => {
        'spec' => '5.7/3',
        'description' => 'mechanism matches if any DNS A RR exists',
        'result' => 'pass',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'mailfrom' => 'foo@e4.example.com'
      },
      'exists-ip6' => {
        'mailfrom' => 'foo@e4.example.com',
        'host' => 'CAFE:BABE::3',
        'helo' => 'mail.example.com',
        'result' => 'pass',
        'description' => 'The lookup type is A even when the connection is ip6',
        'spec' => '5.7/3'
      },
      'exists-dnserr' => {
        'helo' => 'mail.example.com',
        'host' => 'CAFE:BABE::3',
        'mailfrom' => 'foo@e6.example.com',
        'result' => 'temperror',
        'spec' => '5/8',
        'description' => 'Result for DNS error clarified in RFC7208: MTAs or other processors  SHOULD impose a limit on the maximum amount of elapsed time to evaluate  check_host().  Such a limit SHOULD allow at least 20 seconds.  If such  a limit is exceeded, the result of authorization SHOULD be "temperror".'
      },
      'exists-implicit' => {
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'mailfrom' => 'foo@e2.example.com',
        'description' => 'exists           = "exists"   ":" domain-spec',
        'spec' => '5.7/2'
      },
      'exists-empty-domain' => {
        'spec' => '5.7/2',
        'description' => 'domain-spec cannot be empty.',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'mailfrom' => 'foo@e1.example.com',
        'result' => 'permerror'
      }
    },
    'description' => 'EXISTS mechanism syntax'
  },
  {
    'description' => 'IP4 mechanism syntax',
    'zonedata' => {
      'e3.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.2.3.4/33 -all'
        }
      ],
      'mail.example.com' => [
        {
          'A' => '1.2.3.4'
        }
      ],
      'e2.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.2.3.4/32 -all'
        }
      ],
      'e4.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.2.3.4/032 -all'
        }
      ],
      'e7.example.com' => [
        {
          'SPF' => 'v=spf1 -ip4:1.2.3.4 ip6:::FFFF:1.2.3.4'
        }
      ],
      'e6.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.2.3.4//32'
        }
      ],
      'e1.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.1.1.1/0 -all'
        }
      ],
      'e9.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.2.3'
        }
      ],
      'e5.example.com' => [
        {
          'SPF' => 'v=spf1 ip4'
        }
      ],
      'e8.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.2.3.4:8080'
        }
      ]
    },
    'tests' => {
      'cidr4-33' => {
        'description' => 'Invalid CIDR should get permerror.',
        'spec' => '5.6/2',
        'mailfrom' => 'foo@e3.example.com',
        'comment' => 'The RFC4408 was silent on ip4 CIDR > 32 or ip6 CIDR > 128, but RFC7208  is explicit.  Invalid CIDR is prohibited.',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'result' => 'permerror'
      },
      'bad-ip4-short' => {
        'description' => 'It is not permitted to omit parts of the IP address instead of using CIDR notations.',
        'spec' => '5.6/4',
        'mailfrom' => 'foo@e9.example.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'result' => 'permerror'
      },
      'ip4-mapped-ip6' => {
        'mailfrom' => 'foo@e7.example.com',
        'host' => '::FFFF:1.2.3.4',
        'helo' => 'mail.example.com',
        'result' => 'fail',
        'spec' => '5/9/2',
        'description' => 'IP4 mapped IP6 connections MUST be treated as IP4'
      },
      'cidr4-0' => {
        'result' => 'pass',
        'mailfrom' => 'foo@e1.example.com',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'description' => 'ip4-cidr-length  = "/" 1*DIGIT',
        'spec' => '5.6/2'
      },
      'bare-ip4' => {
        'spec' => '5.6/2',
        'description' => 'IP4              = "ip4"      ":" ip4-network   [ ip4-cidr-length ]',
        'mailfrom' => 'foo@e5.example.com',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'result' => 'permerror'
      },
      'ip4-dual-cidr' => {
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'mailfrom' => 'foo@e6.example.com',
        'result' => 'permerror',
        'spec' => '5.6/2',
        'description' => 'dual-cidr-length not permitted on ip4'
      },
      'cidr4-32' => {
        'description' => 'ip4-cidr-length  = "/" 1*DIGIT',
        'spec' => '5.6/2',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'mailfrom' => 'foo@e2.example.com',
        'result' => 'pass'
      },
      'bad-ip4-port' => {
        'comment' => 'This has actually been published in SPF records.',
        'mailfrom' => 'foo@e8.example.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'result' => 'permerror',
        'description' => 'IP4              = "ip4"      ":" ip4-network   [ ip4-cidr-length ]',
        'spec' => '5.6/2'
      },
      'cidr4-032' => {
        'result' => 'permerror',
        'mailfrom' => 'foo@e4.example.com',
        'comment' => 'Leading zeros are not explicitly prohibited by the RFC. However, since the RFC explicity prohibits leading zeros in ip4-network, our interpretation is that CIDR should be also.',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'description' => 'Invalid CIDR should get permerror.',
        'spec' => '5.6/2'
      }
    }
  },
  {
    'description' => 'IP6 mechanism syntax',
    'zonedata' => {
      'e3.example.com' => [
        {
          'SPF' => 'v=spf1 ip6:::1.1.1.1/129'
        }
      ],
      'mail.example.com' => [
        {
          'A' => '1.2.3.4'
        }
      ],
      'e1.example.com' => [
        {
          'SPF' => 'v=spf1 -all ip6'
        }
      ],
      'e4.example.com' => [
        {
          'SPF' => 'v=spf1 ip6:::1.1.1.1//33'
        }
      ],
      'e6.example.com' => [
        {
          'SPF' => 'v=spf1 ip6::CAFE::BABE'
        }
      ],
      'e2.example.com' => [
        {
          'SPF' => 'v=spf1 ip6:::1.1.1.1/0'
        }
      ],
      'e5.example.com' => [
        {
          'SPF' => 'v=spf1 ip6:CAFE:BABE:8000::/33'
        }
      ]
    },
    'comment' => 'IP4 only implementations may skip tests where host is not IP4',
    'tests' => {
      'cidr6-0' => {
        'mailfrom' => 'foo@e2.example.com',
        'helo' => 'mail.example.com',
        'host' => 'DEAF:BABE::CAB:FEE',
        'result' => 'pass',
        'spec' => '5/8',
        'description' => 'Match any IP6'
      },
      'cidr6-129' => {
        'comment' => 'IP4 only implementations MUST fully syntax check all mechanisms, even if they otherwise ignore them.',
        'mailfrom' => 'foo@e3.example.com',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'result' => 'permerror',
        'description' => 'Invalid CIDR',
        'spec' => '5.6/2'
      },
      'cidr6-bad' => {
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'comment' => 'IP4 only implementations MUST fully syntax check all mechanisms, even if they otherwise ignore them.',
        'mailfrom' => 'foo@e4.example.com',
        'description' => 'dual-cidr syntax not used for ip6',
        'spec' => '5.6/2'
      },
      'cidr6-0-ip4' => {
        'description' => 'IP4 connections do not match ip6.',
        'spec' => '5/9/2',
        'result' => 'neutral',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'comment' => 'There was controversy over IPv4 mapped connections.  RFC7208 clearly states IPv4 mapped addresses only match ip4: mechanisms.',
        'mailfrom' => 'foo@e2.example.com'
      },
      'ip6-bad1' => {
        'description' => '',
        'spec' => '5.6/2',
        'result' => 'permerror',
        'mailfrom' => 'foo@e6.example.com',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4'
      },
      'cidr6-33' => {
        'result' => 'pass',
        'mailfrom' => 'foo@e5.example.com',
        'helo' => 'mail.example.com',
        'host' => 'CAFE:BABE:8000::',
        'spec' => '5.6/2',
        'description' => 'make sure ip4 cidr restriction are not used for ip6'
      },
      'cidr6-33-ip4' => {
        'spec' => '5.6/2',
        'description' => 'make sure ip4 cidr restriction are not used for ip6',
        'mailfrom' => 'foo@e5.example.com',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'result' => 'neutral'
      },
      'cidr6-ip4' => {
        'result' => 'neutral',
        'host' => '::FFFF:1.2.3.4',
        'helo' => 'mail.example.com',
        'mailfrom' => 'foo@e2.example.com',
        'comment' => 'There was controversy over ip4 mapped connections.  RFC7208 clearly requires such connections to be considered as ip4 only.',
        'spec' => '5/9/2',
        'description' => 'Even if the SMTP connection is via IPv6, an IPv4-mapped IPv6 IP address (see RFC 3513, Section 2.5.5) MUST still be considered an IPv4 address.'
      },
      'bare-ip6' => {
        'result' => 'permerror',
        'mailfrom' => 'foo@e1.example.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'description' => 'IP6              = "ip6"      ":" ip6-network   [ ip6-cidr-length ]',
        'spec' => '5.6/2'
      }
    }
  },
  {
    'description' => 'Semantics of exp and other modifiers',
    'zonedata' => {
      'twoexp.example.com' => [
        {
          'TXT' => 'one'
        },
        {
          'TXT' => 'two'
        }
      ],
      'e12.example.com' => [
        {
          'SPF' => 'v=spf1 exp= -all'
        }
      ],
      'badexp.example.com' => [
        {
          'TXT' => "\x{ef}\x{bb}\x{bf}Explanation"
        }
      ],
      'e18.example.com' => [
        {
          'SPF' => 'v=spf1 ?all redirect='
        }
      ],
      'e15.example.com' => [
        {
          'SPF' => 'v=spf1 redirect=e12.example.com -all redirect=e12.example.com'
        }
      ],
      'e14.example.com' => [
        {
          'SPF' => 'v=spf1 exp=e13msg.example.com -all exp=e11msg.example.com'
        }
      ],
      'e3.example.com' => [
        {
          'SPF' => 'v=spf1 exp=exp1.example.com redirect=e4.example.com'
        }
      ],
      'e22.example.com' => [
        {
          'SPF' => 'v=spf1 exp=mail.example.com -all'
        }
      ],
      'exp2.example.com' => [
        {
          'TXT' => 'See me.'
        }
      ],
      'exp4.example.com' => [
        {
          'TXT' => '%{l} in implementation'
        }
      ],
      'e20.example.com' => [
        {
          'SPF' => 'v=spf1 default=+'
        }
      ],
      'e6.example.com' => [
        {
          'SPF' => 'v=spf1 =all'
        }
      ],
      'e2.example.com' => [
        {
          'SPF' => 'v=spf1 -all'
        }
      ],
      'e13msg.example.com' => [
        {
          'TXT' => 'The %{x}-files.'
        }
      ],
      'e23.example.com' => [
        {
          'SPF' => 'v=spf1 a:erehwon.example.com a:foobar.com exp=nxdomain.com -all'
        }
      ],
      'e8.example.com' => [
        {
          'SPF' => 'v=spf1 -all exp=exp4.example.com'
        }
      ],
      'e21.example.com' => [
        {
          'SPF' => 'v=spf1 exp=e21msg.example.com -all'
        }
      ],
      'e9.example.com' => [
        {
          'SPF' => 'v=spf1 -all foo=%abc'
        }
      ],
      'e11.example.com' => [
        {
          'SPF' => 'v=spf1 -all exp=e11msg.example.com'
        }
      ],
      'e7.example.com' => [
        {
          'SPF' => 'v=spf1 include:e3.example.com -all exp=exp3.example.com'
        }
      ],
      'exp1.example.com' => [
        {
          'TXT' => 'No-see-um'
        }
      ],
      'mail.example.com' => [
        {
          'A' => '1.2.3.4'
        }
      ],
      'e11msg.example.com' => [
        {
          'TXT' => 'Answer a fool according to his folly.'
        },
        {
          'TXT' => 'Do not answer a fool according to his folly.'
        }
      ],
      'e17.example.com' => [
        {
          'SPF' => 'v=spf1 redirect=-all ?all'
        }
      ],
      'e13.example.com' => [
        {
          'SPF' => 'v=spf1 exp=e13msg.example.com -all'
        }
      ],
      'e21msg.example.com' => [
        'TIMEOUT'
      ],
      'nonascii.example.com' => [
        {
          'SPF' => 'v=spf1 exp=badexp.example.com -all'
        }
      ],
      'e5.example.com' => [
        {
          'SPF' => 'v=spf1 1up=foo'
        }
      ],
      'e1.example.com' => [
        {
          'SPF' => 'v=spf1 exp=exp1.example.com redirect=e2.example.com'
        }
      ],
      'tworecs.example.com' => [
        {
          'SPF' => 'v=spf1 exp=twoexp.example.com -all'
        }
      ],
      'e10.example.com' => [
        {
          'SPF' => 'v=spf1 redirect=erehwon.example.com'
        }
      ],
      'e16.example.com' => [
        {
          'SPF' => 'v=spf1 exp=-all'
        }
      ],
      'exp3.example.com' => [
        {
          'TXT' => 'Correct!'
        }
      ],
      'e19.example.com' => [
        {
          'SPF' => 'v=spf1 default=pass'
        }
      ],
      'e4.example.com' => [
        {
          'SPF' => 'v=spf1 -all exp=exp2.example.com'
        }
      ]
    },
    'tests' => {
      'two-exp-records' => {
        'spec' => '6.2/4',
        'description' => 'Must ignore exp= if DNS returns more than one TXT record.',
        'mailfrom' => 'foobar@tworecs.example.com',
        'explanation' => 'DEFAULT',
        'helo' => 'hosed',
        'host' => '1.2.3.4',
        'result' => 'fail'
      },
      'exp-empty-domain' => {
        'description' => 'PermError if exp= domain-spec is empty.
',
        'spec' => '6.2/4',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'comment' => 'Section 6.2/4 says, "If domain-spec is empty, or there are any DNS processing errors (any RCODE other than 0), or if no records are returned, or if more than one record is returned, or if there are syntax errors in the explanation string, then proceed as if no exp modifier was given."  However, "if domain-spec is empty" conflicts with the grammar given for the exp modifier.  This was reported as an erratum, and the solution chosen was to report explicit "exp=" as PermError, but ignore problems due to macro expansion, DNS, or invalid explanation string.',
        'mailfrom' => 'foo@e12.example.com',
        'result' => 'permerror'
      },
      'redirect-none' => {
        'description' => 'If no SPF record is found, or if the target-name is malformed, the result is a "PermError" rather than "None".',
        'spec' => '6.1/4',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'mailfrom' => 'foo@e10.example.com'
      },
      'empty-modifier-name' => {
        'description' => 'name             = ALPHA *( ALPHA / DIGIT / "-" / "_" / "." )
',
        'spec' => 'A/3',
        'result' => 'permerror',
        'comment' => 'Unknown modifier name must not be empty.',
        'mailfrom' => 'foo@e6.example.com',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4'
      },
      'exp-syntax-error' => {
        'result' => 'permerror',
        'comment' => 'A literal application of the grammar causes modifier syntax errors (except for macro syntax) to become unknown-modifier.

  modifier = explanation | redirect | unknown-modifier

However, it is generally agreed, with precedent in other RFCs, that unknown-modifier should not be "greedy", and should not match known modifier names.  There should have been explicit prose to this effect, and some has been proposed as an erratum.',
        'mailfrom' => 'foo@e16.example.com',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'description' => 'explanation      = "exp" "=" domain-spec
',
        'spec' => '6.2/1'
      },
      'dorky-sentinel' => {
        'spec' => '7.1/6',
        'result' => 'fail',
        'host' => '1.2.3.4',
        'explanation' => 'Macro Error in implementation',
        'mailfrom' => 'Macro Error@e8.example.com',
        'description' => 'An implementation that uses a legal expansion as a sentinel.  We cannot check them all, but we can check this one.',
        'helo' => 'mail.example.com',
        'comment' => 'Spaces are allowed in local-part.'
      },
      'default-modifier-obsolete2' => {
        'description' => 'Unknown modifiers do not modify the RFC SPF result.
',
        'spec' => '6/3',
        'mailfrom' => 'foo@e20.example.com',
        'comment' => 'Some implementations may have a leftover default= modifier from earlier drafts.',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'result' => 'neutral'
      },
      'exp-void' => {
        'spec' => '4.6.4/1, 6/2',
        'description' => 'exp=nxdomain.tld
',
        'result' => 'fail',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'comment' => 'Non-existent exp= domains MUST NOT count against the void lookup limit. Implementations should lookup any exp record at most once after computing the result.',
        'mailfrom' => 'foo@e23.example.com'
      },
      'invalid-modifier' => {
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'mailfrom' => 'foo@e5.example.com',
        'comment' => 'Unknown modifier name must begin with alpha.',
        'result' => 'permerror',
        'spec' => 'A/3',
        'description' => 'unknown-modifier = name "=" macro-string
name             = ALPHA *( ALPHA / DIGIT / "-" / "_" / "." )
'
      },
      'include-ignores-exp' => {
        'description' => 'when executing "include", exp= from the target domain MUST NOT be used.',
        'spec' => '6.2/13',
        'result' => 'fail',
        'explanation' => 'Correct!',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'mailfrom' => 'foo@e7.example.com'
      },
      'default-modifier-obsolete' => {
        'result' => 'neutral',
        'mailfrom' => 'foo@e19.example.com',
        'comment' => 'Some implementations may have a leftover default= modifier from earlier drafts.',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'description' => 'Unknown modifiers do not modify the RFC SPF result.
',
        'spec' => '6/3'
      },
      'non-ascii-exp' => {
        'comment' => 'Checking a possibly different code path for non-ascii chars.',
        'helo' => 'hosed',
        'description' => 'SPF explanation text is restricted to 7-bit ascii.',
        'mailfrom' => 'foobar@nonascii.example.com',
        'host' => '1.2.3.4',
        'explanation' => 'DEFAULT',
        'result' => 'fail',
        'spec' => '6.2/5'
      },
      'explanation-syntax-error' => {
        'result' => 'fail',
        'mailfrom' => 'foo@e13.example.com',
        'explanation' => 'DEFAULT',
        'host' => '1.2.3.4',
        'spec' => '6.2/4',
        'comment' => 'If domain-spec is empty, or there are any DNS processing errors (any RCODE other than 0), or if no records are returned, or if more than one record is returned, or if there are syntax errors in the explanation string, then proceed as if no exp modifier was given.',
        'helo' => 'mail.example.com',
        'description' => 'Ignore exp if the explanation string has a syntax error.
'
      },
      'redirect-cancels-exp' => {
        'result' => 'fail',
        'explanation' => 'DEFAULT',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'mailfrom' => 'foo@e1.example.com',
        'spec' => '6.2/13',
        'description' => 'when executing "redirect", exp= from the original domain MUST NOT be used.'
      },
      'redirect-cancels-prior-exp' => {
        'result' => 'fail',
        'mailfrom' => 'foo@e3.example.com',
        'explanation' => 'See me.',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'spec' => '6.2/13',
        'description' => 'when executing "redirect", exp= from the original domain MUST NOT be used.'
      },
      'redirect-empty-domain' => {
        'spec' => '6.2/4',
        'description' => 'redirect = "redirect" "=" domain-spec
',
        'comment' => 'Unlike for exp, there is no instruction to override the permerror for an empty domain-spec (which is invalid syntax).',
        'mailfrom' => 'foo@e18.example.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'result' => 'permerror'
      },
      'redirect-twice' => {
        'comment' => 'These two modifiers (exp,redirect) MUST NOT appear in a record more than once each. If they do, then check_host() exits with a result of "PermError".',
        'mailfrom' => 'foo@e15.example.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'result' => 'permerror',
        'spec' => '6/2',
        'description' => 'redirect= appears twice.
'
      },
      'exp-dns-error' => {
        'host' => '1.2.3.4',
        'explanation' => 'DEFAULT',
        'mailfrom' => 'foo@e21.example.com',
        'result' => 'fail',
        'spec' => '6.2/4',
        'helo' => 'mail.example.com',
        'comment' => 'If domain-spec is empty, or there are any DNS processing errors (any RCODE other than 0), or if no records are returned, or if more than one record is returned, or if there are syntax errors in the explanation string, then proceed as if no exp modifier was given.',
        'description' => 'Ignore exp if DNS error.
'
      },
      'unknown-modifier-syntax' => {
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'comment' => 'Unknown modifiers must have valid macro syntax.',
        'mailfrom' => 'foo@e9.example.com',
        'result' => 'permerror',
        'description' => 'unknown-modifier = name "=" macro-string
',
        'spec' => 'A/3'
      },
      'exp-multiple-txt' => {
        'helo' => 'mail.example.com',
        'comment' => 'If domain-spec is empty, or there are any DNS processing errors (any RCODE other than 0), or if no records are returned, or if more than one record is returned, or if there are syntax errors in the explanation string, then proceed as if no exp modifier was given.',
        'description' => 'Ignore exp if multiple TXT records.
',
        'explanation' => 'DEFAULT',
        'host' => '1.2.3.4',
        'mailfrom' => 'foo@e11.example.com',
        'result' => 'fail',
        'spec' => '6.2/4'
      },
      'exp-twice' => {
        'description' => 'exp= appears twice.
',
        'spec' => '6/2',
        'comment' => 'These two modifiers (exp,redirect) MUST NOT appear in a record more than once each. If they do, then check_host() exits with a result of "PermError".',
        'mailfrom' => 'foo@e14.example.com',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'result' => 'permerror'
      },
      'exp-no-txt' => {
        'spec' => '6.2/4',
        'mailfrom' => 'foo@e22.example.com',
        'host' => '1.2.3.4',
        'explanation' => 'DEFAULT',
        'result' => 'fail',
        'description' => 'Ignore exp if no TXT records.
',
        'comment' => 'If domain-spec is empty, or there are any DNS processing errors (any RCODE other than 0), or if no records are returned, or if more than one record is returned, or if there are syntax errors in the explanation string, then proceed as if no exp modifier was given.',
        'helo' => 'mail.example.com'
      },
      'redirect-syntax-error' => {
        'description' => 'redirect      = "redirect" "=" domain-spec
',
        'spec' => '6.1/2',
        'result' => 'permerror',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'comment' => 'A literal application of the grammar causes modifier syntax errors (except for macro syntax) to become unknown-modifier.

  modifier = explanation | redirect | unknown-modifier

However, it is generally agreed, with precedent in other RFCs, that unknown-modifier should not be "greedy", and should not match known modifier names.  There should have been explicit prose to this effect, and some has been proposed as an erratum.',
        'mailfrom' => 'foo@e17.example.com'
      }
    },
    'comment' => 'Implementing exp= is optional.  If not implemented, the test driver should not check the explanation field.'
  },
  {
    'description' => 'Macro expansion rules',
    'tests' => {
      'macro-mania-in-domain' => {
        'spec' => '7.1/3, 7.1/4',
        'description' => 'macro-encoded percents (%%), spaces (%_), and URL-percent-encoded spaces (%-)',
        'result' => 'pass',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'mailfrom' => 'test@e1a.example.com'
      },
      'hello-macro' => {
        'result' => 'pass',
        'mailfrom' => 'test@e9.example.com',
        'helo' => 'msgbas2x.cos.example.com',
        'host' => '192.168.218.40',
        'description' => 'h = HELO/EHLO domain',
        'spec' => '7.1/6'
      },
      'require-valid-helo' => {
        'mailfrom' => 'test@e10.example.com',
        'host' => '1.2.3.4',
        'helo' => 'OEMCOMPUTER',
        'result' => 'fail',
        'description' => 'Example of requiring valid helo in sender policy.  This is a complex policy testing several points at once.',
        'spec' => '7.1/6'
      },
      'p-macro-ip4-valid' => {
        'explanation' => 'connect from mx.example.com',
        'host' => '192.168.218.41',
        'mailfrom' => 'test@e6.example.com',
        'result' => 'fail',
        'spec' => '7.1/22',
        'helo' => 'msgbas2x.cos.example.com',
        'comment' => 'If a subdomain of the <domain> is present, it SHOULD be used.',
        'description' => 'p = the validated domain name of <ip>'
      },
      'macro-multiple-delimiters' => {
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'mailfrom' => 'foo-bar+zip+quux@e12.example.com',
        'result' => 'pass',
        'spec' => '7.1/15, 7.1/16',
        'description' => 'Multiple delimiters may be specified in a macro expression.
  macro-expand = ( "%{" macro-letter transformers *delimiter "}" )
                 / "%%" / "%_" / "%-"'
      },
      'macro-reverse-split-on-dash' => {
        'result' => 'pass',
        'mailfrom' => 'philip-gladstone-test@e11.example.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'spec' => '7.1/15, 7.1/16, 7.1/17, 7.1/18',
        'description' => 'Macro value transformation (splitting on arbitrary characters, reversal, number of right-hand parts to use)'
      },
      'hello-domain-literal' => {
        'helo' => '[192.168.218.40]',
        'host' => '192.168.218.40',
        'comment' => 'Domain-spec must end in either a macro, or a valid toplabel. It is not correct to check syntax after macro expansion.',
        'mailfrom' => 'test@e9.example.com',
        'result' => 'fail',
        'description' => 'h = HELO/EHLO domain, but HELO is a domain literal',
        'spec' => '7.1/2'
      },
      'p-macro-ip6-valid' => {
        'description' => 'p = the validated domain name of <ip>',
        'helo' => 'msgbas2x.cos.example.com',
        'comment' => 'If a subdomain of the <domain> is present, it SHOULD be used.',
        'spec' => '7.1/22',
        'host' => 'CAFE:BABE::3',
        'explanation' => 'connect from mx.example.com',
        'mailfrom' => 'test@e6.example.com',
        'result' => 'fail'
      },
      'p-macro-multiple' => {
        'description' => 'p = the validated domain name of <ip>',
        'spec' => '7.1/22',
        'host' => '192.168.218.42',
        'helo' => 'msgbas2x.cos.example.com',
        'mailfrom' => 'test@e7.example.com',
        'comment' => 'If a subdomain of the <domain> is present, it SHOULD be used.',
        'result' => [
          'pass',
          'softfail'
        ]
      },
      'p-macro-ip4-novalid' => {
        'spec' => '7.1/22',
        'result' => 'fail',
        'mailfrom' => 'test@e6.example.com',
        'explanation' => 'connect from unknown',
        'host' => '192.168.218.40',
        'description' => 'p = the validated domain name of <ip>',
        'comment' => 'The PTR in this example does not validate.',
        'helo' => 'msgbas2x.cos.example.com'
      },
      'undef-macro' => {
        'description' => 'Allowed macros chars are \'slodipvh\' plus \'crt\' in explanation.',
        'spec' => '7.1/6',
        'mailfrom' => 'test@e5.example.com',
        'helo' => 'msgbas2x.cos.example.com',
        'host' => 'CAFE:BABE::192.168.218.40',
        'result' => 'permerror'
      },
      'trailing-dot-exp' => {
        'description' => 'trailing dot is not removed from explanation',
        'comment' => 'A simple way for an implementation to ignore trailing dots on domains is to remove it when present.  But be careful not to remove it for explanation text.',
        'helo' => 'msgbas2x.cos.example.com',
        'spec' => '7.1',
        'result' => 'fail',
        'mailfrom' => 'test@exp.example.com',
        'host' => '192.168.218.40',
        'explanation' => 'This is a test.'
      },
      'v-macro-ip4' => {
        'mailfrom' => 'test@e4.example.com',
        'host' => '192.168.218.40',
        'explanation' => '192.168.218.40 is queried as 40.218.168.192.in-addr.arpa',
        'helo' => 'msgbas2x.cos.example.com',
        'result' => 'fail',
        'description' => 'v = the string "in-addr" if <ip> is ipv4, or "ip6" if <ip> is ipv6',
        'spec' => '7.1/6'
      },
      'domain-name-truncation' => {
        'result' => 'fail',
        'host' => '192.168.218.40',
        'explanation' => 'Congratulations!  That was tricky.',
        'helo' => 'msgbas2x.cos.example.com',
        'mailfrom' => 'test@somewhat.long.exp.example.com',
        'spec' => '7.1/25',
        'description' => 'When the result of macro expansion is used in a domain name query, if the expanded domain name exceeds 253 characters, the left side is truncated to fit, by removing successive domain labels until the total length does not exceed 253 characters.'
      },
      'v-macro-ip6' => {
        'spec' => '7.1/6',
        'description' => 'v = the string "in-addr" if <ip> is ipv4, or "ip6" if <ip> is ipv6',
        'result' => 'fail',
        'explanation' => 'cafe:babe::1 is queried as 1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.E.B.A.B.E.F.A.C.ip6.arpa',
        'helo' => 'msgbas2x.cos.example.com',
        'host' => 'CAFE:BABE::1',
        'mailfrom' => 'test@e4.example.com'
      },
      'invalid-hello-macro' => {
        'description' => 'h = HELO/EHLO domain, but HELO is invalid',
        'spec' => '7.1/2',
        'helo' => 'JUMPIN\' JUPITER',
        'host' => '192.168.218.40',
        'mailfrom' => 'test@e9.example.com',
        'comment' => 'Domain-spec must end in either a macro, or a valid toplabel. It is not correct to check syntax after macro expansion.',
        'result' => 'fail'
      },
      'p-macro-ip6-novalid' => {
        'description' => 'p = the validated domain name of <ip>',
        'comment' => 'The PTR in this example does not validate.',
        'helo' => 'msgbas2x.cos.example.com',
        'spec' => '7.1/22',
        'mailfrom' => 'test@e6.example.com',
        'host' => 'CAFE:BABE::1',
        'explanation' => 'connect from unknown',
        'result' => 'fail'
      },
      'exp-only-macro-char' => {
        'spec' => '7.1/8',
        'description' => 'The following macro letters are allowed only in "exp" text: c, r, t',
        'result' => 'permerror',
        'mailfrom' => 'test@e2.example.com',
        'host' => '192.168.218.40',
        'helo' => 'msgbas2x.cos.example.com'
      },
      'invalid-macro-char' => {
        'description' => 'A \'%\' character not followed by a \'{\', \'%\', \'-\', or \'_\' character is a syntax error.',
        'spec' => '7.1/9',
        'mailfrom' => 'test@e1.example.com',
        'helo' => 'msgbas2x.cos.example.com',
        'host' => '192.168.218.40',
        'result' => 'permerror'
      },
      'invalid-embedded-macro-char' => {
        'spec' => '7.1/9',
        'description' => 'A \'%\' character not followed by a \'{\', \'%\', \'-\', or \'_\' character is a syntax error.',
        'result' => 'permerror',
        'host' => '192.168.218.40',
        'helo' => 'msgbas2x.cos.example.com',
        'mailfrom' => 'test@e1e.example.com'
      },
      'exp-txt-macro-char' => {
        'result' => 'fail',
        'mailfrom' => 'test@e3.example.com',
        'helo' => 'msgbas2x.cos.example.com',
        'explanation' => 'Connections from 192.168.218.40 not authorized.',
        'host' => '192.168.218.40',
        'spec' => '7.1/20',
        'description' => 'For IPv4 addresses, both the "i" and "c" macros expand to the standard dotted-quad format.'
      },
      'trailing-dot-domain' => {
        'result' => 'pass',
        'helo' => 'msgbas2x.cos.example.com',
        'host' => '192.168.218.40',
        'mailfrom' => 'test@example.com',
        'description' => 'trailing dot is ignored for domains',
        'spec' => '7.1/16'
      },
      'invalid-trailing-macro-char' => {
        'spec' => '7.1/9',
        'description' => 'A \'%\' character not followed by a \'{\', \'%\', \'-\', or \'_\' character is a syntax error.',
        'host' => '192.168.218.40',
        'helo' => 'msgbas2x.cos.example.com',
        'mailfrom' => 'test@e1t.example.com',
        'result' => 'permerror'
      },
      'upper-macro' => {
        'spec' => '7.1/26',
        'description' => 'Uppercased macros expand exactly as their lowercased equivalents, and are then URL escaped.',
        'result' => 'fail',
        'mailfrom' => 'jack&jill=up@e8.example.com',
        'explanation' => 'http://example.com/why.html?l=jack%26jill%3Dup',
        'host' => '192.168.218.42',
        'helo' => 'msgbas2x.cos.example.com'
      }
    },
    'zonedata' => {
      'example.com.d.spf.example.com' => [
        {
          'SPF' => 'v=spf1 redirect=a.spf.example.com'
        }
      ],
      'e9.example.com' => [
        {
          'SPF' => 'v=spf1 a:%{H} -all'
        }
      ],
      'e8.example.com' => [
        {
          'SPF' => 'v=spf1 -all exp=msg8.%{D2}'
        }
      ],
      '1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.E.B.A.B.E.F.A.C.ip6.arpa' => [
        {
          'PTR' => 'mx.example.com'
        }
      ],
      '_spfh.example.com' => [
        {
          'SPF' => 'v=spf1 -a:%{h} +all'
        }
      ],
      '40.218.168.192.example.com' => [
        {
          'TXT' => 'Connections from %{c} not authorized.'
        }
      ],
      'e7.example.com' => [
        {
          'SPF' => 'v=spf1 exists:%{p}.should.example.com ~exists:%{p}.ok.example.com'
        }
      ],
      'e11.example.com' => [
        {
          'SPF' => 'v=spf1 exists:%{i}.%{l2r-}.user.%{d2}'
        }
      ],
      '3.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.E.B.A.B.E.F.A.C.ip6.arpa' => [
        {
          'PTR' => 'mx.example.com'
        }
      ],
      'e4msg.example.com' => [
        {
          'TXT' => '%{c} is queried as %{ir}.%{v}.arpa'
        }
      ],
      'e2.example.com' => [
        {
          'SPF' => 'v=spf1 -all exp=%{r}.example.com'
        }
      ],
      '1.2.3.4.gladstone.philip.user.example.com' => [
        {
          'A' => '127.0.0.2'
        }
      ],
      'somewhat.long.exp.example.com' => [
        {
          'SPF' => 'v=spf1 -all exp=foobar.%{o}.%{o}.%{o}.%{o}.%{o}.%{o}.%{o}.%{o}.example.com'
        }
      ],
      'e1a.example.com' => [
        {
          'SPF' => 'v=spf1 a:macro%%percent%_%_space%-url-space.example.com -all'
        }
      ],
      'a.spf.example.com' => [
        {
          'SPF' => 'v=spf1 include:o.spf.example.com. ~all'
        }
      ],
      'msgbas2x.cos.example.com' => [
        {
          'A' => '192.168.218.40'
        }
      ],
      'mx.e7.example.com.should.example.com' => [
        {
          'A' => '127.0.0.2'
        }
      ],
      'e1e.example.com' => [
        {
          'SPF' => 'v=spf1 exists:foo%(ir).sbl.example.com ?all'
        }
      ],
      'somewhat.long.exp.example.com.somewhat.long.exp.example.com.somewhat.long.exp.example.com.somewhat.long.exp.example.com.somewhat.long.exp.example.com.somewhat.long.exp.example.com.somewhat.long.exp.example.com.somewhat.long.exp.example.com.example.com' => [
        {
          'TXT' => 'Congratulations!  That was tricky.'
        }
      ],
      'e6.example.com' => [
        {
          'SPF' => 'v=spf1 -all exp=e6msg.example.com'
        }
      ],
      '42.218.168.192.in-addr.arpa' => [
        {
          'PTR' => 'mx.example.com'
        },
        {
          'PTR' => 'mx.e7.example.com'
        }
      ],
      'e12.example.com' => [
        {
          'SPF' => 'v=spf1 exists:%{l2r+-}.user.%{d2}'
        }
      ],
      'e3.example.com' => [
        {
          'SPF' => 'v=spf1 -all exp=%{ir}.example.com'
        }
      ],
      'bar.foo.user.example.com' => [
        {
          'A' => '127.0.0.2'
        }
      ],
      'msg8.example.com' => [
        {
          'TXT' => 'http://example.com/why.html?l=%{L}'
        }
      ],
      'example.com' => [
        {
          'A' => '192.168.90.76'
        },
        {
          'SPF' => 'v=spf1 redirect=%{d}.d.spf.example.com.'
        }
      ],
      'o.spf.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:192.168.218.40'
        }
      ],
      'e1t.example.com' => [
        {
          'SPF' => 'v=spf1 exists:foo%.sbl.example.com ?all'
        }
      ],
      'e4.example.com' => [
        {
          'SPF' => 'v=spf1 -all exp=e4msg.example.com'
        }
      ],
      'macro%percent  space%20url-space.example.com' => [
        {
          'A' => '1.2.3.4'
        }
      ],
      'e10.example.com' => [
        {
          'SPF' => 'v=spf1 -include:_spfh.%{d2} ip4:1.2.3.0/24 -all'
        }
      ],
      '41.218.168.192.in-addr.arpa' => [
        {
          'PTR' => 'mx.example.com'
        }
      ],
      'exp.example.com' => [
        {
          'SPF' => 'v=spf1 exp=msg.example.com. -all'
        }
      ],
      'e5.example.com' => [
        {
          'SPF' => 'v=spf1 a:%{a}.example.com -all'
        }
      ],
      '40.218.168.192.in-addr.arpa' => [
        {
          'PTR' => 'mx.example.com'
        }
      ],
      'mx.example.com.ok.example.com' => [
        {
          'A' => '127.0.0.2'
        }
      ],
      'e6msg.example.com' => [
        {
          'TXT' => 'connect from %{p}'
        }
      ],
      'e1.example.com' => [
        {
          'SPF' => 'v=spf1 -exists:%(ir).sbl.example.com ?all'
        }
      ],
      'mx.example.com' => [
        {
          'A' => '192.168.218.41'
        },
        {
          'A' => '192.168.218.42'
        },
        {
          'AAAA' => 'CAFE:BABE::2'
        },
        {
          'AAAA' => 'CAFE:BABE::3'
        }
      ],
      'msg.example.com' => [
        {
          'TXT' => 'This is a test.'
        }
      ],
      'mx.e7.example.com' => [
        {
          'A' => '192.168.218.42'
        }
      ]
    }
  },
  {
    'description' => 'Processing limits',
    'zonedata' => {
      'e3.example.com' => [
        {
          'SPF' => 'v=spf1 include:e2.example.com'
        },
        {
          'A' => '1.2.3.8'
        }
      ],
      'mail.example.com' => [
        {
          'A' => '1.2.3.4'
        }
      ],
      'e12.example.com' => [
        {
          'TXT' => 'v=spf1 a:err.example.com a:err1.example.com ?all'
        }
      ],
      'e2.example.com' => [
        {
          'SPF' => 'v=spf1 include:e3.example.com'
        },
        {
          'A' => '1.2.3.7'
        }
      ],
      'e10.example.com' => [
        {
          'SPF' => 'v=spf1 a -all'
        },
        {
          'A' => '1.2.3.1'
        },
        {
          'A' => '1.2.3.2'
        },
        {
          'A' => '1.2.3.3'
        },
        {
          'A' => '1.2.3.4'
        },
        {
          'A' => '1.2.3.5'
        },
        {
          'A' => '1.2.3.6'
        },
        {
          'A' => '1.2.3.7'
        },
        {
          'A' => '1.2.3.8'
        },
        {
          'A' => '1.2.3.9'
        },
        {
          'A' => '1.2.3.10'
        },
        {
          'A' => '1.2.3.11'
        },
        {
          'A' => '1.2.3.12'
        }
      ],
      'e6.example.com' => [
        {
          'SPF' => 'v=spf1 a mx a mx a mx a mx a ptr ip4:1.2.3.4 -all'
        },
        {
          'A' => '1.2.3.8'
        },
        {
          'MX' => [
            '10',
            'e6.example.com'
          ]
        }
      ],
      'e7.example.com' => [
        {
          'SPF' => 'v=spf1 a mx a mx a mx a mx a ptr a ip4:1.2.3.4 -all'
        },
        {
          'A' => '1.2.3.20'
        }
      ],
      'e4.example.com' => [
        {
          'SPF' => 'v=spf1 mx'
        },
        {
          'MX' => [
            '0',
            'mail.example.com'
          ]
        },
        {
          'MX' => [
            '1',
            'mail.example.com'
          ]
        },
        {
          'MX' => [
            '2',
            'mail.example.com'
          ]
        },
        {
          'MX' => [
            '3',
            'mail.example.com'
          ]
        },
        {
          'MX' => [
            '4',
            'mail.example.com'
          ]
        },
        {
          'MX' => [
            '5',
            'mail.example.com'
          ]
        },
        {
          'MX' => [
            '6',
            'mail.example.com'
          ]
        },
        {
          'MX' => [
            '7',
            'mail.example.com'
          ]
        },
        {
          'MX' => [
            '8',
            'mail.example.com'
          ]
        },
        {
          'MX' => [
            '9',
            'mail.example.com'
          ]
        },
        {
          'MX' => [
            '10',
            'e4.example.com'
          ]
        },
        {
          'A' => '1.2.3.5'
        }
      ],
      'e1.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.1.1.1 redirect=e1.example.com'
        },
        {
          'A' => '1.2.3.6'
        }
      ],
      'e11.example.com' => [
        {
          'TXT' => 'v=spf1 a:err.example.com a:err1.example.com a:err2.example.com ?all'
        }
      ],
      '5.3.2.1.in-addr.arpa' => [
        {
          'PTR' => 'e1.example.com.'
        },
        {
          'PTR' => 'e2.example.com.'
        },
        {
          'PTR' => 'e3.example.com.'
        },
        {
          'PTR' => 'e4.example.com.'
        },
        {
          'PTR' => 'example.com.'
        },
        {
          'PTR' => 'e6.example.com.'
        },
        {
          'PTR' => 'e7.example.com.'
        },
        {
          'PTR' => 'e8.example.com.'
        },
        {
          'PTR' => 'e9.example.com.'
        },
        {
          'PTR' => 'e10.example.com.'
        },
        {
          'PTR' => 'e5.example.com.'
        }
      ],
      'e9.example.com' => [
        {
          'SPF' => 'v=spf1 a include:inc.example.com a ip4:1.2.3.4 -all'
        },
        {
          'A' => '1.2.3.21'
        }
      ],
      'e5.example.com' => [
        {
          'SPF' => 'v=spf1 ptr'
        },
        {
          'A' => '1.2.3.5'
        }
      ],
      'e8.example.com' => [
        {
          'SPF' => 'v=spf1 a include:inc.example.com ip4:1.2.3.4 mx -all'
        },
        {
          'A' => '1.2.3.4'
        }
      ],
      'inc.example.com' => [
        {
          'SPF' => 'v=spf1 a a a a a a a a'
        },
        {
          'A' => '1.2.3.10'
        }
      ]
    },
    'tests' => {
      'void-at-limit' => {
        'description' => 'SPF implementations SHOULD limit "void lookups" to two.  An  implementation MAY choose to make such a limit configurable. In this case, a default of two is RECOMMENDED.',
        'spec' => '4.6.4/7',
        'mailfrom' => 'foo@e12.example.com',
        'comment' => 'This is a new check in RFC7208, but it\'s been implemented in Mail::SPF for years with no issues.',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'result' => 'neutral'
      },
      'include-over-limit' => {
        'mailfrom' => 'foo@e9.example.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'result' => 'permerror',
        'spec' => '4.6.4/1',
        'description' => 'SPF implementations MUST limit the number of mechanisms and modifiers that do DNS lookups to at most 10 per SPF check.'
      },
      'mech-over-limit' => {
        'spec' => '4.6.4/1',
        'description' => 'SPF implementations MUST limit the number of mechanisms and modifiers that do DNS lookups to at most 10 per SPF check.',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'mailfrom' => 'foo@e7.example.com',
        'comment' => 'We do not check whether an implementation counts mechanisms before or after evaluation.  The RFC is not clear on this.'
      },
      'false-a-limit' => {
        'spec' => '4.6.4',
        'description' => 'unlike MX, PTR, there is no RR limit for A',
        'host' => '1.2.3.12',
        'helo' => 'mail.example.com',
        'comment' => 'There seems to be a tendency for developers to want to limit A RRs in addition to MX and PTR.  These are IPs, not usable for 3rd party DoS attacks, and hence need no low limit.',
        'mailfrom' => 'foo@e10.example.com',
        'result' => 'pass'
      },
      'ptr-limit' => {
        'result' => [
          'neutral',
          'pass'
        ],
        'mailfrom' => 'foo@e5.example.com',
        'comment' => 'The result of this test cannot be permerror not only because the RFC does not specify it, but because the sender has no control over the PTR records of spammers. The preferred result reflects evaluating the 10 allowed PTR records in the order returned by the test data. If testing with live DNS, the PTR order may be random, and a pass result would still be compliant.  The SPF result is effectively randomized.',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.5',
        'spec' => '4.6.4/3',
        'description' => 'there MUST be a limit of no more than 10 PTR looked up and checked.'
      },
      'void-over-limit' => {
        'result' => 'permerror',
        'mailfrom' => 'foo@e11.example.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'spec' => '4.6.4/7',
        'description' => 'SPF implementations SHOULD limit "void lookups" to two.  An implementation MAY choose to make such a limit configurable. In this case, a default of two is RECOMMENDED.'
      },
      'include-at-limit' => {
        'result' => 'pass',
        'comment' => 'The part of the RFC that talks about MAY parse the entire record first (4.6) is specific to syntax errors.  In RFC7208, processing limits are part of syntax checking (4.6).',
        'mailfrom' => 'foo@e8.example.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'spec' => '4.6.4/1',
        'description' => 'SPF implementations MUST limit the number of mechanisms and modifiers that do DNS lookups to at most 10 per SPF check.'
      },
      'mx-limit' => {
        'spec' => '4.6.4/2',
        'description' => 'there MUST be a limit of no more than 10 MX looked up and checked.',
        'result' => 'permerror',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.5',
        'mailfrom' => 'foo@e4.example.com',
        'comment' => 'The required result for this test was the subject of much controversy with RFC4408.  For RFC7208 the ambiguity was resolved in favor of producing a permerror result.'
      },
      'include-loop' => {
        'result' => 'permerror',
        'mailfrom' => 'foo@e2.example.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'description' => 'SPF implementations MUST limit the number of mechanisms and modifiers that do DNS lookups to at most 10 per SPF check.',
        'spec' => '4.6.4/1'
      },
      'redirect-loop' => {
        'spec' => '4.6.4/1',
        'description' => 'SPF implementations MUST limit the number of mechanisms and modifiers that do DNS lookups to at most 10 per SPF check.',
        'mailfrom' => 'foo@e1.example.com',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com',
        'result' => 'permerror'
      },
      'mech-at-limit' => {
        'description' => 'SPF implementations MUST limit the number of mechanisms and modifiers that do DNS lookups to at most 10 per SPF check.',
        'spec' => '4.6.4/1',
        'mailfrom' => 'foo@e6.example.com',
        'helo' => 'mail.example.com',
        'host' => '1.2.3.4',
        'result' => 'pass'
      }
    }
  }
]
