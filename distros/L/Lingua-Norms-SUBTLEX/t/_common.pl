use constant EPS => 1e-2;

sub about_equal {
    return 0
      if !defined $_[0] || !defined $_[1] || !length $_[0] || !length $_[1];
    return 1 if $_[0] + EPS > $_[1] and $_[0] - EPS < $_[1];
    return 0;
}

sub get_canned_data {
    my $lang = shift;

    my %data = (
        DE => {
            'vergüngen' => { freq => '0.04', frq_log => '0.301' },
            rackert     => { freq => '0.08', frq_log => '0.477' },
        },
        PT => {
            'interiorizada' => {
                frq_count => 3,
                frq_opm   => 0.0385,
                frq_log   => 0.6021,
                frq_zipf  => 1.5855,
                cd_count  => 2,
                cd_pct    => 0.0001,
                cd_log    => 0.4771,
                pos_dom   => 'V',
                pos_all   => [qw/V/]
            },
            'ósculo' => {
                frq_count => 2,
                frq_opm   => 0.0256,
                frq_log   => 0.4771,
                frq_zipf  => 1.4082,
                cd_count  => 2,
                cd_pct    => 0.0001,
                cd_log    => 0.4771,
                pos_dom   => 'N',
                pos_all   => [qw/N/]
            },
            'selvagem' => {
                frq_count => 2114,
                frq_opm   => 27.0957,
                frq_log   => 3.3253,
                frq_zipf  => 4.4329,
                cd_count  => 1091,
                cd_pct    => 0.0624,
                cd_log    => 3.0382,
                pos_dom   => 'ADJ',
                pos_all   => [qw/ADJ N/]
            }
        },
        FR => {
            'comprimées' => { frq_opm => 0.01 },
            'embâcle'    => { frq_opm => 0.01 },
            'entretient' => { frq_opm => 1.27 },
            'abaisser'   => { frq_opm => 1.09 },
            'a fortiori' => { frq_opm => 0.04, frq_lemmas => .04 },
            'divorceras' => { frq_opm => 0.02 },
            'je' =>
              { frq_opm => 25983.2, frq_lemmas => 25983.2, pos_dom => 'PN' },
            'vestibules' =>
              { frq_opm => 0, frq_lemmas => 0.96, pos_dom => 'NN' },
            'acceptiez' =>
              { frq_opm => 1, frq_lemmas => 165.84, pos_dom => 'VB' },
            'admiré' => { frq_opm => 2,  frq_lemmas => 32.39, pos_dom => 'VB' },
            'allure' => { frq_opm => 10, frq_lemmas => 10.57, pos_dom => 'NN' },
            'carrément' =>
              { frq_opm => 9.99, frq_lemmas => 9.99, pos_dom => 'AV' },
            'admirait' =>
              { frq_opm => 0.99, frq_lemmas => 32.39, pos_dom => 'VB' },
            'opération' =>
              { frq_opm => 50.01, frq_lemmas => 61.94, pos_dom => 'NN' },
            'action' =>
              { frq_opm => 49.97, frq_lemmas => 69.27, pos_dom => 'NN' },
            'voyage' =>
              { frq_opm => 10.01, frq_lemmas => 45.74, pos_dom => 'VB' },
        },
        NL => {
            niet => { freq => 18323.9788, pos => 'BW' },
            van  => { freq => 10410.2451, pos => 'VZ' },
            maar => { freq => 8385.7271,  pos => 'VG' }
        },
        UK => {
            favourite => {
                frq_count => 27052,
                frq_zipf  => 5.13,
                cd_count  => 13805,
                pos_dom   => 'adjective',
                pos_all   => [qw/adjective noun name verb unclassified/]
            }
        },
        US => {
            the => {
                frq_count => 1501908,
                frq_opm   => 29449.18,
                frq_log   => 6.1766,
                frq_zipf  => 7.468477762,
                cd_count  => 8388,
                cd_pct    => 100,
                cd_log    => 3.9237,
                pos_dom   => 'Article',
                pos_all   => [qw/Article Adverb Noun Preposition Adjective/],
            },
            detective => {
                frq_count => 3117,
                frq_opm   => 61.12,
                frq_log   => 3.4939,
                frq_zipf  => 4.785710253,
                cd_count  => 988,
                cd_pct    => 11.78,
                cd_log    => 2.9952,
                pos_dom   => 'Noun',
                pos_all   => [qw/Noun Name/],
            },
        }
    );

    return defined $lang ? $data{$lang} : \%data;
}

1;
