[
  {
    'tests' => {
      'helo-not-fqdn' => {
        'spec' => '4.3/1',
        'mailfrom' => '',
        'result' => 'none',
        'host' => '1.2.3.5',
        'helo' => 'A2345678'
      },
      'domain-literal' => {
        'spec' => '4.3/1',
        'mailfrom' => 'foo@[1.2.3.5]',
        'result' => 'none',
        'host' => '1.2.3.5',
        'helo' => 'OEMCOMPUTER'
      },
      'nolocalpart' => {
        'spec' => '4.3/2',
        'explanation' => 'postmaster',
        'mailfrom' => '@example.net',
        'result' => 'fail',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.net'
      },
      'toolonglabel' => {
        'spec' => '4.3/1',
        'comment' => 'For initial processing, a long label results in None, not TempError',
        'mailfrom' => 'lyme.eater@A123456789012345678901234567890123456789012345678901234567890123.example.com',
        'description' => 'DNS labels limited to 63 chars.',
        'result' => 'none',
        'host' => '1.2.3.5',
        'helo' => 'mail.example.net'
      },
      'helo-domain-literal' => {
        'spec' => '4.3/1',
        'mailfrom' => '',
        'result' => 'none',
        'host' => '1.2.3.5',
        'helo' => '[1.2.3.5]'
      },
      'emptylabel' => {
        'spec' => '4.3/1',
        'mailfrom' => 'lyme.eater@A...example.com',
        'result' => 'none',
        'host' => '1.2.3.5',
        'helo' => 'mail.example.net'
      },
      'longlabel' => {
        'spec' => '4.3/1',
        'mailfrom' => 'lyme.eater@A12345678901234567890123456789012345678901234567890123456789012.example.com',
        'description' => 'DNS labels limited to 63 chars.',
        'result' => 'fail',
        'host' => '1.2.3.5',
        'helo' => 'mail.example.net'
      }
    },
    'description' => 'Initial processing',
    'zonedata' => {
      'a12345678901234567890123456789012345678901234567890123456789012.example.com' => [
        {
          'SPF' => 'v=spf1 -all'
        }
      ],
      'a.example.net' => [
        {
          'SPF' => 'v=spf1 -all exp=exp.example.net'
        }
      ],
      'example.net' => [
        {
          'SPF' => 'v=spf1 -all exp=exp.example.net'
        }
      ],
      'example.com' => [
        'TIMEOUT'
      ],
      'exp.example.net' => [
        {
          'TXT' => '%{l}'
        }
      ]
    }
  },
  {
    'tests' => {
      'alltimeout' => {
        'spec' => '4.4/2',
        'mailfrom' => 'foo@alltimeout.example.net',
        'description' => 'Both TXT and SPF queries time out',
        'result' => 'temperror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.net'
      },
      'spfonly' => {
        'spec' => '4.4/1',
        'mailfrom' => 'foo@spfonly.example.net',
        'description' => 'Result is none if checking TXT records only.',
        'result' => [
          'fail',
          'none'
        ],
        'host' => '1.2.3.4',
        'helo' => 'mail.example.net'
      },
      'spftimeout' => {
        'spec' => '4.4/1',
        'comment' => 'This actually happens for a popular braindead DNS server.',
        'mailfrom' => 'foo@spftimeout.example.net',
        'description' => 'TXT record present, but SPF lookup times out. Result is temperror if checking SPF records only.',
        'result' => [
          'fail',
          'temperror'
        ],
        'host' => '1.2.3.4',
        'helo' => 'mail.example.net'
      },
      'both' => {
        'spec' => '4.4/1',
        'mailfrom' => 'foo@both.example.net',
        'result' => 'fail',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.net'
      },
      'nospftxttimeout' => {
        'spec' => '4.4/1',
        'comment' => 'Because TXT records is where v=spf1 records will likely be, returning temperror will try again later.  A timeout due to a braindead server is unlikely in the case of TXT, as opposed to the newer SPF RR.',
        'mailfrom' => 'foo@nospftxttimeout.example.net',
        'description' => 'No SPF record present, and TXT lookup times out. If only TXT records are checked, result is temperror.',
        'result' => [
          'temperror',
          'none'
        ],
        'host' => '1.2.3.4',
        'helo' => 'mail.example.net'
      },
      'txttimeout' => {
        'spec' => '4.4/1',
        'mailfrom' => 'foo@txttimeout.example.net',
        'description' => 'SPF record present, but TXT lookup times out. If only TXT records are checked, result is temperror.',
        'result' => [
          'fail',
          'temperror'
        ],
        'host' => '1.2.3.4',
        'helo' => 'mail.example.net'
      },
      'txtonly' => {
        'spec' => '4.4/1',
        'mailfrom' => 'foo@txtonly.example.net',
        'description' => 'Result is none if checking SPF records only.',
        'result' => [
          'fail',
          'none'
        ],
        'host' => '1.2.3.4',
        'helo' => 'mail.example.net'
      }
    },
    'description' => 'Record lookup',
    'zonedata' => {
      'alltimeout.example.net' => [
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
      'spftimeout.example.net' => [
        {
          'TXT' => 'v=spf1 -all'
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
      'txtonly.example.net' => [
        {
          'TXT' => 'v=spf1 -all'
        }
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
      'spfonly.example.net' => [
        {
          'SPF' => 'v=spf1 -all'
        },
        {
          'TXT' => 'NONE'
        }
      ]
    }
  },
  {
    'tests' => {
      'multitxt1' => {
        'spec' => '4.5/5',
        'mailfrom' => 'foo@example5.com',
        'description' => 'Older implementations will give permerror/unknown because of the conflicting TXT records.  However, RFC 4408 says the SPF records overrides them.',
        'result' => [
          'pass',
          'permerror'
        ],
        'host' => '1.2.3.4',
        'helo' => 'mail.example1.com'
      },
      'nospf' => {
        'spec' => '4.5/7',
        'mailfrom' => 'foo@mail.example1.com',
        'result' => 'none',
        'host' => '1.2.3.4',
        'helo' => 'mail.example1.com'
      },
      'case-insensitive' => {
        'spec' => '4.5/6',
        'mailfrom' => 'foo@example9.com',
        'description' => 'v=spf1 is case insensitive',
        'result' => 'softfail',
        'host' => '1.2.3.4',
        'helo' => 'mail.example1.com'
      },
      'multispf2' => {
        'spec' => '4.5/6',
        'mailfrom' => 'foo@example8.com',
        'description' => 'Older implementations ignoring SPF-type records will give pass because there is a (single) TXT record.  But RFC 4408 requires permerror because the SPF records override and there are more than one.',
        'result' => [
          'permerror',
          'pass'
        ],
        'host' => '1.2.3.4',
        'helo' => 'mail.example1.com'
      },
      'nospace1' => {
        'spec' => '4.5/4',
        'mailfrom' => 'foo@example2.com',
        'description' => 'Version must be terminated by space or end of record.  TXT pieces are joined without intervening spaces.',
        'result' => 'none',
        'host' => '1.2.3.4',
        'helo' => 'mail.example1.com'
      },
      'multitxt2' => {
        'spec' => '4.5/6',
        'comment' => 'Implementations that query for SPF-type RRs only will acceptably yield "none".',
        'mailfrom' => 'foo@example6.com',
        'description' => 'Multiple records is a permerror, v=spf1 is case insensitive',
        'result' => [
          'permerror',
          'none'
        ],
        'host' => '1.2.3.4',
        'helo' => 'mail.example1.com'
      },
      'nospace2' => {
        'spec' => '4.5/4',
        'mailfrom' => 'foo@example3.com',
        'result' => 'pass',
        'host' => '1.2.3.4',
        'helo' => 'mail.example1.com'
      },
      'multispf1' => {
        'spec' => '4.5/6',
        'mailfrom' => 'foo@example7.com',
        'description' => 'Multiple records is a permerror, even when they are identical. However, this situation cannot be reliably reproduced with live DNS since cache and resolvers are allowed to combine identical records.',
        'result' => [
          'permerror',
          'fail'
        ],
        'host' => '1.2.3.4',
        'helo' => 'mail.example1.com'
      },
      'empty' => {
        'spec' => '4.5/4',
        'mailfrom' => 'foo@example1.com',
        'description' => 'Empty SPF record.',
        'result' => 'neutral',
        'host' => '1.2.3.4',
        'helo' => 'mail1.example1.com'
      },
      'spfoverride' => {
        'spec' => '4.5/5',
        'mailfrom' => 'foo@example4.com',
        'description' => 'SPF records override TXT records.  Older implementation may check TXT records only.',
        'result' => [
          'pass',
          'fail'
        ],
        'host' => '1.2.3.4',
        'helo' => 'mail.example1.com'
      }
    },
    'description' => 'Selecting records',
    'zonedata' => {
      'example4.com' => [
        {
          'SPF' => 'v=spf1 +all'
        },
        {
          'TXT' => 'v=spf1 -all'
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
      'example9.com' => [
        {
          'SPF' => 'v=SpF1 ~all'
        }
      ],
      'example1.com' => [
        {
          'SPF' => 'v=spf1'
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
      'example6.com' => [
        {
          'TXT' => 'v=spf1 -all'
        },
        {
          'TXT' => 'V=sPf1 +all'
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
      'example7.com' => [
        {
          'SPF' => 'v=spf1 -all'
        },
        {
          'SPF' => 'v=spf1 -all'
        }
      ],
      'example2.com' => [
        {
          'SPF' => [
            'v=spf1',
            'mx'
          ]
        }
      ],
      'mail.example1.com' => [
        {
          'A' => '1.2.3.4'
        }
      ]
    }
  },
  {
    'tests' => {
      'redirect-is-modifier' => {
        'spec' => '4.6.1/4',
        'mailfrom' => 'foo@t8.example.com',
        'description' => 'Invalid mechanism.  Redirect is a modifier.',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'invalid-domain-long-via-macro' => {
        'spec' => [
          '4.3/1',
          '5/10/3'
        ],
        'comment' => 'A domain label longer than 63 characters that results from macro expansion in a mechanism target-name is valid domain-spec syntax (and is not even subject to syntax checking after macro expansion), even though a DNS query cannot be composed from it.  The spec being unclear about it, this could either be considered a syntax error, or, by analogy to 4.3/1 and 5/10/3, the mechanism chould be treated as a no-match.',
        'mailfrom' => 'foo@t12.example.com',
        'description' => 'target-name that is a valid domain-spec per RFC 4408 but an invalid domain name per RFC 1035 (long label) must be treated as non-existent.',
        'result' => [
          'permerror',
          'fail'
        ],
        'host' => '1.2.3.4',
        'helo' => '%%%%%%%%%%%%%%%%%%%%%%'
      },
      'invalid-domain' => {
        'spec' => '8.1/2',
        'mailfrom' => 'foo@t9.example.com',
        'description' => 'Domain-spec must end in macro-expand or valid toplabel.',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'modifier-charset-bad2' => {
        'spec' => '4.6.1/4',
        'mailfrom' => 'foo@t4.example.com',
        'description' => '\'=\' character immediately after the name and before any ":" or "/"',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'invalid-domain-empty-label' => {
        'spec' => [
          '4.3/1',
          '5/10/3'
        ],
        'comment' => 'An empty domain label, i.e. two successive dots, in a mechanism target-name is valid domain-spec syntax, even though a DNS query cannot be composed from it.  The spec being unclear about it, this could either be considered a syntax error, or, by analogy to 4.3/1 and 5/10/3, the mechanism chould be treated as a no-match.',
        'mailfrom' => 'foo@t10.example.com',
        'description' => 'target-name that is a valid domain-spec per RFC 4408 but an invalid domain name per RFC 1035 (empty label) must be treated as non-existent.',
        'result' => [
          'permerror',
          'fail'
        ],
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'invalid-domain-long' => {
        'spec' => [
          '4.3/1',
          '5/10/3'
        ],
        'comment' => 'A domain label longer than 63 characters in a mechanism target-name is valid domain-spec syntax, even though a DNS query cannot be composed from it.  The spec being unclear about it, this could either be considered a syntax error, or, by analogy to 4.3/1 and 5/10/3, the mechanism chould be treated as a no-match.',
        'mailfrom' => 'foo@t11.example.com',
        'description' => 'target-name that is a valid domain-spec per RFC 4408 but an invalid domain name per RFC 1035 (long label) must be treated as non-existent.',
        'result' => [
          'permerror',
          'fail'
        ],
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'redirect-after-mechanisms1' => {
        'spec' => '4.6.3',
        'comment' => 'The redirect in this example would violate processing limits, except that it is never used because of the all mechanism.',
        'mailfrom' => 'foo@t5.example.com',
        'description' => 'The "redirect" modifier has an effect after all the mechanisms.',
        'result' => 'softfail',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'modifier-charset-bad1' => {
        'spec' => '4.6.1/4',
        'mailfrom' => 'foo@t3.example.com',
        'description' => '\'=\' character immediately after the name and before any ":" or "/"',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'default-result' => {
        'spec' => '4.7/1',
        'mailfrom' => 'foo@t7.example.com',
        'description' => 'Default result is neutral.',
        'result' => 'neutral',
        'host' => '1.2.3.5',
        'helo' => 'mail.example.com'
      },
      'modifier-charset-good' => {
        'spec' => '4.6.1/2',
        'mailfrom' => 'foo@t2.example.com',
        'description' => 'name = ALPHA *( ALPHA / DIGIT / "-" / "_" / "." )',
        'result' => 'pass',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'redirect-after-mechanisms2' => {
        'spec' => '4.6.3',
        'mailfrom' => 'foo@t6.example.com',
        'description' => 'The "redirect" modifier has an effect after all the mechanisms.',
        'result' => 'fail',
        'host' => '1.2.3.5',
        'helo' => 'mail.example.com'
      },
      'detect-errors-anywhere' => {
        'spec' => '4.6',
        'mailfrom' => 'foo@t1.example.com',
        'description' => 'Any syntax errors anywhere in the record MUST be detected.',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      }
    },
    'description' => 'Record evaluation',
    'zonedata' => {
      't12.example.com' => [
        {
          'SPF' => 'v=spf1 a:%{H}.bar -all'
        }
      ],
      't10.example.com' => [
        {
          'SPF' => 'v=spf1 a:mail.example...com -all'
        }
      ],
      't9.example.com' => [
        {
          'SPF' => 'v=spf1 a:foo-bar -all'
        }
      ],
      't5.example.com' => [
        {
          'SPF' => 'v=spf1 redirect=t5.example.com ~all'
        }
      ],
      't8.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.2.3.4 redirect:t2.example.com'
        }
      ],
      't1.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.2.3.4 -all moo'
        }
      ],
      't7.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.2.3.4'
        }
      ],
      't4.example.com' => [
        {
          'SPF' => 'v=spf1 moo.cow:far_out=man:dog/cat ip4:1.2.3.4 -all'
        }
      ],
      't2.example.com' => [
        {
          'SPF' => 'v=spf1 moo.cow-far_out=man:dog/cat ip4:1.2.3.4 -all'
        }
      ],
      't3.example.com' => [
        {
          'SPF' => 'v=spf1 moo.cow/far_out=man:dog/cat ip4:1.2.3.4 -all'
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
      't6.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.2.3.4 redirect=t2.example.com'
        }
      ]
    }
  },
  {
    'tests' => {
      'all-cidr' => {
        'spec' => '5.1/1',
        'mailfrom' => 'foo@e3.example.com',
        'description' => 'all              = "all"
',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'all-neutral' => {
        'spec' => '5.1/1',
        'mailfrom' => 'foo@e4.example.com',
        'description' => 'all              = "all"
',
        'result' => 'neutral',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'all-arg' => {
        'spec' => '5.1/1',
        'comment' => 'At least one implementation got this wrong',
        'mailfrom' => 'foo@e2.example.com',
        'description' => 'all              = "all"
',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'all-dot' => {
        'spec' => '5.1/1',
        'comment' => 'At least one implementation got this wrong',
        'mailfrom' => 'foo@e1.example.com',
        'description' => 'all              = "all"
',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'all-double' => {
        'spec' => '5.1/1',
        'mailfrom' => 'foo@e5.example.com',
        'description' => 'all              = "all"
',
        'result' => 'pass',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      }
    },
    'description' => 'ALL mechanism syntax',
    'zonedata' => {
      'e3.example.com' => [
        {
          'SPF' => 'v=spf1 -all/8'
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
      'mail.example.com' => [
        {
          'A' => '1.2.3.4'
        }
      ],
      'e5.example.com' => [
        {
          'SPF' => 'v=spf1 all -all'
        }
      ],
      'e2.example.com' => [
        {
          'SPF' => 'v=spf1 -all:foobar'
        }
      ]
    }
  },
  {
    'tests' => {
      'ptr-nomatch-invalid' => {
        'spec' => '5.5/5',
        'comment' => 'This PTR record does not validate',
        'mailfrom' => 'foo@e4.example.com',
        'description' => 'Check all validated domain names to see if they end in the <target-name> domain.',
        'result' => 'fail',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'ptr-match-implicit' => {
        'spec' => '5.5/5',
        'mailfrom' => 'foo@e3.example.com',
        'description' => 'Check all validated domain names to see if they end in the <target-name> domain.',
        'result' => 'pass',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'ptr-match-target' => {
        'spec' => '5.5/5',
        'mailfrom' => 'foo@e2.example.com',
        'description' => 'Check all validated domain names to see if they end in the <target-name> domain.',
        'result' => 'pass',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'ptr-empty-domain' => {
        'spec' => '5.5/2',
        'mailfrom' => 'foo@e5.example.com',
        'description' => 'domain-spec cannot be empty.',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'ptr-cidr' => {
        'spec' => '5.5/2',
        'mailfrom' => 'foo@e1.example.com',
        'description' => 'PTR              = "ptr"    [ ":" domain-spec ]',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'ptr-match-ip6' => {
        'spec' => '5.5/5',
        'mailfrom' => 'foo@e3.example.com',
        'description' => 'Check all validated domain names to see if they end in the <target-name> domain.',
        'result' => 'pass',
        'host' => 'CAFE:BABE::1',
        'helo' => 'mail.example.com'
      }
    },
    'description' => 'PTR mechanism syntax',
    'zonedata' => {
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
      'e4.example.com' => [
        {
          'SPF' => 'v=spf1 ptr -all'
        }
      ],
      'e1.example.com' => [
        {
          'SPF' => 'v=spf1 ptr/0 -all'
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
      'e2.example.com' => [
        {
          'SPF' => 'v=spf1 ptr:example.com -all'
        }
      ]
    }
  },
  {
    'tests' => {
      'a-empty-domain' => {
        'spec' => '5.3/2',
        'mailfrom' => 'foo@e13.example.com',
        'description' => 'domain-spec cannot be empty.',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'a-cidr6' => {
        'spec' => '5.3/2',
        'mailfrom' => 'foo@e6.example.com',
        'description' => 'A                = "a"      [ ":" domain-spec ] [ dual-cidr-length ]
dual-cidr-length = [ ip4-cidr-length ] [ "/" ip6-cidr-length ]
',
        'result' => 'fail',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'a-numeric-toplabel' => {
        'spec' => '8.1/2',
        'mailfrom' => 'foo@e5.example.com',
        'description' => 'toplabel may not be all numeric',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'a-dash-in-toplabel' => {
        'spec' => '8.1/2',
        'comment' => 'Going from the "toplabel" grammar definition, an implementation using regular expressions in incrementally parsing SPF records might erroneously try to match a TLD such as ".xn--zckzah" (cf. IDN TLDs!) to \'( *alphanum ALPHA *alphanum )\' first before trying the alternative \'( 1*alphanum "-" *( alphanum / "-" ) alphanum )\', essentially causing a non-greedy, and thus, incomplete match.  Make sure a greedy match is performed!',
        'mailfrom' => 'foo@e14.example.com',
        'description' => 'toplabel may contain dashes',
        'result' => 'pass',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'a-only-toplabel' => {
        'spec' => '8.1/2',
        'mailfrom' => 'foo@e5a.example.com',
        'description' => 'domain-spec may not consist of only a toplabel.',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'a-nxdomain' => {
        'spec' => '5.3/3',
        'mailfrom' => 'foo@e1.example.com',
        'description' => 'If no ips are returned, A mechanism does not match, even with /0.',
        'result' => 'fail',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'a-cidr6-0-ip4' => {
        'spec' => '5.3/3',
        'mailfrom' => 'foo@e2a.example.com',
        'description' => 'Would match if any AAAA records are present in DNS, but not for an IP4 connection.',
        'result' => 'fail',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'a-colon-domain' => {
        'spec' => '8.1/2',
        'mailfrom' => 'foo@e11.example.com',
        'description' => 'domain-spec may contain any visible char except %',
        'result' => 'pass',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'a-cidr6-0-ip6' => {
        'spec' => '5.3/3',
        'mailfrom' => 'foo@e2a.example.com',
        'description' => 'Matches if any AAAA records are present in DNS.',
        'result' => 'pass',
        'host' => '1234::1',
        'helo' => 'mail.example.com'
      },
      'a-multi-ip2' => {
        'spec' => '5.3/3',
        'mailfrom' => 'foo@e10.example.com',
        'description' => 'A matches any returned IP.',
        'result' => 'pass',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'a-cidr6-0-ip4mapped' => {
        'spec' => '5.3/3',
        'mailfrom' => 'foo@e2a.example.com',
        'description' => 'Would match if any AAAA records are present in DNS, but not for an IP4 connection.',
        'result' => 'fail',
        'host' => '::FFFF:1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'a-cidr4-0' => {
        'spec' => '5.3/3',
        'mailfrom' => 'foo@e2.example.com',
        'description' => 'Matches if any A records are present in DNS.',
        'result' => 'pass',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'a-bad-toplabel' => {
        'spec' => '8.1/2',
        'mailfrom' => 'foo@e12.example.com',
        'description' => 'toplabel may not begin with a dash',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'a-cidr4-0-ip6' => {
        'spec' => '5.3/3',
        'mailfrom' => 'foo@e2.example.com',
        'description' => 'Matches if any A records are present in DNS.',
        'result' => 'fail',
        'host' => '1234::1',
        'helo' => 'mail.example.com'
      },
      'a-multi-ip1' => {
        'spec' => '5.3/3',
        'mailfrom' => 'foo@e10.example.com',
        'description' => 'A matches any returned IP.',
        'result' => 'pass',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'a-bad-cidr4' => {
        'spec' => '5.3/2',
        'mailfrom' => 'foo@e6a.example.com',
        'description' => 'A                = "a"      [ ":" domain-spec ] [ dual-cidr-length ]
dual-cidr-length = [ ip4-cidr-length ] [ "/" ip6-cidr-length ]
',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'a-only-toplabel-trailing-dot' => {
        'spec' => '8.1/2',
        'comment' => '"A trailing dot doesn\'t help."',
        'mailfrom' => 'foo@e5b.example.com',
        'description' => 'domain-spec may not consist of only a toplabel.',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'a-colon-domain-ip4mapped' => {
        'spec' => '8.1/2',
        'mailfrom' => 'foo@e11.example.com',
        'description' => 'domain-spec may contain any visible char except %',
        'result' => 'pass',
        'host' => '::FFFF:1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'a-bad-cidr6' => {
        'spec' => '5.3/2',
        'mailfrom' => 'foo@e7.example.com',
        'description' => 'A                = "a"      [ ":" domain-spec ] [ dual-cidr-length ]
dual-cidr-length = [ ip4-cidr-length ] [ "/" ip6-cidr-length ]
',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'a-cidr6-0-nxdomain' => {
        'spec' => '5.3/3',
        'mailfrom' => 'foo@e2b.example.com',
        'description' => 'No match if no AAAA records are present in DNS.',
        'result' => 'fail',
        'host' => '1234::1',
        'helo' => 'mail.example.com'
      },
      'a-numeric' => {
        'spec' => '8.1/2',
        'comment' => 'A common publishing mistake is using ip4 addresses with A mechanism. This should receive special diagnostic attention in the permerror.',
        'mailfrom' => 'foo@e4.example.com',
        'description' => 'toplabel may not be all numeric',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'a-bad-domain' => {
        'spec' => '8.1/2',
        'mailfrom' => 'foo@e9.example.com',
        'description' => 'domain-spec must pass basic syntax checks; a \':\' may appear in domain-spec, but not in top-label',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'a-null' => {
        'spec' => '8.1/2',
        'mailfrom' => 'foo@e3.example.com',
        'description' => 'Null octets not allowed in toplabel',
        'result' => 'permerror',
        'host' => '1.2.3.5',
        'helo' => 'mail.example.com'
      }
    },
    'description' => 'A mechanism syntax',
    'zonedata' => {
      'e7.example.com' => [
        {
          'SPF' => 'v=spf1 a//129 -all'
        }
      ],
      'e11.example.com' => [
        {
          'SPF' => 'v=spf1 a:foo:bar/baz.example.com'
        }
      ],
      'e5.example.com' => [
        {
          'SPF' => 'v=spf1 a:abc.123'
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
      'foo:bar/baz.example.com' => [
        {
          'A' => '1.2.3.4'
        }
      ],
      'e1.example.com' => [
        {
          'SPF' => 'v=spf1 a/0 -all'
        }
      ],
      'e2b.example.com' => [
        {
          'A' => '1.1.1.1'
        },
        {
          'SPF' => 'v=spf1 a//0 -all'
        }
      ],
      'e6.example.com' => [
        {
          'SPF' => 'v=spf1 a//33 -all'
        }
      ],
      'e14.example.com' => [
        {
          'SPF' => 'v=spf1 a:foo.example.xn--zckzah -all'
        }
      ],
      'e6a.example.com' => [
        {
          'SPF' => 'v=spf1 a/33 -all'
        }
      ],
      'foo.example.xn--zckzah' => [
        {
          'A' => '1.2.3.4'
        }
      ],
      'e3.example.com' => [
        {
          'SPF' => 'v=spf1 a:foo.example.com '
        }
      ],
      'e9.example.com' => [
        {
          'SPF' => 'v=spf1 a:example.com:8080'
        }
      ],
      'e4.example.com' => [
        {
          'SPF' => 'v=spf1 a:111.222.33.44'
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
      'e5a.example.com' => [
        {
          'SPF' => 'v=spf1 a:museum'
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
      'e13.example.com' => [
        {
          'SPF' => 'v=spf1 a:'
        }
      ],
      'mail.example.com' => [
        {
          'A' => '1.2.3.4'
        }
      ],
      'e12.example.com' => [
        {
          'SPF' => 'v=spf1 a:example.-com'
        }
      ],
      'e5b.example.com' => [
        {
          'SPF' => 'v=spf1 a:museum.'
        }
      ]
    }
  },
  {
    'tests' => {
      'include-empty-domain' => {
        'spec' => '5.2/1',
        'mailfrom' => 'foo@e8.example.com',
        'description' => 'domain-spec cannot be empty.',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'include-fail' => {
        'spec' => '5.2/9',
        'mailfrom' => 'foo@e1.example.com',
        'description' => 'recursive check_host() result of fail causes include to not match.',
        'result' => 'softfail',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'include-neutral' => {
        'spec' => '5.2/9',
        'mailfrom' => 'foo@e3.example.com',
        'description' => 'recursive check_host() result of neutral causes include to not match.',
        'result' => 'fail',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'include-syntax-error' => {
        'spec' => '5.2/1',
        'mailfrom' => 'foo@e6.example.com',
        'description' => 'include          = "include"  ":" domain-spec',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'include-none' => {
        'spec' => '5.2/9',
        'mailfrom' => 'foo@e7.example.com',
        'description' => 'recursive check_host() result of none causes include to permerror',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'include-softfail' => {
        'spec' => '5.2/9',
        'mailfrom' => 'foo@e2.example.com',
        'description' => 'recursive check_host() result of softfail causes include to not match.',
        'result' => 'pass',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'include-permerror' => {
        'spec' => '5.2/9',
        'mailfrom' => 'foo@e5.example.com',
        'description' => 'recursive check_host() result of permerror causes include to permerror',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'include-temperror' => {
        'spec' => '5.2/9',
        'mailfrom' => 'foo@e4.example.com',
        'description' => 'recursive check_host() result of temperror causes include to temperror',
        'result' => 'temperror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'include-cidr' => {
        'spec' => '5.2/1',
        'mailfrom' => 'foo@e9.example.com',
        'description' => 'include          = "include"  ":" domain-spec',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      }
    },
    'description' => 'Include mechanism semantics and syntax',
    'zonedata' => {
      'e8.example.com' => [
        {
          'SPF' => 'v=spf1 include: -all'
        }
      ],
      'e6.example.com' => [
        {
          'SPF' => 'v=spf1 include +all'
        }
      ],
      'ip6.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.2.3.6 ~all'
        }
      ],
      'ip5.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.2.3.5 -all'
        }
      ],
      'e7.example.com' => [
        {
          'SPF' => 'v=spf1 include:erehwon.example.com -all'
        }
      ],
      'e9.example.com' => [
        {
          'SPF' => 'v=spf1 include:ip5.example.com/24 -all'
        }
      ],
      'e3.example.com' => [
        {
          'SPF' => 'v=spf1 include:ip7.example.com -all'
        }
      ],
      'e4.example.com' => [
        {
          'SPF' => 'v=spf1 include:ip8.example.com -all'
        }
      ],
      'e5.example.com' => [
        {
          'SPF' => 'v=spf1 include:e6.example.com -all'
        }
      ],
      'e2.example.com' => [
        {
          'SPF' => 'v=spf1 include:ip6.example.com all'
        }
      ],
      'ip7.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.2.3.7 ?all'
        }
      ],
      'mail.example.com' => [
        {
          'A' => '1.2.3.4'
        }
      ],
      'ip8.example.com' => [
        'TIMEOUT'
      ],
      'e1.example.com' => [
        {
          'SPF' => 'v=spf1 include:ip5.example.com ~all'
        }
      ],
      'erehwon.example.com' => [
        {
          'TXT' => 'v=spfl am not an SPF record'
        }
      ]
    }
  },
  {
    'tests' => {
      'mx-cidr6-0-nxdomain' => {
        'spec' => '5.4/3',
        'mailfrom' => 'foo@e2b.example.com',
        'description' => 'No match if no AAAA records for any MX records are present in DNS.',
        'result' => 'fail',
        'host' => '1234::1',
        'helo' => 'mail.example.com'
      },
      'mx-implicit' => {
        'spec' => '5.4/4',
        'mailfrom' => 'foo@e4.example.com',
        'description' => 'If the target name has no MX records, check_host() MUST NOT pretend the target is its single MX, and MUST NOT default to an A lookup on the target-name directly.',
        'result' => 'neutral',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'mx-null' => {
        'spec' => '8.1/2',
        'mailfrom' => 'foo@e3.example.com',
        'description' => 'Null not allowed in top-label.',
        'result' => 'permerror',
        'host' => '1.2.3.5',
        'helo' => 'mail.example.com'
      },
      'mx-cidr6' => {
        'spec' => '5.4/2',
        'mailfrom' => 'foo@e6.example.com',
        'description' => 'MX                = "mx"      [ ":" domain-spec ] [ dual-cidr-length ]
dual-cidr-length = [ ip4-cidr-length ] [ "/" ip6-cidr-length ]
',
        'result' => 'fail',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'mx-cidr4-0-ip6' => {
        'spec' => '5.4/3',
        'mailfrom' => 'foo@e2.example.com',
        'description' => 'Matches if any A records for any MX records are present in DNS.',
        'result' => 'fail',
        'host' => '1234::1',
        'helo' => 'mail.example.com'
      },
      'mx-bad-cidr6' => {
        'spec' => '5.4/2',
        'mailfrom' => 'foo@e7.example.com',
        'description' => 'MX                = "mx"      [ ":" domain-spec ] [ dual-cidr-length ]
dual-cidr-length = [ ip4-cidr-length ] [ "/" ip6-cidr-length ]
',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'mx-multi-ip1' => {
        'spec' => '5.4/3',
        'mailfrom' => 'foo@e10.example.com',
        'description' => 'MX matches any returned IP.',
        'result' => 'pass',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'mx-cidr6-0-ip6' => {
        'spec' => '5.3/3',
        'mailfrom' => 'foo@e2a.example.com',
        'description' => 'Matches if any AAAA records for any MX records are present in DNS.',
        'result' => 'pass',
        'host' => '1234::1',
        'helo' => 'mail.example.com'
      },
      'mx-cidr6-0-ip4mapped' => {
        'spec' => '5.4/3',
        'mailfrom' => 'foo@e2a.example.com',
        'description' => 'Would match if any AAAA records for MX records are present in DNS, but not for an IP4 connection.',
        'result' => 'fail',
        'host' => '::FFFF:1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'mx-multi-ip2' => {
        'spec' => '5.4/3',
        'mailfrom' => 'foo@e10.example.com',
        'description' => 'MX matches any returned IP.',
        'result' => 'pass',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'mx-nxdomain' => {
        'spec' => '5.4/3',
        'mailfrom' => 'foo@e1.example.com',
        'description' => 'If no ips are returned, MX mechanism does not match, even with /0.',
        'result' => 'fail',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'mx-bad-cidr4' => {
        'spec' => '5.4/2',
        'mailfrom' => 'foo@e6a.example.com',
        'description' => 'MX                = "mx"      [ ":" domain-spec ] [ dual-cidr-length ]
dual-cidr-length = [ ip4-cidr-length ] [ "/" ip6-cidr-length ]
',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'mx-cidr4-0' => {
        'spec' => '5.4/3',
        'mailfrom' => 'foo@e2.example.com',
        'description' => 'Matches if any A records for any MX records are present in DNS.',
        'result' => 'pass',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'mx-empty-domain' => {
        'spec' => '5.2/1',
        'mailfrom' => 'foo@e13.example.com',
        'description' => 'domain-spec cannot be empty.',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'mx-bad-toplab' => {
        'spec' => '8.1/2',
        'mailfrom' => 'foo@e12.example.com',
        'description' => 'Toplabel may not begin with -',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'mx-colon-domain-ip4mapped' => {
        'spec' => '8.1/2',
        'mailfrom' => 'foo@e11.example.com',
        'description' => 'Domain-spec may contain any visible char except %',
        'result' => 'pass',
        'host' => '::FFFF:1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'mx-cidr6-0-ip4' => {
        'spec' => '5.4/3',
        'mailfrom' => 'foo@e2a.example.com',
        'description' => 'Would match if any AAAA records for MX records are present in DNS, but not for an IP4 connection.',
        'result' => 'fail',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'mx-bad-domain' => {
        'spec' => '8.1/2',
        'comment' => 'A \':\' may appear in domain-spec, but not in top-label.',
        'mailfrom' => 'foo@e9.example.com',
        'description' => 'domain-spec must pass basic syntax checks',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'mx-empty' => {
        'spec' => '5.4/3',
        'comment' => 'Some implementations have had trouble with null MX',
        'mailfrom' => '',
        'description' => 'test null MX',
        'result' => 'neutral',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'mx-numeric-top-label' => {
        'spec' => '8.1/2',
        'mailfrom' => 'foo@e5.example.com',
        'description' => 'Top-label may not be all numeric',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'mx-colon-domain' => {
        'spec' => '8.1/2',
        'mailfrom' => 'foo@e11.example.com',
        'description' => 'Domain-spec may contain any visible char except %',
        'result' => 'pass',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      }
    },
    'description' => 'MX mechanism syntax',
    'zonedata' => {
      'e7.example.com' => [
        {
          'SPF' => 'v=spf1 mx//129 -all'
        }
      ],
      'e11.example.com' => [
        {
          'SPF' => 'v=spf1 mx:foo:bar/baz.example.com'
        }
      ],
      'e5.example.com' => [
        {
          'SPF' => 'v=spf1 mx:abc.123'
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
      'foo.example.com' => [
        {
          'MX' => [
            '0',
            'foo1.example.com'
          ]
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
      'e6.example.com' => [
        {
          'SPF' => 'v=spf1 mx//33 -all'
        }
      ],
      'e6a.example.com' => [
        {
          'SPF' => 'v=spf1 mx/33 -all'
        }
      ],
      'e3.example.com' => [
        {
          'SPF' => 'v=spf1 mx:foo.example.com '
        }
      ],
      'e9.example.com' => [
        {
          'SPF' => 'v=spf1 mx:example.com:8080'
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
      'e13.example.com' => [
        {
          'SPF' => 'v=spf1 mx: -all'
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
      'e12.example.com' => [
        {
          'SPF' => 'v=spf1 mx:example.-com'
        }
      ]
    }
  },
  {
    'tests' => {
      'exists-implicit' => {
        'spec' => '5.7/2',
        'mailfrom' => 'foo@e2.example.com',
        'description' => 'exists           = "exists"   ":" domain-spec',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'exists-empty-domain' => {
        'spec' => '5.7/2',
        'mailfrom' => 'foo@e1.example.com',
        'description' => 'domain-spec cannot be empty.',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'exists-cidr' => {
        'spec' => '5.7/2',
        'mailfrom' => 'foo@e3.example.com',
        'description' => 'exists           = "exists"   ":" domain-spec',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      }
    },
    'description' => 'EXISTS mechanism syntax',
    'zonedata' => {
      'e3.example.com' => [
        {
          'SPF' => 'v=spf1 exists:mail.example.com/24'
        }
      ],
      'e1.example.com' => [
        {
          'SPF' => 'v=spf1 exists:'
        }
      ],
      'mail.example.com' => [
        {
          'A' => '1.2.3.4'
        }
      ],
      'e2.example.com' => [
        {
          'SPF' => 'v=spf1 exists'
        }
      ]
    }
  },
  {
    'tests' => {
      'ip4-dual-cidr' => {
        'spec' => '5.6/2',
        'mailfrom' => 'foo@e6.example.com',
        'description' => 'dual-cidr-length not permitted on ip4',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'cidr4-32' => {
        'spec' => '5.6/2',
        'mailfrom' => 'foo@e2.example.com',
        'description' => 'ip4-cidr-length  = "/" 1*DIGIT',
        'result' => 'pass',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'ip4-mapped-ip6' => {
        'spec' => '5/9/2',
        'mailfrom' => 'foo@e7.example.com',
        'description' => 'IP4 mapped IP6 connections MUST be treated as IP4',
        'result' => 'fail',
        'host' => '::FFFF:1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'bare-ip4' => {
        'spec' => '5.6/2',
        'mailfrom' => 'foo@e5.example.com',
        'description' => 'IP4              = "ip4"      ":" ip4-network   [ ip4-cidr-length ]',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'bad-ip4-port' => {
        'spec' => '5.6/2',
        'comment' => 'This has actually been published in SPF records.',
        'mailfrom' => 'foo@e8.example.com',
        'description' => 'IP4              = "ip4"      ":" ip4-network   [ ip4-cidr-length ]',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'cidr4-33' => {
        'spec' => '5.6/2',
        'comment' => 'The RFC is silent on ip4 CIDR > 32 or ip6 CIDR > 128.  However, since there is no reasonable interpretation (except a noop), we have read between the lines to see a prohibition on invalid CIDR.',
        'mailfrom' => 'foo@e3.example.com',
        'description' => 'Invalid CIDR should get permerror.',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'cidr4-0' => {
        'spec' => '5.6/2',
        'mailfrom' => 'foo@e1.example.com',
        'description' => 'ip4-cidr-length  = "/" 1*DIGIT',
        'result' => 'pass',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'cidr4-032' => {
        'spec' => '5.6/2',
        'comment' => 'Leading zeros are not explicitly prohibited by the RFC. However, since the RFC explicity prohibits leading zeros in ip4-network, our interpretation is that CIDR should be also.',
        'mailfrom' => 'foo@e4.example.com',
        'description' => 'Invalid CIDR should get permerror.',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'bad-ip4-short' => {
        'spec' => '5.6/4',
        'mailfrom' => 'foo@e9.example.com',
        'description' => 'It is not permitted to omit parts of the IP address instead of using CIDR notations.',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      }
    },
    'description' => 'IP4 mechanism syntax',
    'zonedata' => {
      'e8.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.2.3.4:8080'
        }
      ],
      'e6.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.2.3.4//32'
        }
      ],
      'e7.example.com' => [
        {
          'SPF' => 'v=spf1 -ip4:1.2.3.4 ip6:::FFFF:1.2.3.4'
        }
      ],
      'e9.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.2.3'
        }
      ],
      'e3.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.2.3.4/33 -all'
        }
      ],
      'e4.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.2.3.4/032 -all'
        }
      ],
      'e5.example.com' => [
        {
          'SPF' => 'v=spf1 ip4'
        }
      ],
      'e2.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.2.3.4/32 -all'
        }
      ],
      'mail.example.com' => [
        {
          'A' => '1.2.3.4'
        }
      ],
      'e1.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.1.1.1/0 -all'
        }
      ]
    }
  },
  {
    'comment' => 'IP4 only implementations may skip tests where host is not IP4',
    'tests' => {
      'cidr6-33' => {
        'spec' => '5.6/2',
        'mailfrom' => 'foo@e5.example.com',
        'description' => 'make sure ip4 cidr restriction are not used for ip6',
        'result' => 'pass',
        'host' => 'CAFE:BABE:8000::',
        'helo' => 'mail.example.com'
      },
      'ip6-bad1' => {
        'spec' => '5.6/2',
        'mailfrom' => 'foo@e6.example.com',
        'description' => '',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'cidr6-33-ip4' => {
        'spec' => '5.6/2',
        'mailfrom' => 'foo@e5.example.com',
        'description' => 'make sure ip4 cidr restriction are not used for ip6',
        'result' => 'neutral',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'cidr6-bad' => {
        'spec' => '5.6/2',
        'comment' => 'IP4 only implementations MUST fully syntax check all mechanisms, even if they otherwise ignore them.',
        'mailfrom' => 'foo@e4.example.com',
        'description' => 'dual-cidr syntax not used for ip6',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'cidr6-0' => {
        'spec' => '5/8',
        'mailfrom' => 'foo@e2.example.com',
        'description' => 'Match any IP6',
        'result' => 'pass',
        'host' => 'DEAF:BABE::CAB:FEE',
        'helo' => 'mail.example.com'
      },
      'cidr6-129' => {
        'spec' => '5.6/2',
        'comment' => 'IP4 only implementations MUST fully syntax check all mechanisms, even if they otherwise ignore them.',
        'mailfrom' => 'foo@e3.example.com',
        'description' => 'Invalid CIDR',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'cidr6-0-ip4' => {
        'spec' => '5/9/2',
        'comment' => 'There is controversy over ip4 mapped connections.  RFC4408 clearly requires such connections to be considered as ip4.  However, some interpret the RFC to mean that such connections should *also* match appropriate ip6 mechanisms (but not, inexplicably, A or MX mechanisms).  Until there is consensus, both results are acceptable.',
        'mailfrom' => 'foo@e2.example.com',
        'description' => 'IP4 connections do not match ip6.',
        'result' => [
          'neutral',
          'pass'
        ],
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'cidr6-ip4' => {
        'spec' => '5/9/2',
        'comment' => 'There is controversy over ip4 mapped connections.  RFC4408 clearly requires such connections to be considered as ip4.  However, some interpret the RFC to mean that such connections should *also* match appropriate ip6 mechanisms (but not, inexplicably, A or MX mechanisms).  Until there is consensus, both results are acceptable.',
        'mailfrom' => 'foo@e2.example.com',
        'description' => 'Even if the SMTP connection is via IPv6, an IPv4-mapped IPv6 IP address (see RFC 3513, Section 2.5.5) MUST still be considered an IPv4 address.',
        'result' => [
          'neutral',
          'pass'
        ],
        'host' => '::FFFF:1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'bare-ip6' => {
        'spec' => '5.6/2',
        'mailfrom' => 'foo@e1.example.com',
        'description' => 'IP6              = "ip6"      ":" ip6-network   [ ip6-cidr-length ]',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      }
    },
    'description' => 'IP6 mechanism syntax',
    'zonedata' => {
      'e6.example.com' => [
        {
          'SPF' => 'v=spf1 ip6::CAFE::BABE'
        }
      ],
      'e3.example.com' => [
        {
          'SPF' => 'v=spf1 ip6:::1.1.1.1/129'
        }
      ],
      'e4.example.com' => [
        {
          'SPF' => 'v=spf1 ip6:::1.1.1.1//33'
        }
      ],
      'e1.example.com' => [
        {
          'SPF' => 'v=spf1 -all ip6'
        }
      ],
      'mail.example.com' => [
        {
          'A' => '1.2.3.4'
        }
      ],
      'e5.example.com' => [
        {
          'SPF' => 'v=spf1 ip6:CAFE:BABE:8000::/33'
        }
      ],
      'e2.example.com' => [
        {
          'SPF' => 'v=spf1 ip6:::1.1.1.1/0'
        }
      ]
    }
  },
  {
    'comment' => 'Implementing exp= is optional.  If not implemented, the test driver should not check the explanation field.',
    'tests' => {
      'dorky-sentinel' => {
        'spec' => '8.1/6',
        'mailfrom' => 'Macro Error@e8.example.com',
        'description' => 'An implementation that uses a legal expansion as a sentinel.  We cannot check them all, but we can check this one.',
        'host' => '1.2.3.4',
        'comment' => 'Spaces are allowed in local-part.',
        'explanation' => 'Macro Error in implementation',
        'helo' => 'mail.example.com',
        'result' => 'fail'
      },
      'redirect-cancels-prior-exp' => {
        'spec' => '6.2/13',
        'explanation' => 'See me.',
        'mailfrom' => 'foo@e3.example.com',
        'description' => 'when executing "redirect", exp= from the original domain MUST NOT be used.',
        'result' => 'fail',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'redirect-cancels-exp' => {
        'spec' => '6.2/13',
        'explanation' => 'DEFAULT',
        'mailfrom' => 'foo@e1.example.com',
        'description' => 'when executing "redirect", exp= from the original domain MUST NOT be used.',
        'result' => 'fail',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'include-ignores-exp' => {
        'spec' => '6.2/13',
        'explanation' => 'Correct!',
        'mailfrom' => 'foo@e7.example.com',
        'description' => 'when executing "include", exp= from the target domain MUST NOT be used.',
        'result' => 'fail',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'redirect-syntax-error' => {
        'spec' => '6.1/2',
        'comment' => 'A literal application of the grammar causes modifier syntax errors (except for macro syntax) to become unknown-modifier.

  modifier = explanation | redirect | unknown-modifier

However, it is generally agreed, with precedent in other RFCs, that unknown-modifier should not be "greedy", and should not match known modifier names.  There should have been explicit prose to this effect, and some has been proposed as an erratum.',
        'mailfrom' => 'foo@e17.example.com',
        'description' => 'redirect      = "redirect" "=" domain-spec
',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'exp-twice' => {
        'spec' => '6/2',
        'comment' => 'These two modifiers (exp,redirect) MUST NOT appear in a record more than once each. If they do, then check_host() exits with a result of "PermError".',
        'mailfrom' => 'foo@e14.example.com',
        'description' => 'exp= appears twice.
',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'default-modifier-obsolete' => {
        'spec' => '6/3',
        'comment' => 'Some implementations may have a leftover default= modifier from earlier drafts.',
        'mailfrom' => 'foo@e19.example.com',
        'description' => 'Unknown modifiers do not modify the RFC SPF result.
',
        'result' => 'neutral',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'exp-dns-error' => {
        'spec' => '6.2/4',
        'mailfrom' => 'foo@e21.example.com',
        'description' => 'Ignore exp if DNS error.
',
        'host' => '1.2.3.4',
        'comment' => 'If domain-spec is empty, or there are any DNS processing errors (any RCODE other than 0), or if no records are returned, or if more than one record is returned, or if there are syntax errors in the explanation string, then proceed as if no exp modifier was given.',
        'explanation' => 'DEFAULT',
        'helo' => 'mail.example.com',
        'result' => 'fail'
      },
      'unknown-modifier-syntax' => {
        'spec' => 'A/3',
        'comment' => 'Unknown modifiers must have valid macro syntax.',
        'mailfrom' => 'foo@e9.example.com',
        'description' => 'unknown-modifier = name "=" macro-string
',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'redirect-none' => {
        'spec' => '6.1/4',
        'mailfrom' => 'foo@e10.example.com',
        'description' => 'If no SPF record is found, or if the target-name is malformed, the result is a "PermError" rather than "None".',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'exp-syntax-error' => {
        'spec' => '6.2/1',
        'comment' => 'A literal application of the grammar causes modifier syntax errors (except for macro syntax) to become unknown-modifier.

  modifier = explanation | redirect | unknown-modifier

However, it is generally agreed, with precedent in other RFCs, that unknown-modifier should not be "greedy", and should not match known modifier names.  There should have been explicit prose to this effect, and some has been proposed as an erratum.',
        'mailfrom' => 'foo@e16.example.com',
        'description' => 'explanation      = "exp" "=" domain-spec
',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'default-modifier-obsolete2' => {
        'spec' => '6/3',
        'comment' => 'Some implementations may have a leftover default= modifier from earlier drafts.',
        'mailfrom' => 'foo@e20.example.com',
        'description' => 'Unknown modifiers do not modify the RFC SPF result.
',
        'result' => 'neutral',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'redirect-twice' => {
        'spec' => '6/2',
        'comment' => 'These two modifiers (exp,redirect) MUST NOT appear in a record more than once each. If they do, then check_host() exits with a result of "PermError".',
        'mailfrom' => 'foo@e15.example.com',
        'description' => 'redirect= appears twice.
',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'invalid-modifier' => {
        'spec' => 'A/3',
        'comment' => 'Unknown modifier name must begin with alpha.',
        'mailfrom' => 'foo@e5.example.com',
        'description' => 'unknown-modifier = name "=" macro-string
name             = ALPHA *( ALPHA / DIGIT / "-" / "_" / "." )
',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'exp-no-txt' => {
        'spec' => '6.2/4',
        'mailfrom' => 'foo@e22.example.com',
        'description' => 'Ignore exp if no TXT records.
',
        'host' => '1.2.3.4',
        'comment' => 'If domain-spec is empty, or there are any DNS processing errors (any RCODE other than 0), or if no records are returned, or if more than one record is returned, or if there are syntax errors in the explanation string, then proceed as if no exp modifier was given.',
        'explanation' => 'DEFAULT',
        'helo' => 'mail.example.com',
        'result' => 'fail'
      },
      'explanation-syntax-error' => {
        'spec' => '6.2/4',
        'mailfrom' => 'foo@e13.example.com',
        'description' => 'Ignore exp if the explanation string has a syntax error.
',
        'host' => '1.2.3.4',
        'comment' => 'If domain-spec is empty, or there are any DNS processing errors (any RCODE other than 0), or if no records are returned, or if more than one record is returned, or if there are syntax errors in the explanation string, then proceed as if no exp modifier was given.',
        'explanation' => 'DEFAULT',
        'helo' => 'mail.example.com',
        'result' => 'fail'
      },
      'empty-modifier-name' => {
        'spec' => 'A/3',
        'comment' => 'Unknown modifier name must not be empty.',
        'mailfrom' => 'foo@e6.example.com',
        'description' => 'name             = ALPHA *( ALPHA / DIGIT / "-" / "_" / "." )
',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'exp-multiple-txt' => {
        'spec' => '6.2/4',
        'mailfrom' => 'foo@e11.example.com',
        'description' => 'Ignore exp if multiple TXT records.
',
        'host' => '1.2.3.4',
        'comment' => 'If domain-spec is empty, or there are any DNS processing errors (any RCODE other than 0), or if no records are returned, or if more than one record is returned, or if there are syntax errors in the explanation string, then proceed as if no exp modifier was given.',
        'explanation' => 'DEFAULT',
        'helo' => 'mail.example.com',
        'result' => 'fail'
      },
      'redirect-empty-domain' => {
        'spec' => '6.2/4',
        'comment' => 'Unlike for exp, there is no instruction to override the permerror for an empty domain-spec (which is invalid syntax).',
        'mailfrom' => 'foo@e18.example.com',
        'description' => 'redirect = "redirect" "=" domain-spec
',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'exp-empty-domain' => {
        'spec' => '6.2/4',
        'comment' => 'Section 6.2/4 says, "If domain-spec is empty, or there are any DNS processing errors (any RCODE other than 0), or if no records are returned, or if more than one record is returned, or if there are syntax errors in the explanation string, then proceed as if no exp modifier was given."  However, "if domain-spec is empty" conflicts with the grammar given for the exp modifier.  This was reported as an erratum, and the solution chosen was to report explicit "exp=" as PermError, but ignore problems due to macro expansion, DNS, or invalid explanation string.',
        'mailfrom' => 'foo@e12.example.com',
        'description' => 'PermError if exp= domain-spec is empty.
',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      }
    },
    'description' => 'Semantics of exp and other modifiers',
    'zonedata' => {
      'e7.example.com' => [
        {
          'SPF' => 'v=spf1 include:e3.example.com -all exp=exp3.example.com'
        }
      ],
      'e20.example.com' => [
        {
          'SPF' => 'v=spf1 default=+'
        }
      ],
      'e11.example.com' => [
        {
          'SPF' => 'v=spf1 -all exp=e11msg.example.com'
        }
      ],
      'e5.example.com' => [
        {
          'SPF' => 'v=spf1 1up=foo'
        }
      ],
      'e18.example.com' => [
        {
          'SPF' => 'v=spf1 ?all redirect='
        }
      ],
      'exp3.example.com' => [
        {
          'TXT' => 'Correct!'
        }
      ],
      'e21.example.com' => [
        {
          'SPF' => 'v=spf1 exp=e21msg.example.com -all'
        }
      ],
      'exp2.example.com' => [
        {
          'TXT' => 'See me.'
        }
      ],
      'e13msg.example.com' => [
        {
          'TXT' => 'The %{x}-files.'
        }
      ],
      'e1.example.com' => [
        {
          'SPF' => 'v=spf1 exp=exp1.example.com redirect=e2.example.com'
        }
      ],
      'exp1.example.com' => [
        {
          'TXT' => 'No-see-um'
        }
      ],
      'e6.example.com' => [
        {
          'SPF' => 'v=spf1 =all'
        }
      ],
      'e8.example.com' => [
        {
          'SPF' => 'v=spf1 -all exp=exp4.example.com'
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
      'e9.example.com' => [
        {
          'SPF' => 'v=spf1 -all foo=%abc'
        }
      ],
      'e22.example.com' => [
        {
          'SPF' => 'v=spf1 exp=mail.example.com -all'
        }
      ],
      'e15.example.com' => [
        {
          'SPF' => 'v=spf1 redirect=e12.example.com -all redirect=e12.example.com'
        }
      ],
      'e4.example.com' => [
        {
          'SPF' => 'v=spf1 -all exp=exp2.example.com'
        }
      ],
      'e10.example.com' => [
        {
          'SPF' => 'v=spf1 redirect=erehwon.example.com'
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
      'e2.example.com' => [
        {
          'SPF' => 'v=spf1 -all'
        }
      ],
      'exp4.example.com' => [
        {
          'TXT' => '%{l} in implementation'
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
      'e19.example.com' => [
        {
          'SPF' => 'v=spf1 default=pass'
        }
      ],
      'mail.example.com' => [
        {
          'A' => '1.2.3.4'
        }
      ],
      'e12.example.com' => [
        {
          'SPF' => 'v=spf1 exp= -all'
        }
      ],
      'e17.example.com' => [
        {
          'SPF' => 'v=spf1 redirect=-all ?all'
        }
      ],
      'e16.example.com' => [
        {
          'SPF' => 'v=spf1 exp=-all'
        }
      ]
    }
  },
  {
    'tests' => {
      'hello-macro' => {
        'spec' => '8.1/6',
        'mailfrom' => 'test@e9.example.com',
        'description' => 'h = HELO/EHLO domain',
        'result' => 'pass',
        'host' => '192.168.218.40',
        'helo' => 'msgbas2x.cos.example.com'
      },
      'require-valid-helo' => {
        'spec' => '8.1/6',
        'mailfrom' => 'test@e10.example.com',
        'description' => 'Example of requiring valid helo in sender policy.  This is a complex policy testing several points at once.',
        'result' => 'fail',
        'host' => '1.2.3.4',
        'helo' => 'OEMCOMPUTER'
      },
      'v-macro-ip4' => {
        'spec' => '8.1/6',
        'explanation' => '192.168.218.40 is queried as 40.218.168.192.in-addr.arpa',
        'mailfrom' => 'test@e4.example.com',
        'description' => 'v = the string "in-addr" if <ip> is ipv4, or "ip6" if <ip> is ipv6',
        'result' => 'fail',
        'host' => '192.168.218.40',
        'helo' => 'msgbas2x.cos.example.com'
      },
      'invalid-hello-macro' => {
        'spec' => '8.1/2',
        'comment' => 'Domain-spec must end in either a macro, or a valid toplabel. It is not correct to check syntax after macro expansion.',
        'mailfrom' => 'test@e9.example.com',
        'description' => 'h = HELO/EHLO domain, but HELO is invalid',
        'result' => 'fail',
        'host' => '192.168.218.40',
        'helo' => 'JUMPIN\' JUPITER'
      },
      'exp-only-macro-char' => {
        'spec' => '8.1/8',
        'mailfrom' => 'test@e2.example.com',
        'description' => 'The following macro letters are allowed only in "exp" text: c, r, t',
        'result' => 'permerror',
        'host' => '192.168.218.40',
        'helo' => 'msgbas2x.cos.example.com'
      },
      'p-macro-multiple' => {
        'spec' => '8.1/22',
        'comment' => 'If a subdomain of the <domain> is present, it SHOULD be used.',
        'mailfrom' => 'test@e7.example.com',
        'description' => 'p = the validated domain name of <ip>',
        'result' => [
          'pass',
          'softfail'
        ],
        'host' => '192.168.218.42',
        'helo' => 'msgbas2x.cos.example.com'
      },
      'undef-macro' => {
        'spec' => '8.1/6',
        'mailfrom' => 'test@e5.example.com',
        'description' => 'Allowed macros chars are \'slodipvh\' plus \'crt\' in explanation.',
        'result' => 'permerror',
        'host' => 'CAFE:BABE::192.168.218.40',
        'helo' => 'msgbas2x.cos.example.com'
      },
      'exp-txt-macro-char' => {
        'spec' => '8.1/20',
        'explanation' => 'Connections from 192.168.218.40 not authorized.',
        'mailfrom' => 'test@e3.example.com',
        'description' => 'For IPv4 addresses, both the "i" and "c" macros expand to the standard dotted-quad format.',
        'result' => 'fail',
        'host' => '192.168.218.40',
        'helo' => 'msgbas2x.cos.example.com'
      },
      'v-macro-ip6' => {
        'spec' => '8.1/6',
        'explanation' => 'cafe:babe::1 is queried as 1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.E.B.A.B.E.F.A.C.ip6.arpa',
        'mailfrom' => 'test@e4.example.com',
        'description' => 'v = the string "in-addr" if <ip> is ipv4, or "ip6" if <ip> is ipv6',
        'result' => 'fail',
        'host' => 'CAFE:BABE::1',
        'helo' => 'msgbas2x.cos.example.com'
      },
      'domain-name-truncation' => {
        'spec' => '8.1/25',
        'explanation' => 'Congratulations!  That was tricky.',
        'mailfrom' => 'test@somewhat.long.exp.example.com',
        'description' => 'When the result of macro expansion is used in a domain name query, if the expanded domain name exceeds 253 characters, the left side is truncated to fit, by removing successive domain labels until the total length does not exceed 253 characters.',
        'result' => 'fail',
        'host' => '192.168.218.40',
        'helo' => 'msgbas2x.cos.example.com'
      },
      'upper-macro' => {
        'spec' => '8.1/26',
        'explanation' => 'http://example.com/why.html?l=jack%26jill%3Dup',
        'mailfrom' => 'jack&jill=up@e8.example.com',
        'description' => 'Uppercased macros expand exactly as their lowercased equivalents, and are then URL escaped.',
        'result' => 'fail',
        'host' => '192.168.218.42',
        'helo' => 'msgbas2x.cos.example.com'
      },
      'p-macro-ip4-valid' => {
        'spec' => '8.1/22',
        'mailfrom' => 'test@e6.example.com',
        'description' => 'p = the validated domain name of <ip>',
        'host' => '192.168.218.41',
        'comment' => 'If a subdomain of the <domain> is present, it SHOULD be used.',
        'explanation' => 'connect from mx.example.com',
        'helo' => 'msgbas2x.cos.example.com',
        'result' => 'fail'
      },
      'trailing-dot-exp' => {
        'spec' => '8.1',
        'mailfrom' => 'test@exp.example.com',
        'description' => 'trailing dot is not removed from explanation',
        'host' => '192.168.218.40',
        'comment' => 'A simple way for an implementation to ignore trailing dots on domains is to remove it when present.  But be careful not to remove it for explanation text.',
        'explanation' => 'This is a test.',
        'helo' => 'msgbas2x.cos.example.com',
        'result' => 'fail'
      },
      'hello-domain-literal' => {
        'spec' => '8.1/2',
        'comment' => 'Domain-spec must end in either a macro, or a valid toplabel. It is not correct to check syntax after macro expansion.',
        'mailfrom' => 'test@e9.example.com',
        'description' => 'h = HELO/EHLO domain, but HELO is a domain literal',
        'result' => 'fail',
        'host' => '192.168.218.40',
        'helo' => '[192.168.218.40]'
      },
      'p-macro-ip6-valid' => {
        'spec' => '8.1/22',
        'mailfrom' => 'test@e6.example.com',
        'description' => 'p = the validated domain name of <ip>',
        'host' => 'CAFE:BABE::3',
        'comment' => 'If a subdomain of the <domain> is present, it SHOULD be used.',
        'explanation' => 'connect from mx.example.com',
        'helo' => 'msgbas2x.cos.example.com',
        'result' => 'fail'
      },
      'macro-reverse-split-on-dash' => {
        'spec' => [
          '8.1/15',
          '8.1/16',
          '8.1/17',
          '8.1/18'
        ],
        'mailfrom' => 'philip-gladstone-test@e11.example.com',
        'description' => 'Macro value transformation (splitting on arbitrary characters, reversal, number of right-hand parts to use)',
        'result' => 'pass',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'p-macro-ip6-novalid' => {
        'spec' => '8.1/22',
        'mailfrom' => 'test@e6.example.com',
        'description' => 'p = the validated domain name of <ip>',
        'host' => 'CAFE:BABE::1',
        'comment' => 'The PTR in this example does not validate.',
        'explanation' => 'connect from unknown',
        'helo' => 'msgbas2x.cos.example.com',
        'result' => 'fail'
      },
      'p-macro-ip4-novalid' => {
        'spec' => '8.1/22',
        'mailfrom' => 'test@e6.example.com',
        'description' => 'p = the validated domain name of <ip>',
        'host' => '192.168.218.40',
        'comment' => 'The PTR in this example does not validate.',
        'explanation' => 'connect from unknown',
        'helo' => 'msgbas2x.cos.example.com',
        'result' => 'fail'
      },
      'macro-mania-in-domain' => {
        'spec' => '8.1/3, 8.1/4',
        'mailfrom' => 'test@e1a.example.com',
        'description' => 'macro-encoded percents (%%), spaces (%_), and URL-percent-encoded spaces (%-)',
        'result' => 'pass',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'invalid-macro-char' => {
        'spec' => '8.1/9',
        'mailfrom' => 'test@e1.example.com',
        'description' => 'A \'%\' character not followed by a \'{\', \'%\', \'-\', or \'_\' character is a syntax error.',
        'result' => 'permerror',
        'host' => '192.168.218.40',
        'helo' => 'msgbas2x.cos.example.com'
      },
      'trailing-dot-domain' => {
        'spec' => '8.1/16',
        'mailfrom' => 'test@example.com',
        'description' => 'trailing dot is ignored for domains',
        'result' => 'pass',
        'host' => '192.168.218.40',
        'helo' => 'msgbas2x.cos.example.com'
      }
    },
    'description' => 'Macro expansion rules',
    'zonedata' => {
      'mx.example.com.ok.example.com' => [
        {
          'A' => '127.0.0.2'
        }
      ],
      'exp.example.com' => [
        {
          'SPF' => 'v=spf1 exp=msg.example.com. -all'
        }
      ],
      '40.218.168.192.example.com' => [
        {
          'TXT' => 'Connections from %{c} not authorized.'
        }
      ],
      'o.spf.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:192.168.218.40'
        }
      ],
      'e1.example.com' => [
        {
          'SPF' => 'v=spf1 -exists:%(ir).sbl.example.com ?all'
        }
      ],
      'somewhat.long.exp.example.com.somewhat.long.exp.example.com.somewhat.long.exp.example.com.somewhat.long.exp.example.com.somewhat.long.exp.example.com.somewhat.long.exp.example.com.somewhat.long.exp.example.com.somewhat.long.exp.example.com.example.com' => [
        {
          'TXT' => 'Congratulations!  That was tricky.'
        }
      ],
      'e8.example.com' => [
        {
          'SPF' => 'v=spf1 -all exp=msg8.%{D2}'
        }
      ],
      '40.218.168.192.in-addr.arpa' => [
        {
          'PTR' => 'mx.example.com'
        }
      ],
      'e6.example.com' => [
        {
          'SPF' => 'v=spf1 -all exp=e6msg.example.com'
        }
      ],
      'e9.example.com' => [
        {
          'SPF' => 'v=spf1 a:%{H} -all'
        }
      ],
      'e4.example.com' => [
        {
          'SPF' => 'v=spf1 -all exp=e4msg.example.com'
        }
      ],
      'e10.example.com' => [
        {
          'SPF' => 'v=spf1 -include:_spfh.%{d2} ip4:1.2.3.0/24 -all'
        }
      ],
      'msgbas2x.cos.example.com' => [
        {
          'A' => '192.168.218.40'
        }
      ],
      'e2.example.com' => [
        {
          'SPF' => 'v=spf1 -all exp=%{r}.example.com'
        }
      ],
      'e4msg.example.com' => [
        {
          'TXT' => '%{c} is queried as %{ir}.%{v}.arpa'
        }
      ],
      'e1a.example.com' => [
        {
          'SPF' => 'v=spf1 a:macro%%percent%_%_space%-url-space.example.com -all'
        }
      ],
      'mx.e7.example.com.should.example.com' => [
        {
          'A' => '127.0.0.2'
        }
      ],
      'e7.example.com' => [
        {
          'SPF' => 'v=spf1 exists:%{p}.should.example.com ~exists:%{p}.ok.example.com'
        }
      ],
      '41.218.168.192.in-addr.arpa' => [
        {
          'PTR' => 'mx.example.com'
        }
      ],
      'e11.example.com' => [
        {
          'SPF' => 'v=spf1 exists:%{i}.%{l2r-}.user.%{d2}'
        }
      ],
      'e5.example.com' => [
        {
          'SPF' => 'v=spf1 a:%{a}.example.com -all'
        }
      ],
      'mx.e7.example.com' => [
        {
          'A' => '192.168.218.42'
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
      '42.218.168.192.in-addr.arpa' => [
        {
          'PTR' => 'mx.example.com'
        },
        {
          'PTR' => 'mx.e7.example.com'
        }
      ],
      'e6msg.example.com' => [
        {
          'TXT' => 'connect from %{p}'
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
      'msg8.example.com' => [
        {
          'TXT' => 'http://example.com/why.html?l=%{L}'
        }
      ],
      '_spfh.example.com' => [
        {
          'SPF' => 'v=spf1 -a:%{h} +all'
        }
      ],
      'example.com.d.spf.example.com' => [
        {
          'SPF' => 'v=spf1 redirect=a.spf.example.com'
        }
      ],
      'somewhat.long.exp.example.com' => [
        {
          'SPF' => 'v=spf1 -all exp=foobar.%{o}.%{o}.%{o}.%{o}.%{o}.%{o}.%{o}.%{o}.example.com'
        }
      ],
      'e3.example.com' => [
        {
          'SPF' => 'v=spf1 -all exp=%{ir}.example.com'
        }
      ],
      'a.spf.example.com' => [
        {
          'SPF' => 'v=spf1 include:o.spf.example.com. ~all'
        }
      ],
      'macro%percent  space%20url-space.example.com' => [
        {
          'A' => '1.2.3.4'
        }
      ],
      'msg.example.com' => [
        {
          'TXT' => 'This is a test.'
        }
      ],
      '1.2.3.4.gladstone.philip.user.example.com' => [
        {
          'A' => '127.0.0.2'
        }
      ],
      '3.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.E.B.A.B.E.F.A.C.ip6.arpa' => [
        {
          'PTR' => 'mx.example.com'
        }
      ],
      '1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.E.B.A.B.E.F.A.C.ip6.arpa' => [
        {
          'PTR' => 'mx.example.com'
        }
      ]
    }
  },
  {
    'tests' => {
      'ptr-limit' => {
        'spec' => '10.1/7',
        'comment' => 'The result of this test cannot be permerror not only because the RFC does not specify it, but because the sender has no control over the PTR records of spammers. The preferred result reflects evaluating the 10 allowed PTR records in the order returned by the test data. If testing with live DNS, the PTR order may be random, and a pass result would still be compliant.  The SPF result is effectively randomized.',
        'mailfrom' => 'foo@e5.example.com',
        'description' => 'there MUST be a limit of no more than 10 PTR looked up and checked.',
        'result' => [
          'neutral',
          'pass'
        ],
        'host' => '1.2.3.5',
        'helo' => 'mail.example.com'
      },
      'mx-limit' => {
        'spec' => '10.1/7',
        'comment' => 'The required result for this test was the subject of much controversy.  Many felt that the RFC *should* have specified permerror, but the consensus was that it failed to actually do so. The preferred result reflects evaluating the 10 allowed MX records in the order returned by the test data - or sorted via priority. If testing with live DNS, the MX order may be random, and a pass result would still be compliant.  The SPF result is effectively random.',
        'mailfrom' => 'foo@e4.example.com',
        'description' => 'there MUST be a limit of no more than 10 MX looked up and checked.',
        'result' => [
          'neutral',
          'pass'
        ],
        'host' => '1.2.3.5',
        'helo' => 'mail.example.com'
      },
      'false-a-limit' => {
        'spec' => '10.1/7',
        'comment' => 'There seems to be a tendency for developers to want to limit A RRs in addition to MX and PTR.  These are IPs, not usable for 3rd party DoS attacks, and hence need no low limit.',
        'mailfrom' => 'foo@e10.example.com',
        'description' => 'unlike MX, PTR, there is no RR limit for A',
        'result' => 'pass',
        'host' => '1.2.3.12',
        'helo' => 'mail.example.com'
      },
      'include-loop' => {
        'spec' => '10.1/6',
        'mailfrom' => 'foo@e2.example.com',
        'description' => 'SPF implementations MUST limit the number of mechanisms and modifiers that do DNS lookups to at most 10 per SPF check.',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'redirect-loop' => {
        'spec' => '10.1/6',
        'mailfrom' => 'foo@e1.example.com',
        'description' => 'SPF implementations MUST limit the number of mechanisms and modifiers that do DNS lookups to at most 10 per SPF check.',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'include-over-limit' => {
        'spec' => '10.1/6',
        'mailfrom' => 'foo@e9.example.com',
        'description' => 'SPF implementations MUST limit the number of mechanisms and modifiers that do DNS lookups to at most 10 per SPF check.',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'mech-over-limit' => {
        'spec' => '10.1/6',
        'comment' => 'We do not check whether an implementation counts mechanisms before or after evaluation.  The RFC is not clear on this.',
        'mailfrom' => 'foo@e7.example.com',
        'description' => 'SPF implementations MUST limit the number of mechanisms and modifiers that do DNS lookups to at most 10 per SPF check.',
        'result' => 'permerror',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'mech-at-limit' => {
        'spec' => '10.1/6',
        'mailfrom' => 'foo@e6.example.com',
        'description' => 'SPF implementations MUST limit the number of mechanisms and modifiers that do DNS lookups to at most 10 per SPF check.',
        'result' => 'pass',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      },
      'include-at-limit' => {
        'spec' => '10.1/6',
        'comment' => 'The part of the RFC that talks about MAY parse the entire record first (4.6) is specific to syntax errors.  Processing limits is a different, non-syntax issue.  Processing limits (10.1) specifically talks about limits during a check.',
        'mailfrom' => 'foo@e8.example.com',
        'description' => 'SPF implementations MUST limit the number of mechanisms and modifiers that do DNS lookups to at most 10 per SPF check.',
        'result' => 'pass',
        'host' => '1.2.3.4',
        'helo' => 'mail.example.com'
      }
    },
    'description' => 'Processing limits',
    'zonedata' => {
      'e8.example.com' => [
        {
          'SPF' => 'v=spf1 a include:inc.example.com ip4:1.2.3.4 mx -all'
        }
      ],
      'e6.example.com' => [
        {
          'SPF' => 'v=spf1 a mx a mx a mx a mx a ptr ip4:1.2.3.4 -all'
        }
      ],
      'e7.example.com' => [
        {
          'SPF' => 'v=spf1 a mx a mx a mx a mx a ptr a ip4:1.2.3.4 -all'
        }
      ],
      'e9.example.com' => [
        {
          'SPF' => 'v=spf1 a include:inc.example.com a ip4:1.2.3.4 -all'
        }
      ],
      'e3.example.com' => [
        {
          'SPF' => 'v=spf1 include:e2.example.com'
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
      'e5.example.com' => [
        {
          'SPF' => 'v=spf1 ptr'
        },
        {
          'A' => '1.2.3.5'
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
      'e2.example.com' => [
        {
          'SPF' => 'v=spf1 include:e3.example.com'
        }
      ],
      'mail.example.com' => [
        {
          'A' => '1.2.3.4'
        }
      ],
      'e1.example.com' => [
        {
          'SPF' => 'v=spf1 ip4:1.1.1.1 redirect=e1.example.com'
        }
      ],
      'inc.example.com' => [
        {
          'SPF' => 'v=spf1 a a a a a a a a'
        }
      ]
    }
  }
]
